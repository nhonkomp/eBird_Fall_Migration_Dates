#This file is intended to be run on borah prior to uploading data and running any other scripts
#It will set up the directories necessary to match the file paths laid out in future scripts

###Use the 00.sh script to submit this job.

#Print script name in output ----
## This is done throughout all the scripts so the logs state which script created the resulting output
print("script name: 00_set_up_borah.R")

####
#Install Packages----
####
## The following code will check if you are missing any of the R packages
##  required for this analysis on borah and install them for you.

#List necessary packages
pkg <- c("auk", "tidyverse", "here", "lubridate", "sf", "rgdal", "terra", "rstan", 
         "rstanarm", "bayesplot", "tidyterra", "ggpubr") #may not need ggpubr anymore

#List the ones that are not already installed
new.pkg <- pkg[!(pkg %in% installed.packages())]

#install packages that aren't already, or return a message
if(length(new.pkg) > 0){
  print(paste("Install missing package(s):", new.pkg, sep=' '))
  install.packages(new.pkg, dependencies = TRUE, repos='http://cran.us.r-project.org')
}else{
  print("All packages are already installed.")
}


####
#Directory set up----
####
## The following code will create the necessary folders within this project directory.

#Make sure directory is set to project folder
here::here()

## Create logs folder---
dir.create("./logs/")

## Create Scripts folder---
dir.create("./scripts/")

## Create Sh_files folder----
dir.create("./sh_files/")

## Create Data folder----
dir.create("./data/")

### Create folders within Data
dir.create("./data/cells_assigned/")
dir.create("./data/cleaned/")
dir.create("./data/filtered/")
dir.create("./data/raw/")
dir.create("./data/refined_species/")
dir.create("./data/removed_overall/")
dir.create("./data/removed_specific/")
dir.create("./data/zerofilled/")

## Create Output folder----
dir.create("./output/")

### Create folders within Output
dir.create("./output/cell_information/")
dir.create("./output/departures/")
dir.create("./output/exploratory_analyses/")

## Create folders within departures
dir.create("./output/departures/divergent_chains/")
dir.create("./output/departures/halfmax_data/")
dir.create("./output/departures/halfmax_pngs/")
dir.create("./output/departures/summary_figs/")

#Create scripts within exploratory analyses
dir.create("./output/exploratory_analyses/data_availability/")
dir.create("./output/exploratory_analyses/distance/")
dir.create("./output/exploratory_analyses/duration/")
dir.create("./output/exploratory_analyses/effort_years/")
dir.create("./output/exploratory_analyses/number_observers/")
dir.create("./output/exploratory_analyses/time_of_day/")
dir.create("./output/exploratory_analyses/year_round/")



#Once this script runs correctly, place the contents of the "./scripts/run_on_borah/" 
##### folder on your local machine into the "./scripts/" folder on borah.
#Place the contents of the "./sh_files/" folder on your local machine in the "./sh_files"
##### folder on borah.
#Last, use globus to upload the raw data .txt files from the "./data/raw/" folder 
##### on your local machine to the "./data/raw" folder on borah.

#Now you are ready to run script 01.

print("script complete")