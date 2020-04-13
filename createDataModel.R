library(data.table)
library(tidyverse)
library(lubridate)
library(parallel)

##########################################################################################################
## Definition der Variablen für URLs und Filterbedingungen

urlCities      <- 'http://www.fa-technik.adfc.de/code/opengeodb/DE.tab'
urlStations    <- 'https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt'
urlWeatherData <- 'https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/'

minLatDistCities <- 0.01
minLonDistCities <- 0.02

minLatDistCityStation <- 0.01
minLonDistCityStation <- 0.02

##########################################################################################################
## Funktionsdefinitionen

getCityData <- function(url = urlCities, 
                        minLatDist = minLatDistCities, 
                        minLonDist = minLonDistCities) {
  
  cities <- read_tsv(file = url) %>%
    filter(typ == 'Stadt' & !is.na(lat) & !is.na(lon)) %>%
    select(ID_city = `#loc_id`, name, lat, lon) %>% 
    arrange(lat) %>% 
    mutate(latDist = lat - lag(lat), 
           lonDist = abs(lon - lag(lon))) %>% 
    filter(latDist > minLatDist | lonDist > minLonDist | is.na(latDist)) %>% 
    select(ID_city, name, lat, lon) %>%
    arrange(ID_city) %>%
    as.data.table()
  
  return(cities)
}

getStationData <- function(url = urlStations, 
                           filterString = '^GM') {
  
  stations <- read_fwf(file = url,
                       fwf_positions(c(1,13,22,42), 
                                     c(11,20,30,71), 
                                     c('ID_station', 'lat', 'lon', 'name'))) %>%
    filter(ID_station %like% filterString) %>%
    arrange(ID_station) %>%
    as.data.table()
  
  return(stations)
}

calcDistance <- function(city, 
                         stations,
                         cities,
                         minLatDist = minLatDistCityStation,
                         minLonDist = minLonDistCityStation) {
  
  distances <- data.table(ID_city = city,
                          ID_station = stations$ID_station,
                          latDist = abs(stations$lat - cities[ID_city == city, lat]),
                          lonDist = abs(stations$lon - cities[ID_city == city, lon]))
  
  distances <- distances %>%
    filter(latDist <= minLatDist & lonDist <= minLonDist) %>% 
    as.data.table()
  
  return(distances)
}

createDimensionTables <- function() {
  
  cityData <- getCityData()
  stationData <- getStationData()
  
  cl <- makeCluster(detectCores() - 1)
  clusterEvalQ(cl, c(library(data.table), library(tidyverse)))
  clusterExport(cl, c('cityData', 'stationData', 'minLatDistCityStation', 'minLonDistCityStation'), envir = environment())
  
  distanceTable <- rbindlist(parApply(cl, cityData[, 1], 1, calcDistance, stations = stationData, cities = cityData))
  
  stopCluster(cl)
  
  cities <- cityData %>% 
    filter(ID_city %in% distanceTable$ID_city) %>%
    as.data.table()
  
  stations <- stationData %>%
    filter(ID_station %in% distanceTable$ID_station) %>%
    as.data.table()
  
  return(list(cities = cities, stations = stations, distanceTable = distanceTable))
}

getWeatherData <- function(station,
                           url = urlWeatherData) {
  
  data <- read_fwf(file = paste0(url, station, '.dly'),
                   fwf_positions(c(1,12,16,18,c(1:31) * 8 + 14), 
                                 c(11,15,17,21,c(1:31) * 8 + 18), 
                                 c('ID_station', 'year', 'month', 'element', paste('day', c(1:31), sep = '_')))) %>%
    filter(element == 'TMAX') %>%
    as.data.table()
  
  return(data)
  
}

getFactTable <- function(dimTab = dimTables) {
  
  cl <- makeCluster(detectCores() - 1)
  clusterEvalQ(cl, c(library(data.table), library(tidyverse)))
  clusterExport(cl, c('dimTab', 'urlWeatherData'), envir = environment())
  
  temperatureTable <- rbindlist(parApply(cl, dimTab$stations[, 1], 1, getWeatherData)) %>%
    gather("day", "TMAX", starts_with('day')) %>%
    filter(TMAX != -9999) %>%
    mutate(date_of_day = ymd(paste0(year, month, gsub('day_', '', day))), TMAX = as.numeric(TMAX) / 10) %>%
    left_join(dimTab$distanceTable, by = 'ID_station') %>%
    select(ID_station, ID_city, date_of_day, TMAX) %>%
    as.data.table()
  
  stopCluster(cl)
  
  return(temperatureTable)
  
}

##########################################################################################################
## Erstellung der Tabellen

dimTables <- createDimensionTables()

factTable <- getFactTable()
