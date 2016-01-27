
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


###################################################################
#                                                                 #
#               'PARAMETERS' & INITIAL INFORMATION                #
#                                                                 #
###################################################################

nAssets = 2
nExp = 11
liquidity = 500   # Used to plot contributions to price formation

# Setting the path to the data folder

# Set the root directory (add your path)
root.dir <- "C:/Users/llacay/eclipse"

# Build the home directory (shouldn't be necessary to change)
home.dir <- paste(root.dir, "/agentsimulator/out/trend-value-ls-abm-simulation/", sep="")


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
   }
}


# Parameters needed from the java files

nRuns <- (dim(tsprices)[2] - 1)/(nAssets*nExp)
nTicks <- dim(tsprices)[1]

param_file = "trend_value_ls_3_assets_abm_001"  # Parameter file

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
      tsrandomprices_avg[,i+k*nAssets] <- tsrandomprices_avg[,i+k*nAssets]/nRuns

      kurt_avg[,i+k*nAssets] <- kurt_avg[,i+k*nAssets]/nRuns
   }
}



#######################################################################################################

# Open files to write the results

pdf(paste(home.dir, "Trend_Value_LS_ABM_Exp_001_outR.pdf", sep=""))   # Plot diagrams in a pdf file
sink(paste(home.dir, "Trend_Value_LS_ABM_Exp_001_outR.txt", sep=""))  # Write quantitative results to a text file



###################################################################
#                                                                 #
#         VALIDATION TESTS (Stylised facts for each asset)        #
#                                                                 #
###################################################################

cat("TEST: VA_TREND_VALUE_LS_ABM \n")
cat("===================================== \n")
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


# ------ VA-TF_ABM-1.1.3 - ARCH effect of log-returns ------ #

cat("\n --- VA-TF_ABM-1.1.3: ARCH test of log-returns --- \n")
cat("\n Test description: Volatility clustering leads to conditional heteroskedasticity effect in the series of squared returns, which should be detected with an ARCH test. Rejection of the ArchTest used here (pvalue close to 0) indicates ARCH effects and so volatility clustering. \n\n")

### First version of the test, taking function from package 'FinTS'

require(FinTS)
failed=-1  # Stores runs where there is no arch effect (the test is accepted)

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         arch <- ArchTest(diff(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]]))  # Rejection of the test (pvalue close to 0) indicates ARCH effects
                                                        # ArchTest function implements test in Tsay 2005 pp 101-102
         if (arch$p.value > 0.05) {
             failed <- append(failed, i+1)
             cat(paste("VA-TF_ABM-1.1.3: Arch test (FinTS package) failed in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }
         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e, "]", ": p-value = ", arch$p.value, "\n"))  # Write the result of each single run to a file
      }
   }
}

percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of VA-TF_ABM-1.1.3 (FinTS package): ", percentage_success, "% \n")  # Percentage of successful runs


#### Second version of the test, taking function from package 'vars'
##
## Comment: the previous function 'ArchTest' from package 'FinTS' implements the test in Tsay 2005 pp 101-102,
## but in my experience it does not work properly, because this test is always rejected, even when the price is 
## mainly random. This second function seems to be more coherent, as it does not reject the test when the price
## is random.
#
## ............... Function to run the ARCH test ....................
#
## This function is taken from: https://stat.ethz.ch/pipermail/r-help/2008-February/153257.html
## !!! EXTREMELY EXPENSIVE TO RUN THIS FUNCTION
#
#require(vars)
#
#archTest=function (x, lags= 16){
#   #x is a vector
#   require(vars)
#   s=embed(x,lags)
#   y=VAR(s,p=1,type="const")
#   result=arch.test(y,multi=F)$arch.uni[[1]]
#   return(result)
#}
#
# ..................................................................
#
#failed=-1  # Stores runs where there is no arch effect (the test is accepted)
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      for (i in seq(from=0, to=nRuns-1)) {
#         arch <- archTest(diff(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]]))  # Rejection of the test (pvalue close to 0) indicates ARCH effects
#
#         if (arch$p.value > 0.05) {
#             failed <- append(failed, i+1)
#             cat(paste("VA-TF_ABM-1.1.3: Arch test (vars package) failed in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
#         }
#         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e, "]", ": p-value = ", arch$p.value, "\n"))  # Write the result of each single run to a file
#      }
#   }
#}
#
#percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
#cat("\n % SUCCESS of VA-TF_ABM-1.1.3 (vars package): ", percentage_success, "% \n")  # Percentage of successful runs
#


# ------ VA-TF_ABM-1.1.6 - R/S test of ABSOLUTE log-returns ------ #

# The R/S test is a test of long-term memory

# .................. Function to calculate modified R/S statistic .......................

# This function is taken from: https://stat.ethz.ch/pipermail/r-help/2001-June/013425.html
#
# rs.test calculates the statistic of the modified R/S test
#
# x: time series
# q: number of lags included for calculation of covariances
#
# significance level: 0.05,     0.1
# critical value:     1.747,    1.62
#
# References: Lo (1991), Long-term Memory in Stock Market Prices, Econometrica 59, 1279--1313
#

# NOTE: The number of q for the maximum of lags to consider is still an open issue (Mills 2008). 
# For this reason, it is convenient to use several values.
# Critical values above do not tally with 2-tailed values given in the literature 
# (see e.g. Taylor 2005, page 135). So perhaps the values provided in the web source 
# above are for 1-tail test.

# Lo's test is documented to be conservative, as this accepts the null hypothesis (=short-term
# memory) for processes which in fact have long-term memory.


rs.test <- function(x, q, alpha) {	
   xbar <- mean(x)
   N <- length(x)
   r <- max(cumsum(x-xbar)) - min(cumsum(x-xbar))
   kovarianzen <- NULL
   for (i in 1:q) {	
      kovarianzen <- c(kovarianzen, sum((x[1:(N-i)]-xbar)*(x[(1+i):N]-xbar)))
   }
   if (q > 0) {
      s <- sum((x-xbar)^2)/N + sum((1-(1:q)/(q+1))*kovarianzen)*2/N
   }
   else {
	s <- sum((x-xbar)^2)/N
   }
   rs <- r/(sqrt(s)*sqrt(N))
   method <- "R/S Test for Long Memory"
   names(rs) <- "R/S Statistic"
   names(q) <- "Bandwidth q"
   structure(list(statistic = rs, parameter = q, method = method, data.name=deparse(substitute(x))), class="htest")
}

# ...................................................................................


### Quantitative test: Measure in how many runs Lo's R/S test is rejected, what
# indicates that the volatility (as absolute returns) has long-term dependence

cat("\n --- Modified R/S test (long-term memory of absolute returns) --- \n")

failed_q0=-1  # Stores runs where the absolute returns have no long-term dependence (R/S test is accepted)
failed_q1=-1 
failed_q5=-1 
failed_q10=-1 

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         RS_test_absreturns_q0 <- rs.test(abs(diff(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]])), 0, 0.05)   # Test for q=0 lags (=Mandelbrot R/S test?)
         if (RS_test_absreturns_q0$statistic < 1.747) {
             failed_q0 <- append(failed_q0, i+1)
             cat(paste("R/S test accepted (absolute returns have no long-term memory, q=0) in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }
         
	   RS_test_absreturns_q1 <- rs.test(abs(diff(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]])), 1, 0.05)   # Test for q=1 lags
         if (RS_test_absreturns_q1$statistic < 1.747) {
             failed_q1 <- append(failed_q1, i+1)
             cat(paste("R/S test accepted (absolute returns have no long-term memory, q=1) in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }

         RS_test_absreturns_q5 <- rs.test(abs(diff(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]])), 5, 0.05)   # Test for q=5 lags
         if (RS_test_absreturns_q5$statistic < 1.747) {
             failed_q5 <- append(failed_q5, i+1)
             cat(paste("R/S test accepted (absolute returns have no long-term memory, q=5) in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }

         RS_test_absreturns_q10 <- rs.test(abs(diff(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]])), 10, 0.05)   # Test for q=10 lags
         if (RS_test_absreturns_q10$statistic < 1.747) {
             failed_q10 <- append(failed_q10, i+1)
             cat(paste("R/S test accepted (absolute returns have no long-term memory, q=10) in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }
      }
   }
}

percentage_success_q0 = (1-((length(failed_q0)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of R/S test for absolute returns (long-term memory, q=0): ", percentage_success_q0, "% \n")  # Percentage of successful runs

percentage_success_q1 = (1-((length(failed_q1)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of R/S test for absolute returns (long-term memory, q=1): ", percentage_success_q1, "% \n")  # Percentage of successful runs

percentage_success_q5 = (1-((length(failed_q5)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of R/S test for absolute returns (long-term memory, q=5): ", percentage_success_q5, "% \n")  # Percentage of successful runs

percentage_success_q10 = (1-((length(failed_q10)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of R/S test for absolute returns (long-term memory, q=10): ", percentage_success_q10, "% \n")  # Percentage of successful runs


### Graphical representation: cdplot of runs where absolute returns have long-term memory

for (i in seq(from=1, to=nAssets)) {

   # Count in how many runs the absolute returns have long-term memory
   test_rejected_q0 <- array(0, dim=c(nExp, nRuns))
   test_rejected_q1 <- array(0, dim=c(nExp, nRuns))
   test_rejected_q5 <- array(0, dim=c(nExp, nRuns))
   test_rejected_q10 <- array(0, dim=c(nExp, nRuns))

   for (e in seq(from=1, to=nExp)) {
      for (j in seq(from=0, to=nRuns-1)) {
         RS_test_absreturns_q0 <- rs.test(abs(diff(tslogprices[[i+1+j*nAssets +(e-1)*nAssets*nRuns]])), 0, 0.05)   # Test for q=0 lags
         RS_test_absreturns_q1 <- rs.test(abs(diff(tslogprices[[i+1+j*nAssets +(e-1)*nAssets*nRuns]])), 1, 0.05)   # Test for q=1 lags
         RS_test_absreturns_q5 <- rs.test(abs(diff(tslogprices[[i+1+j*nAssets +(e-1)*nAssets*nRuns]])), 5, 0.05)   # Test for q=5 lags
         RS_test_absreturns_q10 <- rs.test(abs(diff(tslogprices[[i+1+j*nAssets +(e-1)*nAssets*nRuns]])), 10, 0.05)   # Test for q=10 lags

         if ( RS_test_absreturns_q0$statistic > 1.747 ) {
            test_rejected_q0[e,j+1] = 1
         }

         if ( RS_test_absreturns_q1$statistic > 1.747 ) {
            test_rejected_q1[e,j+1] = 1
         }

         if ( RS_test_absreturns_q5$statistic > 1.747 ) {
            test_rejected_q5[e,j+1] = 1
         }

         if ( RS_test_absreturns_q10$statistic > 1.747 ) {
            test_rejected_q10[e,j+1] = 1
         }
      }
   }

   # Convert numeric vectors to factors to draw cdplots
   long_term_memory_q0 <- factor(test_rejected_q0, levels = 0:1, labels = c("no", "yes"))
   long_term_memory_q1 <- factor(test_rejected_q1, levels = 0:1, labels = c("no", "yes"))
   long_term_memory_q5 <- factor(test_rejected_q5, levels = 0:1, labels = c("no", "yes"))
   long_term_memory_q10 <- factor(test_rejected_q10, levels = 0:1, labels = c("no", "yes"))

   # Draw cdplots
   par(mfrow=c(2,2), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
   x_axis <- rep(1:nExp,nRuns)

   cdplot(long_term_memory_q0~x_axis, xlab="Experiment", ylab="Long-term memory?", main="R/S  q = 0 [Mandelbrot?]", col = c("red3", "palegreen"))
   cdplot(long_term_memory_q1~x_axis, xlab="Experiment", ylab="Long-term memory?", main="R/S  q = 1", col = c("red3", "palegreen"))
   cdplot(long_term_memory_q5~x_axis, xlab="Experiment", ylab="Long-term memory?", main="R/S  q = 5", col = c("red3", "palegreen"))
   cdplot(long_term_memory_q10~x_axis, xlab="Experiment", ylab="Long-term memory?", main="R/S  q = 10", col = c("red3", "palegreen"))
   
   title(paste("Long-term memory of absolute returns (modified R/S test) - Asset ", i), outer = TRUE, col.main="blue", font.main=2)
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


#________________________________________________________#
#                                                        #
#          TEST VA-TF_ABM-1.2: VOLUME CLUSTERING         #
#________________________________________________________#
#                                                        #

# ------ VA-TF_ABM-1.2.1 - ACF of volume ------ #

### ACF of volume for single runs 
#
# Objective: For each experiment, plot a selection of ACF for single runs

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {      
            acf(tsvolume[[i+k+1 +(e-1)*nAssets*nRuns]], main=paste("Run", 1+i/nAssets), ylim=c(-1,1))
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            acf(tsvolume[[i+k +(e-1)*nAssets*nRuns]], main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
         }
      }
      title(paste("VA-TF_ABM-1.2.1 - ACF of volume - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: ACF should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}

### Average ACF of volume
#
# Objective: Plot a summary of the ACF along experiments

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {
      plot(mean_ACF_volume[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Autocorrelations")
      lines(upper_bound, lty=2, col="blue")
      lines(lower_bound, lty=2, col="blue")      
   }
   title(paste("VA-TF_ABM-1.2.1 - Average ACF of volume (over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: ACF should remain positive (that is, above the dashed lines) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}

### Variation in ACF of volume
#
# Plot the maximum and minimum ACF for each experiment
# Objective: Study the range of variation of ACF over experiments

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

for (i in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (k in seq(from=0, to=nExp-1)) {
      #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))    # 1 plot per page
      xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
      yy <- c(Min_ACF_volume[,i+k*nAssets], rev(Max_ACF_volume[,i+k*nAssets]))
      plot(xx,yy, type="l", main=paste("Exp", k+1), 
   	xlab="Lag", ylab=paste("ACF - Asset", i), lwd=1, ylim=c(-1,1))
      polygon(xx, yy, col="gray")
      lines(upper_bound, lty=2, col="blue")
      lines(lower_bound, lty=2, col="blue") 
   }
   title(paste("VA-TF_ABM-1.2.1 - Range of variation of ACF of volume - Asset", i), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: ACF of volume should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ------ VA-TF_ABM-1.2.2 - Hurst exponent of volume ------ #

### Variation of the Hurst exponent of volume
#
# Calculate the min/max value of the Hurst exponent over all runs for each asset.
# This exponent is an indicator of the long-term memory of the time series
# Objective: Study the range of variation of the Hurst exponent over experiments

Max_Hurst <- array(0, dim=c(nExp, nAssets))  # Arrays to store the max and min Hurst exponent over all runs (for each asset and experiment)
Min_Hurst <- array(0, dim=c(nExp, nAssets))
Mean_Hurst <- array(0, dim=c(nExp, nAssets))
Stdev_Hurst <- array(0, dim=c(nExp, nAssets))

volume_Hurst_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the Hurst exponent for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with Hurst exponent of asset i for each run
         volume_Hurst_vector[,j+1] = hurstSpec(tsvolume[[i+1+j*nAssets+k*nAssets*nRuns]])   # Store values of Hurst exponent
      }
      Max_Hurst[k+1,i] = max(volume_Hurst_vector)  # Select max/min Hurst exponent over all runs
      Min_Hurst[k+1,i] = min(volume_Hurst_vector)
      Mean_Hurst[k+1,i] = mean(volume_Hurst_vector)
      Stdev_Hurst[k+1,i] = sd(volume_Hurst_vector[1,])
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
   lines(rep(0.5, nExp), lty=2, col="blue")   # Horizontal line at 0.5
}
title("VA-TF_ABM-1.2.2 - Range of variation of Hurst exp of volume", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the mean/max/min values of the Hurst exponent. It should be above 0.5 (dashed lines).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file

## To provide information in the x axis on e.g. the percentage of HF's: create a vector with the percentages, e.g.:
## x <- c(0.1, 0.2, 0.3, 0.4, 0.5)
## axis(1, at=1:nExp, x)




#_______________________________________________________________#
#                                                               #
#          TEST VA-TF_ABM-1.3: FAT TAILS OF LOG-RETURNS         #
#_______________________________________________________________#
#                                                               #

# ------ VA-TF_ABM-1.3.1 - QQ plot of log-returns ------ #

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) { 
            qqnorm(diff(tslogprices[[i+k+1 +(e-1)*nAssets*nRuns]]), main=paste("Run", 1+i/nAssets)); qqline(diff(tslogprices[[i+k+1 +(e-1)*nAssets*nRuns]]))
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            qqnorm(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]), main=paste("Run", 1+(i-1)/nAssets)); qqline(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]))     
         }
      }
      title(paste("VA-TF_ABM-1.3.1 - Q-Q plot of log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: The distribution of log-returns should deviate from the diagonal (which corresponds to a normal distribution) in the tails.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


# ------ VA-TF_ABM-1.3.2 - Histogram of log-return distribution ------ #

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) { 
            hist(scale(diff(tslogprices[[i+k+1 +(e-1)*nAssets*nRuns]]), center = TRUE, scale = TRUE), freq = FALSE, col = "grey",  main=paste("Run", 1+i/nAssets), xlab="Standardised log-returns", nclass=100)  # Compare the distribution of  standardised log-returns to N(0,1)
      curve(dnorm, col = 2, add = TRUE)
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            hist(scale(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]), center = TRUE, scale = TRUE), freq = FALSE, col = "grey",  main=paste("Run", 1+(i-1)/nAssets), xlab="Standardised log-returns", nclass=100)  # Compare the distribution of  standardised log-returns to N(0,1)
      curve(dnorm, col = 2, add = TRUE)  
         }
      }
      title(paste("VA-TF_ABM-1.3.2 - Histogram of log-returns vs Normal - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: The probability in the tails of the histogram should be higher for the log-return distribution than for the normal one.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file 
   }
}


# ------ VA-TF_ABM-1.3.3 - Excess kurtosis of log-returns ------ #

### Quantitative test: Measure in how many runs there is excess kurtosis

cat("\n\n --- VA-TF_ABM-1.3.3: Excess kurtosis of log-returns --- \n\n")
cat("\n Test description: The test calculates the excess kurtosis of log-returns time series. It measures in what degree the kurtosis exceeds that of the normal distribution, and so it should be greater than 0. \n\n")
failed=-1  # Stores runs where the excess kurtosis is negative

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         kurt <- kurtosis(diff(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]]), na.rm = FALSE, method="excess")[1]
         if (kurt < 0) {
            failed <- append(failed, i+1)
            cat(paste("VA-TF_ABM-1.3.3: Log-return kurtosis is negative in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }
         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e, "]", ": kurtosis = ", kurt, "\n"))  # Write the result of each single run to a file 
      }
   }
}

percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of VA-TF_ABM-1.3.3: ", percentage_success, "% \n")  # Percentage of successful runs


### Graphical test: Plot the mean and range of variation of log-return kurtosis
# Objective: Study the range of variation of kurtosis over experiments

# Calculate the min/max value of log-return kurtosis over all runs for each asset

Max_kurt <- array(0, dim=c(nExp, nAssets))  # Arrays to store the max and min kurtosis over all runs (for each asset and experiment)
Min_kurt <- array(0, dim=c(nExp, nAssets))
Mean_kurt <- array(0, dim=c(nExp, nAssets))  # Array to store the mean kurtosis over all runs (for each asset and experiment)
Stdev_kurt <- array(0, dim=c(nExp, nAssets))  # Array to store the standard deviation of kurtosis over all runs (for each asset and experiment)

asset_kurtosis_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the kurtosis for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with kurtosis of asset i for each run
         asset_kurtosis_vector[,j+1] = kurtosis(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]), na.rm = FALSE, method="excess")[1]   # Store values of kurtosis
      }
      Max_kurt[k+1,i] = max(asset_kurtosis_vector)  # Select max/min kurtosis over all runs
      Min_kurt[k+1,i] = min(asset_kurtosis_vector)
      Mean_kurt[k+1,i] = mean(asset_kurtosis_vector)
      Stdev_kurt[k+1,i] = sd(asset_kurtosis_vector[1,])
   }
}

# Plot mean, minimum, and maximum kurtosis

y_min = min(Min_kurt)  # Range of y axis
y_max = max(Max_kurt)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   xx <- c(1:nExp, nExp:1)   # Needed to shade the area between max and min
   yy <- c(Min_kurt[,i], rev(Max_kurt[,i]))
   plot(xx,yy, type="l", main=paste("Asset", i), col="black", 
	xlab="Experiment", ylab="Max/Min kurtosis", lwd=1, ylim=c(y_min,y_max))
   polygon(xx, yy, col="gray")

   lines(Mean_kurt[,i], type="l", col="black", lwd=2)   
   lines(Mean_kurt[,i]+Stdev_kurt[,i], type="l", col="red2")   # Plot +-1stdev to have an idea of the variability
   lines(Mean_kurt[,i]-Stdev_kurt[,i], type="l", col="red2")
}
title("VA-TF_ABM-1.3.3 - Range of variation of kurtosis", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the mean/max/min values of kurtosis. It should be positive.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


## To provide information in the x axis on e.g. the percentage of HF's: create a vector with the percentages, e.g.:
## x <- c(0.1, 0.2, 0.3, 0.4, 0.5)
## axis(1, at=1:nExp, x)


### Alternative graphical representation: boxplot of log-returns + kurtosis

x_axis <- seq(1,nExp,1) 	# Plot first time series

for (k in seq(from=1, to=nAssets)) {
   indices <- seq(from=k, to=(nExp-1)*nAssets+k, by=nAssets)
   par(mfrow=c(1,1), mar=c(3,7,6,1) + 0.1, oma=c(2,2,2,2))
   boxplot(diff(tslogprices_avg[,indices]), main="", xlab="")  
   axis(2, col="black",lwd=2)
   mtext(2,text="Log-return distribution",line=2)
   
   par(new=T)  # Plot second time series
   plot(x_axis, kurt_avg[,indices], axes=F, xlab="", ylab="", type="l",lty=1, main="", lwd=2, col="red")
   
   axis(2, lwd=2,line=3.5)
   mtext(2,text="Kurtosis",line=5.5, col="red")

#   axis(1,pretty(range(x_axis),10))   # Add x axis
   mtext("Experiment",side=1,col="black",line=2)

   title(main=paste("VA-TF_ABM-1.3.3 - Distrib. log-returns + Kurtosis, avg over runs ( Asset", k, ")"), adj=1, col.main="blue")   # Add title
   mtext("Test description: Overview of the variation of ACF of log-returns (expected to be around 0), and of the average kurtosis (expected to be positive).", side=3, line=-4.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ------ VA-TF_ABM-1.3.4 - Tail behaviour of return distribution: Power law? ------ #

### Graphical test: Do returns follow a power law in the tails?
#
# Objective: study if the tail of return distribution follows a power law. In that case,
# the cumulative distribution of returns in log-log scale can be well fitted by a line
# in the tails. The empirical value for the tail index (slope of the regression line in 
# the tails) lies between -2 and -4 (around -3).
#
# Note: the graph of the cumulative distribution that I am drawing is based on the graph
# presented in Raberto (2001) "Agent-based simulation of a financial market", page 322
# I have not been able to run the R functions devoted to analysing the tail index 
# (such as 'awstindex', in package 'aws'), so I am plotting the graph 'by hand'
#

tsscaledreturns <- array(0, dim=c(nTicks-1, nAssets*nExp*nRuns))    # Standardise the series of returns
for (i in seq(from=1, to=nAssets*nExp*nRuns)) {
   tsscaledreturns[,i] <- scale(diff(tslogprices[[i+1]]))
}

tsabsscaledreturns <- abs(tsscaledreturns)   # Negative and positive tails are merged

# Plot cumulative distribution of absolute standardised returns in log-log scale (for individual runs)

p <- ppoints(100)
tail <- seq(0.85, 0.995, 0.005)   # We select the points in the 15% tail for the regression
for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
            X <- tsabsscaledreturns[,i+k +(e-1)*nAssets*nRuns]
            plot(log(quantile(X, p=p)), log(1-p), type="l", ylab="log(P[|ret|>x])", main=paste("Run", 1+i/nAssets))
            lin_reg <- lm( log(quantile(X,p=p, probs=tail)) ~ log(sort(tail,decreasing=TRUE)) )   # Linear regression that fits the tail             
            abline(lin_reg, col="blue")    # Plot the regression line
            text(-0.2, -0.5, paste("slope =", round(coef(lin_reg)[2],2)), col="blue")  # Print slope of regression line
            lines(log(quantile(abs(rnorm(nTicks-1)), p=p)), log(1-p), type="l", col="red")  # Comparison with a normal distribution
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            X <- tsabsscaledreturns[,(i-1)+k +(e-1)*nAssets*nRuns]
            plot(log(quantile(X, p=p)), log(1-p), type="l", ylab="log(P[|ret|>x])", main=paste("Run", 1+(i-1)/nAssets))
            lin_reg <- lm( log(quantile(X,p=p, probs=tail)) ~ log(sort(tail,decreasing=TRUE)) )   # Linear regression that fits the tail 
            abline(lin_reg, col="blue")    # Plot the regression line
            text(-0.2, -0.5, paste("slope =", round(coef(lin_reg)[2],2)), col="blue")   # Print slope of regression line
            lines(log(quantile(abs(rnorm(nTicks-1)), p=p)), log(1-p), type="l", col="red")  # Comparison with a normal distribution
         }
      }
      title(paste("VA-TF_ABM-1.3.4 - Log-log cumulative distribution of returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: Tail index of the CCF of log-returns (in log-log scale). The slope of the linear regression should be between -2 and -4.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


# ------ VA-TF_ABM-1.3.5 - Tail behaviour of return distribution: Hill estimator ------ #

### Graphical test: Hill tail index of return distribution
#
# Objective: the Hill plot is used to estimate the tail index
# of a Pareto type distribution. If the return distribution follows
# a power law in the tails, then the Hill plot should tend to the exponent

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
       par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             hill(diff(tslogprices[[i+k+1+(e-1)*nAssets*nRuns]]), option = "alpha", end = 500, p = 0.999)
          }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            hill(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]), option = "alpha", end = 500, p = 0.999)
         }
      }
      title(paste("VA-TF_ABM-1.3.5 - Hill tail index of return distribution - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: The Hill tail index should stabilise in a horizontal line in the region 2-4.", side=3, line=1, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


#_________________________________________________________#
#                                                         #
#           TEST VA-TF_ABM-1.4: VOLUME SKEWNESS           #
#_________________________________________________________#
#                                                         #

# ------ VA-TF_ABM-1.4.1 - Histogram of volume distribution ------ #

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) { 
            hist(tsvolume[[i+k+1 +(e-1)*nAssets*nRuns]], main=paste("Run", 1+i/nAssets), xlab="Total volume", nclass=100)
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            hist(tsvolume[[i+k +(e-1)*nAssets*nRuns]], main=paste("Run", 1+(i-1)/nAssets), xlab="Total volume", nclass=100)
         }
      }
      title(paste("VA-TF_ABM-1.4.1 - Histogram of volume distribution - Asset", k, "( Exp", e, ") [No SF?]"), outer = TRUE, col.main="red", font.main=2)
      mtext("Test description: The distribution of volume should be asymmetrical, with the bulk of values lying at the left of the mean.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file 
   }
}


# ------ VA-TF_ABM-1.4.2 - Skewness of volume ------ #

### Quantitative test: Measure in how many runs the skewnewss is negative

cat("\n\n --- VA-TF_ABM-1.4.2: Skewness of volume [No SF?] --- \n\n")
cat("\n Test description: The test calculates the skewness of volume time series. As the volume is expected to be asymmetrical, with the mass of the distribution concentrated on the left of the figure, the skewness should be greater than 0. \n\n")

failed=-1  # Stores runs where the volume skewness is negative

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         skew <- skewness(tsvolume[[k+1+i*nAssets +(e-1)*nAssets*nRuns]], na.rm = FALSE, method="moment")[1]
         if (skew < 0) {
            failed <- append(failed, i+1)
            cat(paste("VA-TF_ABM-1.4.2: Volume skewness is negative in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }
         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e, "]", ": skewness = ", skew, "\n"))  # Write the result of each single run to a file 
      }
   }
} 

percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of VA-TF_ABM-1.4.2: ", percentage_success, "% \n")  # Percentage of successful runs


### Graphical test: Plot the mean and range of variation of volume skewness
# Objective: Study the range of variation of skewness over experiments

# Calculate the maximum value of volume skewness over all runs for each asset

Max_skew <- array(0, dim=c(nExp, nAssets))  # Arrays to store the max and min skewness over all runs (for each asset and experiment)
Min_skew <- array(0, dim=c(nExp, nAssets))
Mean_skew <- array(0, dim=c(nExp, nAssets))  # Array to store the mean skewness over all runs (for each asset and experiment)
Stdev_skew <- array(0, dim=c(nExp, nAssets))  # Array to store the standard deviation of skewness over all runs (for each asset and experiment)

asset_skewness_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the skewness for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with skewness of asset i for each run
         asset_skewness_vector[,j+1] = skewness(tsvolume[[i+1+j*nAssets+k*nAssets*nRuns]], na.rm = FALSE, method="moment")[1]   # Store values of skewness
      }
      Max_skew[k+1,i] = max(asset_skewness_vector)  # Select max/min skewness over all runs
      Min_skew[k+1,i] = min(asset_skewness_vector)
      Mean_skew[k+1,i] = mean(asset_skewness_vector)
      Stdev_skew[k+1,i] = sd(asset_skewness_vector[1,])
   }
}

