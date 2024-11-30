#Compile Departure data and filter out poor model fits

#run on borah with 13.sh

#input csv files of departure data from all jobs submitted
#output combined dataset of all departure data with poorly fit models removed

print("13_combine_halfmax.R")

#load packages----
library(tidyverse)
library(here)
library(sf)
library(terra)
library(tidyterra)

#set directory and source file----
here()
source("../parameters.R")

#Create vector of file names
file_names <- list.files("../output/departures/halfmax_data/", pattern = "*.csv", full.names = T)

print(length(file_names))
print("^^^^Note to reader: number of files to rbind.")

#read in all files and create a list
file_list <- lapply(file_names, read.csv, header = T)

#bind all files----
combined.df <- do.call(rbind, file_list)

rm(file_list)

print(head(combined.df[,c(1:23)]))
print(summary(combined.df[,c(1:23)]))
print("^^^^Note to reader: inital combined data.")

#filter out GAMs... ----
combined.df2 <- combined.df %>%
  filter(num_diverge == 0) %>% #with unresolved divergent transitions
  filter(max_Rhat <= 1.02) %>% # with Rhat > 1.02
  filter(min_neff >=400) # with number of effective samples <400 for any parameter

print(paste0("^^^^Note to reader: ", nrow(combined.df)-nrow(combined.df2), " rows removed due to filtering parameters."))

#Assess filtering results
print(head(combined.df2[,c(1:23)]))
print(summary(combined.df2[,c(1:23)]))
print("^^^^Note to reader: filtered combined data") 

#hist of NA's in halfmax estimates---
png(paste0("../output/departures/summary_figs/hmNA_hist_", data_version, ".png" ), width = 1000, height = 700)

hist(combined.df2$hm_NA, main = "Distribution on NA's in Halfmax Estimates", xlab = "Proportion of iterations with Halfmax = NA")

dev.off()

#create confidence interval
combined.df2$hm_CI <- combined.df2$UCI_hm - combined.df2$LCI_hm

#hist of halfmax confidence intervals----
png(paste0("../output/departures/summary_figs/hmCI_hist_", data_version, ".png" ), width = 1000, height = 700)

hist(combined.df2$hm_CI, main = "Distribution of HalfMax Estimate CI's", xlab = "Difference in Days b/w Upper and Lower CI")

dev.off()

#hist of halfmax standard errors----
png(paste0("../output/departures/summary_figs/hmSE_hist_", data_version, ".png" ), width = 1000, height = 700)

hist(combined.df2$se_hm, main = "Distribution of HalfMax Estimate Standard Error's", xlab = "Halfmax Estimate Standard Error")

dev.off()


#write finalized file----
write.csv(combined.df2, "../data/combined_halfmax_df.csv", row.names = F)


#histograms of departure date by species----

for(i in 1:length(refined_species)){
  
single_sp <- combined.df2 %>%
  filter(species == refined_species[i])

print(summary(as.factor(single_sp$species)))

png(paste0("../output/departures/summary_figs/depart_hist_", refined_species[i], "_", data_version, ".png" ), width = 1000, height = 700)

graphics::hist(single_sp$mn_hm, xlim = c(172, 366), main = refined_species[i], xlab = "Mean Halfmax's", breaks = 20, ylim = c(0, 200))

dev.off()

}

#histograms of departures per year----

actual_years <- combined.df2 %>%
  pull(year) %>%
  base::unique()

for(i in 1:length(actual_years)){
 
  single_yr <- combined.df2 %>%
    filter(year == actual_years[i])
  
  print(summary(single_yr$year))
  
  png(paste0("../output/departures/summary_figs/depart_hist_", actual_years[i], "_", data_version, ".png" ), width = 1000, height = 700)
  
  hist(single_yr$mn_hm, xlim = c(172, 366), main = actual_years[i], xlab = "Mean Halfmax's", breaks = 25, ylim = c(0, 100))
  
  dev.off()
  
}


#departure date maps----

#read in cell raster
cells<-rast(paste0("../output/cell_information/cell_raster_", data_version, ".tif"))

#read in countries outlines
countries_proj <- read_sf(paste0("../output/cell_information/country_outlines_", data_version, ".shp"))

print(all(st_is_valid(countries_proj))) 
print("^^^^Note to reader: make sure country vectors are valid.")

st_crs(cells) # == st_crs(countries_proj)
st_crs(countries_proj) #user input different so not matching?
print("^^^^Note to reader: check if cell raster projection matches country projection. ")


#make df of all cell values
all_cells <- data.frame(values(cells))
names(all_cells) <- "cell"

print(summary(all_cells))

#max and min depart
max_depart <- max(combined.df2$mn_hm)
min_depart <- min(combined.df2$mn_hm)


