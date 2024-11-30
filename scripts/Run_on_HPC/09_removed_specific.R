#This script will remove checklists from species' analyses in cells and years that:
# 1) the cell doesnt have the desired number of days with lists reporting the species between the average summer solstice date and the selected "year-round period"
# 2) the cell has more than the desired percent of lists with species present within the year-round period (eg. >5% of lists after Nov. 30th = "Year-round" designation for a given cell-year-species combo)
# 3) the cell has a proportion of year-round years higher than 0.40
# It will also restrict all data to the second half of the year (after average summer solstice)

# Run with 09.sh on borah
# input: each species' file from ./data/removed_overall/ folder on borah
# output: csv's (with specific cell/year combos removed) for each species in ./data/removed_specific/ folder on borah
#secondary output: csv for each species of cell/year combos with adequate data availability in ./output/exploratory_analyses/data_availability/ folder
#secondary output: csv for each species of cell/year combos considered year-round and a csv of each cells's proportion of years year-round in output/exploratory_analyses/year_round/

print('script name:09_removed_specific.R')

#load packages----
library(here)
library(tidyverse)

#set directory and source file----
here()
source("../parameters.R")


#For loop for species-specific cell removal----
for(i in 1:length(alpha_codes)){
  

  print(paste0("^^^^Note to reader: currently viewing ", alpha_codes[i], "'s data."))
  
  #read in files
  overall_removed <- read.csv(paste0("../data/removed_overall/overall_cells_", alpha_codes[i], "_", data_version, ".csv")) 
  
  
  print(summary(overall_removed))
  print("^^^^Note to reader: initial bird data (overall cells removed)")
  
  #days-with-species requirement----
  #Find year-cell combos with desired minimum number of days with lists reporting target species in the second half of the year (but before year round cut off)
  atleast_30 <- overall_removed %>%
    filter(species_observed == TRUE) %>%
    filter(day_of_year > 172) %>%
    filter(day_of_year <= max_doy) %>% #exclude year round lists when counting days with species observed
    group_by(cell, year, day_of_year) %>%
    tally() %>%
    ungroup() %>%
    group_by(cell, year)%>%
    tally() %>%
    filter(n >= species_present_days) %>%
    ungroup()
  
  names(atleast_30)[3] <- "days_present"
  
  print(summary(atleast_30))
  print("^^^Note to reader: cells/years that meet days-with-species requirement")
  
  #save files of adequate data cells
  write_csv(atleast_30, paste0("../output/exploratory_analyses/data_availability/atleast_", species_present_days, "_", alpha_codes[i], "_", data_version, ".csv"))
  
  
  #remove specific cells (days-with-species requirement)----
  #Remove cell/year combos with less than required number of days with lists reporting the target species
  specific_removed <- semi_join(overall_removed, atleast_30, by = c("cell", "year"))
  
  print(paste0("^^^^Note to reader: ", nrow(overall_removed)-nrow(specific_removed), " rows removed because the cell has less than desired number of days with observations of ",  alpha_codes[i], " in the second half of the given year."))
  rm(overall_removed)
  
  #determine year-round cell/year combos---- 
  
  #Find rows with species sightings after end of year cut off
  year_round_raw <- specific_removed %>%
    filter(species_observed == TRUE) %>% #filtering to observations that included the target species
    filter(day_of_year > max_doy) #filtering to days within year-round period
  
  
  #tally year round cases by cell and year
  year_round_grouped <- year_round_raw %>%
    group_by(cell, year) %>%
    tally() 
  
  names(year_round_grouped)[3] <- "yero_lists"
  
  
  #Find rows with species sightings in secoond half of the year
  present_raw <- specific_removed %>%
    filter(species_observed == TRUE) %>% #filtering to observations that included the target species
    filter(day_of_year > 172) #filtering to second half of year
  
  
  #tally detection lists by cell and year
  present_grouped <- present_raw %>%
    group_by(cell, year) %>%
    tally() 
  
  names(present_grouped)[3] <- "present_lists"
  
  
  #combine all lists with year-round lists
  year_round_percent <- left_join(present_grouped, year_round_grouped, by = c("cell", "year")) #combine with df showing count of species_observed lists in second half of the year
  
  #convert NA's to zeros
  year_round_percent["yero_lists"][is.na(year_round_percent["yero_lists"])] <- 0
  
  #calculate proportion of detection lists falling in year-round period
  year_round_percent$percent_yero <- year_round_percent$yero_lists / year_round_percent$present_lists
  
  print(summary(year_round_percent))
  print("^^^^Note to reader: should see calculated proportions of detection lists falling in the year-round period. must be between 0 and 1")
  
  #Filter to year-round cell-year combos
  year_round <- year_round_percent %>%
    filter(percent_yero > yero_cutoff) #select cell-year combos with more than acceptable percent of lists in year-round period
  
  print(summary(year_round))
  print("^^^^Note to Reader: filtered for just year-round")
    
  #save files of year round cases
  write_csv(year_round, paste0("../output/exploratory_analyses/year_round/yearround_cells_", alpha_codes[i], "_", data_version, ".csv"))
  
  #remove year-round cases----
  yero_removed <- anti_join(specific_removed, year_round, by = c("cell", "year"))
  
  print(paste0("^^^^Note to reader: ", nrow(specific_removed)-nrow(yero_removed), " rows removed because ", alpha_codes[i], " present year round."))
  rm(specific_removed)
  
  print(summary(yero_removed))
  print("^^^^Note to reader: remaining cells after year round removed")
  
 
  #find proportions of year round----
  
  #Find total years per cell
  total_tallied <- atleast_30 %>%
    group_by(cell) %>%
    tally()
  
  names(total_tallied)[2] <- "total_yrs"
  
  #find number of years year-round per cell
  yero_tallied <- year_round %>%
    group_by(cell) %>%
    tally()

  names(yero_tallied)[2] <- "yrs_res"
  
  #combine datasets
  prop_yr <- left_join(total_tallied, yero_tallied)
  
  #convert NA's to zeros
  prop_yr["yrs_res"][is.na(prop_yr["yrs_res"])] <- 0
  
  #Calculate proportion
  prop_yr$prop_yero <- prop_yr$yrs_res / prop_yr$total_yrs

  
  #Save file of year round proportions
  write.csv(prop_yr, paste0("../output/exploratory_analyses/year_round/prop_yero_", alpha_codes[i], "_", data_version, ".csv"), row.names = F)
  
  #Find high proportions
  high_prop <- prop_yr %>%
    filter(prop_yero > prop_yero_max)
  
  print(summary(high_prop))
  print("^^^^Note to reader: all props should be above acceptable year round proportion")
  
  #remove cells with high year round proportions
  hiprop_removed <- anti_join(yero_removed, high_prop, by = "cell")
  
  print("^^^^Note to reader: cells with high proportion of year-round years now removed")

  #cut to second half of year----
  second_half <- hiprop_removed %>%
    filter(day_of_year > 172)
  #removes cells that have lists only in first half of year, as mentioned in previous script
  
  print(summary(second_half))
  print("^^^^Note to reader: cut to second half of year (after average summer solstice date)")
  
  #write final file----
  write.csv(second_half, paste0("../data/removed_specific/specific_cells_", alpha_codes[i], "_", data_version, ".csv"), row.names = F)

  
  
}

print("script complete")