# Plot mean, minimum, and maximum skewness

y_min = min(Min_skew)   # Range of y axis
y_max = max(Max_skew)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
#   dev.new()         # Plots each figure in a new window
   xx <- c(1:nExp, nExp:1)   # Needed to shade the area between max and min
   yy <- c(Min_skew[,i], rev(Max_skew[,i]))
   plot(xx,yy, type="l", main=paste("Asset", i), col="black", 
	xlab="Experiment", ylab="Max/Min skewness", lwd=1, ylim=c(y_min,y_max))
   polygon(xx, yy, col="gray")
   lines(Mean_skew[,i], type="l", col="black", lwd=2)
   lines(Mean_skew[,i]+Stdev_skew[,i], type="l", col="red2")   # Plot +-1stdev to have an idea of the variability
   lines(Mean_skew[,i]-Stdev_skew[,i], type="l", col="red2")
}
title("VA-TF_ABM-1.4.2 - Range of variation of volume skewness [No SF?]", outer = TRUE, col.main="red", font.main=2)
mtext("Test description: Overview of the mean/max/min values of skewness. It should be positive.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


## To provide information in the x axis on e.g. the percentage of HF's: create a vector with the percentages, e.g.:
## x <- c(0.1, 0.2, 0.3, 0.4, 0.5)
## plot(x, Max_skew[,i], [...])



#___________________________________________________________________________________#
#                                                                                   #
#           TEST VA-TF_ABM-1.5: CORRELATION BETWEEN VOLATILITY AND VOLUME           #
#___________________________________________________________________________________#
#                                                                                   #

# ------ VA-TF_ABM-1.5.1 - Correlation between volume and volatility as absolute log-returns ------ #

### Quantitative test: Measure in how many runs the correlation between volatility and volume is positive

tsvolume2 <- tsvolume[-1,]  # Delete first row to have the same dimension than returns vector
cat("\n\n --- VA-TF_ABM-1.5.1: Correlation between volume and volatility as absolute log-returns --- \n\n")
cat("\n Test description: The test calculates the correlation between the time series of volatility (measured as absolute log-returns) and volume. It should be positive. \n\n")

failed=-1  # Stores runs where the correlation is negative

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         vvcor <- cor(abs(diff(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]])), tsvolume2[[k+1+i*nAssets +(e-1)*nAssets*nRuns]], use = "everything")[1]
         if (vvcor < 0) {
            failed <- append(failed, i+1)
            cat(paste("VA-TF_ABM-1.5.1: Correlation between volume and volatility is negative in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }
         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e, "]", ": volat-volume corr = ", vvcor, "\n"))  # Write the result of each single run to a file 
      }
   }
}

percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of VA-TF_ABM-1.5.1: ", percentage_success, "% \n")  # Percentage of successful runs


### Graphical test: Plot the mean and range of variation of correlation beween volume and volatility
# Objective: Study the range of variation of the correlation between volume and volatility over experiments
# Volatility is defined here as absolute returns

# Calculate the maximum value of correlation between volume and volatility over all runs for each asset

Max_corr <- array(0, dim=c(nExp, nAssets))  # Arrays to store the max and min correlation over all runs (for each asset and experiment)
Min_corr <- array(0, dim=c(nExp, nAssets))
Mean_corr <- array(0, dim=c(nExp, nAssets))  # Array to store the mean correlation over all runs (for each asset and experiment)
Stdev_corr <- array(0, dim=c(nExp, nAssets))  # Array to store the standard deviation of correlation over all runs (for each asset and experiment)

asset_correlation_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the correlation for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with correlation of asset i for each run
         asset_correlation_vector[,j+1] = cor(abs(diff(tslogprices[[i+1+j*nAssets +k*nAssets*nRuns]])), tsvolume2[[i+1+j*nAssets +k*nAssets*nRuns]], use = "everything")[1]   # Store values of correlation
      }
      Max_corr[k+1,i] = max(asset_correlation_vector)  # Select max/min correlation over all runs
      Min_corr[k+1,i] = min(asset_correlation_vector)
      Mean_corr[k+1,i] = mean(asset_correlation_vector)
      Stdev_corr[k+1,i] = sd(asset_correlation_vector[1,])
   }
}

##boxplot(asset_correlation_vector[,], notch=FALSE, ylim=c(0.55,0.7))   ## Plot for the thesis


# Plot mean, minimum, and maximum correlation

y_min = min(Min_corr)   # Range of y axis
y_max = max(Max_corr)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
#   dev.new()         # Plots each figure in a new window
   xx <- c(1:nExp, nExp:1)   # Needed to shade the area between max and min
   yy <- c(Min_corr[,i], rev(Max_corr[,i]))
   plot(xx,yy, type="l", main=paste("Asset", i), col="black", 
	xlab="Experiment", ylab="Max/Min correlation", lwd=1, ylim=c(y_min,y_max))
   polygon(xx, yy, col="gray")
   lines(Mean_corr[,i], type="l", col="black", lwd=2)
   lines(Mean_corr[,i]+Stdev_corr[,i], type="l", col="red2")   # Plot +-1stdev to have an idea of the variability
   lines(Mean_corr[,i]-Stdev_corr[,i], type="l", col="red2")
}
title("VA-TF_ABM-1.5.1 - Range of variation of correlation between volume and volatility (abs returns)", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the mean/max/min values of correlation between volume and volatility. It should be positive.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


## To provide information in the x axis on e.g. the percentage of HF's: create a vector with the percentages, e.g.:
## x <- c(0.1, 0.2, 0.3, 0.4, 0.5)
## plot(x, Max_skew[,i], [...])



# ------ VA-TF_ABM-1.5.2 - Correlation between volume and volatility as squared log-returns ------ #

### Quantitative test: Measure in how many runs the correlation between volatility and volume is positive

tsvolume2 <- tsvolume[-1,]  # Delete first row to have the same dimension than returns vector
cat("\n\n --- VA-TF_ABM-1.5.2: Correlation between volume and volatility as squared log-returns --- \n\n")
cat("\n Test description: The test calculates the correlation between the time series of volatility (measured as squared log-returns) and volume. It should be positive. \n\n")

failed=-1  # Stores runs where the correlation is negative

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         vvcor <- cor(diff(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]])^2, tsvolume2[[k+1+i*nAssets +(e-1)*nAssets*nRuns]], use = "everything")[1]
         if (vvcor < 0) {
            failed <- append(failed, i+1)
            cat(paste("VA-TF_ABM-1.5.2: Correlation between volume and volatility is negative in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }
         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e, "]", ": volat-volume corr = ", vvcor, "\n"))  # Write the result of each single run to a file
      }
   }
} 

percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of VA-TF_ABM-1.5.2: ", percentage_success, "% \n")  # Percentage of successful runs


### Graphical test: Plot the mean and range of variation of correlation beween volume and volatility
# Objective: Study the range of variation of the correlation between volume and volatility over experiments
# Volatility is defined here as squared returns

# Calculate the maximum value of correlation between volume and volatility over all runs for each asset

Max_corr <- array(0, dim=c(nExp, nAssets))  # Arrays to store the max and min correlation over all runs (for each asset and experiment)
Min_corr <- array(0, dim=c(nExp, nAssets))
Mean_corr <- array(0, dim=c(nExp, nAssets))  # Array to store the mean correlation over all runs (for each asset and experiment)
Stdev_corr <- array(0, dim=c(nExp, nAssets))  # Array to store the standard deviation of correlation over all runs (for each asset and experiment)

asset_correlation_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the correlation for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with correlation of asset i for each run
         asset_correlation_vector[,j+1] = cor((diff(tslogprices[[i+1+j*nAssets +k*nAssets*nRuns]]))^2, tsvolume2[[i+1+j*nAssets +k*nAssets*nRuns]], use = "everything")[1]   # Store values of correlation
      }
      Max_corr[k+1,i] = max(asset_correlation_vector)  # Select max/min correlation over all runs
      Min_corr[k+1,i] = min(asset_correlation_vector)
      Mean_corr[k+1,i] = mean(asset_correlation_vector)
      Stdev_corr[k+1,i] = sd(asset_correlation_vector[1,])
   }
}

# Plot mean, minimum, and maximum correlation

