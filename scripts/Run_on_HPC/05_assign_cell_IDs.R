#this script assigns each list to a cell by determining which cell of the raster the lat and long of the list falls into
#output: csv of updated dataframe for each species
#additional output: csv of checklists that were not properly assigned to a cell (i.e. cell = NA)

## Code adapted from Bre Power's code (Powers et al. 2021)
#Run on borah with 05.sh
#make sure "./output/cell_information" folder exists on borah and "cell_raster.tif" was moved into it
#make sure "./data/cleaned/" has all species csv's and a "./data/cells_assigned" folder exists


print('script name: 05_assign_cell_IDs.R')

#Load packages----
library(here)
library(tidyverse)
library(sf)
library(terra)

#set directory and source file----
here()
source("../parameters.R")


#bring in cell raster
cell_raster<-rast(paste0("../output/cell_information/cell_raster_", data_version, ".tif"))

#For loop for assigning cell ID's----
for(i in 1:length(alpha_codes)){
  
  print(paste0("now viewing ", alpha_codes[i], "'s file"))
  #tells us what species is having an issue if the script fails in the middle of this loop
  
  #read in the cleaned datasets
  bird_data<-read_csv(paste0("../data/cleaned/cleaned_", alpha_codes[i], "_", data_version, ".csv"))

  #confirm this was read in properly
  print(str(bird_data))
  print("^^^^Note to reader: check that the latitude and longitude columns have what look like decimal degree points in them")
  
  
  #turn the latitude and longitude columns into a spatial variable (coordinates)
  list_pts<-bird_data%>%
    st_as_sf(coords = c("longitude", "latitude"))
  print(str(list_pts))
  print("^^^^Note to reader: Check that latitude and longitude columns are gone and a new geometry column has been created")
  print(head(list_pts$geometry))
  print("^^^^Note to reader: This gives the head of the geometry column. Should see that there are points and no CRS is currently set")
  
  
  #this gives the geometry column of coordinates a crs. 
  #first assigns WGS84 projection, then transforms to desired projection
  list_pts<-list_pts%>%
    st_set_crs(4326)%>% #assuming WGS84 accurately describes location of coordinates recorded in eBird checklist (https://epsg.io/4326)
    st_transform(projection)
  print(head(list_pts$geometry))
  print("^^^^Note to reader: Should see that CRS is now our desired projection")
  
  #make the vector into a SpatVector
  list_pts <- as(list_pts, "SpatVector")
  
  #Extract the cell ID 
  ## this extracts the cell ID of the raster cell that each point falls into and creates a "cell" column for these values
  bird_data$cell <- terra::extract(cell_raster, list_pts)$lyr.1
  
  
  #viewing cell assignments
  print(summary(bird_data$cell))
  print("^^^^Note to reader: Cell column added. Numbers should fall within range of total number of cells in raster. Can also see number of NA's")

  #NA cell----
  #creating list of checklists that weren't assigned to a cell for fixing
  no_cell<-bird_data%>%
    select(checklist_id, species_observed, country, latitude, longitude, cell)%>%
    filter(is.na(cell))
  print("checklists not assigned a cell:")
  print(no_cell)
  print("^^^^Note to reader: number of rows should match number of NA's previously reported. May need to manually assign cell ID's")

  
  #saving the new dataframes
  write_csv(bird_data, paste0("../data/cells_assigned/cells_assigned_",alpha_codes[i],"_", data_version, ".csv"))


  #Saving a list of information about checklists that weren't assigned to a cell
  write_csv(no_cell, paste0("../data/cells_assigned/NA_cells_",alpha_codes[i],"_",data_version,".csv"))
  
  
  }

print("script complete")

#check the lists that were not assigned to a cell and re-run scripts 04 and 05 if necessary.
