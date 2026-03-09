#!/bin/bash
#SBATCH -J 00_script  # job name
#SBATCH --mail-type=ALL
#SBATCH --mail-user=norahonkomp@boisestate.edu # email when the job is done
#SBATCH -o ./log_00script_%j  # output and error file name (%j expands to jobID)
#SBATCH -n 48
#SBATCH -p bsudfq            # queue (partition) -- defq, ipowerq, eduq, gpuq.
#SBATCH -t 0-01:00:00      # run time (d-hh:mm:ss)
ulimit -v unlimited
ulimit -s unlimited
ulimit -u 10000

. ~/ebird.env

Rscript ~/scratch/ebird_departure_analysis/00_set_up_borah.R