y_min = min(Min_corr)   # Range of y axis
y_max = max(Max_corr)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
#   dev.new()         # Plots each figure in a new window
   xx <- c(1:nExp, nExp:1)   # Needed to shade the area between max and min
   yy <- c(Min_corr[,i], rev(Max_corr[,i]))
   plot(xx,yy, type="l", main=paste("Asset", i), col="black", 
	xlab="Experiment", ylab="Max/Min correlation", lwd=1, ylim=c(y_min,y_max))
   polygon(xx, yy, col="gray")
   lines(Mean_corr[,i], type="l", col="black", lwd=2)
   lines(Mean_corr[,i]+Stdev_corr[,i], type="l", col="red2")   # Plot +-1stdev to have an idea of the variability
   lines(Mean_corr[,i]-Stdev_corr[,i], type="l", col="red2")
}
title("VA-TF_ABM-1.5.2 - Range of variation of correlation between volume and volatility (sq returns)", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the mean/max/min values of correlation between volume and volatility. It should be positive.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


## To provide information in the x axis on e.g. the percentage of HF's: create a vector with the percentages, e.g.:
## x <- c(0.1, 0.2, 0.3, 0.4, 0.5)
## plot(x, Max_skew[,i], [...])



# ------ VA-TF_ABM-1.5.3 - Correlation between volume and volatility as absolute log-returns for different lags (CCF) ------ #

### Cross-correlation function of volume and ABSOLUTE log-returns for single runs 
#
# Objective: For each experiment, plot a cross-correlation function of volume and volatility
# (as absolute log returns) for single runs to study the correlation for different lags

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
       par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             ccf(abs(diff(tslogprices[[i+1+k+(e-1)*nAssets*nRuns]])), tsvolume2[[i+1+k+(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            ccf(abs(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]])), tsvolume2[[i+k +(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
          }
      }
      title(paste("VA-TF_ABM-1.5.3 - CCF of volume and absolute log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: CCF should be high for lags 0 and 1, and smaller for other lags.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


# ------ VA-TF_ABM-1.5.4 - Correlation between volume and volatility as squared log-returns for different lags (CCF) ------ #

### Cross-correlation function of volume and SQUARED log-returns for single runs 
#
# Objective: For each experiment, plot a cross-correlation function of volume and volatility
# (as squared log returns) for single runs to study the correlation for different lags

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
       par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             ccf((diff(tslogprices[[k+1+i +(e-1)*nAssets*nRuns]]))^2, tsvolume2[[k+1+i +(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            ccf((diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]))^2, tsvolume2[[i+k +(e-1)*nAssets*nRuns]], ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
          }
      }
      title(paste("VA-TF_ABM-1.5.4 - CCF of volume and squared log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: CCF should be high for lags 0 and 1, and smaller for other lags.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}



#_____________________________________________________________#
#                                                             #
#           TEST VA-TF_ABM-1.6: VOLATILITY SKEWNESS           #
#_____________________________________________________________#
#                                                             #

# ------ VA-TF_ABM-1.6.1 - Histogram of absolute returns distribution ------ #

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
		hist(abs(diff(tslogprices[[i+1+k+(e-1)*nAssets*nRuns]])), main=paste("Run", 1+i/nAssets), xlab="Abs returns", nclass=100)
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {            
		hist(abs(diff(tslogprices[[i+k+(e-1)*nAssets*nRuns]])), main=paste("Run", 1+(i-1)/nAssets), xlab="Abs returns", nclass=100)
         }
      }
      title(paste("VA-TF_ABM-1.6.1 - Histogram of volatility (abs returns) distrib. - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: The distribution of volatility should be asymmetrical, skewed to the right (and similar to a log-normal distribution).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file 
   }
}


# ------ VA-TF_ABM-1.6.2 - Skewness of absolute returns ------ #

### Quantitative test: Measure in how many runs the skewnewss is negative

cat("\n\n --- VA-TF_ABM-1.6.2: Skewness of volatility (abs returns) --- \n\n")
cat("\n Test description: The test calculates the skewness of absolute returns time series. As the volatility distribution is expected to be asymmetrical, with the mass of the distribution skewed to the right, the skewness should be greater than 0. \n\n")

failed=-1  # Stores runs where the volatility skewness is negative

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         skew <- skewness(abs(diff(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]])), na.rm = FALSE, method="moment")[1]
         if (skew < 0) {
            failed <- append(failed, i+1)
            cat(paste("VA-TF_ABM-1.6.2: Volatility skewness is negative in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }
         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e, "]", ": skewness = ", skew, "\n"))  # Write the result of each single run to a file 
      }
   }
} 

percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of VA-TF_ABM-1.6.2: ", percentage_success, "% \n")  # Percentage of successful runs


### Graphical test: Plot the mean and range of variation of abs returns skewness
# Objective: Study the range of variation of skewness over experiments

Max_skew <- array(0, dim=c(nExp, nAssets))  # Arrays to store the max and min skewness over all runs (for each asset and experiment)
Min_skew <- array(0, dim=c(nExp, nAssets))
Mean_skew <- array(0, dim=c(nExp, nAssets))  # Array to store the mean skewness over all runs (for each asset and experiment)
Stdev_skew <- array(0, dim=c(nExp, nAssets))  # Array to store the standard deviation of skewness over all runs (for each asset and experiment)

asset_skewness_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the skewness for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with skewness of asset i for each run         
	   asset_skewness_vector[,j+1] = skewness(abs(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]])), na.rm = FALSE, method="moment")[1]   # Store values of skewness
      }
      Max_skew[k+1,i] = max(asset_skewness_vector)  # Select max/min skewness over all runs
      Min_skew[k+1,i] = min(asset_skewness_vector)
      Mean_skew[k+1,i] = mean(asset_skewness_vector)
      Stdev_skew[k+1,i] = sd(asset_skewness_vector[1,])
   }
}

# Plot mean, minimum, and maximum skewness

y_min = min(Min_skew)   # Range of y axis
y_max = max(Max_skew)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
#   dev.new()         # Plots each figure in a new window
   xx <- c(1:nExp, nExp:1)   # Needed to shade the area between max and min
   yy <- c(Min_skew[,i], rev(Max_skew[,i]))
   plot(xx,yy, type="l", main=paste("Asset", i), col="black", 
	xlab="Experiment", ylab="Max/Min skewness", lwd=1, ylim=c(y_min,y_max))
   polygon(xx, yy, col="gray")
   lines(Mean_skew[,i], type="l", col="black", lwd=2)
   lines(Mean_skew[,i]+Stdev_skew[,i], type="l", col="red2")   # Plot +-1stdev to have an idea of the variability
   lines(Mean_skew[,i]-Stdev_skew[,i], type="l", col="red2")
}
title("VA-TF_ABM-1.6.2 - Range of variation of abs returns skewness", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the mean/max/min values of volatility skewness. It should be positive.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


## To provide information in the x axis on e.g. the percentage of HF's: create a vector with the percentages, e.g.:
## x <- c(0.1, 0.2, 0.3, 0.4, 0.5)
## plot(x, Max_skew[,i], [...])




#__________________________________________________________#
#                                                          #
#              TEST VA-TF_ABM-1.7: UNIT ROOT               #
#__________________________________________________________#
#                                                          #

### Quantitative test: Measure in how many runs there is a unit root
#
# The standard test for this property is the Dickey-Fuller test, which 
# in the presence of a unit root is not rejected 

cat("\n --- VA-TF_ABM-1.7.1: Unit root of log prices (with Augmented Dickey-Fuller test) --- \n")
cat("\n Test description: When there is a unit root in prices (that is, prices follow an autoregressive process) the Dickey-Fuller test is not rejected. \n\n")

require(tseries)
failed=-1  # Stores runs where the Dickey-Fuller test has been rejected

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         unitroot <- adf.test(tslogprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]])  # Non-rejection of the test (pvalue higher than e.g. 0.05) indicates there is a unit root
         if (unitroot$p.value < 0.05) {
             failed <- append(failed, i+1)
             cat(paste("VA-TF_ABM-1.6.1: Unit root failed in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }
         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e, "]", ": p-value = ", unitroot$p.value, "\n"))  # Write the result of each single run to a file
      }
   }
}

percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of VA-TF_ABM-1.7.1: ", percentage_success, "% \n")  # Percentage of successful runs


### Graphical representation: cdplot of runs where there is a unit root in log prices
#
# Objective: Count in how many runs there is a unit root (that is, the 
# Augmented Dickey-Fuller test is not rejected)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (i in seq(from=1, to=nAssets)) {

   # Count in how many runs the Augmented Dickey-Fuller test is not rejected (at confidence level 95%)
   ADF_accepted <- array(0, dim=c(nExp, nRuns))
   
   for (k in seq(from=0, to=nExp-1)) {
      for (j in seq(from=0, to=nRuns-1)) {
         if ( adf.test(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]])$p.value > 0.05 ) {
            ADF_accepted[k+1,j+1] = 1
         }
      }
   }

   # Convert numeric vector to factor to draw cdplot
   unitroot <- factor(ADF_accepted, levels = 0:1, labels = c("no", "yes"))

   # Draw cdplot
   x_axis <- rep(1:nExp,nRuns)
   cdplot(unitroot~x_axis, xlab="Experiment", ylab="Unit root?", main=paste("Asset ", i), col=c("red3", "palegreen"))
}
title("VA-TF_ABM-1.7.1 - Unit root in log prices", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: There is a unit root in the series of (log) prices, that is, prices are autoregressive (used ADF test)", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



#__________________________________________________________#
#                                                          #
#            TEST VA-TF_ABM-1.8: TAYLOR EFFECT             #
#__________________________________________________________#
#                                                          #

# The "Taylor Effect" describes the fact that absolute returns of speculative 
# assets have significant serial correlation over long lags. Even more, 
# autocorrelations of absolute returns are typically greater than those of 
# squared returns. From these observations the Taylor effect states, that
# the autocorrelations of absolute returns to the the power of delta,
# |x-mean(x)|^delta reach their maximum at delta=1. 

# Objective: For each experiment, plot autocorrelations of absolute returns 
# to the the power of delta as a function of the exponent delta for single 
# runs to study the Taylor effect. If the Taylor effect is satisfied, then 
# all the curves should peak at the same value around delta=1.


for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
       par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             teffectPlot(diff(tslogprices[[k+1+i+(e-1)*nAssets*nRuns]]), deltas = seq(from = 0.2, to = 4, by = 0.2))
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            teffectPlot(diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]), deltas = seq(from = 0.2, to = 4, by = 0.2))
          }
      }
      title(paste("VA-TF_ABM-1.8.1 - Taylor effect - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: All the curves should peak around delta=1.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


#____________________________________________________________#
#                                                            #
#            TEST VA-TF_ABM-1.9: LEVERAGE EFFECT             #
#____________________________________________________________#
#                                                            # 

# Graphical test: There is a negative correlation between volatility and past returns,
# indicating that negative returns lead to a rise in volatility. This negative correlation
# decays slowly to 0. However, the causal relation does not work in the other direction: 
# the correlation between volatility and future returns is close to zero.
#
# Objective: For each experiment, plot a cross-correlation function of volatility and
# (as squared log returns) and returns for single runs to study the correlation for different lags

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
       par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             ccf((diff(tslogprices[[k+1+i+(e-1)*nAssets*nRuns]]))^2, diff(tslogprices[[k+1+i+(e-1)*nAssets*nRuns]]), ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            ccf((diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]))^2, diff(tslogprices[[i+k +(e-1)*nAssets*nRuns]]), ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
          }
      }
      title(paste("VA-TF_ABM-1.9.1 - Leverage effect (corr. returns-volatility) - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: CCF should be 0 for lags<0, and negative and slow decaying to 0 for lags>0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}




#############################################################################
#                                                                           #
#                             ADDITIONAL ANALYSES                           #
#                                                                           #
#############################################################################

#______________________________________________#
#                                              #
#           DO PRICES TEND TO VALUE?           #
#______________________________________________#
#                                              #

# FUND investors should push prices towards values.
# We plot here the mean price and values (over runs) of each asset
# to study if prices tend to the fundamental value over experiments


### Plot of prices vs values (averaged over runs)

y_max = max(max(tsvalues_avg[,1:(nAssets*nExp)]), max(tsprices_avg[,1:(nAssets*nExp)]))
y_min = min(min(tsvalues_avg[,1:(nAssets*nExp)]), min(tsprices_avg[,1:(nAssets*nExp)]))

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      plot(tsprices_avg[,(e-1)*nAssets+k], type="l", main="", ylim=c(y_min,y_max), xlab="Tick", ylab="")
      lines(tsvalues_avg[,(e-1)*nAssets+k], type="l", col="red")
   }
   title(paste("Average prices vs values (over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   #legend("bottomleft", c("Precio","Valor"), lty=c(1,1), lwd=c(3,3), col=c("black", "red"))
   mtext("Objective: Study if mean prices are pushed toward mean values (over experiments).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Plot of prices vs values (for individual runs)

#y_max = max(max(tsvalues[,2:(nAssets*nRuns*nExp+1)]), max(tsprices[,2:(nAssets*nRuns*nExp+1)]))
#y_min = min(min(tsvalues[,2:(nAssets*nRuns*nExp+1)]), min(tsprices[,2:(nAssets*nRuns*nExp+1)]))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
#            plot(tsprices[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Decimal price and value", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max))
#            lines(tsvalues[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="red")
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(tsprices[[i+k+(e-1)*nAssets*nRuns]], type="l", ylab="Decimal price and value", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max))
#            lines(tsvalues[[i+k+(e-1)*nAssets*nRuns]], type="l", col="red")  
#         }
#      }
#      title(paste("Decimal price and value - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}


### Calculate distance of each price series to value

dist_prices_values <- array(0, dim=c(nExp, nAssets))   # Array to store the mean distance between price and fundamental value over all runs (for each asset and experiment)
distance_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the distance d(P,V) for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with distance d(P,V) of asset i for each run
         distance_vector[,j+1] = sqrt(sum((tsprices[[i+1+j*nAssets+k*nAssets*nRuns]] - tsvalues[[i+1+j*nAssets+k*nAssets*nRuns]])^2))/nTicks
      }
      dist_prices_values[k+1,i] = mean(distance_vector)
   }
}


# Plot distance of each asset price to values (for each experiment)

# To provide information in the x axis on e.g. the percentage of HF's or FUND's: create a vector with the percentages, e.g.:
# x <- c(0.1, 0.2, 0.3, 0.4, 0.5)
# matplot(x, dist_prices, type="l", lty=1, col="black")

par(mfrow=c(1,1), mar=c(5,4,6,1), oma=c(2,2,2,2), mgp=c(3,1,0))  # Margins adjusted so that title and axes labels are properly shown
matplot(dist_prices_values, type="l", lty=1, col = 1:10, xlab="Experiment", main="Distance of asset prices to values", col.main="blue")
legend("topleft", c("Asset 1","Asset 2", "Asset 3"), lty=c(1,1), col=1:10)
mtext("Objective: Study if distance between mean prices and mean values decreases (over experiments).", side=3, line=-5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=5, cex=0.75)  # Add parameter file



#________________________________________________________#
#                                                        #
#           COINTEGRATION OF PRICES AND VALUES           #
#________________________________________________________#
#                                                        #

# Farmer and Joshi argue for the introduction of entry/exit thresholds in the
# trading strategies saying that these cointegrate prices and values, and
# so prices track the fundamental values. 
# We test here for the cointegration of the time series of prices and values
# to see if they are cointegrated and if this property changes along experiments.


# .................. Function to test cointegration .......................

# This function is taken from the script "Testing_cointegration.R" within the folder
# "\Dropbox\Modelling journeys\Long-short incident of August 2007\Chunks\Active\C2.1 - Long-short (LS) exploratory evaluation"
#
# This function tests the  cointegration of two series, using the Augmented Dickey-Fuller test
# The implementation used here is based on:  http://quanttrader.info/public/testForCoint.html

cointegration_test <- function(series1, series2) {

     library(tseries)         # Load the tseries package
   
   # The lm function builds linear regression models using OLS.
   # We build the linear model, m, forcing a zero intercept,
   # then we extract the model's first regression coefficient.

     m <- lm(series1 ~ series2 + 0)
     beta <- coef(m)[1]
     ##cat("Assumed hedge ratio is", beta, "\n")

   # Now compute the spread

     spread <- series1 - beta*series2

   # Test cointegration with Dickey-Fuller test
   # Null hypothesis is that the spread is non-stationary or explosive.
   # Setting k=0 forces a basic (not augmented) test.

     result <- adf.test(spread, alternative="stationary", k=0)
     return(result)
}

# ............................................................................


### Quantitative test: Measure in how many runs there is cointegration between price and value

cat("\n --- Cointegration of prices and values --- \n")

failed=-1  # Stores runs where price and value are not cointegrated

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      for (i in seq(from=0, to=nRuns-1)) {
         test_result_spread <- cointegration_test(tsprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]], tsvalues[[k+1+i*nAssets +(e-1)*nAssets*nRuns]])
         if (test_result_spread$p.value < 0.05) {
             failed <- append(failed, i+1)
             cat(paste("Price and value not cointegrated in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
         }
         #cat(paste("[ A=", k, ", R=", i+1, ", E=", e, "]", ": p-value = ", test_result_spread$p.value, "\n"))  # Write the result of each single run to a file
      }
   }
}

percentage_success = (1-((length(failed)-1)/(nAssets*nRuns*nExp))) * 100
cat("\n % SUCCESS of cointegration between price and value: ", percentage_success, "% \n")  # Percentage of successful runs


### Graphical representation: cdplot of runs where price and value are cointegrated

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (i in seq(from=1, to=nAssets)) {

   # Count in how many runs there is cointegration between prices and values
   test_accepted <- array(0, dim=c(nExp, nRuns))
   
   for (e in seq(from=1, to=nExp)) {
      for (j in seq(from=0, to=nRuns-1)) {
         test_result_spread <- cointegration_test(tsprices[[i+1+j*nAssets +(e-1)*nAssets*nRuns]], tsvalues[[i+1+j*nAssets +(e-1)*nAssets*nRuns]])
         if ( test_result_spread$p.value > 0.05 ) {
            test_accepted[e,j+1] = 1
         }
      }
   }

   # Convert numeric vector to factor to draw cdplot
   cointegration <- factor(test_accepted, levels = 0:1, labels = c("no", "yes"))

   # Draw cdplot
   x_axis <- rep(1:nExp,nRuns)
   cdplot(cointegration~x_axis, xlab="Experiment", ylab="Cointegrated?", main=paste("Asset ", i))
}
title("Cointegration between prices and fundamental values", outer = TRUE, col.main="blue", font.main=2)
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



#____________________________________________________________#
#                                                            #
#                  SPREAD vs HISTORICAL MEAN                 #
#____________________________________________________________#
#                                                            #

# Objective: As LS strategies push the spread towards its mean value,
# we plot here the spread between asset 1 and 2 versus its historical mean to
# study if an increasing percentage of LS (different experiments) makes a difference

# !! Only spread for assets 1 and 2 is considered. Add code
# if there are more assets in the market

tsspread_12 <- array(0, dim=c(nTicks, nExp*nRuns))
tsspread_12_histmean <- array(0, dim=c(nTicks, nExp*nRuns))
tsspread_12_avg <- array(0, dim=c(nTicks, nExp))
tsspread_12_histmean_avg <- array(0, dim=c(nTicks, nExp))

tszero <- array(0, dim=c(nTicks, 1))
meanWindow = 225

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nRuns)) {
      tsspread_12[,(e-1)*nRuns+k] <- tsprices[[1+1+(e-1)*nAssets*nRuns+(k-1)*nAssets]] - tsprices[[1+2+(e-1)*nAssets*nRuns+(k-1)*nAssets]]
      tsspread_12_histmean[,(e-1)*nRuns+k] <- SMA(tsspread_12[,(e-1)*nRuns+k], n=meanWindow)
   }
}

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nRuns)) {
      tsspread_12_avg[,e] <- tsspread_12_avg[,e] + tsspread_12[,(e-1)*nRuns+k]
      tsspread_12_histmean_avg[,e] <- tsspread_12_histmean_avg[,e] + tsspread_12_histmean[,(e-1)*nRuns+k]
   }
   tsspread_12_avg[,e] <- tsspread_12_avg[,e]/nRuns
   tsspread_12_histmean_avg[,e] <- tsspread_12_histmean_avg[,e]/nRuns
}


### Plot of time series of spread vs historical mean (averaged over runs)

y_max = max(tsspread_12_avg[,1:nExp])
y_min = min(tsspread_12_avg[,1:nExp])

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))

for (e in seq(from=1, to=nExp)) {
   plot(tsspread_12_avg[,e], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="", col="black")
   lines(tsspread_12_histmean_avg[,e], type="l", col="blue")
   lines(tszero[,1], type="l", col="gray")  # Plot a horizontal line at 0 to better see if spread tends to 0
}
title(paste("Spread A1-A2 and its historical mean (avg. over runs)"), outer = TRUE, col.main="blue", font.main=2)
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Plot of time series of spread vs historical mean (for individual runs)

