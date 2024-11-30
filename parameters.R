#Setting Analysis Parameters----
## The following parameters can be customized by changing the words/numbers listed. Do not change object names.

## Included Species:----
### Note- these two lists must contain information referring to the same species, in the same order.
### This information must also match the names and codes used in your version of the eBird Basic Dataset
### (i.e. capitalization, spaces, and punctuation matter)
common_names <- c("Turkey Vulture", "Red-tailed Hawk", "Osprey", "American Kestrel", "Cooper's Hawk",
                  "Northern Harrier", "Sharp-shinned Hawk", "Peregrine Falcon", "Merlin",
                  "Broad-winged Hawk", "Swainson's Hawk", "Rough-legged Hawk", "Golden Eagle",
                  "Ferruginous Hawk", "Mississippi Kite", "Swallow-tailed Kite", "Bald Eagle",
                  "Red-shouldered Hawk", "Flammulated Owl", "Burrowing Owl", "Long-eared Owl", 
                  "Short-eared Owl")

alpha_codes <- c("turvul","rethaw", "osprey", "amekes", "coohaw",
                 "norhar2", "shshaw", "perfal","merlin",
                 "brwhaw", "swahaw", "rolhaw", "goleag",
                 "ferhaw", "miskit", "swtkit", "baleag",
                 "reshaw", "flaowl", "burowl", "loeowl",
                 "sheowl")

#check that lengths are equal
length(common_names) == length(alpha_codes)
#if this says false, you are missing a species in one of the lists

#After script __, you can pick which species should remain in the analysis based on data availability.
#Start with the list from the alpha_codes object above, then remove species that you do not want to continue analyzing.
refined_species <- c("turvul","rethaw", "osprey", "amekes", "coohaw", 
                     "norhar2", "shshaw", "perfal", "merlin",
                     "brwhaw", "swahaw", "goleag",
                     "ferhaw", "miskit", "swtkit", "baleag",
                      "burowl")


## Included Years:----
### Note- Years prior to 2002 shouldn't be included in your analysis.
### Additionally, the year your data was downloaded should NOT be included in this list
###   unless you have downloaded the December version. All other versions will have  ###Check if this is true
###   incomplete data for the current year. 
years_included <- c(2002:2021) #these don't need to be continuous, you can make a list of specific years of interest


## Change SED and EBD version-----
### This will come from looking at the file names of the downloaded data 
data_version <- "relJun-2022"
# this could also be used to keep track of versions if running the analysis multiple times 
#(e.g. "relJun-2022-2" if running a second time, but input filenames may need to be changed manually when transitioning between versions)

# Included Countries: ----
countries_included <- c("US", "CA")
## These must be the country letter codes (or country names) recognized by the auk_country() filter in the auk package
countries_fullname <- c("united states of america", "canada")
#These must be the full names of countries recognized by the ne_countries() function in the rnaturalearth package
map_countries <- c("united states of america", "canada", "mexico", "greenland")
#These must be the full names of countries recognized by the ne_countries() function in the rnaturalearth package as well.
#You can include surrounding countries here so that the maps look more complete. ###Check if I left this in


#Map Projection----
projection <- '+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'
#choose an equal area projection that best encompasses your countries of interest
#can be written in several formats, just has to be something the terra and sf packages recognize as a crs (e.g. ESPG numbers will work)

#Change cell size-----
cell_size <- 300000 #units from your projection, length and width of cells (ex. this is 300km x 300km cells, because my units are meters)

#Change overall list requirements----
overall_lists <- 100 #lists
#minimum number of lists recorded in second half of the year in order 
# for a cell/year combo to be included in analysis overall

#Change species-specific requirement----
species_present_days <- 10 #days
#minimum number of days in second half of year with target species reported
## in order for cell/year combo to be included in individual species analysis

#Parameters for determining year-round species----
max_doy <- 334 #November 30th (non-leap years), days after this are considered the "year-round period"
yero_cutoff <- 0.05 #max proportion of lists reporting a species in the year-round period for a cell-year combo to remain in the species' analysis (out of 1)
prop_yero_max <- 0.4 #max proportion of years a cell can be year-round and remain in a species analysis (if the cell stays in, the year-round years are still removed)


#Bayes GAM parameters----
ITER <- 1500
CHAINS <- 4
delta_start <- 0.95
TREE_DEPTH <- 15
#these are used in script ____ for ____ function from rstanarm

#Final Species and years
## After the departure date distributions are estimated, the species list and year list can be altered here
final_years <- c(2011:2021)
final_species<- c("turvul","rethaw", "osprey", "amekes", "coohaw", 
                  "norhar2", "shshaw", "perfal", "merlin",
                  "brwhaw", "swahaw",
                  "miskit", "swtkit", "baleag",
                  "burowl")
