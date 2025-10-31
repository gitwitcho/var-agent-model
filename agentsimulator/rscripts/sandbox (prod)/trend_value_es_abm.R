
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
nExp = 11
liquidity = 400      # Used to plot contributions to price formation
volWindow = 20       # Window used to calculate volatility
LVar = 40            # Value of Var limit to compare it to portfolio value

# Setting the path to the data folder

# Set the root directory (add your path)
root.dir <- "C:/Users/bllac/eclipse-workspace/eclipse_DB"

# Build the home directory (shouldn't be necessary to change)
home.dir <- paste(root.dir, "/agentsimulator/out/trend-value-es-abm-simulation/", sep="")

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
tsFUNDwealth <- read.table(paste(home.dir,"list_fundwealth_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDwealth <- read.table(paste(home.dir,"list_trendwealth_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDorders <- read.table(paste(home.dir,"list_fundorders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDorders <- read.table(paste(home.dir,"list_trendorders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

#tsFUNDvarreducedvolume <- read.table(paste(home.dir,"list_fundvarreducedvolume_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsTRENDvarreducedvolume <- read.table(paste(home.dir,"list_trendvarreducedvolume_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsFUNDvarreducedorders <- read.table(paste(home.dir,"list_fundvarreducedorders_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsTRENDvarreducedorders <- read.table(paste(home.dir,"list_trendvarreducedorders_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsFUNDesreducedvolume <- read.table(paste(home.dir,"list_fundesreducedvolume_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsTRENDesreducedvolume <- read.table(paste(home.dir,"list_trendesreducedvolume_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsFUNDesreducedorders <- read.table(paste(home.dir,"list_fundesreducedorders_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsTRENDesreducedorders <- read.table(paste(home.dir,"list_trendesreducedorders_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

tsFUNDvarsellofforders <- read.table(paste(home.dir,"list_fundvarsellofforders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDvarsellofforders <- read.table(paste(home.dir,"list_trendvarsellofforders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDvarselloffvolume <- read.table(paste(home.dir,"list_fundvarselloffvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDvarselloffvolume <- read.table(paste(home.dir,"list_trendvarselloffvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDessellofforders <- read.table(paste(home.dir,"list_fundessellofforders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDessellofforders <- read.table(paste(home.dir,"list_trendessellofforders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDesselloffvolume <- read.table(paste(home.dir,"list_fundesselloffvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDesselloffvolume <- read.table(paste(home.dir,"list_trendesselloffvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

tsFUNDvar <- read.table(paste(home.dir,"list_fundvar_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDvar <- read.table(paste(home.dir,"list_trendvar_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDstressedvar <- read.table(paste(home.dir,"list_fundstressedvar_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDstressedvar <- read.table(paste(home.dir,"list_trendstressedvar_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDes <- read.table(paste(home.dir,"list_fundes_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDes <- read.table(paste(home.dir,"list_trendes_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDstressedes <- read.table(paste(home.dir,"list_fundstressedes_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDstressedes <- read.table(paste(home.dir,"list_trendstressedes_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

#tsFUNDfailures <- read.table(paste(home.dir,"list_fundfailures_timeseries_E0.csv",sep=""),
#   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsTRENDfailures <- read.table(paste(home.dir,"list_trendfailures_timeseries_E0.csv",sep=""),
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

      tsFUNDwealth_exp <- read.table(paste(home.dir, paste("list_fundwealth_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDwealth <- merge(tsFUNDwealth, tsFUNDwealth_exp, by="tick")

      tsTRENDwealth_exp <- read.table(paste(home.dir, paste("list_trendwealth_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDwealth <- merge(tsTRENDwealth, tsTRENDwealth_exp, by="tick")

      tsFUNDorders_exp <- read.table(paste(home.dir, paste("list_fundorders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDorders <- merge(tsFUNDorders, tsFUNDorders_exp, by="tick")

      tsTRENDorders_exp <- read.table(paste(home.dir, paste("list_trendorders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDorders <- merge(tsTRENDorders, tsTRENDorders_exp, by="tick")

#      tsFUNDvarreducedvolume_exp <- read.table(paste(home.dir, paste("list_fundvarreducedvolume_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsFUNDvarreducedvolume <- merge(tsFUNDvarreducedvolume, tsFUNDvarreducedvolume_exp, by="tick")

#      tsTRENDvarreducedvolume_exp <- read.table(paste(home.dir, paste("list_trendvarreducedvolume_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsTRENDvarreducedvolume <- merge(tsTRENDvarreducedvolume, tsTRENDvarreducedvolume_exp, by="tick")

#      tsFUNDvarreducedorders_exp <- read.table(paste(home.dir, paste("list_fundvarreducedorders_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsFUNDvarreducedorders <- merge(tsFUNDvarreducedorders, tsFUNDvarreducedorders_exp, by="tick")

#      tsTRENDvarreducedorders_exp <- read.table(paste(home.dir, paste("list_trendvarreducedorders_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsTRENDvarreducedorders <- merge(tsTRENDvarreducedorders, tsTRENDvarreducedorders_exp, by="tick")

#      tsFUNDesreducedvolume_exp <- read.table(paste(home.dir, paste("list_fundesreducedvolume_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsFUNDesreducedvolume <- merge(tsFUNDesreducedvolume, tsFUNDesreducedvolume_exp, by="tick")

#      tsTRENDesreducedvolume_exp <- read.table(paste(home.dir, paste("list_trendesreducedvolume_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsTRENDesreducedvolume <- merge(tsTRENDesreducedvolume, tsTRENDesreducedvolume_exp, by="tick")

#      tsFUNDesreducedorders_exp <- read.table(paste(home.dir, paste("list_fundesreducedorders_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsFUNDesreducedorders <- merge(tsFUNDesreducedorders, tsFUNDesreducedorders_exp, by="tick")

#      tsTRENDesreducedorders_exp <- read.table(paste(home.dir, paste("list_trendesreducedorders_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsTRENDesreducedorders <- merge(tsTRENDesreducedorders, tsTRENDesreducedorders_exp, by="tick")

      tsFUNDvarsellofforders_exp <- read.table(paste(home.dir, paste("list_fundvarsellofforders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDvarsellofforders <- merge(tsFUNDvarsellofforders, tsFUNDvarsellofforders_exp, by="tick")

      tsTRENDvarsellofforders_exp <- read.table(paste(home.dir, paste("list_trendvarsellofforders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDvarsellofforders <- merge(tsTRENDvarsellofforders, tsTRENDvarsellofforders_exp, by="tick")

      tsFUNDvarselloffvolume_exp <- read.table(paste(home.dir, paste("list_fundvarselloffvolume_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDvarselloffvolume <- merge(tsFUNDvarselloffvolume, tsFUNDvarselloffvolume_exp, by="tick")

      tsTRENDvarselloffvolume_exp <- read.table(paste(home.dir, paste("list_trendvarselloffvolume_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDvarselloffvolume <- merge(tsTRENDvarselloffvolume, tsTRENDvarselloffvolume_exp, by="tick")

      tsFUNDessellofforders_exp <- read.table(paste(home.dir, paste("list_fundessellofforders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDessellofforders <- merge(tsFUNDessellofforders, tsFUNDessellofforders_exp, by="tick")

      tsTRENDessellofforders_exp <- read.table(paste(home.dir, paste("list_trendessellofforders_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDessellofforders <- merge(tsTRENDessellofforders, tsTRENDessellofforders_exp, by="tick")

      tsFUNDesselloffvolume_exp <- read.table(paste(home.dir, paste("list_fundesselloffvolume_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDesselloffvolume <- merge(tsFUNDesselloffvolume, tsFUNDesselloffvolume_exp, by="tick")

      tsTRENDesselloffvolume_exp <- read.table(paste(home.dir, paste("list_trendesselloffvolume_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDesselloffvolume <- merge(tsTRENDesselloffvolume, tsTRENDesselloffvolume_exp, by="tick")

      tsFUNDvar_exp <- read.table(paste(home.dir, paste("list_fundvar_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDvar <- merge(tsFUNDvar, tsFUNDvar_exp, by="tick")

      tsTRENDvar_exp <- read.table(paste(home.dir, paste("list_trendvar_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDvar <- merge(tsTRENDvar, tsTRENDvar_exp, by="tick")

      tsFUNDes_exp <- read.table(paste(home.dir, paste("list_fundes_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDes <- merge(tsFUNDes, tsFUNDes_exp, by="tick")

      tsTRENDes_exp <- read.table(paste(home.dir, paste("list_trendes_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDes <- merge(tsTRENDes, tsTRENDes_exp, by="tick")

      tsFUNDstressedvar_exp <- read.table(paste(home.dir, paste("list_fundstressedvar_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDstressedvar <- merge(tsFUNDstressedvar, tsFUNDstressedvar_exp, by="tick")

      tsTRENDstressedvar_exp <- read.table(paste(home.dir, paste("list_trendstressedvar_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDstressedvar <- merge(tsTRENDstressedvar, tsTRENDstressedvar_exp, by="tick")

      tsFUNDstressedes_exp <- read.table(paste(home.dir, paste("list_fundstressedes_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDstressedes <- merge(tsFUNDstressedes, tsFUNDstressedes_exp, by="tick")

      tsTRENDstressedes_exp <- read.table(paste(home.dir, paste("list_trendstressedes_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDstressedes <- merge(tsTRENDstressedes, tsTRENDstressedes_exp, by="tick")

#      tsFUNDfailures_exp <- read.table(paste(home.dir, paste("list_fundfailures_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsFUNDfailures <- merge(tsFUNDfailures, tsFUNDfailures_exp, by="tick")

#      tsTRENDfailures_exp <- read.table(paste(home.dir, paste("list_trendfailures_timeseries_E",e,".csv", sep=""), sep=""),
#         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#      tsTRENDfailures <- merge(tsTRENDfailures, tsTRENDfailures_exp, by="tick")
   }
}


# Parameters needed from the java files

nRuns <- (dim(tsprices)[2] - 1)/(nAssets*nExp)
nTicks <- dim(tsprices)[1]

param_file = "trend_value_es_1_asset_abm"  # Parameter file

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
colnames(tsFUNDwealth) <- titles
colnames(tsTRENDwealth) <- titles
colnames(tsFUNDorders) <- titles
colnames(tsTRENDorders) <- titles
#colnames(tsFUNDvarreducedvolume) <- titles
#colnames(tsTRENDvarreducedvolume) <- titles
#colnames(tsFUNDvarreducedorders) <- titles
#colnames(tsTRENDvarreducedorders) <- titles
#colnames(tsFUNDesreducedvolume) <- titles
#colnames(tsTRENDesreducedvolume) <- titles
#colnames(tsFUNDesreducedorders) <- titles
#colnames(tsTRENDesreducedorders) <- titles
colnames(tsFUNDvarsellofforders) <- titles
colnames(tsTRENDvarsellofforders) <- titles
colnames(tsFUNDvarselloffvolume) <- titles
colnames(tsTRENDvarselloffvolume) <- titles
colnames(tsFUNDessellofforders) <- titles
colnames(tsTRENDessellofforders) <- titles
colnames(tsFUNDesselloffvolume) <- titles
colnames(tsTRENDesselloffvolume) <- titles

titles = "tick"

for (e in seq(from=1, to=nExp)) {
   for (r in seq(from=1, to=nRuns)) {
      titles <- append(titles, paste("E", e, "_R", r, sep=""))
   }
}

colnames(tsFUNDvar) <- titles
colnames(tsTRENDvar) <- titles
colnames(tsFUNDes) <- titles
colnames(tsTRENDes) <- titles
colnames(tsFUNDstressedvar) <- titles
colnames(tsTRENDstressedvar) <- titles
colnames(tsFUNDstressedes) <- titles
colnames(tsTRENDstressedes) <- titles
#colnames(tsFUNDfailures) <- titles
#colnames(tsTRENDfailures) <- titles



###################################################################
#                                                                 #
#                    [AUXILIARY CALCULATIONS]                     #
#                                                                 #
#          AVERAGE ACF's and time series (for each asset)         #
#                   - averaged over all runs -                    #
#                                                                 #
###################################################################

# ------ Calculate logarithmic prices (for returns) and values ------ #

tslogprices <- base::log(tsprices)
tslogprices[[1]] <- tsprices[[1]]  # The 'tick' column must not change

tslogvalues <- base::log(tsvalues)
tslogvalues[[1]] <- tsvalues[[1]]  # The 'tick' column must not change


# ------ Calculate exogenous, random contribution to price formation ------ #

tsrandomprices <- array(0, dim=c(nTicks, 1+nAssets*nExp*nRuns))

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         tsrandomprices[1:(nTicks-1),i+1+j*nAssets+k*nAssets*nRuns] <- diff(tsprices[[i+1+j*nAssets+k*nAssets*nRuns]])[1:(nTicks-1)] - 
 		  tsFUNDorders[1:(nTicks-1),i+1+j*nAssets+k*nAssets*nRuns]/liquidity - tsTRENDorders[1:(nTicks-1),i+1+j*nAssets+k*nAssets*nRuns]/liquidity
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
tsFUNDwealth_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDwealth_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsFUNDorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsFUNDvarreducedvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsTRENDvarreducedvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsFUNDvarreducedorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsTRENDvarreducedorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsFUNDesreducedvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsTRENDesreducedvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsFUNDesreducedorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
#tsTRENDesreducedorders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsFUNDvarsellofforders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDvarsellofforders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsFUNDvarselloffvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDvarselloffvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsFUNDessellofforders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDessellofforders_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsFUNDesselloffvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDesselloffvolume_avg <- array(0, dim=c(nTicks, nAssets*nExp))
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

         tsFUNDwealth_avg[,i+k*nAssets] <- tsFUNDwealth_avg[,i+k*nAssets] + tsFUNDwealth[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDwealth_avg[,i+k*nAssets] <- tsTRENDwealth_avg[,i+k*nAssets] + tsTRENDwealth[[i+1+j*nAssets+k*nAssets*nRuns]]

         tsFUNDorders_avg[,i+k*nAssets] <- tsFUNDorders_avg[,i+k*nAssets] + tsFUNDorders[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDorders_avg[,i+k*nAssets] <- tsTRENDorders_avg[,i+k*nAssets] + tsTRENDorders[[i+1+j*nAssets+k*nAssets*nRuns]]

#         tsFUNDvarreducedvolume_avg[,i+k*nAssets] <- tsFUNDvarreducedvolume_avg[,i+k*nAssets] + tsFUNDvarreducedvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
#         tsTRENDvarreducedvolume_avg[,i+k*nAssets] <- tsTRENDvarreducedvolume_avg[,i+k*nAssets] + tsTRENDvarreducedvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
#         tsFUNDvarreducedorders_avg[,i+k*nAssets] <- tsFUNDvarreducedorders_avg[,i+k*nAssets] + tsFUNDvarreducedorders[[i+1+j*nAssets+k*nAssets*nRuns]]
#         tsTRENDvarreducedorders_avg[,i+k*nAssets] <- tsTRENDvarreducedorders_avg[,i+k*nAssets] + tsTRENDvarreducedorders[[i+1+j*nAssets+k*nAssets*nRuns]]

#         tsFUNDesreducedvolume_avg[,i+k*nAssets] <- tsFUNDesreducedvolume_avg[,i+k*nAssets] + tsFUNDesreducedvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
#         tsTRENDesreducedvolume_avg[,i+k*nAssets] <- tsTRENDesreducedvolume_avg[,i+k*nAssets] + tsTRENDesreducedvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
#         tsFUNDesreducedorders_avg[,i+k*nAssets] <- tsFUNDesreducedorders_avg[,i+k*nAssets] + tsFUNDesreducedorders[[i+1+j*nAssets+k*nAssets*nRuns]]
#         tsTRENDesreducedorders_avg[,i+k*nAssets] <- tsTRENDesreducedorders_avg[,i+k*nAssets] + tsTRENDesreducedorders[[i+1+j*nAssets+k*nAssets*nRuns]]

         tsFUNDvarsellofforders_avg[,i+k*nAssets] <- tsFUNDvarsellofforders_avg[,i+k*nAssets] + tsFUNDvarsellofforders[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDvarsellofforders_avg[,i+k*nAssets] <- tsTRENDvarsellofforders_avg[,i+k*nAssets] + tsTRENDvarsellofforders[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsFUNDvarselloffvolume_avg[,i+k*nAssets] <- tsFUNDvarselloffvolume_avg[,i+k*nAssets] + tsFUNDvarselloffvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDvarselloffvolume_avg[,i+k*nAssets] <- tsTRENDvarselloffvolume_avg[,i+k*nAssets] + tsTRENDvarselloffvolume[[i+1+j*nAssets+k*nAssets*nRuns]]

         tsFUNDessellofforders_avg[,i+k*nAssets] <- tsFUNDessellofforders_avg[,i+k*nAssets] + tsFUNDessellofforders[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDessellofforders_avg[,i+k*nAssets] <- tsTRENDessellofforders_avg[,i+k*nAssets] + tsTRENDessellofforders[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsFUNDesselloffvolume_avg[,i+k*nAssets] <- tsFUNDesselloffvolume_avg[,i+k*nAssets] + tsFUNDesselloffvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDesselloffvolume_avg[,i+k*nAssets] <- tsTRENDesselloffvolume_avg[,i+k*nAssets] + tsTRENDesselloffvolume[[i+1+j*nAssets+k*nAssets*nRuns]]

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
      tsFUNDwealth_avg[,i+k*nAssets] <- tsFUNDwealth_avg[,i+k*nAssets]/nRuns
      tsTRENDwealth_avg[,i+k*nAssets] <- tsTRENDwealth_avg[,i+k*nAssets]/nRuns
      tsFUNDorders_avg[,i+k*nAssets] <- tsFUNDorders_avg[,i+k*nAssets]/nRuns
      tsTRENDorders_avg[,i+k*nAssets] <- tsTRENDorders_avg[,i+k*nAssets]/nRuns

#	tsFUNDvarreducedvolume_avg[,i+k*nAssets] <- tsFUNDvarreducedvolume_avg[,i+k*nAssets]/nRuns
#	tsTRENDvarreducedvolume_avg[,i+k*nAssets] <- tsTRENDvarreducedvolume_avg[,i+k*nAssets]/nRuns
#	tsFUNDvarreducedorders_avg[,i+k*nAssets] <- tsFUNDvarreducedorders_avg[,i+k*nAssets]/nRuns
#	tsTRENDvarreducedorders_avg[,i+k*nAssets] <- tsTRENDvarreducedorders_avg[,i+k*nAssets]/nRuns

#	tsFUNDesreducedvolume_avg[,i+k*nAssets] <- tsFUNDesreducedvolume_avg[,i+k*nAssets]/nRuns
#	tsTRENDesreducedvolume_avg[,i+k*nAssets] <- tsTRENDesreducedvolume_avg[,i+k*nAssets]/nRuns
#	tsFUNDesreducedorders_avg[,i+k*nAssets] <- tsFUNDesreducedorders_avg[,i+k*nAssets]/nRuns
#	tsTRENDesreducedorders_avg[,i+k*nAssets] <- tsTRENDesreducedorders_avg[,i+k*nAssets]/nRuns

	tsFUNDvarsellofforders_avg[,i+k*nAssets] <- tsFUNDvarsellofforders_avg[,i+k*nAssets]/nRuns
	tsTRENDvarsellofforders_avg[,i+k*nAssets] <- tsTRENDvarsellofforders_avg[,i+k*nAssets]/nRuns
	tsFUNDvarselloffvolume_avg[,i+k*nAssets] <- tsFUNDvarselloffvolume_avg[,i+k*nAssets]/nRuns
	tsTRENDvarselloffvolume_avg[,i+k*nAssets] <- tsTRENDvarselloffvolume_avg[,i+k*nAssets]/nRuns

	tsFUNDessellofforders_avg[,i+k*nAssets] <- tsFUNDessellofforders_avg[,i+k*nAssets]/nRuns
	tsTRENDessellofforders_avg[,i+k*nAssets] <- tsTRENDessellofforders_avg[,i+k*nAssets]/nRuns
	tsFUNDesselloffvolume_avg[,i+k*nAssets] <- tsFUNDesselloffvolume_avg[,i+k*nAssets]/nRuns
	tsTRENDesselloffvolume_avg[,i+k*nAssets] <- tsTRENDesselloffvolume_avg[,i+k*nAssets]/nRuns

      tsrandomprices_avg[,i+k*nAssets] <- tsrandomprices_avg[,i+k*nAssets]/nRuns

      kurt_avg[,i+k*nAssets] <- kurt_avg[,i+k*nAssets]/nRuns
   }
}


tsFUNDvar_avg <- array(0, dim=c(nTicks, nExp))
tsTRENDvar_avg <- array(0, dim=c(nTicks, nExp))
tsFUNDes_avg <- array(0, dim=c(nTicks, nExp))
tsTRENDes_avg <- array(0, dim=c(nTicks, nExp))
tsFUNDstressedvar_avg <- array(0, dim=c(nTicks, nExp))
tsTRENDstressedvar_avg <- array(0, dim=c(nTicks, nExp))
tsFUNDstressedes_avg <- array(0, dim=c(nTicks, nExp))
tsTRENDstressedes_avg <- array(0, dim=c(nTicks, nExp))
#tsFUNDfailures_avg <- array(0, dim=c(nTicks, nExp))
#tsTRENDfailures_avg <- array(0, dim=c(nTicks, nExp))

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=1, to=nRuns)) {
      tsFUNDvar_avg[,k+1] <- tsFUNDvar_avg[,k+1] + tsFUNDvar[[1+j+k*nRuns]]
      tsTRENDvar_avg[,k+1] <- tsTRENDvar_avg[,k+1] + tsTRENDvar[[1+j+k*nRuns]]
      tsFUNDes_avg[,k+1] <- tsFUNDes_avg[,k+1] + tsFUNDes[[1+j+k*nRuns]]
      tsTRENDes_avg[,k+1] <- tsTRENDes_avg[,k+1] + tsTRENDes[[1+j+k*nRuns]]
      tsFUNDstressedvar_avg[,k+1] <- tsFUNDstressedvar_avg[,k+1] + tsFUNDstressedvar[[1+j+k*nRuns]]
      tsTRENDstressedvar_avg[,k+1] <- tsTRENDstressedvar_avg[,k+1] + tsTRENDstressedvar[[1+j+k*nRuns]]
      tsFUNDstressedes_avg[,k+1] <- tsFUNDstressedes_avg[,k+1] + tsFUNDstressedes[[1+j+k*nRuns]]
      tsTRENDstressedes_avg[,k+1] <- tsTRENDstressedes_avg[,k+1] + tsTRENDstressedes[[1+j+k*nRuns]]
#      tsFUNDfailures_avg[,k+1] <- tsFUNDfailures_avg[,k+1] + tsFUNDfailures[[1+j+k*nRuns]]
#      tsTRENDfailures_avg[,k+1] <- tsTRENDfailures_avg[,k+1] + tsTRENDfailures[[1+j+k*nRuns]]
   }
   tsFUNDvar_avg[,k+1] <- tsFUNDvar_avg[,k+1]/nRuns
   tsTRENDvar_avg[,k+1] <- tsTRENDvar_avg[,k+1]/nRuns
   tsFUNDes_avg[,k+1] <- tsFUNDes_avg[,k+1]/nRuns
   tsTRENDes_avg[,k+1] <- tsTRENDes_avg[,k+1]/nRuns
   tsFUNDstressedvar_avg[,k+1] <- tsFUNDstressedvar_avg[,k+1]/nRuns
   tsTRENDstressedvar_avg[,k+1] <- tsTRENDstressedvar_avg[,k+1]/nRuns
   tsFUNDstressedes_avg[,k+1] <- tsFUNDstressedes_avg[,k+1]/nRuns
   tsTRENDstressedes_avg[,k+1] <- tsTRENDstressedes_avg[,k+1]/nRuns
#   tsFUNDfailures_avg[,k+1] <- tsFUNDfailures_avg[,k+1]/nRuns
#   tsTRENDfailures_avg[,k+1] <- tsTRENDfailures_avg[,k+1]/nRuns
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

#pdf(paste(home.dir, "Trend_Value_ES_ABM_Exp_outR.pdf", sep=""))   # Plot diagrams in a pdf file
#sink(paste(home.dir, "Trend_Value_ES_ABM_Exp_outR.txt", sep=""))  # Write quantitative results to a text file



###################################################################
#                                                                 #
#         VALIDATION TESTS (Stylised facts for each asset)        #
#                                                                 #
###################################################################

cat("TEST: VA_TREND_VALUE_ES_ABM \n")
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



#____________________________________________________#
#                                                    #
#           PERFORMANCE OF FUNDs vs TRENDs           #
#____________________________________________________#
#                                                    #

# We plot here the average increment in wealth of FUNDs and TRENDs
# to compare their performance


### Plot of time series of wealth increment (averaged over runs)

y_max = max(max(tsFUNDwealth_avg[,1:(nAssets*nExp)]), max(tsTRENDwealth_avg[,1:(nAssets*nExp)]))
y_min = min(min(tsFUNDwealth_avg[,1:(nAssets*nExp)]), min(tsTRENDwealth_avg[,1:(nAssets*nExp)]))

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      plot(tsFUNDwealth_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Wealth", col="darkorange1")
      lines(tsTRENDwealth_avg[,(e-1)*nAssets+k], type="l", col="seagreen")
   }
   title(paste("Increment in wealth of FUNDs vs TRENDs (averaged over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Study which group of agents performs better (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
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


### Plot of wealth increment (for individual runs)

y_max = max(max(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)]))
y_min = min(min(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)]))

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
            plot(tsFUNDwealth[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Wealth", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max), col="darkorange1")
            lines(tsTRENDwealth[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            plot(tsFUNDwealth[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Wealth", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max), col="darkorange1")
            lines(tsTRENDwealth[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
         }
      }
      title(paste("Increment in wealth of FUNDs/TRENDs - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Objective: Study which group of agents performs better (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


### Plot of final wealth (averaged over runs)

y_max = max(max(tsFUNDwealth_avg[nTicks,1:(nAssets*nExp)]), max(tsTRENDwealth_avg[nTicks,1:(nAssets*nExp)]))
y_min = min(min(tsFUNDwealth_avg[nTicks,1:(nAssets*nExp)]), min(tsTRENDwealth_avg[nTicks,1:(nAssets*nExp)]))

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

for (k in seq(from=1, to=nAssets)) {
   indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)
   plot(tsFUNDwealth_avg[nTicks, indices], type="l", main=paste("Asset", k), xlab="Experiment", ylab="Wealth", ylim=c(y_min, y_max), lwd=2, col="darkorange1")
   lines(tsTRENDwealth_avg[nTicks, indices], type="l", col="seagreen", lwd=2)
}
title(paste("Total increment in wealth of FUNDs vs TRENDs (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study which group of agents performs better (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


## Version for the thesis 
#y_max = max(max(tsFUNDwealth_avg[nTicks,1:(nAssets*nExp)]), max(tsTRENDwealth_avg[nTicks,1:(nAssets*nExp)]))
#y_min = min(min(tsFUNDwealth_avg[nTicks,1:(nAssets*nExp)]), min(tsTRENDwealth_avg[nTicks,1:(nAssets*nExp)]))
#x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
##x_axis <- c("5", "", "", "20", "", "", "35", "", "", "50", "", "", "65", "", "", "80")
#
##dev.new()
#k=1
#indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)
#plot(tsFUNDwealth_avg[nTicks, indices], type="l", main="", xlab="Porcentaje de agentes con l�mite antic�clico", ylab="", ylim=c(y_min, y_max), lwd=2, col="darkorange1", xaxt='n')
#lines(tsTRENDwealth_avg[nTicks, indices], type="l", col="seagreen", lwd=2)
#axis(1, at=1:nExp, labels=x_axis)
#legend("topright", c("Fundamentalistas","Tecnicos"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen"))



### Plot of ratio between mean and standard deviation of final wealth (~Sharpe ratio) [mean and stdev calculated over runs]

Sharpe_FUND <- array(0, dim=c(nExp, nAssets))   # Array to store the Sharpe ratio for each asset and experiment
Sharpe_TREND <- array(0, dim=c(nExp, nAssets))

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (i in seq(from=1, to=nAssets)) {
   for (e in seq(from=1, to=nExp)) {
      final_FUND_wealth <- rep(0, nRuns)   # Vectors to store final wealth for each run
      final_TREND_wealth <- rep(0, nRuns)

      for (j in seq(from=0, to=nRuns-1)) {
         final_FUND_wealth[j+1] = tsFUNDwealth[nTicks, 1+i+j*nAssets+(e-1)*nAssets*nRuns]
         final_TREND_wealth[j+1] = tsTRENDwealth[nTicks, 1+i+j*nAssets+(e-1)*nAssets*nRuns]
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
   }
   
   y_max = max(max(Sharpe_FUND[,i]), max(Sharpe_TREND[,i]))
   y_min = min(min(Sharpe_FUND[,i]), min(Sharpe_TREND[,i]))

   plot(Sharpe_FUND[,i], type="l", main=paste("Asset", i), xlab="Experiment", ylab="mean(wealth)/sd(wealth)", ylim=c(y_min,y_max), lwd=2, col="darkorange1")
   lines(Sharpe_TREND[,i], type="l", col="seagreen", lwd=2)
}
title(paste("'Sharpe ratio': Mean of final wealth increment of FUNDs vs TRENDs, \n divided by std dev of final wealth (over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study which group of agents performs better, taking into account the volatility of their results (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


## Version for the JEDC article
#
#i=1
#y_max = max(max(Sharpe_FUND[,i]), max(Sharpe_TREND[,i]))
#y_min = min(min(Sharpe_FUND[,i]), min(Sharpe_TREND[,i]))
##x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
#
##dev.new()
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))
#plot(Sharpe_FUND[,i], type="l", main="Strength index", xlab="VaR limit", ylab="", ylim=c(y_min,y_max), lwd=2, col="darkorange1", xaxt='n')
#lines(Sharpe_TREND[,i], type="l", col="seagreen", lwd=2)
#axis(1, at=1:nExp, labels=x_axis)
#legend("bottomright", c("FUND","TREND"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen"))


#### Bar charts of FUND/TREND final wealth for EACH individual run
##
## Objective: Compare the relative wealth accumulated by each group of traders
## at the end of the simulation
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows, numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#            wealth <- c(tsFUNDwealth[[k+1+i +(e-1)*nAssets*nRuns]][nTicks], tsTRENDwealth[[k+1+i +(e-1)*nAssets*nRuns]][nTicks])
#            labels <- c("FUND", "TREND") 
#            barplot(wealth, names = labels, col=c("darkorange1", "seagreen"), main=paste("Run", 1+i/nAssets))
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            wealth <- c(tsFUNDwealth[[k+i +(e-1)*nAssets*nRuns]][nTicks], tsTRENDwealth[[k+i +(e-1)*nAssets*nRuns]][nTicks])
#            labels <- c("FUND", "TREND") 
#            barplot(wealth, names = labels, col=c("darkorange1", "seagreen"), main=paste("Run", 1+(i-1)/nAssets))
#         }
#      }
#      title(paste("Final wealth along simulations - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Compare the final wealth accumulated by each strategy.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}


### Bar charts of FUND/TREND final wealth (averaged over runs)
#
# Objective: Compare the relative wealth accumulated by each group of traders
# at the end of the simulations, averaged over runs

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      wealth <- c(tsFUNDwealth_avg[nTicks,(e-1)*nAssets+k], tsTRENDwealth_avg[nTicks,(e-1)*nAssets+k])
      labels <- c("FUND", "TREND")
      barplot(wealth, names = labels, col=c("darkorange1", "seagreen"), main=paste("Exp", e))
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

   wealth_F_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , wealth increment of FUNDs)
   wealth_T_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , wealth increment of TRENDs)
      
   for (e in seq(from=0, to=nExp-1)) {
      for (i in seq(from=0, to=nRuns-1)) {
	   volume_F_matrix[i+1+e*nRuns,1] = e+1
	   volume_F_matrix[i+1+e*nRuns,2] = mean(tsFUNDvolume[[k+1+i*nAssets+e*nAssets*nRuns]])

	   volume_T_matrix[i+1+e*nRuns,1] = e+1
	   volume_T_matrix[i+1+e*nRuns,2] = mean(tsTRENDvolume[[k+1+i*nAssets+e*nAssets*nRuns]])

	   wealth_F_matrix[i+1+e*nRuns,1] = e+1
         wealth_F_matrix[i+1+e*nRuns,2] = mean(tsFUNDwealth[[k+1+i*nAssets+e*nAssets*nRuns]])

	   wealth_T_matrix[i+1+e*nRuns,1] = e+1
	   wealth_T_matrix[i+1+e*nRuns,2] = mean(tsTRENDwealth[[k+1+i*nAssets+e*nAssets*nRuns]])
      }
   }

   # Place the plots in a 2x2 matrix

   par(mfrow=c(2,2), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

   plot(volume_F_matrix[,1], volume_F_matrix[,2], main="Volume FUNDs", xlab="Experiment", ylab="Volume FUNDs", pch=21, col="darkorange1")
   abline(lin_reg <- lm(volume_F_matrix[,2]~volume_F_matrix[,1]), col="red")   # regression line (volume_F ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   plot(volume_T_matrix[,1], volume_T_matrix[,2], main="Volume TRENDs", xlab="Experiment", ylab="Volume TRENDs", pch=21, col="seagreen")
   abline(lin_reg <- lm(volume_T_matrix[,2]~volume_T_matrix[,1]), col="red")   # regression line (volume_T ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   plot(wealth_F_matrix[,1], wealth_F_matrix[,2], main="Wealth increment FUNDs", xlab="Experiment", ylab="Wealth FUNDs", pch=21, col="darkorange1")
   abline(lin_reg <- lm(wealth_F_matrix[,2]~wealth_F_matrix[,1]), col="red")   # regression line (wealth_F ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   plot(wealth_T_matrix[,1], wealth_T_matrix[,2], main="Wealth increment TRENDs", xlab="Experiment", ylab="Wealth TRENDs", pch=21, col="seagreen")
   abline(lin_reg <- lm(wealth_T_matrix[,2]~wealth_T_matrix[,1]), col="red")   # regression line (wealth_T ~ experiment)
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
## We plot here the total volume of FUNDs and TRENDs, together
## with their sell-off volume, to get an idea of the size (and 
## potential impact) of the portfolio reductions in comparison to the
## total trading volume
#
#### Plot of time series of volume + sell-off volume (averaged over runs)
#
#y_max_V = max(max(tsFUNDvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvolume_avg[,1:(nAssets*nExp)]))
#y_min_V = min(min(tsFUNDvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvolume_avg[,1:(nAssets*nExp)]))
#
#y_max_SO = max(max(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))
#y_min_SO = min(min(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))
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
#	lines(tsFUNDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="coral4")
#
#	# Show average of volume and sell-off volume
#	mtext(paste("avg_vol =", round(mean(tsFUNDvolume_avg[,(e-1)*nAssets+k]),1), " / avg_varselloff_vol =", round(mean(tsFUNDvarselloffvolume_avg[,(e-1)*nAssets+k]),1)) , side=3, line=0.1, cex=0.6, col="red")
#   }
#   title(paste("Total volume + sell-off volume of FUNDs (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
#   mtext("Objective: Get an idea of the size of sell-off volume w.r.t. total volume (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
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
#	lines(tsTRENDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen2")
#
#	# Show average of volume and sell-off volume
#	mtext(paste("avg_vol =", round(mean(tsTRENDvolume_avg[,(e-1)*nAssets+k]),1), " / avg_varselloff_vol =", round(mean(tsTRENDvarselloffvolume_avg[,(e-1)*nAssets+k]),1)) , side=3, line=0.1, cex=0.6, col="red")
#   }
#   title(paste("Total volume + sell-off volume of TRENDs (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Get an idea of the size of sell-off volume w.r.t. total volume (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#


##____________________________________________________________#
##                                                            #
##              PERFORMANCE vs REDUCTION VOLUME               #
##____________________________________________________________#
##                                                            #
#
## We plot here the reduced volume of FUNDs and TRENDs, together
## with their average increment in wealth, to see if VaR limits have any
## effect on the performance of agents
#
#### Plot of time series of wealth increment + reduction volume (averaged over runs)
#
#y_max_W = max(max(tsFUNDwealth_avg[,1:(nAssets*nExp)]), max(tsTRENDwealth_avg[,1:(nAssets*nExp)]))
#y_min_W = min(min(tsFUNDwealth_avg[,1:(nAssets*nExp)]), min(tsTRENDwealth_avg[,1:(nAssets*nExp)]))
#
#y_max_RV = max(max(tsFUNDvarreducedvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvarreducedvolume_avg[,1:(nAssets*nExp)]))
#y_min_RV = min(min(tsFUNDvarreducedvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvarreducedvolume_avg[,1:(nAssets*nExp)]))
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
#	plot(x=x_axis, y=tsFUNDvarreducedvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
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
#   mtext("Objective: Study the effect of VaR limits on wealth increment (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
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
#	plot(x=x_axis, y=tsTRENDvarreducedvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
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
#   mtext("Objective: Study the effect of VaR limits on wealth increment (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
##### Plot of time series of wealth increment + reduction volume (for individual runs)
##
##y_max_W = max(max(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)]))
##y_min_W = min(min(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)]))
##
##y_max_RV = max(max(tsFUNDvarreducedvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDvarreducedvolume[,2:(nAssets*nRuns*nExp+1)]))
##y_min_RV = min(min(tsFUNDvarreducedvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDvarreducedvolume[,2:(nAssets*nRuns*nExp+1)]))
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
##		plot(x=x_axis, y=tsFUNDvarreducedvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
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
##		plot(x=x_axis, y=tsFUNDvarreducedvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
##			ylab="Wealth vs Red. volume", col="coral4", xaxt='n', axes=F)
##		axis(4, pretty(c(y_min_RV, y_max_RV)), col="coral4")
##
##		# Add x axis
##		axis(1, pretty(range(x_axis)))
##         }
##      }
##      title(paste("Increment in wealth + reduction volume of FUNDs - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
##      mtext("Objective:Study the effect of VaR limits on wealth increment. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
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
##		plot(x=x_axis, y=tsTRENDvarreducedvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
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
##		plot(x=x_axis, y=tsTRENDvarreducedvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_RV,y_max_RV), xlab="", 
##			ylab="Wealth vs Red. volume", col="seagreen2", xaxt='n', axes=F)
##		axis(4, pretty(c(y_min_RV, y_max_RV)), col="seagreen2")
##
##		# Add x axis
##		axis(1, pretty(range(x_axis)))
##         }
##      }
##      title(paste("Increment in wealth + reduction volume of TRENDs - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
##      mtext("Objective:Study the effect of VaR limits on wealth increment. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
##      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
##   }
##}



##_________________________________________________________#
##                                                         #
##           REDUCTION ORDERS OF FUNDs vs TRENDs           #
##_________________________________________________________#
##                                                         #
#
#### Reduction orders of FUNDs and TRENDs (averaged over runs)
##
## Objective: Study if the reduction orders of one group induces reductions
## in the portfolio of the other agent groups
#
#y_max = max(max(tsFUNDvarreducedorders_avg[,1:(nAssets*nExp)]), max(tsTRENDvarreducedorders_avg[,1:(nAssets*nExp)]))
#y_min = min(min(tsFUNDvarreducedorders_avg[,1:(nAssets*nExp)]), min(tsTRENDvarreducedorders_avg[,1:(nAssets*nExp)]))
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   for (e in seq(from=1, to=nExp)) {      
#      plot(tsFUNDvarreducedorders_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Red. orders", col="darkorange1")
#      lines(tsTRENDvarreducedorders_avg[,(e-1)*nAssets+k], type="l", col="seagreen")
#   }
#   title(paste("Reduction orders of FUNDs/TRENDs (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study if the reduction orders sent by one group induces reductions by other groups (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Plot of reduction orders of FUNDs and TRENDs (for individual runs)
#
#y_max = max(max(tsFUNDvarreducedorders[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDvarreducedorders[,2:(nAssets*nRuns*nExp+1)]))
#y_min = min(min(tsFUNDvarreducedorders[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDvarreducedorders[,2:(nAssets*nRuns*nExp+1)]))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#            plot(tsFUNDvarreducedorders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Red. orders", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDvarreducedorders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(tsFUNDvarreducedorders[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Red. orders", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDvarreducedorders[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
#         }
#      }
#      title(paste("Reduction orders of FUNDs/TRENDs - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Study if the reduction orders sent by one group induces reductions by other groups (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}
#
#
#
##_________________________________________________________#
##                                                         #
##           REDUCTION VOLUME OF FUNDs vs TRENDs           #
##_________________________________________________________#
##                                                         #
#
#### Reduction volume of FUNDs and TRENDs (averaged over runs)
##
## Objective: Study if the reduction orders of one group induces reductions
## in the portfolio of the other agent groups
#
#y_max = max(max(tsFUNDvarreducedvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvarreducedvolume_avg[,1:(nAssets*nExp)]))
#y_min = min(min(tsFUNDvarreducedvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvarreducedvolume_avg[,1:(nAssets*nExp)]))
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   for (e in seq(from=1, to=nExp)) {      
#      plot(tsFUNDvarreducedvolume_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Red. volume", col="darkorange1")
#      lines(tsTRENDvarreducedvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")
#   }
#   title(paste("Reduction volume of FUNDs/TRENDs (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study if the reduction orders sent by one group induces reductions by other groups (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Plot of reduction volume of FUNDs and TRENDs (for individual runs)
#
#y_max = max(max(tsFUNDvarreducedvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDvarreducedvolume[,2:(nAssets*nRuns*nExp+1)]))
#y_min = min(min(tsFUNDvarreducedvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDvarreducedvolume[,2:(nAssets*nRuns*nExp+1)]))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
#            plot(tsFUNDvarreducedvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Red. volume", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDvarreducedvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(tsFUNDvarreducedvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Red. volume", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDvarreducedvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
#         }
#      }
#      title(paste("Reduction volume of FUNDs/TRENDs - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Study if the reduction orders sent by one group induces reductions by other groups (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}
#



#_________________________________________________________#
#                                                         #
#            SELL-OFF ORDERS OF FUNDs vs TRENDs           #
#_________________________________________________________#
#                                                         #

#### Sell-off orders of FUNDs and TRENDs (averaged over runs)
##
## Objective: Study if the sell-off orders of one group induces sell-off
## orders from the other agent groups
#
#y_max = max(max(tsFUNDvarsellofforders_avg[,1:(nAssets*nExp)]), max(tsTRENDvarsellofforders_avg[,1:(nAssets*nExp)]))
#y_min = min(min(tsFUNDvarsellofforders_avg[,1:(nAssets*nExp)]), min(tsTRENDvarsellofforders_avg[,1:(nAssets*nExp)]))
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   for (e in seq(from=1, to=nExp)) {      
#      plot(tsFUNDvarsellofforders_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Sell-off orders", col="darkorange1")
#      lines(tsTRENDvarsellofforders_avg[,(e-1)*nAssets+k], type="l", col="seagreen")
#   }
#   title(paste("Sell-off orders of FUNDs/TRENDs (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study if the sell-off orders sent by one group induces sell-offs by other groups (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Plot of sell-off orders of FUNDs and TRENDs (for individual runs)
#
#y_max = max(max(tsFUNDvarsellofforders[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDvarsellofforders[,2:(nAssets*nRuns*nExp+1)]))
#y_min = min(min(tsFUNDvarsellofforders[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDvarsellofforders[,2:(nAssets*nRuns*nExp+1)]))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#            plot(tsFUNDvarsellofforders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Sell-off orders", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDvarsellofforders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(tsFUNDvarsellofforders[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Sell-off orders", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDvarsellofforders[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
#         }
#      }
#      title(paste("Sell-off orders of FUNDs/TRENDs - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Study if the sell-off orders sent by one group induces sell-offs by other groups (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}


#_________________________________________________________#
#                                                         #
#            SELL-OFF VOLUME OF FUNDs vs TRENDs           #
#_________________________________________________________#
#                                                         #

#### Sell-off volume of FUNDs and TRENDs (averaged over runs)
##
## Objective: Study if the sell-off orders of one group induces sell-offs
## by the other agent groups
#
#y_max = max(max(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))
#y_min = min(min(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   for (e in seq(from=1, to=nExp)) {      
#      plot(tsFUNDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Sell-off volume", col="darkorange1")
#      lines(tsTRENDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")
#   }
#   title(paste("Sell-off volume of FUNDs/TRENDs (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study if the sell-off orders sent by one group induces sell-offs by other groups (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Plot of sell-off volume of FUNDs and TRENDs (for individual runs)
#
#y_max = max(max(tsFUNDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
#y_min = min(min(tsFUNDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
#            plot(tsFUNDvarselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Sell-off volume", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDvarselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(tsFUNDvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Sell-off volume", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max), col="darkorange1")
#            lines(tsTRENDvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
#         }
#      }
#      title(paste("Sell-off volume of FUNDs/TRENDs - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Study if the sell-off orders sent by one group induces sell-offs by other groups (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}
#


#____________________________________________________________________#
#                                                                    #
#                     PRICES vs SELL-OFF VOLUME                      #
#____________________________________________________________________#
#                                                                    #

# ----------------- VaR ----------------- #

# We plot here the VaR sell-off volume of FUNDs and TRENDs, together
# with the series of prices, to see the effect of VaR limits on price movements

### Plot of time series of price + VaR sell-off volume (averaged over runs)

y_max_P =  max(tsprices_avg[,1:(nAssets*nExp)])
y_min_P =  min(tsprices_avg[,1:(nAssets*nExp)])

y_max_SO = max(max(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))
y_min_SO = min(min(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))

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
	plot(x=x_axis, y=tsFUNDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
	lines(tsTRENDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")  
	axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

	# Add x axis
	axis(1, pretty(range(x_axis)))
   }
   title(paste("Price + VaR sell-off volume of FUND/TREND (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Study the effect of VaR limits on price (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ----------------- ES ----------------- #

# We plot here the ES sell-off volume of FUNDs and TRENDs, together
# with the series of prices, to see the effect of ES limits on price movements

### Plot of time series of price + ES sell-off volume (averaged over runs)

y_max_P =  max(tsprices_avg[,1:(nAssets*nExp)])
y_min_P =  min(tsprices_avg[,1:(nAssets*nExp)])

y_max_SO = max(max(tsFUNDesselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDesselloffvolume_avg[,1:(nAssets*nExp)]))
y_min_SO = min(min(tsFUNDesselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDesselloffvolume_avg[,1:(nAssets*nExp)]))

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
	plot(x=x_axis, y=tsFUNDesselloffvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
	lines(tsTRENDesselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")  
	axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

	# Add x axis
	axis(1, pretty(range(x_axis)))
   }
   title(paste("Price + ES sell-off volume of FUND/TREND (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Study the effect of ES limits on price (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
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

# We plot here the sell-off volume of FUNDs and TRENDs, together
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

y_max_SO = max(max(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))
y_min_SO = min(min(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))

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
	plot(x=x_axis, y=tsFUNDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
      lines(tsTRENDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")  
	axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

	# Add x axis
	axis(1, pretty(range(x_axis)))

	# Show average of volatility time series
	mtext(paste("avg_volat =", round(mean(tsvolatility_avg[,(e-1)*nAssets+k]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
   }
   title(paste("Price volatility + sell-off volume of FUND/TREND (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Study the effect of VaR limits on price volatility (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Plot of time series of price volatility + sell-off volume (for individual runs)

y_max_V = max(tsvolatility[,1:(nAssets*nRuns*nExp)])
y_min_V = min(tsvolatility[,1:(nAssets*nRuns*nExp)])

y_max_SO = max(max(tsFUNDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
y_min_SO = min(min(tsFUNDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]))

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
		plot(x=x_axis, y=tsFUNDvarselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDvarselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
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
		plot(x=x_axis, y=tsFUNDvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

		# Add x axis
		axis(1, pretty(range(x_axis)))

		# Show average of volatility time series
		mtext(paste("avg_volat =", round(mean(tsvolatility[,i+k +(e-1)*nAssets*nRuns-1]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
         }
      }
      title(paste("Price volatility + sell-off volume of FUND/TREND - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Objective:Study the effect of VaR limits on price volatility. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


### Cross-correlation function of price volatility and sell-off volume (averaged over runs)
#
# Objective: Plot a cross-correlation function of price volatility and sell-off volume
# averaged over runs to study the correlation for different lags, in order to see
# if sell-off volume causes volatility, or vice-versa

tstotalvarselloffvolume_avg <- tsFUNDvarselloffvolume_avg + tsTRENDvarselloffvolume_avg

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))

   for (e in seq(from=1, to=nExp)) {
	ccf(tsvolatility_avg[,(e-1)*nAssets+k], tstotalvarselloffvolume_avg[,(e-1)*nAssets+k], ylab = "Cross-correlation", main=paste("Exp", e), ylim=c(-1,1), lag.max = 50)
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

tstotalvarselloffvolume <- tsFUNDvarselloffvolume + tsTRENDvarselloffvolume
tstotalvarselloffvolume[[1]] <- tsFUNDvarselloffvolume[[1]]    # 'tick' column

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
       par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             ccf(tsvolatility[,i+1+k+(e-1)*nAssets*nRuns-1], tstotalvarselloffvolume[[i+1+k+(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1), lag.max = 50)
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            ccf(tsvolatility[,i+k +(e-1)*nAssets*nRuns-1], tstotalvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1), lag.max = 50)
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


#### Boxplot of mean of time series of price volatility (along experiments) [Thesis Ch4]
#
#x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
##x_axis <- c("5", "", "", "20", "", "", "35", "", "", "50", "", "", "65", "", "", "80")
#
#mean_mean_tsvolatility_th <- array(0, dim=c(nAssets, nExp))
#
#for (k in seq(from=1, to=nAssets)) {   # Calculate means to add them to the boxplots
#   for (e in seq(from=0, to=nExp-1)) {
#	mean_mean_tsvolatility_th[k, e+1] = mean(mean_tsvolatility_th[,k+e*nAssets])
#   }
#}
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))
#for (i in seq(from=1, to=nAssets)) {
#   #dev.new()         # Plots each figure in a new window
#   boxplot(mean_tsvolatility_th[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="", xlab="Porcentaje de agentes con l�mite antic�clico", xaxt='n')   
#   points(mean_mean_tsvolatility_th[i,],col="red",pch=18)
#   lines(mean_mean_tsvolatility_th[i,], col="red", lwd=2)
#   axis(1, at=1:nExp, labels=x_axis)
#}



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

# We plot here the sell-off volume of FUNDs and TRENDs, together
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

y_max_SO = max(max(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))
y_min_SO = min(min(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))

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
	plot(x=x_axis, y=tsFUNDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
	lines(tsTRENDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")  
	axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

	# Add x axis
	axis(1, pretty(range(x_axis)))

	# Show average of volatility time series
	mtext(paste("avg_volat =", 100*round(mean(tsvolatility_avg[,(e-1)*nAssets+k]),4), "%"), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
   }
   title(paste("Return volatility + sell-off volume of FUND/TREND (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Study the effect of VaR limits on return volatility (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Plot of time series of returns volatility + sell-off volume (for individual runs)

y_max_V = max(tsvolatility[,1:(nAssets*nRuns*nExp)])
y_min_V = min(tsvolatility[,1:(nAssets*nRuns*nExp)])

y_max_SO = max(max(tsFUNDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
y_min_SO = min(min(tsFUNDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]))

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
		plot(x=x_axis, y=tsFUNDvarselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDvarselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
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
		plot(x=x_axis, y=tsFUNDvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

		# Add x axis
		axis(1, pretty(range(x_axis)))

		# Show average of volatility time series
		mtext(paste("avg_volat =", 100*round(mean(tsvolatility[,i+k +(e-1)*nAssets*nRuns-1]),4), "%"), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
         }
      }
      title(paste("Return volatility + sell-off volume of FUND/TREND - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Objective:Study the effect of VaR limits on return volatility. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


### Cross-correlation function of price volatility and sell-off volume (averaged over runs)
#
# Objective: Plot a cross-correlation function of price volatility and sell-off volume
# averaged over runs to study the correlation for different lags, in order to see
# if sell-off volume causes volatility, or vice-versa

tstotalvarselloffvolume_avg <- tsFUNDvarselloffvolume_avg + tsTRENDvarselloffvolume_avg

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))

   for (e in seq(from=1, to=nExp)) {
	ccf(tsvolatility_avg[,(e-1)*nAssets+k], tstotalvarselloffvolume_avg[,(e-1)*nAssets+k], ylab = "Cross-correlation", main=paste("Exp", e), ylim=c(-1,1), lag.max = 50)
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

tstotalvarselloffvolume <- tsFUNDvarselloffvolume + tsTRENDvarselloffvolume
tstotalvarselloffvolume[[1]] <- tsFUNDvarselloffvolume[[1]]    # 'tick' column

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
       par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             ccf(tsvolatility[,i+1+k+(e-1)*nAssets*nRuns-1], tstotalvarselloffvolume[[i+1+k+(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1), lag.max = 50)
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            ccf(tsvolatility[,i+k +(e-1)*nAssets*nRuns-1], tstotalvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1), lag.max = 50)
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


#### Boxplot of mean of time series of return volatility (along experiments) [Thesis Ch4]
#
##x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
#
#y_min_V = 0.0
#y_max_V = 1.5
#
#mean_mean_tsvolatility_th <- array(0, dim=c(nAssets, nExp))
#
#for (k in seq(from=1, to=nAssets)) {   # Calculate means to add them to the boxplots
#   for (e in seq(from=0, to=nExp-1)) {
#	mean_mean_tsvolatility_th[k, e+1] = mean(mean_tsvolatility_th[,k+e*nAssets])
#   }
#}
#
#mean_tsvolatility_th_annualised <- mean_tsvolatility_th*sqrt(252)  # annualise volatility
#mean_mean_tsvolatility_th_annualised <- mean_mean_tsvolatility_th*sqrt(252)
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))
#for (i in seq(from=1, to=nAssets)) {
#   #dev.new()         # Plots each figure in a new window
#   #boxplot(mean_tsvolatility_th_annualised[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="", xlab="Porcentaje de agentes con l�mite antic�clico", xaxt='n', yaxt='n')
#   boxplot(mean_tsvolatility_th_annualised[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="Return volatility", xlab="VaR limit", xaxt='n', yaxt='n')
#   points(mean_mean_tsvolatility_th_annualised[i,],col="red",pch=18)
#   lines(mean_mean_tsvolatility_th_annualised[i,], col="red", lwd=2)
#   axis(1, at=1:nExp, labels=x_axis)
#   axis(2, at=seq(y_min_V,y_max_V,by=.1), labels=paste(100*seq(y_min_V,y_max_V,by=.1), "%") )  # adjust y axis to show percentages
#}



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
## We plot here the sell-off volume of FUNDs and TRENDs, together
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
#y_max_SO = max(max(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))
#y_min_SO = min(min(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))
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
#	plot(x=x_axis, y=tsFUNDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
#		ylab="", col="darkorange1", xaxt='n', axes=F)
#	lines(tsTRENDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")  
#	axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")
#
#	# Add x axis
#	axis(1, pretty(range(x_axis)))
#
#	# Show average of skewness time series
#	mtext(paste("avg_skew =", round(mean(tsskewness_avg[,(e-1)*nAssets+k]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#   }
#   title(paste("Return skewness + sell-off volume of FUND/TREND (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Description: A negative skewness indicates that negative returns occur more often. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Plot of time series of returns skewness + sell-off volume (for individual runs)
#
#y_max_Sk = max(tsskewness[,1:(nAssets*nRuns*nExp)])
#y_min_Sk = min(tsskewness[,1:(nAssets*nRuns*nExp)])
#
#y_max_SO = max(max(tsFUNDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
#y_min_SO = min(min(tsFUNDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
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
#		plot(x=x_axis, y=tsFUNDvarselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
#			ylab="", col="darkorange1", xaxt='n', axes=F)
#		lines(tsTRENDvarselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
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
#		plot(x=x_axis, y=tsFUNDvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
#			ylab="", col="darkorange1", xaxt='n', axes=F)
#		lines(tsTRENDvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
#		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")
#
#		# Add x axis
#		axis(1, pretty(range(x_axis)))
#
#		# Show average of skewness time series
#		mtext(paste("avg_skew =", round(mean(tsskewness[,i+k +(e-1)*nAssets*nRuns-1]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
#         }
#      }
#      title(paste("Return skewness + sell-off volume of FUND/TREND - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Description: A negative skewness indicates that negative returns occur more often. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
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

# We plot here the sell-off volume of FUNDs and TRENDs, together
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

y_max_SO = max(max(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))
y_min_SO = min(min(tsFUNDvarselloffvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvarselloffvolume_avg[,1:(nAssets*nExp)]))

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
	plot(x=x_axis, y=tsFUNDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
	lines(tsTRENDvarselloffvolume_avg[,(e-1)*nAssets+k], type="l", col="seagreen")  
	axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

	# Add x axis
	axis(1, pretty(range(x_axis)))

	# Show average of kurtosis time series
	mtext(paste("avg_kurt =", round(mean(tskurtosis_avg[,(e-1)*nAssets+k]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
   }
   title(paste("Return kurtosis + sell-off volume of FUND/TREND (avg. over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Description: A higher kurtosis indicates that extreme returns occur more often. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Plot of time series of returns kurtosis + sell-off volume (for individual runs)

y_max_kurt = max(tskurtosis[,1:(nAssets*nRuns*nExp)])
y_min_kurt = min(tskurtosis[,1:(nAssets*nRuns*nExp)])

y_max_SO = max(max(tsFUNDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]))
y_min_SO = min(min(tsFUNDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDvarselloffvolume[,2:(nAssets*nRuns*nExp+1)]))

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
		plot(x=x_axis, y=tsFUNDvarselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDvarselloffvolume[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="seagreen")
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
		plot(x=x_axis, y=tsFUNDvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
			ylab="", col="darkorange1", xaxt='n', axes=F)
		lines(tsTRENDvarselloffvolume[[i+k +(e-1)*nAssets*nRuns]], type="l", col="seagreen")  
		axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

		# Add x axis
		axis(1, pretty(range(x_axis)))

		# Show average of kurtosis time series
		mtext(paste("avg_kurt =", round(mean(tskurtosis[,i+k +(e-1)*nAssets*nRuns-1]),3)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
         }
      }
      title(paste("Return kurtosis + sell-off volume of FUND/TREND - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Description: A higher kurtosis indicates that extreme returns occur more often. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
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


#### Boxplot of mean of time series of return kurtosis (along experiments) [Thesis Ch4]
#
##x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
#mean_mean_tskurtosis_th <- array(0, dim=c(nAssets, nExp))
#
#for (k in seq(from=1, to=nAssets)) {   # Calculate means to add them to the boxplots
#   for (e in seq(from=0, to=nExp-1)) {
#	mean_mean_tskurtosis_th[k, e+1] = mean(mean_tskurtosis_th[,k+e*nAssets])
#   }
#}
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))
#for (i in seq(from=1, to=nAssets)) {
#   #dev.new()         # Plots each figure in a new window
#   #boxplot(mean_tskurtosis_th[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="", xlab="Porcentaje de agentes con l�mite antic�clico", xaxt='n')
#   boxplot(mean_tskurtosis_th[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="Return kurtosis", xlab="VaR limit", xaxt='n')
#   points(mean_mean_tskurtosis_th[i,],col="red",pch=18)
#   lines(mean_mean_tskurtosis_th[i,], col="red", lwd=2)
#   axis(1, at=1:nExp, labels=x_axis)
#}


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
                             ## In [Hill]�s first implementation, Du Mouchel (1979) showed 
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


#### Boxplot of Hill index along experiments (considering the individual runs)  [Thesis Ch4]
#
#par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))
##x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
#
#for (i in seq(from=1, to=nAssets)) {
#   hillreturns_exp <- array(0, dim=c(nRuns, nExp))    # It allocates the Hill indexes corresponding to the same experiment and asset
#   mean_hillreturns_exp <- array(0, dim=c(1, nExp))   # Mean Hill index over runs
#
#   for (e in seq(from=1, to=nExp)) {      
#      for (j in seq(from=1, to=nRuns)) {
#         hillreturns_exp[j,e] <- hillreturns[,i+(j-1)*nAssets+(e-1)*nAssets*nRuns]
#      }
#      mean_hillreturns_exp[,e] <- mean(hillreturns_exp[,e])
#   }
#   #boxplot(hillreturns_exp[,], notch=FALSE, main="", range=1.5, xlab="Porcentaje de agentes con l�mite antic�clico", xaxt='n')
#   boxplot(hillreturns_exp[,], notch=FALSE, main="Hill index", range=1.5, xlab="VaR limit", xaxt='n')
#   points(mean_hillreturns_exp[,],col="red",pch=18)
#   lines(mean_hillreturns_exp[,], col="red", lwd=2)
#   axis(1, at=1:nExp, labels=x_axis)
#}


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



#______________________________________________________________#
#                                                              #
#                        FUND/TREND VaR                        #
#______________________________________________________________#
#                                                              # 

### Plot of FUND and TREND VaR (averaged over runs)

y_max = max(max(tsFUNDvar_avg[,1:nExp]), max(tsTRENDvar_avg[,1:nExp]))
y_min = min(min(tsFUNDvar_avg[,1:nExp]), min(tsTRENDvar_avg[,1:nExp]))

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(tsTRENDvar_avg[,e], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="VaR", col="seagreen")
   lines(tsFUNDvar_avg[,e], type="l", col="darkorange1")
}
title(paste("VaR of FUNDs vs TRENDs (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Compare the VaR level of the three groups of agents (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



### Plot of FUND and TREND VaR + stressed VaR (averaged over runs)

y_max = max(max(tsFUNDvar_avg[,1:nExp]+tsFUNDstressedvar_avg[,1:nExp]), max(tsTRENDvar_avg[,1:nExp]+tsTRENDstressedvar_avg[,1:nExp]))
y_min = min(min(tsFUNDvar_avg[,1:nExp]+tsFUNDstressedvar_avg[,1:nExp]), min(tsTRENDvar_avg[,1:nExp]+tsTRENDstressedvar_avg[,1:nExp]))

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(tsTRENDvar_avg[,e]+tsTRENDstressedvar_avg[,e], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="VaR+SVaR", col="seagreen")
   lines(tsFUNDvar_avg[,e]+tsFUNDstressedvar_avg[,e], type="l", col="darkorange1")
}
title(paste("VaR + Stressed VaR of FUNDs vs TRENDs (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Compare the VaR+SVaR level of the two groups of agents (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


#### Stacked plot of VaR and stressed VaR (averaged over runs)
#
#y_max = max(max(tsFUNDvar_avg[,1:nExp]+tsFUNDstressedvar_avg[,1:nExp]), max(tsTRENDvar_avg[,1:nExp]+tsTRENDstressedvar_avg[,1:nExp]))
#y_min = min(min(tsFUNDvar_avg[,1:nExp]+tsFUNDstressedvar_avg[,1:nExp]), min(tsTRENDvar_avg[,1:nExp]+tsTRENDstressedvar_avg[,1:nExp]))
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


### Plot of FUND and TREND VaR (for individual runs)

y_max = max(max(tsFUNDvar[,2:(nRuns*nExp+1)]), max(tsTRENDvar[,2:(nRuns*nExp+1)]))
y_min = min(min(tsFUNDvar[,2:(nRuns*nExp+1)]), min(tsTRENDvar[,2:(nRuns*nExp+1)]))

step2 <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {     
         plot(tsFUNDvar[[i+2 +(e-1)*nRuns]], type="l", ylab="VaR", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDvar[[i+2 +(e-1)*nRuns]], type="l", col="seagreen")
      }
   } else {
      for (i in seq(from=1, to=nRuns, by=1)) {
         plot(tsFUNDvar[[i+2 +(e-1)*nRuns]], type="l", ylab="VaR", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDvar[[i+2 +(e-1)*nRuns]], type="l", col="seagreen")  
      }
   }
   title(paste("VaR of FUNDs vs TRENDs ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Compare the VaR level of the three groups of agents. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}

### Plot of FUND and TREND VaR + stressed VaR (for individual runs)

y_max = max(max(tsFUNDvar[,2:(nRuns*nExp+1)]+tsFUNDstressedvar[,2:(nRuns*nExp+1)]), max(tsTRENDvar[,2:(nRuns*nExp+1)]+tsTRENDstressedvar[,2:(nRuns*nExp+1)]))
y_min = min(min(tsFUNDvar[,2:(nRuns*nExp+1)]+tsFUNDstressedvar[,2:(nRuns*nExp+1)]), min(tsTRENDvar[,2:(nRuns*nExp+1)]+tsTRENDstressedvar[,2:(nRuns*nExp+1)]))

step2 <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {     
         plot(tsFUNDvar[[i+2 +(e-1)*nRuns]]+tsFUNDstressedvar[[i+1 +(e-1)*nRuns]], type="l", ylab="VaR+SVaR", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDvar[[i+2 +(e-1)*nRuns]]+tsTRENDstressedvar[[i+1 +(e-1)*nRuns]], type="l", col="seagreen")
      }
   } else {
      for (i in seq(from=1, to=nRuns, by=1)) {
         plot(tsFUNDvar[[i+2 +(e-1)*nRuns]]+tsFUNDstressedvar[[i+1 +(e-1)*nRuns]], type="l", ylab="VaR+SVaR", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDvar[[i+2 +(e-1)*nRuns]]+tsTRENDstressedvar[[i+1 +(e-1)*nRuns]], type="l", col="seagreen")  
      }
   }
   title(paste("VaR + Stressed VaR of FUNDs vs TRENDs ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Compare the VaR+SVaR level of the three groups of agents. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


#### Stacked plot of VaR and stressed VaR (for individual runs)
#
#y_max = max(max(tsFUNDvar[,2:(nRuns*nExp+1)]+tsFUNDstressedvar[,2:(nRuns*nExp+1)]), max(tsTRENDvar[,2:(nRuns*nExp+1)]+tsTRENDstressedvar[,2:(nRuns*nExp+1)]))
#y_min = min(min(tsFUNDvar[,2:(nRuns*nExp+1)]+tsFUNDstressedvar[,2:(nRuns*nExp+1)]), min(tsTRENDvar[,2:(nRuns*nExp+1)]+tsTRENDstressedvar[,2:(nRuns*nExp+1)]))
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


### Line plot of mean VaR along experiments (averaged over runs)

par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

mean_tsFUNDvar_avg <- array(0, dim=c(1, nExp))
mean_tsTRENDvar_avg <- array(0, dim=c(1, nExp))

for (e in seq(from=1, to=nExp)) {
   mean_tsFUNDvar_avg[e] <- mean(tsFUNDvar_avg[,e])
   mean_tsTRENDvar_avg[e] <- mean(tsTRENDvar_avg[,e])
}

y_max = max(max(mean_tsFUNDvar_avg), max(mean_tsTRENDvar_avg))
y_min = min(min(mean_tsFUNDvar_avg), min(mean_tsTRENDvar_avg))

plot(mean_tsFUNDvar_avg[,], type="l", main="FUND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean VaR", col="darkorange1")
plot(mean_tsTRENDvar_avg[,], type="l", main="TREND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean VaR", col="seagreen")

title(paste("Mean VaR (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)
mtext("Objective: Study the evolution of VaR level along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Line plot of mean VaR + stressed VaR along experiments (averaged over runs)

par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

mean_tsFUNDtotalvar_avg <- array(0, dim=c(1, nExp))
mean_tsTRENDtotalvar_avg <- array(0, dim=c(1, nExp))

for (e in seq(from=1, to=nExp)) {
   mean_tsFUNDtotalvar_avg[e] <- mean(tsFUNDvar_avg[,e] + tsFUNDstressedvar_avg[,e])
   mean_tsTRENDtotalvar_avg[e] <- mean(tsTRENDvar_avg[,e] + tsTRENDstressedvar_avg[,e])
}

y_max = max(max(mean_tsFUNDtotalvar_avg), max(mean_tsTRENDtotalvar_avg))
y_min = min(min(mean_tsFUNDtotalvar_avg), min(mean_tsTRENDtotalvar_avg))

plot(mean_tsFUNDtotalvar_avg[,], type="l", main="FUND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean VaR+SVaR", col="darkorange1")
plot(mean_tsTRENDtotalvar_avg[,], type="l", main="TREND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean VaR+SVaR", col="seagreen")

title(paste("Mean VaR + Stressed VaR (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study the evolution of VaR+SVaR level along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of time series of VaR averaged over runs (along experiments)
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

boxplot(tsFUNDvar_avg[,], notch=TRUE, col="darkorange1", main="FUND", xlab="")
boxplot(tsTRENDvar_avg[,], notch=TRUE, col="seagreen", main="TREND", xlab="")

title("Range of variation of mean VaR", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of agents' mean VaR.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of average VaR + stressed VaR along experiments
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

boxplot(tsFUNDvar_avg[,] + tsFUNDstressedvar_avg[,], notch=TRUE, col="darkorange1", main="FUND", xlab="")
boxplot(tsTRENDvar_avg[,] + tsTRENDstressedvar_avg[,], notch=TRUE, col="seagreen", main="TREND", xlab="")

title("Range of variation of mean VaR + SVaR", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of agents' mean VaR+SVaR.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter 


#### Boxplot of VaR along experiments (considering the individual runs)
## Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots
#
#par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#tsFUNDvar_exp <- array(0, dim=c(nTicks*nRuns, nExp))    # These allocate the agents' var time series corresponding to the same experiment
#tsTRENDvar_exp <- array(0, dim=c(nTicks*nRuns, nExp))
#
#for (e in seq(from=1, to=nExp)) {      
#   for (j in seq(from=1, to=nRuns)) {
#      tsFUNDvar_exp[((j-1)*nTicks+1):(j*nTicks),e] <- tsFUNDvar[,1+j+(e-1)*nRuns]
#      tsTRENDvar_exp[((j-1)*nTicks+1):(j*nTicks),e] <- tsTRENDvar[,1+j+(e-1)*nRuns]
#   }
#}
#boxplot(tsFUNDvar_exp[,], notch=TRUE, col="darkorange1", main="FUND", xlab="")
#boxplot(tsTRENDvar_exp[,], notch=TRUE, col="seagreen", main="TREND", xlab="")
#
#title("Range of variation of VaR", outer = TRUE, col.main="blue", font.main=2)
#mtext("Test description: Overview of the distribution of agents' VaR.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



#### Boxplot of mean of VaR time series (along experiments) [Thesis Ch4]
#
#x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
##x_axis <- c("5", "", "", "20", "", "", "35", "", "", "50", "", "", "65", "", "", "80")
#
#mean_tsFUNDvar <- array(0, dim=c(nRuns, nExp))
#mean_tsTRENDvar <- array(0, dim=c(nRuns, nExp))
#
#mean_mean_tsFUNDvar <- array(0, dim=c(1, nExp))
#mean_mean_tsTRENDvar <- array(0, dim=c(1, nExp))
#
#for (e in seq(from=1, to=nExp)) {
#   for (j in seq(from=1, to=nRuns)) {
#	mean_tsFUNDvar[j,e] = mean(tsFUNDvar[,1+j+(e-1)*nRuns])
#	mean_tsTRENDvar[j,e] = mean(tsTRENDvar[,1+j+(e-1)*nRuns])
#   }
#   mean_mean_tsFUNDvar[,e] = mean(mean_tsFUNDvar[,e])
#   mean_mean_tsTRENDvar[,e] = mean(mean_tsTRENDvar[,e])
#}
#
#par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#boxplot(mean_tsFUNDvar[,seq(1,nExp)], notch=FALSE, range=1.5, main="Fundamentalistas", cex.main=1.5, col="darkorange1", xlab="Porcentaje de agentes con l�mite antic�clico", xaxt='n')
#points(mean_mean_tsFUNDvar[,],col="red",pch=18)
#lines(mean_mean_tsFUNDvar[,], col="red", lwd=2)
#axis(1, at=1:nExp, labels=x_axis)
#
#boxplot(mean_tsTRENDvar[,seq(1,nExp)], notch=FALSE, range=1.5, main="T�cnicos", cex.main=1.5, col="seagreen", xlab="Porcentaje de agentes con l�mite antic�clico", xaxt='n')
#points(mean_mean_tsTRENDvar[,],col="red",pch=18)
#lines(mean_mean_tsTRENDvar[,], col="red", lwd=2)
#axis(1, at=1:nExp, labels=x_axis)



### Scatterplot of VaR along experiments

par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

FUNDvar_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , Var)
TRENDvar_matrix <- array(0, dim=c(nRuns*nExp, 2))
      
for (e in seq(from=1, to=nExp)) {      
   for (j in seq(from=1, to=nRuns)) {
      FUNDvar_matrix[j+(e-1)*nRuns,1] = e
	TRENDvar_matrix[j+(e-1)*nRuns,1] = e
	   
	FUNDvar_matrix[j+(e-1)*nRuns,2] = mean(tsFUNDvar[,1+j+(e-1)*nRuns])
	TRENDvar_matrix[j+(e-1)*nRuns,2] = mean(tsTRENDvar[,1+j+(e-1)*nRuns])
   }
}
plot(FUNDvar_matrix[,1], FUNDvar_matrix[,2], main="FUND", xlab="Experiment", ylab="VaR", pch=21)
abline(lin_reg <- lm(FUNDvar_matrix[,2]~FUNDvar_matrix[,1]), col="red")   # regression line (var ~ experiment)
mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

plot(TRENDvar_matrix[,1], TRENDvar_matrix[,2], main="TREND", xlab="Experiment", ylab="VaR", pch=21)
abline(lin_reg <- lm(TRENDvar_matrix[,2]~TRENDvar_matrix[,1]), col="red")   # regression line (var ~ experiment)
mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

title(paste("Impact of changing parameter on agents' VaR."), outer = TRUE, col.main="blue", font.main=2)
mtext(paste("Objective: Study if agents' VaR is affected by the changing parameter"), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



#______________________________________________________________#
#                                                              #
#                        FUND/TREND ES                         #
#______________________________________________________________#
#                                                              # 

### Plot of FUND and TREND ES (averaged over runs)

y_max = max(max(tsFUNDes_avg[,1:nExp]), max(tsTRENDes_avg[,1:nExp]))
y_min = min(min(tsFUNDes_avg[,1:nExp]), min(tsTRENDes_avg[,1:nExp]))

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(tsTRENDes_avg[,e], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="ES", col="seagreen")
   lines(tsFUNDes_avg[,e], type="l", col="darkorange1")
}
title(paste("ES of FUNDs vs TRENDs (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Compare the ES level of the two groups of agents (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



### Plot of FUND and TREND ES + stressed ES (averaged over runs)

y_max = max(max(tsFUNDes_avg[,1:nExp]+tsFUNDstressedes_avg[,1:nExp]), max(tsTRENDes_avg[,1:nExp]+tsTRENDstressedes_avg[,1:nExp]))
y_min = min(min(tsFUNDes_avg[,1:nExp]+tsFUNDstressedes_avg[,1:nExp]), min(tsTRENDes_avg[,1:nExp]+tsTRENDstressedes_avg[,1:nExp]))

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(tsTRENDes_avg[,e]+tsTRENDstressedes_avg[,e], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="ES+SES", col="seagreen")
   lines(tsFUNDes_avg[,e]+tsFUNDstressedes_avg[,e], type="l", col="darkorange1")
}
title(paste("ES + Stressed ES of FUNDs vs TRENDs (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Compare the ES+SES level of the two groups of agents (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


#### Stacked plot of ES and stressed ES (averaged over runs)
#
#y_max = max(max(tsFUNDes_avg[,1:nExp]+tsFUNDstressedes_avg[,1:nExp]), max(tsTRENDes_avg[,1:nExp]+tsTRENDstressedes_avg[,1:nExp]))
#y_min = min(min(tsFUNDes_avg[,1:nExp]+tsFUNDstressedes_avg[,1:nExp]), min(tsTRENDes_avg[,1:nExp]+tsTRENDstressedes_avg[,1:nExp]))
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
#   df = data.frame(seq(1:nTicks), tsFUNDstressedes_avg[,e], tsFUNDes_avg[,e])
#   colnames(df) <- c("tick", "SES", "ES")
#
#   df <- reshape(df, varying = c("SES", "ES"), v.names = "value", timevar = "group", 
# 		     times = c("SES", "ES"), direction = "long")
#
#   df$group <- factor(df$group, levels = c("ES", "SES"))   # Change the order of stacks (ES below, SES on top)
#            
#   # Plot ES & SES in stacked area plot
#   graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("darkorange1", "coral4"), name = paste("E", e), 
#            	breaks = c("SES", "ES"), labels = c("SES", "ES")) + ylim(y_min, y_max)
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
#   df = data.frame(seq(1:nTicks), tsTRENDstressedes_avg[,e], tsTRENDes_avg[,e])
#   colnames(df) <- c("tick", "SES", "ES")
#
#   df <- reshape(df, varying = c("SES", "ES"), v.names = "value", timevar = "group", 
# 		     times = c("SES", "ES"), direction = "long")
#
#   df$group <- factor(df$group, levels = c("ES", "SES"))   # Change the order of stacks (ES below, SES on top)
#            
#   # Plot ES & SES in stacked area plot
#   graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("seagreen", "seagreen2"), name = paste("E", e), 
#            	breaks = c("SES", "ES"), labels = c("SES", "ES")) + ylim(y_min, y_max)
#
#   # Display graphics in a grid   #!! It does not work properly if numExp > numCols*numRows
#   col = e %% numCols   
#   col = col + numCols * (col==0)   # Columns cannot take value 0
#   row = floor((e-1)/numCols) + 1
#   print(graph,vp=vplayout(row,col))
#}
#


### Plot of FUND and TREND ES (for individual runs)

y_max = max(max(tsFUNDes[,2:(nRuns*nExp+1)]), max(tsTRENDes[,2:(nRuns*nExp+1)]))
y_min = min(min(tsFUNDes[,2:(nRuns*nExp+1)]), min(tsTRENDes[,2:(nRuns*nExp+1)]))

step2 <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {     
         plot(tsFUNDes[[i+2 +(e-1)*nRuns]], type="l", ylab="ES", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDes[[i+2 +(e-1)*nRuns]], type="l", col="seagreen")
      }
   } else {
      for (i in seq(from=1, to=nRuns, by=1)) {
         plot(tsFUNDes[[i+2 +(e-1)*nRuns]], type="l", ylab="ES", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDes[[i+2 +(e-1)*nRuns]], type="l", col="seagreen")  
      }
   }
   title(paste("ES of FUNDs vs TRENDs ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Compare the ES level of the two groups of agents. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}

### Plot of FUND and TREND ES + stressed ES (for individual runs)

y_max = max(max(tsFUNDes[,2:(nRuns*nExp+1)]+tsFUNDstressedes[,2:(nRuns*nExp+1)]), max(tsTRENDes[,2:(nRuns*nExp+1)]+tsTRENDstressedes[,2:(nRuns*nExp+1)]))
y_min = min(min(tsFUNDes[,2:(nRuns*nExp+1)]+tsFUNDstressedes[,2:(nRuns*nExp+1)]), min(tsTRENDes[,2:(nRuns*nExp+1)]+tsTRENDstressedes[,2:(nRuns*nExp+1)]))

step2 <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {     
         plot(tsFUNDes[[i+2 +(e-1)*nRuns]]+tsFUNDstressedes[[i+1 +(e-1)*nRuns]], type="l", ylab="ES+SES", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDes[[i+2 +(e-1)*nRuns]]+tsTRENDstressedes[[i+1 +(e-1)*nRuns]], type="l", col="seagreen")
      }
   } else {
      for (i in seq(from=1, to=nRuns, by=1)) {
         plot(tsFUNDes[[i+2 +(e-1)*nRuns]]+tsFUNDstressedes[[i+1 +(e-1)*nRuns]], type="l", ylab="ES+SES", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
         lines(tsTRENDes[[i+2 +(e-1)*nRuns]]+tsTRENDstressedes[[i+1 +(e-1)*nRuns]], type="l", col="seagreen")  
      }
   }
   title(paste("ES + Stressed ES of FUNDs vs TRENDs ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Compare the ES+SES level of the two groups of agents. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


#### Stacked plot of ES and stressed ES (for individual runs)
#
#y_max = max(max(tsFUNDes[,2:(nRuns*nExp+1)]+tsFUNDstressedes[,2:(nRuns*nExp+1)]), max(tsTRENDes[,2:(nRuns*nExp+1)]+tsTRENDstressedes[,2:(nRuns*nExp+1)]))
#y_min = min(min(tsFUNDes[,2:(nRuns*nExp+1)]+tsFUNDstressedes[,2:(nRuns*nExp+1)]), min(tsTRENDes[,2:(nRuns*nExp+1)]+tsTRENDstressedes[,2:(nRuns*nExp+1)]))
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
#    	    df = data.frame(seq(1:nTicks), tsFUNDstressedes[,i+2+(e-1)*nRuns], tsFUNDes[,i+2+(e-1)*nRuns])
#         colnames(df) <- c("tick", "SES", "ES")
#
#	    df <- reshape(df, varying = c("SES", "ES"), v.names = "value", timevar = "group", 
# 		     times = c("SES", "ES"), direction = "long")
#
#         df$group <- factor(df$group, levels = c("ES", "SES"))   # Change the order of stacks (ES below, SES on top)
#            
#         # Plot ES & SES in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("darkorange1", "coral4"), name = paste("R", 1+i, ", E", e), 
#           	breaks = c("SES", "ES"), labels = c("SES", "ES")) + ylim(y_min, y_max)
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
#         df = data.frame(seq(1:nTicks), tsFUNDstressedes[,i+1+(e-1)*nRuns], tsFUNDes[,i+1+(e-1)*nRuns])
#         colnames(df) <- c("tick", "SES", "ES")
#
#	    df <- reshape(df, varying = c("SES", "ES"), v.names = "value", timevar = "group", 
# 		     times = c("SES", "ES"), direction = "long")
#
#         df$group <- factor(df$group, levels = c("ES", "SES"))   # Change the order of stacks (ES below, SES on top)
#
#         # Plot ES & SES in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("darkorange1", "coral4"), name = paste("R", i, " E", e), 
#            	breaks = c("SES", "ES"), labels = c("SES", "ES")) + ylim(y_min, y_max)
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
#         df = data.frame(seq(1:nTicks), tsTRENDstressedes[,i+2+(e-1)*nRuns], tsTRENDes[,i+2+(e-1)*nRuns])
#         colnames(df) <- c("tick", "SES", "ES")
#
#	    df <- reshape(df, varying = c("SES", "ES"), v.names = "value", timevar = "group", 
# 		     times = c("SES", "ES"), direction = "long")
#
#         df$group <- factor(df$group, levels = c("ES", "SES"))   # Change the order of stacks (ES below, SES on top)
#            
#         # Plot ES & SES in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("seagreen", "seagreen2"), name = paste("R", 1+i, ", E", e), 
#            	breaks = c("SES", "ES"), labels = c("SES", "ES")) + ylim(y_min, y_max)
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
#         df = data.frame(seq(1:nTicks), tsTRENDstressedes[,i+1+(e-1)*nRuns], tsTRENDes[,i+1+(e-1)*nRuns])
#         colnames(df) <- c("tick", "SES", "ES")
#
# 	    df <- reshape(df, varying = c("SES", "ES"), v.names = "value", timevar = "group", 
# 		     times = c("SES", "ES"), direction = "long")
#
#         df$group <- factor(df$group, levels = c("ES", "SES"))   # Change the order of stacks (ES below, SES on top)
#
#         # Plot ES & SES in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "", title = "") + 
#	            scale_fill_manual(values=c("seagreen", "seagreen2"), name = paste("R", i, " E", e), 
#            	breaks = c("SES", "ES"), labels = c("SES", "ES")) + ylim(y_min, y_max)
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


### Line plot of mean ES along experiments (averaged over runs)

par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

mean_tsFUNDes_avg <- array(0, dim=c(1, nExp))
mean_tsTRENDes_avg <- array(0, dim=c(1, nExp))

for (e in seq(from=1, to=nExp)) {
   mean_tsFUNDes_avg[e] <- mean(tsFUNDes_avg[,e])
   mean_tsTRENDes_avg[e] <- mean(tsTRENDes_avg[,e])
}

y_max = max(max(mean_tsFUNDes_avg), max(mean_tsTRENDes_avg))
y_min = min(min(mean_tsFUNDes_avg), min(mean_tsTRENDes_avg))

plot(mean_tsFUNDes_avg[,], type="l", main="FUND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean ES", col="darkorange1")
plot(mean_tsTRENDes_avg[,], type="l", main="TREND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean ES", col="seagreen")

title(paste("Mean ES (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)
mtext("Objective: Study the evolution of ES level along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Line plot of mean ES + stressed ES along experiments (averaged over runs)

par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

mean_tsFUNDtotales_avg <- array(0, dim=c(1, nExp))
mean_tsTRENDtotales_avg <- array(0, dim=c(1, nExp))

for (e in seq(from=1, to=nExp)) {
   mean_tsFUNDtotales_avg[e] <- mean(tsFUNDes_avg[,e] + tsFUNDstressedes_avg[,e])
   mean_tsTRENDtotales_avg[e] <- mean(tsTRENDes_avg[,e] + tsTRENDstressedes_avg[,e])
}

y_max = max(max(mean_tsFUNDtotales_avg), max(mean_tsTRENDtotales_avg))
y_min = min(min(mean_tsFUNDtotales_avg), min(mean_tsTRENDtotales_avg))

plot(mean_tsFUNDtotales_avg[,], type="l", main="FUND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean ES+SES", col="darkorange1")
plot(mean_tsTRENDtotales_avg[,], type="l", main="TREND", ylim=c(y_min, y_max), xlab="Experiment", ylab="Mean ES+SES", col="seagreen")

title(paste("Mean ES + Stressed ES (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study the evolution of ES+SES level along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of time series of ES averaged over runs (along experiments)
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

boxplot(tsFUNDes_avg[,], notch=TRUE, col="darkorange1", main="FUND", xlab="")
boxplot(tsTRENDes_avg[,], notch=TRUE, col="seagreen", main="TREND", xlab="")

title("Range of variation of mean ES", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of agents' mean ES.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of average ES + stressed ES along experiments
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

boxplot(tsFUNDes_avg[,] + tsFUNDstressedes_avg[,], notch=TRUE, col="darkorange1", main="FUND", xlab="")
boxplot(tsTRENDes_avg[,] + tsTRENDstressedes_avg[,], notch=TRUE, col="seagreen", main="TREND", xlab="")

title("Range of variation of mean ES + SES", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of agents' mean ES+SES.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter 


#### Boxplot of ES along experiments (considering the individual runs)
## Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots
#
#par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#tsFUNDes_exp <- array(0, dim=c(nTicks*nRuns, nExp))    # These allocate the agents' ES time series corresponding to the same experiment
#tsTRENDes_exp <- array(0, dim=c(nTicks*nRuns, nExp))
#
#for (e in seq(from=1, to=nExp)) {      
#   for (j in seq(from=1, to=nRuns)) {
#      tsFUNDes_exp[((j-1)*nTicks+1):(j*nTicks),e] <- tsFUNDes[,1+j+(e-1)*nRuns]
#      tsTRENDes_exp[((j-1)*nTicks+1):(j*nTicks),e] <- tsTRENDes[,1+j+(e-1)*nRuns]
#   }
#}
#boxplot(tsFUNDes_exp[,], notch=TRUE, col="darkorange1", main="FUND", xlab="")
#boxplot(tsTRENDes_exp[,], notch=TRUE, col="seagreen", main="TREND", xlab="")
#
#title("Range of variation of ES", outer = TRUE, col.main="blue", font.main=2)
#mtext("Test description: Overview of the distribution of agents' ES.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



#### Boxplot of mean of ES time series (along experiments) [Thesis Ch4]
#
#x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
##x_axis <- c("5", "", "", "20", "", "", "35", "", "", "50", "", "", "65", "", "", "80")
#
#mean_tsFUNDes <- array(0, dim=c(nRuns, nExp))
#mean_tsTRENDes <- array(0, dim=c(nRuns, nExp))
#
#mean_mean_tsFUNDes <- array(0, dim=c(1, nExp))
#mean_mean_tsTRENDes <- array(0, dim=c(1, nExp))
#
#for (e in seq(from=1, to=nExp)) {
#   for (j in seq(from=1, to=nRuns)) {
#	mean_tsFUNDes[j,e] = mean(tsFUNDes[,1+j+(e-1)*nRuns])
#	mean_tsTRENDes[j,e] = mean(tsTRENDes[,1+j+(e-1)*nRuns])
#   }
#   mean_mean_tsFUNDes[,e] = mean(mean_tsFUNDes[,e])
#   mean_mean_tsTRENDes[,e] = mean(mean_tsTRENDes[,e])
#}
#
#par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#boxplot(mean_tsFUNDes[,seq(1,nExp)], notch=FALSE, range=1.5, main="Fundamentalistas", cex.main=1.5, col="darkorange1", xlab="Porcentaje de agentes con limite anticiclico", xaxt='n')
#points(mean_mean_tsFUNDes[,],col="red",pch=18)
#lines(mean_mean_tsFUNDes[,], col="red", lwd=2)
#axis(1, at=1:nExp, labels=x_axis)
#
#boxplot(mean_tsTRENDes[,seq(1,nExp)], notch=FALSE, range=1.5, main="Tecnicos", cex.main=1.5, col="seagreen", xlab="Porcentaje de agentes con limite anticiclico", xaxt='n')
#points(mean_mean_tsTRENDes[,],col="red",pch=18)
#lines(mean_mean_tsTRENDes[,], col="red", lwd=2)
#axis(1, at=1:nExp, labels=x_axis)



### Scatterplot of ES along experiments

par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

FUNDes_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , ES)
TRENDes_matrix <- array(0, dim=c(nRuns*nExp, 2))
      
for (e in seq(from=1, to=nExp)) {      
   for (j in seq(from=1, to=nRuns)) {
      FUNDes_matrix[j+(e-1)*nRuns,1] = e
	TRENDes_matrix[j+(e-1)*nRuns,1] = e
	   
	FUNDes_matrix[j+(e-1)*nRuns,2] = mean(tsFUNDes[,1+j+(e-1)*nRuns])
	TRENDes_matrix[j+(e-1)*nRuns,2] = mean(tsTRENDes[,1+j+(e-1)*nRuns])
   }
}
plot(FUNDes_matrix[,1], FUNDes_matrix[,2], main="FUND", xlab="Experiment", ylab="ES", pch=21)
abline(lin_reg <- lm(FUNDes_matrix[,2]~FUNDes_matrix[,1]), col="red")   # regression line (es ~ experiment)
mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

plot(TRENDes_matrix[,1], TRENDes_matrix[,2], main="TREND", xlab="Experiment", ylab="ES", pch=21)
abline(lin_reg <- lm(TRENDes_matrix[,2]~TRENDes_matrix[,1]), col="red")   # regression line (es ~ experiment)
mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

title(paste("Impact of changing parameter on agents' ES."), outer = TRUE, col.main="blue", font.main=2)
mtext(paste("Objective: Study if agents' ES is affected by the changing parameter"), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



##______________________________________________________________#
##                                                              #
##            FUND/TREND LVaR as % of portfolio value           #
##______________________________________________________________#
##                                                              #
#
#### Calculate series of LVaR as % of portfolio value
#
##!! It is assumed that LVar is constant, and its value is set at the beginning of the script
#
#numFUND = 200  # Needed because VaR is averaged over the number of agents
#numTREND = 200
#
#tsFUNDvarperc <- array(0, dim=c(nTicks, nExp*nRuns))
#tsTRENDvarperc <- array(0, dim=c(nTicks, nExp*nRuns))
#
#tsFUNDvarperc_avg <- array(0, dim=c(nTicks, nExp))
#tsTRENDvarperc_avg <- array(0, dim=c(nTicks, nExp))
#
#for (k in seq(from=0, to=nExp-1)) {
#   for (j in seq(from=0, to=nRuns-1)) {
#      for (t in seq(from=1, to=nTicks)) {
#     
#         portfolioValue_FUND = 0
#         portfolioValue_TREND = 0
#
#         for (i in seq(from=1, to=nAssets)) {
#            portfolioValue_FUND <- portfolioValue_FUND + tsFUNDvolume[t,1+i+j*nAssets+k*nAssets*nRuns] * tsprices[t,1+i+j*nAssets+k*nAssets*nRuns]
#            portfolioValue_TREND <- portfolioValue_TREND + tsTRENDvolume[t,1+i+j*nAssets+k*nAssets*nRuns] * tsprices[t,1+i+j*nAssets+k*nAssets*nRuns]
#         }
#
#         if (portfolioValue_FUND > 10000){  # Ensure that the positions are not insignificant
#            tsFUNDvarperc[t,j+1+k*nRuns] <- numFUND * LVar/portfolioValue_FUND
#         }
#
#         if (portfolioValue_TREND > 10000){   # Ensure that the positions are not insignificant
#            tsTRENDvarperc[t,j+1+k*nRuns] <- numTREND * LVar/portfolioValue_TREND
#         }
#      }
#   }
#}
#
#for (k in seq(from=0, to=nExp-1)) {
#   for (j in seq(from=0, to=nRuns-1)) {
#      tsFUNDvarperc_avg[,1+k] <- tsFUNDvarperc_avg[,1+k] + tsFUNDvarperc[,j+1+k*nRuns]
#      tsTRENDvarperc_avg[,1+k] <- tsTRENDvarperc_avg[,1+k] + tsTRENDvarperc[,j+1+k*nRuns]
#   }
#   tsFUNDvarperc_avg[,1+k] <- tsFUNDvarperc_avg[,1+k]/nRuns
#   tsTRENDvarperc_avg[,1+k] <- tsTRENDvarperc_avg[,1+k]/nRuns
#}
#
#
#
#### Plot of FUND and TREND LVaR as percentage of portfolio value (averaged over runs)
#
#y_max = max(max(tsFUNDvarperc_avg[,1:nExp]), max(tsTRENDvarperc_avg[,1:nExp]))
#y_min = 0
#
#par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#for (e in seq(from=1, to=nExp)) {      
#   plot(tsTRENDvarperc_avg[,e], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="LVaR/Portf.value", col="seagreen")
#   lines(tsFUNDvarperc_avg[,e], type="l", col="darkorange1")
#}
#title(paste("Ratio of LVaR and portfolio value (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
#mtext("Objective: See how large is the LVaR w.r.t. portfolio value (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#### Plot of FUND and TREND LVaR as percentage of portfolio value (for individual runs)
#
#y_max = max(max(tsFUNDvarperc[,1:(nRuns*nExp)]), max(tsTRENDvarperc[,1:(nRuns*nExp)]))
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
#      }
#   } else {
#      for (i in seq(from=1, to=nRuns, by=1)) {
#         plot(tsFUNDvarperc[,i+(e-1)*nRuns], type="l", ylab="LVaR/Portf.value", main=paste("Run", i), ylim=c(y_min, y_max), col="darkorange1")
#         lines(tsTRENDvarperc[,i+(e-1)*nRuns], type="l", col="seagreen")  
#      }
#   }
#   title(paste("Ratio of LVaR and portfolio value ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#   mtext("Objective: See how large is the VaR w.r.t. portfolio value. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#



##_______________________________________________________________#
##                                                               #
##                      FUND/TREND FAILURES                      #
##_______________________________________________________________#
##                                                               # 
#
#### Plot of FUND and TREND failures (averaged over runs)
#
#y_max = max(max(tsFUNDfailures_avg[,1:nExp]), max(tsTRENDfailures_avg[,1:nExp]))
#y_min = min(min(tsFUNDfailures_avg[,1:nExp]), min(tsTRENDfailures_avg[,1:nExp]))
#
#par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#for (e in seq(from=1, to=nExp)) {      
#   plot(tsTRENDfailures_avg[,e], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Failures", col="seagreen")
#   lines(tsFUNDfailures_avg[,e], type="l", col="darkorange1")
#}
#title(paste("Failures of FUNDs vs TRENDs (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
#mtext("Objective: Compare the number of failures of the three groups of agents (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#### Plot of FUND and TREND failures (for individual runs)
#
#y_max = max(max(tsFUNDfailures[,2:(nRuns*nExp+1)]), max(tsTRENDfailures[,2:(nRuns*nExp+1)]))
#y_min = min(min(tsFUNDfailures[,2:(nRuns*nExp+1)]), min(tsTRENDfailures[,2:(nRuns*nExp+1)]))
#
#step2 <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many
#
#for (e in seq(from=1, to=nExp)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   if (nRuns>numRows*numCols){   
#      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {
#         plot(tsFUNDfailures[[i+2 +(e-1)*nRuns]], type="l", ylab="Failures", main=paste("Run", i+1), ylim=c(y_min, y_max), col="darkorange1")
#         lines(tsTRENDfailures[[i+2 +(e-1)*nRuns]], type="l", col="seagreen")
#      }
#   } else {
#      for (i in seq(from=1, to=nRuns, by=1)) {
#         plot(tsFUNDfailures[[i+1 +(e-1)*nRuns]], type="l", ylab="Failures", main=paste("Run", i), ylim=c(y_min, y_max), col="darkorange1")
#         lines(tsTRENDfailures[[i+1 +(e-1)*nRuns]], type="l", col="seagreen")  
#      }
#   }
#   title(paste("Failures of FUNDs vs TRENDs ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#   mtext("Objective: Compare the number of failures of the three groups of agents. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}
#
#
#### Bar charts of FUND/TREND aggregated failures (averaged over runs)
##
## Objective: Compare the failures accumulated by each group of traders
#
#par(mfrow=c(numRows, numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#for (e in seq(from=1, to=nExp)) {
#   failures <- c(sum(tsFUNDfailures_avg[,e]), sum(tsTRENDfailures_avg[,e]))
#   labels <- c("FUND", "TREND") 
#   barplot(failures, names = labels, col=c("darkorange1", "seagreen"), main=paste("Exp", e), ylim=c(0,200))
#}
#title(paste("Total failures along simulations"), outer = TRUE, col.main="blue", font.main=2)
#mtext("Objective: Compare the number of failures accumulated by each strategy.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#
#### Bar charts of FUND/TREND aggregated failures (for individual runs)
##
## Objective: Compare the failures accumulated by each group of traders
## along each simulation
#
#for (e in seq(from=1, to=nExp)) {
#   par(mfrow=c(numRows, numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#   if (nRuns>numRows*numCols){   
#      for (i in seq(from=step2, to=step2*numRows*numCols, by=step2)) {
#         failures <- c(sum(tsFUNDfailures[[2+i +(e-1)*nRuns]]), sum(tsTRENDfailures[[2+i +(e-1)*nRuns]]))
#         labels <- c("FUND", "TREND") 
#         barplot(failures, names = labels, col=c("darkorange1", "seagreen"), main=paste("Run", i+1), ylim=c(0,200))
#      }
#   } else {
#      for (i in seq(from=1, to=nRuns, by=1)) {
#         failures <- c(sum(tsFUNDfailures[[1+i +(e-1)*nRuns]]), sum(tsTRENDfailures[[1+i +(e-1)*nRuns]]))
#         labels <- c("FUND", "TREND") 
#         barplot(failures, names = labels, col=c("darkorange1", "seagreen"), main=paste("Run", i), ylim=c(0,200))
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
#par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#sum_tsFUNDfailures_avg <- array(0, dim=c(1, nExp))
#sum_tsTRENDfailures_avg <- array(0, dim=c(1, nExp))
#
#for (e in seq(from=1, to=nExp)) {
#   sum_tsFUNDfailures_avg[e] <- sum(tsFUNDfailures_avg[,e])
#   sum_tsTRENDfailures_avg[e] <- sum(tsTRENDfailures_avg[,e])
#}
#
#y_max = max(max(sum_tsFUNDfailures_avg), max(sum_tsTRENDfailures_avg))
#y_min = min(min(sum_tsFUNDfailures_avg), min(sum_tsTRENDfailures_avg))
#
#plot(sum_tsFUNDfailures_avg[,], type="l", main="FUND", ylim=c(y_min, y_max), xlab="Experiment", ylab="", col="darkorange1")
#plot(sum_tsTRENDfailures_avg[,], type="l", main="TREND", ylim=c(y_min, y_max), xlab="Experiment", ylab="", col="seagreen")
#
#title(paste("Aggregated failures (averaged over runs)"), outer = TRUE, col.main="blue", font.main=2)   
#mtext("Objective: Study the evolution of agents' failures along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#### Boxplot of aggregated failures along experiments
## Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots
#
#par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#tsFUNDfailures_exp <- array(0, dim=c(nRuns, nExp))    # These allocate the sum of agent failures corresponding to the same experiment
#tsTRENDfailures_exp <- array(0, dim=c(nRuns, nExp))
#
#for (e in seq(from=1, to=nExp)) {      
#   for (j in seq(from=1, to=nRuns)) {
#      tsFUNDfailures_exp[j,e] <- sum(tsFUNDfailures[,1+j+(e-1)*nRuns])
#      tsTRENDfailures_exp[j,e] <- sum(tsTRENDfailures[,1+j+(e-1)*nRuns])
#   }
#}
#boxplot(tsFUNDfailures_exp[,], notch=TRUE, col="darkorange1", main="FUND", xlab="")
#boxplot(tsTRENDfailures_exp[,], notch=TRUE, col="seagreen", main="TREND", xlab="")
#
#title("Range of variation of aggregated failures", outer = TRUE, col.main="blue", font.main=2)
#mtext("Test description: Overview of the evolution of agents' failures along experiments.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#
#
#
#### Scatterplot of failures along experiments
#
#par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
#
#FUNDfailures_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , failures)
#TRENDfailures_matrix <- array(0, dim=c(nRuns*nExp, 2))
#     
#for (e in seq(from=1, to=nExp)) {
#   for (j in seq(from=1, to=nRuns)) {
#     FUNDfailures_matrix[j+(e-1)*nRuns,1] = e
#	TRENDfailures_matrix[j+(e-1)*nRuns,1] = e
#	   
#	FUNDfailures_matrix[j+(e-1)*nRuns,2] = sum(tsFUNDfailures[,1+j+(e-1)*nRuns])
#	TRENDfailures_matrix[j+(e-1)*nRuns,2] = sum(tsTRENDfailures[,1+j+(e-1)*nRuns])
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
#   mtext("Objective: Study if movements in one asset induce movements in the other asset. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
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
#      mtext("Objective: Study if movements in one asset induce movements in the other asset. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
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
#      mtext("Objective: Study if movements in one asset induce movements in the other asset. [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
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
#           tscorr_23[i+volWindow,(e-1)*nRuns+k] <- cor( diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+2]), diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+3]) )
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


#dev.off()  # Close output files
#sink()


# ----------------------------------------------- #