y_max = max(tsspread_12[,1:nExp*nRuns])
y_min = min(tsspread_12[,1:nExp*nRuns])

step_cor <- as.integer(nRuns/(numRows*numCols))  # Selects which plots to draw if there are too many

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){
      for (i in seq(from=step_cor, to=step_cor*numRows*numCols, by=step_cor)) {
         plot(tsspread_12[,i+1 +(e-1)*nRuns-1], type="l", main=paste("Run", i), ylim=c(y_min,y_max), xlab="Tick", ylab="", col="black")
         lines(tsspread_12_histmean[,i+1 +(e-1)*nRuns-1], type="l", col="blue")
         lines(tszero[,1], type="l", col="gray")  # Plot a horizontal line at 0 to better see if spread tends to 0
      }
   } else {
      for (i in seq(from=1, to=nRuns)) {
         plot(tsspread_12[,i+1 +(e-1)*nRuns-1], type="l", main=paste("Run", i), ylim=c(y_min,y_max), xlab="Tick", ylab="", col="black")
         lines(tsspread_12_histmean[,i+1 +(e-1)*nRuns-1], type="l", col="blue")
         lines(tszero[,1], type="l", col="gray")  # Plot a horizontal line at 0 to better see if spread tends to 0
      }
   }
   title(paste("Spread A1-A2 and its historical mean ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Calculate distance of spread A1-A2 to its historical mean

dist_spread <- array(0, dim=c(nExp, 1))  # Array to store the mean distance between the spread and its historical mean (for each experiment)
distance_vector <- array(0, dim=c(1, nRuns))   # Auxiliary vector to store the distance d(S,mean(S)) for A1-A2 (over all runs)

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nRuns)) {     # Calculate vector with distance d(S, mean(S)) of assets A1-A2 for each run
      distance_vector[,k] = sqrt(sum((tsspread_12[,(e-1)*nRuns+k] - tsspread_12_histmean[,(e-1)*nRuns+k])^2, na.rm=TRUE))
   }
   dist_spread[e,1] = mean(distance_vector)
}


# Plot distance of spread to its historical mean (for each experiment)

par(mfrow=c(1,1), mar=c(5,4,6,1), oma=c(2,2,2,2), mgp=c(3,1,0))  # Margins adjusted so that title and axes labels are properly shown
matplot(dist_spread, type="l", lty=1, col = 1:10, xlab="Experiment", main="Distance of spread to historical mean", col.main="blue")
mtext("Objective: Study if distance between spread and its historical mean decreases (over experiments).", side=3, line=-5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=5, cex=0.75)  # Add parameter file



#____________________________________________________________#
#                                                            #
#                   DISTANCE BETWEEN ASSETS                  #
#____________________________________________________________#
#                                                            #

# Objective: As LS strategies trade on the spread, we plot here the
# distance between asset 1 and 2 to study if it diminishes when there
# are more LS agents in the market

# !! Only spread for assets 1 and 2 is considered. Add code
# if there are more assets in the market


### Plot of time series of prices (averaged over runs)

y_max = max(tsprices_avg[,1:(nAssets*nExp)])
y_min = min(tsprices_avg[,1:(nAssets*nExp)])

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(tsprices_avg[,1+(e-1)*nAssets], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="A1 vs A2")
   lines(tsprices_avg[,2+(e-1)*nAssets], type="l", col="blue")
}
title(paste("Average prices of assets A1 (black) and A2 (blue) (over runs)"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Objective: Study if mean prices get closer (over experiments).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Plot of time series of prices (for individual runs)

y_max = max(tsprices[,2:(nAssets*nRuns*nExp+1)])
y_min = min(tsprices[,2:(nAssets*nRuns*nExp+1)])

for (e in seq(from=1, to=nExp)) {

      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
            plot(tsprices[[1+i+1 +(e-1)*nAssets*nRuns]], type="l", ylab="A1 vs A2", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max))
            lines(tsprices[[2+i+1 +(e-1)*nAssets*nRuns]], type="l", col="blue")
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            plot(tsprices[[1+i+(e-1)*nAssets*nRuns]], type="l", ylab="A1 vs A2", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max))
            lines(tsvalues[[2+i+(e-1)*nAssets*nRuns]], type="l", col="blue")
         }
      }
      title(paste("Prices of assets A1 (black) and A2 (blue) ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Calculate distance between assets A1-A2

dist_assets <- array(0, dim=c(nExp, 1))        # Array to store the mean distance between the prices of A1 and A2 (for each experiment)
distance_vector <- array(0, dim=c(1, nRuns))   # Auxiliary vector to store the distance d(A1, A2) (over all runs)

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nRuns)) {     # Calculate vector with distance between assets A1-A2 for each run
      distance_vector[,k] = sqrt(sum((tsprices[[1+1+(e-1)*nAssets*nRuns+(k-1)*nAssets]] - tsprices[[1+2+(e-1)*nAssets*nRuns+(k-1)*nAssets]])^2, na.rm=TRUE))
   }
   dist_assets[e,1] = mean(distance_vector)
}

# Plot distance of between asseta A1-A2 (for each experiment)

par(mfrow=c(1,1), mar=c(5,4,6,1), oma=c(2,2,2,2), mgp=c(3,1,0))  # Margins adjusted so that title and axes labels are properly shown
matplot(dist_assets, type="l", lty=1, col = 1:10, xlab="Experiment", main="Distance between assets A1 and A2", col.main="blue")
mtext("Objective: Study if distance between assets decreases (over experiments).", side=3, line=-5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=5, cex=0.75)  # Add parameter file



#_________________________________________________________________#
#                                                                 #
#           COINTEGRATION OF PRICES OF DIFFERENT ASSETS           #
#_________________________________________________________________#
#                                                                 #

# We test here for the cointegration of the time series of prices of different assets
# to see if they are cointegrated (because of the action of LS traders) and if this 
# property changes along experiments.

# We test the cointegration between the price of asset 1 and the price of the rest of 
# assets, because the pairs are always defined as 'asset_1 - asset_k'.

### Quantitative test: Measure in how many runs there is cointegration between prices

cat("\n --- Cointegration of prices --- \n")

failed=-1  # Stores runs where prices are not cointegrated

if (nAssets >=2) {
   for (e in seq(from=1, to=nExp)) {
      for (k in seq(from=2, to=nAssets)) {
         for (i in seq(from=0, to=nRuns-1)) {
            test_result_spread <- cointegration_test(tsprices[[1+1+i*nAssets +(e-1)*nAssets*nRuns]], tsprices[[k+1+i*nAssets +(e-1)*nAssets*nRuns]])
            if (test_result_spread$p.value < 0.05) {
                failed <- append(failed, i+1)
                cat(paste("Prices are not cointegrated in [ A=", k, ", R=", i+1, ", E=", e, "]", "\n"))  # Write the runs where the test failed to a file
            }
            #cat(paste("[ A=", k, ", R=", i+1, ", E=", e, "]", ": p-value = ", test_result_spread$p.value, "\n"))  # Write the result of each single run to a file
         }
      }
   }
}

percentage_success = (1-((length(failed)-1)/((nAssets-1)*nRuns*nExp))) * 100
cat("\n % SUCCESS of cointegration between prices: ", percentage_success, "% \n")  # Percentage of successful runs


### Graphical representation: cdplot of runs where prices are cointegrated

