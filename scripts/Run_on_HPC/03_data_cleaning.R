#This script will transform variables and remove unnecessary columns.
##Run on borah with 03.sh file, make sure all species' zerofilled datasets are in the data/zerofilled folder on borah

# Code adapted from "Best Practices for Using eBird Data" (Strimas-Mackey et al. 2020) examples

print('script name: 03_data_cleaning.R')
#load packages----
library(auk)
library(here)
library(tidyverse)
library(lubridate)#for hms, hours, minutes, seconds, year, yday

#set directory and source file----
here()
source("../parameters.R")

# function to convert time observation to hours since midnight----
time_to_decimal <- function(x) {
  x <- hms(x, quiet = TRUE)
  hour(x) + minute(x) / 60 + second(x) / 3600
}


#For loop for cleaning----
for(i in 1:length(alpha_codes)){
  
  print(paste0("^^^^Note to reader: currently viewing ", alpha_codes[i], "'s zerofilled file"))
  #tells us what species is having an issue if the script fails in the middle of this loop
  
  #read in the zerofilled dataset
  ebd_zf<-read.delim(paste0("../data/zerofilled/zerofilled_", alpha_codes[i], "_", data_version, ".txt"), sep="\t")
  
  #confirm this was read in properly
  print(str(ebd_zf))
  print("^^^^Note to reader: use str() output to confirm zerofilled dataset was read in properly.")
  
  # clean up observation count, time, and date variables----
  ebd_zf <- ebd_zf %>% 
    mutate(
      # convert X's to NA's
      observation_count = if_else(observation_count == "X", 
                                  NA_character_, observation_count), #dont technically need this because removing this column later anyway
      observation_count = as.integer(observation_count),
      # effort_distance_km to 0 for non-travelling counts
      effort_distance_km = if_else(protocol_type != "Traveling", 
                                   0, effort_distance_km),
      # convert time to decimal hours since midnight
      time_observations_started = time_to_decimal(time_observations_started),
      # split date into year and day of year
      year = year(observation_date),
      day_of_year = yday(observation_date)
    )
  
  print(str(ebd_zf))
  print("^^^^Note to reader: should see the number of variables increase to 36, with year and day_of_year added to the end. Also time_observations_started is changed to a decimal.")
  
  #filtering by effort----
  ebd_zf_filtered <- ebd_zf %>% 
    dplyr::filter(
      duration_minutes <= 5 * 60, #5 or less hours (this should already be done from initial filtering)
      effort_distance_km <= 5, #5 or less kilometers traveled
      number_observers <= 10) %>% # 10 or fewer observers
    dplyr::filter( duration_minutes > 0, #checklists are at least a minute long
                   number_observers > 0) #checklists have at least 1 person
  
  
  print(str(ebd_zf_filtered))
  print("^^^^ Note to reader: should see number of observations (rows) decreased above")
  

  #Remove unnecessary columns
  ebird <- ebd_zf_filtered %>% 
    dplyr::select(checklist_id, species_observed, 
                  country, latitude, longitude,
                  protocol_type, all_species_reported,
                  year, day_of_year,
                  time_observations_started, 
                  duration_minutes, effort_distance_km,
                  number_observers)
  
  
  print(str(ebird))
  print("^^^^ Note to reader: should see only 13 variables above now")
  
  print(summary(ebird))
  print("^^^^ Note to reader: Species observed tells us how many lists had that species present. Latitude and longitude included for ")
        print("determining checklist location. All species reported should be all TRUE. Year shows time range of data available.  ")
        print("Day of year should start at 1 and end at or before 366. Time observation started should start at 0 and end at or before 24. ")
        print("Duration minutes should have max no more than 300. Effort distance max no more than 5. Number of observers max no more than 10.")
  
  
  write_csv(ebird, paste0("../data/cleaned/cleaned_", alpha_codes[i], "_", data_version, ".csv"), na = "")

  
}



#Assess Data Availability ----
## The following will gather information about the number of checklists meeting the filtering criteria by year and day of year.
## It uses the last species' zerofilled file, which should contain the same checklists as all other species' zerofilled files
print(paste0("^^^^Note to reader: assessing temporal data availability"))

#number of lists by year----
lists_by_year<-ebird%>%
   dplyr::count(year)

 write.csv(lists_by_year, "../output/exploratory_analyses/data_availability/lists_by_year.csv", row.names = F)

 #number of lists by day----
 lists_by_day<-ebird%>%
   dplyr::count(day_of_year)

write.csv(lists_by_day, "../output/exploratory_analyses/data_availability/lists_by_day.csv", row.names = F)

print("script complete")

