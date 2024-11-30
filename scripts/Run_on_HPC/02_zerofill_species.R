#zerofill sed with ebd's to make full presence absence datasets
#run on borah with 02.sh file, make sure all species' filtered EBD files and the 
# filtered SED file are still in the filtered data folder on borah


# Code adapted from Bre Power's code (Powers et al. 2021) and "Best Practices for Using eBird Data" (Strimas-Mackey et al. 2020) examples


print('script name: 02_zerofill_species.R')
#load packages----
library(auk)
library(here)
library(tidyverse)

#set directory and source file----
here()
source("../parameters.R")


#For loop for Zerofill----
for(i in 1:length(alpha_codes)){
  
  print(paste0("^^^^Note to reader: currently viewing ", alpha_codes[i], "'s filtered file"))
  #tells us what species is having an issue if the script fails in the middle of this loop
  
  #Read in filtered EBD and SED
  ebd_file<-paste0("../data/filtered/filtered_", alpha_codes[i], "_", data_version, ".txt")
  sed_file<- paste0("../data/filtered/filtered_sed_", data_version, ".txt")
  
  #zerofill the ebd and sed
  zf_df<-auk_zerofill(ebd_file, sed_file, collapse=T)
  #this automatically applies auk_rollup() and auk_unique(), species names will be uniform and only one copy of group lists will be included
  
  print(str(zf_df))
  print(summary(zf_df))
  print("^^^Note to reader: str() and summary() of zerofilled file.")
  
  #write new file of zerofilled dataset
  write.table(zf_df, file = paste0("../data/zerofilled/zerofilled_", alpha_codes[i], "_", data_version, ".txt"), sep="\t", row.names = F)
  
}


print('script complete')

