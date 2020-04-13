library(data.table)
library(tidyverse)
library(lubridate)

if(!(exists('dimTables') & exists('factTable'))) {source('createDataModel.R')}

task1 <- factTable %>% 
  group_by(date_of_day) %>% 
  summarise(med_TMAX = median(TMAX)) %>%
  as.data.table()

task2 <- factTable %>% 
  filter(year(date_of_day) == 2019) %>% 
  group_by(ID_city) %>% 
  summarise(avg_TMAX = mean(TMAX)) %>% 
  left_join(dimTables$cities, by = 'ID_city') %>% 
  select(ID_city, name, avg_TMAX) %>% 
  as.data.table()

maxTemp <- factTable %>% 
  filter(date_of_day >= '1947-01-01') %>%
  group_by(date_of_day) %>% 
  top_n(1, TMAX) %>%
  arrange(date_of_day) %>% 
  as.data.table()

bonusTask <- maxTemp %>% 
  mutate(streak = sequence(rle(maxTemp$ID_city)$lengths)) %>% 
  group_by(ID_city) %>%
  summarise(longestStreak = max(streak)) %>%
  left_join(dimTables$cities, by = 'ID_city') %>%
  select(ID_city, name, longestStreak) %>%
  arrange(desc(longestStreak)) %>%
  as.data.table()
