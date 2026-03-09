#This script fits a gam for the proportion of lists reporting the target species within each year and each cell for each species
#output: data frames of halfmax distributions and model diagnostics, png's or GAM predictions and divergent chains

#Code adapted from Bird_Phenology repository. Copyright (c) 2019 Casey Youngflesh

#make sure each species has a file in "./data/refined_species" folder
#make sure "./output/departures/halfmax_data", "./output/departures/divergent_chains", and "./output/departures/halfmax_pngs" exist

#Run the jobs.tcl to create a database of species cell year combos, then run it again to submit jobs

print('script name: 12_gams_halfmax.R')

alpha <- NA
year <- NA
cell <- NA
input <- NA
output <- NA
help <- FALSE

# parse command line arguments, and set some options if provided.
args <- commandArgs(trailingOnly = TRUE)
i <- 1
while(i <= length(args)) {
  if(args[i] == "-alpha") {
    i <- i + 1
    alpha = args[i]
  } else if(args[i] == "-cell") {
    i <- i + 1
    cell = as.integer(args[i])
  } else if(args[i] == "-year") {
    i <- i + 1
    year = as.integer(args[i])
  } else if(args[i] == "-help") {
    help <- TRUE
  } else if(is.na(input)) {
    input = args[i]
  } else if(is.na(output)) {
    output = args[i]
  }
  i <- i + 1
}
if(help) {
  s <- sprintf("10_gams_quartiles.R [-cell int] [-year int] -alpha band_code inputfile [outputfile]")
  print(s)
  quit()
}
if(is.na(output)) {
  base <- basename(input)
  output <- sprintf("../output/departures/halfmax_data/halfmax_%s_%d_%d_%s.csv", substr(base, 0, nchar(base)-4), year, cell, alpha)
}
print(alpha)
print(year)
print(cell)
print(input)
print(output)

# check for the provided alpha code in the input file name
if(!grepl(alpha, input, fixed=TRUE)) {
  print(sprintf("alpha/input file mismatch, alpha: %s, input file: %s", alpha, input))
  quit()
}

#loading packages----
library(tidyverse)
library(rstanarm)
library(rstan)
library(bayesplot)
library(here)

