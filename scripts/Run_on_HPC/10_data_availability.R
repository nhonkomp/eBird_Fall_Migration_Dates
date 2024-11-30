#This script is for assessing data availability for each species
#will create figures (overall, year round, and specific cells) and a dataframe of years per cell by species

#need:
# -cell raster from "04_create_grid.R" script in "./output/cell_information/" on borah
# -country vectors from from "04_create_grid.R" script in "./output/cell_information/" on borah
# -csv of overall cells in "./output/exploratory_analyses/data_availability/"
# -csv for each species year round cell/year combos in "./output/exploratory_analyses/year_round/"
# -csv of each species' year round proportions in "output/exploratory_analyses/year_round/"
# -csv of each species cells with enough data available in "/output/exploratory_analyses/data_availability/"

print('script name: 10_data_availability.R')

#Load packages----
library(sf)
library(terra)
library(tidyverse)
library(tidyterra)
library(here)

#Set directory and source file----
here()
source("../parameters.R")


#Bring in cell info----
#these files were initially created with the "04_create_grid.R" script
cells<-rast(paste0("../output/cell_information/cell_raster_", data_version, ".tif"))
countries_proj <- read_sf(paste0("../output/cell_information/country_outlines_", data_version, ".shp"))

all(st_is_valid(countries_proj)) 
print("^^^^Note to reader: make sure country vectors are valid.")


st_crs(cells) # == st_crs(countries_proj)
st_crs(countries_proj) #user input different so not techincally matching?
print("^^^^Note to reader: check if cell raster projection matches country projection. ")


##Convert cell raster to a vector----
cells_vector <- as.polygons(cells)
all(is.valid(cells_vector))
print("^^^^Note to reader: if TRUE above, all cell polygons are valid")


#Overall cells available----
#bring in data
overall_cell_data <- read.csv(paste0("../output/exploratory_analyses/data_availability/atleast_", overall_lists, "_lists_", data_version, ".csv"))
summary(overall_cell_data)
print("^^^^Note to reader: overall cells' data above.")

#tally years per cell
years_per_cell <- overall_cell_data %>%
  group_by(cell)%>%
  tally()
names(years_per_cell)[2] <- "years_avail" 

full_grid <- data.frame(values(cells))
names(full_grid) <- "cell"

full_grid_years <- merge(full_grid, years_per_cell, all.x = T, by = "cell")
summary(full_grid_years)

cell_years <- cells
values(cell_years) <- full_grid_years$years_avail

#Plot overall cells----
print("^^^^Note to reader: creating overall cells figure")
 png(paste0("../output/exploratory_analyses/data_availability/overall_cells_", data_version, ".png" ), width = 1000, height = 700)
 

ggplot()+
  geom_spatraster(data = cell_years)+
  geom_spatvector(data = countries_proj, fill = NA )+
  geom_spatvector(data = cells_vector, fill = NA)+
  scale_fill_viridis_c(na.value = "white")+
  labs(fill = "# of Years with\nAdequate\nData Availability")+
  theme_void()+
  theme(legend.key.size = unit(1, 'cm'), #change legend key size
      legend.key.height = unit(1, 'cm'), #change legend key height
      legend.key.width = unit(1, 'cm'), #change legend key width
      legend.title = element_text(size=20), #change legend title font size
      legend.text = element_text(size=15)) #change legend text font size

dev.off()

#make vector of available cells----
available_cells_vector <- as.polygons(cell_years, dissolve = FALSE)
all(is.valid(available_cells_vector))
print("^^^^Note to reader: if TRUE above, all polygons of available cells are valid.")


available_cells_df <- full_grid_years %>%
  filter(years_avail > 0)
summary(available_cells_df)
print("^^^^Note to reader: years_avail should be greater than 0")


#loop to create combo dataframe----
#forloop prep
print("^^^^Note to reader: Prepping forloop to tally years per cell per species.")

df_length <- length(alpha_codes)*length(years_included)*nrow(available_cells_df)
combined_df <- data.frame(species = rep(NA, df_length),
                                  cell = rep(NA, df_length),
                                  year = rep(NA, df_length))
print(head(combined_df))

counter <- 1

#forloop start
for(i in 1:length(alpha_codes)){

  print(paste0("^^^^Note to reader: currently viewing ", alpha_codes[i], "'s file."))

  #read in data
  species_data <- read.csv(paste0("../data/removed_specific/specific_cells_", alpha_codes[i], "_", data_version, ".csv"))
  print(summary(species_data))

  #group by cell and year
  cell_year_combos <- species_data %>%
    group_by(cell, year) %>%
    tally() %>%
    ungroup()
  print(cell_year_combos)

  for(j in 1:nrow(cell_year_combos)){

  combined_df$cell[counter] <- cell_year_combos$cell[j]
  combined_df$year[counter] <- cell_year_combos$year[j]
  combined_df$species[counter] <- alpha_codes[i]

  counter <- counter + 1

  }

}

