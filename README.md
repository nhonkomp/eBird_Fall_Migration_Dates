# eBird_Fall_Migration_Dates
This repository creates a dataset of modelled fall migration dates for a pre-determined list of species using eBird data. Additional outcomes include visual assessments of effort variabels and spatiotemporal data availability. The resulting data set can be used in analyses performed in this repository: _________.

The code in this repository requires access to a computer cluster with R installed and access to R and Rstudio on a local device. All data management, analyses, and visualizations are produced with R. Submission scripts used for running the R scripts on a cluster computer are provided as examples. These must be updated to match your system prior to running. 

Large portions of this code are based off of the scripts in this repository: https://github.com/phenomismatch/Bird_Phenology , Accessed between June 2022 and June 2025."Copyright (c) 2019 Casey Youngflesh" is included at the top of scripts containing substantial portions of the original code.

## Usage Instructions
The following is a brief description of how to use this code. More descriptive instructions are provided in the script annotations. Always review outputs to ensure code ran as expected.

Before you start:
- obtain the eBird Basic Dataset (EBD) and Sampling Event Data (SED) for the years and locations of interest (eBird, 2021). EBD files must separated by species (i.e. one download per species).
- obtain access to a cluster computing system or high performance computer. Modify the files in the "sh_files" folder to match your system.
- Update the parameters.R script to match the species, years, and locations of interest.
 
1. Run /scripts/Run_locally/00_set_up_local.R on the local device.
2. Place extracted EBD and SED data files (.txt format) into /data/raw.
3. Run /scripts/Run_on_HPC/00_set_up_borah.R on the cluster computer.
4. Transfer the files in /scripts/Run_on_HPC/ on the local device to /scripts/ on the cluster computer. Repeat with the eBird data files and parameters.R script.
5. Run /scripts/Run_on_HPC/01_filter_species_ebds.R, .../02_zerofill_species.R, and .../03_data_cleaning.R on the cluster computer.
6. Run /scripts/Run_locally/04_create_grid.R on your local device.
7. Place the transfer the output of this script to the directory on the cluster computer.
8. Run /script/Run_on_HPC/05_assign_cell_IDs.R, .../06_removed_overall.R, .../07_effort_years.R, .../08_species_effort.R, .../09_removed_specific.R, and .../10_data_availability.R on the cluster computer.
9. 




## Citations
- eBird. 2021. eBird: An online database of bird distribution and abundance [web application]. eBird, Cornell Lab of Ornithology, Ithaca, New York. Available: http://www.ebird.org. 
- Powers, B.F., Winiarski, J.M., Requena-Mullor, J.M. and Heath, J.A. (2021), *Intra-specific variation in migration phenology of American Kestrels (Falco sparverius) in response to spring temperatures.* Ibis, 163: 1448-1456. https://doi.org/10.1111/ibi.12953
- Strimas-Mackey, M., W.M. Hochachka, V. Ruiz-Gutierrez, O.J. Robinson, E.T. Miller, T. Auer, S. Kelling, D. Fink, A. Johnston. 2020. *Best Practices for Using eBird Data*. Version 1.0. https://cornelllabofornithology.github.io/ebird-best-practices/. Cornell Lab of Ornithology, Ithaca, New York. https://doi.org/10.5281/zenodo.3620739\