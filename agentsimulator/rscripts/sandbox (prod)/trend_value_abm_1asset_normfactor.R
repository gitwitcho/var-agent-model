# http://code.google.com/p/systemic-risk/
# 
# Copyright (c) 2011, CIMNE and Gilbert Peffer.
# All rights reserved
#
# This software is open-source under the BSD license; see 
# http://code.google.com/p/systemic-risk/wiki/SoftwareLicense

rm(list = ls())     # clear objects
graphics.off()      # close graphics windows
library(fUtilities)  # calculation of kurtosis, skewness


###################################################################
#                                                                 #
#               'PARAMETERS' & INITIAL INFORMATION                #
#                                                                 #
###################################################################

# Setting the path to the data folder

# Set the root directory (add your path)
root.dir <- "C:/Users/llacay/eclipse"

# Build the home directory (shouldn't be necessary to change)
home.dir <- paste(root.dir, "/agentsimulator/out/trend-value-abm-simulation/normfactor/", sep="")



# Read data from csv files

# ................. 1 Fund + 1 Trend .................... #

dalFundIndicator <- 
  read.table(paste(home.dir,"list_fundIndicator_slopediffstdev_1T1F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalTrendIndicator <- 
  read.table(paste(home.dir,"list_trendIndicator_slopediffstdev_1T1F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalRatioIndicator <- 
  read.table(paste(home.dir,"list_ratioIndicator_slopediffstdev_1T1F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)


dalFundMaxPosition <- 
  read.table(paste(home.dir,"list_fundMaxPosition_slopediffstdev_1T1F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalTrendMaxPosition <- 
  read.table(paste(home.dir,"list_trendMaxPosition_slopediffstdev_1T1F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalRatioMaxPosition <- 
  read.table(paste(home.dir,"list_ratioMaxPosition_slopediffstdev_1T1F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)



# ............... 50F Funds + 50 Trends .................. #

dalFundIndicator <- 
  read.table(paste(home.dir,"list_fundIndicator_slopediffstdev_50T50F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalTrendIndicator <- 
  read.table(paste(home.dir,"list_trendIndicator_slopediffstdev_50T50F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalRatioIndicator <- 
  read.table(paste(home.dir,"list_ratioIndicator_slopediffstdev_50T50F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)


dalFundMaxPosition <- 
  read.table(paste(home.dir,"list_fundMaxPosition_slopediffstdev_50T50F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalTrendMaxPosition <- 
  read.table(paste(home.dir,"list_trendMaxPosition_slopediffstdev_50T50F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalRatioMaxPosition <- 
  read.table(paste(home.dir,"list_ratioMaxPosition_slopediffstdev_50T50F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)


dalFundMeanMaxPosition <- 
  read.table(paste(home.dir,"list_fundMeanMaxPosition_slopediffstdev_50T50F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalTrendMeanMaxPosition <- 
  read.table(paste(home.dir,"list_trendMeanMaxPosition_slopediffstdev_50T50F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalRatioMeanMaxPosition <- 
  read.table(paste(home.dir,"list_ratioMeanMaxPosition_slopediffstdev_50T50F.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)




# Parameters needed from the java files

nAssets = 1    # TODO Extract nAssets automatically from the CVS headers
nExp = 1       # TODO Extract nExp automatically from the CVS headers
nRuns <- (dim(dalFundIndicator)[1])/(nAssets*nExp)

param_file = "trend_value_abm_normfactor_50T50F"   # Parameter file for 50 Funds + 50 Trends
#param_file = "trend_value_abm_normfactor_1T1F"   # Parameter file for 1 Fund + 1 Trend



###################################################################
#                                                                 #
#               CALCULATION OF NORMALISATION FACTOR               #
#                                                                 #
###################################################################

# Histograms of FUND/TREND entry indicator and max positions, and their ratio

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
	par(mfrow=c(3,2), mar=c(3,4,3,1), oma=c(3,3,5,3))
      hist(dalFundIndicator[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="FUND ind", xlab="Entry indicator")
      hist(dalFundMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="FUND max pos", xlab="Max abs position")

      hist(dalTrendIndicator[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="TREND ind", xlab="Entry indicator")
      hist(dalTrendMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="TREND max pos", xlab="Max abs position")

      hist(dalRatioIndicator[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="Ratio FUND/TREND ind", xlab="Ratio of entry indicators")
      hist(dalRatioMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="Ratio FUND/TREND max pos", xlab="Ratio of max abs positions")
   }
   title(main="L: Distribution of mean entry indicator / R: Distribution of max position", outer = TRUE, col.main="blue", font.main=2)
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}

dev.new()

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
	par(mfrow=c(3,2), mar=c(3,4,3,1), oma=c(3,3,5,3))
      hist(dalFundMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="FUND max pos", xlab="Max abs position")
      hist(dalFundMeanMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="FUND max pos", xlab="Mean max abs position")

      hist(dalTrendMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="TREND max pos", xlab="Max abs position")
      hist(dalTrendMeanMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="TREND max pos", xlab="Mean max abs position")

      hist(dalRatioMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="Ratio FUND/TREND max pos", xlab="Ratio of max abs positions")
      hist(dalRatioMeanMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="Ratio FUND/TREND max pos", xlab="Ratio of mean max abs positions")

   }
   title(main="L: Distribution of max position of individual trade / R: Distribution of mean max position over all traders", outer = TRUE, col.main="blue", font.main=2)
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# Statistics of entry indicator and max position

summary(dalFundIndicator)
summary(dalTrendIndicator)
summary(dalRatioIndicator)

summary(dalFundMaxPosition)
summary(dalTrendMaxPosition)
summary(dalRatioMaxPosition)

summary(dalFundMeanMaxPosition)
summary(dalTrendMeanMaxPosition)
summary(dalRatioMeanMaxPosition)


# ----------------------------------------------- #