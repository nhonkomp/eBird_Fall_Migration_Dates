#this script removes cells from overall analysis in years that they:
# 1) dont have 100 lists in the second half of the year
#also remove years we aren't interested in

#run with 06.sh on borah
#input: each species cells_assigned csv in "./data/cells_assigned" folder on borah
#output: csv's of each species file with identical lists removed from all files, goes in the ./data/removed_overall/ folder on borah
#secondary output: csv of cells that have the desired amount of lists in the second half of a year placed in ./output/exploratory_analyses/ folder on borah

print('script name:06_remove_cells_overall.R')

#load packages----
library(here)
library(tidyverse)

#set directory and source file----
here()
source("../parameters.R")

#read in template file----
# This is a single species' file to use as a template for overall filtering. 
# Can use any species' file: they should all contain the same checklists, and the column that is different (species_observed) is irrelevant right now
template <- read.csv(paste0("../data/cells_assigned/cells_assigned_", alpha_codes[1],"_", data_version, ".csv"))

#Find cells with less than desired number of lists in the second half of a year-----
atleast_100 <- template %>%
  filter(!is.na(cell))%>% #removes rows with no cell ID assigned
  filter(year %in% years_included) %>% 
  filter(day_of_year > 172) %>% #restricts count to second half of the year
  group_by(cell, year)%>%
  tally()%>%
  filter(n >= overall_lists)
 

print(atleast_100)
print(summary(atleast_100))

#Save list of cells meeting this criteria
write_csv(atleast_100, paste0("../output/exploratory_analyses/data_availability/atleast_", overall_lists, "_lists_", data_version, ".csv"))


#forloop start------
for(i in 1:length(alpha_codes)){
  
  print(paste0("^^^^Note to reader: currently viewing ", alpha_codes[i], " data."))
  
  # read in species' data---
  cells_assigned <- read.csv(paste0("../data/cells_assigned/cells_assigned_", alpha_codes[i],"_", data_version, ".csv"))
  
  print(summary(cells_assigned))
  print(paste0("^^^^Note to reader: Initial number of lists included: ", nrow(cells_assigned), " lists"))

  # Clean data----
  cells_assigned2 <- cells_assigned %>%
    filter(year %in% years_included) %>% #only use data from years_included
    filter(!is.na(cell)) #removes rows with no cell ID assigned
  
  print(summary(cells_assigned2))
  print("^^^^Note to reader: should see years match desired years now and no NA's in cell")
  
  print(paste0("^^^^Note to reader: ", nrow(cells_assigned)-nrow(cells_assigned2), " rows removed because year not = years_included or cell was NA"))
  rm(cells_assigned) #removing this to free up memory. Only saved it to find difference of rows in line right before this


  # at least 100 lists in second half of the year----
  overall_removed <- semi_join(cells_assigned2, atleast_100, by = c("cell", "year"))
  # remove cells in years with insufficient list quantity
  
  
  print(paste0("^^^^Note to reader: ", nrow(cells_assigned2)-nrow(overall_removed), " rows removed because the cell/year has less than desired number of lists recorded in the second half of the year"))
  rm(cells_assigned2)


#write files----
write_csv(overall_removed, paste0("../data/removed_overall/overall_cells_", alpha_codes[i], "_", data_version, ".csv"))

}

print("script complete")