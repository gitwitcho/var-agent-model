
# http://code.google.com/p/systemic-risk/
# 
# Copyright (c) 2011, CIMNE and Gilbert Peffer.
# All rights reserved
#
# This software is open-source under the BSD license; see 
# http://code.google.com/p/systemic-risk/wiki/SoftwareLicense

rm(list = ls())        # clear objects
graphics.off()         # close graphics windows
library(fUtilities)    # calculation of kurtosis, skewness
library(fractal)       # calculation of Hurst exponent
library(fBasics)       # calculation of Taylor effect
library(latticeExtra)  # plotting of horizonplot
library(evir)          # plotting of Hill tail index
library(reshape)       # plotting ggplots
library(ggplot2)
library(zoo)
library(grid)          # plotting ggplots in a grid
library(TTR)           # calculation of MA's


###################################################################
#                                                                 #
#               'PARAMETERS' & INITIAL INFORMATION                #
#                                                                 #
###################################################################

nAssets = 1
nExp = 16
liquidity = 400      # Used to plot contributions to price formation
volWindow = 20       # Window used to calculate volatility
LVar = 40            # Value of Var limit to compare it to portfolio value

# Setting the path to the data folder

# Set the root directory (add your path)
root.dir <- "C:/Users/llacay/eclipse"

# Build the home directory (shouldn't be necessary to change)
home.dir <- paste(root.dir, "/agentsimulator/out/trend-value-ls-var-abm-simulation/kk/", sep="")


# Read data from csv files for each experiment

