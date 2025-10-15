import requests
import json
import pandas as pd


# Henter lenken til alle kommuneinndelinger etter 2012
def get_urls(year=2012):
    url = "http://data.ssb.no/api/klass/v1/classifications/131"

    r = requests.get(url)

    versions = json.loads(r.text)
    versions = versions["versions"]

    kommuneversjoner = []

    for elem in versions:
        elem["year"] = int(elem["name"].removeprefix("Kommuneinndeling"))
        elem["url"] = elem["_links"]["self"]["href"]
        if elem["year"] > 2012:
            kommuneversjoner.append(elem)
            # print(elem)

    return kommuneversjoner


# Henter alle kommuneinndelinger og returnerer et datasett
def get_kommuneinndeling(url, year):

    kommuneinndelinger = []

    r = requests.get(url)

    data = json.loads(r.text)

    df = pd.DataFrame(data["classificationItems"])
    df.drop(columns=["parentCode", "level", "shortName"], inplace=True)
    df["year"] = year
    df = df.iloc[:, [3, 0, 1, 2]]
    return df


def get_correspondance():
    url = "https://data.ssb.no/api/klass/v1/classifications/131/changes?from=2008-01-01"
    r = requests.get(url)
    data = json.loads(r.text)
    return data["codeChanges"]


def find_new_code(code, mappings):
    if code == "5055":
        return "5059"  # Snillfjord -> Orkland
    elif code == "1850":
        return "1806"  # Tysfjord -> Narvik
    elif code == "1507":
        return "1508"  # Ålesund -> Ålesund (ignorerer 1580 Haram)
    elif code == "1534":
        return "1580"  # Haram -> Haram

    for m in mappings:
        if m["oldCode"] == code:
            return find_new_code(m["newCode"], mappings)
    return code


if __name__ == "__main__":
    correspondance = get_correspondance()
    code = find_new_code("5012", correspondance)
    print(code)
