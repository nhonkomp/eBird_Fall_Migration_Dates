# eBird_Fall_Migration_Dates
This repository creates a dataset of modelled fall migration dates for a pre-determined list of species using eBird data. Additional outcomes include visual assessments of effort variabels and spatiotemporal data availability. The resulting data set can be used in analyses performed in this repository: _________.

The code in this repository requires access to a computer cluster with R installed and access to R and Rstudio on a local device. All data management, analyses, and visualizations are produced with R. Submission scripts used for running the R scripts on a cluster computer are provided as examples. These must be updated to match your system prior to running. 

Large portions of this code are based off of the scripts in this repository: https://github.com/phenomismatch/Bird_Phenology , Accessed between June 2022 and June 2025."Copyright (c) 2019 Casey Youngflesh" is included at the top of scripts containing substantial portions of the original code.

## Usage Instructions
The following is a brief description of how to use this code. More descriptive instructions are provided in the script annotations.

Before you start:
- obtain text files containing the eBird Basic Dataset (EBD) and Sampling Event Data (SED) for each species, year, and location of interest (eBird, 2021).
- obtain access to a cluster computing system or high performance computer. Modify the files in the "sh_files" folder to match your system.
 
1. Run the Scripts > Run_locally > 00_set_up_local.R file
2. 



## Citations
eBird. 2021. eBird: An online database of bird distribution and abundance [web application]. eBird, Cornell Lab of Ornithology, Ithaca, New York. Available: http://www.ebird.org. 
