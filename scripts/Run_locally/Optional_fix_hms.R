#fix problem halfmaxes

#Load packages----
library(tidyverse)
library(here)

#Set directory and Source script----
here()
source("./parameters.R")

#Create standard error function----
std.error <- function(x) sd(x, na.rm = T)/sqrt(length(na.omit(x)))

#read in complete dataset----
depart_df <- read.csv("./data/combined_halfmax_df.csv")

str(depart_df)

#read in list of problem data----
problem_list <- read.csv("./output/departures/problem_halfmaxs.csv")

str(problem_list)
summary(problem_list)

#filter to desired level of confidence----
problem_list2 <- filter(problem_list, confidence < 2)

#create blank df----
new_values <- depart_df[0,]


#for loop start

for(i in 1:nrow(problem_list2)){

#filter to species, cell, and year
single_combo <- depart_df %>%
  filter(species == problem_list2[i, 1]) %>%
  filter(cell == problem_list2[i, 2]) %>%
  filter(year == problem_list2[i, 3])

#return number of rows
print(nrow(single_combo))

#if zero, print
if(nrow(single_combo) == 0){
  print(paste0("Cannot find combo in halfmax dataset: ", problem_list2[i, 1], problem_list2[i, 2], problem_list2[i, 3]))
}

#if greater than zero, print
if(nrow(single_combo) > 1){
  print(paste0("More than one row for combo. Invalid input:"))
  print(single_combo[,c(1,2,3)])
  
}

#if 1, replace values below cut off with NA
if(nrow(single_combo) == 1){
  col_names <- colnames(single_combo)
  itr_cols <- grep('hm_iter', col_names)
  
  hm_dist <- as.numeric(single_combo[1, itr_cols])
  
  print(paste0("Old mean: ", mean(hm_dist, na.rm = T)))
  print(paste0("Old se: ", std.error(hm_dist)))
  
  cutoff <- problem_list2[i,4]
  
  hm_dist[hm_dist < cutoff] <- NA
  new_mean <- mean(hm_dist, na.rm = T)
  new_se <- std.error(hm_dist)
  new_NA <- round(sum(is.na(hm_dist))/((ITER/2)*CHAINS), 3)
  
  print(paste0("New mean: ", new_mean))
  print(paste0("New se: ", new_se))
  
  single_combo[1,itr_cols] <- hm_dist
  single_combo$mn_hm <- new_mean
  single_combo$se_hm <- new_se
  single_combo$hm_NA <- new_NA
  
  new_values <- rbind(new_values, single_combo)
  
}


#finish forloop
}

#find ones that didn't work----
problem_problems <- anti_join(problem_list2, new_values, by = c("species", "cell", "year"))
## usually typos that need to be fixed in original file
max(new_values$hm_NA)== 1
#if TRUE, likely a cutoff typo resulting in all NA's in a distribution

#remove old rows from depart_df----
depart_df <- anti_join(depart_df, problem_list2, by = c("species", "cell", "year"))

#add fixed data----
depart_df <- rbind(depart_df, new_values)
summary(depart_df[,1:24])


#write file----
write.csv(depart_df, "./data/combined_halfmax_df_fixed.csv", row.names = FALSE)

#New plots----

#Plot new se

hist(depart_df$se_hm, main = "Distribution of HalfMax Estimate Standard Error's", xlab = "Halfmax Estimate Standard Error")

#plot new hists

species_fix <- problem_list2 %>%
  pull(species) %>%
  unique()


for(i in 1:length(species_fix)){
  
  single_sp <- depart_df %>%
    filter(species == species_fix[i])
  
  print(summary(as.factor(single_sp$species)))
  
  png(paste0("./output/departures/summary_figs/fixed/depart_hist_fixed_", species_fix[i], "_", data_version, ".png" ), width = 1000, height = 700)
  
  graphics::hist(single_sp$mn_hm, xlim = c(172, 366), main = species_fix[i], xlab = "Mean Halfmax's", breaks = 20, ylim = c(0, 200))
  
  dev.off()
  
}
