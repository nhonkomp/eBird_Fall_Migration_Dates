#This script assesses the frequency of effort values and their relationship to species detection likelihood
#this is important for determining which detection variables should be included in the departure date models

#Code adapted from "Best Practices for Using eBird Data" section 2.5 (Strimas-Mackey et al. 2020).
#<https://cornelllabofornithology.github.io/ebird-best-practices/ebird.html#ebird-explore>

#Run on borah with 08.sh file
#make sure all species have files in /data/removed_overall/ folder
#make sure folders exist for each effort variable in /output/exploratory_analyses/


print('script name: 08_species_effort.R')

#load packages----
library(tidyverse)
library(here)

#set directory and source file----
here()
source("../parameters.R")


 #For-loop for species detection rates----

for(i in 1:length(alpha_codes)){

  print(paste0("^^^^Note to reader: now viewing ", alpha_codes[i], "'s file"))
  
  
  #read in cleaned data
  ebird<-read_csv(paste0("../data/removed_overall/overall_cells_", alpha_codes[i], "_", data_version, ".csv"))

  #confirm data read in properly
  print(str(ebird))
  
  ##Detection rate by time of day-----
  breaks <- 0:24
  labels <- breaks[-length(breaks)] + diff(breaks) / 2
  ebird_tod <- ebird %>% 
    mutate(tod_bins = cut(time_observations_started, 
                          breaks = breaks, 
                          labels = labels,
                          include.lowest = TRUE),
           tod_bins = as.numeric(as.character(tod_bins))) %>% 
    group_by(tod_bins) %>% 
    summarise(n_checklists = n(),
              n_detected = sum(species_observed),
              det_freq = mean(species_observed))  
  
  print(head(ebird_tod))
 
  png(paste0("../output/exploratory_analyses/time_of_day/tod_", alpha_codes[i], "_detection.png"), width = 1000, height = 375)
  
 
  #create plot of frequency of detection by time of day
  g_tod_freq <- ggplot(ebird_tod %>% filter(n_checklists > 100)) +
    aes(x = tod_bins, y = det_freq) +
    geom_line() +
    geom_point() +
    scale_x_continuous(breaks = seq(0, 24, by = 3), limits = c(0, 24)) +
    scale_y_continuous(labels = scales::percent) +
    labs(x = "Hours since midnight",
         y = "% checklists with detections",
         title = paste0(common_names[i]," detection frequency"))+
    theme(text = element_text(size=20)) #change text font size
  
  print(g_tod_freq)
  
  dev.off()
  

  #Detection rate by duration----
  breaks <- seq(0, 5, by = 0.5)
  labels <- breaks[-length(breaks)] + diff(breaks) / 2
  ebird_dur <- ebird %>%
    mutate(dur_bins = cut(duration_minutes / 60,
                          breaks = breaks,
                          labels = labels,
                          include.lowest = TRUE),
           dur_bins = as.numeric(as.character(dur_bins))) %>%
    group_by(dur_bins) %>%
    summarise(n_checklists = n(),
              n_detected = sum(species_observed),
              det_freq = mean(species_observed))

  print(head(ebird_dur))
  
  png(paste0("../output/exploratory_analyses/duration/dur_", alpha_codes[i], "_detection.png"), width = 1000, height = 375)
  
 
  #create plot of frequency of detection by duration of checklist
  g_dur_freq <- ggplot(ebird_dur %>% filter(n_checklists > 100)) +
    aes(x = dur_bins, y = det_freq) +
    geom_line() +
    geom_point() +
    scale_x_continuous(breaks = 0:5) +
    scale_y_continuous(labels = scales::percent) +
    labs(x = "Checklist duration (hours)",
         y = "% checklists with detections",
         title = paste0(common_names[i], " detection frequency"))+
    theme(text = element_text(size=20)) #change text font size
  
  
  print(g_dur_freq)
  
  dev.off()
  
  
  

  #Detection rate by distance traveled ----
  breaks <- seq(0, 5, by = 0.5)
  labels <- breaks[-length(breaks)] + diff(breaks) / 2
  ebird_dist <- ebird %>%
    mutate(dist_bins = cut(effort_distance_km,
                           breaks = breaks,
                           labels = labels,
                           include.lowest = TRUE),
           dist_bins = as.numeric(as.character(dist_bins))) %>%
    group_by(dist_bins) %>%
    summarise(n_checklists = n(),
              n_detected = sum(species_observed),
              det_freq = mean(species_observed))

  print(head(ebird_dist))
  
  png(paste0("../output/exploratory_analyses/distance/dist_", alpha_codes[i], "_detection.png"), width = 1000, height = 375)
  
 
  #create plot of frequency of detection by distance of checklist
  g_dist_freq <- ggplot(ebird_dist %>% filter(n_checklists > 100)) +
    aes(x = dist_bins, y = det_freq) +
    geom_line() +
    geom_point() +
    scale_x_continuous(breaks = 0:5) +
    scale_y_continuous(labels = scales::percent) +
    labs(x = "Distance travelled (km)",
         y = "% checklists with detections",
         title = paste0(common_names[i]," detection frequency"))+
    theme(text = element_text(size=20)) #change text font size
  

  print(g_dist_freq)
  
  dev.off()
  
  

  #Detection rate by number of observers----
  breaks <- 0:10
  labels <- 1:10
  ebird_obs <- ebird %>%
    mutate(obs_bins = cut(number_observers,
                          breaks = breaks,
                          label = labels,
                          include.lowest = TRUE),
           obs_bins = as.numeric(as.character(obs_bins))) %>%
    group_by(obs_bins) %>%
    summarise(n_checklists = n(),
              n_detected = sum(species_observed),
              det_freq = mean(species_observed))

  print(head(ebird_obs))
  
  png(paste0("../output/exploratory_analyses/number_observers/obs_", alpha_codes[i], "_detection.png"), width = 1000, height = 375)
  
  
  #create plot of frequency of detection by number of observers per checklist
  g_obs_freq <- ggplot(ebird_obs %>% filter(n_checklists > 100)) +
    aes(x = obs_bins, y = det_freq) +
    geom_line() +
    geom_point() +
    scale_x_continuous(breaks = 1:10) +
    scale_y_continuous(labels = scales::percent) +
    labs(x = "# observers",
         y = "% checklists with detections",
         title = paste0(common_names[i]," detection frequency"))+
    theme(text = element_text(size=20)) #change text font size
  
 
  print(g_obs_freq)
  
  dev.off()
  
  print("^^^^Note to reader: all four figures created")

}
 
 # Effort Histograms----
 
 
 #Using last species' data, should be the same for all and "species_observed" not relevant
 print(str(ebird))
 
 ##Detection rate by time of day-----
 breaks <- 0:24
 labels <- breaks[-length(breaks)] + diff(breaks) / 2
 ebird_tod <- ebird %>% 
   mutate(tod_bins = cut(time_observations_started, 
                         breaks = breaks, 
                         labels = labels,
                         include.lowest = TRUE),
          tod_bins = as.numeric(as.character(tod_bins))) %>% 
   group_by(tod_bins) %>% 
   summarise(n_checklists = n(),
             n_detected = sum(species_observed), #species observed not needed but I left it to avoid breaking things temporarily
             det_freq = mean(species_observed))  
 
 print(head(ebird_tod))
 
 #using "aaaa" in place of alpha code so these come alphabetically first in the folders
 png(paste0("../output/exploratory_analyses/time_of_day/tod_aaaa_frequency.png"), width = 1000, height = 375)
 
 #create histogram of lists by time of day
 g_tod_hist <- ggplot(ebird_tod) +
   aes(x = tod_bins, y = n_checklists) +
   geom_segment(aes(xend = tod_bins, y = 0, yend = n_checklists),
                color = "grey50") +
   geom_point() +
   scale_x_continuous(breaks = seq(0, 24, by = 3), limits = c(0, 24)) +
   scale_y_continuous(labels = scales::comma) +
   labs(x = "Hours since midnight",
        y = "# checklists",
        title = "Distribution of observation start times")+
   theme(text = element_text(size=20)) #change text font size
 
 print(g_tod_hist)
 
 dev.off()
 
 #Detection rate by duration----
 breaks <- seq(0, 5, by = 0.5)
 labels <- breaks[-length(breaks)] + diff(breaks) / 2
 ebird_dur <- ebird %>%
   mutate(dur_bins = cut(duration_minutes / 60,
                         breaks = breaks,
                         labels = labels,
                         include.lowest = TRUE),
          dur_bins = as.numeric(as.character(dur_bins))) %>%
   group_by(dur_bins) %>%
   summarise(n_checklists = n(),
             n_detected = sum(species_observed),
             det_freq = mean(species_observed))
 
 print(head(ebird_dur))
 
 png(paste0("../output/exploratory_analyses/duration/dur_aaaa_frequency.png"), width = 1000, height = 375)
 
 #create histogram of duration of checklists
 g_dur_hist <- ggplot(ebird_dur) +
   aes(x = dur_bins, y = n_checklists) +
   geom_segment(aes(xend = dur_bins, y = 0, yend = n_checklists),
                color = "grey50") +
   geom_point() +
   scale_x_continuous(breaks = 0:5) +
   scale_y_continuous(labels = scales::comma) +
   labs(x = "Checklist duration (hours)",
        y = "# checklists",
        title = "Distribution of checklist durations")+
   theme(text = element_text(size=20)) #change text font size
 
 print(g_dur_hist)
 
 dev.off()
 
 #Detection rate by distance traveled ----
 breaks <- seq(0, 5, by = 0.5)
 labels <- breaks[-length(breaks)] + diff(breaks) / 2
 ebird_dist <- ebird %>%
   mutate(dist_bins = cut(effort_distance_km,
                          breaks = breaks,
                          labels = labels,
                          include.lowest = TRUE),
          dist_bins = as.numeric(as.character(dist_bins))) %>%
   group_by(dist_bins) %>%
   summarise(n_checklists = n(),
             n_detected = sum(species_observed),
             det_freq = mean(species_observed))
 
 print(head(ebird_dist))
 
 png(paste0("../output/exploratory_analyses/distance/dist_aaaa_frequency.png"), width = 1000, height = 375)
 
 #create histogram of distance of checklist
 g_dist_hist <- ggplot(ebird_dist) +
   aes(x = dist_bins, y = n_checklists) +
   geom_segment(aes(xend = dist_bins, y = 0, yend = n_checklists),
                color = "grey50") +
   geom_point() +
   scale_x_continuous(breaks = 0:5) +
   scale_y_continuous(labels = scales::comma) +
   labs(x = "Distance travelled (km)",
        y = "# checklists",
        title = "Distribution of distance travelled")+
   theme(text = element_text(size=20)) #change text font size
 
 print(g_dist_hist)
 
 dev.off()
 
 #Detection rate by number of observers----
 breaks <- 0:10
 labels <- 1:10
 ebird_obs <- ebird %>%
   mutate(obs_bins = cut(number_observers,
                         breaks = breaks,
                         label = labels,
                         include.lowest = TRUE),
          obs_bins = as.numeric(as.character(obs_bins))) %>%
   group_by(obs_bins) %>%
   summarise(n_checklists = n(),
             n_detected = sum(species_observed),
             det_freq = mean(species_observed))
 
 print(head(ebird_obs))
 
 png(paste0("../output/exploratory_analyses/number_observers/obs_aaaa_frequency.png"), width = 1000, height = 375)
 
 #create histogram of number of observers per checklist
 g_obs_hist <- ggplot(ebird_obs) +
   aes(x = obs_bins, y = n_checklists) +
   geom_segment(aes(xend = obs_bins, y = 0, yend = n_checklists),
                color = "grey50") +
   geom_point() +
   scale_x_continuous(breaks = 1:10) +
   scale_y_continuous(labels = scales::comma) +
   labs(x = "# observers",
        y = "# checklists",
        title = "Distribution of the number of observers")+
   theme(text = element_text(size=20)) #change text font size
 
 print(g_obs_hist)
 
 dev.off()
 
 

print("script complete")