#Species for loop
for(i in 1:length(refined_species)){

  print(paste0("^^^^Note to reader: starting ", refined_species[i], "'s departure maps."))
  
  #filter combined df to a single species
  single_sp2 <- combined.df2 %>%
    filter(species == refined_species[i])
  
  print(summary(as.factor(single_sp2$species)))
  
  #make a list of cells available
  avail_cells <- single_sp2 %>%
    select(cell) %>%
    unique() %>%
    plyr::mutate(included = 1) #make column of 1's

  
  #merge df's with all cell values df
  cells_included <- left_join(all_cells, avail_cells)
  

  print(summary(cells_included))
  
  #new raster with value set to new column
  species_cells <- cells
  values(species_cells) <- cells_included$included
  
  ##Convert cell raster to a vector
  cells_vector <- as.polygons(species_cells, dissolve = FALSE)
  print(all(is.valid(cells_vector)))
  print("^^^^Note to reader: if TRUE above, all cell polygons are valid")
  
  ##Empty Fig
  #open device
  png(paste0("../output/departures/summary_figs/departure_map_", refined_species[i], "_empty_", data_version, ".png" ), width = 1000, height = 800)
  
  
  #plot map, raster, then species-cells-polygon
  print( ggplot()+
           geom_spatvector(data = countries_proj, fill = NA )+
           geom_spatvector(data = cells_vector, fill = NA)+
           scale_fill_viridis_c(na.value = "white", limits = c(min_depart, max_depart))+
           labs(fill = "Halfmax DOY")+
           theme_void()+
           theme(legend.key.size = unit(1, 'cm'), #change legend key size
                 legend.key.height = unit(1, 'cm'), #change legend key height
                 legend.key.width = unit(1, 'cm'), #change legend key width
                 legend.title = element_text(size=20), #change legend title font size
                 legend.text = element_text(size=15)) #change legend text font size
  )
  
  #close device
  dev.off()
  
  #make a list of years available
  avail_years <- single_sp2 %>%
    pull(year) %>%
    base::unique()
  
  #Start second for loop looping through years
for(j in 1:length(avail_years)){
  
  print(paste0("^^^^Note to reader: working on ", refined_species[i], "'s ", avail_years[j], " map."))
  
  #filter data to single year
  single_yr <- single_sp2 %>%
    filter(year == avail_years[j]) %>%
    select(cell, year, mn_hm)
  
  print(summary(single_yr))
  
  #make df of cell and mn_hm
  single_yr_hm <- single_yr %>%
    select(cell, mn_hm)
  
  #merge hm df with full cell values df
  all_cell_hm <- left_join(all_cells, single_yr_hm)
  
  print(summary(all_cell_hm))
  
  #set values of raster to hm column of merged df
  dep_date <- cells
  values(dep_date) <- all_cell_hm$mn_hm
  
  #open device
  png(paste0("../output/departures/summary_figs/departure_map_", refined_species[i], "_", avail_years[j], "_", data_version, ".png" ), width = 1000, height = 800)
  
  
  #plot map, raster, then species-cells-polygon
 print( ggplot()+
    geom_spatraster(data = dep_date)+
    geom_spatvector(data = countries_proj, fill = NA )+
    geom_spatvector(data = cells_vector, fill = NA)+
    scale_fill_viridis_c(na.value = "white", limits = c(min_depart, max_depart))+
    labs(fill = "Halfmax DOY")+
    theme_void()+
    theme(legend.key.size = unit(1, 'cm'), #change legend key size
          legend.key.height = unit(1, 'cm'), #change legend key height
          legend.key.width = unit(1, 'cm'), #change legend key width
          legend.title = element_text(size=20), #change legend title font size
          legend.text = element_text(size=15)) #change legend text font size
 )
  
  #close device
  dev.off()
  
  } #close year for loop
  
} #close species for loop

print("done making maps")

#calculated departure combos----
#summarise available combos by species and year- NOT GENERALIZABLE

df <- combined.df2 %>% select(species, cell, year)

table <- df %>%
  group_by(species, year) %>%
  tally() %>%
  arrange(year)
names(table)[3] <- "n_halfmax"

print(table)

species_lists <- table %>%
  pull(species) %>%
  unique() %>%
  sort()

species_df <- data.frame(species = species_lists)

year_lists <- 2002:2021


table_2 <- data.frame(Species = species_lists, year_2002 = NA,year_2003 = NA,year_2004 = NA,
                     year_2005 = NA,year_2006 = NA,year_2007 = NA,year_2008 = NA, year_2009 = NA,
                     year_2010 = NA,year_2011 = NA,year_2012 = NA,year_2013 = NA,year_2014 = NA,
                     year_2015 = NA,year_2016 = NA,year_2017 = NA,year_2018 = NA,year_2019 = NA,
                     year_2020 = NA,year_2021 = NA)


for(i in 1:length(year_lists)){
  
  single_yr <- table %>%
    filter(year == year_lists[i])
  
  all_sp <- left_join(species_df, single_yr)
  
  table_2[,(i+1)] <- all_sp$n_halfmax
  
}

print(table_2)

write.csv(table_2, "../output/departures/calculated_departures_combos.csv", row.names = F)


print("script complete")
