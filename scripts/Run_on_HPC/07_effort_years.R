#This script will examine the relationship between effort variables and day of year in second half of a year for the checklists included in the overall cell and year combos.
#It will also determine the correlation between the effort variables.
#this is important for ensuring there are no trends in effort that could bias the "species observed" variable

#Run with 07.sh on borah
#make sure all species have files in  /data/removed_overall/ folder
#make sure /output/exploratory_analyses/effort_years/ folder exists

#this script splits up the years before plotting each variable to allow for easier visual inspection.
#if we try to view all years at once, the points will cover each other and not be distinguishable


print('script name: 07_effort_years.R')

#loading packages----
library(tidyverse)
library(here)

#Set directory and source file
here()
source("../parameters.R")

#Read in csv----
effort_data <- read.csv(paste0("../data/removed_overall/overall_cells_", alpha_codes[1], "_", data_version, ".csv"))
str(effort_data)


##Cut to second half of year
second_half <- effort_data %>%
  filter(day_of_year > 180)

rm(effort_data)

summary(second_half[,c(10, 11, 12, 13)])

#create correlation matrix
cor(second_half[,c(10, 11, 12, 13)], use = "complete") #use = "complete" will ignore rows with NA's, lots of data left out


#for loop for plots----

for(i in 1:length(years_included)){
  
  single_year <- second_half %>%
    filter(year == years_included[i])
  
  print(paste0("Plotting effort for ", years_included[i]))
  
  #Plot time of day by day of year----
  png(paste0("../output/exploratory_analyses/effort_years/tod_",years_included[i], "_", data_version, ".png"), width = 1000, height = 1000, pointsize = 6)
  par(mar=c(5,6,4,1)+.1)
  
  plot(single_year$time_observations_started ~ single_year$day_of_year,
       main = paste0("Time of Day by Julian Day- ", years_included[i]),
       cex.lab = 3,
       cex.axis = 3,
       cex.main = 3)
  
  dev.off()
  
  #Plot distance by day of year----
  png(paste0("../output/exploratory_analyses/effort_years/dist_", years_included[i], "_", data_version, ".png"), width = 1000, height = 1000, pointsize = 6)
  par(mar=c(5,6,4,1)+.1)
  
  plot(single_year$effort_distance_km ~ single_year$day_of_year,
       main = paste0("Distance by Julian Day- ", years_included[i]),
       cex.lab = 3,
       cex.axis = 3,
       cex.main = 3)
  
  dev.off()
  
  #Plot duration by day of year----
  png(paste0("../output/exploratory_analyses/effort_years/dur_", years_included[i], "_", data_version, ".png"), width = 1000, height = 1000, pointsize = 6)
  par(mar=c(5,6,4,1)+.1)
  
  plot(single_year$duration_minutes ~ single_year$day_of_year,
       main = paste0("Duration by Julian Day- ", years_included[i]),
       cex.lab = 3,
       cex.axis = 3,
       cex.main = 3)
  
  dev.off()
  
  #Plot number of observers by day of year----
  png(paste0("../output/exploratory_analyses/effort_years/obs_", years_included[i], "_", data_version, ".png"), width = 1000, height = 1000, pointsize = 6)
  par(mar=c(5,6,4,1)+.1)
  
  plot(jitter(single_year$number_observers) ~ single_year$day_of_year,
       main = paste0("Observers (jittered) by Julian Day- ", years_included[i]),
       cex.lab = 3,
       cex.axis = 3,
       cex.main = 3)
  
  dev.off()
  
  
}
  


print("script complete")
