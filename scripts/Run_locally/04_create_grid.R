#This script creates the grid of cells to bin eBird checklists into 
#Run this script on your local machine. No input files are necessary.
#After script is run, place contents of "./output/cell_information/" folder in  "./output/cell_information/" folder on borah

#Load packages
library(rnaturalearth)
library(sf)
library(terra)
library(here)

#Set directory and source file----
here()
source("./parameters.R")

#create object with polygons of included countries----
countries<-ne_countries(country=countries_fullname, returnclass = "sf")

#see what projection is currently used and transform it to the one we want
st_crs(countries)$input

countries_proj <- st_transform(countries,
                     crs = projection)

st_crs(countries_proj)$input

#make sure country vectors are valid after re-projecting
all(st_is_valid(countries_proj)) 


#create buffer around vectors to ensure raster extent won't cut parts of the vector off
countries_buff <- st_buffer(countries_proj, dist = cell_size)

#create a raster with our desired extent, resolution, and projection----
cell_raster <- rast(crs = projection, extent = ext(countries_buff), resolution = cell_size)


#giving random value to each cell so we can make all the cells different colors
#This just allows us to see our raster on top of our map. The values don't mean anything and will be changed later
cell_raster <- setValues(cell_raster, rnorm(n = ncell(cell_raster), 0, 1))

#plot the raster cells
plot(cell_raster, alpha = 0.5) 
#plot country outlines on top of raster
plot(st_geometry(countries_proj), 
     add = TRUE)

#set value of raster to unique cell IDs----
cell_raster <- setValues(cell_raster, 1:ncell(cell_raster))

#save cells raster----
writeRaster(cell_raster, paste0("./output/cell_information/cell_raster_", data_version, ".tif"), overwrite = T)

#save country polygons----
write_sf(countries_proj, paste0("./output/cell_information/country_outlines_", data_version, ".shp"), overwrite = T)

#place contents of "./output/cell_information/" folder in  "./output/cell_information/" folder on borah
#Then you are ready to run script 05