tsprices <- read.table(paste(home.dir,"list_price_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsvalues <- read.table(paste(home.dir,"list_fundvalues_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsvolume <- read.table(paste(home.dir,"list_totalvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDvolume <- read.table(paste(home.dir,"list_fundvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDvolume <- read.table(paste(home.dir,"list_trendvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsLSvolume <- read.table(paste(home.dir,"list_lsvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDwealth <- read.table(paste(home.dir,"list_fundwealth_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDwealth <- read.table(paste(home.dir,"list_trendwealth_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsLSwealth <- read.table(paste(home.dir,"list_lswealth_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDorders <- read.table(paste(home.dir,"list_fundorders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDorders <- read.table(paste(home.dir,"list_trendorders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsLSorders <- read.table(paste(home.dir,"list_lsorders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsFUNDreducedvolume <- read.table(paste(home.dir,"list_fundreducedvolume_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsTRENDreducedvolume <- read.table(paste(home.dir,"list_trendreducedvolume_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsLSreducedvolume <- read.table(paste(home.dir,"list_lsreducedvolume_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsFUNDreducedorders <- read.table(paste(home.dir,"list_fundreducedorders_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsTRENDreducedorders <- read.table(paste(home.dir,"list_trendreducedorders_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsLSreducedorders <- read.table(paste(home.dir,"list_lsreducedorders_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDsellofforders <- read.table(paste(home.dir,"list_fundsellofforders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDsellofforders <- read.table(paste(home.dir,"list_trendsellofforders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsLSsellofforders <- read.table(paste(home.dir,"list_lssellofforders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDselloffvolume <- read.table(paste(home.dir,"list_fundselloffvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDselloffvolume <- read.table(paste(home.dir,"list_trendselloffvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsLSselloffvolume <- read.table(paste(home.dir,"list_lsselloffvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

tsFUNDvar <- read.table(paste(home.dir,"list_fundvar_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDvar <- read.table(paste(home.dir,"list_trendvar_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsLSvar <- read.table(paste(home.dir,"list_lsvar_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDstressedvar <- read.table(paste(home.dir,"list_fundstressedvar_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDstressedvar <- read.table(paste(home.dir,"list_trendstressedvar_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsLSstressedvar <- read.table(paste(home.dir,"list_lsstressedvar_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

#tsFUNDfailures <- read.table(paste(home.dir,"list_fundfailures_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsTRENDfailures <- read.table(paste(home.dir,"list_trendfailures_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsLSfailures <- read.table(paste(home.dir,"list_lsfailures_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)



if (nExp > 1) {   # Read data for single experiments and merge them
   for (e in seq(from=1, to=nExp-1)) {
      tsprices_exp <- read.table(paste(home.dir, paste("list_price_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsprices <- merge(tsprices, tsprices_exp, by="tick")

      tsvalues_exp <- read.table(paste(home.dir, paste("list_fundvalues_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsvalues <- merge(tsvalues, tsvalues_exp, by="tick")
   
      tsvolume_exp <- read.table(paste(home.dir, paste("list_totalvolume_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsvolume <- merge(tsvolume, tsvolume_exp, by="tick")

      tsFUNDvolume_exp <- read.table(paste(home.dir, paste("list_fundvolume_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDvolume <- merge(tsFUNDvolume, tsFUNDvolume_exp, by="tick")

      tsTRENDvolume_exp <- read.table(paste(home.dir, paste("list_trendvolume_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDvolume <- merge(tsTRENDvolume, tsTRENDvolume_exp, by="tick")

      tsLSvolume_exp <- read.table(paste(home.dir, paste("list_lsvolume_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsLSvolume <- merge(tsLSvolume, tsLSvolume_exp, by="tick")

      tsFUNDwealth_exp <- read.table(paste(home.dir, paste("list_fundwealth_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDwealth <- merge(tsFUNDwealth, tsFUNDwealth_exp, by="tick")

      tsTRENDwealth_exp <- read.table(paste(home.dir, paste("list_trendwealth_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDwealth <- merge(tsTRENDwealth, tsTRENDwealth_exp, by="tick")

      tsLSwealth_exp <- read.table(paste(home.dir, paste("list_lswealth_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsLSwealth <- merge(tsLSwealth, tsLSwealth_exp, by="tick")

      tsFUNDorders_exp <- read.table(paste(home.dir, paste("list_fundorders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDorders <- merge(tsFUNDorders, tsFUNDorders_exp, by="tick")

      tsTRENDorders_exp <- read.table(paste(home.dir, paste("list_trendorders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDorders <- merge(tsTRENDorders, tsTRENDorders_exp, by="tick")

      tsLSorders_exp <- read.table(paste(home.dir, paste("list_lsorders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsLSorders <- merge(tsLSorders, tsLSorders_exp, by="tick")

#      tsFUNDreducedvolume_exp <- read.table(paste(home.dir, paste("list_fundreducedvolume_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsFUNDreducedvolume <- merge(tsFUNDreducedvolume, tsFUNDreducedvolume_exp, by="tick")

#      tsTRENDreducedvolume_exp <- read.table(paste(home.dir, paste("list_trendreducedvolume_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsTRENDreducedvolume <- merge(tsTRENDreducedvolume, tsTRENDreducedvolume_exp, by="tick")

#      tsLSreducedvolume_exp <- read.table(paste(home.dir, paste("list_lsreducedvolume_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsLSreducedvolume <- merge(tsLSreducedvolume, tsLSreducedvolume_exp, by="tick")

#      tsFUNDreducedorders_exp <- read.table(paste(home.dir, paste("list_fundreducedorders_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsFUNDreducedorders <- merge(tsFUNDreducedorders, tsFUNDreducedorders_exp, by="tick")

#      tsTRENDreducedorders_exp <- read.table(paste(home.dir, paste("list_trendreducedorders_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsTRENDreducedorders <- merge(tsTRENDreducedorders, tsTRENDreducedorders_exp, by="tick")

#      tsLSreducedorders_exp <- read.table(paste(home.dir, paste("list_lsreducedorders_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsLSreducedorders <- merge(tsLSreducedorders, tsLSreducedorders_exp, by="tick")

      tsFUNDsellofforders_exp <- read.table(paste(home.dir, paste("list_fundsellofforders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDsellofforders <- merge(tsFUNDsellofforders, tsFUNDsellofforders_exp, by="tick")

      tsTRENDsellofforders_exp <- read.table(paste(home.dir, paste("list_trendsellofforders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDsellofforders <- merge(tsTRENDsellofforders, tsTRENDsellofforders_exp, by="tick")

      tsLSsellofforders_exp <- read.table(paste(home.dir, paste("list_lssellofforders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsLSsellofforders <- merge(tsLSsellofforders, tsLSsellofforders_exp, by="tick")

      tsFUNDselloffvolume_exp <- read.table(paste(home.dir, paste("list_fundselloffvolume_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDselloffvolume <- merge(tsFUNDselloffvolume, tsFUNDselloffvolume_exp, by="tick")

      tsTRENDselloffvolume_exp <- read.table(paste(home.dir, paste("list_trendselloffvolume_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDselloffvolume <- merge(tsTRENDselloffvolume, tsTRENDselloffvolume_exp, by="tick")

      tsLSselloffvolume_exp <- read.table(paste(home.dir, paste("list_lsselloffvolume_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsLSselloffvolume <- merge(tsLSselloffvolume, tsLSselloffvolume_exp, by="tick")


      tsFUNDvar_exp <- read.table(paste(home.dir, paste("list_fundvar_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDvar <- merge(tsFUNDvar, tsFUNDvar_exp, by="tick")

      tsTRENDvar_exp <- read.table(paste(home.dir, paste("list_trendvar_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDvar <- merge(tsTRENDvar, tsTRENDvar_exp, by="tick")

      tsLSvar_exp <- read.table(paste(home.dir, paste("list_lsvar_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsLSvar <- merge(tsLSvar, tsLSvar_exp, by="tick")

      tsFUNDstressedvar_exp <- read.table(paste(home.dir, paste("list_fundstressedvar_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDstressedvar <- merge(tsFUNDstressedvar, tsFUNDstressedvar_exp, by="tick")

      tsTRENDstressedvar_exp <- read.table(paste(home.dir, paste("list_trendstressedvar_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDstressedvar <- merge(tsTRENDstressedvar, tsTRENDstressedvar_exp, by="tick")

      tsLSstressedvar_exp <- read.table(paste(home.dir, paste("list_lsstressedvar_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsLSstressedvar <- merge(tsLSstressedvar, tsLSstressedvar_exp, by="tick")


#      tsFUNDfailures_exp <- read.table(paste(home.dir, paste("list_fundfailures_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsFUNDfailures <- merge(tsFUNDfailures, tsFUNDfailures_exp, by="tick")

#      tsTRENDfailures_exp <- read.table(paste(home.dir, paste("list_trendfailures_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsTRENDfailures <- merge(tsTRENDfailures, tsTRENDfailures_exp, by="tick")

#      tsLSfailures_exp <- read.table(paste(home.dir, paste("list_lsfailures_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsLSfailures <- merge(tsLSfailures, tsLSfailures_exp, by="tick")
   }
}


# Parameters needed from the java files

nRuns <- (dim(tsprices)[2] - 1)/(nAssets*nExp)
nTicks <- dim(tsprices)[1]

param_file = "trend_value_ls_var_3_assets_abm_001"  # Parameter file

# Plots are distributed in a matrix. Choose here the dimensions of the matrix

numRows <- 3  # Dimensions of matrix of plots
numCols <- 2
step <- as.integer((nRuns-1)/(numRows*numCols))*nAssets  # Selects which plots to draw if there are too many


# Change titles of dataframe columns to more descriptive ones

titles = "tick"

for (e in seq(from=1, to=nExp)) {
   for (r in seq(from=1, to=nRuns)) {
      for (a in seq(from=1, to=nAssets)) {
         titles <- append(titles, paste("E", e, "_R", r, "_A", a, sep=""))
      }
   }
}

colnames(tsprices) <- titles
colnames(tsvalues) <- titles
colnames(tsvolume) <- titles
colnames(tsFUNDvolume) <- titles
colnames(tsTRENDvolume) <- titles
colnames(tsLSvolume) <- titles
colnames(tsFUNDwealth) <- titles
colnames(tsTRENDwealth) <- titles
colnames(tsLSwealth) <- titles
colnames(tsFUNDorders) <- titles
colnames(tsTRENDorders) <- titles
colnames(tsLSorders) <- titles
#colnames(tsFUNDreducedvolume) <- titles
#colnames(tsTRENDreducedvolume) <- titles
#colnames(tsLSreducedvolume) <- titles
#colnames(tsFUNDreducedorders) <- titles
#colnames(tsTRENDreducedorders) <- titles
#colnames(tsLSreducedorders) <- titles
colnames(tsFUNDsellofforders) <- titles
colnames(tsTRENDsellofforders) <- titles
colnames(tsLSsellofforders) <- titles
colnames(tsFUNDselloffvolume) <- titles
colnames(tsTRENDselloffvolume) <- titles
colnames(tsLSselloffvolume) <- titles

titles = "tick"

for (e in seq(from=1, to=nExp)) {
   for (r in seq(from=1, to=nRuns)) {
      titles <- append(titles, paste("E", e, "_R", r, sep=""))
   }
}

colnames(tsFUNDvar) <- titles
colnames(tsTRENDvar) <- titles
colnames(tsLSvar) <- titles
colnames(tsFUNDstressedvar) <- titles
colnames(tsTRENDstressedvar) <- titles
colnames(tsLSstressedvar) <- titles
#colnames(tsFUNDfailures) <- titles
#colnames(tsTRENDfailures) <- titles
#colnames(tsLSfailures) <- titles



###################################################################
#                                                                 #
#                    [AUXILIARY CALCULATIONS]                     #
#                                                                 #
#          AVERAGE ACF's and time series (for each asset)         #
#                   - averaged over all runs -                    #
#                                                                 #
###################################################################

# ------ Calculate logarithmic prices (for returns) and values ------ #

tslogprices <- log(tsprices)
tslogprices[[1]] <- tsprices[[1]]  # The 'tick' column must not change

tslogvalues <- log(tsvalues)
tslogvalues[[1]] <- tsvalues[[1]]  # The 'tick' column must not change


# ------ Calculate exogenous, random contribution to price formation ------ #

tsrandomprices <- array(0, dim=c(nTicks, 1+nAssets*nExp*nRuns))

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         tsrandomprices[1:(nTicks-1),i+1+j*nAssets+k*nAssets*nRuns] <- diff(tsprices[[i+1+j*nAssets+k*nAssets*nRuns]])[1:(nTicks-1)] - 
 		  tsFUNDorders[1:(nTicks-1),i+1+j*nAssets+k*nAssets*nRuns]/liquidity - tsTRENDorders[1:(nTicks-1),i+1+j*nAssets+k*nAssets*nRuns]/liquidity -
              tsLSorders[1:(nTicks-1),i+1+j*nAssets+k*nAssets*nRuns]/liquidity
      }
   }
}
tsrandomprices[,1] <- tsprices[[1]]    # 'tick' column


# ------ Calculate the mean value of ACF over all runs for each asset ------ #
# Note: This is done at the beginning to avoid that auxiliary ACFs are plotted in the pdf

aux_acf <- acf(diff(tslogprices[[2]]), main="IGNORE (Auxiliary calculation)")  # Calculate how many lags R uses in the ACF plot
nlags <- length(aux_acf$acf)

mean_ACF_returns <- array(0, dim=c(nlags, nAssets*nExp)) # Arrays to store mean ACF's at each lag over all runs (for each asset and experiment)
mean_ACF_absreturns <- array(0, dim=c(nlags, nAssets*nExp)) 
mean_ACF_squaredreturns <- array(0, dim=c(nlags, nAssets*nExp))
mean_ACF_volume <- array(0, dim=c(nlags, nAssets*nExp))

stdev_ACF_returns <- array(0, dim=c(nlags, nAssets*nExp)) # Arrays to store standard deviation of ACF's at each lag over all runs (for each asset and experiment)
stdev_ACF_absreturns <- array(0, dim=c(nlags, nAssets*nExp)) 
stdev_ACF_squaredreturns <- array(0, dim=c(nlags, nAssets*nExp))
stdev_ACF_volume <- array(0, dim=c(nlags, nAssets*nExp))

Max_ACF_returns <- array(0, dim=c(nlags, nAssets*nExp)) # Arrays to store the max and min ACF at each lag over all runs (for each asset and experiment)
Min_ACF_returns <- array(0, dim=c(nlags, nAssets*nExp))
Max_ACF_absreturns <- array(0, dim=c(nlags, nAssets*nExp))
Min_ACF_absreturns <- array(0, dim=c(nlags, nAssets*nExp))
Max_ACF_squaredreturns <- array(0, dim=c(nlags, nAssets*nExp))
Min_ACF_squaredreturns <- array(0, dim=c(nlags, nAssets*nExp))
Max_ACF_volume <- array(0, dim=c(nlags, nAssets*nExp))
Min_ACF_volume <- array(0, dim=c(nlags, nAssets*nExp))

asset_ACF_matrix <- array(0, dim=c(nlags, nRuns))  # Auxiliary array to store the ACF's for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with ACF of asset i for each run
         aux_acf <- acf(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]), lag.max=nlags-1, main="IGNORE (Auxiliary calculation)") 
         asset_ACF_matrix[,j+1] = aux_acf$acf   # Store the vector of correlations
      }

      for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
         mean_ACF_returns[r,i+k*nAssets] = mean(asset_ACF_matrix[r,])
         stdev_ACF_returns[r,i+k*nAssets] = sd(asset_ACF_matrix[r,])
         Max_ACF_returns[r,i+k*nAssets] = max(asset_ACF_matrix[r,])
         Min_ACF_returns[r,i+k*nAssets] = min(asset_ACF_matrix[r,])
      }
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with ACF of asset i for each run
         aux_acf <- acf(abs(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]])), lag.max=nlags-1, main="IGNORE (Auxiliary calculation)") 
         asset_ACF_matrix[,j+1] = aux_acf$acf   # Store the vector of correlations
      }

      for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
         mean_ACF_absreturns[r,i+k*nAssets] = mean(asset_ACF_matrix[r,])
         stdev_ACF_absreturns[r,i+k*nAssets] = sd(asset_ACF_matrix[r,])
	   Max_ACF_absreturns[r,i+k*nAssets] = max(asset_ACF_matrix[r,])
	   Min_ACF_absreturns[r,i+k*nAssets] = min(asset_ACF_matrix[r,])
      }
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with ACF of asset i for each run
         aux_acf <- acf((diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]))^2, lag.max=nlags-1, main="IGNORE (Auxiliary calculation)") 
         asset_ACF_matrix[,j+1] = aux_acf$acf   # Store the vector of correlations
      }

      for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
         mean_ACF_squaredreturns[r,i+k*nAssets] = mean(asset_ACF_matrix[r,])
         stdev_ACF_squaredreturns[r,i+k*nAssets] = sd(asset_ACF_matrix[r,])
         Max_ACF_squaredreturns[r,i+k*nAssets] = max(asset_ACF_matrix[r,])
         Min_ACF_squaredreturns[r,i+k*nAssets] = min(asset_ACF_matrix[r,])
      }
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with ACF of asset i for each run
         aux_acf <- acf(tsvolume[[i+1+j*nAssets+k*nAssets*nRuns]], lag.max=nlags-1, main="IGNORE (Auxiliary calculation)") 
         asset_ACF_matrix[,j+1] = aux_acf$acf   # Store the vector of correlations
      }

      for (r in seq(from=1, to=nlags)) {   # Calculate average autocorrelation at each lag over all runs
         mean_ACF_volume[r,i+k*nAssets] = mean(asset_ACF_matrix[r,])
         stdev_ACF_volume[r,i+k*nAssets] = sd(asset_ACF_matrix[r,])
         Max_ACF_volume[r,i+k*nAssets] = max(asset_ACF_matrix[r,])
         Min_ACF_volume[r,i+k*nAssets] = min(asset_ACF_matrix[r,])
      }
   }
}


# ------ Calculate average time series ------ #

tsprices_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tslogprices_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsvalues_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tslogvalues_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsFUNDvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsLSvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsFUNDwealth_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDwealth_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsLSwealth_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsFUNDorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsLSorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsFUNDreducedvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsTRENDreducedvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsLSreducedvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsFUNDreducedorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsTRENDreducedorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsLSreducedorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsFUNDsellofforders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDsellofforders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsLSsellofforders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsFUNDselloffvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDselloffvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsLSselloffvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsrandomprices_avg <- array(0, dim=c(nTicks, nAssets*nExp))

kurt_avg <- array(0, dim=c(1, nAssets*nExp))  # Averages the kurtosis of log-returns obtained on each run

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         tsprices_avg[,i+k*nAssets] <- tsprices_avg[,i+k*nAssets] + tsprices[[i+1+j*nAssets+k*nAssets*nRuns]]
         tslogprices_avg[,i+k*nAssets] <- tslogprices_avg[,i+k*nAssets] + tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsvalues_avg[,i+k*nAssets] <- tsvalues_avg[,i+k*nAssets] + tsvalues[[i+1+j*nAssets+k*nAssets*nRuns]]
         tslogvalues_avg[,i+k*nAssets] <- tslogvalues_avg[,i+k*nAssets] + tslogvalues[[i+1+j*nAssets+k*nAssets*nRuns]]

         tsvolume_avg[,i+k*nAssets] <- tsvolume_avg[,i+k*nAssets] + tsvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsFUNDvolume_avg[,i+k*nAssets] <- tsFUNDvolume_avg[,i+k*nAssets] + tsFUNDvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDvolume_avg[,i+k*nAssets] <- tsTRENDvolume_avg[,i+k*nAssets] + tsTRENDvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsLSvolume_avg[,i+k*nAssets] <- tsLSvolume_avg[,i+k*nAssets] + tsLSvolume[[i+1+j*nAssets+k*nAssets*nRuns]]

         tsFUNDwealth_avg[,i+k*nAssets] <- tsFUNDwealth_avg[,i+k*nAssets] + tsFUNDwealth[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDwealth_avg[,i+k*nAssets] <- tsTRENDwealth_avg[,i+k*nAssets] + tsTRENDwealth[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsLSwealth_avg[,i+k*nAssets] <- tsLSwealth_avg[,i+k*nAssets] + tsLSwealth[[i+1+j*nAssets+k*nAssets*nRuns]]

         tsFUNDorders_avg[,i+k*nAssets] <- tsFUNDorders_avg[,i+k*nAssets] + tsFUNDorders[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDorders_avg[,i+k*nAssets] <- tsTRENDorders_avg[,i+k*nAssets] + tsTRENDorders[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsLSorders_avg[,i+k*nAssets] <- tsLSorders_avg[,i+k*nAssets] + tsLSorders[[i+1+j*nAssets+k*nAssets*nRuns]]

#         tsFUNDreducedvolume_avg[,i+k*nAssets] <- tsFUNDreducedvolume_avg[,i+k*nAssets] + tsFUNDreducedvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
#         tsTRENDreducedvolume_avg[,i+k*nAssets] <- tsTRENDreducedvolume_avg[,i+k*nAssets] + tsTRENDreducedvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
#         tsLSreducedvolume_avg[,i+k*nAssets] <- tsLSreducedvolume_avg[,i+k*nAssets] + tsLSreducedvolume[[i+1+j*nAssets+k*nAssets*nRuns]]

#         tsFUNDreducedorders_avg[,i+k*nAssets] <- tsFUNDreducedorders_avg[,i+k*nAssets] + tsFUNDreducedorders[[i+1+j*nAssets+k*nAssets*nRuns]]
#         tsTRENDreducedorders_avg[,i+k*nAssets] <- tsTRENDreducedorders_avg[,i+k*nAssets] + tsTRENDreducedorders[[i+1+j*nAssets+k*nAssets*nRuns]]
#         tsLSreducedorders_avg[,i+k*nAssets] <- tsLSreducedorders_avg[,i+k*nAssets] + tsLSreducedorders[[i+1+j*nAssets+k*nAssets*nRuns]]

         tsFUNDsellofforders_avg[,i+k*nAssets] <- tsFUNDsellofforders_avg[,i+k*nAssets] + tsFUNDsellofforders[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDsellofforders_avg[,i+k*nAssets] <- tsTRENDsellofforders_avg[,i+k*nAssets] + tsTRENDsellofforders[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsLSsellofforders_avg[,i+k*nAssets] <- tsLSsellofforders_avg[,i+k*nAssets] + tsLSsellofforders[[i+1+j*nAssets+k*nAssets*nRuns]]

         tsFUNDselloffvolume_avg[,i+k*nAssets] <- tsFUNDselloffvolume_avg[,i+k*nAssets] + tsFUNDselloffvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDselloffvolume_avg[,i+k*nAssets] <- tsTRENDselloffvolume_avg[,i+k*nAssets] + tsTRENDselloffvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsLSselloffvolume_avg[,i+k*nAssets] <- tsLSselloffvolume_avg[,i+k*nAssets] + tsLSselloffvolume[[i+1+j*nAssets+k*nAssets*nRuns]]

         tsrandomprices_avg[,i+k*nAssets] <- tsrandomprices_avg[,i+k*nAssets] + tsrandomprices[,i+1+j*nAssets+k*nAssets*nRuns]

         kurt_avg[,i+k*nAssets] <- kurt_avg[,i+k*nAssets] + kurtosis(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]), na.rm = FALSE, method="excess")[1]
      }

      tsprices_avg[,i+k*nAssets] <- tsprices_avg[,i+k*nAssets]/nRuns
      tslogprices_avg[,i+k*nAssets] <- tslogprices_avg[,i+k*nAssets]/nRuns
      tsvalues_avg[,i+k*nAssets] <- tsvalues_avg[,i+k*nAssets]/nRuns
      tslogvalues_avg[,i+k*nAssets] <- tslogvalues_avg[,i+k*nAssets]/nRuns
      tsvolume_avg[,i+k*nAssets] <- tsvolume_avg[,i+k*nAssets]/nRuns
      tsFUNDvolume_avg[,i+k*nAssets] <- tsFUNDvolume_avg[,i+k*nAssets]/nRuns
      tsTRENDvolume_avg[,i+k*nAssets] <- tsTRENDvolume_avg[,i+k*nAssets]/nRuns
      tsLSvolume_avg[,i+k*nAssets] <- tsLSvolume_avg[,i+k*nAssets]/nRuns
      tsFUNDwealth_avg[,i+k*nAssets] <- tsFUNDwealth_avg[,i+k*nAssets]/nRuns
      tsTRENDwealth_avg[,i+k*nAssets] <- tsTRENDwealth_avg[,i+k*nAssets]/nRuns
      tsLSwealth_avg[,i+k*nAssets] <- tsLSwealth_avg[,i+k*nAssets]/nRuns
      tsFUNDorders_avg[,i+k*nAssets] <- tsFUNDorders_avg[,i+k*nAssets]/nRuns
      tsTRENDorders_avg[,i+k*nAssets] <- tsTRENDorders_avg[,i+k*nAssets]/nRuns
      tsLSorders_avg[,i+k*nAssets] <- tsLSorders_avg[,i+k*nAssets]/nRuns

#	tsFUNDreducedvolume_avg[,i+k*nAssets] <- tsFUNDreducedvolume_avg[,i+k*nAssets]/nRuns
#	tsTRENDreducedvolume_avg[,i+k*nAssets] <- tsTRENDreducedvolume_avg[,i+k*nAssets]/nRuns
#	tsLSreducedvolume_avg[,i+k*nAssets] <- tsLSreducedvolume_avg[,i+k*nAssets]/nRuns
#	tsFUNDreducedorders_avg[,i+k*nAssets] <- tsFUNDreducedorders_avg[,i+k*nAssets]/nRuns
#	tsTRENDreducedorders_avg[,i+k*nAssets] <- tsTRENDreducedorders_avg[,i+k*nAssets]/nRuns
#	tsLSreducedorders_avg[,i+k*nAssets] <- tsLSreducedorders_avg[,i+k*nAssets]/nRuns

	tsFUNDsellofforders_avg[,i+k*nAssets] <- tsFUNDsellofforders_avg[,i+k*nAssets]/nRuns
	tsTRENDsellofforders_avg[,i+k*nAssets] <- tsTRENDsellofforders_avg[,i+k*nAssets]/nRuns
	tsLSsellofforders_avg[,i+k*nAssets] <- tsLSsellofforders_avg[,i+k*nAssets]/nRuns
	tsFUNDselloffvolume_avg[,i+k*nAssets] <- tsFUNDselloffvolume_avg[,i+k*nAssets]/nRuns
	tsTRENDselloffvolume_avg[,i+k*nAssets] <- tsTRENDselloffvolume_avg[,i+k*nAssets]/nRuns
	tsLSselloffvolume_avg[,i+k*nAssets] <- tsLSselloffvolume_avg[,i+k*nAssets]/nRuns

      tsrandomprices_avg[,i+k*nAssets] <- tsrandomprices_avg[,i+k*nAssets]/nRuns

      kurt_avg[,i+k*nAssets] <- kurt_avg[,i+k*nAssets]/nRuns
   }
}


tsFUNDvar_avg <- array(0, dim=c(nTicks, nExp))
tsTRENDvar_avg <- array(0, dim=c(nTicks, nExp))
tsLSvar_avg <- array(0, dim=c(nTicks, nExp))
tsFUNDstressedvar_avg <- array(0, dim=c(nTicks, nExp))
tsTRENDstressedvar_avg <- array(0, dim=c(nTicks, nExp))
tsLSstressedvar_avg <- array(0, dim=c(nTicks, nExp))
#tsFUNDfailures_avg <- array(0, dim=c(nTicks, nExp))
#tsTRENDfailures_avg <- array(0, dim=c(nTicks, nExp))
#tsLSfailures_avg <- array(0, dim=c(nTicks, nExp))

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=1, to=nRuns)) {
      tsFUNDvar_avg[,k+1] <- tsFUNDvar_avg[,k+1] + tsFUNDvar[[1+j+k*nRuns]]
      tsTRENDvar_avg[,k+1] <- tsTRENDvar_avg[,k+1] + tsTRENDvar[[1+j+k*nRuns]]
      tsLSvar_avg[,k+1] <- tsLSvar_avg[,k+1] + tsLSvar[[1+j+k*nRuns]]
      tsFUNDstressedvar_avg[,k+1] <- tsFUNDstressedvar_avg[,k+1] + tsFUNDstressedvar[[1+j+k*nRuns]]
      tsTRENDstressedvar_avg[,k+1] <- tsTRENDstressedvar_avg[,k+1] + tsTRENDstressedvar[[1+j+k*nRuns]]
      tsLSstressedvar_avg[,k+1] <- tsLSstressedvar_avg[,k+1] + tsLSstressedvar[[1+j+k*nRuns]]
#      tsFUNDfailures_avg[,k+1] <- tsFUNDfailures_avg[,k+1] + tsFUNDfailures[[1+j+k*nRuns]]
#      tsTRENDfailures_avg[,k+1] <- tsTRENDfailures_avg[,k+1] + tsTRENDfailures[[1+j+k*nRuns]]
#      tsLSfailures_avg[,k+1] <- tsLSfailures_avg[,k+1] + tsLSfailures[[1+j+k*nRuns]]
   }
   tsFUNDvar_avg[,k+1] <- tsFUNDvar_avg[,k+1]/nRuns
   tsTRENDvar_avg[,k+1] <- tsTRENDvar_avg[,k+1]/nRuns
   tsLSvar_avg[,k+1] <- tsLSvar_avg[,k+1]/nRuns
   tsFUNDstressedvar_avg[,k+1] <- tsFUNDstressedvar_avg[,k+1]/nRuns
   tsTRENDstressedvar_avg[,k+1] <- tsTRENDstressedvar_avg[,k+1]/nRuns
   tsLSstressedvar_avg[,k+1] <- tsLSstressedvar_avg[,k+1]/nRuns
#   tsFUNDfailures_avg[,k+1] <- tsFUNDfailures_avg[,k+1]/nRuns
#   tsTRENDfailures_avg[,k+1] <- tsTRENDfailures_avg[,k+1]/nRuns
#   tsLSfailures_avg[,k+1] <- tsLSfailures_avg[,k+1]/nRuns
}



### [AUXILIARY CALCULATION] Calculate Hill index of returns for each run

hillreturns <- array(0, dim=c(1, nAssets*nExp*nRuns))
hillreturns_avg <- array(0, dim=c(1, nAssets*nExp))

sample_size = 0.1 * nTicks

for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
   hillreturns[1,j] <- hill(diff(tslogprices[[1+j]]), option = "alpha", end = sample_size, p = NA)$y[1]
}

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         hillreturns_avg[1,i+k*nAssets] <- hillreturns_avg[1,i+k*nAssets] + hillreturns[1,i+j*nAssets+k*nAssets*nRuns]
      }
      hillreturns_avg[1,i+k*nAssets] <- hillreturns_avg[1,i+k*nAssets]/nRuns
   }
}



#######################################################################################################

# Open files to write the results

pdf(paste(home.dir, "Trend_Value_LS_Var_ABM_Exp_001_outR.pdf", sep=""))   # Plot diagrams in a pdf file
sink(paste(home.dir, "Trend_Value_LS_Var_ABM_Exp_001_outR.txt", sep=""))  # Write quantitative results to a text file



###################################################################
#                                                                 #
#         VALIDATION TESTS (Stylised facts for each asset)        #
#                                                                 #
###################################################################

cat("TEST: VA_TREND_VALUE_LS_VAR_ABM \n")
cat("========================================= \n")
cat(paste("Parameter file:", param_file, "\n\n"))  # Add parameter file

cat(paste("Notation: [A=Asset, R=Run, E=Experiment] \n\n"))  # Add parameter file

# Plots for a single asset (over different runs) are shown in a matrix
# If there are more runs than positions in the matrix, 
# only a a selection of the plots is shown


#_________________________________________________________________#
#                                                                 # 
#        TEST VA-TF_ABM-1.0: LACK OF RETURN AUTOCORRELATION       #
#_________________________________________________________________#
#                                                                 #
      
# ------ VA-TF_ABM-1.0.1 - ACF of log-returns ------ #

### ACF of log-returns for single runs 
#
# Objective: For each experiment, plot a selection of ACF for single runs

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
            acf(diff(tslogprices[[i+k+1 +(e-1)*nAssets*nRuns]]), main=paste("Run", 1+i/nAssets), ylim=c(-1,1))
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            acf(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]), main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
         }
      }
      title(paste("VA-TF_ABM-1.0.1 - ACF of log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: ACF should decay quickly to zero (that is, it should lie between the dashed lines).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}

### Average ACF of log-returns
#
# Objective: Plot a summary of the ACF along experiments

upper_bound = rep(-1/nTicks+2/sqrt(nTicks), nrow(mean_ACF_returns))
lower_bound = rep(-1/nTicks-2/sqrt(nTicks), nrow(mean_ACF_returns))

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      plot(mean_ACF_returns[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Autocorrelations")
      lines(upper_bound, lty=2, col="blue")
      lines(lower_bound, lty=2, col="blue")      
   }
   title(paste("VA-TF_ABM-1.0.1 - Average ACF of log-returns (over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Test description: ACF should decay quickly to zero (that is, it should lie between the dashed lines).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Variation in ACF of log-returns
#
# Plot the maximum and minimum ACF for each experiment
# Objective: Study the range of variation of ACF over experiments

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

for (i in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (k in seq(from=0, to=nExp-1)) {
      #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
      xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
      yy <- c(Min_ACF_returns[,i+k*nAssets], rev(Max_ACF_returns[,i+k*nAssets]))
      plot(xx,yy, type="l", main=paste("Exp", k+1), 
   	xlab="Lag", ylab=paste("ACF - Asset", i), lwd=1, ylim=c(-1,1))
      polygon(xx, yy, col="gray")
      lines(upper_bound, lty=2, col="blue")
      lines(lower_bound, lty=2, col="blue")   
   }
   title(paste("VA-TF_ABM-1.0.1 - Range of variation of ACF of log-returns - Asset", i), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: Overview of the max/min values of ACF of log-returns. It should decay rapidly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ------ VA-TF_ABM-1.0.2 - Hurst exponent of log-returns ------ #

### Variation of the Hurst exponent of log-returns
#
# Calculate the min/max value of the Hurst exponent over all runs for each asset.
# This exponent is an indicator of the long-term memory of the time series
# Objective: Study the range of variation of the Hurst exponent over experiments

Max_Hurst <- array(0, dim=c(nExp, nAssets))  # Arrays to store the max and min Hurst exponent over all runs (for each asset and experiment)
Min_Hurst <- array(0, dim=c(nExp, nAssets))
Mean_Hurst <- array(0, dim=c(nExp, nAssets))
Stdev_Hurst <- array(0, dim=c(nExp, nAssets))

asset_Hurst_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the Hurst exponent for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with Hurst exponent of asset i for each run
         asset_Hurst_vector[,j+1] = hurstSpec(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]))   # Store values of Hurst exponent
      }
      Max_Hurst[k+1,i] = max(asset_Hurst_vector)  # Select max/min Hurst exponent over all runs
      Min_Hurst[k+1,i] = min(asset_Hurst_vector)
      Mean_Hurst[k+1,i] = mean(asset_Hurst_vector)
      Stdev_Hurst[k+1,i] = sd(asset_Hurst_vector[1,])
   }
}

# Plot mean, minimum, and maximum Hurst exponent

y_min = min(Min_Hurst)  # Range of y axis
y_max = max(Max_Hurst)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   xx <- c(1:nExp, nExp:1)   # Needed to shade the area between max and min
   yy <- c(Min_Hurst[,i], rev(Max_Hurst[,i]))
   plot(xx,yy, type="l", main=paste("Asset", i), col="black", 
	xlab="Experiment", ylab="Max/Min Hurst exponent", lwd=1, ylim=c(0,1))
   polygon(xx, yy, col="gray")

   lines(Mean_Hurst[,i], type="l", col="black", lwd=2)
   lines(Mean_Hurst[,i]+Stdev_Hurst[,i], type="l", col="red2")   # Plot +-1stdev to have an idea of the variability
   lines(Mean_Hurst[,i]-Stdev_Hurst[,i], type="l", col="red2")
   lines(rep(0.5, nExp), lty=2, col="blue")  # Horizontal line at 0.5 (lack of long-memory)
}
title("VA-TF_ABM-1.0.2 - Range of variation of Hurst exp of log-returns", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the mean/max/min values of the Hurst exponent. It should be around 0.5 (dashed line).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file

## To provide information in the x axis on e.g. the percentage of HF's: create a vector with the percentages, e.g.:
## x <- c(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5)
## axis(1, at=1:nExp, x)


### Quantitative test: is the Hurst exponent around 0.5?

cat("\n --- VA-TF_ABM-1.0.2: Hurst exponent of log-returns --- \n")
cat("\n Test description: As the log-returns have no long-term memory, their Hurst exponent should be around 0.5. \n\n")

failed=-1  # Stores runs where the Hurst exponent is 'far' from 0.5

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         hurst <- hurstSpec(diff(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]]))  # Hurst exponent of the log-return series
         if (hurst < 0.45 || hurst > 0.55) {  # I assume that a Hurst exponent "close to 0.5" means to belong to [0.45, 0.55]
             failed <- append(failed, i+1)
             cat(paste("VA-TF_ABM-1.0.2: Hurst exponent different from 0.5 in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }
         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e, "]", ": hurst exponent = ", hurst, "\n"))  # Write the result of each single run to a file
      }
   }
}

percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of VA-TF_ABM-1.0.2: ", percentage_success, "% \n")  # Percentage of successful runs



### Alternative graphical representation: 'heat map' of log-returns persistence (Hurst exponent of log-returns)
#
# Objective: Visually summarise the value of the Hurst exponent of log-returns 
# for each run with a color code (e.g. green when the Hurst exponent is around 0.5 or red
# when the Hurst exponent is small or big)

for (a in seq(from=1, to=nAssets)) {
   Hurst_matrix <- array(0, dim=c(nRuns, nExp))  # Array to store the Hurst exponent of each run

   for (k in seq(from=0, to=nExp-1)) {
      for (j in seq(from=0, to=nRuns-1)){
         Hurst_matrix[j+1,k+1] = hurstSpec(diff(tslogprices[[a+1+j*nAssets+k*nAssets*nRuns]]))   # Store values of Hurst exponent
      }
   }

   # Values of Hurst exponent that define the different categories
   intervals <- c(0, 0.4, 0.45, 0.55, 0.6, 2)

   # prepare label text (use two adjacent values for range text)
   label_text <- rollapply(round(intervals, 2), width = 2, by = 1, FUN = function(i) paste(i, collapse = "-"))

   # discretize matrix; this is the most important step, where for each value we find category of predefined ranges
   mod_mat <- matrix(findInterval(Hurst_matrix, intervals, all.inside = TRUE), nrow = nrow(Hurst_matrix))

   # output the graphics
   df_Hurst <- melt(mod_mat)
   colnames(df_Hurst) <- c("Run", "Experiment", "value")

   # Obs: 'print' must be explicitly used when the ggplot is inside a loop
   print(ggplot(df_Hurst, aes(x = Experiment, y = Run, fill = factor(value))) + geom_tile(color = "black") +
	scale_fill_manual(values = c("1"="red3", "2"="orange", "3"="forestgreen", "4"="orange", "5"="red3"), 
	limits = c("1", "2", "3", "4", "5"), name = paste("Hurst exponent r \n Asset", a), breaks=c(1,2,3,4,5), labels = label_text))
}


#________________________________________________________#
#                                                        #
#        TEST VA-TF_ABM-1.1: VOLATILITY CLUSTERING       #
#________________________________________________________#
#                                                        #

# ------ VA-TF_ABM-1.1.1 - ACF of ABSOLUTE log-returns ------ #

### ACF of ABSOLUTE log-returns for single runs 
#
# Objective: For each experiment, plot a selection of ACF for single runs

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
            acf(abs(diff(tslogprices[[i+k+1 +(e-1)*nAssets*nRuns]])), main=paste("Run", 1+i/nAssets), ylim=c(-1,1))         
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            acf(abs(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]])), main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
         }
      }
      title(paste("VA-TF_ABM-1.1.1 - ACF of absolute log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: ACF should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}

### Average ACF of ABSOLUTE log-returns
#
# Objective: Plot a summary of the ACF along experiments

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3)) 
   for (e in seq(from=1, to=nExp)) {
      plot(mean_ACF_absreturns[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Autocorrelations")
      lines(upper_bound, lty=2, col="blue")
      lines(lower_bound, lty=2, col="blue")      
   }
   title(paste("VA-TF_ABM-1.1.1 - Average ACF of absolute log-returns (over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: ACF should remain positive (that is, above the dashed lines) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Variation in ACF of ABSOLUTE log-returns
#
# Plot the maximum and minimum ACF for each experiment
# Objective: Study the range of variation of ACF over experiments

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

for (i in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (k in seq(from=0, to=nExp-1)) {
      #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
      xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
      yy <- c(Min_ACF_absreturns[,i+k*nAssets], rev(Max_ACF_absreturns[,i+k*nAssets]))
      plot(xx,yy, type="l", main=paste("Exp", k+1), 
   	xlab="Lag", ylab=paste("ACF - Asset", i), lwd=1, ylim=c(-1,1))
      polygon(xx, yy, col="gray")
      lines(upper_bound, lty=2, col="blue")
      lines(lower_bound, lty=2, col="blue")  
   }
   title(paste("VA-TF_ABM-1.1.1 - Range of variation of ACF of abs log-returns - Asset", i), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: ACF of absolute log-returns should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ------ VA-TF_ABM-1.1.4 - Hurst exponent of ABSOLUTE log-returns ------ #

### Variation of the Hurst exponent of ABSOLUTE log-returns
#
# Calculate the min/max value of the Hurst exponent over all runs for each asset.
# This exponent is an indicator of the long-term memory of the time series
# Objective: Study the range of variation of the Hurst exponent over experiments

Max_Hurst <- array(0, dim=c(nExp, nAssets))  # Arrays to store the max and min Hurst exponent over all runs (for each asset and experiment)
Min_Hurst <- array(0, dim=c(nExp, nAssets))
Mean_Hurst <- array(0, dim=c(nExp, nAssets))
Stdev_Hurst <- array(0, dim=c(nExp, nAssets))

asset_Hurst_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the Hurst exponent for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with Hurst exponent of asset i for each run
         asset_Hurst_vector[,j+1] = hurstSpec(abs(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]])))   # Store values of Hurst exponent
      }
      Max_Hurst[k+1,i] = max(asset_Hurst_vector)  # Select max/min Hurst exponent over all runs
      Min_Hurst[k+1,i] = min(asset_Hurst_vector)
      Mean_Hurst[k+1,i] = mean(asset_Hurst_vector)
      Stdev_Hurst[k+1,i] = sd(asset_Hurst_vector[1,])
   }
}

# Plot mean, minimum, and maximum Hurst exponent

y_min = min(Min_Hurst)  # Range of y axis
y_max = max(Max_Hurst)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   xx <- c(1:nExp, nExp:1)   # Needed to shade the area between max and min
   yy <- c(Min_Hurst[,i], rev(Max_Hurst[,i]))
   plot(xx,yy, type="l", main=paste("Asset", i), col="black", 
	xlab="Experiment", ylab="Max/Min Hurst exponent", lwd=1, ylim=c(0,1))
   polygon(xx, yy, col="gray")

   lines(Mean_Hurst[,i], type="l", col="black", lwd=2)
   lines(Mean_Hurst[,i]+Stdev_Hurst[,i], type="l", col="red2")   # Plot +-1stdev to have an idea of the variability
   lines(Mean_Hurst[,i]-Stdev_Hurst[,i], type="l", col="red2")
   lines(rep(0.7, nExp), lty=2, col="blue")   # Horizontal line at 0.7-0.9 (empirical values for volatility Hurst exp)
   lines(rep(0.9, nExp), lty=2, col="blue")
}
title("VA-TF_ABM-1.1.4 - Range of variation of Hurst exp of absolute log-returns", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the mean/max/min values of the Hurst exponent. It should be between 0.7 and 0.9 (dashed lines).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file

## To provide information in the x axis on e.g. the percentage of HF's: create a vector with the percentages, e.g.:
## x <- c(0.1, 0.2, 0.3, 0.4, 0.5)
## axis(1, at=1:nExp, x)



### Alternative graphical representation: cdplot of volatility clustering (Hurst exponent of ABSOLUTE log-returns)
#
# Objective: Count in how many runs the Hurst exponent of absolute
# log-returns is above 0.7 (empirical value observed for Hurst exponent
# of volatility, which exhibits long-term memory)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (i in seq(from=1, to=nAssets)) {

   # Count in how many runs the Hurst exponent is above 0.7
   persistent_absreturns <- array(0, dim=c(nExp, nRuns))
   
   for (k in seq(from=0, to=nExp-1)) {
      for (j in seq(from=0, to=nRuns-1)) {
         if ( hurstSpec(abs(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]))) > 0.7 ) {
            persistent_absreturns[k+1,j+1] = 1
         }
      }
   }

   # Convert numeric vector to factor to draw cdplot
   clustered <- factor(persistent_absreturns, levels = 0:1, labels = c("no", "yes"))

   # Draw cdplot
   x_axis <- rep(1:nExp,nRuns)
   cdplot(clustered~x_axis, xlab="Experiment", ylab="Clustered?", main=paste("Asset ", i), col=c("red3", "palegreen"))
}
title("VA-TF_ABM-1.1.4 - Clustering of absolute log-returns", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Is there long-term memory in the series of absolute log-returns? (measured with Hurst exponent)", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Quantitative test: is the Hurst exponent higher than 0.7?
#
# Note: a time series has long-memory if its Hurst exponent is higher than 0.5. I am testing here
# a more strong condition - whether the Hurst exponent is higher than 0.7 - because the empirical 
# value of the Hurst exponent is claimed to lie between 0.7 and 0.9.

cat("\n --- VA-TF_ABM-1.1.4: Hurst exponent of absolute log-returns --- \n")
cat("\n Test description: As the absolute log-returns have long-term memory, their Hurst exponent should be higher than 0.7. \n\n")

failed=-1  # Stores runs where the Hurst exponent is smaller than 0.7

for (e in seq(from=0, to=nExp-1)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         hurst <- hurstSpec(abs(diff(tslogprices[[k+1+i*nAssets+ e*nAssets*nRuns]])))  # Hurst exponent of the absolute log-return series
         if (hurst < 0.7) {
             failed <- append(failed, i+1)
             cat(paste("VA-TF_ABM-1.1.4: Hurst exponent smaller than 0.7 in [ A=", k, ", R=", i+1, ", E=", e+1, "]", "\n"))  # Write the runs where the test failed to a file
         }
         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e+1, "]", ": hurst exponent = ", hurst, "\n"))  # Write the result of each single run to a file
      }
   }
}

percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of VA-TF_ABM-1.1.4: ", percentage_success, "% \n")  # Percentage of successful runs


### Alternative graphical representation: 'heat map' of volatility clustering (Hurst exponent of ABSOLUTE log-returns)
#
# Objective: Visually summarise the value of the Hurst exponent of absolute returns 
# for each run with a color code (e.g. red when the Hurst exponent is below 0.5 or green
# when the Hurst exponent is above 0.7)

for (a in seq(from=1, to=nAssets)) {
   Hurst_matrix <- array(0, dim=c(nRuns, nExp))  # Array to store the Hurst exponent of each run

   for (k in seq(from=0, to=nExp-1)) {
      for (j in seq(from=0, to=nRuns-1)){
         Hurst_matrix[j+1,k+1] = hurstSpec(abs(diff(tslogprices[[a+1+j*nAssets+k*nAssets*nRuns]])))   # Store values of Hurst exponent
      }
   }

   # Values of Hurst exponent that define the different categories
   intervals <- c(0, 0.5, 0.55, 0.7, 2)

   # prepare label text (use two adjacent values for range text)
   label_text <- rollapply(round(intervals, 2), width = 2, by = 1, FUN = function(i) paste(i, collapse = "-"))

   # discretize matrix; this is the most important step, where for each value we find category of predefined ranges
   mod_mat <- matrix(findInterval(Hurst_matrix, intervals, all.inside = TRUE), nrow = nrow(Hurst_matrix))

   # output the graphics
   df_Hurst <- melt(mod_mat)
   colnames(df_Hurst) <- c("Run", "Experiment", "value")

   # Obs: 'print' must be explicitly used when the ggplot is inside a loop
   print(ggplot(df_Hurst, aes(x = Experiment, y = Run, fill = factor(value))) + geom_tile(color = "black") +
	scale_fill_manual(values = c("1"="red3", "2"="orange", "3"="palegreen", "4"="palegreen4"), 
	limits = c("1", "2", "3", "4"), name = paste("Hurst exponent |r| \n Asset", a), breaks=c(1,2,3,4), 
	labels = label_text))
}


# ------ VA-TF_ABM-1.1.2 - ACF of SQUARED log-returns ------ #

### ACF of SQUARED log-returns for single runs 
#
# Objective: For each experiment, plot a selection of ACF for single runs

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
       par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {      
            acf(diff(tslogprices[[i+k+1 +(e-1)*nAssets*nRuns]])^2, main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            acf(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]])^2, main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
          }
      }
      title(paste("VA-TF_ABM-1.1.2 - ACF of squared log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: ACF should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}

### Average ACF of SQUARED log-returns
#
# Objective: Plot a summary of the ACF along experiments

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {
      plot(mean_ACF_squaredreturns[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Autocorrelations")
      lines(upper_bound, lty=2, col="blue")
      lines(lower_bound, lty=2, col="blue")      
   }
   title(paste("VA-TF_ABM-1.1.2 - Average ACF of squared log-returns (over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: ACF should remain positive (that is, above the dashed lines) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Variation in ACF of SQUARED log-returns
#
# Plot the maximum and minimum ACF for each experiment
# Objective: Study the range of variation of ACF over experiments

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

for (i in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (k in seq(from=0, to=nExp-1)) {
      #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
      xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
      yy <- c(Min_ACF_squaredreturns[,i+k*nAssets], rev(Max_ACF_squaredreturns[,i+k*nAssets]))
      plot(xx,yy, type="l", main=paste("Exp", k+1), 
   	xlab="Lag", ylab=paste("ACF - Asset", i), lwd=1, ylim=c(-1,1))
      polygon(xx, yy, col="gray")
      lines(upper_bound, lty=2, col="blue")
      lines(lower_bound, lty=2, col="blue")  
   }
   title(paste("VA-TF_ABM-1.1.2 - Range of variation of ACF of squared log-returns - Asset", i), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: ACF of squared log-returns should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ------ VA-TF_ABM-1.1.5 - Hurst exponent of SQUARED log-returns ------ #

### Variation of the Hurst exponent of SQUARED log-returns
#
# Calculate the min/max value of the Hurst exponent over all runs for each asset.
# This exponent is an indicator of the long-term memory of the time series
# Objective: Study the range of variation of the Hurst exponent over experiments

Max_Hurst <- array(0, dim=c(nExp, nAssets))  # Arrays to store the max and min Hurst exponent over all runs (for each asset and experiment)
Min_Hurst <- array(0, dim=c(nExp, nAssets))
Mean_Hurst <- array(0, dim=c(nExp, nAssets))
Stdev_Hurst <- array(0, dim=c(nExp, nAssets))

asset_Hurst_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the Hurst exponent for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with Hurst exponent of asset i for each run
         asset_Hurst_vector[,j+1] = hurstSpec((diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]))^2)   # Store values of Hurst exponent
      }
      Max_Hurst[k+1,i] = max(asset_Hurst_vector)  # Select max/min Hurst exponent over all runs
      Min_Hurst[k+1,i] = min(asset_Hurst_vector)
      Mean_Hurst[k+1,i] = mean(asset_Hurst_vector)
      Stdev_Hurst[k+1,i] = sd(asset_Hurst_vector[1,])
   }
}

# Plot mean, minimum, and maximum Hurst exponent

y_min = min(Min_Hurst)  # Range of y axis
y_max = max(Max_Hurst)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   xx <- c(1:nExp, nExp:1)   # Needed to shade the area between max and min
   yy <- c(Min_Hurst[,i], rev(Max_Hurst[,i]))
   plot(xx,yy, type="l", main=paste("Asset", i), col="black", 
	xlab="Experiment", ylab="Max/Min Hurst exponent", lwd=1, ylim=c(0,1))
   polygon(xx, yy, col="gray")

   lines(Mean_Hurst[,i], type="l", col="black", lwd=2)
   lines(Mean_Hurst[,i]+Stdev_Hurst[,i], type="l", col="red2")   # Plot +-1stdev to have an idea of the variability
   lines(Mean_Hurst[,i]-Stdev_Hurst[,i], type="l", col="red2")
   lines(rep(0.7, nExp), lty=2, col="blue")   # Horizontal line at 0.7-0.9 (empirical values for volatility Hurst exp)
   lines(rep(0.9, nExp), lty=2, col="blue")
}
title("VA-TF_ABM-1.1.5 - Range of variation of Hurst exp of squared log-returns", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the mean/max/min values of the Hurst exponent. It should be between 0.7 and 0.9 (dashed lines).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file

## To provide information in the x axis on e.g. the percentage of HF's: create a vector with the percentages, e.g.:
## x <- c(0.1, 0.2, 0.3, 0.4, 0.5)
## axis(1, at=1:nExp, x)


### Alternative graphical representation: cdplot of volatility clustering (Hurst exponent of SQUARED log-returns)
#
# Objective: Count in how many runs the Hurst exponent of squared
# log-returns is above 0.7 (empirical value observed for Hurst exponent
# of volatility, which exhibits long-term memory)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (i in seq(from=1, to=nAssets)) {

   # Count in how many runs the Hurst exponent is above 0.7
   persistent_sqreturns <- array(0, dim=c(nExp, nRuns))
   
   for (k in seq(from=0, to=nExp-1)) {
      for (j in seq(from=0, to=nRuns-1)) {
         if ( hurstSpec((diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]))^2) > 0.7 ) {
            persistent_sqreturns[k+1,j+1] = 1
         }
      }
   }

   # Convert numeric vector to factor to draw cdplot
   clustered <- factor(persistent_sqreturns, levels = 0:1, labels = c("no", "yes"))

   # Draw cdplot
   x_axis <- rep(1:nExp,nRuns)
   cdplot(clustered~x_axis, xlab="Experiment", ylab="Clustered?", main=paste("Asset ", i), col=c("red3", "palegreen"))
}
title("VA-TF_ABM-1.1.5 - Clustering of squared log-returns", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Is there long-term memory in the series of squared log-returns? (measured with Hurst exponent)", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



### Quantitative test: is the Hurst exponent higher than 0.7?
#
# Note: a time series has long-memory if its Hurst exponent is higher than 0.5. I am testing here
# a more strong condition - whether the Hurst exponent is higher than 0.7 - because the empirical 
# value of the Hurst exponent is claimed to lie between 0.7 and 0.9.

cat("\n --- VA-TF_ABM-1.1.5: Hurst exponent of squared log-returns --- \n")
cat("\n Test description: As the squared log-returns have long-term memory, their Hurst exponent should be higher than 0.7. \n\n")

failed=-1  # Stores runs where the Hurst exponent is smaller than 0.7

for (e in seq(from=0, to=nExp-1)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         hurst <- hurstSpec((diff(tslogprices[[k+1+i*nAssets+ e*nAssets*nRuns]]))^2)  # Hurst exponent of the squared log-return series
         if (hurst < 0.7) {
             failed <- append(failed, i+1)
             cat(paste("VA-TF_ABM-1.1.5: Hurst exponent smaller than 0.7 in [ A=", k, ", R=", i+1, ", E=", e+1, "]", "\n"))  # Write the runs where the test failed to a file
         }
         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e+1, "]", ": hurst exponent = ", hurst, "\n"))  # Write the result of each single run to a file
      }
   }
}

percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of VA-TF_ABM-1.1.5: ", percentage_success, "% \n")  # Percentage of successful runs



### Alternative graphical representation: 'heat map' of volatility clustering (Hurst exponent of SQUARED log-returns)
#
# Objective: Visually summarise the value of the Hurst exponent of squared returns 
# for each run with a color code (e.g. red when the Hurst exponent is below 0.5 or green
# when the Hurst exponent is above 0.7)

for (a in seq(from=1, to=nAssets)) {
   Hurst_matrix <- array(0, dim=c(nRuns, nExp))  # Array to store the Hurst exponent of each run

   for (k in seq(from=0, to=nExp-1)) {
      for (j in seq(from=0, to=nRuns-1)){
         Hurst_matrix[j+1,k+1] = hurstSpec((diff(tslogprices[[a+1+j*nAssets+k*nAssets*nRuns]]))^2)   # Store values of Hurst exponent
      }
   }

   # Values of Hurst exponent that define the different categories
   intervals <- c(0, 0.5, 0.55, 0.7, 2)

   # prepare label text (use two adjacent values for range text)
   label_text <- rollapply(round(intervals, 2), width = 2, by = 1, FUN = function(i) paste(i, collapse = "-"))

   # discretize matrix; this is the most important step, where for each value we find category of predefined ranges
   mod_mat <- matrix(findInterval(Hurst_matrix, intervals, all.inside = TRUE), nrow = nrow(Hurst_matrix))

   # output the graphics
   df_Hurst <- melt(mod_mat)
   colnames(df_Hurst) <- c("Run", "Experiment", "value")

   # Obs: 'print' must be explicitly used when the ggplot is inside a loop
   print(ggplot(df_Hurst, aes(x = Experiment, y = Run, fill = factor(value))) + geom_tile(color = "black") +
	scale_fill_manual(values = c("1"="red3", "2"="orange", "3"="palegreen", "4"="palegreen4"), 
	limits = c("1", "2", "3", "4"), name = paste("Hurst exponent r^2 \n Asset", a), breaks=c(1,2,3,4), 
	labels = label_text))
}


# ----------------------------------------------- #


#dev.off()  # Close output files
#sink()


# ----------------------------------------------- #








################################################################################
#                                                                              #
#               ADDITIONAL ANALYSES: PRICE, PERFORMANCE, VOLUME                #
#                                                                              #
################################################################################

#_________________________________________________#
#                                                 #
#           PRICES vs FUNDAMENTAL VALUE           #
#_________________________________________________#
#                                                 #

### Plot of prices vs values (averaged over runs)

y_max = max(max(tsvalues_avg[,1:(nAssets*nExp)]), max(tsprices_avg[,1:(nAssets*nExp)]))
y_min = min(min(tsvalues_avg[,1:(nAssets*nExp)]), min(tsprices_avg[,1:(nAssets*nExp)]))

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      plot(tsprices_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Price vs Value")
      lines(tsvalues_avg[,(e-1)*nAssets+k], type="l", col="red")
   }
   title(paste("Average prices vs values (over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Study if mean prices are pushed toward mean values (over experiments).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Plot of prices vs values (for individual runs)

y_max = max(max(tsvalues[,2:(nAssets*nRuns*nExp+1)]), max(tsprices[,2:(nAssets*nRuns*nExp+1)]))
y_min = min(min(tsvalues[,2:(nAssets*nRuns*nExp+1)]), min(tsprices[,2:(nAssets*nRuns*nExp+1)]))

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
            plot(tsprices[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Decimal price and value", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max))
            lines(tsvalues[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="red")
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            plot(tsprices[[i+k+(e-1)*nAssets*nRuns]], type="l", ylab="Decimal price and value", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max))
            lines(tsvalues[[i+k+(e-1)*nAssets*nRuns]], type="l", col="red")  
         }
      }
      title(paste("Decimal price and value - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}



#____________________________________________________________#
#                                                            #
#           PERFORMANCE OF FUNDs vs TRENDs vs LS's           #
#____________________________________________________________#
#                                                            #

# We plot here the average increment in wealth of FUNDs, TRENDs
# and LS's to compare their performance


### Plot of time series of wealth increment (averaged over runs)

y_max = max(max(tsFUNDwealth_avg[,1:(nAssets*nExp)]), max(tsTRENDwealth_avg[,1:(nAssets*nExp)]), max(tsLSwealth_avg[,1:(nAssets*nExp)]))
y_min = min(min(tsFUNDwealth_avg[,1:(nAssets*nExp)]), min(tsTRENDwealth_avg[,1:(nAssets*nExp)]), min(tsLSwealth_avg[,1:(nAssets*nExp)]))

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      plot(tsFUNDwealth_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Wealth", col="darkorange1")
      lines(tsTRENDwealth_avg[,(e-1)*nAssets+k], type="l", col="seagreen")
      lines(tsLSwealth_avg[,(e-1)*nAssets+k], type="l", col="royalblue3")
   }
   title(paste("Increment in wealth of FUNDs vs TRENDs vs LS's (averaged over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Study which group of agents performs better (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}

### Horizon plot of time series of wealth increment (averaged over runs)

for (k in seq(from=1, to=nAssets)) {
   y_max = max(abs(tsFUNDwealth_avg[,1:(nAssets*nExp)]))
   print(horizonplot(ts(tsFUNDwealth_avg[,seq(k,nAssets*nExp,nAssets)]), layout = c(1,nExp), colorkey = TRUE, origin=0, horizonscale = y_max/3, main=paste("Increment in wealth of FUNDs (averaged over runs) - Asset ", k)))
}

for (k in seq(from=1, to=nAssets)) {
   y_max = max(abs(tsTRENDwealth_avg[,1:(nAssets*nExp)]))
   print(horizonplot(ts(tsTRENDwealth_avg[,seq(k,nAssets*nExp,nAssets)]), layout = c(1,nExp), colorkey = TRUE, origin=0, horizonscale = y_max/3, main=paste("Increment in wealth of TRENDs (averaged over runs) - Asset ",k)))
}

for (k in seq(from=1, to=nAssets)) {
   y_max = max(abs(tsLSwealth_avg[,1:(nAssets*nExp)]))
   print(horizonplot(ts(tsLSwealth_avg[,seq(k,nAssets*nExp,nAssets)]), layout = c(1,nExp), colorkey = TRUE, origin=0, horizonscale = y_max/3, main=paste("Increment in wealth of LS's (averaged over runs) - Asset ",k)))
}


### Plot of wealth increment (for individual runs)

y_max = max(max(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)]), max(tsLSwealth[,2:(nAssets*nRuns*nExp+1)]))
y_min = min(min(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)]), min(tsLSwealth[,2:(nAssets*nRuns*nExp+1)]))

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
            plot(tsFUNDwealth[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Wealth", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max), col="darkorange1")
            lines(tsTRENDwealth[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
            lines(tsLSwealth[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            plot(tsFUNDwealth[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Wealth", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max), col="darkorange1")
            lines(tsTRENDwealth[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
            lines(tsLSwealth[[i+k +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
         }
      }
      title(paste("Increment in wealth of FUNDs/TRENDs/LS's - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Objective: Study which group of agents performs better (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


### Plot of final wealth (averaged over runs)

y_max = max(max(tsFUNDwealth_avg[nTicks,1:(nAssets*nExp)]), max(tsTRENDwealth_avg[nTicks,1:(nAssets*nExp)]), max(tsLSwealth_avg[nTicks,1:(nAssets*nExp)]))
y_min = min(min(tsFUNDwealth_avg[nTicks,1:(nAssets*nExp)]), min(tsTRENDwealth_avg[nTicks,1:(nAssets*nExp)]), min(tsLSwealth_avg[nTicks,1:(nAssets*nExp)]))

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)
   plot(tsFUNDwealth_avg[nTicks, indices], type="l", main=paste("Asset", k), xlab="Experiment", ylab="Wealth", ylim=c(y_min, y_max), lwd=2, col="darkorange1")
   lines(tsTRENDwealth_avg[nTicks, indices], type="l", col="seagreen", lwd=2)
   lines(tsLSwealth_avg[nTicks, indices], type="l", col="blue", lwd=2)
}
title(paste("Total increment in wealth of FUNDs vs TRENDs vs LS's (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study which group of agents performs better (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


# Version for the thesis 
y_max = max(max(tsFUNDwealth_avg[nTicks,1:(nAssets*nExp)]), max(tsTRENDwealth_avg[nTicks,1:(nAssets*nExp)]), max(tsLSwealth_avg[nTicks,1:(nAssets*nExp)]))
y_min = min(min(tsFUNDwealth_avg[nTicks,1:(nAssets*nExp)]), min(tsTRENDwealth_avg[nTicks,1:(nAssets*nExp)]), min(tsLSwealth_avg[nTicks,1:(nAssets*nExp)]))
x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "", "20", "", "", "35", "", "", "50", "", "", "65", "", "", "80")

#dev.new()
k=1
indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)
plot(tsFUNDwealth_avg[nTicks, indices], type="l", main="", xlab="Porcentaje de agentes con límite anticíclico", ylab="", ylim=c(y_min, y_max), lwd=2, col="darkorange1", xaxt='n')
lines(tsTRENDwealth_avg[nTicks, indices], type="l", col="seagreen", lwd=2)
lines(tsLSwealth_avg[nTicks, indices], type="l", col="blue", lwd=2)
axis(1, at=1:nExp, labels=x_axis)
legend("topright", c("Fundamentalistas","Técnicos", "Long-short"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen", "royalblue3"))



### Plot of ratio between mean and standard deviation of final wealth (~Sharpe ratio) [mean and stdev calculated over runs]

Sharpe_FUND <- array(0, dim=c(nExp, nAssets))   # Array to store the Sharpe ratio for each asset and experiment
Sharpe_TREND <- array(0, dim=c(nExp, nAssets))
Sharpe_LS <- array(0, dim=c(nExp, nAssets))

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (i in seq(from=1, to=nAssets)) {
   for (e in seq(from=1, to=nExp)) {
      final_FUND_wealth <- rep(0, nRuns)   # Vectors to store final wealth for each run
      final_TREND_wealth <- rep(0, nRuns)
      final_LS_wealth <- rep(0, nRuns)

      for (j in seq(from=0, to=nRuns-1)) {
         final_FUND_wealth[j+1] = tsFUNDwealth[nTicks, 1+i+j*nAssets+(e-1)*nAssets*nRuns]
         final_TREND_wealth[j+1] = tsTRENDwealth[nTicks, 1+i+j*nAssets+(e-1)*nAssets*nRuns]
         final_LS_wealth[j+1] = tsLSwealth[nTicks, 1+i+j*nAssets+(e-1)*nAssets*nRuns]
      }
	# final_FUND_wealth <- final_FUND_wealth[-8]
	# final_TREND_wealth <- final_TREND_wealth[-8]
      # final_FUND_wealth <- final_FUND_wealth[-31]
      # final_TREND_wealth <- final_TREND_wealth[-31]

      if (sd(final_FUND_wealth) > 0) {
         Sharpe_FUND[e,i] = mean(final_FUND_wealth)/sd(final_FUND_wealth)
      }
      if (sd(final_TREND_wealth) > 0) {
         Sharpe_TREND[e,i] = mean(final_TREND_wealth)/sd(final_TREND_wealth)
      }
      if (sd(final_LS_wealth) > 0) {
         Sharpe_LS[e,i] = mean(final_LS_wealth)/sd(final_LS_wealth)
      }
   }
   
   y_max = max(max(Sharpe_FUND[,i]), max(Sharpe_TREND[,i]), max(Sharpe_LS[,i]))
   y_min = min(min(Sharpe_FUND[,i]), min(Sharpe_TREND[,i]), min(Sharpe_LS[,i]))

   plot(Sharpe_FUND[,i], type="l", main=paste("Asset", i), xlab="Experiment", ylab="mean(wealth)/sd(wealth)", ylim=c(y_min,y_max), lwd=2, col="darkorange1")
   lines(Sharpe_TREND[,i], type="l", col="seagreen", lwd=2)
   lines(Sharpe_LS[,i], type="l", col="royalblue3", lwd=2)
}
title(paste("'Sharpe ratio': Mean of final wealth increment of FUNDs vs TRENDs vs LS's, \n divided by std dev of final wealth (over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study which group of agents performs better, taking into account the volatility of their results (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


# Version for the thesis 

i=1
y_max = max(max(Sharpe_FUND[,i]), max(Sharpe_TREND[,i]), max(Sharpe_LS[,i]))
y_min = min(min(Sharpe_FUND[,i]), min(Sharpe_TREND[,i]), min(Sharpe_LS[,i]))
x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "", "20", "", "", "35", "", "", "50", "", "", "65", "", "", "80")

#dev.new()
par(mfrow=c(nAssets,1), mar=c(1,1,2,1), oma=c(3,3,5,3))
plot(Sharpe_FUND[,i], type="l", main="", xlab="Porcentaje de agentes con límite anticíclico", ylab="", ylim=c(y_min,y_max), lwd=2, col="darkorange1", xaxt='n')
lines(Sharpe_TREND[,i], type="l", col="seagreen", lwd=2)
lines(Sharpe_LS[,i], type="l", col="royalblue3", lwd=2)
axis(1, at=1:nExp, labels=x_axis)
legend("topleft", c("Fundamentalistas","Técnicos", "Long-short"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen", "royalblue3"))


# Version for the JEDC article

i=1
y_max = max(max(Sharpe_FUND[,i]), max(Sharpe_TREND[,i]))
y_min = min(min(Sharpe_FUND[,i]), min(Sharpe_TREND[,i]))
#x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")

#dev.new()
par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))
plot(Sharpe_FUND[,i], type="l", main="Strength index", xlab="VaR limit", ylab="", ylim=c(y_min,y_max), lwd=2, col="darkorange1", xaxt='n')
lines(Sharpe_TREND[,i], type="l", col="seagreen", lwd=2)
axis(1, at=1:nExp, labels=x_axis)
legend("bottomright", c("FUND","TREND"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen"))


#### Bar charts of FUND/TREND/LS final wealth for EACH individual run
##
## Objective: Compare the relative wealth accumulated by each group of traders
## at the end of the simulation
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows, numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#            wealth <- c(tsFUNDwealth[[k+1+i +(e-1)*nAssets*nRuns]][nTicks], tsTRENDwealth[[k+1+i +(e-1)*nAssets*nRuns]][nTicks], tsLSwealth[[k+1+i +(e-1)*nAssets*nRuns]][nTicks])
#            labels <- c("FUND", "TREND", "LS") 
#            barplot(wealth, names = labels, col=c("darkorange1", "seagreen", "royalblue3"), main=paste("Run", 1+i/nAssets))
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            wealth <- c(tsFUNDwealth[[k+i +(e-1)*nAssets*nRuns]][nTicks], tsTRENDwealth[[k+i +(e-1)*nAssets*nRuns]][nTicks], tsLSwealth[[k+i +(e-1)*nAssets*nRuns]][nTicks])
#            labels <- c("FUND", "TREND", "LS") 
#            barplot(wealth, names = labels, col=c("darkorange1", "seagreen", "royalblue3"), main=paste("Run", 1+(i-1)/nAssets))
#         }
#      }
#      title(paste("Final wealth along simulations - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Compare the final wealth accumulated by each strategy.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}


### Bar charts of FUND/TREND/LS final wealth (averaged over runs)
#
# Objective: Compare the relative wealth accumulated by each group of traders
# at the end of the simulations, averaged over runs

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      wealth <- c(tsFUNDwealth_avg[nTicks,(e-1)*nAssets+k], tsTRENDwealth_avg[nTicks,(e-1)*nAssets+k], tsLSwealth_avg[nTicks,(e-1)*nAssets+k])
      labels <- c("FUND", "TREND", "LS")
      barplot(wealth, names = labels, col=c("darkorange1", "seagreen", "royalblue3"), main=paste("Exp", e))
   }
   title(paste("Final wealth, averaged over runs - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Compare the final wealth accumulated by each strategy (over experiments).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}



### Scatterplot of volume and wealth along experiments
#
# Objective: Compare the mean wealth and volume by each group of traders

for (k in seq(from=1, to=nAssets)) {

   # Build data arrays to plot scatterplots

   volume_F_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , volume of FUNDs)
   volume_T_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , volume of TRENDs)
   volume_L_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , volume of LS's)

   wealth_F_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , wealth increment of FUNDs)
   wealth_T_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , wealth increment of TRENDs)
   wealth_L_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , wealth increment of LS's)
      
   for (e in seq(from=0, to=nExp-1)) {
      for (i in seq(from=0, to=nRuns-1)) {
	   volume_F_matrix[i+1+e*nRuns,1] = e+1
	   volume_F_matrix[i+1+e*nRuns,2] = mean(tsFUNDvolume[[k+1+i*nAssets+e*nAssets*nRuns]])

	   volume_T_matrix[i+1+e*nRuns,1] = e+1
	   volume_T_matrix[i+1+e*nRuns,2] = mean(tsTRENDvolume[[k+1+i*nAssets+e*nAssets*nRuns]])

	   volume_L_matrix[i+1+e*nRuns,1] = e+1
	   volume_L_matrix[i+1+e*nRuns,2] = mean(tsLSvolume[[k+1+i*nAssets+e*nAssets*nRuns]])

	   wealth_F_matrix[i+1+e*nRuns,1] = e+1
         wealth_F_matrix[i+1+e*nRuns,2] = mean(tsFUNDwealth[[k+1+i*nAssets+e*nAssets*nRuns]])

	   wealth_T_matrix[i+1+e*nRuns,1] = e+1
	   wealth_T_matrix[i+1+e*nRuns,2] = mean(tsTRENDwealth[[k+1+i*nAssets+e*nAssets*nRuns]])

	   wealth_L_matrix[i+1+e*nRuns,1] = e+1
	   wealth_L_matrix[i+1+e*nRuns,2] = mean(tsLSwealth[[k+1+i*nAssets+e*nAssets*nRuns]])
      }
   }

   # Place the plots in a 2x2 matrix

   par(mfrow=c(2,3), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

   plot(volume_F_matrix[,1], volume_F_matrix[,2], main="Volume FUNDs", xlab="Experiment", ylab="Volume FUNDs", pch=21, col="darkorange1")
   abline(lin_reg <- lm(volume_F_matrix[,2]~volume_F_matrix[,1]), col="red")   # regression line (volume_F ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   plot(volume_T_matrix[,1], volume_T_matrix[,2], main="Volume TRENDs", xlab="Experiment", ylab="Volume TRENDs", pch=21, col="seagreen")
   abline(lin_reg <- lm(volume_T_matrix[,2]~volume_T_matrix[,1]), col="red")   # regression line (volume_T ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   plot(volume_L_matrix[,1], volume_L_matrix[,2], main="Volume LS's", xlab="Experiment", ylab="Volume LS's", pch=21, col="blue")
   abline(lin_reg <- lm(volume_L_matrix[,2]~volume_L_matrix[,1]), col="red")   # regression line (volume_L ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file


   plot(wealth_F_matrix[,1], wealth_F_matrix[,2], main="Wealth increment FUNDs", xlab="Experiment", ylab="Wealth FUNDs", pch=21, col="darkorange1")
   abline(lin_reg <- lm(wealth_F_matrix[,2]~wealth_F_matrix[,1]), col="red")   # regression line (wealth_F ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   plot(wealth_T_matrix[,1], wealth_T_matrix[,2], main="Wealth increment TRENDs", xlab="Experiment", ylab="Wealth TRENDs", pch=21, col="seagreen")
   abline(lin_reg <- lm(wealth_T_matrix[,2]~wealth_T_matrix[,1]), col="red")   # regression line (wealth_T ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   plot(wealth_L_matrix[,1], wealth_L_matrix[,2], main="Wealth increment LSs", xlab="Experiment", ylab="Wealth LS's", pch=21, col="blue")
   abline(lin_reg <- lm(wealth_L_matrix[,2]~wealth_L_matrix[,1]), col="red")   # regression line (wealth_L ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   title(paste("Impact of changing parameter - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext(paste("Objective: Study which variables are affected by the changing parameter"), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}




##_____________________________________________________________#
##                                                             #
##               TOTAL VOLUME vs SELL-OFF VOLUME               #
##_____________________________________________________________#
##                                                             #
#
## We plot here the total volume of FUNDs, TRENDs and LS's, together
## with their sell-off volume, to get an idea of the size (and 
## potential impact) of the portfolio reductions in comparison to the
## total trading volume
#
#### Plot of time series of volume + sell-off volume (averaged over runs)
#
#y_max_V = max(max(tsFUNDvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvolume_avg[,1:(nAssets*nExp)]), max(tsLSvolume_avg[,1:(nAssets*nExp)]))
#y_min_V = min(min(tsFUNDvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvolume_avg[,1:(nAssets*nExp)]), min(tsLSvolume_avg[,1:(nAssets*nExp)]))
#
#y_max_SO = max(max(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))
#y_min_SO = min(min(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))
#
#y_max = max(y_max_V, y_max_SO)
#y_min = min(y_min_V, y_min_SO)
#
## FUNDs
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#
#   for (e in seq(from=1, to=nExp)) {
#	plot(tsFUNDvolume_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="", col="darkorange1")
#	lines(tsFUNDselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="coral4")
#
#	# Show average of volume and sell-off volume
#	mtext(paste("avg_vol =", round(mean(tsFUNDvolume_avg[,(e-1)*nAssets+k]),1), " / avg_selloff_vol =", round(mean(tsFUNDselloffvolume_avg[,(e-1)*nAssets+k]),1)) , side=3, line=0.1, cex=0.6, col="red")
#   }
#   title(paste("Total volume + sell-off volume of FUNDs (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
#   mtext("Objective: Get an idea of the size of sell-off volume w.r.t. total volume (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
## TRENDs
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#
#   for (e in seq(from=1, to=nExp)) {
#	plot(tsTRENDvolume_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="", col="seagreen")
#	lines(tsTRENDselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen2")
#
#	# Show average of volume and sell-off volume
#	mtext(paste("avg_vol =", round(mean(tsTRENDvolume_avg[,(e-1)*nAssets+k]),1), " / avg_selloff_vol =", round(mean(tsTRENDselloffvolume_avg[,(e-1)*nAssets+k]),1)) , side=3, line=0.1, cex=0.6, col="red")
#   }
#   title(paste("Total volume + sell-off volume of TRENDs (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Get an idea of the size of sell-off volume w.r.t. total volume (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
## LS
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#
#   for (e in seq(from=1, to=nExp)) {
#	plot(tsLSvolume_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="", col="royalblue3")
#	lines(tsLSselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="skyblue2")
#
#	# Show average of volume and sell-off volume
#	mtext(paste("avg_vol =", round(mean(tsLSvolume_avg[,(e-1)*nAssets+k]),1), " / avg_selloff_vol =", round(mean(tsLSselloffvolume_avg[,(e-1)*nAssets+k]),1)) , side=3, line=0.1, cex=0.6, col="red")
#   }
#   title(paste("Total volume + sell-off volume of LS's (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Get an idea of the size of sell-off volume w.r.t. total volume (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#


##____________________________________________________________#
##                                                            #
##              PERFORMANCE vs REDUCTION VOLUME               #
##____________________________________________________________#
##                                                            #
#
## We plot here the reduced volume of FUNDs, TRENDs and LS's, together
## with their average increment in wealth, to see if VaR limits have any
## effect on the performance of agents
#
#### Plot of time series of wealth increment + reduction volume (averaged over runs)
#
#y_max_W = max(max(tsFUNDwealth_avg[,1:(nAssets*nExp)]), max(tsTRENDwealth_avg[,1:(nAssets*nExp)]), max(tsLSwealth_avg[,1:(nAssets*nExp)]))
#y_min_W = min(min(tsFUNDwealth_avg[,1:(nAssets*nExp)]), min(tsTRENDwealth_avg[,1:(nAssets*nExp)]), min(tsLSwealth_avg[,1:(nAssets*nExp)]))
#
#y_max_RV = max(max(tsFUNDreducedvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDreducedvolume_avg[,1:(nAssets*nExp)]), max(tsLSreducedvolume_avg[,1:(nAssets*nExp)]))
#y_min_RV = min(min(tsFUNDreducedvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDreducedvolume_avg[,1:(nAssets*nExp)]), min(tsLSreducedvolume_avg[,1:(nAssets*nExp)]))
#
#x_axis <- seq(1,nTicks,1)
#
## FUNDs
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#
#   for (e in seq(from=1, to=nExp)) {
#
#	# Plot time series of wealth increment (averaged over runs)
#	plot(x=x_axis, y=tsFUNDwealth_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min_W,y_max_W), xlab="Tick", 
#		ylab="", col="darkorange1", xaxt='n', yaxt='n')
#	axis(2, pretty(c(y_min_W, y_max_W)), col="darkorange1")
#
#	# Plot time series of reduction volume (averaged over runs) 
#	par(new=T)  # Plot second time series
#	plot(x=x_axis, y=tsFUNDreducedvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
#		ylab="Wealth vs Red. volume", col="coral4", xaxt='n', axes=F)
#	axis(4, pretty(c(y_min_RV, y_max_RV)), col="coral4")
#
#	# Add x axis
#	axis(1, pretty(range(x_axis)))
#
#	# Show average of wealth
#	mtext(paste("avg_W =", round(mean(tsFUNDwealth_avg[,(e-1)*nAssets+k]),1)) , side=3, line=0.1, cex=0.6, col="red")
#   }
#   title(paste("Increment in wealth + reduction volume of FUNDs (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study the effect of VaR limits on wealth increment (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
## TRENDs
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#
#   for (e in seq(from=1, to=nExp)) {
#
#	# Plot time series of wealth increment (averaged over runs)
#	plot(x=x_axis, y=tsTRENDwealth_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min_W,y_max_W), xlab="Tick", 
#		ylab="", col="seagreen", xaxt='n', yaxt='n')
#	axis(2, pretty(c(y_min_W, y_max_W)), col="seagreen")
#
#	# Plot time series of reduction volume (averaged over runs) 
#	par(new=T)  # Plot second time series
#	plot(x=x_axis, y=tsTRENDreducedvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
#		ylab="Wealth vs Red. volume", col="seagreen2", xaxt='n', axes=F)
#	axis(4, pretty(c(y_min_RV, y_max_RV)), col="seagreen2")
#
#	# Add x axis
#	axis(1, pretty(range(x_axis)))
#
#	# Show average of wealth
#	mtext(paste("avg_W =", round(mean(tsTRENDwealth_avg[,(e-1)*nAssets+k]),1)) , side=3, line=0.1, cex=0.6, col="red")
#   }
#   title(paste("Increment in wealth + reduction volume of TRENDs (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study the effect of VaR limits on wealth increment (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
## LS
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#
#   for (e in seq(from=1, to=nExp)) {
#
#	# Plot time series of wealth increment (averaged over runs)
#	plot(x=x_axis, y=tsLSwealth_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min_W,y_max_W), xlab="Tick", 
#		ylab="", col="royalblue3", xaxt='n', yaxt='n')
#	axis(2, pretty(c(y_min_W, y_max_W)), col="royalblue3")
#
#	# Plot time series of reduction volume (averaged over runs) 
#	par(new=T)  # Plot second time series
#	plot(x=x_axis, y=tsLSreducedvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
#		ylab="Wealth vs Red. volume", col="skyblue2", xaxt='n', axes=F)
#	axis(4, pretty(c(y_min_RV, y_max_RV)), col="skyblue2")
#
#	# Add x axis
#	axis(1, pretty(range(x_axis)))
#
#	# Show average of wealth
#	mtext(paste("avg_W =", round(mean(tsLSwealth_avg[,(e-1)*nAssets+k]),1)) , side=3, line=0.1, cex=0.6, col="red")
#   }
#   title(paste("Increment in wealth + reduction volume of LS's (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study the effect of VaR limits on wealth increment (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#
##### Plot of time series of wealth increment + reduction volume (for individual runs)
##
##y_max_W = max(max(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)]), max(tsLSwealth[,2:(nAssets*nRuns*nExp+1)]))
##y_min_W = min(min(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)]), min(tsLSwealth[,2:(nAssets*nRuns*nExp+1)]))
##
##y_max_RV = max(max(tsFUNDreducedvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDreducedvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsLSreducedvolume[,2:(nAssets*nRuns*nExp+1)]))
##y_min_RV = min(min(tsFUNDreducedvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDreducedvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsLSreducedvolume[,2:(nAssets*nRuns*nExp+1)]))
##
##x_axis <- seq(1,nTicks,1)
##
### FUNDs
##
##for (e in seq(from=1, to=nExp)) {
##   for (k in seq(from=1, to=nAssets)) {
##   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
##      if (nRuns>numRows*numCols){
##         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
##
##		# Plot time series of wealth increment
##		plot(x=x_axis, y=tsFUNDwealth[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main=paste("Run", 1+i/nAssets), ylim=c(y_min_W,y_max_W), xlab="Tick", 
##			ylab="", col="darkorange1", xaxt='n', yaxt='n')
##		axis(2, pretty(c(y_min_W, y_max_W)), col="darkorange1")
##
##		# Plot time series of reduction volume
##		par(new=T)  # Plot second time series
##		plot(x=x_axis, y=tsFUNDreducedvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
##			ylab="Wealth vs Red. volume", col="coral4", xaxt='n', axes=F)
##		axis(4, pretty(c(y_min_RV, y_max_RV)), col="coral4")
##
##		# Add x axis
##		axis(1, pretty(range(x_axis)))
##         }
##      } else {
##         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
##
##		# Plot time series of wealth increment
##		plot(x=x_axis, y=tsFUNDwealth[[i+k +(e-1)*nAssets*nRuns]], type="l", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min_W,y_max_W), xlab="Tick", 
##			ylab="", col="darkorange1", xaxt='n', yaxt='n')
##		axis(2, pretty(c(y_min_W, y_max_W)), col="darkorange1")
##
##		# Plot time series of reduction volume
##		par(new=T)  # Plot second time series
##		plot(x=x_axis, y=tsFUNDreducedvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
##			ylab="Wealth vs Red. volume", col="coral4", xaxt='n', axes=F)
##		axis(4, pretty(c(y_min_RV, y_max_RV)), col="coral4")
##
##		# Add x axis
##		axis(1, pretty(range(x_axis)))
##         }
##      }
##      title(paste("Increment in wealth + reduction volume of FUNDs - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
##      mtext("Objective:Study the effect of VaR limits on wealth increment. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
##      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
##   }
##}
##
##
### TRENDs
##
##for (e in seq(from=1, to=nExp)) {
##   for (k in seq(from=1, to=nAssets)) {
##   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
##      if (nRuns>numRows*numCols){
##         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
##
##		# Plot time series of wealth increment
##		plot(x=x_axis, y=tsTRENDwealth[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main=paste("Run", 1+i/nAssets), ylim=c(y_min_W,y_max_W), xlab="Tick", 
##			ylab="", col="seagreen", xaxt='n', yaxt='n')
##		axis(2, pretty(c(y_min_W, y_max_W)), col="seagreen")
##
##		# Plot time series of reduction volume
##		par(new=T)  # Plot second time series
##		plot(x=x_axis, y=tsTRENDreducedvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
##			ylab="Wealth vs Red. volume", col="seagreen2", xaxt='n', axes=F)
##		axis(4, pretty(c(y_min_RV, y_max_RV)), col="seagreen2")
##
##		# Add x axis
##		axis(1, pretty(range(x_axis)))
##         }
##      } else {
##         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
##
##		# Plot time series of wealth increment
##		plot(x=x_axis, y=tsTRENDwealth[[i+k +(e-1)*nAssets*nRuns]], type="l", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min_W,y_max_W), xlab="Tick", 
##			ylab="", col="seagreen", xaxt='n', yaxt='n')
##		axis(2, pretty(c(y_min_W, y_max_W)), col="seagreen")
##
##		# Plot time series of reduction volume
##		par(new=T)  # Plot second time series
##		plot(x=x_axis, y=tsTRENDreducedvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
##			ylab="Wealth vs Red. volume", col="seagreen2", xaxt='n', axes=F)
##		axis(4, pretty(c(y_min_RV, y_max_RV)), col="seagreen2")
##
##		# Add x axis
##		axis(1, pretty(range(x_axis)))
##         }
##      }
##      title(paste("Increment in wealth + reduction volume of TRENDs - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
##      mtext("Objective:Study the effect of VaR limits on wealth increment. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
##      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
##   }
##}
##
##
### LS
##
##for (e in seq(from=1, to=nExp)) {
##   for (k in seq(from=1, to=nAssets)) {
##   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
##      if (nRuns>numRows*numCols){
##         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
##
##		# Plot time series of wealth increment
##		plot(x=x_axis, y=tsLSwealth[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main=paste("Run", 1+i/nAssets), ylim=c(y_min_W,y_max_W), xlab="Tick", 
##			ylab="", col="royalblue3", xaxt='n', yaxt='n')
##		axis(2, pretty(c(y_min_W, y_max_W)), col="royalblue3")
##
##		# Plot time series of reduction volume
##		par(new=T)  # Plot second time series
##		plot(x=x_axis, y=tsLSreducedvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
##			ylab="Wealth vs Red. volume", col="skyblue2", xaxt='n', axes=F)
##		axis(4, pretty(c(y_min_RV, y_max_RV)), col="skyblue2")
##
##		# Add x axis
##		axis(1, pretty(range(x_axis)))
##         }
##      } else {
##         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
##
##		# Plot time series of wealth increment
##		plot(x=x_axis, y=tsLSwealth[[i+k +(e-1)*nAssets*nRuns]], type="l", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min_W,y_max_W), xlab="Tick", 
##			ylab="", col="royalblue3", xaxt='n', yaxt='n')
##		axis(2, pretty(c(y_min_W, y_max_W)), col="royalblue3")
##
##		# Plot time series of reduction volume
##		par(new=T)  # Plot second time series
##		plot(x=x_axis, y=tsLSreducedvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
##			ylab="Wealth vs Red. volume", col="skyblue2", xaxt='n', axes=F)
##		axis(4, pretty(c(y_min_RV, y_max_RV)), col="skyblue2")
##
##		# Add x axis
##		axis(1, pretty(range(x_axis)))
##         }
##      }
##      title(paste("Increment in wealth + reduction volume of LS's - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
##      mtext("Objective:Study the effect of VaR limits on wealth increment. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
##      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
##   }
##}



##_________________________________________________________________#
##                                                                 #
##           REDUCTION ORDERS OF FUNDs vs TRENDs vs LS's           #
##_________________________________________________________________#
##                                                                 #
#
#### Reduction orders of FUNDs, TRENDs and LS's (averaged over runs)
##
## Objective: Study if the reduction orders of one group induces reductions
## in the portfolio of the other agent groups
#
#y_max = max(max(tsFUNDreducedorders_avg[,1:(nAssets*nExp)]), max(tsTRENDreducedorders_avg[,1:(nAssets*nExp)]), max(tsLSreducedorders_avg[,1:(nAssets*nExp)]))
#y_min = min(min(tsFUNDreducedorders_avg[,1:(nAssets*nExp)]), min(tsTRENDreducedorders_avg[,1:(nAssets*nExp)]), min(tsLSreducedorders_avg[,1:(nAssets*nExp)]))
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   for (e in seq(from=1, to=nExp)) {      
#      plot(tsFUNDreducedorders_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Red. orders", col="darkorange1")
#      lines(tsTRENDreducedorders_avg[,(e-1)*nAssets+k], type="l", col="seagreen")
#      lines(tsLSreducedorders_avg[,(e-1)*nAssets+k], type="l", col="royalblue3")
#   }
#   title(paste("Reduction orders of FUNDs/TRENDs/LS's (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study if the reduction orders sent by one group induces reductions by other groups (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Plot of reduction orders of FUNDs, TRENDs and LS's (for individual runs)
#
#y_max = max(max(tsFUNDreducedorders[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDreducedorders[,2:(nAssets*nRuns*nExp+1)]), max(tsLSreducedorders[,2:(nAssets*nRuns*nExp+1)]))
#y_min = min(min(tsFUNDreducedorders[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDreducedorders[,2:(nAssets*nRuns*nExp+1)]), min(tsLSreducedorders[,2:(nAssets*nRuns*nExp+1)]))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#            plot(tsFUNDreducedorders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Red. orders", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDreducedorders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
#            lines(tsLSreducedorders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(tsFUNDreducedorders[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Red. orders", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDreducedorders[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
#            lines(tsLSreducedorders[[i+k +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
#         }
#      }
#      title(paste("Reduction orders of FUNDs/TRENDs/LS's - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Study if the reduction orders sent by one group induces reductions by other groups (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}
#
#
#
##_________________________________________________________________#
##                                                                 #
##           REDUCTION VOLUME OF FUNDs vs TRENDs vs LS's           #
##_________________________________________________________________#
##                                                                 #
#
#### Reduction volume of FUNDs, TRENDs and LS's (averaged over runs)
##
## Objective: Study if the reduction orders of one group induces reductions
## in the portfolio of the other agent groups
#
#y_max = max(max(tsFUNDreducedvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDreducedvolume_avg[,1:(nAssets*nExp)]), max(tsLSreducedvolume_avg[,1:(nAssets*nExp)]))
#y_min = min(min(tsFUNDreducedvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDreducedvolume_avg[,1:(nAssets*nExp)]), min(tsLSreducedvolume_avg[,1:(nAssets*nExp)]))
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   for (e in seq(from=1, to=nExp)) {      
#      plot(tsFUNDreducedvolume_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Red. volume", col="darkorange1")
#      lines(tsTRENDreducedvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")
#      lines(tsLSreducedvolume_avg[,(e-1)*nAssets+k], type="l", col="royalblue3")
#   }
#   title(paste("Reduction volume of FUNDs/TRENDs/LS's (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study if the reduction orders sent by one group induces reductions by other groups (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Plot of reduction volume of FUNDs, TRENDs and LS's (for individual runs)
#
#y_max = max(max(tsFUNDreducedvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDreducedvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsLSreducedvolume[,2:(nAssets*nRuns*nExp+1)]))
#y_min = min(min(tsFUNDreducedvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDreducedvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsLSreducedvolume[,2:(nAssets*nRuns*nExp+1)]))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
#            plot(tsFUNDreducedvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Red. volume", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDreducedvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
#            lines(tsLSreducedvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(tsFUNDreducedvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Red. volume", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDreducedvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
#            lines(tsLSreducedvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
#         }
#      }
#      title(paste("Reduction volume of FUNDs/TRENDs/LS's - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Study if the reduction orders sent by one group induces reductions by other groups (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}
#



#_________________________________________________________________#
#                                                                 #
#            SELL-OFF ORDERS OF FUNDs vs TRENDs vs LS's           #
#_________________________________________________________________#
#                                                                 #

#### Sell-off orders of FUNDs, TRENDs and LS's (averaged over runs)
##
## Objective: Study if the sell-off orders of one group induces sell-off
## orders from the other agent groups
#
#y_max = max(max(tsFUNDsellofforders_avg[,1:(nAssets*nExp)]), max(tsTRENDsellofforders_avg[,1:(nAssets*nExp)]), max(tsLSsellofforders_avg[,1:(nAssets*nExp)]))
#y_min = min(min(tsFUNDsellofforders_avg[,1:(nAssets*nExp)]), min(tsTRENDsellofforders_avg[,1:(nAssets*nExp)]), min(tsLSsellofforders_avg[,1:(nAssets*nExp)]))
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   for (e in seq(from=1, to=nExp)) {      
#      plot(tsFUNDsellofforders_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Sell-off orders", col="darkorange1")
#      lines(tsTRENDsellofforders_avg[,(e-1)*nAssets+k], type="l", col="seagreen")
#      lines(tsLSsellofforders_avg[,(e-1)*nAssets+k], type="l", col="royalblue3")
#   }
#   title(paste("Sell-off orders of FUNDs/TRENDs/LS's (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study if the sell-off orders sent by one group induces sell-offs by other groups (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Plot of sell-off orders of FUNDs, TRENDs and LS's (for individual runs)
#
#y_max = max(max(tsFUNDsellofforders[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDsellofforders[,2:(nAssets*nRuns*nExp+1)]), max(tsLSsellofforders[,2:(nAssets*nRuns*nExp+1)]))
#y_min = min(min(tsFUNDsellofforders[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDsellofforders[,2:(nAssets*nRuns*nExp+1)]), min(tsLSsellofforders[,2:(nAssets*nRuns*nExp+1)]))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#            plot(tsFUNDsellofforders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Sell-off orders", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDsellofforders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
#            lines(tsLSsellofforders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(tsFUNDsellofforders[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Sell-off orders", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDsellofforders[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
#            lines(tsLSsellofforders[[i+k +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
#         }
#      }
#      title(paste("Sell-off orders of FUNDs/TRENDs/LS's - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Study if the sell-off orders sent by one group induces sell-offs by other groups (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}


#_________________________________________________________________#
#                                                                 #
#            SELL-OFF VOLUME OF FUNDs vs TRENDs vs LS's           #
#_________________________________________________________________#
#                                                                 #

#### Sell-off volume of FUNDs, TRENDs and LS's (averaged over runs)
##
## Objective: Study if the sell-off orders of one group induces sell-offs
## by the other agent groups
#
#y_max = max(max(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))
#y_min = min(min(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   for (e in seq(from=1, to=nExp)) {      
#      plot(tsFUNDselloffvolume_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Sell-off volume", col="darkorange1")
#      lines(tsTRENDselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")
#      lines(tsLSselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="royalblue3")
#   }
#   title(paste("Sell-off volume of FUNDs/TRENDs/LS's (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study if the sell-off orders sent by one group induces sell-offs by other groups (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Plot of sell-off volume of FUNDs, TRENDs and LS's (for individual runs)
#
#y_max = max(max(tsFUNDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsLSselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
#y_min = min(min(tsFUNDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsLSselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
#            plot(tsFUNDselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Sell-off volume", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
#            lines(tsLSselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(tsFUNDselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Sell-off volume", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
#            lines(tsLSselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
#         }
#      }
#      title(paste("Sell-off volume of FUNDs/TRENDs/LS's - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Study if the sell-off orders sent by one group induces sell-offs by other groups (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}
#


#____________________________________________________________________#
#                                                                    #
#                     PRICES vs SELL-OFF VOLUME                      #
#____________________________________________________________________#
#                                                                    #

# We plot here the sell-off volume of FUNDs, TRENDs and LS's, together
# with the series of prices, to see the effect of VaR limits on price movements

### Plot of time series of price + sell-off volume (averaged over runs)

y_max_P =  max(tsprices_avg[,1:(nAssets*nExp)])
y_min_P =  min(tsprices_avg[,1:(nAssets*nExp)])

y_max_SO = max(max(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))
y_min_SO = min(min(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))

x_axis <- seq(1,nTicks,1)

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))

   for (e in seq(from=1, to=nExp)) {

	# Plot time series of price (averaged over runs)
	plot(x=x_axis, y=tsprices_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min_P,y_max_P), xlab="Tick", 
		ylab="", col="black", xaxt='n', yaxt='n')
	axis(2, pretty(c(y_min_P, y_max_P)), col="black")

	# Plot time series of sell-off volume (averaged over runs)
	par(new=T)  # Plot second time series
	plot(x=x_axis, y=tsFUNDselloffvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
	lines(tsTRENDselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")  
      lines(tsLSselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="royalblue3")
	axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

	# Add x axis
	axis(1, pretty(range(x_axis)))
   }
   title(paste("Price + sell-off volume of FUND/TREND/LS (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Study the effect of VaR limits on price (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}



###################################################################
#                                                                 #
#                      INSTABILITY INDICATORS                     #
#                                                                 #
###################################################################

#____________________________________________________________________#
#                                                                    #
#              VOLATILITY OF PRICES vs SELL-OFF VOLUME               #
#____________________________________________________________________#
#                                                                    #

# We plot here the sell-off volume of FUNDs, TRENDs and LS's, together
# with the volatility of prices, to see the effect of VaR limits on volatility

### Calculate series of price volatility

tsvolatility <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))
tsvolatility_avg <- array(0, dim=c(nTicks, nAssets*nExp))
mean_tsvolatility_th <- array(0, dim=c(nRuns, nAssets*nExp))

for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
   for (i in seq(from=1, to=nTicks-volWindow)) {
      tsvolatility[i+volWindow,j] <- sd(tsprices[(i+1):(i+volWindow),1+j], na.rm = FALSE)
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         tsvolatility_avg[,i+k*nAssets] <- tsvolatility_avg[,i+k*nAssets] + tsvolatility[,i+j*nAssets+k*nAssets*nRuns]
         mean_tsvolatility_th[j+1,i+k*nAssets] <- mean(tsvolatility[(volWindow+1):nTicks,i+j*nAssets+k*nAssets*nRuns])
      }
      tsvolatility_avg[,i+k*nAssets] <- tsvolatility_avg[,i+k*nAssets]/nRuns
   }
}

### Plot of time series of price volatility + sell-off volume (averaged over runs)

y_max_V =  max(tsvolatility_avg[,1:(nAssets*nExp)])
y_min_V =  min(tsvolatility_avg[,1:(nAssets*nExp)])

y_max_SO = max(max(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))
y_min_SO = min(min(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))

x_axis <- seq(1,nTicks,1)

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))

   for (e in seq(from=1, to=nExp)) {

	# Plot time series of price volatility (averaged over runs)
	plot(x=x_axis, y=tsvolatility_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min_V,y_max_V), xlab="Tick", 
		ylab="", col="black", xaxt='n', yaxt='n')
	axis(2, pretty(c(y_min_V, y_max_V)), col="black")

	# Plot time series of sell-off volume (averaged over runs) 
	par(new=T)  # Plot second time series
	plot(x=x_axis, y=tsFUNDselloffvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
      lines(tsTRENDselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")  
      lines(tsLSselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="royalblue3")
	axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

	# Add x axis
	axis(1, pretty(range(x_axis)))

	# Show average of volatility time series
	mtext(paste("avg_volat =", round(mean(tsvolatility_avg[,(e-1)*nAssets+k]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
   }
   title(paste("Price volatility + sell-off volume of FUND/TREND/LS (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Study the effect of VaR limits on price volatility (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Plot of time series of price volatility + sell-off volume (for individual runs)

y_max_V = max(tsvolatility[,1:(nAssets*nRuns*nExp)])
y_min_V = min(tsvolatility[,1:(nAssets*nRuns*nExp)])

y_max_SO = max(max(tsFUNDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsLSselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
y_min_SO = min(min(tsFUNDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsLSselloffvolume[,2:(nAssets*nRuns*nExp+1)]))

x_axis <- seq(1,nTicks,1)

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {

		# Plot time series of price volatility
		plot(x=x_axis, y=tsvolatility[,i+k+1 +(e-1)*nAssets*nRuns-1], type="l", main=paste("Run", 1+i/nAssets), ylim=c(y_min_V,y_max_V), xlab="Tick", 
			ylab="", col="black", xaxt='n', yaxt='n')
		axis(2, pretty(c(y_min_V, y_max_V)), col="black")

		# Plot time series of sell-off volume
		par(new=T)  # Plot second time series
		plot(x=x_axis, y=tsFUNDselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
		lines(tsLSselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

		# Add x axis
		axis(1, pretty(range(x_axis)))

		# Show average of volatility time series
		mtext(paste("avg_volat =", round(mean(tsvolatility[,i+k+1 +(e-1)*nAssets*nRuns-1]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {

		# Plot time series of price volatility
		plot(x=x_axis, y=tsvolatility[,i+k +(e-1)*nAssets*nRuns-1], type="l", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min_V,y_max_V), xlab="Tick", 
			ylab="", col="black", xaxt='n', yaxt='n')
		axis(2, pretty(c(y_min_V, y_max_V)), col="black")

		# Plot time series of sell-off volume
		par(new=T)  # Plot second time series
		plot(x=x_axis, y=tsFUNDselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
		lines(tsLSselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")  
		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

		# Add x axis
		axis(1, pretty(range(x_axis)))

		# Show average of volatility time series
		mtext(paste("avg_volat =", round(mean(tsvolatility[,i+k +(e-1)*nAssets*nRuns-1]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
         }
      }
      title(paste("Price volatility + sell-off volume of FUND/TREND/LS - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Objective:Study the effect of VaR limits on price volatility. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


### Cross-correlation function of price volatility and sell-off volume (averaged over runs)
#
# Objective: Plot a cross-correlation function of price volatility and sell-off volume
# averaged over runs to study the correlation for different lags, in order to see
# if sell-off volume causes volatility, or vice-versa

tstotalselloffvolume_avg <- tsFUNDselloffvolume_avg + tsTRENDselloffvolume_avg + tsLSselloffvolume_avg

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))

   for (e in seq(from=1, to=nExp)) {
	ccf(tsvolatility_avg[,(e-1)*nAssets+k], tstotalselloffvolume_avg[,(e-1)*nAssets+k], ylab = "Cross-correlation", main=paste("Exp", e), ylim=c(-1,1), lag.max = 50)
   }
   title(paste("CCF of price volatility and sell-off volume - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Study if volatility causes sell-off orders, or vice-versa.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Cross-correlation function of price volatility and sell-off volume (for individual runs)
#
# Objective: Plot a cross-correlation function of price volatility and sell-off volume
# for single runs to study the correlation for different lags, in order to see
# if sell-off volume causes volatility, or vice-versa

tstotalselloffvolume <- tsFUNDselloffvolume + tsTRENDselloffvolume + tsLSselloffvolume
tstotalselloffvolume[[1]] <- tsFUNDselloffvolume[[1]]    # 'tick' column

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
       par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             ccf(tsvolatility[,i+1+k+(e-1)*nAssets*nRuns-1], tstotalselloffvolume[[i+1+k+(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1), lag.max = 50)
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            ccf(tsvolatility[,i+k +(e-1)*nAssets*nRuns-1], tstotalselloffvolume[[i+k +(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1), lag.max = 50)
          }
      }
      title(paste("CCF of price volatility and sell-off volume - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Objective: Study if volatility causes sell-off orders, or vice-versa.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


### Line plot of mean price volatility along experiments (averaged over runs)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   mean_tsvolatility_avg <- array(0, dim=c(1, nExp))
   indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)

   for (e in seq(from=1, to=nExp)) {
      mean_tsvolatility_avg[e] <- mean(tsvolatility_avg[(volWindow+1):nTicks,(e-1)*nAssets+k])
   }
   plot(mean_tsvolatility_avg[,], type="l", main=paste("Asset", k), xlab="Experiment", ylab="Mean volatility")
}
title(paste("Mean price volatility (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study the evolution of price volatility along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Line plot of mean price volatility along experiments (for individual runs)

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
         mean_tsvolatility <- array(0, dim=c(1, nExp))

         for (e in seq(from=1, to=nExp)) {
            mean_tsvolatility[e] <- mean(tsvolatility[,i+1+k+(e-1)*nAssets*nRuns-1])
         }
         plot(mean_tsvolatility[,], type="l", main=paste("Run", 1+i/nAssets), xlab="Exp", ylab="")
      }
   }
   else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         mean_tsvolatility <- array(0, dim=c(1, nExp))

         for (e in seq(from=1, to=nExp)) { 
            mean_tsvolatility[e] <- mean(tsvolatility[,i+k+(e-1)*nAssets*nRuns-1])
         }
         plot(mean_tsvolatility[,], type="l", main=paste("Run", 1+(i-1)/nAssets), xlab="Exp", ylab="")
      }
   }
   title(paste("Mean price volatility over experiments - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Study the evolution of price volatility along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Boxplot of time series of price volatility averaged over runs (along experiments)
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(tsvolatility_avg[,seq(i,nAssets*nExp,nAssets)], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
}
title("Range of variation of average price volatility", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of price volatility.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


#### Boxplot of price volatility along experiments (considering the individual runs)
## Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#for (i in seq(from=1, to=nAssets)) {
#   tsvolatility_exp <- array(0, dim=c(nTicks*nRuns, nExp))    # It allocates the volatility time series corresponding to the same experiment and asset
#
#   for (e in seq(from=1, to=nExp)) {      
#      for (j in seq(from=1, to=nRuns)) {
#         tsvolatility_exp[((j-1)*nTicks+1):(j*nTicks),e] <- tsvolatility[,i+(j-1)*nAssets+(e-1)*nAssets*nRuns]
#      }
#   }
#   boxplot(tsvolatility_exp[100:nTicks,], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
#}
#title("Range of variation of price volatility", outer = TRUE, col.main="blue", font.main=2)
#mtext("Test description: Overview of the distribution of price volatility.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of mean of time series of price volatility (along experiments) [Thesis Ch4]

x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "", "20", "", "", "35", "", "", "50", "", "", "65", "", "", "80")

mean_mean_tsvolatility_th <- array(0, dim=c(nAssets, nExp))

for (k in seq(from=1, to=nAssets)) {   # Calculate means to add them to the boxplots
   for (e in seq(from=0, to=nExp-1)) {
	mean_mean_tsvolatility_th[k, e+1] = mean(mean_tsvolatility_th[,k+e*nAssets])
   }
}

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(mean_tsvolatility_th[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="", xlab="Porcentaje de agentes con límite anticíclico", xaxt='n')   
   points(mean_mean_tsvolatility_th[i,],col="red",pch=18)
   lines(mean_mean_tsvolatility_th[i,], col="red", lwd=2)
   axis(1, at=1:nExp, labels=x_axis)
}



### Scatterplot of price volatility along experiments

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   volatility_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , volatility)
      
   for (e in seq(from=0, to=nExp-1)) {
      for (i in seq(from=0, to=nRuns-1)) {
	   volatility_matrix[i+1+e*nRuns,1] = e+1
	   volatility_matrix[i+1+e*nRuns,2] = mean(tsvolatility[,k+i*nAssets+e*nAssets*nRuns], na.rm = FALSE)
      }
   }
   plot(volatility_matrix[,1], volatility_matrix[,2], main=paste("Asset", k), xlab="Experiment", ylab="Volatility", pch=21)
   abline(lin_reg <- lm(volatility_matrix[,2]~volatility_matrix[,1]), col="red")   # regression line (volatility ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
}
title(paste("Impact of changing parameter on mean price volatility"), outer = TRUE, col.main="blue", font.main=2)
mtext(paste("Objective: Study if mean price volatility is affected by the changing parameter"), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



### Alternative graphical representation: 'heat map' of volatility
#
# Objective: Visually summarise if the volatility increases much in the different
# runs along experiments.
# The plot builds on the maximum value of volatility for each run, averaged over
# a window of 5 ticks to smooth 

for (a in seq(from=1, to=nAssets)) {
   vol_matrix <- array(0, dim=c(nRuns, nExp))  # Array to store the maximum volatility over each run

   for (k in seq(from=0, to=nExp-1)) {
      for (j in seq(from=0, to=nRuns-1)){
         vol_matrix[j+1,k+1] = max(SMA(tsvolatility[,a+j*nAssets+k*nAssets*nRuns], n=5), na.rm=TRUE)    # Store the maximum of volatility MA
      }
   }

   # Number of standard deviations that define the different categories
   intervals <- c(0, 3, 4, 6, 1000)

   # prepare label text (use two adjacent values for range text)
   label_text <- rollapply(round(intervals, 2), width = 2, by = 1, FUN = function(i) paste(i, collapse = "-"))

   # discretize matrix; this is the most important step, where for each value we find category of predefined ranges
   mod_mat <- matrix(findInterval(vol_matrix, intervals, all.inside = TRUE), nrow = nrow(vol_matrix))

   # output the graphics
   df_vol <- melt(mod_mat)
   colnames(df_vol) <- c("Run", "Experiment", "value")

   # Obs: 'print' must be explicitly used when the ggplot is inside a loop
   print(ggplot(df_vol, aes(x = Experiment, y = Run, fill = factor(value))) + geom_tile(color = "black") +
	scale_fill_manual(values = c("1"="palegreen4", "2"="palegreen", "3"="orange", "4"="red3"), 
	limits = c("1", "2", "3", "4"), name = paste("Extreme volatilities \n Asset", a), breaks=c(1,2,3,4), 
	labels = label_text))
}



# ----------------------------------------------------------

### Calculate volatility as the stddev of the ENTIRE time series of prices

vol_avg <- array(0, dim=c(1, nAssets*nExp))    # Averages the volatility of prices obtained on each run

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         vol_avg[,i+k*nAssets] <- vol_avg[,i+k*nAssets] + sd(tsprices[[i+1+j*nAssets+k*nAssets*nRuns]], na.rm = FALSE)
      }
      vol_avg[,i+k*nAssets] <- vol_avg[,i+k*nAssets]/nRuns
   }
}


### Line plot of mean volatility, where volatility is the stddev of the ENTIRE 
### time series of prices (averaged over runs)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)
   plot(vol_avg[,indices], type="l", main=paste("Asset", k), xlab="Experiment", ylab="Mean volatility")
}
title(paste("Mean volatility of whole time series of prices (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study the evolution of price volatility along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of mean volatility, where volatility is the stddev of the ENTIRE
### time series of prices
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

vol_matrix <- array(0, dim=c(nRuns, nAssets*nExp))   # Auxiliary array to store the price volatility for each run and asset

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with volatility of asset i for each run
         vol_matrix[j+1,i+k*nAssets] = sd(tsprices[[i+1+j*nAssets+k*nAssets*nRuns]], na.rm = FALSE)
      }
   }
}

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(vol_matrix[,seq(i,nAssets*nExp,nAssets)], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
}
title("Range of variation of price volatility", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of price volatility.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



#_____________________________________________________________________#
#                                                                     #
#              VOLATILITY OF RETURNS vs SELL-OFF VOLUME               #
#_____________________________________________________________________#
#                                                                     #

# We plot here the sell-off volume of FUNDs, TRENDs and LS's, together
# with the volatility of returns, to see the effect of VaR limits on volatility

### Calculate series of return volatility

tsvolatility <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))
tsvolatility_avg <- array(0, dim=c(nTicks, nAssets*nExp))
mean_tsvolatility_th <- array(0, dim=c(nRuns, nAssets*nExp))

for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
   for (i in seq(from=1, to=nTicks-volWindow)) {
      tsvolatility[i+volWindow,j] <- sd(diff(tslogprices[(i+1):(i+volWindow),1+j]), na.rm = FALSE)
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         tsvolatility_avg[,i+k*nAssets] <- tsvolatility_avg[,i+k*nAssets] + tsvolatility[,i+j*nAssets+k*nAssets*nRuns]
         mean_tsvolatility_th[j+1,i+k*nAssets] <- mean(tsvolatility[(volWindow+1):nTicks,i+j*nAssets+k*nAssets*nRuns])
      }
      tsvolatility_avg[,i+k*nAssets] <- tsvolatility_avg[,i+k*nAssets]/nRuns
   }
}

### Plot of time series of returns volatility + sell-off volume (averaged over runs)

y_max_V =  max(tsvolatility_avg[,1:(nAssets*nExp)])
y_min_V =  min(tsvolatility_avg[,1:(nAssets*nExp)])

y_max_SO = max(max(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))
y_min_SO = min(min(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))

x_axis <- seq(1,nTicks,1)

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))

   for (e in seq(from=1, to=nExp)) {

	# Plot time series of return volatility (averaged over runs)
	plot(x=x_axis, y=tsvolatility_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min_V,y_max_V), xlab="Tick", 
		ylab="", col="black", xaxt='n', yaxt='n')
	axis(2, pretty(c(y_min_V, y_max_V)), col="black")

	# Plot time series of sell-off volume (averaged over runs)
	par(new=T)  # Plot second time series
	plot(x=x_axis, y=tsFUNDselloffvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
	lines(tsTRENDselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")  
      lines(tsLSselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="royalblue3")
	axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

	# Add x axis
	axis(1, pretty(range(x_axis)))

	# Show average of volatility time series
	mtext(paste("avg_volat =", 100*round(mean(tsvolatility_avg[,(e-1)*nAssets+k]),4), "%"), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
   }
   title(paste("Return volatility + sell-off volume of FUND/TREND/LS (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Study the effect of VaR limits on return volatility (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Plot of time series of returns volatility + sell-off volume (for individual runs)

y_max_V = max(tsvolatility[,1:(nAssets*nRuns*nExp)])
y_min_V = min(tsvolatility[,1:(nAssets*nRuns*nExp)])

y_max_SO = max(max(tsFUNDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsLSselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
y_min_SO = min(min(tsFUNDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsLSselloffvolume[,2:(nAssets*nRuns*nExp+1)]))

x_axis <- seq(1,nTicks,1)

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {

		# Plot time series of return volatility
		plot(x=x_axis, y=tsvolatility[,i+k+1 +(e-1)*nAssets*nRuns-1], type="l", main=paste("Run", 1+i/nAssets), ylim=c(y_min_V,y_max_V), xlab="Tick", 
			ylab="", col="black", xaxt='n', yaxt='n')
		axis(2, pretty(c(y_min_V, y_max_V)), col="black")

		# Plot time series of sell-off volume
		par(new=T)  # Plot second time series
		plot(x=x_axis, y=tsFUNDselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
		lines(tsLSselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

		# Add x axis
		axis(1, pretty(range(x_axis)))

		# Show average of volatility time series
		mtext(paste("avg_volat =", 100*round(mean(tsvolatility[,i+k+1 +(e-1)*nAssets*nRuns-1]),4), "%"), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {

		# Plot time series of return volatility
		plot(x=x_axis, y=tsvolatility[,i+k +(e-1)*nAssets*nRuns-1], type="l", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min_V,y_max_V), xlab="Tick", 
			ylab="", col="black", xaxt='n', yaxt='n')
		axis(2, pretty(c(y_min_V, y_max_V)), col="black")

		# Plot time series of sell-off volume
		par(new=T)  # Plot second time series
		plot(x=x_axis, y=tsFUNDselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
		lines(tsLSselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")  
		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

		# Add x axis
		axis(1, pretty(range(x_axis)))

		# Show average of volatility time series
		mtext(paste("avg_volat =", 100*round(mean(tsvolatility[,i+k +(e-1)*nAssets*nRuns-1]),4), "%"), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
         }
      }
      title(paste("Return volatility + sell-off volume of FUND/TREND/LS - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Objective:Study the effect of VaR limits on return volatility. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


### Cross-correlation function of price volatility and sell-off volume (averaged over runs)
#
# Objective: Plot a cross-correlation function of price volatility and sell-off volume
# averaged over runs to study the correlation for different lags, in order to see
# if sell-off volume causes volatility, or vice-versa

tstotalselloffvolume_avg <- tsFUNDselloffvolume_avg + tsTRENDselloffvolume_avg + tsLSselloffvolume_avg

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))

   for (e in seq(from=1, to=nExp)) {
	ccf(tsvolatility_avg[,(e-1)*nAssets+k], tstotalselloffvolume_avg[,(e-1)*nAssets+k], ylab = "Cross-correlation", main=paste("Exp", e), ylim=c(-1,1), lag.max = 50)
   }
   title(paste("CCF of return volatility and sell-off volume - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Study if volatility causes sell-off orders, or vice-versa.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Cross-correlation function of return volatility and sell-off volume (for individual runs)
#
# Objective: Plot a cross-correlation function of return volatility and sell-off volume
# for single runs to study the correlation for different lags, in order to see
# if sell-off volume causes volatility, or vice-versa

tstotalselloffvolume <- tsFUNDselloffvolume + tsTRENDselloffvolume + tsLSselloffvolume
tstotalselloffvolume[[1]] <- tsFUNDselloffvolume[[1]]    # 'tick' column

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
       par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             ccf(tsvolatility[,i+1+k+(e-1)*nAssets*nRuns-1], tstotalselloffvolume[[i+1+k+(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1), lag.max = 50)
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            ccf(tsvolatility[,i+k +(e-1)*nAssets*nRuns-1], tstotalselloffvolume[[i+k +(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1), lag.max = 50)
          }
      }
      title(paste("CCF of return volatility and sell-off volume - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Objective: Study if volatility causes sell-off orders, or vice-versa.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


### Line plot of mean return volatility along experiments (averaged over runs)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   mean_tsvolatility_avg <- array(0, dim=c(1, nExp))
   indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)

   for (e in seq(from=1, to=nExp)) {
      mean_tsvolatility_avg[e] <- mean(tsvolatility_avg[(volWindow+1):nTicks,(e-1)*nAssets+k])
   }
   plot(mean_tsvolatility_avg[,], type="l", main=paste("Asset", k), xlab="Experiment", ylab="Mean volatility")
}
title(paste("Mean return volatility (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study the evolution of return volatility along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Line plot of mean return volatility along experiments (for individual runs)

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
         mean_tsvolatility <- array(0, dim=c(1, nExp))

         for (e in seq(from=1, to=nExp)) {
            mean_tsvolatility[e] <- mean(tsvolatility[,i+1+k+(e-1)*nAssets*nRuns-1])
         }
         plot(mean_tsvolatility[,], type="l", main=paste("Run", 1+i/nAssets), xlab="Exp", ylab="")
      }
   }
   else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         mean_tsvolatility <- array(0, dim=c(1, nExp))

         for (e in seq(from=1, to=nExp)) { 
            mean_tsvolatility[e] <- mean(tsvolatility[,i+k+(e-1)*nAssets*nRuns-1])
         }
         plot(mean_tsvolatility[,], type="l", main=paste("Run", 1+(i-1)/nAssets), xlab="Exp", ylab="")
      }
   }
   title(paste("Mean return volatility over experiments - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Study the evolution of return volatility along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}



### Boxplot of time series of return volatility averaged over runs (along experiments)

# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(tsvolatility_avg[,seq(i,nAssets*nExp,nAssets)], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
}
title("Range of variation of average return volatility", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of return volatility.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


#### Boxplot of return volatility along experiments (considering the individual runs)
## Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#for (i in seq(from=1, to=nAssets)) {
#   tsvolatility_exp <- array(0, dim=c(nTicks*nRuns, nExp))    # It allocates the volatility time series corresponding to the same experiment and asset
#
#   for (e in seq(from=1, to=nExp)) {      
#      for (j in seq(from=1, to=nRuns)) {
#         tsvolatility_exp[((j-1)*nTicks+1):(j*nTicks),e] <- tsvolatility[,i+(j-1)*nAssets+(e-1)*nAssets*nRuns]
#      }
#   }
#   boxplot(tsvolatility_exp[,], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
#}
#title("Range of variation of return volatility", outer = TRUE, col.main="blue", font.main=2)
#mtext("Test description: Overview of the distribution of return volatility.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of mean of time series of return volatility (along experiments) [Thesis Ch4]

#x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")

y_min_V = 0.0
y_max_V = 1.5

mean_mean_tsvolatility_th <- array(0, dim=c(nAssets, nExp))

for (k in seq(from=1, to=nAssets)) {   # Calculate means to add them to the boxplots
   for (e in seq(from=0, to=nExp-1)) {
	mean_mean_tsvolatility_th[k, e+1] = mean(mean_tsvolatility_th[,k+e*nAssets])
   }
}

mean_tsvolatility_th_annualised <- mean_tsvolatility_th*sqrt(252)  # annualise volatility
mean_mean_tsvolatility_th_annualised <- mean_mean_tsvolatility_th*sqrt(252)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   #boxplot(mean_tsvolatility_th_annualised[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="", xlab="Porcentaje de agentes con límite anticíclico", xaxt='n', yaxt='n')
   boxplot(mean_tsvolatility_th_annualised[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="Return volatility", xlab="VaR limit", xaxt='n', yaxt='n')
   points(mean_mean_tsvolatility_th_annualised[i,],col="red",pch=18)
   lines(mean_mean_tsvolatility_th_annualised[i,], col="red", lwd=2)
   axis(1, at=1:nExp, labels=x_axis)
   axis(2, at=seq(y_min_V,y_max_V,by=.1), labels=paste(100*seq(y_min_V,y_max_V,by=.1), "%") )  # adjust y axis to show percentages
}



### Scatterplot of return volatility along experiments

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   volatility_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , volatility)
      
   for (e in seq(from=0, to=nExp-1)) {
      for (i in seq(from=0, to=nRuns-1)) {
	   volatility_matrix[i+1+e*nRuns,1] = e+1
	   volatility_matrix[i+1+e*nRuns,2] = mean(tsvolatility[,k+i*nAssets+e*nAssets*nRuns], na.rm = FALSE)
      }
   }
   plot(volatility_matrix[,1], volatility_matrix[,2], main=paste("Asset", k), xlab="Experiment", ylab="Volatility", pch=21)
   abline(lin_reg <- lm(volatility_matrix[,2]~volatility_matrix[,1]), col="red")   # regression line (volatility ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
}
title(paste("Impact of changing parameter on return volatility"), outer = TRUE, col.main="blue", font.main=2)
mtext(paste("Objective: Study if return volatility is affected by the changing parameter"), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



# ----------------------------------------------------------

### Calculate volatility as the stddev of the ENTIRE time series of returns

vol_avg <- array(0, dim=c(1, nAssets*nExp))    # Averages the volatility of log-returns obtained on each run

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         vol_avg[,i+k*nAssets] <- vol_avg[,i+k*nAssets] + sd(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]), na.rm = FALSE)
      }
      vol_avg[,i+k*nAssets] <- vol_avg[,i+k*nAssets]/nRuns
   }
}


### Line plot of mean volatility, where volatility is the stddev of the ENTIRE 
### time series of returns (averaged over runs)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)
   plot(vol_avg[,indices], type="l", main=paste("Asset", k), xlab="Experiment", ylab="Mean volatility")
}
title(paste("Mean volatility of whole time series of returns (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study the evolution of return volatility along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of mean volatility, where volatility is the stddev of the ENTIRE
### time series of returns
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

vol_matrix <- array(0, dim=c(nRuns, nAssets*nExp))   # Auxiliary array to store the return volatility for each run and asset

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with volatility of asset i for each run
         vol_matrix[j+1,i+k*nAssets] = sd(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]), na.rm = FALSE)
      }
   }
}

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(vol_matrix[,seq(i,nAssets*nExp,nAssets)], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
}
title("Range of variation of return volatility", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of return volatility.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file




##___________________________________________________________________#
##                                                                   #
##              SKEWNESS OF RETURNS vs SELL-OFF VOLUME               #
##___________________________________________________________________#
##                                                                   #
#
## We plot here the sell-off volume of FUNDs, TRENDs and LS's, together
## with the skewness of returns. Return skewness is a measure of instability,
## as a market with a higher frequency of negative returns (--> negative skewness) 
## is likely to be less stable.
#
#### Calculate series of return skewness
#
#tsskewness <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))
#tsskewness_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tszero <- array(0, dim=c(nTicks, 1))
#
#for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
#   for (i in seq(from=1, to=nTicks-volWindow)) {
#      tsskewness[i+volWindow,j] <- skewness(diff(tslogprices[i:(i+volWindow-1),1+j]), na.rm = FALSE)
#   }
#}
#
#for (k in seq(from=0, to=nExp-1)) {
#   for (i in seq(from=1, to=nAssets)) {
#      for (j in seq(from=0, to=nRuns-1)) {
#         tsskewness_avg[,i+k*nAssets] <- tsskewness_avg[,i+k*nAssets] + tsskewness[,i+j*nAssets+k*nAssets*nRuns]
#      }
#      tsskewness_avg[,i+k*nAssets] <- tsskewness_avg[,i+k*nAssets]/nRuns
#   }
#}
#
#### Plot of time series of returns skewness + sell-off volume (averaged over runs)
#
#y_max_Sk =  max(tsskewness_avg[,1:(nAssets*nExp)])
#y_min_Sk =  min(tsskewness_avg[,1:(nAssets*nExp)])
#
#y_max_SO = max(max(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))
#y_min_SO = min(min(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))
#
#x_axis <- seq(1,nTicks,1)
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#
#   for (e in seq(from=1, to=nExp)) {
#
#	# Plot time series of return skewness (averaged over runs)
#	plot(x=x_axis, y=tsskewness_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min_Sk,y_max_Sk), xlab="Tick", 
#		ylab="", col="black", xaxt='n', yaxt='n')
#	lines(x=x_axis, y=tszero[,1], type="l", col="gray")  # Plot a horizontal line at 0 to better see if skewness is positive or negative
#	axis(2, pretty(c(y_min_Sk, y_max_Sk)), col="black")
#
#	# Plot time series of sell-off volume (averaged over runs)
#	par(new=T)  # Plot second time series
#	plot(x=x_axis, y=tsFUNDselloffvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
#		ylab="", col="darkorange1", xaxt='n', axes=F)
#	lines(tsTRENDselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")  
#      lines(tsLSselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="royalblue3")
#	axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")
#
#	# Add x axis
#	axis(1, pretty(range(x_axis)))
#
#	# Show average of skewness time series
#	mtext(paste("avg_skew =", round(mean(tsskewness_avg[,(e-1)*nAssets+k]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#   }
#   title(paste("Return skewness + sell-off volume of FUND/TREND/LS (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Description: A negative skewness indicates that negative returns occur more often. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Plot of time series of returns skewness + sell-off volume (for individual runs)
#
#y_max_Sk = max(tsskewness[,1:(nAssets*nRuns*nExp)])
#y_min_Sk = min(tsskewness[,1:(nAssets*nRuns*nExp)])
#
#y_max_SO = max(max(tsFUNDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsLSselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
#y_min_SO = min(min(tsFUNDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsLSselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
#
#x_axis <- seq(1,nTicks,1)
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#
#		# Plot time series of return skewness
#		plot(x=x_axis, y=tsskewness[,i+k+1 +(e-1)*nAssets*nRuns-1], type="l", main=paste("Run", 1+i/nAssets), ylim=c(y_min_Sk,y_max_Sk), xlab="Tick", 
#			ylab="", col="black", xaxt='n', yaxt='n')
#		lines(x=x_axis, y=tszero[,1], type="l", col="gray")  # Plot a horizontal line at 0 to better see if skewness is positive or negative
#		axis(2, pretty(c(y_min_Sk, y_max_Sk)), col="black")
#
#		# Plot time series of sell-off volume
#		par(new=T)  # Plot second time series
#		plot(x=x_axis, y=tsFUNDselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
#			ylab="", col="darkorange1", xaxt='n', axes=F)
#		lines(tsTRENDselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
#		lines(tsLSselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
#		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")
#
#		# Add x axis
#		axis(1, pretty(range(x_axis)))
#
#		# Show average of skewness time series
#		mtext(paste("avg_skew =", round(mean(tsskewness[,i+k+1 +(e-1)*nAssets*nRuns-1]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#
#		# Plot time series of return skewness
#		plot(x=x_axis, y=tsskewness[,i+k +(e-1)*nAssets*nRuns-1], type="l", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min_Sk,y_max_Sk), xlab="Tick", 
#			ylab="", col="black", xaxt='n', yaxt='n')
#		lines(x=x_axis, y=tszero[,1], type="l", col="gray")  # Plot a horizontal line at 0 to better see if skewness is positive or negative
#		axis(2, pretty(c(y_min_Sk, y_max_Sk)), col="black")
#
#		# Plot time series of sell-off volume
#		par(new=T)  # Plot second time series
#		plot(x=x_axis, y=tsFUNDselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
#			ylab="", col="darkorange1", xaxt='n', axes=F)
#		lines(tsTRENDselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
#		lines(tsLSselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")  
#		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")
#
#		# Add x axis
#		axis(1, pretty(range(x_axis)))
#
#		# Show average of skewness time series
#		mtext(paste("avg_skew =", round(mean(tsskewness[,i+k +(e-1)*nAssets*nRuns-1]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#         }
#      }
#      title(paste("Return skewness + sell-off volume of FUND/TREND/LS - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Description: A negative skewness indicates that negative returns occur more often. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}
#
#
#### Line plot of mean return skewness along experiments (averaged over runs)
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#for (k in seq(from=1, to=nAssets)) {
#   mean_tsskewness_avg <- array(0, dim=c(1, nExp))
#   indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)
#
#   for (e in seq(from=1, to=nExp)) {
#      mean_tsskewness_avg[e] <- mean(tsskewness_avg[(volWindow+1):nTicks,(e-1)*nAssets+k])
#   }
#   plot(mean_tsskewness_avg[,], type="l", main=paste("Asset", k), xlab="Experiment", ylab="Mean skewness")
#}
#title(paste("Mean return skewness (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
#mtext("Objective: Study the evolution of return skewness along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#### Line plot of mean return skewness along experiments (for individual runs)
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   if (nRuns>numRows*numCols){
#      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#         mean_tsskewness <- array(0, dim=c(1, nExp))
#
#         for (e in seq(from=1, to=nExp)) {
#            mean_tsskewness[e] <- mean(tsskewness[,i+1+k+(e-1)*nAssets*nRuns-1])
#         }
#         plot(mean_tsskewness[,], type="l", main=paste("Run", 1+i/nAssets), xlab="Exp", ylab="")
#      }
#   }
#   else {
#      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#         mean_tsskewness <- array(0, dim=c(1, nExp))
#
#         for (e in seq(from=1, to=nExp)) { 
#            mean_tsskewness[e] <- mean(tsskewness[,i+k+(e-1)*nAssets*nRuns-1])
#         }
#         plot(mean_tsskewness[,], type="l", main=paste("Run", 1+(i-1)/nAssets), xlab="Exp", ylab="")
#      }
#   }
#   title(paste("Mean return skewness over experiments - Asset", k), outer = TRUE, col.main="blue", font.main=2)
#   mtext("Objective: Study the evolution of return skewness along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Boxplot of time series of return skewness averaged over runs (along experiments)
## Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#for (i in seq(from=1, to=nAssets)) {
#   #dev.new()         # Plots each figure in a new window
#   boxplot(tsskewness_avg[,seq(i,nAssets*nExp,nAssets)], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
#}
#title("Range of variation of average return skewness", outer = TRUE, col.main="blue", font.main=2)
#mtext("Test description: Overview of the distribution of return skewness.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
##### Boxplot of return skewness along experiments (considering the individual runs)
### Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots
##
##par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
##for (i in seq(from=1, to=nAssets)) {
##   tsskewness_exp <- array(0, dim=c(nTicks*nRuns, nExp))    # It allocates the skewness time series corresponding to the same experiment and asset
##
##   for (e in seq(from=1, to=nExp)) {      
##      for (j in seq(from=1, to=nRuns)) {
##         tsskewness_exp[((j-1)*nTicks+1):(j*nTicks),e] <- tsskewness[,i+(j-1)*nAssets+(e-1)*nAssets*nRuns]
##      }
##   }
##   boxplot(tsskewness_exp[,], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
##}
##title("Range of variation of return skewness", outer = TRUE, col.main="blue", font.main=2)
##mtext("Test description: Overview of the distribution of return skewness.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
##mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#### Scatterplot of return skewness along experiments
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#for (k in seq(from=1, to=nAssets)) {
#   skewness_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , skewness)
#      
#   for (e in seq(from=0, to=nExp-1)) {
#      for (i in seq(from=0, to=nRuns-1)) {
#	   skewness_matrix[i+1+e*nRuns,1] = e+1
#	   skewness_matrix[i+1+e*nRuns,2] = mean(tsskewness[,k+i*nAssets+e*nAssets*nRuns], na.rm = FALSE)
#      }
#   }
#   plot(skewness_matrix[,1], skewness_matrix[,2], main=paste("Asset", k), xlab="Experiment", ylab="Skewness", pch=21)
#   abline(lin_reg <- lm(skewness_matrix[,2]~skewness_matrix[,1]), col="red")   # regression line (skewness ~ experiment)
#   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#}
#title(paste("Impact of changing parameter on return skewness"), outer = TRUE, col.main="blue", font.main=2)
#mtext(paste("Objective: Study if return skewness is affected by the changing parameter"), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
##### Histogram of log-return distribution
##
##for (e in seq(from=1, to=nExp)) {
##   for (k in seq(from=1, to=nAssets)) {
##      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
##      if (nRuns>numRows*numCols){   
##         for (i in seq(from=step, to=step*numRows*numCols, by=step)) { 
##            hist(scale(diff(tslogprices[[i+k+1 +(e-1)*nAssets*nRuns]]), center = TRUE, scale = TRUE), freq = FALSE, col = "grey",  main=paste("Run", 1+i/nAssets), xlab="Standardised log-returns", nclass=100)  # Compare the distribution of  standardised log-returns to N(0,1)
##      #curve(dnorm, col = 2, add = TRUE)
##         }
##      } else {
##         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
##            hist(scale(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]), center = TRUE, scale = TRUE), freq = FALSE, col = "grey",  main=paste("Run", 1+(i-1)/nAssets), xlab="Standardised log-returns", nclass=100)  # Compare the distribution of  standardised log-returns to N(0,1)
##      #curve(dnorm, col = 2, add = TRUE)  
##         }
##      }
##      title(paste("Histogram of log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
##      mtext("Test description: Bigger tails indicate that there are more extreme returns.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
##      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file 
##   }
##}
#
#
## ----------------------------------------------------------
#
#### Calculate skewness over the ENTIRE time series of returns
#
#skew_avg <- array(0, dim=c(1, nAssets*nExp))    # Averages the skewness of log-returns obtained on each run
#
#for (k in seq(from=0, to=nExp-1)) {
#   for (i in seq(from=1, to=nAssets)) {
#      for (j in seq(from=0, to=nRuns-1)) {
#         skew_avg[,i+k*nAssets] <- skew_avg[,i+k*nAssets] + skewness(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]), na.rm = FALSE)[1]
#      }
#      skew_avg[,i+k*nAssets] <- skew_avg[,i+k*nAssets]/nRuns
#   }
#}
#
#
#### Line plot of mean skewness, where skewness is calculated over the ENTIRE 
#### time series of returns (averaged over runs)
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#for (k in seq(from=1, to=nAssets)) {
#   indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)
#   plot(skew_avg[,indices], type="l", main=paste("Asset", k), xlab="Experiment", ylab="Mean skewness")
#}
#title(paste("Mean skewness of whole time series of returns (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
#mtext("Objective: Study the evolution of return skewness along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#### Boxplot of mean skewness, where skewness is calculated over the ENTIRE
#### time series of returns
## Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots
#
#skew_matrix <- array(0, dim=c(nRuns, nAssets*nExp))   # Auxiliary array to store the return skewness for each run and asset
#
#for (k in seq(from=0, to=nExp-1)) {
#   for (i in seq(from=1, to=nAssets)) {
#      for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with skewness of asset i for each run
#         skew_matrix[j+1,i+k*nAssets] = skewness(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]), na.rm = FALSE)[1]
#      }
#   }
#}
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#for (i in seq(from=1, to=nAssets)) {
#   #dev.new()         # Plots each figure in a new window
#   boxplot(skew_matrix[,seq(i,nAssets*nExp,nAssets)], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
#}
#title("Range of variation of skewness", outer = TRUE, col.main="blue", font.main=2)
#mtext("Test description: Overview of the distribution of return skewness.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#



#_________________________________________________________________________#
#                                                                         #
#             EXCESS KURTOSIS OF RETURNS vs SELL-OFF VOLUME               #
#_________________________________________________________________________#
#                                                                         #

# We plot here the sell-off volume of FUNDs, TRENDs and LS's, together
# with the kurtosis of returns. 
# Kurtosis should be higher when there are extreme returns.

### Calculate series of return kurtosis

tskurtosis <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))
tskurtosis_avg <- array(0, dim=c(nTicks, nAssets*nExp))
mean_tskurtosis_th <- array(0, dim=c(nRuns, nAssets*nExp))

for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
   for (i in seq(from=1, to=nTicks-volWindow)) {
      tskurtosis[i+volWindow,j] <- kurtosis(diff(tslogprices[i:(i+volWindow-1),1+j]), na.rm = FALSE, method="excess")[1]
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         tskurtosis_avg[,i+k*nAssets] <- tskurtosis_avg[,i+k*nAssets] + tskurtosis[,i+j*nAssets+k*nAssets*nRuns]
         mean_tskurtosis_th[j+1,i+k*nAssets] <- mean(tskurtosis[(volWindow+1):nTicks,i+j*nAssets+k*nAssets*nRuns])
      }
      tskurtosis_avg[,i+k*nAssets] <- tskurtosis_avg[,i+k*nAssets]/nRuns
   }
}


### Plot of time series of returns kurtosis + sell-off volume (averaged over runs)

y_max_kurt =  max(tskurtosis_avg[,1:(nAssets*nExp)])
y_min_kurt =  min(tskurtosis_avg[,1:(nAssets*nExp)])

y_max_SO = max(max(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), max(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))
y_min_SO = min(min(tsFUNDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDselloffvolume_avg[,1:(nAssets*nExp)]), min(tsLSselloffvolume_avg[,1:(nAssets*nExp)]))

x_axis <- seq(1,nTicks,1)

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))

   for (e in seq(from=1, to=nExp)) {

	# Plot time series of return kurtosis (averaged over runs)
	plot(x=x_axis, y=tskurtosis_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min_kurt,y_max_kurt), xlab="Tick", 
		ylab="", col="black", xaxt='n', yaxt='n')
	axis(2, pretty(c(y_min_kurt, y_max_kurt)), col="black")

	# Plot time series of sell-off volume (averaged over runs)
	par(new=T)  # Plot second time series
	plot(x=x_axis, y=tsFUNDselloffvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
	lines(tsTRENDselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")  
      lines(tsLSselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="royalblue3")
	axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

	# Add x axis
	axis(1, pretty(range(x_axis)))

	# Show average of kurtosis time series
	mtext(paste("avg_kurt =", round(mean(tskurtosis_avg[,(e-1)*nAssets+k]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
   }
   title(paste("Return kurtosis + sell-off volume of FUND/TREND/LS (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Description: A higher kurtosis indicates that extreme returns occur more often. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Plot of time series of returns kurtosis + sell-off volume (for individual runs)

y_max_kurt = max(tskurtosis[,1:(nAssets*nRuns*nExp)])
y_min_kurt = min(tskurtosis[,1:(nAssets*nRuns*nExp)])

y_max_SO = max(max(tsFUNDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsLSselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
y_min_SO = min(min(tsFUNDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsLSselloffvolume[,2:(nAssets*nRuns*nExp+1)]))

x_axis <- seq(1,nTicks,1)

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {

		# Plot time series of return kurtosis
		plot(x=x_axis, y=tskurtosis[,i+k+1 +(e-1)*nAssets*nRuns-1], type="l", main=paste("Run", 1+i/nAssets), ylim=c(y_min_kurt,y_max_kurt), xlab="Tick", 
			ylab="", col="black", xaxt='n', yaxt='n')
		axis(2, pretty(c(y_min_kurt, y_max_kurt)), col="black")

		# Plot time series of sell-off volume
		par(new=T)  # Plot second time series
		plot(x=x_axis, y=tsFUNDselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
		lines(tsLSselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

		# Add x axis
		axis(1, pretty(range(x_axis)))

		# Show average of kurtosis time series
		mtext(paste("avg_kurt =", round(mean(tskurtosis[,i+k+1 +(e-1)*nAssets*nRuns-1]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {

		# Plot time series of return kurtosis
		plot(x=x_axis, y=tskurtosis[,i+k +(e-1)*nAssets*nRuns-1], type="l", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min_Sk,y_max_Sk), xlab="Tick", 
			ylab="", col="black", xaxt='n', yaxt='n')
		axis(2, pretty(c(y_min_kurt, y_max_kurt)), col="black")

		# Plot time series of sell-off volume
		par(new=T)  # Plot second time series
		plot(x=x_axis, y=tsFUNDselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
		lines(tsLSselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")  
		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

		# Add x axis
		axis(1, pretty(range(x_axis)))

		# Show average of kurtosis time series
		mtext(paste("avg_kurt =", round(mean(tskurtosis[,i+k +(e-1)*nAssets*nRuns-1]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
         }
      }
      title(paste("Return kurtosis + sell-off volume of FUND/TREND/LS - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Description: A higher kurtosis indicates that extreme returns occur more often. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


### Line plot of mean return kurtosis along experiments (averaged over runs)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   mean_tskurtosis_avg <- array(0, dim=c(1, nExp))

   for (e in seq(from=1, to=nExp)) {
      mean_tskurtosis_avg[e] <- mean(tskurtosis_avg[(volWindow+1):nTicks,(e-1)*nAssets+k])
   }
   plot(mean_tskurtosis_avg[,], type="l", main=paste("Asset", k), xlab="Experiment", ylab="Mean kurtosis")
}
title(paste("Mean return kurtosis (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study the evolution of return kurtosis along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Line plot of mean return kurtosis along experiments (for individual runs)

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
         mean_tskurtosis <- array(0, dim=c(1, nExp))

         for (e in seq(from=1, to=nExp)) {
            mean_tskurtosis[e] <- mean(tskurtosis[,i+1+k+(e-1)*nAssets*nRuns-1])
         }
         plot(mean_tskurtosis[,], type="l", main=paste("Run", 1+i/nAssets), xlab="Exp", ylab="")
      }
   }
   else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         mean_tskurtosis <- array(0, dim=c(1, nExp))

         for (e in seq(from=1, to=nExp)) { 
            mean_tskurtosis[e] <- mean(tskurtosis[,i+k+(e-1)*nAssets*nRuns-1])
         }
         plot(mean_tskurtosis[,], type="l", main=paste("Run", 1+(i-1)/nAssets), xlab="Exp", ylab="")
      }
   }
   title(paste("Mean return kurtosis over experiments - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Study the evolution of return kurtosis along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Boxplot of time series of return kurtosis averaged over runs (along experiments)
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(tskurtosis_avg[,seq(i,nAssets*nExp,nAssets)], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
}
title("Range of variation of average return kurtosis", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of return kurtosis.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


#### Boxplot of return kurtosis along experiments (considering the individual runs)
## Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#for (i in seq(from=1, to=nAssets)) {
#   tskurtosis_exp <- array(0, dim=c(nTicks*nRuns, nExp))    # It allocates the kurtosis time series corresponding to the same experiment and asset
#
#   for (e in seq(from=1, to=nExp)) {      
#      for (j in seq(from=1, to=nRuns)) {
#         tskurtosis_exp[((j-1)*nTicks+1):(j*nTicks),e] <- tskurtosis[,i+(j-1)*nAssets+(e-1)*nAssets*nRuns]
#      }
#   }
#   boxplot(tskurtosis_exp[,], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
#}
#title("Range of variation of return kurtosis", outer = TRUE, col.main="blue", font.main=2)
#mtext("Test description: Overview of the distribution of return kurtosis.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of mean of time series of return kurtosis (along experiments) [Thesis Ch4]

#x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
mean_mean_tskurtosis_th <- array(0, dim=c(nAssets, nExp))

for (k in seq(from=1, to=nAssets)) {   # Calculate means to add them to the boxplots
   for (e in seq(from=0, to=nExp-1)) {
	mean_mean_tskurtosis_th[k, e+1] = mean(mean_tskurtosis_th[,k+e*nAssets])
   }
}

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   #boxplot(mean_tskurtosis_th[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="", xlab="Porcentaje de agentes con límite anticíclico", xaxt='n')
   boxplot(mean_tskurtosis_th[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="Return kurtosis", xlab="VaR limit", xaxt='n')
   points(mean_mean_tskurtosis_th[i,],col="red",pch=18)
   lines(mean_mean_tskurtosis_th[i,], col="red", lwd=2)
   axis(1, at=1:nExp, labels=x_axis)
}


### Scatterplot of return kurtosis along experiments

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   kurtosis_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , kurtosis)
      
   for (e in seq(from=0, to=nExp-1)) {
      for (i in seq(from=0, to=nRuns-1)) {
	   kurtosis_matrix[i+1+e*nRuns,1] = e+1
	   kurtosis_matrix[i+1+e*nRuns,2] = mean(tskurtosis[,k+i*nAssets+e*nAssets*nRuns], na.rm = FALSE)
      }
   }
   plot(kurtosis_matrix[,1], kurtosis_matrix[,2], main=paste("Asset", k), xlab="Experiment", ylab="Kurtosis", pch=21)
   abline(lin_reg <- lm(kurtosis_matrix[,2]~kurtosis_matrix[,1]), col="red")   # regression line (kurtosis ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
}
title(paste("Impact of changing parameter on return kurtosis"), outer = TRUE, col.main="blue", font.main=2)
mtext(paste("Objective: Study if return kurtosis is affected by the changing parameter"), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


#### Histogram of log-return distribution
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) { 
#            hist(scale(diff(tslogprices[[i+k+1 +(e-1)*nAssets*nRuns]]), center = TRUE, scale = TRUE), freq = FALSE, col = "grey",  main=paste("Run", 1+i/nAssets), xlab="Standardised log-returns", nclass=100)  # Compare the distribution of  standardised log-returns to N(0,1)
#      #curve(dnorm, col = 2, add = TRUE)
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            hist(scale(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]), center = TRUE, scale = TRUE), freq = FALSE, col = "grey",  main=paste("Run", 1+(i-1)/nAssets), xlab="Standardised log-returns", nclass=100)  # Compare the distribution of  standardised log-returns to N(0,1)
#      #curve(dnorm, col = 2, add = TRUE)  
#         }
#      }
#      title(paste("Histogram of log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Test description: Bigger tails indicate that there are more extreme returns.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file 
#   }
#}


# ----------------------------------------------------------

### Calculate kurtosis over the ENTIRE time series of returns

kurt_avg <- array(0, dim=c(1, nAssets*nExp))    # Averages the kurtosis of log-returns obtained on each run

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         kurt_avg[,i+k*nAssets] <- kurt_avg[,i+k*nAssets] + kurtosis(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]), na.rm = FALSE, method="excess")[1]
      }
      kurt_avg[,i+k*nAssets] <- kurt_avg[,i+k*nAssets]/nRuns
   }
}


### Line plot of mean kurtosis, where kurtosis is calculated over the ENTIRE 
### time series of returns (averaged over runs)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)
   plot(kurt_avg[,indices], type="l", main=paste("Asset", k), xlab="Experiment", ylab="Mean kurtosis")
}
title(paste("Mean kurtosis of whole time series of returns (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study the evolution of return kurtosis along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



### Boxplot of mean kurtosis, where kurtosis is calculated over the ENTIRE
### time series of returns
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

kurt_matrix <- array(0, dim=c(nRuns, nAssets*nExp))   # Auxiliary array to store the return kurtosis for each run and asset

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with kurtosis of asset i for each run
         kurt_matrix[j+1,i+k*nAssets] = kurtosis(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]), na.rm = FALSE, method="excess")[1]
      }
   }
}

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(kurt_matrix[,seq(i,nAssets*nExp,nAssets)], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
}
title("Range of variation of kurtosis", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of return kurtosis.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file




#___________________________________________________________________#
#                                                                   #
#                           HILL TAIL INDEX                         #
#___________________________________________________________________#
#                                                                   #

### Tail behaviour of return distribution: Hill estimator
#
# The Hill plot is used to estimate the tail index
# of a Pareto type distribution. If the return distribution follows
# a power law in the tails, then the Hill plot should tend to the exponent
#
# The Hill index of returns is an indicator of the occurrence of extreme events.
# From Hermsen 2010: "The lower the Hill index, the lower the stability
# of the financial market, since more extraordinary losses occur."

## WARNING: I am not familiar with the Hill index, and I am not sure that 
## what I am doing below (selecting the index for a given sample size) is 
## completely sensible.

sample_size = 0.1 * nTicks   ## I use the 10% of the number of ticks
                             ## In [Hill]’s first implementation, Du Mouchel (1979) showed 
                             ## a heuristic 10% of the sample size to perform reasonably in large 
                             ## samples (from http://people.brandeis.edu/~blebaron/wps/tails.pdf)


# NOTE: The calculation of the Hill tail index has been moved at the beginning
# of the script to avoid that auxiliary plots appear in the pdf


### Hill plots of returns (averaged over runs)

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,5,1), oma=c(3,3,5,3))

   for (e in seq(from=1, to=nExp)) {
       hill(diff(tslogprices_avg[,(e-1)*nAssets+k]), option = "alpha", end = sample_size, p = NA, main=paste("Exp", e))
   }
   title(paste("Hill index of returns (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Description: a lower Hill index indicates that extreme events occur more often.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Hill plot of returns (for individual runs)

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
       par(mfrow=c(numRows,numCols), mar=c(3,4,5,1), oma=c(3,3,5,3))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             hill(diff(tslogprices[[i+k+1+(e-1)*nAssets*nRuns]]), option = "alpha", end = sample_size, p = NA, main=paste("Run", 1+i/nAssets))
          }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            hill(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]), option = "alpha", end = sample_size, p = NA,  main=paste("Run", 1+(i-1)/nAssets))
         }
      }
      title(paste("Hill tail index of return distribution - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Description: a lower Hill index indicates that extreme events occur more often.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


### Line plot of mean Hill index along experiments

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)
   plot(hillreturns_avg[1,indices], type="l", main=paste("Asset", k), xlab="Experiment", ylab="Mean Hill index")
}
title(paste("Mean Hill index for average returns"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study the evolution of return Hill index along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Line plot of Hill index along experiments (for individual runs)

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
         hillreturns_exp <- array(0, dim=c(1, nExp))

         for (e in seq(from=1, to=nExp)) {
            hillreturns_exp[e] <- hillreturns[1,i+1+k+(e-1)*nAssets*nRuns-1]
         }
         plot(hillreturns_exp[,], type="l", main=paste("Run", 1+i/nAssets), xlab="Exp", ylab="")
      }
   }
   else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         hillreturns_exp <- array(0, dim=c(1, nExp))

         for (e in seq(from=1, to=nExp)) { 
            hillreturns_exp[e] <- hillreturns[1,i+k+(e-1)*nAssets*nRuns-1]
         }
         plot(hillreturns_exp[,], type="l", main=paste("Run", 1+(i-1)/nAssets), xlab="Exp", ylab="")
      }
   }
   title(paste("Hill index over experiments - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Study the evolution of return Hill index along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Boxplot of Hill index along experiments (considering the individual runs)
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (i in seq(from=1, to=nAssets)) {
   hillreturns_exp <- array(0, dim=c(nRuns, nExp))    # It allocates the Hill indexes corresponding to the same experiment and asset

   for (e in seq(from=1, to=nExp)) {      
      for (j in seq(from=1, to=nRuns)) {
         hillreturns_exp[j,e] <- hillreturns[,i+(j-1)*nAssets+(e-1)*nAssets*nRuns]
      }
   }
   boxplot(hillreturns_exp[,], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
}
title("Range of variation of return Hill index", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of return Hill index.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of Hill index along experiments (considering the individual runs)  [Thesis Ch4]

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))
#x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")

for (i in seq(from=1, to=nAssets)) {
   hillreturns_exp <- array(0, dim=c(nRuns, nExp))    # It allocates the Hill indexes corresponding to the same experiment and asset
   mean_hillreturns_exp <- array(0, dim=c(1, nExp))   # Mean Hill index over runs

   for (e in seq(from=1, to=nExp)) {      
      for (j in seq(from=1, to=nRuns)) {
         hillreturns_exp[j,e] <- hillreturns[,i+(j-1)*nAssets+(e-1)*nAssets*nRuns]
      }
      mean_hillreturns_exp[,e] <- mean(hillreturns_exp[,e])
   }
   #boxplot(hillreturns_exp[,], notch=FALSE, main="", range=1.5, xlab="Porcentaje de agentes con límite anticíclico", xaxt='n')
   boxplot(hillreturns_exp[,], notch=FALSE, main="Hill index", range=1.5, xlab="VaR limit", xaxt='n')
   points(mean_hillreturns_exp[,],col="red",pch=18)
   lines(mean_hillreturns_exp[,], col="red", lwd=2)
   axis(1, at=1:nExp, labels=x_axis)
}


### Scatterplot of return Hill index along experiments

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   hillreturns_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , Hill index)
      
   for (e in seq(from=0, to=nExp-1)) {
      for (i in seq(from=0, to=nRuns-1)) {
	   hillreturns_matrix[i+1+e*nRuns,1] = e+1
	   hillreturns_matrix[i+1+e*nRuns,2] = hillreturns[1,k+i*nAssets+e*nAssets*nRuns]
      }
   }
   plot(hillreturns_matrix[,1], hillreturns_matrix[,2], main=paste("Asset", k), xlab="Experiment", ylab="Hill index", pch=21)
   abline(lin_reg <- lm(hillreturns_matrix[,2]~hillreturns_matrix[,1]), col="red")   # regression line (Hill index ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
}
title(paste("Impact of changing parameter on return Hill index"), outer = TRUE, col.main="blue", font.main=2)
mtext(paste("Objective: Study if return Hill index is affected by the changing parameter"), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



#_________________________________________________________________#
#                                                                 #
#                        FUND/TREND/LS VaR                        #
#_________________________________________________________________#
#                                                                 # 

### Plot of FUND, TREND and LS VaR (averaged over runs)

y_max = max(max(tsFUNDvar_avg[,1:nExp]), max(tsTRENDvar_avg[,1:nExp]), max(tsLSvar_avg[,1:nExp]))
y_min = min(min(tsFUNDvar_avg[,1:nExp]), min(tsTRENDvar_avg[,1:nExp]), min(tsLSvar_avg[,1:nExp]))

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(tsTRENDvar_avg[,e], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="VaR", col="seagreen")
   lines(tsFUNDvar_avg[,e], type="l", col="darkorange1")
   lines(tsLSvar_avg[,e], type="l", col="blue")
}
title(paste("VaR of FUNDs vs TRENDs vs LS's (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Compare the VaR level of the three groups of agents (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



### Plot of FUND, TREND and LS VaR + stressed VaR (averaged over runs)

y_max = max(max(tsFUNDvar_avg[,1:nExp]+tsFUNDstressedvar_avg[,1:nExp]), max(tsTRENDvar_avg[,1:nExp]+tsTRENDstressedvar_avg[,1:nExp]), max(tsLSvar_avg[,1:nExp]+tsLSstressedvar_avg[,1:nExp]))
y_min = min(min(tsFUNDvar_avg[,1:nExp]+tsFUNDstressedvar_avg[,1:nExp]), min(tsTRENDvar_avg[,1:nExp]+tsTRENDstressedvar_avg[,1:nExp]), min(tsLSvar_avg[,1:nExp]+tsLSstressedvar_avg[,1:nExp]))

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(tsTRENDvar_avg[,e]+tsTRENDstressedvar_avg[,e], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="VaR+SVaR", col="seagreen")
   lines(tsFUNDvar_avg[,e]+tsFUNDstressedvar_avg[,e], type="l", col="darkorange1")
   lines(tsLSvar_avg[,e]+tsLSstressedvar_avg[,e], type="l", col="blue")
}
title(paste("VaR + Stressed VaR of FUNDs vs TRENDs vs LS's (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Compare the VaR+SVaR level of the three groups of agents (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


#### Stacked plot of VaR and stressed VaR (averaged over runs)
#
#y_max = max(max(tsFUNDvar_avg[,1:nExp]+tsFUNDstressedvar_avg[,1:nExp]), max(tsTRENDvar_avg[,1:nExp]+tsTRENDstressedvar_avg[,1:nExp]), max(tsLSvar_avg[,1:nExp]+tsLSstressedvar_avg[,1:nExp]))
#y_min = min(min(tsFUNDvar_avg[,1:nExp]+tsFUNDstressedvar_avg[,1:nExp]), min(tsTRENDvar_avg[,1:nExp]+tsTRENDstressedvar_avg[,1:nExp]), min(tsLSvar_avg[,1:nExp]+tsLSstressedvar_avg[,1:nExp]))
#
##FUND
#
## Plot graphics in a grid ('par' cannot be used with ggplot)
#grid.newpage()
#pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#for (e in seq(from=1, to=nExp)) {
#
#   # Create dataframe of contribution to plot stacked area graphic
#   df = data.frame(seq(1:nTicks), tsFUNDstressedvar_avg[,e], tsFUNDvar_avg[,e])
#   colnames(df) <- c("tick", "SVar", "Var")
#
#   df <- reshape(df, varying = c("SVar", "Var"), v.names = "value", timevar = "group", 
# 		     times = c("SVar", "Var"), direction = "long")
#
#   df$group <- factor(df$group, levels = c("Var", "SVar"))   # Change the order of stacks (VaR below, SVar on top)
#            
#   # Plot VaR & SVar in stacked area plot
#   graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("darkorange1", "coral4"), name = paste("E", e), 
#            	breaks = c("SVar", "Var"), labels = c("SVar", "Var")) + ylim(y_min, y_max)
#
#   # Display graphics in a grid  #!! It does not work properly if numExp > numCols*numRows
#   col = e %% numCols   
#   col = col + numCols * (col==0)   # Columns cannot take value 0
#   row = floor((e-1)/numCols) + 1
#   print(graph,vp=vplayout(row,col))
#}
#
## TREND
#
## Plot graphics in a grid ('par' cannot be used with ggplot)
#grid.newpage()
#pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#for (e in seq(from=1, to=nExp)) {
#
#   # Create dataframe of contribution to plot stacked area graphic
#   df = data.frame(seq(1:nTicks), tsTRENDstressedvar_avg[,e], tsTRENDvar_avg[,e])
#   colnames(df) <- c("tick", "SVar", "Var")
#
#   df <- reshape(df, varying = c("SVar", "Var"), v.names = "value", timevar = "group", 
# 		     times = c("SVar", "Var"), direction = "long")
#
#   df$group <- factor(df$group, levels = c("Var", "SVar"))   # Change the order of stacks (VaR below, SVar on top)
#            
#   # Plot VaR & SVar in stacked area plot
#   graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("seagreen", "seagreen2"), name = paste("E", e), 
#            	breaks = c("SVar", "Var"), labels = c("SVar", "Var")) + ylim(y_min, y_max)
#
#   # Display graphics in a grid   #!! It does not work properly if numExp > numCols*numRows
#   col = e %% numCols   
#   col = col + numCols * (col==0)   # Columns cannot take value 0
#   row = floor((e-1)/numCols) + 1
#   print(graph,vp=vplayout(row,col))
#}
#
## LS
#
## Plot graphics in a grid ('par' cannot be used with ggplot)
#grid.newpage()
#pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#for (e in seq(from=1, to=nExp)) {
#
#   # Create dataframe of contribution to plot stacked area graphic
#   df = data.frame(seq(1:nTicks), tsLSstressedvar_avg[,e], tsLSvar_avg[,e])
#   colnames(df) <- c("tick", "SVar", "Var")
#
#   df <- reshape(df, varying = c("SVar", "Var"), v.names = "value", timevar = "group", 
# 		     times = c("SVar", "Var"), direction = "long")
#
#   df$group <- factor(df$group, levels = c("Var", "SVar"))   # Change the order of stacks (VaR below, SVar on top)
#            
#   # Plot VaR & SVar in stacked area plot
#   graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("royalblue3", "skyblue2"), name = paste("E", e), 
#            	breaks = c("SVar", "Var"), labels = c("SVar", "Var")) + ylim(y_min, y_max)
#
#   # Display graphics in a grid   #!! It does not work properly if numExp > numCols*numRows
#   col = e %% numCols   
#   col = col + numCols * (col==0)   # Columns cannot take value 0
#   row = floor((e-1)/numCols) + 1
#   print(graph,vp=vplayout(row,col))
#}
#


### Plot of FUND, TREND and LS VaR (for individual runs)

y_max = max(max(tsFUNDvar[,2:(nRuns*nExp+1)]), max(tsTRENDvar[,2:(nRuns*nExp+1)]), max(tsLSvar[,2:(nRuns*nExp+1)]))
y_min = min(min(tsFUNDvar[,2:(nRuns*nExp+1)]), min(tsTRENDvar[,2:(nRuns*nExp+1)]), min(tsLSvar[,2:(nRuns*nExp+1)]))

step2 <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {     
         plot(tsFUNDvar[[i+2 +(e-1)*nRuns]], type="l", ylab="VaR", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDvar[[i+2 +(e-1)*nRuns]], type="l", col="seagreen")
         lines(tsLSvar[[i+2 +(e-1)*nRuns]], type="l", col="royalblue3")
      }
   } else {
      for (i in seq(from=1, to=nRuns, by=1)) {
         plot(tsFUNDvar[[i+2 +(e-1)*nRuns]], type="l", ylab="VaR", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDvar[[i+2 +(e-1)*nRuns]], type="l", col="seagreen")  
         lines(tsLSvar[[i+2 +(e-1)*nRuns]], type="l", col="royalblue3")
      }
   }
   title(paste("VaR of FUNDs vs TRENDs vs LS's ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Compare the VaR level of the three groups of agents. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}

### Plot of FUND, TREND and LS VaR + stressed VaR (for individual runs)

y_max = max(max(tsFUNDvar[,2:(nRuns*nExp+1)]+tsFUNDstressedvar[,2:(nRuns*nExp+1)]), max(tsTRENDvar[,2:(nRuns*nExp+1)]+tsTRENDstressedvar[,2:(nRuns*nExp+1)]), max(tsLSvar[,2:(nRuns*nExp+1)]+tsLSstressedvar[,2:(nRuns*nExp+1)]))
y_min = min(min(tsFUNDvar[,2:(nRuns*nExp+1)]+tsFUNDstressedvar[,2:(nRuns*nExp+1)]), min(tsTRENDvar[,2:(nRuns*nExp+1)]+tsTRENDstressedvar[,2:(nRuns*nExp+1)]), min(tsLSvar[,2:(nRuns*nExp+1)]+tsLSstressedvar[,2:(nRuns*nExp+1)]))

step2 <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {     
         plot(tsFUNDvar[[i+2 +(e-1)*nRuns]]+tsFUNDstressedvar[[i+1 +(e-1)*nRuns]], type="l", ylab="VaR+SVaR", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDvar[[i+2 +(e-1)*nRuns]]+tsTRENDstressedvar[[i+1 +(e-1)*nRuns]], type="l", col="seagreen")
         lines(tsLSvar[[i+2 +(e-1)*nRuns]]+tsLSstressedvar[[i+1 +(e-1)*nRuns]], type="l", col="royalblue3")
      }
   } else {
      for (i in seq(from=1, to=nRuns, by=1)) {
         plot(tsFUNDvar[[i+2 +(e-1)*nRuns]]+tsFUNDstressedvar[[i+1 +(e-1)*nRuns]], type="l", ylab="VaR+SVaR", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDvar[[i+2 +(e-1)*nRuns]]+tsTRENDstressedvar[[i+1 +(e-1)*nRuns]], type="l", col="seagreen")  
         lines(tsLSvar[[i+2 +(e-1)*nRuns]]+tsLSstressedvar[[i+1 +(e-1)*nRuns]], type="l", col="royalblue3")
      }
   }
   title(paste("VaR + Stressed VaR of FUNDs vs TRENDs vs LS's ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Compare the VaR+SVaR level of the three groups of agents. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


#### Stacked plot of VaR and stressed VaR (for individual runs)
#
#y_max = max(max(tsFUNDvar[,2:(nRuns*nExp+1)]+tsFUNDstressedvar[,2:(nRuns*nExp+1)]), max(tsTRENDvar[,2:(nRuns*nExp+1)]+tsTRENDstressedvar[,2:(nRuns*nExp+1)]), max(tsLSvar[,2:(nRuns*nExp+1)]+tsLSstressedvar[,2:(nRuns*nExp+1)]))
#y_min = min(min(tsFUNDvar[,2:(nRuns*nExp+1)]+tsFUNDstressedvar[,2:(nRuns*nExp+1)]), min(tsTRENDvar[,2:(nRuns*nExp+1)]+tsTRENDstressedvar[,2:(nRuns*nExp+1)]), min(tsLSvar[,2:(nRuns*nExp+1)]+tsLSstressedvar[,2:(nRuns*nExp+1)]))
#
#step2 <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many
#
## FUND
#
#for (e in seq(from=1, to=nExp)) {
#
#   # Plot graphics in a grid ('par' cannot be used with ggplot)
#   grid.newpage()
#   pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#   vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#   if (nRuns>numRows*numCols){   
#      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {
#
#         # Create dataframe of contribution to plot stacked area graphic
#    	    df = data.frame(seq(1:nTicks), tsFUNDstressedvar[,i+2+(e-1)*nRuns], tsFUNDvar[,i+2+(e-1)*nRuns])
#         colnames(df) <- c("tick", "SVar", "Var")
#
#	    df <- reshape(df, varying = c("SVar", "Var"), v.names = "value", timevar = "group", 
# 		     times = c("SVar", "Var"), direction = "long")
#
#         df$group <- factor(df$group, levels = c("Var", "SVar"))   # Change the order of stacks (VaR below, SVar on top)
#            
#         # Plot VaR & SVar in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("darkorange1", "coral4"), name = paste("R", 1+i, ", E", e), 
#           	breaks = c("SVar", "Var"), labels = c("SVar", "Var")) + ylim(y_min, y_max)
#
#	   # Display graphics in a grid
#	   col = (i/step2) %% numCols  
#        col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor((i/step2-1)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   } else {
#      for (i in seq(from=1, to=nRuns, by=1)) {
#
#         # Create dataframe of contribution to plot stacked area graphic
#         df = data.frame(seq(1:nTicks), tsFUNDstressedvar[,i+1+(e-1)*nRuns], tsFUNDvar[,i+1+(e-1)*nRuns])
#         colnames(df) <- c("tick", "SVar", "Var")
#
#	    df <- reshape(df, varying = c("SVar", "Var"), v.names = "value", timevar = "group", 
# 		     times = c("SVar", "Var"), direction = "long")
#
#         df$group <- factor(df$group, levels = c("Var", "SVar"))   # Change the order of stacks (VaR below, SVar on top)
#
#         # Plot Var & SVar in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("darkorange1", "coral4"), name = paste("R", i, " E", e), 
#            	breaks = c("SVar", "Var"), labels = c("SVar", "Var")) + ylim(y_min, y_max)
#
#	   # Display graphics in a grid
#	   col = i %% numCols   
#         col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor((i-1)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   }
#}
#
#
## TREND
#
#for (e in seq(from=1, to=nExp)) {
#
#   # Plot graphics in a grid ('par' cannot be used with ggplot)
#   grid.newpage()
#   pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#   vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#   if (nRuns>numRows*numCols){   
#      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {
#
#         # Create dataframe of contribution to plot stacked area graphic
#         df = data.frame(seq(1:nTicks), tsTRENDstressedvar[,i+2+(e-1)*nRuns], tsTRENDvar[,i+2+(e-1)*nRuns])
#         colnames(df) <- c("tick", "SVar", "Var")
#
#	    df <- reshape(df, varying = c("SVar", "Var"), v.names = "value", timevar = "group", 
# 		     times = c("SVar", "Var"), direction = "long")
#
#         df$group <- factor(df$group, levels = c("Var", "SVar"))   # Change the order of stacks (VaR below, SVar on top)
#            
#         # Plot VaR & SVar in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("seagreen", "seagreen2"), name = paste("R", 1+i, ", E", e), 
#            	breaks = c("SVar", "Var"), labels = c("SVar", "Var")) + ylim(y_min, y_max)
#
#	   # Display graphics in a grid
#	   col = (i/step2) %% numCols  
#         col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor((i/step2-1)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   } else {
#      for (i in seq(from=1, to=nRuns, by=1)) {
#
#         # Create dataframe of contribution to plot stacked area graphic
#         df = data.frame(seq(1:nTicks), tsTRENDstressedvar[,i+1+(e-1)*nRuns], tsTRENDvar[,i+1+(e-1)*nRuns])
#         colnames(df) <- c("tick", "SVar", "Var")
#
# 	    df <- reshape(df, varying = c("SVar", "Var"), v.names = "value", timevar = "group", 
# 		     times = c("SVar", "Var"), direction = "long")
#
#         df$group <- factor(df$group, levels = c("Var", "SVar"))   # Change the order of stacks (VaR below, SVar on top)
#
#         # Plot Var & SVar in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("seagreen", "seagreen2"), name = paste("R", i, " E", e), 
#            	breaks = c("SVar", "Var"), labels = c("SVar", "Var")) + ylim(y_min, y_max)
#
#	   # Display graphics in a grid
#	   col = i %% numCols   
#         col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor((i-1)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   }
#}
#
#
## LS
#
#for (e in seq(from=1, to=nExp)) {
#
#   # Plot graphics in a grid ('par' cannot be used with ggplot)
#   grid.newpage()
#   pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#   vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#   if (nRuns>numRows*numCols){   
#      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {
#
#         # Create dataframe of contribution to plot stacked area graphic
#         df = data.frame(seq(1:nTicks), tsLSstressedvar[,i+2+(e-1)*nRuns], tsLSvar[,i+2+(e-1)*nRuns])
#         colnames(df) <- c("tick", "SVar", "Var")
#
#	    df <- reshape(df, varying = c("SVar", "Var"), v.names = "value", timevar = "group", 
# 		     times = c("SVar", "Var"), direction = "long")
#
#         df$group <- factor(df$group, levels = c("Var", "SVar"))   # Change the order of stacks (VaR below, SVar on top)
#           
#         # Plot VaR & SVar in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("royalblue3", "skyblue2"), name = paste("R", 1+i, ", E", e), 
#            	breaks = c("SVar", "Var"), labels = c("SVar", "Var")) + ylim(y_min, y_max)
#
#	   # Display graphics in a grid
#	   col = (i/step2) %% numCols  
#         col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor((i/step2-1)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   } else {
#      for (i in seq(from=1, to=nRuns, by=1)) {
#
#         # Create dataframe of contribution to plot stacked area graphic
#         df = data.frame(seq(1:nTicks), tsLSstressedvar[,i+1+(e-1)*nRuns], tsLSvar[,i+1+(e-1)*nRuns])
#         colnames(df) <- c("tick", "SVar", "Var")
#
#	    df <- reshape(df, varying = c("SVar", "Var"), v.names = "value", timevar = "group", 
# 		     times = c("SVar", "Var"), direction = "long")
#
#         df$group <- factor(df$group, levels = c("Var", "SVar"))   # Change the order of stacks (VaR below, SVar on top)
#
#         # Plot Var & SVar in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("royalblue3", "skyblue2"), name = paste("R", i, " E", e), 
#            	breaks = c("SVar", "Var"), labels = c("SVar", "Var")) + ylim(y_min, y_max)
#
#	   # Display graphics in a grid
#	   col = i %% numCols   
#         col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor((i-1)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   }
#}
#


### Line plot of mean VaR along experiments (averaged over runs)

par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

mean_tsFUNDvar_avg <- array(0, dim=c(1, nExp))
mean_tsTRENDvar_avg <- array(0, dim=c(1, nExp))
mean_tsLSvar_avg <- array(0, dim=c(1, nExp))

for (e in seq(from=1, to=nExp)) {
   mean_tsFUNDvar_avg[e] <- mean(tsFUNDvar_avg[,e])
   mean_tsTRENDvar_avg[e] <- mean(tsTRENDvar_avg[,e])
   mean_tsLSvar_avg[e] <- mean(tsLSvar_avg[,e])
}

y_max = max(max(mean_tsFUNDvar_avg), max(mean_tsTRENDvar_avg), max(mean_tsLSvar_avg))
y_min = min(min(mean_tsFUNDvar_avg), min(mean_tsTRENDvar_avg), min(mean_tsLSvar_avg))

plot(mean_tsFUNDvar_avg[,], type="l", main="FUND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean VaR", col="darkorange1")
plot(mean_tsTRENDvar_avg[,], type="l", main="TREND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean VaR", col="seagreen")
plot(mean_tsLSvar_avg[,], type="l", main="LS", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean VaR", col="royalblue3")

title(paste("Mean VaR (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study the evolution of VaR level along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Line plot of mean VaR + stressed VaR along experiments (averaged over runs)

par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

mean_tsFUNDtotalvar_avg <- array(0, dim=c(1, nExp))
mean_tsTRENDtotalvar_avg <- array(0, dim=c(1, nExp))
mean_tsLStotalvar_avg <- array(0, dim=c(1, nExp))

for (e in seq(from=1, to=nExp)) {
   mean_tsFUNDtotalvar_avg[e] <- mean(tsFUNDvar_avg[,e] + tsFUNDstressedvar_avg[,e])
   mean_tsTRENDtotalvar_avg[e] <- mean(tsTRENDvar_avg[,e] + tsTRENDstressedvar_avg[,e])
   mean_tsLStotalvar_avg[e] <- mean(tsLSvar_avg[,e] + tsLSstressedvar_avg[,e])
}

y_max = max(max(mean_tsFUNDtotalvar_avg), max(mean_tsTRENDtotalvar_avg), max(mean_tsLStotalvar_avg))
y_min = min(min(mean_tsFUNDtotalvar_avg), min(mean_tsTRENDtotalvar_avg), min(mean_tsLStotalvar_avg))

plot(mean_tsFUNDtotalvar_avg[,], type="l", main="FUND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean VaR+SVaR", col="darkorange1")
plot(mean_tsTRENDtotalvar_avg[,], type="l", main="TREND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean VaR+SVaR", col="seagreen")
plot(mean_tsLStotalvar_avg[,], type="l", main="LS", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean VaR+SVaR", col="royalblue3")

title(paste("Mean VaR + Stressed VaR (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study the evolution of VaR+SVaR level along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of time series of VaR averaged over runs (along experiments)
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

boxplot(tsFUNDvar_avg[,], notch=TRUE, col="darkorange1", main="FUND", xlab="")
boxplot(tsTRENDvar_avg[,], notch=TRUE, col="seagreen", main="TREND", xlab="")
boxplot(tsLSvar_avg[,], notch=TRUE, col="royalblue3", main="LS", xlab="")

title("Range of variation of mean VaR", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of agents' mean VaR.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of average VaR + stressed VaR along experiments
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

boxplot(tsFUNDvar_avg[,] + tsFUNDstressedvar_avg[,], notch=TRUE, col="darkorange1", main="FUND", xlab="")
boxplot(tsTRENDvar_avg[,] + tsTRENDstressedvar_avg[,], notch=TRUE, col="seagreen", main="TREND", xlab="")
boxplot(tsLSvar_avg[,] + tsLSstressedvar_avg[,], notch=TRUE, col="royalblue3", main="LS", xlab="")

title("Range of variation of mean VaR + SVaR", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of agents' mean VaR+SVaR.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter 


#### Boxplot of VaR along experiments (considering the individual runs)
## Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots
#
#par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#tsFUNDvar_exp <- array(0, dim=c(nTicks*nRuns, nExp))    # These allocate the agents' var time series corresponding to the same experiment
#tsTRENDvar_exp <- array(0, dim=c(nTicks*nRuns, nExp))
#tsLSvar_exp <- array(0, dim=c(nTicks*nRuns, nExp))
#
#for (e in seq(from=1, to=nExp)) {      
#   for (j in seq(from=1, to=nRuns)) {
#      tsFUNDvar_exp[((j-1)*nTicks+1):(j*nTicks),e] <- tsFUNDvar[,1+j+(e-1)*nRuns]
#      tsTRENDvar_exp[((j-1)*nTicks+1):(j*nTicks),e] <- tsTRENDvar[,1+j+(e-1)*nRuns]
#      tsLSvar_exp[((j-1)*nTicks+1):(j*nTicks),e] <- tsLSvar[,1+j+(e-1)*nRuns]
#   }
#}
#boxplot(tsFUNDvar_exp[,], notch=TRUE, col="darkorange1", main="FUND", xlab="")
#boxplot(tsTRENDvar_exp[,], notch=TRUE, col="seagreen", main="TREND", xlab="")
#boxplot(tsLSvar_exp[,], notch=TRUE, col="royalblue3", main="LS", xlab="")
#
#title("Range of variation of VaR", outer = TRUE, col.main="blue", font.main=2)
#mtext("Test description: Overview of the distribution of agents' VaR.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



### Boxplot of mean of VaR time series (along experiments) [Thesis Ch4]

x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "", "20", "", "", "35", "", "", "50", "", "", "65", "", "", "80")

mean_tsFUNDvar <- array(0, dim=c(nRuns, nExp))
mean_tsTRENDvar <- array(0, dim=c(nRuns, nExp))
mean_tsLSvar <- array(0, dim=c(nRuns, nExp))

mean_mean_tsFUNDvar <- array(0, dim=c(1, nExp))
mean_mean_tsTRENDvar <- array(0, dim=c(1, nExp))
mean_mean_tsLSvar <- array(0, dim=c(1, nExp))

for (e in seq(from=1, to=nExp)) {
   for (j in seq(from=1, to=nRuns)) {
	mean_tsFUNDvar[j,e] = mean(tsFUNDvar[,1+j+(e-1)*nRuns])
	mean_tsTRENDvar[j,e] = mean(tsTRENDvar[,1+j+(e-1)*nRuns])
      mean_tsLSvar[j,e] = mean(tsLSvar[,1+j+(e-1)*nRuns])
   }
   mean_mean_tsFUNDvar[,e] = mean(mean_tsFUNDvar[,e])
   mean_mean_tsTRENDvar[,e] = mean(mean_tsTRENDvar[,e])
   mean_mean_tsLSvar[,e] = mean(mean_tsLSvar[,e])
}

par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
boxplot(mean_tsFUNDvar[,seq(1,nExp)], notch=FALSE, range=1.5, main="Fundamentalistas", cex.main=1.5, col="darkorange1", xlab="Porcentaje de agentes con límite anticíclico", xaxt='n')
points(mean_mean_tsFUNDvar[,],col="red",pch=18)
lines(mean_mean_tsFUNDvar[,], col="red", lwd=2)
axis(1, at=1:nExp, labels=x_axis)

boxplot(mean_tsTRENDvar[,seq(1,nExp)], notch=FALSE, range=1.5, main="Técnicos", cex.main=1.5, col="seagreen", xlab="Porcentaje de agentes con límite anticíclico", xaxt='n')
points(mean_mean_tsTRENDvar[,],col="red",pch=18)
lines(mean_mean_tsTRENDvar[,], col="red", lwd=2)
axis(1, at=1:nExp, labels=x_axis)

boxplot(mean_tsLSvar[,seq(1,nExp)], notch=FALSE, range=1.5, main="Long-short", cex.main=1.5, col="royalblue3", xlab="Porcentaje de agentes con límite anticíclico", xaxt='n')
points(mean_mean_tsLSvar[,],col="red",pch=18)
lines(mean_mean_tsLSvar[,], col="red", lwd=2)
axis(1, at=1:nExp, labels=x_axis)



### Scatterplot of VaR along experiments

par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

FUNDvar_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , Var)
TRENDvar_matrix <- array(0, dim=c(nRuns*nExp, 2))
LSvar_matrix <- array(0, dim=c(nRuns*nExp, 2))
      
for (e in seq(from=1, to=nExp)) {      
   for (j in seq(from=1, to=nRuns)) {
      FUNDvar_matrix[j+(e-1)*nRuns,1] = e
	TRENDvar_matrix[j+(e-1)*nRuns,1] = e
	LSvar_matrix[j+(e-1)*nRuns,1] = e
	   
	FUNDvar_matrix[j+(e-1)*nRuns,2] = mean(tsFUNDvar[,1+j+(e-1)*nRuns])
	TRENDvar_matrix[j+(e-1)*nRuns,2] = mean(tsTRENDvar[,1+j+(e-1)*nRuns])
	LSvar_matrix[j+(e-1)*nRuns,2] = mean(tsLSvar[,1+j+(e-1)*nRuns])
   }
}
plot(FUNDvar_matrix[,1], FUNDvar_matrix[,2], main="FUND", xlab="Experiment", ylab="VaR", pch=21)
abline(lin_reg <- lm(FUNDvar_matrix[,2]~FUNDvar_matrix[,1]), col="red")   # regression line (var ~ experiment)
mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

plot(TRENDvar_matrix[,1], TRENDvar_matrix[,2], main="TREND", xlab="Experiment", ylab="VaR", pch=21)
abline(lin_reg <- lm(TRENDvar_matrix[,2]~TRENDvar_matrix[,1]), col="red")   # regression line (var ~ experiment)
mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

plot(LSvar_matrix[,1], LSvar_matrix[,2], main="LS", xlab="Experiment", ylab="VaR", pch=21)
abline(lin_reg <- lm(LSvar_matrix[,2]~LSvar_matrix[,1]), col="red")   # regression line (var ~ experiment)
mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

title(paste("Impact of changing parameter on agents' VaR."), outer = TRUE, col.main="blue", font.main=2)
mtext(paste("Objective: Study if agents' VaR is affected by the changing parameter"), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



##_________________________________________________________________#
##                                                                 #
##            FUND/TREND/LS LVaR as % of portfolio value           #
##_________________________________________________________________#
##                                                                 #
#
#### Calculate series of LVaR as % of portfolio value
#
##!! It is assumed that LVar is constant, and its value is set at the beginning of the script
#
#numFUND = 200  # Needed because VaR is averaged over the number of agents
#numTREND = 200
#numLS = 200
#
#tsFUNDvarperc <- array(0, dim=c(nTicks, nExp*nRuns))
#tsTRENDvarperc <- array(0, dim=c(nTicks, nExp*nRuns))
#tsLSvarperc <- array(0, dim=c(nTicks, nExp*nRuns))
#
#tsFUNDvarperc_avg <- array(0, dim=c(nTicks, nExp))
#tsTRENDvarperc_avg <- array(0, dim=c(nTicks, nExp))
#tsLSvarperc_avg <- array(0, dim=c(nTicks, nExp))
#
#for (k in seq(from=0, to=nExp-1)) {
#   for (j in seq(from=0, to=nRuns-1)) {
#      for (t in seq(from=1, to=nTicks)) {
#     
#         portfolioValue_FUND = 0
#         portfolioValue_TREND = 0
#         portfolioValue_LS = 0
#
#         for (i in seq(from=1, to=nAssets)) {
#            portfolioValue_FUND <- portfolioValue_FUND + tsFUNDvolume[t,1+i+j*nAssets+k*nAssets*nRuns] * tsprices[t,1+i+j*nAssets+k*nAssets*nRuns]
#            portfolioValue_TREND <- portfolioValue_TREND + tsTRENDvolume[t,1+i+j*nAssets+k*nAssets*nRuns] * tsprices[t,1+i+j*nAssets+k*nAssets*nRuns]
#            portfolioValue_LS <- portfolioValue_LS + tsLSvolume[t,1+i+j*nAssets+k*nAssets*nRuns] * tsprices[t,1+i+j*nAssets+k*nAssets*nRuns]
#         }
#
#         if (portfolioValue_FUND > 10000){  # Ensure that the positions are not insignificant
#            tsFUNDvarperc[t,j+1+k*nRuns] <- numFUND * LVar/portfolioValue_FUND
#         }
#
#         if (portfolioValue_TREND > 10000){   # Ensure that the positions are not insignificant
#            tsTRENDvarperc[t,j+1+k*nRuns] <- numTREND * LVar/portfolioValue_TREND
#         }
#
#         if (portfolioValue_LS > 10000){   # Ensure that the positions are not insignificant
#            tsLSvarperc[t,j+1+k*nRuns] <- numLS * LVar/portfolioValue_LS
#         }
#      }
#   }
#}
#
#for (k in seq(from=0, to=nExp-1)) {
#   for (j in seq(from=0, to=nRuns-1)) {
#      tsFUNDvarperc_avg[,1+k] <- tsFUNDvarperc_avg[,1+k] + tsFUNDvarperc[,j+1+k*nRuns]
#      tsTRENDvarperc_avg[,1+k] <- tsTRENDvarperc_avg[,1+k] + tsTRENDvarperc[,j+1+k*nRuns]
#      tsLSvarperc_avg[,1+k] <- tsLSvarperc_avg[,1+k] + tsLSvarperc[,j+1+k*nRuns]
#   }
#   tsFUNDvarperc_avg[,1+k] <- tsFUNDvarperc_avg[,1+k]/nRuns
#   tsTRENDvarperc_avg[,1+k] <- tsTRENDvarperc_avg[,1+k]/nRuns
#   tsLSvarperc_avg[,1+k] <- tsLSvarperc_avg[,1+k]/nRuns
#}
#
#
#
#### Plot of FUND, TREND and LS LVaR as percentage of portfolio value (averaged over runs)
#
#y_max = max(max(tsFUNDvarperc_avg[,1:nExp]), max(tsTRENDvarperc_avg[,1:nExp]), max(tsLSvarperc_avg[,1:nExp]))
#y_min = 0
#
#par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#for (e in seq(from=1, to=nExp)) {      
#   plot(tsTRENDvarperc_avg[,e], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="LVaR/Portf.value", col="seagreen")
#   lines(tsFUNDvarperc_avg[,e], type="l", col="darkorange1")
#   lines(tsLSvarperc_avg[,e], type="l", col="blue")
#}
#title(paste("Ratio of LVaR and portfolio value (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
#mtext("Objective: See how large is the LVaR w.r.t. portfolio value (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#### Plot of FUND, TREND and LS LVaR as percentage of portfolio value (for individual runs)
#
#y_max = max(max(tsFUNDvarperc[,1:(nRuns*nExp)]), max(tsTRENDvarperc[,1:(nRuns*nExp)]), max(tsLSvarperc[,1:(nRuns*nExp)]))
#y_min = 0
#
#step2 <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many
#
#for (e in seq(from=1, to=nExp)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   if (nRuns>numRows*numCols){   
#      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {     
#         plot(tsFUNDvarperc[,i+1+(e-1)*nRuns], type="l", ylab="LVaR/Portf.value", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
#         lines(tsTRENDvarperc[,i+1+(e-1)*nRuns], type="l", col="seagreen")
#         lines(tsLSvarperc[,i+1+(e-1)*nRuns], type="l", col="royalblue3")
#      }
#   } else {
#      for (i in seq(from=1, to=nRuns, by=1)) {
#         plot(tsFUNDvarperc[,i+(e-1)*nRuns], type="l", ylab="LVaR/Portf.value", main=paste("Run", i), ylim=c(y_min, y_max), col="darkorange1")
#         lines(tsTRENDvarperc[,i+(e-1)*nRuns], type="l", col="seagreen")  
#         lines(tsLSvarperc[,i+(e-1)*nRuns], type="l", col="royalblue3")
#      }
#   }
#   title(paste("Ratio of LVaR and portfolio value ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#   mtext("Objective: See how large is the VaR w.r.t. portfolio value. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#



##__________________________________________________________________#
##                                                                  #
##                      FUND/TREND/LS FAILURES                      #
##__________________________________________________________________#
##                                                                  # 
#
#### Plot of FUND, TREND and LS failures (averaged over runs)
#
#y_max = max(max(tsFUNDfailures_avg[,1:nExp]), max(tsTRENDfailures_avg[,1:nExp]), max(tsLSfailures_avg[,1:nExp]))
#y_min = min(min(tsFUNDfailures_avg[,1:nExp]), min(tsTRENDfailures_avg[,1:nExp]), min(tsLSfailures_avg[,1:nExp]))
#
#par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#for (e in seq(from=1, to=nExp)) {      
#   plot(tsTRENDfailures_avg[,e], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Failures", col="seagreen")
#   lines(tsFUNDfailures_avg[,e], type="l", col="darkorange1")
#   lines(tsLSfailures_avg[,e], type="l", col="blue")
#}
#title(paste("Failures of FUNDs vs TRENDs vs LS's (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
#mtext("Objective: Compare the number of failures of the three groups of agents (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#### Plot of FUND, TREND and LS failures (for individual runs)
#
#y_max = max(max(tsFUNDfailures[,2:(nRuns*nExp+1)]), max(tsTRENDfailures[,2:(nRuns*nExp+1)]), max(tsLSfailures[,2:(nRuns*nExp+1)]))
#y_min = min(min(tsFUNDfailures[,2:(nRuns*nExp+1)]), min(tsTRENDfailures[,2:(nRuns*nExp+1)]), min(tsLSfailures[,2:(nRuns*nExp+1)]))
#
#step2 <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many
#
#for (e in seq(from=1, to=nExp)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   if (nRuns>numRows*numCols){   
#      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {
#         plot(tsFUNDfailures[[i+2 +(e-1)*nRuns]], type="l", ylab="Failures", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
#         lines(tsTRENDfailures[[i+2 +(e-1)*nRuns]], type="l", col="seagreen")
#         lines(tsLSfailures[[i+2 +(e-1)*nRuns]], type="l", col="royalblue3")
#      }
#   } else {
#      for (i in seq(from=1, to=nRuns, by=1)) {
#         plot(tsFUNDfailures[[i+1 +(e-1)*nRuns]], type="l", ylab="Failures", main=paste("Run", i), ylim=c(y_min, y_max), col="darkorange1")
#         lines(tsTRENDfailures[[i+1 +(e-1)*nRuns]], type="l", col="seagreen")  
#         lines(tsLSfailures[[i+1 +(e-1)*nRuns]], type="l", col="royalblue3")
#      }
#   }
#   title(paste("Failures of FUNDs vs TRENDs vs LS's ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#   mtext("Objective: Compare the number of failures of the three groups of agents. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Bar charts of FUND/TREND/LS aggregated failures (averaged over runs)
##
## Objective: Compare the failures accumulated by each group of traders
#
#par(mfrow=c(numRows, numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#for (e in seq(from=1, to=nExp)) {
#   failures <- c(sum(tsFUNDfailures_avg[,e]), sum(tsTRENDfailures_avg[,e]), sum(tsLSfailures_avg[,e]))
#   labels <- c("FUND", "TREND", "LS") 
#   barplot(failures, names = labels, col=c("darkorange1", "seagreen", "royalblue3"), main=paste("Exp", e), ylim=c(0,200))
#}
#title(paste("Total failures along simulations"), outer = TRUE, col.main="blue", font.main=2)
#mtext("Objective: Compare the number of failures accumulated by each strategy.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#
#### Bar charts of FUND/TREND/LS aggregated failures (for individual runs)
##
## Objective: Compare the failures accumulated by each group of traders
## along each simulation
#
#for (e in seq(from=1, to=nExp)) {
#   par(mfrow=c(numRows, numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#   if (nRuns>numRows*numCols){   
#      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {
#         failures <- c(sum(tsFUNDfailures[[2+i +(e-1)*nRuns]]), sum(tsTRENDfailures[[2+i +(e-1)*nRuns]]), sum(tsLSfailures[[2+i +(e-1)*nRuns]]))
#         labels <- c("FUND", "TREND", "LS") 
#         barplot(failures, names = labels, col=c("darkorange1", "seagreen", "royalblue3"), main=paste("Run", i+1), ylim=c(0,200))
#      }
#   } else {
#      for (i in seq(from=1, to=nRuns, by=1)) {
#         failures <- c(sum(tsFUNDfailures[[1+i +(e-1)*nRuns]]), sum(tsTRENDfailures[[1+i +(e-1)*nRuns]]), sum(tsLSfailures[[1+i +(e-1)*nRuns]]))
#         labels <- c("FUND", "TREND", "LS") 
#         barplot(failures, names = labels, col=c("darkorange1", "seagreen", "royalblue3"), main=paste("Run", i), ylim=c(0,200))
#      }
#   }
#   title(paste("Total failures along simulations ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#   mtext("Objective: Compare the number of failures accumulated by each strategy.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#
#### Line plot of aggregated failures along experiments (averaged over runs)
#
#par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#sum_tsFUNDfailures_avg <- array(0, dim=c(1, nExp))
#sum_tsTRENDfailures_avg <- array(0, dim=c(1, nExp))
#sum_tsLSfailures_avg <- array(0, dim=c(1, nExp))
#
#for (e in seq(from=1, to=nExp)) {
#   sum_tsFUNDfailures_avg[e] <- sum(tsFUNDfailures_avg[,e])
#   sum_tsTRENDfailures_avg[e] <- sum(tsTRENDfailures_avg[,e])
#   sum_tsLSfailures_avg[e] <- sum(tsLSfailures_avg[,e])
#}
#
#y_max = max(max(sum_tsFUNDfailures_avg), max(sum_tsTRENDfailures_avg), max(sum_tsLSfailures_avg))
#y_min = min(min(sum_tsFUNDfailures_avg), min(sum_tsTRENDfailures_avg), min(sum_tsLSfailures_avg))
#
#plot(sum_tsFUNDfailures_avg[,], type="l", main="FUND", ylim=c(y_min, y_max), xlab="Experiment", ylab="", col="darkorange1")
#plot(sum_tsTRENDfailures_avg[,], type="l", main="TREND", ylim=c(y_min, y_max), xlab="Experiment", ylab="", col="seagreen")
#plot(sum_tsLSfailures_avg[,], type="l", main="LS", ylim=c(y_min, y_max), xlab="Experiment", ylab="", col="royalblue3")
#
#title(paste("Aggregated failures (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
#mtext("Objective: Study the evolution of agents' failures along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#### Boxplot of aggregated failures along experiments
## Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots
#
#par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#tsFUNDfailures_exp <- array(0, dim=c(nRuns, nExp))    # These allocate the sum of agent failures corresponding to the same experiment
#tsTRENDfailures_exp <- array(0, dim=c(nRuns, nExp))
#tsLSfailures_exp <- array(0, dim=c(nRuns, nExp))
#
#for (e in seq(from=1, to=nExp)) {      
#   for (j in seq(from=1, to=nRuns)) {
#      tsFUNDfailures_exp[j,e] <- sum(tsFUNDfailures[,1+j+(e-1)*nRuns])
#      tsTRENDfailures_exp[j,e] <- sum(tsTRENDfailures[,1+j+(e-1)*nRuns])
#      tsLSfailures_exp[j,e] <- sum(tsLSfailures[,1+j+(e-1)*nRuns])
#   }
#}
#boxplot(tsFUNDfailures_exp[,], notch=TRUE, col="darkorange1", main="FUND", xlab="")
#boxplot(tsTRENDfailures_exp[,], notch=TRUE, col="seagreen", main="TREND", xlab="")
#boxplot(tsLSfailures_exp[,], notch=TRUE, col="royalblue3", main="LS", xlab="")
#
#title("Range of variation of aggregated failures", outer = TRUE, col.main="blue", font.main=2)
#mtext("Test description: Overview of the evolution of agents' failures along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#
#### Scatterplot of failures along experiments
#
#par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#FUNDfailures_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , failures)
#TRENDfailures_matrix <- array(0, dim=c(nRuns*nExp, 2))
#LSfailures_matrix <- array(0, dim=c(nRuns*nExp, 2))
#     
#for (e in seq(from=1, to=nExp)) {
#   for (j in seq(from=1, to=nRuns)) {
#      FUNDfailures_matrix[j+(e-1)*nRuns,1] = e
#	TRENDfailures_matrix[j+(e-1)*nRuns,1] = e
#	LSfailures_matrix[j+(e-1)*nRuns,1] = e
#	   
#	FUNDfailures_matrix[j+(e-1)*nRuns,2] = sum(tsFUNDfailures[,1+j+(e-1)*nRuns])
#	TRENDfailures_matrix[j+(e-1)*nRuns,2] = sum(tsTRENDfailures[,1+j+(e-1)*nRuns])
#	LSfailures_matrix[j+(e-1)*nRuns,2] = sum(tsLSfailures[,1+j+(e-1)*nRuns])
#   }
#}
#plot(FUNDfailures_matrix[,1], FUNDfailures_matrix[,2], main="FUND", xlab="Experiment", ylab="Failures", pch=21)
#abline(lin_reg <- lm(FUNDfailures_matrix[,2]~FUNDfailures_matrix[,1]), col="red")   # regression line (failures ~ experiment)
#mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#
#plot(TRENDfailures_matrix[,1], TRENDfailures_matrix[,2], main="TREND", xlab="Experiment", ylab="Failures", pch=21)
#abline(lin_reg <- lm(TRENDfailures_matrix[,2]~TRENDfailures_matrix[,1]), col="red")   # regression line (failures ~ experiment)
#mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#
#plot(LSfailures_matrix[,1], LSfailures_matrix[,2], main="LS", xlab="Experiment", ylab="Failures", pch=21)
#abline(lin_reg <- lm(LSfailures_matrix[,2]~LSfailures_matrix[,1]), col="red")   # regression line (failures ~ experiment)
#mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#
#title(paste("Impact of changing parameter on agents' failures."), outer = TRUE, col.main="blue", font.main=2)
#mtext(paste("Objective: Study if agents' failures is affected by the changing parameter"), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#




###################################################################
#                                                                 #
#                       CONTAGION INDICATORS                      #
#                                                                 #
###################################################################

#_____________________________________________________________________________#
#                                                                             #
#           CONTAGION: CORRELATION OF RETURNS OF DIFFERENT ASSETS             #
#_____________________________________________________________________________#
#                                                                             #

#### Scatterplot of inter-asset returns to study their correlation (for individual runs)
##
## Objective: Study the correlation between the returns of different assets, as
## cross-market correlation is a measure of contagion
#
## !! It is assumed that the market has 2 or 3 assets
#
## Asset 1 & Asset 2
#
#for (e in seq(from=1, to=nExp)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   if (nRuns>numRows*numCols){
#      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#         plot(diff(tslogprices[[i+1+1 +(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+2+1 +(e-1)*nAssets*nRuns]]), main=paste("Run", 1+i/nAssets), xlab="Asset 1", ylab="Asset 2", pch=21, asp=1)
#         abline(lin_reg <- lm(diff(tslogprices[[i+2+1 +(e-1)*nAssets*nRuns]])~diff(tslogprices[[i+1+1 +(e-1)*nAssets*nRuns]])), col="red")   # regression line (returns A2 ~ returns A1)
#         mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#      }
#   } else {
#      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#         plot(diff(tslogprices[[i+1 +(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+2 +(e-1)*nAssets*nRuns]]), main=paste("Run", 1+i/nAssets), xlab="Asset 1", ylab="Asset 2", pch=21, asp=1)
#         abline(lin_reg <- lm(diff(tslogprices[[i+2 +(e-1)*nAssets*nRuns]])~diff(tslogprices[[i+1 +(e-1)*nAssets*nRuns]])), col="red")   # regression line (returns A2 ~ returns A1)
#         mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#      }
#   }
#   title(paste("Contagion: Correlation between returns of Asset 1 and Asset 2 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#   mtext("Objective: Study if movements in one asset induce movements in the other asset. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#if (nAssets > 2){
#
#   # Asset 1 & Asset 3
#
#   for (e in seq(from=1, to=nExp)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#            plot(diff(tslogprices[[i+1+1 +(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+3+1 +(e-1)*nAssets*nRuns]]), main=paste("Run", 1+i/nAssets), xlab="Asset 1", ylab="Asset 3", pch=21, asp=1)
#            abline(lin_reg <- lm(diff(tslogprices[[i+3+1 +(e-1)*nAssets*nRuns]])~diff(tslogprices[[i+1+1 +(e-1)*nAssets*nRuns]])), col="red")   # regression line (returns A3 ~ returns A1)
#            mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(diff(tslogprices[[i+1 +(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+3 +(e-1)*nAssets*nRuns]]), main=paste("Run", 1+i/nAssets), xlab="Asset 1", ylab="Asset 3", pch=21, asp=1)
#            abline(lin_reg <- lm(diff(tslogprices[[i+3 +(e-1)*nAssets*nRuns]])~diff(tslogprices[[i+1 +(e-1)*nAssets*nRuns]])), col="red")   # regression line (returns A3 ~ returns A1)
#            mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#         }
#      }
#      title(paste("Contagion: Correlation between returns of Asset 1 and Asset 3 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Study if movements in one asset induce movements in the other asset. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#
#
#   # Asset 2 & Asset 3
#
#   for (e in seq(from=1, to=nExp)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#            plot(diff(tslogprices[[i+2+1 +(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+3+1 +(e-1)*nAssets*nRuns]]), main=paste("Run", 1+i/nAssets), xlab="Asset 2", ylab="Asset 3", pch=21, asp=1)
#            abline(lin_reg <- lm(diff(tslogprices[[i+3+1 +(e-1)*nAssets*nRuns]])~diff(tslogprices[[i+2+1 +(e-1)*nAssets*nRuns]])), col="red")   # regression line (returns A3 ~ returns A2)
#            mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(diff(tslogprices[[i+2 +(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+3 +(e-1)*nAssets*nRuns]]), main=paste("Run", 1+i/nAssets), xlab="Asset 2", ylab="Asset 3", pch=21, asp=1)
#            abline(lin_reg <- lm(diff(tslogprices[[i+3 +(e-1)*nAssets*nRuns]])~diff(tslogprices[[i+2 +(e-1)*nAssets*nRuns]])), col="red")   # regression line (returns A3 ~ returns A2)
#            mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#         }
#      }
#      title(paste("Contagion: Correlation between returns of Asset 2 and Asset 3 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Study if movements in one asset induce movements in the other asset. [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#
#}


#### Time series of correlation of returns of different assets
## 
## Objective: Study if correlation between different assets increases after a shock
#
#### Calculate series of correlations
## !! It is assumed that the market has 2 or 3 assets
#
#tscorr_12 <- array(0, dim=c(nTicks, nExp*nRuns))
#tscorr_12_avg <- array(0, dim=c(nTicks, nExp))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nRuns)) {
#      for (i in seq(from=1, to=nTicks-volWindow)) {
#	   tscorr_12[i+volWindow,(e-1)*nRuns+k] <- cor( diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+1]), diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+2]) )
#      }
#   }
#}
#
#for (e in seq(from=1, to=nExp)) {
#   for (j in seq(from=1, to=nRuns)) {
#      tscorr_12_avg[,e] <- tscorr_12_avg[,e] + tscorr_12[,j+(e-1)*nRuns]
#   }
#   tscorr_12_avg[,e] <- tscorr_12_avg[,e]/nRuns
#}
#
#
#if (nAssets > 2){
#   
#   tscorr_13 <- array(0, dim=c(nTicks, nExp*nRuns))
#   tscorr_23 <- array(0, dim=c(nTicks, nExp*nRuns))
#
#   tscorr_13_avg <- array(0, dim=c(nTicks, nExp))
#   tscorr_23_avg <- array(0, dim=c(nTicks, nExp))
#
#   for (e in seq(from=1, to=nExp)) {
#      for (k in seq(from=1, to=nRuns)) {
#         for (i in seq(from=1, to=nTicks-volWindow)) {
#	      tscorr_13[i+volWindow,(e-1)*nRuns+k] <- cor( diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+1]), diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+3]) )
#            tscorr_23[i+volWindow,(e-1)*nRuns+k] <- cor( diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+2]), diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+3]) )
#         }
#      }
#   }
#
#   for (e in seq(from=1, to=nExp)) {
#      for (j in seq(from=1, to=nRuns)) {
#         tscorr_13_avg[,e] <- tscorr_13_avg[,e] + tscorr_13[,j+(e-1)*nRuns]
#         tscorr_23_avg[,e] <- tscorr_23_avg[,e] + tscorr_23[,j+(e-1)*nRuns]
#      }
#      tscorr_13_avg[,e] <- tscorr_13_avg[,e]/nRuns
#      tscorr_23_avg[,e] <- tscorr_23_avg[,e]/nRuns
#   }
#}
#
#
#### Plot of time series of cross-market return correlations (averaged over runs)
#
#par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#
#for (e in seq(from=1, to=nExp)) {
#   plot(tscorr_12_avg[,e], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Tick", ylab="", col="black")
#
#   if (nAssets > 2){
#      lines(tscorr_13_avg[,e], type="l", col="purple")
#      lines(tscorr_23_avg[,e], type="l", col="plum4")
#   }
#}
#title(paste("Contagion: Correlations between returns of different assets (avg. over runs)"), outer = TRUE, col.main="blue", font.main=2)   
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#### Plot of time series of cross-market return correlations (for individual runs)
#
#step_cor <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many
#
#for (e in seq(from=1, to=nExp)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   if (nRuns>numRows*numCols){
#      for (i in seq(from=step_cor, to=step_cor*numRows*numCols, by=step_cor)) {
#         plot(tscorr_12[,i+1 +(e-1)*nRuns], type="l", main=paste("Run", i+1), ylim=c(-1,1), xlab="Tick", ylab="", col="black")
#
#         if (nAssets > 2){
#            lines(tscorr_13[,i+1 +(e-1)*nRuns], type="l", col="purple")
#            lines(tscorr_23[,i+1 +(e-1)*nRuns], type="l", col="plum4")
#         }
#      }
#   } else {
#      for (i in seq(from=1, to=nRuns)) {
#         plot(tscorr_12[,i+1 +(e-1)*nRuns-1], type="l", main=paste("Run", i), ylim=c(-1,1), xlab="Tick", ylab="", col="black")
#
#         if (nAssets > 2){ 
#            lines(tscorr_13[,i+1 +(e-1)*nRuns-1], type="l", col="purple")
#            lines(tscorr_23[,i+1 +(e-1)*nRuns-1], type="l", col="plum4")
#         }
#      }
#   }
#   title(paste("Contagion: Correlations between returns of different assets ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#


# ----------------------------------------------- #


dev.off()  # Close output files
sink()


# ----------------------------------------------- #




