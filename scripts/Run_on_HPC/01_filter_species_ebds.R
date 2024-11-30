# This script filters the raw eBird data
## It must be run on borah with 01.sh file.
## First, make sure all species' EBD files and the SED file are placed in the /data/raw folder on borah

# Code adapted from Bre Power's code (Powers et al. 2021) and "Best Practices for Using eBird Data" (Strimas-Mackey et al. 2020) examples

#Print script name in output ----
## This is done throughout all the scripts so the logs show which script created the resulting output
print('script name: 01_filter_species_ebds.R')

#Load Packages----
library(auk)
library(here)
library(tidyverse)

#Set directory and source files ----
here()
source("../parameters.R")

#FILTERING SED----
##Read in SED----
sed_file<-paste0("../data/raw/ebd_sampling_", data_version, ".txt")

##Define filters for sed----
sed_filters <- auk_sampling(sed_file) %>% ### Note that the sed file is read in at this point
  auk_country(countries_included) %>%
  auk_protocol(protocol = c("Stationary", "Traveling")) %>% #excludes incidental and historical lists
  auk_duration(duration = c(0,300)) %>% #includes only lists less than 5 hours
  auk_complete() #excludes incomplete lists, which is necessary for assuming non-detection

##Check that my filters have been properly applied----
sed_filters #running this sets the parameters to filter by
print("^^^^Note to reader: look through output above and make sure all filters are correct")
# "Notes to the reader" like the one above, will show up throughout the logs in places where things need to be checked to make sure they ran properly
# If you open the logs in a text editor, you may be able to search for these words to easily navigate to important parts of the output

##Create path for sed output----
sed_output <- paste0("../data/filtered/filtered_sed_", data_version, ".txt")

##Filter sed----
auk_filter(sed_filters, file = sed_output, overwrite = T)
#This completes the filtering


#Check filtered SED file----

##Read in filtered sampling file----
sed <- read_sampling(paste0("../data/filtered/filtered_sed_", data_version, ".txt"), unique = F)
### Unique=F to maintain copies of group checklists.
### We will filter them out later.
###  For now they need to stay in because the ebd has those copies still.

##Check structure of SED dataframe----
### Can see number of rows, column names, and data types
print(str(sed))

##Change character variables to factors----
### This will allow us to see a count of each country and protocol type in the summary
sed$country <- as.factor(sed$country)
sed$protocol_type <- as.factor(sed$protocol_type)

##View a summary of the columns of interest----
summary(sed[,c(2,21,24, 28)])
print("^^^^Note to reader: make sure Country only contains countries you included,")
print("      Protocol Type is only Stationary and Travelling, ")
print("      Duration does not exceed 300 minutes, ")
print("      and All Species Reported is only 1s")


#FILTERING EBD's----

##For loop for filtering each species' file----
### This will cycle through and filter each species' EBD file
for(i in 1:length(alpha_codes)){
  
  #Label this species's section of output
  ## This allows us to see which species is having an issue if the script fails in the middle of it
  print(paste0("^^^^Note to reader: currently filtering ", alpha_codes[i], "'s file"))
  
  #Set the file path for species' EBD and the filtered SED
  ## Note, an SED must be provided to auk_filter() when filtering an EBD
  ## However, we will specify that we do not want to filter the SED (since we already did that above)
  ebd_input <- paste0("../data/raw/ebd_", alpha_codes[i],"_", data_version, ".txt")
  sed_input <- paste0("../data/filtered/filtered_sed_", data_version, ".txt" )
  
  #Pair the EBD and SED together into an "ebd object"
  ## This allows auk_filter() to recognize the ebd better.
  ebd_object <- auk_ebd(ebd_input, sed_input)
  
  #Set the filtering parameters
  ebd_filters <- ebd_object %>% ## Note that the ebd object is also provided at this point
    auk_species(common_names[i]) %>%
    auk_country(countries_included) %>%
    auk_protocol(protocol = c("Stationary", "Traveling")) %>% #excludes incidental and historical lists
    auk_duration(duration = c(0,300)) %>% #excludes lists more than 5 hours
    auk_complete() #excludes incomplete lists, necessary for assuming non-detection
  
  #Check that the filtering parameters were set properly
  print(ebd_filters)
  print("^^^^Note to reader: look through output above and make sure all filters are correct")
  
  #Set file name and path for output file
  ebd_output <- paste0("../data/filtered/filtered_", alpha_codes[i],"_", data_version, ".txt")
  
  #Filter the EBD
  auk_filter(ebd_filters, file = ebd_output, overwrite = T, filter_sampling = F)
  ## Overwrite=T ensures new file is still written if the file already exists
  ## Filter_sampling=F stops the function from filtering the SED since it is already filtered
 
  #Check filtered EBD file----
  ebd <- read_ebd(paste0("../data/filtered/filtered_", file_names[i], "_", data_version, ".txt"), unique = F, rollup = F)
  
  #Check ebd structure
  ## Can see number of rows, column names, and data types
  print(str(ebd))
  
  #Change character variables to factors
  ## This will allow us to see a count of each country, species name, and protocol type in the summary
  ebd$country <- as.factor(ebd$country)
  ebd$common_name <- as.factor(ebd$common_name)
  ebd$protocol_type <- as.factor(ebd$protocol_type)
  
  #View a summary of the columns of interest
  print(summary(ebd[, c(6,16, 35, 38, 42)]))
  print("^^^^Note to reader: make sure only one species' name is present,")
  print("      Country only contains countries you included,")
  print("      Protocol Type is only Stationary and Travelling, ")
  print("      Duration does not exceed 300 minutes, ")
  print("      and All Species Reported is only 1s")
  
  
}

print("script complete")
