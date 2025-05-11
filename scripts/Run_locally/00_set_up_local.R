#This script is intended to be run at the beginning of the analysis.
## It will create directories and install the necessary R packages on your local device.

####
#Directory set up----
####
## The following code will create the necessary directories within this project folder.
## Make sure these lines are run in order.

#Check working directory
getwd()
#If this does not match the project folder you are intending to complete your analysis in, use setwd() to change it

##Create Data folder----
dir.create("./data/")

###Create folders within Data
dir.create("./data/cells_assigned/") #csv's of checklists that were not properly assigned a cell will end up here to be checked and fixed
dir.create("./data/tar_files/") #put data here initially (should download as .tar files)
dir.create("./data/txt.gz_files/") #extract tar files into here (should extract as .txt.gz)
dir.create("./data/raw/") #extract .txt.gz files into here, should end up as .txt files (its ok if above process differs, as long as .txt files of all data end up in this folder)


##Create Output folder----
dir.create("./output/")

###Create folders within Output
dir.create("./output/cell_information/") #put cell raster and country outline vectors here
dir.create("./output/departures/") 
dir.create("./output/exploratory_analyses/") #this name is deceptive because these analyses actually provide necessary info. To deeply embedded to change now.
dir.create("./output/htmls/") #not sure if need this. decide if keeping rmarkdowns


####Create folders within departures
dir.create("./output/departures/halfmax_pngs/") #graphs of estimated departure distributions end up here
dir.create("./output/departures/halfmax_data/") #csv's of estimated departure distributions end up here
dir.create("./output/departures/divergent_chains/") #objects of model fits with chains that diverged end up here

####Create folders within exploratory_analyses 
dir.create("./output/exploratory_analyses/distance/") #figures about distance end up here (distribution across lists and effect on detection likelihood of each species)
dir.create("./output/exploratory_analyses/duration/") #figures about duration end up here (distribution across lists and effect on detection likelihood of each species)
dir.create("./output/exploratory_analyses/time_of_day/") #figures about time of day end up here (distribution across lists and effect on detection likelihood of each species)
dir.create("./output/exploratory_analyses/number_observers/") #figures about number of observers end up here (distribution across lists and effect on detection likelihood of each species)
dir.create("./output/exploratory_analyses/effort_years/") #figures of the distribution of each effort variable across the second half of the year, split by year, ends up here
dir.create("./output/exploratory_analyses/year_round/") #figures and datasets describing which cell/year/species/ combos count as year round, and at what proportion, end up here
dir.create("./output/exploratory_analyses/data_availability/") #figures and datasets describing which cells have enough data for analysis end up here

####
# Checking and Installing Packages----
####
## The following code will check if you are missing any of the R packages
##  required for this analysis on your local device and install them for you.

#List necessary packages
pkg <- c("auk", "tidyverse", "here", "lubridate", "sf", "rgdal",
         "scales", "rnaturalearth", "rgeos", "terra") #not sure if we need lubridate, rgdal, scales, or rgeos anymore

#List the ones that are not already installed
new.pkg <- pkg[!(pkg %in% installed.packages())]

#install packages that aren't already, or return a message
if(length(new.pkg) > 0){
  print(paste("Install missing package(s):", new.pkg, sep=' '))
  install.packages(new.pkg, dependencies = TRUE)
}else{
  print("All packages are already installed!")
}

#rstan/cmdstanr for R 4.2... 
## 5/11/25: not sure what this note was for. I went through a period early on (pre-HPC incrporation) where 
##         I tried cmdstanr installation and running (for GAMs I think? potnentially even frequentist GAMs?)
##         to make things run faster on my local device. Shouldn't be any remainin cmdstanr code anywhere.
##         Will check revision history (in original repository) to see why this may be here.

#Local set up complete. Bring in data and extract into designated folders. Then begin HPC set up.

