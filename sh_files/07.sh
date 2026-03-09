#!/bin/bash
#SBATCH -J 07_script  # job name
#SBATCH --mail-type=ALL
#SBATCH --mail-user=norahonkomp@boisestate.edu # email when the job is done
#SBATCH -o ../logs/log_07script_%j  # output and error file name (%j expands to jobID)
#SBATCH -n 48
#SBATCH -p bsudfq            # queue (partition) -- defq, ipowerq, eduq, gpuq.
#SBATCH -t 1-00:00:00      # run time (d-hh:mm:ss)
ulimit -v unlimited
ulimit -s unlimited
ulimit -u 10000

. ~/ebird.env

/cm/shared/software/spack/opt/spack/linux-centos7-cascadelake/gcc-12.1.0/r-4.2.2-7at2r2ejr7hheltu5nz5sczgipc7f2pk/bin/Rscript ~/scratch/ebird_departure_analysis/scripts/07_effort_years.R

