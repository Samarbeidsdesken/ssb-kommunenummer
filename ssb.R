

library(httr)
# henter rjstat bibliotek for behandling av JSON-stat
#library(rjstat)
library(tidyverse)

# Hente kommuneklassifiseringer
url <- "http://data.ssb.no/api/klass/v1/classifications/131"
d.tmp<-GET(url)
d.tmp

# Henter ut innholdet fra d.tmp kun som tekst og deretter bearbeides av fromJSONstat
kommuneklass <- 
    as_tibble()

# behandle klassifiseringsversjonene, og bare ta vare på versjoner etter 2007
kommuneklass <- 
    jsonlite::fromJSON(content(d.tmp, "text", encoding = "utf-8"))$versions |>
    as_tibble()
    mutate(
        year = as.numeric(str_sub(name, nchar(name) - 4 + 1, nchar(name))),
        validFrom = as.Date(validFrom, "%Y-%m-%d"),
        validTo = as.Date(validTo, "%Y-%m-%d")
    ) |>
    filter(year > 2007) |>
    arrange(year)


fylkesklass <- 
    jsonlite::fromJSON(content(GET('https://data.ssb.no/api/klass/v1/classifications/104'), "text", encoding = "utf-8"))$versions |>
    as_tibble() |>
    mutate(
        year = as.numeric(str_sub(name, nchar(name) - 4 + 1, nchar(name))),
        validFrom = as.Date(validFrom, "%Y-%m-%d"),
        validTo = as.Date(validTo, "%Y-%m-%d")
    )  |>
    filter(year > 2007)

# funksjon for å hente ut alle kommuneversjoner fra lenkene i datasettet
# Returnerer datasett
get_version <- function(url){
    tmp = GET(url)
    if(tmp$status == 200){
        df_content <- jsonlite::fromJSON(content(tmp, "text", encoding = "utf-8"))
        print(df_content[[1]])

        for(p in df_content){
            if(class(p) == 'data.frame' & 'code' %in% names(p)){
                df <- 
                    p |>
                    mutate(
                        ar = as.numeric(str_sub(df_content[[1]], nchar(df_content[[1]]) - 4 + 1, nchar(df_content[[1]])))
                        ) |>
                        as_tibble() |>
                        select(code, name, ar)
                return(df)
            }}
    } else {
        print(paste0('Status code: ', tmp$status))
    }
}

#get_version('http://data.ssb.no/api/klass/v1/versions/1847')

# Hent alle fylkeskoder
all_fylkeklasses <- 
    lapply(fylkesklass$`_links`$self$href, get_version) |>
    bind_rows()

# Hent alle kommunerkoder
all_kommklasses <- 
    lapply(kommuneklass$`_links`$self$href, get_version) |>
    bind_rows()

#all_kommklasses |> 
#    filter(ar == 2024)
#    tail()


# Alle kommuneedringer. 
changes <- 
    jsonlite::fromJSON(content(GET('https://data.ssb.no/api/klass/v1/classifications/131/changes?from=2008-01-01'), 'text', encoding = "utf-8"))[[1]] |> 
    as_tibble() |>
    mutate(
        changeOccurred = as.Date(changeOccurred, "%Y-%m-%d")
    )

# Hvis det er registrert flere endringer på samme kommunenummer
# er vi bare interessert i den nyeste endringen. Særlig
# relevant for navneendringer som ikke medfører endring i kommunenummer. 
changes <- 
    changes |>
    group_by(oldCode) |>
    filter(changeOccurred == max(changeOccurred))


# Legg til nye kommunenummer som oldCode, slik 
# at nye kommuner refererer til seg selv. 
# Nødvendig for å vite når vi har det nyeste kommunenummeret. 

changes_new <- 
     changes |>
     filter(!newCode %in% changes$oldCode) |>
     transmute(
        oldCode = newCode,
        oldName = newName,
        newCode,
        newName
     )  

# legg til kommunenummer hvor det ikke
# har vært endringer (nordland, M og R, Rogaland)
changes_new <- 
    all_kommklasses |>
    filter(ar >= 2020) |>
    filter(!code %in% changes$oldCode) |>
    transmute(
        oldCode = code,
        oldName = name, 
        newCode = code,
        newName = name
    ) |> 
    distinct()


changes_new |>
    filter(oldCode == '1547')

# Kombiner endrede og stabile kommunenummer 
# til èn felles korrespondansematrise
correspondance <- 
    changes |>
    #group_by(oldCode) |>
    #filter(changeOccurred == max(changeOccurred))
    bind_rows(
        changes_new
    )
    

correspondance |>
    filter(oldCode == '3907')

# Enkelte kommuner har blitt delt opp. Disse må gå til 
# èn kommune. 
correspondance |>
        filter(oldCode == '5012')

correspondance |>
        filter(oldCode == '1850')

correspondance |>
        filter(oldCode == '1507')

correspondance <- 
    correspondance |>
    mutate(
        # Snillfjord
        newName = ifelse(oldCode == '5012', 'Orkland', newName),
        newCode = ifelse(oldCode == '5012', '5059', newCode),
        # Tysfjord
        newName = ifelse(oldCode == '1850', 'Narvik', newName),
        newCode = ifelse(oldCode == '1850', '1806', newCode),
        # Tysfjord
        newName = ifelse(oldCode == '1507', 'Ålesund', newName),
        newCode = ifelse(oldCode == '1507', '1508', newCode),

    ) |>
    distinct(oldCode, newCode, .keep_all = TRUE)


correspondance |> 
    filter(newCode == '1547')



# Funksjon for å finne det nye kommunenummeret
# til et historisk kommunenummer. 

# Eksempel på bruk. Hvor df er en data.frame med unike kommunenummer.
# Koden er treg. Kan nok forbedres. 
# df$code2024 <- unlist(map(df$kommnrold, function(x){find_newest(x, correspondance)}))


find_newest_komm <- 
    function(code, df){

        keep_going = TRUE

        while(keep_going){

            newCode <- 
                df |>
                filter(oldCode == code)  |>
                pull(newCode)

            #print(newCode)

                if(identical(newCode, character(0))) {
                    newCode = ''
                    break
                } 
                if(code == newCode){
                    keep_going = FALSE
                } else {
                    code = newCode
                }
            }
            return(newCode)
}


find_newest_komm('1920', correspondance)
