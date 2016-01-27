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
home.dir <- paste(root.dir, "/agentsimulator/out/trend-value-ls-abm-simulation/normfactor/", sep="")



# Read data from csv files

# ................. 1 Fund + 1 LS .................... #

##### header FALSE to read well the first row

dalFundIndicator <- 
  read.table(paste(home.dir,"list_fundIndicator_divergence_1L1F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalLSIndicator <- 
  read.table(paste(home.dir,"list_lsIndicator_divergence_1L1F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalRatioIndicator <- 
  read.table(paste(home.dir,"list_ratioIndicator_divergence_1L1F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)


dalFundMaxPosition <- 
  read.table(paste(home.dir,"list_fundMaxPosition_divergence_1L1F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalLSMaxPosition <- 
  read.table(paste(home.dir,"list_lsMaxPosition_divergence_1L1F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalRatioMaxPosition <- 
  read.table(paste(home.dir,"list_ratioMaxPosition_divergence_1L1F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)



# ............... 50F Funds + 50 LS .................. #

##### header FALSE to read well the first row

dalFundIndicator <- 
  read.table(paste(home.dir,"list_fundIndicator_divergencestdev_50L50F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalLSIndicator <- 
  read.table(paste(home.dir,"list_lsIndicator_divergencestdev_50L50F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalRatioIndicator <- 
  read.table(paste(home.dir,"list_ratioIndicator_divergencestdev_50L50F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)


dalFundMaxPosition <- 
  read.table(paste(home.dir,"list_fundMaxPosition_divergencestdev_50L50F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalLSMaxPosition <- 
  read.table(paste(home.dir,"list_lsMaxPosition_divergencestdev_50L50F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalRatioMaxPosition <- 
  read.table(paste(home.dir,"list_ratioMaxPosition_divergencestdev_50L50F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)


dalFundMeanMaxPosition <- 
  read.table(paste(home.dir,"list_fundMeanMaxPosition_divergencestdev_50L50F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalLSMeanMaxPosition <- 
  read.table(paste(home.dir,"list_lsMeanMaxPosition_divergencestdev_50L50F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

dalRatioMeanMaxPosition <- 
  read.table(paste(home.dir,"list_ratioMeanMaxPosition_divergencestdev_50L50F.csv",sep=""),
   header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)




# Parameters needed from the java files

nAssets = 1
nExp = 1
nRuns <- (dim(dalFundIndicator)[1])/(nAssets*nExp)

param_file = "ls_value_abm_normfactor_50T50F"   # Parameter file for 50 Funds + 50 Trends
#param_file = "ls_value_abm_normfactor_1T1F"   # Parameter file for 1 Fund + 1 Trend



###################################################################
#                                                                 #
#               CALCULATION OF NORMALISATION FACTOR               #
#                                                                 #
###################################################################

# Histograms of FUND/LS entry indicator and max positions, and their ratio

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
	par(mfrow=c(3,2), mar=c(3,4,3,1), oma=c(3,3,5,3))
      hist(dalFundIndicator[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="FUND ind", xlab="Entry indicator")
      hist(dalFundMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="FUND max pos", xlab="Max abs position")

      hist(dalLSIndicator[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="LS ind", xlab="Entry indicator")
      hist(dalLSMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="LS max pos", xlab="Max abs position")

      hist(dalRatioIndicator[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="Ratio FUND/LS ind", xlab="Ratio of entry indicators")
      hist(dalRatioMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="Ratio FUND/LS max pos", xlab="Ratio of max abs positions")
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

      hist(dalLSMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="LS max pos", xlab="Max abs position")
      hist(dalLSMeanMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="LS max pos", xlab="Mean max abs position")

      hist(dalRatioMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="Ratio FUND/LS max pos", xlab="Ratio of max abs positions")
      hist(dalRatioMeanMaxPosition[[k +(e-1)*nAssets*nRuns]], freq = TRUE, col = "grey",  main="Ratio FUND/LS max pos", xlab="Ratio of mean max abs positions")

   }
   title(main="L: Distribution of max position of individual trader / R: Distribution of mean max position over all traders", outer = TRUE, col.main="blue", font.main=2)
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# Statistics of entry indicator and max position

summary(dalFundIndicator)
summary(dalLSIndicator)
summary(dalRatioIndicator)

summary(dalFundMaxPosition)
summary(dalLSMaxPosition)
summary(dalRatioMaxPosition)

summary(dalFundMeanMaxPosition)
summary(dalLSMeanMaxPosition)
summary(dalRatioMeanMaxPosition)


# ----------------------------------------------- #