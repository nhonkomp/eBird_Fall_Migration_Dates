library(geoR)
library(tidyverse)
library(brms)

source("./parameters.R")

#Make functions----
## functions from Peter
plot.gd <- function(data.gd, col=T){
  if(col){
    points(data.gd, col=rev(heat.colors(12)), xlab=NA, ylab=NA)
  }
  if(!col){
    points(data.gd, col="grey", xlab=NA, ylab=NA)
  }
}


variog.508 <- function(data.gd, nbins=20, max.dist=NA, type="class", pairs.min = 10, plots=F){
  library(geoR)
  if(is.na(max.dist)){
    max.dist <- 0.5*max(dist(data.gd$coords)) # max.dist = half maximum distance
  }
  if(type=="class"){
    type = "classical"
  }
  if(type=="mod"){
    type = "modulus"
  }
  data.vg <- variog(data.gd, max.dist=max.dist, uvec = nbins, pairs.min=pairs.min, option="bin", estimator.type=type, messages=F)
  
  if(plots){
    plot.vg(data.vg, err=T)
  }
  return(data.vg)
}


plot.vg <- function(data.vg, err=F, pairs=T) {
  library(geoR)
  plot(data.vg,pch=16, col="darkblue",cex=1.2, xlab="lag distance (h)",ylab="gamma")
  
  if(err){
    #library(Hmisc)
    yup <- data.vg$v + 1.96*sqrt(2)*data.vg$v/sqrt(data.vg$n)
    ydn <- data.vg$v - 1.96*sqrt(2)*data.vg$v/sqrt(data.vg$n)
    arrows(x0=data.vg$u, y0=ydn, x1=data.vg$u, y1=yup, code=3, angle=90, length=0.05, col = "darkblue")
    if(pairs){
      text(data.vg$u, data.vg$v,labels=data.vg$n,pos=1,offset=1, cex=0.8, col="darkred", font=2)
    }
  }
}




rand.vg <- function(data.gd, data.vg, nsim=99){
  data.env<-variog.mc.env(data.gd, obj.variog=data.vg, nsim=99, messages=F)
  plot(data.vg,pch=16, col="darkblue",cex=1.2, envelope=data.env)
}


check.vg <- function(data.gd) {
  library(geoR)
  mar.default<-par("mar")  # save defaults
  par(mfrow=c(2,2), mar=c(4,4,1,0))	# sets up to plot in 2 by 2 panels with no margins  
  
  plot.gd(data.gd)   
  qqnorm(data.gd$data)
  data.vg <- variog.508(data.gd, pairs.min=1, plots=F)
  plot(variog4(data.gd, max.dist=data.vg$max.dist, messages=F), lwd=3, legend=F)
  # legend(x="bottomright", legend=c("0","45","90","135"),lty = 1:4, col=1:4, lwd=3)
  rand.vg(data.gd,data.vg,nsim-99)
  par(mfrow=c(1,1), mar=mar.default)	# returns plot in 1 panel and regular margins
  # data.lm<-lm(data.gd$data ~ data.gd$coords[,1]*data.gd$coords[,2])
  # cat("linear trend surface approximate r-squared = ",round(summary(data.lm)$adj.r.squared,2),"\n",sep="")
}
  
  #read in data---
  complete <- read.csv(paste0("./data/joined_depart_trait_data.csv"))
  summary(complete)
  
  model_name <- "all_horshoe"
  model <- readRDS(paste0("./output/trait_assessment/final/", model_name,".RDS"))
  summary(model)
  model_sp <- model$data
  residuals <- residuals(model)
  model_sp$residuals <- residuals[,1]
  
  
  single_sp <- complete %>%
    select(longitude, latitude, year)
  
  
  sim <- data.frame(longitude = single_sp$longitude, latitude = single_sp$latitude, residuals = model_sp$residuals)
  sim[,1:2] <- jitterDupCoords(sim[,1:2], max = 100000)
  sim.gd <- as.geodata(sim[,1:3]) # convert to geoR object
  
  
  png(paste0("./output/trait_assessment/final/", model_name, "_variograms.png"), width = 1000, height = 1000 )
  
  
  print(check.vg(sim.gd))
  
  dev.off()


