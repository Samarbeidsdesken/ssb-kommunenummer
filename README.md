

### Norske kommunenummer

R-skriptet `ssb.R` henter alle kommunestandarder etter 2007 fra [SSBs API](https://data.ssb.no/api/klass/v1/api-guide.html). 

Objektet `all_kommklasses` inneholder alle kommuner i perioden 2007-2024. Hvis man ønsker en tabell med 2024-kommuner, kan det gjøres slik: 

```
source('ssb.R')

kommnr_2024 <-
    all_kommklasses |> 
    filter(ar == 2024)

```

Tilsvarende inneholder objektet `all_fylkeklasses` alle fylkeskommuner i perioden 2007-2024. Hvis man ønsker en tabell med 2024-fylkeskommuner, kan det gjøres slik:

```
source(ssb.R)

all_fylkeklasses <-
    filter(ar == 2024)
    tail()
 
```

`correspondance` er en tabell med historiske endringer i kommunenummer. Det er gjort en manuell jobb for å ta hensyn til kommuner som har blitt delt opp. De manuelle tilpasningene må oppdateres ved eventuelt nye oppdelinger. 

Bruk funksjonen `find_newest_komm` til å søke opp dagens kommunenummer. 

I dette eksempelet returnerer funksjonen kommunenenummeret `5518`, som er det nye kommunenummeret til 2015-kommunen Lavangen. 

```
source('ssb.R')

find_newest_komm('1920', correspondance)

> 5518

```

I dette eksempelet returnerer funksjonen kommunenenummeret `1108`, som er det nye kommunenummeret til Sandes etter sammenslåingen med 1129-Forsand i 2020. 

```
source('ssb.R')

find_newest_komm('1920', correspondance)

> 1108  

```

Hvis du ikke har kommunenummer, bare kommunenavn, men ønsker å koble på kommunenummer ved hjelp av navn, oppstår det ofte problem med kommuner som har samiske og norske navn. 

Funksjonen `fuzzfind()`bruker regex til å matche hele ord i kommunenavnet. 

```
source('ssb.R')

fuzzfind('Levanger - Levangke', kommnr_2024)

> 5037

```