summary(combined_df)
summary(as.factor(combined_df$species))
print("^^^^Note to reader: should contain all species. Will still have rows with NA's left over")

combined_df2 <- na.omit(combined_df)
summary(combined_df2)
summary(as.factor(combined_df2$species))
print("^^^^Note to reader: All NA's removed. species numbers shouldn't change.")


write.csv(combined_df2,paste0("../output/exploratory_analyses/data_availability/final_combos_", data_version, ".csv"), row.names = F)



#Species-specific figures for loop----
print("^^^^Note to reader: starting for loop for species-specific cell figures.")

for(i in 1:length(alpha_codes)){

  print(paste0("^^^^Note to reader: currently viewing ", alpha_codes[i], "'s file."))

  #final cells species maps----

  specific_cells <- combined_df2%>%
    filter(species == alpha_codes[i])

  print(summary(specific_cells))
  print(summary(as.factor(specific_cells$species)))
  print("^^^^Note to reader: should only see one species")

  years_per_cell_spec <- specific_cells %>%
    group_by(cell) %>%
    tally()

  names(years_per_cell_spec)[2] <- "years_avail"

  print(years_per_cell_spec)
  print(summary(years_per_cell_spec))
  print("^^^^Note to reader: shouldn't be any year_avail greater than number of years included.")

  full_grid_spec <- data.frame(values(cells))
  names(full_grid_spec) <- "cell"

  full_grid_years_spec <- merge(full_grid_spec, years_per_cell_spec, all.x = T, by = "cell")
  print(summary(full_grid_years_spec))
  print("^^^^Note to reader: NA's should be greater than or equal to number of NA's from overall cell data summary")

  cell_years_spec <- cells
  values(cell_years_spec) <- full_grid_years_spec$years_avail

  print("creating plot 1")

  png(paste0("../output/exploratory_analyses/data_availability/final_cells_", alpha_codes[i], "_", data_version, ".png" ), width = 1000, height = 800)

 print(ggplot()+
    geom_spatraster(data = cell_years_spec)+
    geom_spatvector(data = countries_proj, fill = NA )+
    geom_spatvector(data = available_cells_vector, fill = NA)+
    scale_fill_viridis_c(na.value = "white")+
    labs(fill = "# of Years\nAvailable\nfor Analysis", title = paste0(common_names[i], "'s Final Cells"))+
    theme_void()+
    theme(legend.key.size = unit(1, 'cm'), #change legend key size
          legend.key.height = unit(1, 'cm'), #change legend key height
          legend.key.width = unit(1, 'cm'), #change legend key width
          legend.title = element_text(size=20), #change legend title font size
          legend.text = element_text(size=15),
          plot.title = element_text(size=25)) #change legend text font size
  )

  dev.off()


  #Map year round cells----
  #read in year round data
  yearround_data <- read.csv(paste0("../output/exploratory_analyses/year_round/yearround_cells_", alpha_codes[i], "_", data_version, ".csv"))

  #tally year-round years per cell
  yearround_sums <- yearround_data %>%
    group_by(cell) %>%
    tally()

  names(yearround_sums)[2] <- "years_resident"
  
  #create full cell list
  full_grid_resident <- data.frame(values(cells))
  names(full_grid_resident) <- "cell"

  #merge to fill in number of year round cells per year
  full_grid_resident_years <- merge(full_grid_resident, yearround_sums, all.x = T, by = "cell")
  print(summary(full_grid_resident_years))
  print("^^^^Note to reader: Year round data. NA's should be greater than or equal to number of NA's from overall cell data summary")

  #create raster
  year_round_raster <- cells
  values(year_round_raster) <- full_grid_resident_years$years_resident

  print("creating plot 2")
  
  png(paste0("../output/exploratory_analyses/year_round/yero_cells_", alpha_codes[i], "_", data_version, ".png" ), width = 1000, height = 800)
  
  print(ggplot()+
    geom_spatraster(data = year_round_raster)+
    geom_spatvector(data = countries_proj, fill = NA )+
    geom_spatvector(data = available_cells_vector, fill = NA)+
    scale_fill_viridis_c(na.value = "white")+
    labs(fill = "# of Years\nConsidered\nYear-Round", title = paste0(common_names[i], " Year-Round"))+
    theme_void()+
    theme(legend.key.size = unit(1, 'cm'), #change legend key size
          legend.key.height = unit(1, 'cm'), #change legend key height
          legend.key.width = unit(1, 'cm'), #change legend key width
          legend.title = element_text(size=20), #change legend title font size
          legend.text = element_text(size=15),
          plot.title = element_text(size=25)) #change legend text font size
  )

  dev.off()

  #Map cells meeting data requirement----
  #read in year round data
  range_data <- read.csv(paste0("../output/exploratory_analyses/data_availability/atleast_", species_present_days, "_", alpha_codes[i], "_", data_version, ".csv"))
  
  #tally year-round years per cell
  range_sums <- range_data %>%
    group_by(cell) %>%
    tally()
  
  names(range_sums)[2] <- "years_avail"
  
  #create full cell list
  full_grid_range <- data.frame(values(cells))
  names(full_grid_range) <- "cell"
  
  #merge to fill in number of year round cells per year
  full_grid_range_years <- merge(full_grid_range, range_sums, all.x = T, by = "cell")
  print(summary(full_grid_range_years))
  print("^^^^Note to reader: data availability data. NA's should be greater than or equal to number of NA's from overall cell data summary")
  
  #create raster
  range_raster <- cells
  values(range_raster) <- full_grid_range_years$years_avail
  
  print("creating plot 3")
  
  png(paste0("../output/exploratory_analyses/data_availability/range_", alpha_codes[i], "_", data_version, ".png" ), width = 1000, height = 800)
  
  print(ggplot()+
          geom_spatraster(data = range_raster)+
          geom_spatvector(data = countries_proj, fill = NA )+
          geom_spatvector(data = available_cells_vector, fill = NA)+
          scale_fill_viridis_c(na.value = "white")+
          labs(fill = "# of Years\nMeeting Data\nRequirement", title = paste0(common_names[i], " Available Cells"))+
          theme_void()+
          theme(legend.key.size = unit(1, 'cm'), #change legend key size
                legend.key.height = unit(1, 'cm'), #change legend key height
                legend.key.width = unit(1, 'cm'), #change legend key width
                legend.title = element_text(size=20), #change legend title font size
                legend.text = element_text(size=15),
                plot.title = element_text(size=25)) #change legend text font size
  )
  
  dev.off()
  
  #Map proportion of year round ----
  #read in year round data
  prop_data <- read.csv(paste0("../output/exploratory_analyses/year_round/prop_yero_", alpha_codes[i], "_", data_version, ".csv"))
  
  print(head(prop_data))
  print(" head of prop_data")
  
  #create full cell list
  full_grid_prop <- data.frame(values(cells))
  names(full_grid_prop) <- "cell"
  
  #merge to fill in number of year round cells per year
  full_grid_prop_years <- merge(full_grid_prop, prop_data, all.x = T, by = "cell")
  print(summary(full_grid_prop_years))
  print("^^^^Note to reader: Proportion data. NA's should be greater than or equal to number of NA's from overall cell data summary")
  
  #create raster
  prop_raster <- cells
  values(prop_raster) <- full_grid_prop_years$prop_yero
  
  print("creating plot 4")
  
  png(paste0("../output/exploratory_analyses/year_round/prop_yero_", alpha_codes[i], "_", data_version, ".png" ), width = 1000, height = 800)
  
  print(ggplot()+
          geom_spatraster(data = prop_raster)+
          geom_spatvector(data = countries_proj, fill = NA )+
          geom_spatvector(data = available_cells_vector, fill = NA)+
          scale_fill_gradient(na.value = "white", high = "#ff0000", low = "#ffebeb")+
          labs(fill = "Proportion\nof Years\n Year-Round", title = paste0(common_names[i], " Proportion Year-Round"))+
          theme_void()+
          theme(legend.key.size = unit(1, 'cm'), #change legend key size
                legend.key.height = unit(1, 'cm'), #change legend key height
                legend.key.width = unit(1, 'cm'), #change legend key width
                legend.title = element_text(size=20), #change legend title font size
                legend.text = element_text(size=15),
                plot.title = element_text(size=25)) #change legend text font size
  )
  
  dev.off()
  
  #Make histogram of proportions----
  
  breaks <- seq(0, 1, by = 0.1)
  labels <- breaks[-length(breaks)] + diff(breaks) / 2
  prop_hist <- prop_data %>%
    mutate(prop_bins = cut(prop_yero,
                          breaks = breaks,
                          labels = labels,
                          include.lowest = TRUE),
           prop_bins = as.numeric(as.character(prop_bins))) %>%
    group_by(prop_bins) %>%
    summarise(n_checklists = n())
  
  print(prop_hist)
  print("^^^^Note to reader: binned histogram data")
  
  print("creating plot 5")
  
  png(paste0("../output/exploratory_analyses/year_round/prop_hist_", alpha_codes[i], "_", data_version, ".png"), width = 1000, height = 375)
  
  #create histogram of duration of checklists
  g_prop_hist <- ggplot(prop_hist) +
    aes(x = prop_bins, y = n_checklists) +
    geom_segment(aes(xend = prop_bins, y = 0, yend = n_checklists),
                 color = "grey50") +
    geom_point() +
    scale_x_continuous(breaks = breaks) +
    # scale_y_continuous(labels = scales::comma) +
    labs(x = "Proportion of Years Year-Round",
         y = "Number of Cells",
         title = paste0("Distribution of year-round proportions in ", common_names[i], "'s Cells"))+
    theme(text = element_text(size=20)) #change text font size
  
  print(g_prop_hist)
  
  dev.off()
  
  
}

print("script complete")








  