#Set directory and source file----
here()
source("../parameters.R")

  ## read in data----
  final_data <- read_csv(input)
  print(str(final_data))
  print(summary(final_data))
  
  #Center effort ----
  # (to make sure supplying value of 0 in post-model prediction is meaningful)
  final_data$dur_center <- scale(final_data$duration_minutes, scale = FALSE)[,1]
  
  #getting a list of the unique cell IDs to cycle through----
  cells <- final_data %>%
    distinct(cell) %>%
    pull(cell)
  
  # check if the user provided a cell via the command line
  # if they did, make sure it's in cells, if not use all cells
  if(!is.na(cell)) {
    if(!(cell %in% cells)) {
      print("cell not in data")
      quit()
    }
    cells <- c(cell)
  }
  
  years <- final_data %>%
    distinct(year) %>%
    pull(year)
  
  # same for year
  if(!is.na(year)) {
    if(!(year %in% years)) {
      print("year not in data")
      quit()
    }
    years <- c(year)
  }
  
  print(paste0("^^^^Note to reader: This script will analyze the following cells and years for ", alpha))
  print(cells)
  print(years)

  
  #empty bin creation ----
  ncell <- length(cells)
  nyr <- length(years) #not all years in all cells, so this may result in empty rows in final file
  hm_mat <- matrix(data = NA, nrow = ncell*nyr, ncol = ((ITER/2)*CHAINS))
  max_mat <- matrix(data = NA, nrow = ncell*nyr, ncol = ((ITER/2)*CHAINS))
  colnames(hm_mat) <- paste0('hm_iter_', 1:((ITER/2)*CHAINS))
  colnames(max_mat) <- paste0('max_iter_', 1:((ITER/2)*CHAINS))
  arrival_df <- data.frame(species = rep(alpha, ncell*nyr), 
                           cell = NA,
                           year = NA, 
                           max_Rhat = NA,
                           min_neff = NA,
                           mlmax = NA,
                           plmax = NA,
                           hm_NA = NA,
                           num_diverge = NA,
                           num_tree = NA,
                           num_BFMI = NA,
                           delta = NA,
                           tree_depth = NA,
                           t_iter = NA,
                           n1 = NA,
                           n0 = NA,
                           mn_hm = NA,
                           LCI_hm = NA,
                           UCI_hm = NA,
                           se_hm =NA,
                           mn_max = NA,
                           LCI_max = NA,
                           UCI_max = NA,
                           hm_mat,
                           max_mat)
  
  print("^^^^Note to reader: empty data frame created.")
  print(str(arrival_df))
  
  #create counter----
  counter <- 1
  
  #Create standard error function----
  std.error <- function(x) sd(x, na.rm = T)/sqrt(length(na.omit(x)))
  
  #start cell for-loop----
  for (j in seq_along(cells)) {
    
    ## filter down to a specific cell----
    cell_loop_data <- final_data %>%
      filter(cell == cells[j])
    
    
    print(paste0("^^^^Note to reader:  ", length(years), " years will be analyzed in cell ", cells[j], " for ", alpha))
  
    # start year for-loop----
    #now loop through each year for that particular cell
    for (k in seq_along(years)) {
      
      ###filter down to a particular year----
      year_loop_data <- cell_loop_data %>%
        filter(year == years[k])
      
     
      print(summary(year_loop_data))
      print("^^^^Note to reader: Make sure only one cell and one year included. Day of year between 173 and 366.")
      
      #Record initial metrics----
      #number of surveys where species was detected
      n1 <- sum(year_loop_data$species_observed)
      #number of surveys where species was not detected
      n0 <- sum(year_loop_data$species_observed == 0)
      
      arrival_df$n1[counter] <- n1
      arrival_df$n0[counter] <- n0
      arrival_df$cell <- cells[j]
      arrival_df$year <- years[k]
  
      DELTA <- delta_start #start with default delta
      
      #Fit GAM with Rstanarm----
      fit <- rstanarm::stan_gamm4(species_observed ~ s(day_of_year, k = 30) + dur_center,
                                   data = year_loop_data,
                                   family = binomial(link = "logit"),
                                   algorithm = 'sampling',
                                   iter = ITER,
                                   chains = CHAINS,
                                   cores = CHAINS,
                                   adapt_delta = DELTA,
                                   control = list(max_treedepth = TREE_DEPTH), 
                                    prior = normal(location = 0, scale = NULL),
                                    prior_intercept = normal(location = 0, scale = NULL), 
                                    prior_ops = prior_options(prior_scale_for_dispersion = 5, min_prior_scale = 1e-12, scaled = TRUE),
                                    prior_covariance = decov(regularization = 1, concentration = 1, shape = 1, scale = 1), 
                                    prior_PD = FALSE)
      #### explicitly stated rstanarm prior defaults in case they change
      
      #calculate diagnostics----
      num_diverge <- rstan::get_num_divergent(fit$stanfit)
      num_tree <- rstan::get_num_max_treedepth(fit$stanfit)
      num_BFMI <- length(rstan::get_low_bfmi_chains(fit$stanfit))
      
      #rerun model if divergences occurred----
      while (num_diverge > 0 & DELTA <= 0.98)
      {
        DELTA <- DELTA + 0.01
        print(paste0("^^^^Note to reader: chains diverged, running again with delta = ", DELTA))
        
        fit <- rstanarm::stan_gamm4(species_observed ~ s(day_of_year, k = 30) + dur_center,
                                     data = year_loop_data,
                                     family = binomial(link = "logit"),
                                     algorithm = 'sampling',
                                     iter = ITER,
                                     chains = CHAINS,
                                     cores = CHAINS,
                                     adapt_delta = DELTA,
                                     control = list(max_treedepth = TREE_DEPTH), 
                                    prior = normal(location = 0, scale = NULL),
                                    prior_intercept = normal(location = 0, scale = NULL), 
                                    prior_ops = prior_options(prior_scale_for_dispersion = 5, min_prior_scale = 1e-12, scaled = TRUE),
                                    prior_covariance = decov(regularization = 1, concentration = 1, shape = 1, scale = 1), 
                                    prior_PD = FALSE)
        
        num_diverge <- rstan::get_num_divergent(fit$stanfit)
        num_tree <- rstan::get_num_max_treedepth(fit$stanfit)
        num_BFMI <- length(rstan::get_low_bfmi_chains(fit$stanfit))
        
        saveRDS(fit,paste0("../output/departures/divergent_chains/diverge_fit_", alpha,"_", cell[j], "_", year[k], "_delta_", DELTA, ".RDS") )
        print(paste0("saved model object for delta= ", DELTA))
        
      }
      
      max_Rhat <- round(max(summary(fit)[, 'Rhat']), 2)
      min_neff <- min(summary(fit)[, 'n_eff'])
      
      arrival_df$num_diverge[counter] <- num_diverge
      arrival_df$num_tree[counter] <- num_tree
      arrival_df$num_BFMI[counter] <- num_BFMI
      arrival_df$delta[counter] <- DELTA
      arrival_df$tree_depth[counter] <- TREE_DEPTH
      arrival_df$t_iter[counter] <- ITER
      arrival_df$max_Rhat[counter] <- max_Rhat
      arrival_df$min_neff[counter] <- min_neff
      
      #generate prediction data----
      predictDays <- range(year_loop_data$day_of_year)[1]:range(year_loop_data$day_of_year)[2]
      newdata <- data.frame(day_of_year = predictDays, dur_center = 0)
      
      print(paste0("^^^^Note to reader: getting ready to predict response from model fit. Predicting off of data with following summary: "))
      print(summary(newdata))
      
      #predict response----
      dfit <- rstanarm::posterior_epred(fit, newdata = newdata)
      halfmax_fit <- rep(NA, ((ITER/2)*CHAINS))
      max_fit <- rep(NA, ((ITER/2)*CHAINS))
      tlmax <- rep(NA, ((ITER/2)*CHAINS))
      
      #halfmax for loop----
      #day at which probability of occurrence is half local maximum value
      for (L in 1:((ITER/2)*CHAINS))
      {
        rowL <- as.vector(dfit[L,])
        # #last detection
        # ld <- max(year_loop_data$day_of_year[which(year_loop_data$species_observed == 1)])
        # #local maximum(s)
        # #from: stackoverflow.com/questions/6836409/finding-local-maxima-and-minima
        # lmax_idx <- which(diff(sign(diff(rowL))) == -2) + 1
        # lmax <- predictDays[lmax_idx]
        # #last local max to come before last detection
        # llm <- which(lmax < ld)
        # if (length(llm) > 0)
        # {
        #   #last local max to come before last detection
        #   lmax2_idx <- lmax_idx[max(llm)]
        #   lmax2 <- lmax[max(llm)]
        #   tlmax[L] <- TRUE
        # } else {
          #no local max
          lmax2_idx <- which.max(rowL)
          lmax2 <- predictDays[which.max(rowL)]
          tlmax[L] <- FALSE
        # }
        #store local max----
        max_fit[L] <- lmax2 
        
        #min after max
        lmin_idx <- which.min(rowL[lmax2_idx:length(rowL)])+lmax2_idx - 1
        lmin <- predictDays[lmin_idx]
        
        #value at local max - value at min (typically 0)
        dmm <- rowL[lmax2_idx] - rowL[lmin_idx]
        #all positions less than or equal to half diff between max and min + value min
        tlm <- which(rowL <= ((dmm/2) + rowL[lmin_idx]))
        #which of these come after max and before or at min
        vgm <- tlm[which(tlm > lmax2_idx & tlm <= lmin_idx)]
       
         #insert halfmax (NA for situations where no days met halfmax criteria)
        if (length(vgm) > 0)
        {
          halfmax_fit[L] <- predictDays[min(vgm)]
        } else {
          halfmax_fit[L] <- NA # different from Youngflesh et al. 2021
        }
      
      } #close halfmax loop----
      
      #proportion of iterations that had local max
      arrival_df$plmax[counter] <- round(sum(tlmax)/((ITER/2)*CHAINS), 3)
      
      #proportion NA's in hm's
      arrival_df$hm_NA[counter] <- round(sum(is.na(halfmax_fit))/((ITER/2)*CHAINS), 3)
      
      #model fit----
      mn_dfit <- apply(dfit, 2, mean)
      LCI_dfit <- apply(dfit, 2, function(x) quantile(x, probs = 0.025))
      UCI_dfit <- apply(dfit, 2, function(x) quantile(x, probs = 0.975))
      
      #check whether local max exists for mean model fit
      mlmax <- sum(diff(sign(diff(mn_dfit))) == -2)
      if (mlmax > 0)
      {
        arrival_df$mlmax[counter] <- TRUE
      } else {
        arrival_df$mlmax[counter] <- FALSE
      }
      
      #estimated halfmax----
      mn_hm <- mean(halfmax_fit, na.rm = T)
      LCI_hm <- quantile(halfmax_fit, probs = 0.025, na.rm = T) 
      UCI_hm <- quantile(halfmax_fit, probs = 0.975, na.rm = T) 
      se_hm <- std.error(halfmax_fit)
      
      print(paste0("^^^^Note to reader: mean halfmax = day ", mn_hm))
      
      
      #estimated max
      mn_max <- mean(max_fit)
      LCI_max <- quantile(max_fit, probs = 0.025, na.rm = T)
      UCI_max <- quantile(max_fit, probs = 0.975, na.rm = T)
      
      print(paste0("^^^^Note to reader: mean max = day ", mn_max))
      
      #save max and half max mean and CI's
      arrival_df$mn_hm[counter] <- mn_hm
      arrival_df$LCI_hm[counter] <- LCI_hm
      arrival_df$UCI_hm[counter] <- UCI_hm
      arrival_df$se_hm[counter] <- se_hm
      arrival_df$mn_max[counter] <- mn_max
      arrival_df$LCI_max[counter] <- LCI_max
      arrival_df$UCI_max[counter] <- UCI_max
      
      
      #fill df with halfmax iter
      cndf <- colnames(arrival_df)
      hm_iter_ind <- grep('hm_iter', cndf)
      arrival_df[counter, hm_iter_ind] <- halfmax_fit
      
      #fill df with max iter
      max_iter_ind <- grep('max_iter', cndf)
      arrival_df[counter, max_iter_ind] <- max_fit
      
      
      
      #PLOT MODEL FIT AND DATA----
      
      print("^^^^Note to reader: Plotting first halfmax figure")
      
      png(paste0("../output/departures/halfmax_pngs/", alpha, '_', cells[j], '_', years[k], '_departure.png'), width = 1000, height = 1000)
      
      plot(predictDays, UCI_dfit, type = 'l', col = 'red', lty = 2, lwd = 2,
           ylim = c(0, max(UCI_dfit)),
           main = paste0(alpha, '_', cells[j], '_', years[k]),
           xlab = 'Julian Day', ylab = 'Probability of occurrence')
      lines(predictDays, LCI_dfit, col = 'red', lty = 2, lwd = 2)
      lines(predictDays, mn_dfit, lwd = 2)
      dd <- year_loop_data$species_observed
      dd[which(dd == 1)] <- max(UCI_dfit)
      points(year_loop_data$day_of_year, dd, col = rgb(0,0,0,0.25))
      abline(v = mn_hm, col = rgb(0,0,1,0.5), lwd = 2)
      abline(v = LCI_hm, col = rgb(0,0,1,0.5), lwd = 2, lty = 2)
      abline(v = UCI_hm, col = rgb(0,0,1,0.5), lwd = 2, lty = 2)
      #abline(v = me_hm, col = rgb(0,1,0,0.5), lwd = 2)
      # abline(v = LCI_max, col = rgb(0,1,0,0.5), lwd = 2, lty = 2)
      # abline(v = UCI_max, col = rgb(0,1,0,0.5), lwd = 2, lty = 2)
      legend('right',
             legend = c('Model fit', 'CI fit', 'Half max', 'CI HM'),
             col = c('black', 'red', rgb(0,0,1,0.5), rgb(0,0,1,0.5)),
             lty = c(1,2,1,2), lwd = c(2,2,2,2), cex = 1.3)
      dev.off()
      
      print("^^^^Note to reader: Finished plotting first halfmax figure")
      
      # alternative visualization----
      print("^^^^Note to reader: Plotting second halfmax figure")
      
      png(paste0("../output/departures/halfmax_pngs/", alpha, '_', cells[j], '_', years[k], '_departure_realizations.png'), width = 1000, height = 1000)
      
      plot(NA, xlim = c(range(year_loop_data$day_of_year)[1], range(year_loop_data$day_of_year)[2]), 
           ylim = c(0, quantile(dfit, 0.999)),
           xlab = 'Julian Day', ylab = 'Probability of occurrence')
      for (L in 1:((ITER/2)*CHAINS))
      {
        lines(range(year_loop_data$day_of_year)[1]:range(year_loop_data$day_of_year)[2], as.vector(dfit[L,]), type = 'l', col = rgb(0,0,0,0.025))
      }
      for (L in 1:((ITER/2)*CHAINS))
      {
        abline(v = halfmax_fit[L], col = rgb(1,0,0,0.05))
      }
      
      dev.off()
      
      print("^^^^Note to reader: Finished plotting second halfmax figure")
      
      
      #Add to counter----
      counter <- counter + 1
      
      print("^^^^Note to reader: Starting next year")
      
    } # close year loop ----
    
    print("^^^^Note to reader: All years done, starting next cell")
    
  } #close cell loop ----
  
  print("^^^^Note to reader: All cells done. Writing final file.")
  
  #save halfmax dataframe----
  print(sprintf("writing output file: %s", output))
  write_csv(arrival_df, output)
  
  #save.image(sprintf("../workspace_%d.RData", cell))

print("script complete")
