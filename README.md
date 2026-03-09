# eBird_Fall_Migration_Dates
This repository creates a dataset of gridded annual fall migration dates (average and standard error) for a pre-determined list of species using eBird data and Bayesian GAMMs. Additional outcomes include visual assessments of effort variabels and spatiotemporal data availability. The resulting dataset can be used in analyses performed in this repository: https://github.com/nhonkomp/Species-Specific-Weather-Effects.

The code in this repository requires access to a computer cluster with R installed and access to R and Rstudio on a local device. All data management, analyses, and visualizations are produced with R. Submission scripts used for running the R scripts on a cluster computer are provided as examples. These must be updated to match your system prior to running. 

Large portions of code in several scripts are based off the auk package Vingette (Strimas-Mackey et al., 2026) and code provided in Best Practices for Using eBird (Strimas-Mackey et al., 2020).

The majority of the code in /script/Run_on_HPC/12_gams_halfmax.R is based off this repository: https://github.com/phenomismatch/Bird_Phenology , Accessed between June 2022 and June 2025. Copyright (c) 2019 Casey Youngflesh

## Usage Instructions
The following is a brief description of how to use this code. More descriptive instructions are provided in the script annotations. Always review outputs to ensure code ran as expected.

### Before you start:
- obtain the eBird Basic Dataset (EBD) and Sampling Event Data (SED) for the years and locations of interest (eBird, 2021). EBD files must separated by species (i.e. one download per species).
- obtain access to a cluster computing system or high performance computer. Modify the files in the "sh_files" folder to match your system.
- Update the parameters.R script to match the species, years, and locations of interest.
 
### To use the code:
1. Run /scripts/Run_locally/00_set_up_local.R on the local device.
2. Place extracted EBD and SED data files (.txt format) into /data/raw.
3. Run /scripts/Run_on_HPC/00_set_up_borah.R on the cluster computer.
4. Transfer the files in /scripts/Run_on_HPC/ on the local device to /scripts/ on the cluster computer. Repeat with the eBird data files and parameters.R script.
5. Run /scripts/Run_on_HPC/01_filter_species_ebds.R, .../02_zerofill_species.R, and .../03_data_cleaning.R on the cluster computer.
6. Run /scripts/Run_locally/04_create_grid.R on your local device.
7. Place the transfer the output of this script to the directory on the cluster computer.
8. Run /script/Run_on_HPC/05_assign_cell_IDs.R, .../06_removed_overall.R, .../07_effort_years.R, .../08_species_effort.R, .../09_removed_specific.R, and .../10_data_availability.R on the cluster computer.
9. Transfer outputs from these scripts on the cluster computer to the associated directories on your local device.
10. Update the png file names in /11_refine_species.qmd on your local device and Knit this file.
11. Based on these results, refine the species list in the /parameters.R files on your local device, then transfer the updated /parameters.R file to the HPC.
12. Move the data file for each species in the refined species list from /data/removed_specific/ to /data/refined_species/ on the computer cluster.
13. Run /script/Run_on_HPC/12_gams_halfmax.R on the cluster computer. This involves subsetting the data across many jobs, potentially running one job for each species/cell/year combnation.
14. Run /script/Run_on_HPC/13_combine_halfmax.R on the cluster computer. (This creates the finalized dataset). Transfer the output files from this script to the appropriate directories on your local device.
15. Update the png file names in /14_departure_dates.qmd and Knit this file to visualize the fall migration dates produced in step 14.

NOTE: We found a handful of the GAMs that ran create plots with multiple peaks in the probability a species was observed over time. In these instances, the resulting mean fall migration dates were skewed earlier and the standard deviation of the date of halfmax distribution was elevated. Because this happened in a limited number of cases, we opted to correct this by hand. This involved reviewing the plots created by 12_gams_halfmax.R to identify GAMs that resulted in multiple peaks. We then created a csv listing each species/cell/year combination that required fixing and a date cut off date before which any halfmaxes that were calculated are considered incorrect. We then ran the /scripts/Run_locally/Manual_fix_hms.R file on our local device after script 13 but before running script 14. This script removes halfmax dates that occur before the cut off from the average fall migration date caluclation. This decrease in number of values used to caluclate an average results in a larger standard error, which reflects an increase in the uncertainty of the average fall migration date. 


## Citations
- eBird. 2021. eBird: An online database of bird distribution and abundance [web application]. eBird, Cornell Lab of Ornithology, Ithaca, New York. Available: http://www.ebird.org. 
- Powers, B.F., Winiarski, J.M., Requena-Mullor, J.M. and Heath, J.A. (2021), *Intra-specific variation in migration phenology of American Kestrels (Falco sparverius) in response to spring temperatures.* Ibis, 163: 1448-1456. https://doi.org/10.1111/ibi.12953
- Strimas-Mackey, M., W.M. Hochachka, V. Ruiz-Gutierrez, O.J. Robinson, E.T. Miller, T. Auer, S. Kelling, D. Fink, A. Johnston. 2020. *Best Practices for Using eBird Data*. Version 1.0. https://cornelllabofornithology.github.io/ebird-best-practices/. Cornell Lab of Ornithology, Ithaca, New York. https://doi.org/10.5281/zenodo.3620739\
- Strimas-Mackey M, Miller E, Hochachka W (2026). auk: eBird Data Extraction and Processing in R. R package version 0.9.1, https://cornelllabofornithology.github.io/auk/.