par(mfrow=c((nAssets-1),1), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (i in seq(from=2, to=nAssets)) {

   # Count in how many runs there is cointegration between prices
   test_accepted <- array(0, dim=c(nExp, nRuns))
   
   for (e in seq(from=1, to=nExp)) {
      for (j in seq(from=0, to=nRuns-1)) {
         test_result_spread <- cointegration_test(tsprices[[1+1+j*nAssets +(e-1)*nAssets*nRuns]], tsprices[[i+1+j*nAssets +(e-1)*nAssets*nRuns]])
         if ( test_result_spread$p.value > 0.05 ) {
            test_accepted[e,j+1] = 1
         }
      }
   }

   # Convert numeric vector to factor to draw cdplot
   cointegration <- factor(test_accepted, levels = 0:1, labels = c("no", "yes"))

   # Draw cdplot
   x_axis <- rep(1:nExp,nRuns)
   cdplot(cointegration~x_axis, xlab="Experiment", ylab="Cointegrated?", main=paste("Assets 1 & ", i))
}
title("Cointegration between prices", outer = TRUE, col.main="blue", font.main=2)
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



#___________________________________________________________#
#                                                           #
#             CORRELATIONS BETWEEN ASSET PRICES             #
#___________________________________________________________#
#                                                           #

### Correlation matrix of asset prices (averaged over runs)
#
# Objective: Study if the introduction of LS traders induces correlations between
# the prices of assets that make a pair

panel.cor <- function(x, y, digits=2, prefix="", cex.cor)
{
    usr <- par("usr"); on.exit(par(usr))
    par(usr = c(0, 1, 0, 1))
    r <- abs(cor(x, y))
    txt <- format(c(r, 0.123456789), digits=digits)[1]
    txt <- paste(prefix, txt, sep="")
    if(missing(cex.cor)) cex <- 0.8/strwidth(txt)
    
    test <- cor.test(x,y)
    # borrowed from printCoefmat
    Signif <- symnum(test$p.value, corr = FALSE, na = FALSE,
                  cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
                  symbols = c("***", "**", "*", ".", " "))
    
    text(0.5, 0.5, txt, cex = cex * r)
    text(.8, .8, Signif, cex=cex, col=2)
}

for (e in seq(from=1, to=nExp)) {   
   indices <- seq(from=(e-1)*nAssets+1, to=(e-1)*nAssets+nAssets)
   pairs(tslogprices_avg[,indices], labels = c("Asset 1", "Asset 2", "Asset 3"), oma=c(5,5,7,5), lower.panel=panel.smooth, upper.panel=panel.cor)

   title(paste("Correlations between prices of different assets (averaged over runs) ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Objective: Study if the action of LS traders induces correlations in prices of different assets.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Schematic (ellipse) correlation matrix of pairs of asset prices (averaged over runs)
#
# Objective: Study if the introduction of LS traders induces correlations between
# the prices of assets that make a pair. In this case, the correlation matrix is
# schematised with ellipses.

# "The plotcorr function plots a correlation matrix using ellipse-shaped 
# glyphs for each entry. The ellipse represents a level curve of the density 
# of a bivariate normal with the matching correlation." 
# (http://addictedtor.free.fr/graphiques/graphcode.php?graph=149)

library(package="ellipse")

for (e in seq(from=1, to=nExp)) {
   indices <- seq(from=(e-1)*nAssets+1, to=(e-1)*nAssets+nAssets)
   corr.prices <- cor(tsprices_avg[,indices])
   ord <- order(corr.prices[1,])
   xc <- corr.prices[ord, ord]
   colors <- c("#A50F15","#DE2D26","#FB6A4A","#FCAE91","#FEE5D9","white",
     "#EFF3FF","#BDD7E7","#6BAED6","#3182BD","#08519C")
   plotcorr(xc, col=colors[5*xc + 6], main = "")

   title(paste("Correlations between prices of different assets (averaged over runs) ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Study if the action of LS traders induces correlations in prices of different assets.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
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
   #legend("topleft", c("Fundamentalistas","Técnicos", "Long-short"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen", "royalblue3"))
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

y_max = max(max(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)]), max(tsLSwealth[,2:(nAssets*nRuns*nExp+1)]))
y_min = min(min(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)]), min(tsLSwealth[,2:(nAssets*nRuns*nExp+1)]))

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


### Bar charts of FUND/TREND/LS final wealth for EACH individual run
#
# Objective: Compare the relative wealth accumulated by each group of traders
# at the end of the simulation

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows, numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
            wealth <- c(tsFUNDwealth[[k+1+i +(e-1)*nAssets*nRuns]][nTicks], tsTRENDwealth[[k+1+i +(e-1)*nAssets*nRuns]][nTicks], tsLSwealth[[k+1+i +(e-1)*nAssets*nRuns]][nTicks])
            labels <- c("FUND", "TREND", "LS") 
            barplot(wealth, names = labels, col=c("darkorange1", "seagreen", "royalblue3"), main=paste("Run", 1+i/nAssets))
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            wealth <- c(tsFUNDwealth[[k+i +(e-1)*nAssets*nRuns]][nTicks], tsTRENDwealth[[k+i +(e-1)*nAssets*nRuns]][nTicks], tsLSwealth[[k+i +(e-1)*nAssets*nRuns]][nTicks])
            labels <- c("FUND", "TREND", "LS") 
            barplot(wealth, names = labels, col=c("darkorange1", "seagreen", "royalblue3"), main=paste("Run", 1+(i-1)/nAssets))
         }
      }
      title(paste("Final wealth along simulations - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Objective: Compare the final wealth accumulated by each strategy.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


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



##_____________________________________________________________________________________#
##                                                                                     #
##           PERFORMANCE OF FUNDs vs TRENDs vs LS's  - AGGREGATED OVER ASSETS          #
##_____________________________________________________________________________________#
##                                                                                     #  
#
## !!! EXTREMELY EXPENSIVE TO DRAW THESE PLOTS
#
#### Plot of FUND, TREND and LS wealth aggregated for all the assets (for individual runs)
#
#y_max_FUND = 3 * max(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)])
#y_min_FUND = 3 * min(tsFUNDwealth[,2:(nAssets*nRuns*nExp+1)])
#
#y_max_TREND = 3 * max(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)])
#y_min_TREND = 3 * min(tsTRENDwealth[,2:(nAssets*nRuns*nExp+1)])
#
#y_max_LS = 3 * max(tsLSwealth[,2:(nAssets*nRuns*nExp+1)])
#y_min_LS = 3 * min(tsLSwealth[,2:(nAssets*nRuns*nExp+1)])
#
#for (e in seq(from=1, to=nExp)) {
#
#   ##  ......... FUNDs ......... ##
#
#   # Plot graphics in a grid ('par' cannot be used with ggplot)
#   grid.newpage()
#   pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#   vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#   if (nRuns>numRows*numCols){   
#      for (i in seq(from=step, to=step*numRows*numCols, by=step)) { 
#
#         # Create dataframe of wealth on each asset (contribution to plot stacked area graphic)
#         df = data.frame(seq(1:nTicks), tsFUNDwealth[1:nTicks, i+1+1+(e-1)*nAssets*nRuns], 
#	     	   tsFUNDwealth[1:nTicks, i+2+1+(e-1)*nAssets*nRuns], 
#              tsFUNDwealth[1:nTicks, i+3+1+(e-1)*nAssets*nRuns])
#         colnames(df) <- c("tick", "A1", "A2", "A3")
#
#	   df <- reshape(df, varying = c("A1", "A2", "A3"), v.names = "wealth", timevar = "group", 
# 	        times = c("A1", "A2", "A3"), direction = "long")
#
#         # Aggregate wealth for each asset in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=wealth, fill=group)) + geom_area(position = 'stack') +
#		 labs(x = "Tick", y = "Aggregate wealth", title = "") + 
#		scale_fill_manual(values=brewer.pal(3,"Oranges"), name = paste("FUNDs", "\n", "R", 1+i/nAssets, ", E", e), 
#		breaks = c("A1", "A2", "A3"), labels = c("A1", "A2", "A3")) + 
#            ylim(y_min_FUND,y_max_FUND)
#
# 	   # Display graphics in a grid
#	   col = (i/step) %% numCols   
#         col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor((i/step-1)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   } else {
#      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#
#         # Create dataframe of wealth on each asset (contribution to plot stacked area graphic)
#    	   df = data.frame(seq(1:nTicks), tsFUNDwealth[1:nTicks, i+1+(e-1)*nAssets*nRuns], 
#	     	   tsFUNDwealth[1:nTicks, i+2+(e-1)*nAssets*nRuns], 
#               tsFUNDwealth[1:nTicks, i+3+(e-1)*nAssets*nRuns])
#     	   colnames(df) <- c("tick", "A1", "A2", "A3")
#
#	   df <- reshape(df, varying = c("A1", "A2", "A3"), v.names = "wealth", timevar = "group", 
# 		  times = c("A1", "A2", "A3"), direction = "long")
#
#         # Aggregate wealth for each asset in stacked area plot
#    	   graph = ggplot(df, aes(x=tick, y=wealth, fill=group)) + geom_area(position = 'stack') +
#	     	   labs(x = "Tick", y = "Aggregate wealth", title = "") + 
#		   scale_fill_manual(values=brewer.pal(3,"Oranges"), name = paste("FUNDs", "\n", "R", 1+(i-1)/nAssets, ", E", e), 
#               breaks = c("A1", "A2", "A3"), labels = c("A1", "A2", "A3")) + 
#               ylim(y_min_FUND,y_max_FUND)
#
#	   # Display graphics in a grid
#	   col = (1+(i-1)/nAssets) %% numCols   
#         col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor(((i-1)/nAssets)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   }
#
#
#   ##  ......... TRENDs ......... ##
#
#   # Plot graphics in a grid ('par' cannot be used with ggplot)
#   grid.newpage()
#   pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#   vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#   if (nRuns>numRows*numCols){   
#      for (i in seq(from=step, to=step*numRows*numCols, by=step)) { 
#
#         # Create dataframe of wealth on each asset (contribution to plot stacked area graphic)
#         df = data.frame(seq(1:nTicks), tsTRENDwealth[1:nTicks, i+1+1+(e-1)*nAssets*nRuns], 
#	     	   tsTRENDwealth[1:nTicks, i+2+1+(e-1)*nAssets*nRuns], 
#               tsTRENDwealth[1:nTicks, i+3+1+(e-1)*nAssets*nRuns])
#         colnames(df) <- c("tick", "A1", "A2", "A3")
#
#	   df <- reshape(df, varying = c("A1", "A2", "A3"), v.names = "wealth", timevar = "group", 
# 	        times = c("A1", "A2", "A3"), direction = "long")
#
#         # Aggregate wealth for each asset in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=wealth, fill=group)) + geom_area(position = 'stack') +
#		 labs(x = "Tick", y = "Aggregate wealth", title = "") + 
#		scale_fill_manual(values=brewer.pal(3,"Greens"), name = paste("TRENDs", "\n", "R", 1+i/nAssets, ", E", e), 
#		breaks = c("A1", "A2", "A3"), labels = c("A1", "A2", "A3")) + 
#            ylim(y_min_TREND,y_max_TREND)
#
# 	   # Display graphics in a grid
#	   col = (i/step) %% numCols   
#         col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor((i/step-1)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   } else {
#      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#
#         # Create dataframe of wealth on each asset (contribution to plot stacked area graphic)
#    	   df = data.frame(seq(1:nTicks), tsTRENDwealth[1:nTicks, i+1+(e-1)*nAssets*nRuns], 
#	     	   tsTRENDwealth[1:nTicks, i+2+(e-1)*nAssets*nRuns], 
#               tsTRENDwealth[1:nTicks, i+3+(e-1)*nAssets*nRuns])
#     	   colnames(df) <- c("tick", "A1", "A2", "A3")
#
#	   df <- reshape(df, varying = c("A1", "A2", "A3"), v.names = "wealth", timevar = "group", 
# 		  times = c("A1", "A2", "A3"), direction = "long")
#
#         # Aggregate wealth for each asset in stacked area plot
#    	   graph = ggplot(df, aes(x=tick, y=wealth, fill=group)) + geom_area(position = 'stack') +
#	     	   labs(x = "Tick", y = "Aggregate wealth", title = "") + 
#		   scale_fill_manual(values=brewer.pal(3,"Greens"), name = paste("TRENDs", "\n", "R", 1+(i-1)/nAssets, ", E", e), 
#               breaks = c("A1", "A2", "A3"), labels = c("A1", "A2", "A3")) + 
#               ylim(y_min_TREND,y_max_TREND)
#
#	   # Display graphics in a grid
#	   col = (1+(i-1)/nAssets) %% numCols   
#         col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor(((i-1)/nAssets)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   }
#
#
#   ##  ......... LSs ......... ##
#
#   # Plot graphics in a grid ('par' cannot be used with ggplot)
#   grid.newpage()
#   pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#   vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#   if (nRuns>numRows*numCols){   
#      for (i in seq(from=step, to=step*numRows*numCols, by=step)) { 
#
#         # Create dataframe of wealth on each asset (contribution to plot stacked area graphic)
#         df = data.frame(seq(1:nTicks), tsLSwealth[1:nTicks, i+1+1+(e-1)*nAssets*nRuns], 
#	     	   tsLSwealth[1:nTicks, i+2+1+(e-1)*nAssets*nRuns], 
#               tsLSwealth[1:nTicks, i+3+1+(e-1)*nAssets*nRuns])
#         colnames(df) <- c("tick", "A1", "A2", "A3")
#
#	   df <- reshape(df, varying = c("A1", "A2", "A3"), v.names = "wealth", timevar = "group", 
# 	        times = c("A1", "A2", "A3"), direction = "long")
#
#         # Aggregate wealth for each asset in stacked area plot
#         graph = ggplot(df, aes(x=tick, y=wealth, fill=group)) + geom_area(position = 'stack') +
#		 labs(x = "Tick", y = "Aggregate wealth", title = "") + 
#		scale_fill_manual(values=brewer.pal(3,"Blues"), name = paste("LSs", "\n", "R", 1+i/nAssets, ", E", e), 
#		breaks = c("A1", "A2", "A3"), labels = c("A1", "A2", "A3")) + 
#            ylim(y_min_LS,y_max_LS)
#
# 	   # Display graphics in a grid
#	   col = (i/step) %% numCols   
#         col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor((i/step-1)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   } else {
#      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#
#         # Create dataframe of wealth on each asset (contribution to plot stacked area graphic)
#    	   df = data.frame(seq(1:nTicks), tsLSwealth[1:nTicks, i+1+(e-1)*nAssets*nRuns], 
#	     	   tsLSwealth[1:nTicks, i+2+(e-1)*nAssets*nRuns], 
#               tsLSwealth[1:nTicks, i+3+(e-1)*nAssets*nRuns])
#     	   colnames(df) <- c("tick", "A1", "A2", "A3")
#
#	   df <- reshape(df, varying = c("A1", "A2", "A3"), v.names = "wealth", timevar = "group", 
# 		  times = c("A1", "A2", "A3"), direction = "long")
#
#         # Aggregate wealth for each asset in stacked area plot
#    	   graph = ggplot(df, aes(x=tick, y=wealth, fill=group)) + geom_area(position = 'stack') +
#	     	   labs(x = "Tick", y = "Aggregate wealth", title = "") + 
#		   scale_fill_manual(values=brewer.pal(3,"Blues"), name = paste("LSs", "\n", "R", 1+(i-1)/nAssets, ", E", e), 
#               breaks = c("A1", "A2", "A3"), labels = c("A1", "A2", "A3")) + 
#               ylim(y_min_LS,y_max_LS)
#
#	   # Display graphics in a grid
#	   col = (1+(i-1)/nAssets) %% numCols   
#         col = col + numCols * (col==0)   # Columns cannot take value 0
#	   row = floor(((i-1)/nAssets)/numCols) + 1
#	   print(graph,vp=vplayout(row,col))
#      }
#   }
#}
#


#### Plot of FUND, TREND and LS wealth aggregated for all the assets (averaged over runs)
#
###  ......... FUNDs ......... ##
#
## Plot graphics in a grid ('par' cannot be used with ggplot)
#grid.newpage()
#pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#y_max_FUND = 3 * max(tsFUNDwealth_avg)
#y_min_FUND = 3 * min(tsFUNDwealth_avg)
#
#for (e in seq(from=1, to=nExp)) {
#
#   # Create dataframe of avg wealth on each asset (contribution to plot stacked area graphic)
#   df = data.frame(seq(1:nTicks), tsFUNDwealth_avg[1:nTicks,(e-1)*nAssets+1], 
#	tsFUNDwealth_avg[1:nTicks,(e-1)*nAssets+2], tsFUNDwealth_avg[1:nTicks,(e-1)*nAssets+3])
#
#   colnames(df) <- c("tick", "A1", "A2", "A3")
#
#   df <- reshape(df, varying = c("A1", "A2", "A3"), v.names = "wealth", timevar = "group", 
# 	   times = c("A1", "A2", "A3"), direction = "long")
#
#   # Aggregate avg wealth for each asset in stacked area plot
#   graph = ggplot(df, aes(x=tick, y=wealth, fill=group)) + geom_area(position = 'stack') +
#	labs(x = "Tick", y = "Aggregate wealth", title = paste("Exp", e)) + 
#        scale_fill_manual(values=brewer.pal(3,"Oranges"), name = paste("FUND", ", E", e), 
#	  breaks = c("A1", "A2", "A3"), labels = c("A1", "A2", "A3")) +
#        ylim(y_min_FUND,y_max_FUND)
#
#   # Display graphics in a grid
#   col = e %% numCols   
#   col = col + numCols * (col==0)   # Columns cannot take value 0
#   row = floor((e-1)/numCols) + 1
#   print(graph,vp=vplayout(row,col))
#}
#
#
###  ......... TRENDs ......... ##
#
## Plot graphics in a grid ('par' cannot be used with ggplot)
#grid.newpage()
#pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#y_max_TREND = 3 * max(tsTRENDwealth_avg)
#y_min_TREND = 3 * min(tsTRENDwealth_avg)
#
#for (e in seq(from=1, to=nExp)) {
#
#   # Create dataframe of avg wealth on each asset (contribution to plot stacked area graphic)
#   df = data.frame(seq(1:nTicks), tsTRENDwealth_avg[1:nTicks,(e-1)*nAssets+1], 
#	tsTRENDwealth_avg[1:nTicks,(e-1)*nAssets+2], tsTRENDwealth_avg[1:nTicks,(e-1)*nAssets+3])
#
#   colnames(df) <- c("tick", "A1", "A2", "A3")
#
#   df <- reshape(df, varying = c("A1", "A2", "A3"), v.names = "wealth", timevar = "group", 
# 	   times = c("A1", "A2", "A3"), direction = "long")
#
#   # Aggregate avg wealth for each asset in stacked area plot
#   graph = ggplot(df, aes(x=tick, y=wealth, fill=group)) + geom_area(position = 'stack') +
#	labs(x = "Tick", y = "Aggregate wealth", title = paste("Exp", e)) + 
#        scale_fill_manual(values=brewer.pal(3,"Greens"), name = paste("TREND", ", E", e), 
#	  breaks = c("A1", "A2", "A3"), labels = c("A1", "A2", "A3")) +
#        ylim(y_min_TREND,y_max_TREND)
#
#   # Display graphics in a grid
#   col = e %% numCols   
#   col = col + numCols * (col==0)   # Columns cannot take value 0
#   row = floor((e-1)/numCols) + 1
#   print(graph,vp=vplayout(row,col))
#}
#
#
###  ......... LSs ......... ##
#
## Plot graphics in a grid ('par' cannot be used with ggplot)
#grid.newpage()
#pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#y_max_LS = 3 * max(tsLSwealth_avg)
#y_min_LS = 3 * min(tsLSwealth_avg)
#
#for (e in seq(from=1, to=nExp)) {
#
#   # Create dataframe of avg wealth on each asset (contribution to plot stacked area graphic)
#   df = data.frame(seq(1:nTicks), tsLSwealth_avg[1:nTicks,(e-1)*nAssets+1], 
#	tsLSwealth_avg[1:nTicks,(e-1)*nAssets+2], tsLSwealth_avg[1:nTicks,(e-1)*nAssets+3])
#
#   colnames(df) <- c("tick", "A1", "A2", "A3")
#
#   df <- reshape(df, varying = c("A1", "A2", "A3"), v.names = "wealth", timevar = "group", 
# 	   times = c("A1", "A2", "A3"), direction = "long")
#
#   # Aggregate avg wealth for each asset in stacked area plot
#   graph = ggplot(df, aes(x=tick, y=wealth, fill=group)) + geom_area(position = 'stack') +
#	labs(x = "Tick", y = "Aggregate wealth", title = paste("Exp", e)) + 
#        scale_fill_manual(values=brewer.pal(3,"Blues"), name = paste("LS", ", E", e), 
#	  breaks = c("A1", "A2", "A3"), labels = c("A1", "A2", "A3")) +
#        ylim(y_min_LS,y_max_LS)
#
#   # Display graphics in a grid
#   col = e %% numCols   
#   col = col + numCols * (col==0)   # Columns cannot take value 0
#   row = floor((e-1)/numCols) + 1
#   print(graph,vp=vplayout(row,col))
#}
#






#______________________________________________________________________#
#                                                                      #
#                     FUND/TREND ORDERS AND VOLUME                     #
#______________________________________________________________________#
#                                                                      # 

# --------------------------- VOLUME --------------------------- #

### Plot of FUND, TREND and LS total volume (averaged over runs)

y_max = max(max(tsFUNDvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvolume_avg[,1:(nAssets*nExp)]), max(tsLSvolume_avg[,1:(nAssets*nExp)]))
y_min = min(min(tsFUNDvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvolume_avg[,1:(nAssets*nExp)]), min(tsLSvolume_avg[,1:(nAssets*nExp)]))

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      plot(tsTRENDvolume_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Total volume", col="seagreen")
      lines(tsFUNDvolume_avg[,(e-1)*nAssets+k], type="l", col="darkorange1")
      lines(tsLSvolume_avg[,(e-1)*nAssets+k], type="l", col="blue")
   }
   title(paste("Total volume of FUNDs vs TRENDs vs LS's (averaged over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Study which group of agents moves a higher volume (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


#### Plot of FUND and TREND volume per trader (averaged over runs)
##
## Added this plot for the experiment set where the number of FUNDs and TRENDs change.
## Here we divide the total volume by the number of FUNDs or TRENDs,
## to be able to see if the FUND/TREND volume increase or decrease due to the price
## dynamics instead of being higher/smaller only due to the number of traders
#
#y_max = max(max(tsFUNDvolume_avg[,1:(nAssets*nExp)]), max(tsTRENDvolume_avg[,1:(nAssets*nExp)]))/400
#y_min = min(min(tsFUNDvolume_avg[,1:(nAssets*nExp)]), min(tsTRENDvolume_avg[,1:(nAssets*nExp)]))/400
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   for (e in seq(from=1, to=nExp)) {
#      plot(tsTRENDvolume_avg[,(e-1)*nAssets+k]/((e-1)*40), type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Volume per trader", col="seagreen")
#      lines(tsFUNDvolume_avg[,(e-1)*nAssets+k]/(400-(e-1)*40), type="l", col="darkorange1")
#   }
#   title(paste("Volume per trader of FUNDs vs TRENDs (averaged over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study which group of agents sends larger orders (and so impact more on prices) (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}


#### Plot of FUND and TREND volume per trader for EACH individual run
##
## Added this plot for the experiment set where the number of FUNDs and TRENDs change.
## Here we divide the total volume by the number of FUNDs or TRENDs,
## to be able to see if the FUND/TREND volume increase or decrease due to the price
## dynamics instead of being higher/smaller only due to the number of traders.
## For each experiment, we plot here the time series of volume for all the runs.
#
#y_max = max(max(tsFUNDvolume[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDvolume[,2:(nAssets*nRuns*nExp+1)]))/200
#y_min = min(min(tsFUNDvolume[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDvolume[,2:(nAssets*nRuns*nExp+1)]))/200
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      plot(tsTRENDvolume[[k+1+0*nAssets +(e-1)*nAssets*nRuns]]/((e-1)*40), type="l", ylab="TREND volume", ylim=c(y_min, y_max), main="TREND volume", col=rainbow(nRuns)[1])
#      for (i in seq(from=1, to=nRuns-1)) {
#         lines(tsTRENDvolume[[k+1+i*nAssets +(e-1)*nAssets*nRuns]]/((e-1)*40), type="l", col=rainbow(nRuns)[i+1])  
#      }
#      lines(tsTRENDvolume_avg[,(e-1)*nAssets+k]/((e-1)*40), type="l", col="black", lwd=2)
#
#      plot(tsFUNDvolume[[k+1+0*nAssets +(e-1)*nAssets*nRuns]]/(400-(e-1)*40), type="l", ylab="FUND volume", ylim=c(y_min, y_max), main="FUND volume", col=rainbow(nRuns)[1])  
#      for (i in seq(from=1, to=nRuns-1)) {
#         lines(tsFUNDvolume[[k+1+i*nAssets +(e-1)*nAssets*nRuns]]/(400-(e-1)*40), type="l", col=rainbow(nRuns)[i+1])
#      }
#      lines(tsFUNDvolume_avg[,(e-1)*nAssets+k]/(400-(e-1)*40), type="l", col="black", lwd=2)
#
#      title(paste("Volume per trader of FUNDs vs TRENDs for all runs - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Compare the size of volume of FUNDs and TRENDs.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}


### Pie charts of FUND/TREND/LS mean volume for EACH individual run
#
# Objective: Study the relative volume moved by each group of traders,
# to be able to compare with empirical percentages.

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows, numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
            volumes <- c(mean(tsFUNDvolume[[k+1+i +(e-1)*nAssets*nRuns]]), mean(tsTRENDvolume[[k+1+i +(e-1)*nAssets*nRuns]]), mean(tsLSvolume[[k+1+i +(e-1)*nAssets*nRuns]]))
            labels <- c("F", "T", "LS") 
            pct <- round(volumes/sum(volumes)*100)
            labels <- paste(labels, pct) # add percents to labels
            labels <- paste(labels,"%",sep="") # ad % to labels 
            pie(volumes, labels = labels, col=c("darkorange1", "seagreen", "royalblue3"), main=paste("Run", 1+i/nAssets))
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            volumes <- c(mean(tsFUNDvolume[[k+i +(e-1)*nAssets*nRuns]]), mean(tsTRENDvolume[[k+i +(e-1)*nAssets*nRuns]]), mean(tsLSvolume[[k+i +(e-1)*nAssets*nRuns]]))
            labels <- c("F", "T", "LS") 
            pct <- round(volumes/sum(volumes)*100)
            labels <- paste(labels, pct) # add percents to labels
            labels <- paste(labels,"%",sep="") # ad % to labels 
            pie(volumes, labels = labels, col=c("darkorange1", "seagreen", "royalblue3"), main=paste("Run", 1+(i-1)/nAssets))
         }
      }
      title(paste("Mean volumes along simulations - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Objective: Study the mean volume moved by each strategy.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}



### Pie charts of FUND/TREND/LS mean volume (averaged over runs)
#
# Objective: Study the relative volume moved by each group of traders,
# to be able to compare with empirical percentages.

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      volumes <- c(mean(tsFUNDvolume_avg[,(e-1)*nAssets+k]), mean(tsTRENDvolume_avg[,(e-1)*nAssets+k]), mean(tsLSvolume_avg[,(e-1)*nAssets+k]))
      labels <- c("F", "T", "LS") 
      pct <- round(volumes/sum(volumes)*100)
      labels <- paste(labels, pct) # add percents to labels
      labels <- paste(labels,"%",sep="") # ad % to labels 
      pie(volumes, labels = labels, col=c("darkorange1", "seagreen", "royalblue3"), main=paste("Exp", e))
   }
   title(paste("Mean volumes (averaged over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   mtext("Objective: Study the mean volume moved by each strategy (over experiments).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}




# --------------------------- ORDERS --------------------------- #

### Plot of FUND, TREND and LS total orders (averaged over runs)

y_max = max(max(tsFUNDorders_avg[,1:(nAssets*nExp)]), max(tsTRENDorders_avg[,1:(nAssets*nExp)]), max(tsLSorders_avg[,1:(nAssets*nExp)]))
y_min = min(min(tsFUNDorders_avg[,1:(nAssets*nExp)]), min(tsTRENDorders_avg[,1:(nAssets*nExp)]), min(tsLSorders_avg[,1:(nAssets*nExp)]))

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      plot(tsTRENDorders_avg[,(e-1)*nAssets+k], type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Total orders", col="seagreen")
      lines(tsFUNDorders_avg[,(e-1)*nAssets+k], type="l", col="darkorange1")
      lines(tsLSorders_avg[,(e-1)*nAssets+k], type="l", col="royalblue3")
   }
   title(paste("Total orders of FUNDs vs TRENDs vs LS's (averaged over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
   #legend("topleft", c("Fundamentalistas","Técnicos", "Long-short"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen", "royalblue3"))
   mtext("Objective: Study which group of agents sends larger orders (and so impact more on prices) (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


#### Plot of FUND and TREND orders per trader (averaged over runs)
##
## Added this plot for the experiment set where the number of FUNDs and TRENDs change.
## Here we divide the total orders by the number of FUNDs or TRENDs,
## to be able to see if the FUND/TREND orders increase or decrease due to the price
## dynamics instead of being higher/smaller only due to the number of traders
#
#y_max = max(max(tsFUNDorders_avg[,1:(nAssets*nExp)]), max(tsTRENDorders_avg[,1:(nAssets*nExp)]))/400
#y_min = min(min(tsFUNDorders_avg[,1:(nAssets*nExp)]), min(tsTRENDorders_avg[,1:(nAssets*nExp)]))/400
#
#for (k in seq(from=1, to=nAssets)) {
#   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#   for (e in seq(from=1, to=nExp)) {
#      plot(tsTRENDorders_avg[,(e-1)*nAssets+k]/((e-1)*40), type="l", main=paste("Exp", e), ylim=c(y_min,y_max), xlab="Tick", ylab="Orders per trader", col="seagreen")
#      lines(tsFUNDorders_avg[,(e-1)*nAssets+k]/(400-(e-1)*40), type="l", col="darkorange1")
#   }
#   title(paste("Orders per trader of FUNDs vs TRENDs (averaged over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)   
#   mtext("Objective: Study which group of agents sends larger orders (and so impact more on prices) (over experiments). [orange=F, green=T]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#}

#### Plot of FUND and TREND orders per trader for EACH individual run
##
## Added this plot for the experiment set where the number of FUNDs and TRENDs change.
## Here we divide the total orders by the number of FUNDs or TRENDs,
## to be able to see if the FUND/TREND orders increase or decrease due to the price
## dynamics instead of being higher/smaller only due to the number of traders.
## For each experiment, we plot here the time series of orders for all the runs.
#
#y_max = max(max(tsFUNDorders[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDorders[,2:(nAssets*nRuns*nExp+1)]))/200
#y_min = min(min(tsFUNDorders[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDorders[,2:(nAssets*nRuns*nExp+1)]))/200
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
#      plot(tsTRENDorders[[k+1+0*nAssets +(e-1)*nAssets*nRuns]]/((e-1)*40), type="l", ylab="TREND orders", ylim=c(y_min, y_max), main="TREND orders", col=rainbow(nRuns)[1])  
#      for (i in seq(from=1, to=nRuns-1)) {
#         lines(tsTRENDorders[[k+1+i*nAssets +(e-1)*nAssets*nRuns]]/((e-1)*40), type="l", col=rainbow(nRuns)[i+1])  
#      }
#      lines(tsTRENDorders_avg[,(e-1)*nAssets+k]/((e-1)*40), type="l", col="black", lwd=2)
#
#      plot(tsFUNDorders[[k+1+0*nAssets +(e-1)*nAssets*nRuns]]/(400-(e-1)*40), type="l", ylab="FUND orders", ylim=c(y_min, y_max), main="FUND orders", col=rainbow(nRuns)[1])
#      for (i in seq(from=1, to=nRuns-1)) {
#         lines(tsFUNDorders[[k+1+i*nAssets +(e-1)*nAssets*nRuns]]/(400-(e-1)*40), type="l", col=rainbow(nRuns)[i+1])
#      }
#      lines(tsFUNDorders_avg[,(e-1)*nAssets+k]/(400-(e-1)*40), type="l", col="black", lwd=2)
#
#      title(paste("Orders per trader of FUNDs vs TRENDs for all runs - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext("Objective: Compare the size of orders of FUNDs and TRENDs.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}


### xyplot of FUND, TREND and LS orders (averaged over runs)

y_max = max(max(tsFUNDorders_avg), max(tsTRENDorders_avg), max(tsLSorders_avg))
y_min = min(min(tsFUNDorders_avg), min(tsTRENDorders_avg), min(tsLSorders_avg))

labels = "E 1"
for (e in seq(from=2, to=nExp)) {
   labels <- append(labels, paste("E", e))
}

for (k in seq(from=1, to=nAssets)) {
   #grid.newpage()
   pushViewport(viewport(layout=grid.layout(1,2)))   # Although I try to display the xyplots in a 1x2 grid, it does not work
   vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)

   graph1 <- xyplot(ts(tsFUNDorders_avg[,seq(k, nAssets*nExp, by=nAssets)]), layout=c(1,nExp), main = paste("FUND orders (averaged over runs) - Asset",k), 
         par.settings = list(strip.background = list(col = "gray")), 
	   ylim=c(y_min, y_max), strip=FALSE, strip.left = strip.custom(factor.levels=labels), col="darkorange1")

   print(graph1,vp=vplayout(1,1))    # Display the graphic in the grid

   graph2 <- xyplot(ts(tsTRENDorders_avg[,seq(k, nAssets*nExp, by=nAssets)]), layout=c(1,nExp), main = paste("TREND orders (averaged over runs) - Asset",k),
 	   par.settings = list(strip.background = list(col = "gray")), 
	   ylim=c(y_min, y_max), strip=FALSE, strip.left = strip.custom(factor.levels=labels), col="seagreen")

   print(graph2,vp=vplayout(1,2))    # Display the graphic in the grid

   graph3 <- xyplot(ts(tsLSorders_avg[,seq(k, nAssets*nExp, by=nAssets)]), layout=c(1,nExp), main = paste("LS orders (averaged over runs) - Asset",k),
 	   par.settings = list(strip.background = list(col = "gray")), 
	   ylim=c(y_min, y_max), strip=FALSE, strip.left = strip.custom(factor.levels=labels), col="royalblue3")

   print(graph3,vp=vplayout(1,2))    # Display the graphic in the grid
}


### Plot FUND, TREND and LS orders (for individual runs)

y_max = max(max(tsFUNDorders[,2:(nAssets*nRuns*nExp+1)]), max(tsTRENDorders[,2:(nAssets*nRuns*nExp+1)]), max(tsLSorders[,2:(nAssets*nRuns*nExp+1)]))
y_min = min(min(tsFUNDorders[,2:(nAssets*nRuns*nExp+1)]), min(tsTRENDorders[,2:(nAssets*nRuns*nExp+1)]), min(tsLSorders[,2:(nAssets*nRuns*nExp+1)]))

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
      if (nRuns>numRows*numCols){   
         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
            plot(tsTRENDorders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", ylab="Orders", main=paste("Run", 1+i/nAssets), ylim=c(y_min, y_max), col="seagreen")
            lines(tsFUNDorders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="darkorange1")
            lines(tsLSorders[[i+k+1 +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            plot(tsTRENDorders[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Orders", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max), col="seagreen")
            lines(tsFUNDorders[[i+k +(e-1)*nAssets*nRuns]], type="l", col="darkorange1")
            lines(tsLSorders[[i+k +(e-1)*nAssets*nRuns]], type="l", col="royalblue3")
         }
      }
      title(paste("Total orders of FUNDs/TRENDs/LS's - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Objective: Study which group of agents sends larger orders (and so impacts more on prices) (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}


# ------------------------ ORDERS + VOLUME ------------------------ #

### Plot of average FUND, TREND and LS volume & orders along experiments

FUND_volume <- array(0, dim=c(nExp, nAssets))   # Array to store the volume averaged over all runs and ticks (for each asset and experiment)
TREND_volume <- array(0, dim=c(nExp, nAssets))
LS_volume <- array(0, dim=c(nExp, nAssets))
FUND_orders <- array(0, dim=c(nExp, nAssets))   # Array to store the orders averaged over all runs and ticks (for each asset and experiment)
TREND_orders <- array(0, dim=c(nExp, nAssets))
LS_orders <- array(0, dim=c(nExp, nAssets))

par(mfrow=c(nAssets,2), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   for (e in seq(from=0, to=nExp-1)) {
      FUND_volume[e+1,i] = mean(tsFUNDvolume_avg[,i+e*nAssets])
      TREND_volume[e+1,i] = mean(tsTRENDvolume_avg[,i+e*nAssets])
      LS_volume[e+1,i] = mean(tsLSvolume_avg[,i+e*nAssets])
      FUND_orders[e+1,i] = mean(tsFUNDorders_avg[,i+e*nAssets])
      TREND_orders[e+1,i] = mean(tsTRENDorders_avg[,i+e*nAssets])
      LS_orders[e+1,i] = mean(tsLSorders_avg[,i+e*nAssets])
   }

   y_max = max(max(FUND_volume[,i]), max(TREND_volume[,i]), max(LS_volume[,i]))
   y_min = min(min(FUND_volume[,i]), min(TREND_volume[,i]), min(LS_volume[,i]))
   plot(FUND_volume[,i], type="l", ylab="", main=paste("Mean volume - Asset", i), ylim=c(y_min, y_max), lwd=2, col="darkorange1")
   lines(TREND_volume[,i], type="l", col="seagreen", lwd=2)
   lines(LS_volume[,i], type="l", col="blue", lwd=2)

   y_max = max(max(FUND_orders[,i]), max(TREND_orders[,i]), max(LS_orders[,i]))
   y_min = min(min(FUND_orders[,i]), min(TREND_orders[,i]), min(LS_orders[,i]))
   plot(FUND_orders[,i], type="l", ylab="", main=paste("Mean orders - Asset", i), ylim=c(y_min, y_max), lwd=2, col="darkorange1")
   lines(TREND_orders[,i], type="l", col="seagreen", lwd=2)
   lines(LS_orders[,i], type="l", col="blue", lwd=2)
}
title("Mean volume & orders of FUNDs/TRENDs/LS's over experiments", outer = TRUE, col.main="blue", font.main=2)
mtext("Objective: Study which group of agents sends larger orders (and so impacts more on prices) (over experiments). [orange=F, green=T, blue=LS]", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of FUND, TREND and LS volume along experiments

volume_avg_FTL <- array(0, dim=c(nTicks, 3*nAssets*nExp))   # Auxiliary array to store volume averaged over runs

# Mean volume of FUNDs, TRENDs and LS's for each run are allocated in a single matrix to plot the parallel boxplots
for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      volume_avg_FTL[,1+3*(i-1)+3*k*nAssets] = tsFUNDvolume_avg[,i+k*nAssets]    # Columns % 1 (mod 3) allocate FUNDs' volume
      volume_avg_FTL[,2+3*(i-1)+3*k*nAssets] = tsTRENDvolume_avg[,i+k*nAssets]   # Columns % 2 (mod 3) allocate TRENDs' volume
      volume_avg_FTL[,3+3*(i-1)+3*k*nAssets] = tsLSvolume_avg[,i+k*nAssets]      # Columns % 0 (mod 3) allocate LS' volume
   }
}

indices <- c(1,2,3)
exp_labels <- c("Exp 1", "", "")
position_labels <- c(1,2,3)

if (nExp>1) {
   for (e in seq(from=1, to=nExp-1)) {
      indices <- append(indices, 1+e*3*nAssets)    # Sequence of indices of columns to be plot for asset 1
      indices <- append(indices, 2+e*3*nAssets)
      indices <- append(indices, 3+e*3*nAssets)

      exp_labels <- append(exp_labels, paste("Exp",(e+1)))    # x labels
      exp_labels <- append(exp_labels, "")
      exp_labels <- append(exp_labels, "")

      position_labels <- append(position_labels, 1+e*4)   # Position of boxplots (leave space between different experiments)
      position_labels <- append(position_labels, 2+e*4)
      position_labels <- append(position_labels, 3+e*4)
   }
}

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(2.5,0.5,0))

for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(volume_avg_FTL[,(3*(i-1)+indices)], notch=FALSE, col=c("darkorange1", "seagreen", "royalblue3"), names=exp_labels,
	las=2, at=position_labels, main=paste("Asset", i), xlim = c(0, nExp*4),
	xlab="", ylab ="Volume FUND/TREND/LS")
}
legend("topleft", c("FUND","TREND", "LS"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen", "royalblue3"))
title("Range of variation of volume (averaged over runs)", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of FUND/TREND/LS volume.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


### Boxplot of FUND, TREND and LS orders along experiments

orders_avg_FTL <- array(0, dim=c(nTicks, 3*nAssets*nExp))   # Auxiliary array to store the orders averaged over runs

# Mean orders of FUNDs, TRENDs and LS's for each run are allocated in a single matrix to plot the parallel boxplots
for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      orders_avg_FTL[,1+3*(i-1)+3*k*nAssets] = tsFUNDorders_avg[,i+k*nAssets]    # Columns % 1 (mod 3) allocate FUNDs' orders
      orders_avg_FTL[,2+3*(i-1)+3*k*nAssets] = tsTRENDorders_avg[,i+k*nAssets]   # Columns % 2 (mod 3) allocate TRENDs' orders
      orders_avg_FTL[,3+3*(i-1)+3*k*nAssets] = tsLSorders_avg[,i+k*nAssets]      # Columns % 0 (mod 3) allocate LS' orders
   }
}

indices <- c(1,2,3)
exp_labels <- c("Exp 1", "", "")
position_labels <- c(1,2,3)

if (nExp>1) {
   for (e in seq(from=1, to=nExp-1)) {
      indices <- append(indices, 1+e*3*nAssets)    # Sequence of indices of columns to be plotted for asset 1
      indices <- append(indices, 2+e*3*nAssets)
      indices <- append(indices, 3+e*3*nAssets)

      exp_labels <- append(exp_labels, paste("Exp",(e+1)))    # x labels
      exp_labels <- append(exp_labels, "")
      exp_labels <- append(exp_labels, "")

      position_labels <- append(position_labels, 1+e*4)   # Position of boxplots (leave space between different experiments)
      position_labels <- append(position_labels, 2+e*4)
      position_labels <- append(position_labels, 3+e*4)
   }
}

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(2.5,0.5,0))

for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(orders_avg_FTL[,(3*(i-1)+indices)], notch=FALSE, col=c("darkorange1", "seagreen", "royalblue3"), names=exp_labels,
	las=2, at=position_labels, main=paste("Asset", i), xlim = c(0, nExp*4),
	xlab="", ylab ="Orders FUND/TREND/LS")
}
legend("topleft", c("FUND","TREND","LS"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen", "royalblue3"))
title("Range of variation of orders (averaged over runs)", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of FUND/TREND/LS orders.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



#__________________________________________________________________________#
#                                                                          #
#           CONTRIBUTION OF FUNDS, TRENDS & LS TO PRICE FORMATION          #
#__________________________________________________________________________#
#                                                                          #

#### Plot of FUND, TREND and LS % contribution to price formation (for individual runs)
#
## !!! EXTREMELY EXPENSIVE TO DRAW THESE PLOTS
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#
#      # Plot graphics in a grid ('par' cannot be used with ggplot)
#      grid.newpage()
#      pushViewport(viewport(layout=grid.layout(numRows,numCols)))
#      vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)
#
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) { 
#
#            # Create dataframe of contribution to plot stacked area graphic
#      	df = data.frame(seq(1:(nTicks-1)), tsFUNDorders[1:(nTicks-1), i+k+1+(e-1)*nAssets*nRuns]/liquidity, 
#	      	tsTRENDorders[1:(nTicks-1), i+k+1+(e-1)*nAssets*nRuns]/liquidity, 
#                  tsLSorders[1:(nTicks-1), i+k+1+(e-1)*nAssets*nRuns]/liquidity, 
#	      	tsrandomprices[1:(nTicks-1), i+k+1+(e-1)*nAssets*nRuns])
#      	colnames(df) <- c("tick", "FUND", "TREND", "LS", "random")
#
#	      df <- reshape(df, varying = c("FUND", "TREND", "LS", "random"), v.names = "contribution", timevar = "group", 
# 		     times = c("FUND", "TREND", "LS", "random"), direction = "long")
#
#            # Create dataframe of contributions in percentage
#            df_prop <- ddply(df, "tick", transform, Percent = abs(contribution) / sum(abs(contribution)) * 100)
#
#       # Plot contributions in stacked area plot
#       # !! Colours are assigned in alphabetical order of categories: FUND - LS - random - TREND
#      	graph = ggplot(df_prop, aes(x=tick, y=Percent, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "Contrib. to price", title = "") + 
#                   scale_fill_manual(values=c("darkorange1", "royalblue3", "gray80", "seagreen"), name = paste("A",k, ", R", 1+i/nAssets, ", E", e), 
#            	breaks = c("FUND", "TREND", "LS", "random"), labels = c("FUND", "TREND", "LS", "Random"))
#
#		# Display graphics in a grid
#	      col = (i/step) %% numCols   
#      	col = col + numCols * (col==0)   # Columns cannot take value 0
#	      row = floor((i/step-1)/numCols) + 1
#	      print(graph,vp=vplayout(row,col))
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#
#            # Create dataframe of contribution to plot stacked area graphic
#      	df = data.frame(seq(1:(nTicks-1)), tsFUNDorders[1:(nTicks-1), i+k+(e-1)*nAssets*nRuns]/liquidity, 
#	      	tsTRENDorders[1:(nTicks-1), i+k+(e-1)*nAssets*nRuns]/liquidity, 
#                  tsLSorders[1:(nTicks-1), i+k+(e-1)*nAssets*nRuns]/liquidity,
#	      	tsrandomprices[1:(nTicks-1), i+k+(e-1)*nAssets*nRuns])
#      	colnames(df) <- c("tick", "FUND", "TREND", "LS", "random")
#
#	      df <- reshape(df, varying = c("FUND", "TREND", "LS", "random"), v.names = "contribution", timevar = "group", 
# 		     times = c("FUND", "TREND", "LS", "random"), direction = "long")
#
#            # Create dataframe of contributions in percentage
#            df_prop <- ddply(df, "tick", transform, Percent = abs(contribution) / sum(abs(contribution)) * 100)
#
#       # Plot contributions in stacked area plot
#       # !! Colours are assigned in alphabetical order of categories: FUND - LS - random - TREND
#      	graph = ggplot(df_prop, aes(x=tick, y=Percent, fill=group)) + geom_area(position = 'stack') +
#	      	labs(x = "Tick", y = "% contrib. to price", title = "") + 
#		     scale_fill_manual(values=c("darkorange1", "royalblue3", "gray80", "seagreen"), name = paste("A",k, ", R", 1+(i-1)/nAssets, ", E", e), 
#            	breaks = c("FUND", "TREND", "LS", "random"), labels = c("FUND", "TREND", "LS", "Random"))
#
#		# Display graphics in a grid
#	      col = (1+(i-1)/nAssets) %% numCols   
#      	col = col + numCols * (col==0)   # Columns cannot take value 0
#	      row = floor(((i-1)/nAssets)/numCols) + 1
#	      print(graph,vp=vplayout(row,col))
#         }
#      }
#   }
#}


### Plot of FUND, TREND and LS % contribution to price formation (averaged over runs)

# !!! EXTREMELY EXPENSIVE TO DRAW THESE PLOTS

# Calculate absolute orders averaged over runs (to avoid that positive
# and negative orders cancel out)

tsFUNDorders_abs_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsTRENDorders_abs_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsLSorders_abs_avg <- array(0, dim=c(nTicks, nAssets*nExp))
tsrandomprices_abs_avg <- array(0, dim=c(nTicks, nAssets*nExp))

#for (k in seq(from=0, to=nExp-1)) {
#   for (i in seq(from=1, to=nAssets)) {
#      for (j in seq(from=0, to=nRuns-1)) {
#         tsFUNDorders_abs_avg[,i+k*nAssets] <- tsFUNDorders_abs_avg[,i+k*nAssets] + abs(tsFUNDorders[[i+1+j*nAssets+k*nAssets*nRuns]])
#         tsTRENDorders_abs_avg[,i+k*nAssets] <- tsTRENDorders_abs_avg[,i+k*nAssets] + abs(tsTRENDorders[[i+1+j*nAssets+k*nAssets*nRuns]])
#         tsLSorders_abs_avg[,i+k*nAssets] <- tsLSorders_abs_avg[,i+k*nAssets] + abs(tsLSorders[[i+1+j*nAssets+k*nAssets*nRuns]])
#         tsrandomprices_abs_avg[,i+k*nAssets] <- tsrandomprices_abs_avg[,i+k*nAssets] + abs(tsrandomprices[,i+1+j*nAssets+k*nAssets*nRuns])
#      }
#      tsFUNDorders_abs_avg[,i+k*nAssets] <- tsFUNDorders_abs_avg[,i+k*nAssets]/nRuns
#      tsTRENDorders_abs_avg[,i+k*nAssets] <- tsTRENDorders_abs_avg[,i+k*nAssets]/nRuns
#      tsLSorders_abs_avg[,i+k*nAssets] <- tsLSorders_abs_avg[,i+k*nAssets]/nRuns
#      tsrandomprices_abs_avg[,i+k*nAssets] <- tsrandomprices_abs_avg[,i+k*nAssets]/nRuns
#   }
#}

# [25 Aug 2015] I change the implementation, building on volumes (instead of orders)
# This gives a result more coherent with the scatterplots below

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         tsFUNDorders_abs_avg[,i+k*nAssets] <- tsFUNDorders_abs_avg[,i+k*nAssets] + tsFUNDvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsTRENDorders_abs_avg[,i+k*nAssets] <- tsTRENDorders_abs_avg[,i+k*nAssets] + tsTRENDvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsLSorders_abs_avg[,i+k*nAssets] <- tsLSorders_abs_avg[,i+k*nAssets] + tsLSvolume[[i+1+j*nAssets+k*nAssets*nRuns]]
         tsrandomprices_abs_avg[,i+k*nAssets] <- tsrandomprices_abs_avg[,i+k*nAssets] + abs(tsrandomprices[,i+1+j*nAssets+k*nAssets*nRuns])
      }
      tsFUNDorders_abs_avg[,i+k*nAssets] <- tsFUNDorders_abs_avg[,i+k*nAssets]/nRuns
      tsTRENDorders_abs_avg[,i+k*nAssets] <- tsTRENDorders_abs_avg[,i+k*nAssets]/nRuns
      tsLSorders_abs_avg[,i+k*nAssets] <- tsLSorders_abs_avg[,i+k*nAssets]/nRuns
      tsrandomprices_abs_avg[,i+k*nAssets] <- tsrandomprices_abs_avg[,i+k*nAssets]/nRuns
   }
}


for (k in seq(from=1, to=nAssets)) {

   # Plot graphics in a grid ('par' cannot be used with ggplot)
   grid.newpage()
   pushViewport(viewport(layout=grid.layout(numRows,numCols)))
   vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)

   for (e in seq(from=1, to=nExp)) {

      # Create dataframe of contribution to plot stacked area graphic
	df = data.frame(seq(1:(nTicks-1)), tsFUNDorders_abs_avg[1:(nTicks-1),(e-1)*nAssets+k]/liquidity, 
		tsTRENDorders_abs_avg[1:(nTicks-1),(e-1)*nAssets+k]/liquidity, 
            tsLSorders_abs_avg[1:(nTicks-1),(e-1)*nAssets+k]/liquidity,
		tsrandomprices_abs_avg[1:(nTicks-1),(e-1)*nAssets+k])

	colnames(df) <- c("tick", "FUND", "TREND", "LS", "random")

	df <- reshape(df, varying = c("FUND", "TREND", "LS", "random"), v.names = "contribution", timevar = "group", 
 		times = c("FUND", "TREND", "LS", "random"), direction = "long")

      # Create dataframe of contributions in percentage
      df_prop <- ddply(df, "tick", transform, Percent = abs(contribution) / sum(abs(contribution)) * 100)

	# Plot % contributions in stacked area plot
      # !! Colours are assigned in alphabetical order of categories: FUND - LS - random - TREND
	graph = ggplot(df_prop, aes(x=tick, y=Percent, fill=group)) + geom_area(position = 'stack') +
		#labs(x = "Tick", y = "% contrib. to price", title = paste("Exp", e)) + 
            labs(x = "", y = "% contribución en la formación del precio", title = paste("Exp", e)) + 
             #scale_fill_manual(values=c("darkorange1", "royalblue3", "gray80", "seagreen"), name = paste("A", k, ", E", e), 
             scale_fill_manual(values=c("darkorange1", "royalblue3", "gray80", "seagreen"), name = "",
		breaks = c("FUND", "TREND", "LS", "random"), labels = c("Fundamentalistas", "Técnicos", "Long-short", "Aleatorio"))

	# Display graphics in a grid
      col = e %% numCols   
      col = col + numCols * (col==0)   # Columns cannot take value 0
      row = floor((e-1)/numCols) + 1
      print(graph,vp=vplayout(row,col))
   }
#   title(paste("Contribution to price discovery: FUND/TREND/LS/random (averaged over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
#   mtext("Objective: Study the impact of agents in prices (over experiments).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


### Plot of FUND, TREND and LS % contribution to price formation (averaged over runs and ticks)

# Create dataframe of contributions to price, averaged in absolute value over runs and ticks
tsFUNDorders_abs_avg_avg <- rep(0, nAssets*nExp)
tsTRENDorders_abs_avg_avg <- rep(0, nAssets*nExp)
tsLSorders_abs_avg_avg <- rep(0, nAssets*nExp)
tsrandomprices_abs_avg_avg <- rep(0, nAssets*nExp)

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      tsFUNDorders_abs_avg_avg[(e-1)*nAssets+k] <- mean(tsFUNDorders_abs_avg[,(e-1)*nAssets+k])
      tsTRENDorders_abs_avg_avg[(e-1)*nAssets+k] <- mean(tsTRENDorders_abs_avg[,(e-1)*nAssets+k])
      tsLSorders_abs_avg_avg[(e-1)*nAssets+k] <- mean(tsLSorders_abs_avg[,(e-1)*nAssets+k])
      tsrandomprices_abs_avg_avg[(e-1)*nAssets+k] <- mean(tsrandomprices_abs_avg[,(e-1)*nAssets+k])
   }
}

for (k in seq(from=1, to=nAssets)) {

   # Plot graphics in a grid ('par' cannot be used with ggplot)
   grid.newpage()
   pushViewport(viewport(layout=grid.layout(1,1)))
   vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)

   df = data.frame(seq(1:nExp), tsFUNDorders_abs_avg_avg[seq(k, nAssets*nExp, by=nAssets)]/liquidity, 
	tsTRENDorders_abs_avg_avg[seq(k, nAssets*nExp, by=nAssets)]/liquidity, 
      tsLSorders_abs_avg_avg[seq(k, nAssets*nExp, by=nAssets)]/liquidity,
      tsrandomprices_abs_avg_avg[seq(k, nAssets*nExp, by=nAssets)])
   colnames(df) <- c("experiment", "FUND", "TREND", "LS", "random")

   df <- reshape(df, varying = c("FUND", "TREND", "LS", "random"), v.names = "contribution", timevar = "group", 
 	times = c("FUND", "TREND", "LS", "random"), direction = "long")

   # Create dataframe of contributions in percentage
   df_prop <- ddply(df, "experiment", transform, Percent = abs(contribution) / sum(abs(contribution)) * 100)

   # Plot contributions in stacked area plot
   # !! Colours are assigned in alphabetical order of categories: FUND - LS - random - TREND
   graph = ggplot(df_prop, aes(x=experiment, y=Percent, fill=group)) + geom_area(position = 'stack') +
	labs(x = "Experiment", y = "% contribution to price", title = paste("Asset", k)) + 
      scale_fill_manual(values=c("darkorange1", "royalblue3", "gray80", "seagreen"), name = paste("Asset", k), breaks = c("FUND", "TREND", "LS", "random"), labels = c("FUND", "TREND", "LS", "Random"))

   # Display graphic in the grid (Obs: 'print' must be explicitly used when the ggplot is inside a loop)
   print(graph,vp=vplayout(1,1))
}



### Scatterplot of FUND/TREND/LS orders and returns (for individual runs)
#
# Objective: Study if the price is moved by FUNDs, TRENDs or LS's

tsFUNDorders_liq <- tsFUNDorders/liquidity
tsFUNDorders_liq[[1]] <- tsFUNDorders[[1]]  # The 'tick' column must not change

tsTRENDorders_liq <- tsTRENDorders/liquidity
tsTRENDorders_liq[[1]] <- tsTRENDorders[[1]]  # The 'tick' column must not change

tsLSorders_liq <- tsLSorders/liquidity
tsLSorders_liq[[1]] <- tsLSorders[[1]]  # The 'tick' column must not change

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows, numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             plot(tsFUNDorders_liq[1:(nTicks-1), (k+1+i +(e-1)*nAssets*nRuns)], diff(tsprices[[k+1+i +(e-1)*nAssets*nRuns]]), ylab = "Price increment", xlab="Orders/liquidity", main=paste("Run",  1+i/nAssets), col="darkorange1")
		 if ( sum(abs(tsFUNDorders[1:nTicks, (k+1+i +(e-1)*nAssets*nRuns)]))>0 ) {   # The regression line cannot only be calculated if x's !=0
                abline(lin_reg <- lm(diff(tsprices[[k+1+i +(e-1)*nAssets*nRuns]]) ~ tsFUNDorders_liq[1:(nTicks-1), (k+1+i +(e-1)*nAssets*nRuns)] ), col="red")   # regression line (price increments ~ orders)
                mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
             } 
          }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            plot(tsFUNDorders_liq[1:(nTicks-1), (i+k +(e-1)*nAssets*nRuns)], diff(tsprices[[i+k +(e-1)*nAssets*nRuns]]), ylab = "Price increment", xlab="Orders/liquidity", main=paste("Run",  1+(i-1)/nAssets), col="darkorange1")
            if ( sum(abs(tsFUNDorders[1:nTicks, (i+k +(e-1)*nAssets*nRuns)]))>0 ) {   # The regression line cannot only be calculated if x's !=0
               abline(lin_reg <- lm(diff(tsprices[[i+k +(e-1)*nAssets*nRuns]]) ~ tsFUNDorders_liq[1:(nTicks-1), (i+k +(e-1)*nAssets*nRuns)]), col="red")   # regression line (price increments ~ orders)
               mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
            }
         }
      }
      title(paste("Scatterplot of FUND orders and price increments - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: Study if FUNDs are moving the price.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             plot(tsTRENDorders_liq[1:(nTicks-1), (k+1+i +(e-1)*nAssets*nRuns)], diff(tsprices[[k+1+i +(e-1)*nAssets*nRuns]]), ylab = "Price increment", xlab="Orders/liquidity", main=paste("Run",  1+i/nAssets), col="seagreen")
		 if ( sum(abs(tsTRENDorders[1:nTicks, (k+1+i +(e-1)*nAssets*nRuns)]))>0 ) {   # The regression line cannot only be calculated if x's !=0
                abline(lin_reg <- lm(diff(tsprices[[k+1+i +(e-1)*nAssets*nRuns]]) ~ tsTRENDorders_liq[1:(nTicks-1), (k+1+i +(e-1)*nAssets*nRuns)]), col="red")   # regression line (price increments ~ orders)
                mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
             }
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            plot(tsTRENDorders_liq[1:(nTicks-1), (i+k +(e-1)*nAssets*nRuns)], diff(tsprices[[i+k +(e-1)*nAssets*nRuns]]), ylab = "Price increment", xlab="Orders/liquidity", main=paste("Run",  1+(i-1)/nAssets), col="seagreen")
            if ( sum(abs(tsTRENDorders[1:nTicks, (i+k +(e-1)*nAssets*nRuns)]))>0 ) {   # The regression line cannot only be calculated if x's !=0
               abline(lin_reg <- lm(diff(tsprices[[i+k +(e-1)*nAssets*nRuns]]) ~ tsTRENDorders_liq[1:(nTicks-1), (i+k +(e-1)*nAssets*nRuns)]), col="red")   # regression line (price increments ~ orders)
               mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
            }
          }
      }
      title(paste("Scatterplot of TREND orders and price increments - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: Study if TRENDs are moving the price.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}

for (e in seq(from=1, to=nExp)) {
   for (k in seq(from=1, to=nAssets)) {
      par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
       if (nRuns>numRows*numCols){   
          for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
             plot(tsLSorders_liq[1:(nTicks-1), (k+1+i +(e-1)*nAssets*nRuns)], diff(tsprices[[k+1+i +(e-1)*nAssets*nRuns]]), ylab = "Price increment", xlab="Orders/liquidity", main=paste("Run",  1+i/nAssets), col="royalblue3")
		 if ( sum(abs(tsLSorders[1:nTicks, (k+1+i +(e-1)*nAssets*nRuns)]))>0 ) {   # The regression line cannot only be calculated if x's !=0
                abline(lin_reg <- lm(diff(tsprices[[k+1+i +(e-1)*nAssets*nRuns]]) ~ tsLSorders_liq[1:(nTicks-1), (k+1+i +(e-1)*nAssets*nRuns)]), col="red")   # regression line (price increments ~ orders)
                mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
             }
         }
      } else {
         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
            plot(tsLSorders_liq[1:(nTicks-1), (i+k +(e-1)*nAssets*nRuns)], diff(tsprices[[i+k +(e-1)*nAssets*nRuns]]), ylab = "Price increment", xlab="Orders/liquidity", main=paste("Run",  1+(i-1)/nAssets), col="royalblue3")
            if ( sum(abs(tsLSorders[1:nTicks, (i+k +(e-1)*nAssets*nRuns)]))>0 ) {   # The regression line cannot only be calculated if x's !=0
               abline(lin_reg <- lm(diff(tsprices[[i+k +(e-1)*nAssets*nRuns]]) ~ tsLSorders_liq[1:(nTicks-1), (i+k +(e-1)*nAssets*nRuns)]), col="red")   # regression line (price increments ~ orders)
               mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
            }
         }
      }
      title(paste("Scatterplot of LS orders and price increments - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: Study if LS's are moving the price.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}



### Scatterplot of FUND/TREND/LS orders and returns (averaged over runs)
#
# Objective: Study if the price is moved by FUNDs, TRENDs or LS's over experiments

# !! The slope of the regression line is very small because the orders are not divided by liquidity
# (however, the cloud of points looks exactly the same way, and R^2 is the same)

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
   for (e in seq(from=1, to=nExp)) {
      plot(tsFUNDorders_avg[1:(nTicks-1), (e-1)*nAssets+k], diff(tsprices_avg[,(e-1)*nAssets+k]), ylab = "Price increment", xlab="Orders/liquidity", main=paste("Exp", e), col="darkorange1")
      if ( sum(abs(tsFUNDorders_avg[1:nTicks, (e-1)*nAssets+k]))>0 ) {   # The regression line cannot only be calculated if x's !=0
         abline(lin_reg <- lm(diff(tsprices_avg[,(e-1)*nAssets+k]) ~ tsFUNDorders_avg[1:(nTicks-1), (e-1)*nAssets+k]), col="red")   # regression line (price increments ~ orders)
         mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
      }
   }
   title(paste("Scatterplot of FUND orders and price increments (over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: Study if FUNDs are moving the price.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
   for (e in seq(from=1, to=nExp)) {
      plot(tsTRENDorders_avg[1:(nTicks-1), (e-1)*nAssets+k], diff(tsprices_avg[,(e-1)*nAssets+k]), ylab = "Price increment", xlab="Orders/liquidity",  main=paste("Exp", e), col="seagreen")
      if ( sum(abs(tsTRENDorders_avg[1:nTicks, (e-1)*nAssets+k]))>0 ) {   # The regression line cannot only be calculated if x's !=0
         abline(lin_reg <- lm(diff(tsprices_avg[,(e-1)*nAssets+k]) ~ tsTRENDorders_avg[1:(nTicks-1), (e-1)*nAssets+k]), col="red")   # regression line (price increments ~ orders)
         mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
      }
   }
   title(paste("Scatterplot of TREND orders and price increments (over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: Study if TRENDs are moving the price.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
   for (e in seq(from=1, to=nExp)) {
      plot(tsLSorders_avg[1:(nTicks-1), (e-1)*nAssets+k], diff(tsprices_avg[,(e-1)*nAssets+k]), ylab = "Price increment", xlab="Orders/liquidity",  main=paste("Exp", e), col="royalblue3")
      if ( sum(abs(tsLSorders_avg[1:nTicks, (e-1)*nAssets+k]))>0 ) {   # The regression line cannot only be calculated if x's !=0
         abline(lin_reg <- lm(diff(tsprices_avg[,(e-1)*nAssets+k]) ~ tsLSorders_avg[1:(nTicks-1), (e-1)*nAssets+k]), col="red")   # regression line (price increments ~ orders)
         mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file
      }
   }
   title(paste("Scatterplot of LS orders and price increments (over runs) - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: Study if LS's are moving the price.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


#______________________________________________#
#                                              #
#             VOLATILITY OF PRICES             #
#______________________________________________#
#                                              #

### Plot the mean and range of variation of volatility of price time series (averaged over runs)
# Objective: Study the range of variation of volatility over experiments

# Calculate the min/max value of price volatility over all runs for each asset

Max_volat <- array(0, dim=c(nExp, nAssets))  # Arrays to store the max and min volatility over all runs (for each asset and experiment)
Min_volat <- array(0, dim=c(nExp, nAssets))
Mean_volat <- array(0, dim=c(nExp, nAssets))  # Array to store the mean volatility over all runs (for each asset and experiment)
Stdev_volat <- array(0, dim=c(nExp, nAssets))  # Array to store the standard deviation of volatility over all runs (for each asset and experiment)

asset_volatility_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the volatility for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with volatility of asset i for each run
         asset_volatility_vector[,j+1] = sd(tsprices[[i+1+j*nAssets+k*nAssets*nRuns]], na.rm = FALSE)   # Store values of volatility
      }
      Max_volat[k+1,i] = max(asset_volatility_vector)  # Select max/min volatility over all runs
      Min_volat[k+1,i] = min(asset_volatility_vector)
      Mean_volat[k+1,i] = mean(asset_volatility_vector)
      Stdev_volat[k+1,i] = sd(asset_volatility_vector[1,])
   }
}

# Plot mean, minimum, and maximum volatility

y_min = min(Min_volat)  # Range of y axis
y_max = max(Max_volat)

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   xx <- c(1:nExp, nExp:1)   # Needed to shade the area between max and min
   yy <- c(Min_volat[,i], rev(Max_volat[,i]))
   plot(xx,yy, type="l", main=paste("Asset", i), col="black", 
	xlab="Experiment", ylab="Max/Min volatility", lwd=1, ylim=c(y_min,y_max))
   polygon(xx, yy, col="gray")

   lines(Mean_volat[,i], type="l", col="black", lwd=2)
   lines(Mean_volat[,i]+Stdev_volat[,i], type="l", col="red2")   # Plot +-1stdev to have an idea of the variability
   lines(Mean_volat[,i]-Stdev_volat[,i], type="l", col="red2")
}
title("Range of variation of volatility", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the mean/max/min values of volatility (stdev of prices).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


## To provide information in the x axis on e.g. the percentage of HF's: create a vector with the percentages, e.g.:
## x <- c(0.1, 0.2, 0.3, 0.4, 0.5)
## axis(1, at=1:nExp, x)


### Boxplot of volatility along experiments
# Description of notched boxplots: https://sites.google.com/site/davidsstatistics/home/notched-box-plots

volatility_matrix <- array(0, dim=c(nRuns, nAssets*nExp))   # Auxiliary array to store the price volatility for each run and asset

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with volatility of asset i for each run
         volatility_matrix[j+1,i+k*nAssets] = sd(tsprices[[1+i+j*nAssets+k*nAssets*nRuns]])   # Store the volatility (calculated as the std dev of prices)
      }
   }
}

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))
for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(volatility_matrix[,seq(i,nAssets*nExp,nAssets)], notch=TRUE, col="gold", main=paste("Asset", i), xlab="")
}
title("Range of variation of volatility", outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the distribution of volatility (stdev of prices).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



for (k in seq(from=1, to=nAssets)) {

   # Build data arrays to plot scatterplots

   volatility_matrix <- array(0, dim=c(nRuns*nExp, 2))   # Create a matrix: (experiment , volatility of time series)
   kurtosis_matrix <- array(0, dim=c(nRuns*nExp, 2))     # Create a matrix: (experiment , kurtosis of time series)
   volume_matrix <- array(0, dim=c(nRuns*nExp, 2))       # Create a matrix: (experiment , volume of time series)
   distance_matrix <- array(0, dim=c(nRuns*nExp, 2))     # Create a matrix: (experiment , distance between price and value time series)
      
   for (e in seq(from=0, to=nExp-1)) {
      for (i in seq(from=0, to=nRuns-1)) {
	   volatility_matrix[i+1+e*nRuns,1] = e+1
	   volatility_matrix[i+1+e*nRuns,2] = sd(tsprices[[k+1+i*nAssets+e*nAssets*nRuns]], na.rm = FALSE)         

	   kurtosis_matrix[i+1+e*nRuns,1] = e+1
	   kurtosis_matrix[i+1+e*nRuns,2] = kurtosis(diff(tsprices[[k+1+i*nAssets+e*nAssets*nRuns]]), na.rm = FALSE, method="excess")[1]

	   volume_matrix[i+1+e*nRuns,1] = e+1
	   volume_matrix[i+1+e*nRuns,2] = mean(tsvolume[[k+1+i*nAssets+e*nAssets*nRuns]])

	   distance_matrix[i+1+e*nRuns,1] = e+1
	   distance_matrix[i+1+e*nRuns,2] = sqrt(sum((tsprices[[k+1+i*nAssets+e*nAssets*nRuns]] - tsvalues[[k+1+i*nAssets+e*nAssets*nRuns]])^2))/nTicks
      }
   }

   # Place the plots in a 2x2 matrix

   par(mfrow=c(2,2), mar=c(3,4,3,1), oma=c(3,3,5,3), mgp=c(1.75,0.5,0))

   plot(volatility_matrix[,1], volatility_matrix[,2], main="Price Volatility", xlab="Experiment", ylab="Volatility", pch=21)
   abline(lin_reg <- lm(volatility_matrix[,2]~volatility_matrix[,1]), col="red")   # regression line (volatility ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   plot(kurtosis_matrix[,1], kurtosis_matrix[,2], main="Return kurtosis", xlab="Experiment", ylab="Kurtosis", pch=21)
   abline(lin_reg <- lm(kurtosis_matrix[,2]~kurtosis_matrix[,1]), col="red")   # regression line (kurtosis ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   plot(volume_matrix[,1], volume_matrix[,2], main="Total volume", xlab="Experiment", ylab="Volume", pch=21)
   abline(lin_reg <- lm(volume_matrix[,2]~volume_matrix[,1]), col="red")   # regression line (volume ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   plot(distance_matrix[,1], distance_matrix[,2], main="Distance between price and value", xlab="Experiment", ylab="Distance", pch=21)
   abline(lin_reg <- lm(distance_matrix[,2]~distance_matrix[,1]), col="red")   # regression line (distance ~ experiment)
   mtext(paste("slope =", round(coef(lin_reg)[2],2), ",  R^2 =", round(summary(lin_reg)$r.squared,2)), side=3, line=0.1, cex=0.6, col="red")  # Add parameter file

   title(paste("Impact of changing parameter - Asset", k), outer = TRUE, col.main="blue", font.main=2)
   mtext(paste("Objective: Study which variables are affected by the changing parameter"), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# Scatterplots of volatility, kurtosis, volume and price-volume distance

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



# ----------------------------------------------- #


dev.off()  # Close output files
sink()


# ----------------------------------------------- #



# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #



#############################################################################
#                                                                           #
#                     FUTURE ANALYSES (for LS traders)                      #
#                                                                           #
#############################################################################


## ------------ BARYCENTRIC PLOT: CONTRIBUTION OF STRATEGIES TO VOLUME ------------- #
#
#require("vcd")
#
#for (e in seq(from=1, to=nExp)) {
#   for (a in seq(from=1, to=nAssets)) {
#       par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
#       if (nRuns>numRows*numCols){   
#          for (r in seq(from=step, to=step*numRows*numCols, by=step)) {
#             # Need to build a matrix with the order vectors to plot
#             orders_a_r_e <- array(0, dim=c(nTicks, 3))
#             orders_a_r_e[,1] <- abs(tsFUNDorders[[r+a+1 + (e-1)*nAssets*nRuns]])
#             orders_a_r_e[,2] <- abs(tsTRENDorders[[r+a+1 + (e-1)*nAssets*nRuns]])
#             orders_a_r_e[,3] <- abs(tsLSorders[[r+a+1 + (e-1)*nAssets*nRuns]])
#
#             # The sum of rows needs to be >0. So we delete those rows that do not satisfy this condition
#             indices <- which(orders_a_r_e[,1] + orders_a_r_e[,2] + orders_a_r_e[,3] > 0)
#             orders <- orders_a_r_e[indices,]
#
#             # Barycentric plot
#             ternaryplot(orders, dimnames=c("FUND", "TREND", "LS"), main = paste("Run", 1+r/nAssets), col="black", pch=1, cex=0.8)
#          }
#       } else {
#          for (r in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#             # Need to build a matrix with the order vectors to plot
#             orders_a_r_e <- array(0, dim=c(nTicks, 3))
#             orders_a_r_e[,1] <- abs(tsFUNDorders[[1+a + (e-1)*nAssets*nRuns]])
#             orders_a_r_e[,2] <- abs(tsTRENDorders[[1+a + (e-1)*nAssets*nRuns]])
#             orders_a_r_e[,3] <- abs(tsLSorders[[1+a + (e-1)*nAssets*nRuns]])
#
#             # The sum of rows needs to be >0. So we delete those rows that do not satisfy this condition
#             indices <- which(orders_a_r_e[,1] + orders_a_r_e[,2] + orders_a_r_e[,3] > 0)
#             orders <- orders_a_r_e[indices,]
#
#             # Barycentric plot
#             ternaryplot(orders, dimnames=c("FUND", "TREND", "LS"), main = paste("Run", 1+(r-1)/nAssets), col="black", pch=1, cex=0.8)
#         }
#      }
#      title(paste("Weight of each strategy in total volume - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}


## ------------ DO PRICES TEND TO MEAN? ------------- #
#
## Objective: As LS strategies can push prices (or returns?) towards mean values,
## we plot here the price of each asset versus the mean of all assets
## to study if an increasing percentage of LS (different experiments) makes a difference
#
#
## Calculate average of prices over all assets
#
#tsprices_avg_avg <- array(0, dim=c(nTicks, nExp))
#tsreturns_avg_avg <- array(0, dim=c(nTicks-1, nExp))
#
#for (i in seq(from=1, to=nExp)) {
#   for (j in seq(from=1, to=nAssets)) {
#      tsprices_avg_avg[,i] <- tsprices_avg_avg[,i] + tsprices_avg[,(i-1)*nAssets+j]
#      tsreturns_avg_avg[,i] <- tsreturns_avg_avg[,i] + diff(tsprices_avg[,(i-1)*nAssets+j])
#   }
#   tsprices_avg_avg[,i] <- tsprices_avg_avg[,i]/nAssets
#   tsreturns_avg_avg[,i] <- tsreturns_avg_avg[,i]/nAssets
#}
#
#
### Plot of prices vs mean
##
##y_max = max(max(tsprices_avg[,1:(nAssets*nExp)]), max(tsprices_avg_avg[,1:(nExp)]))
##y_min = min(min(tsprices_avg[,1:(nAssets*nExp)]), min(tsprices_avg_avg[,1:(nExp)]))
##
##par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
##for (i in seq(from=1, to=nExp)) {
##   plot(tsprices_avg_avg[,i], type="l", col="red", main=paste("Experiment", i), ylim=c(y_min,y_max),
##    	xlab="Tick", ylab="Prices", lwd=3)
##   for (j in seq(from=1, to=nAssets)) {
##      lines(tsprices_avg[,(i-1)*nAssets+j], type="l", col="black")
##   }
##}
##title("Prices of each asset vs mean (over runs)", outer = TRUE, col.main="blue", font.main=2)
##mtext("Objective: Study if prices tend to the mean price (over assets) when the proportion of LS's increases (over experiments).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
##mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
##
#
### Plot of log-returns vs mean
##
##y_max = max(max(diff(tslogprices_avg[,1:(nAssets*nExp)])), max(tslogreturns_avg_avg[,1:(nExp)]))
##y_min = min(min(diff(tslogprices_avg[,1:(nAssets*nExp)])), min(tslogreturns_avg_avg[,1:(nExp)]))
##
##par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
##for (i in seq(from=1, to=nExp)) {
##   plot(tslogreturns_avg_avg[,i], type="l", col="red", main=paste("Experiment", i), ylim=c(y_min,y_max),
##    	xlab="Tick", ylab="Log-returns", lwd=3)
##   for (j in seq(from=1, to=nAssets)) {
##      lines(diff(tslogprices_avg[,(i-1)*nAssets+j]), type="l", col="black")
##   }
##}
##title("Log-returns of each asset vs mean (over runs)", outer = TRUE, col.main="blue", font.main=2)
##mtext("Objective: Study if log-returns tend to the mean return (over assets) when the proportion of LS's increases (over experiments).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
##mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
##
#
## Calculate distance of each price series to mean
#
#dist_prices <- array(0, dim=c(nExp, nAssets))
#
#for (i in seq(from=1, to=nExp)) {
#   for (j in seq(from=1, to=nAssets)) {
#      dist_prices[i,j] <- sqrt(sum((tsprices_avg[,(i-1)*nAssets+j] - tsprices_avg_avg[,i])^2))/nTicks
#   }
#}
#
## Plot distance of each asset price to mean of prices (for each experiment)
#
## To provide information in the x axis on e.g. the percentage of HF's: create a vector with the percentages, e.g.:
## x <- c(0.1, 0.2, 0.3, 0.4, 0.5)
## matplot(x, dist_prices, type="l", lty=1, col="black")
#
#par(mfrow=c(1,1), mar=c(5,4,6,1), oma=c(2,2,2,2), mgp=c(3,1,0))  # Margins adjusted so that title and axes labels are properly shown
#matplot(dist_prices, type="l", lty=1, col=1:10, xlab="Experiment", main="Distance of asset prices to mean", col.main="blue")
#legend("topleft", c("Asset 1","Asset 2", "Asset 3"), lty=c(1,1), col=1:10)
#mtext("Objective: study if prices tend to mean price (over assets) when the proportion of HFs increases.", side=3, line=-5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
#mtext(paste("Parameters:", param_file), side=1, line=5, cex=0.75)  # Add parameter file
#


#############################################################################
#                                                                           #
#                        GRAPHICS NOT USED  - DELETE                        #
#                                                                           #
#############################################################################


#_____________________________________________________________#
#                                                             #
#            TIME SERIES OF VOLATILITY vs VOLUME              #
#_____________________________________________________________#
#                                                             #

### Plot the time series of price volatility along with the time series of 
# volume moved by FUNDs and TRENDs

## !!! EXTREMELY EXPENSIVE TO CALCULATE THESE MATRICES
#
## Calculate time series of price volatility using a moving window
#
#mw = 250  # Length of moving window
#tsvolatility <- array(0, dim=c(nTicks, nAssets*nRuns*nExp))
#
#for (j in seq(from=1, to=nAssets*nRuns*nExp)) {
#   for (i in seq(from=1, to=nTicks-mw)) {
#      tsvolatility[i+mw,j] <- sd(tsprices[[j+1]][i:(i+mw-1)], na.rm = FALSE)
#   }
#}
#
## Plot volatility with volume
## A double Y scale needs to be drawn
#
#y_max = max(max(tsFUNDvolume[,2:(nAssets*nExp*nRuns)]), max(tsTRENDvolume[,2:(nAssets*nExp*nRuns)]))
#y_min = min(min(tsFUNDvolume[,2:(nAssets*nExp*nRuns)]), min(tsTRENDvolume[,2:(nAssets*nExp*nRuns)]))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(4, 7, 2, 2) + 0.1, oma=c(3,3,5,3))
#      x_axis <-seq(1,nTicks,1) 	# Plot first time series
# 
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#            plot(x_axis, tsvolatility[,i+k+(e-1)*nAssets*nRuns], axes=F, ylim=c(0,max(tsvolatility)), xlab="", ylab="",type="l",col="black", main=paste("Run", 1+i/nAssets),xlim=c(1,nTicks))
#            axis(2, ylim=c(0,max(tsvolatility)),col="black",lwd=2)
#            mtext(2,text="Volatility",line=2,cex=0.75)
#
#            par(new=T)  # Plot second time series
#            plot(x_axis, tsFUNDvolume[,i+k+1+(e-1)*nAssets*nRuns], axes=F, ylim=c(y_min,y_max), xlab="", ylab="", 
#            type="l",lty=1, main="",xlim=c(1,nTicks),lwd=1, col="red")
#            axis(2, ylim=c(y_min,y_max),lwd=2,line=3.5)
#            mtext(2,text="Volume",line=5.5,cex=0.75,col="red")
#            axis(1,pretty(range(x_axis),10))   # Add x axis            
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(x_axis, tsvolatility[,i-1+k +(e-1)*nAssets*nRuns], axes=F, ylim=c(0,max(tsvolatility)), xlab="", ylab="",type="l",col="black", main=paste("Run", 1+(i-1)/nAssets),xlim=c(1,nTicks))
#            axis(2, ylim=c(0,max(tsvolatility)),col="black",lwd=2)
#            mtext(2,text="Volatility",line=2,cex=0.75)
#
#            par(new=T)  # Plot second time series
#            plot(x_axis, tsFUNDvolume[,i+k +(e-1)*nAssets*nRuns], axes=F, ylim=c(y_min,y_max), xlab="", ylab="", 
#            type="l",lty=1, main="",xlim=c(1,nTicks),lwd=1, col="red")
#            axis(2, ylim=c(y_min,y_max),lwd=2,line=3.5)
#            mtext(2,text="Volume",line=5.5,cex=0.75,col="red")
#            axis(1,pretty(range(x_axis),10))   # Add x axis
#         }
#      }
#      #legend("topleft", c("Volatility","Volume"), col=c("black", "red"), lty=1)  # Add legend      
#      title(paste("Volatility vs. trading volume - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext(paste("Objective: Study relationship between volatility and volume. Window =", mw), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}



#________________________________________________________________#
#                                                                #
#          TIME SERIES OF KURTOSIS vs ELEMENTS IN TAILS          #
#________________________________________________________________#
#                                                                #

### Plot the time series of kurtosis along with the time series of number of
# log returns in tails (beyond 2 sigmas) to see their relationship 

## !!! EXTREMELY EXPENSIVE TO CALCULATE THESE MATRICES
#
## Calculate time series of log-return kurtosis using a moving window
#mw = 250  # Length of moving window
#tskurt <- array(0, dim=c(nTicks, nAssets*nRuns*nExp))
#elements_in_tails <- array(0, dim=c(nTicks, nAssets*nRuns*nExp))
#
#for (j in seq(from=1, to=nAssets*nRuns*nExp)) {
#   log_return_mean <- mean(diff(tslogprices[[j+1]]))
#   log_return_std <- sd(diff(tslogprices[[j+1]]))
#
#   for (i in seq(from=1, to=nTicks-mw)) {
#      tskurt[i+mw,j] <- kurtosis(diff(tslogprices[[j+1]])[i:(i+mw-1)], na.rm = FALSE, method="excess")[1]
#
#      # Count elements beyond 2 sigmas
#      elements_in_tails[i+mw,j] <- length(subset(diff(tslogprices[[j+1]])[i:(i+mw-1)], abs(diff(tslogprices[[j+1]])[i:(i+mw-1)] - log_return_mean) > 2*log_return_std))
#   }
#}

### Plot kurtosis with elements_in_tails
# A double Y scale needs to be drawn

#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(4, 7, 2, 2) + 0.1, oma=c(3,3,5,3))
#      x_axis <- seq(1,nTicks,1) 	# Plot first time series
# 
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#            plot(x_axis, tskurt[,i+k+(e-1)*nAssets*nRuns], axes=F, ylim=c(0,max(tskurt)), xlab="", ylab="",type="l",col="black", main=paste("Run", 1+i/nAssets),xlim=c(1,nTicks))
#            axis(2, ylim=c(0,max(tskurt)),col="black",lwd=2)
#            mtext(2,text="Kurtosis",line=2,cex=0.75)
#
#            par(new=T)  # Plot second time series
#            plot(x_axis, elements_in_tails[,i+k+(e-1)*nAssets*nRuns], axes=F, ylim=c(0,max(elements_in_tails)), xlab="", ylab="", 
#            type="l",lty=1, main="",xlim=c(1,nTicks),lwd=1, col="green")
#            axis(2, ylim=c(0,max(elements_in_tails)),lwd=2,line=3.5)
#            mtext(2,text="Elements in tails",line=5.5,cex=0.75,col="green")        
#            axis(1,pretty(range(x_axis),10))   # Add x axis            
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(x_axis, tskurt[,i-1+k +(e-1)*nAssets*nRuns], axes=F, ylim=c(0,max(tskurt)), xlab="", ylab="",type="l",col="black", main=paste("Run", 1+(i-1)/nAssets),xlim=c(1,nTicks))
#            axis(2, ylim=c(0,max(tskurt)),col="black",lwd=2)
#            mtext(2,text="Kurtosis",line=2,cex=0.75)
#
#            par(new=T)  # Plot second time series
#            plot(x_axis, elements_in_tails[,i-1+k +(e-1)*nAssets*nRuns], axes=F, ylim=c(0,max(elements_in_tails)), xlab="", ylab="", 
#            type="l",lty=1, main="",xlim=c(1,nTicks),lwd=1, col="green")
#            axis(2, ylim=c(0,max(elements_in_tails)),lwd=2,line=3.5)
#            mtext(2,text="Elements in tails",line=5.5,cex=0.75,col="green")
#            axis(1,pretty(range(x_axis),10))   # Add x axis
#         }
#      }
#      #legend("topleft", c("Kurtosis","Elements in tails"),col=c("black","green"), lty=1)  # Add legend      
#      title(paste("Kurtosis vs. frequency of log returns beyond 2 sigmas - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext(paste("Objective: Study relationship between kurtosis and extreme returns, which should move in the same direction. Window=", mw), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}


### Plot the time series of kurtosis along with the time series of prices to
# see how the kurtosis changes with the movements in price

##y_min = min(tsprices[,2:(nAssets*nExp*nRuns+1)])  # Range of y axis for log-prices
##y_max = max(tsprices[,2:(nAssets*nExp*nRuns+1)])
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nAssets)) {
#      par(mfrow=c(numRows,numCols), mar=c(4, 7, 2, 2) + 0.1, oma=c(3,3,5,3))
#      x_axis <- seq(1,nTicks,1) 	# Plot first time series
# 
#      if (nRuns>numRows*numCols){   
#         for (i in seq(from=step, to=step*numRows*numCols, by=step)) {
#            plot(x_axis, tskurt[,i+k+(e-1)*nAssets*nRuns], axes=F, ylim=c(0,max(tskurt)), xlab="", ylab="",type="l",col="black", main=paste("Run", 1+i/nAssets),xlim=c(1,nTicks))
#            axis(2, ylim=c(0,max(tskurt)),col="black",lwd=2)
#            mtext(2,text="Kurtosis",line=2,cex=0.75)
#
#            par(new=T)  # Plot second time series
#            plot(x_axis, tsprices[,i+k+1+(e-1)*nAssets*nRuns], axes=F, xlab="", ylab="", 
#            type="l",lty=1, main="",xlim=c(1,nTicks),lwd=1, col="blue")
#            axis(2,lwd=2,line=3.5)
#            mtext(2,text="Prices",line=5.5,cex=0.75,col="blue")            
#            axis(1,pretty(range(x_axis),10))   # Add x axis            
#         }
#      } else {
#         for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
#            plot(x_axis, tskurt[,i-1+k +(e-1)*nAssets*nRuns], axes=F, ylim=c(0,max(tskurt)), xlab="", ylab="",type="l",col="black", main=paste("Run", 1+(i-1)/nAssets),xlim=c(1,nTicks))
#            axis(2, ylim=c(0,max(tskurt)),col="black",lwd=2)
#            mtext(2,text="Kurtosis",line=2,cex=0.75)
#
#            par(new=T)  # Plot second time series
#            plot(x_axis, tsprices[,i+k+(e-1)*nAssets*nRuns], axes=F, xlab="", ylab="", 
#            type="l",lty=1, main="",xlim=c(1,nTicks),lwd=1, col="blue")
#            axis(2,lwd=2,line=3.5)
#            mtext(2,text="Prices",line=5.5,cex=0.75,col="blue")
#            axis(1,pretty(range(x_axis),10))   # Add x axis
#         }
#      }
#      #legend("topleft", c("Kurtosis","Prices"),col=c("black","blue"), lwd=1, lty=1)  # Add legend      
#      title(paste("Kurtosis vs. prices - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
#      mtext(paste("Objective: Study relationship between kurtosis and prices. Window =", mw), side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the graph objective
#      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
#   }
#}


# --------------------------------------------------------------- #



