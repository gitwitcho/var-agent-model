
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

nAssets = 3   # DO NOT CHANGE THE NUMBER OF ASSETS!!
nExp = 1

# Setting the path to the data folder

# Set the root directory (add your path)
root.dir <- "C:/Users/llacay/eclipse"

# Build the home directory (shouldn't be necessary to change)
home.dir <- paste(root.dir, "/agentsimulator/out/trend-value-ls-abm-simulation/", sep="")


# Read data from csv files for each experiment

tsprices <- read.table(paste(home.dir,"list_price_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

if (nExp > 1) {   # Read data for single experiments and merge them
   for (e in seq(from=1, to=nExp-1)) {
      tsprices_exp <- read.table(paste(home.dir, paste("list_price_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsprices <- merge(tsprices, tsprices_exp, by="tick")
   }
}


# Parameters needed from the java files

nRuns <- (dim(tsprices)[2] - 1)/(nAssets*nExp)
nTicks <- dim(tsprices)[1]

param_file = "trend_value_ls_3_assets_abm_001"  # Parameter file

# Plots are distributed in a matrix. Choose here the dimensions of the matrix

numRows <- 3  # Dimensions of matrix of plots
numCols <- 3
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


# ------ Calculate the mean value of CCF over all runs for each asset ------ #
# Note: This is done at the beginning to avoid that auxiliary CCFs are plotted in the pdf

aux_ccf <- ccf(diff(tslogprices[[2]]), diff(tslogprices[[3]]), main="IGNORE (Auxiliary calculation)")  # Calculate how many lags R uses in the CCF plot
nlags <- length(aux_ccf$acf)

mean_CCF_returns_12 <- array(0, dim=c(nlags, nExp)) # Arrays to store mean CCF's at each lag over all runs (for each pair of assets and experiment)
mean_CCF_returns_13 <- array(0, dim=c(nlags, nExp))
mean_CCF_returns_23 <- array(0, dim=c(nlags, nExp))

mean_CCF_absreturns_12 <- array(0, dim=c(nlags, nExp)) 
mean_CCF_absreturns_13 <- array(0, dim=c(nlags, nExp)) 
mean_CCF_absreturns_23 <- array(0, dim=c(nlags, nExp)) 

mean_CCF_squaredreturns_12 <- array(0, dim=c(nlags, nExp))
mean_CCF_squaredreturns_13 <- array(0, dim=c(nlags, nExp))
mean_CCF_squaredreturns_23 <- array(0, dim=c(nlags, nExp))


Max_CCF_returns_12 <- array(0, dim=c(nlags, nExp)) # Arrays to store the max and min CCF at each lag over all runs (for each pair of assets and experiment)
Min_CCF_returns_12 <- array(0, dim=c(nlags, nExp))
Max_CCF_returns_13 <- array(0, dim=c(nlags, nExp))
Min_CCF_returns_13 <- array(0, dim=c(nlags, nExp))
Max_CCF_returns_23 <- array(0, dim=c(nlags, nExp))
Min_CCF_returns_23 <- array(0, dim=c(nlags, nExp))

Max_CCF_absreturns_12 <- array(0, dim=c(nlags, nExp))
Min_CCF_absreturns_12 <- array(0, dim=c(nlags, nExp))
Max_CCF_absreturns_13 <- array(0, dim=c(nlags, nExp))
Min_CCF_absreturns_13 <- array(0, dim=c(nlags, nExp))
Max_CCF_absreturns_23 <- array(0, dim=c(nlags, nExp))
Min_CCF_absreturns_23 <- array(0, dim=c(nlags, nExp))

Max_CCF_squaredreturns_12 <- array(0, dim=c(nlags, nExp))
Min_CCF_squaredreturns_12 <- array(0, dim=c(nlags, nExp))
Max_CCF_squaredreturns_13 <- array(0, dim=c(nlags, nExp))
Min_CCF_squaredreturns_13 <- array(0, dim=c(nlags, nExp))
Max_CCF_squaredreturns_23 <- array(0, dim=c(nlags, nExp))
Min_CCF_squaredreturns_23 <- array(0, dim=c(nlags, nExp))


# ... Asset 1 vs Asset 2 (IBM vs MSFT) ... #

asset_CCF_matrix <- array(0, dim=c(nlags, nRuns))  # Auxiliary array to store the CCF's for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with CCF of assets 1&2 for each run
      aux_ccf <- ccf(diff(tslogprices[[1+1+j*nAssets+k*nAssets*nRuns]]), diff(tslogprices[[2+1+j*nAssets+k*nAssets*nRuns]]), main="IGNORE (Auxiliary calculation)") 
      asset_CCF_matrix[,j+1] = aux_ccf$acf   # Store the vector of correlations
   }

   for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
      mean_CCF_returns_12[r,k+1] = mean(asset_CCF_matrix[r,])
      Max_CCF_returns_12[r,k+1] = max(asset_CCF_matrix[r,])
      Min_CCF_returns_12[r,k+1] = min(asset_CCF_matrix[r,])
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with CCF of assets 1&2 for each run
      aux_ccf <- ccf(abs(diff(tslogprices[[1+1+j*nAssets+k*nAssets*nRuns]])), abs(diff(tslogprices[[2+1+j*nAssets+k*nAssets*nRuns]])), main="IGNORE (Auxiliary calculation)") 
      asset_CCF_matrix[,j+1] = aux_ccf$acf   # Store the vector of correlations
   }

   for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
      mean_CCF_absreturns_12[r,k+1] = mean(asset_CCF_matrix[r,])
      Max_CCF_absreturns_12[r,k+1] = max(asset_CCF_matrix[r,])
	Min_CCF_absreturns_12[r,k+1] = min(asset_CCF_matrix[r,])
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with CCF of assets 1&2 for each run
      aux_ccf <- ccf((diff(tslogprices[[1+1+j*nAssets+k*nAssets*nRuns]]))^2, (diff(tslogprices[[2+1+j*nAssets+k*nAssets*nRuns]]))^2, main="IGNORE (Auxiliary calculation)") 
      asset_CCF_matrix[,j+1] = aux_ccf$acf   # Store the vector of correlations
   }

   for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
      mean_CCF_squaredreturns_12[r,k+1] = mean(asset_CCF_matrix[r,])
      Max_CCF_squaredreturns_12[r,k+1] = max(asset_CCF_matrix[r,])
      Min_CCF_squaredreturns_12[r,k+1] = min(asset_CCF_matrix[r,])
   }
}


# ... Asset 1 vs Asset 3 (IBM vs GOOG) ... #

asset_CCF_matrix <- array(0, dim=c(nlags, nRuns))  # Auxiliary array to store the CCF's for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with CCF of assets 1&3 for each run
      aux_ccf <- ccf(diff(tslogprices[[1+1+j*nAssets+k*nAssets*nRuns]]), diff(tslogprices[[3+1+j*nAssets+k*nAssets*nRuns]]), main="IGNORE (Auxiliary calculation)") 
      asset_CCF_matrix[,j+1] = aux_ccf$acf   # Store the vector of correlations
   }

   for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
      mean_CCF_returns_13[r,k+1] = mean(asset_CCF_matrix[r,])
      Max_CCF_returns_13[r,k+1] = max(asset_CCF_matrix[r,])
      Min_CCF_returns_13[r,k+1] = min(asset_CCF_matrix[r,])
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with CCF of assets 1&3 for each run
      aux_ccf <- ccf(abs(diff(tslogprices[[1+1+j*nAssets+k*nAssets*nRuns]])), abs(diff(tslogprices[[3+1+j*nAssets+k*nAssets*nRuns]])), main="IGNORE (Auxiliary calculation)") 
      asset_CCF_matrix[,j+1] = aux_ccf$acf   # Store the vector of correlations
   }

   for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
      mean_CCF_absreturns_13[r,k+1] = mean(asset_CCF_matrix[r,])
      Max_CCF_absreturns_13[r,k+1] = max(asset_CCF_matrix[r,])
	Min_CCF_absreturns_13[r,k+1] = min(asset_CCF_matrix[r,])
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with CCF of assets 1&3 for each run
      aux_ccf <- ccf((diff(tslogprices[[1+1+j*nAssets+k*nAssets*nRuns]]))^2, (diff(tslogprices[[3+1+j*nAssets+k*nAssets*nRuns]]))^2, main="IGNORE (Auxiliary calculation)") 
      asset_CCF_matrix[,j+1] = aux_ccf$acf   # Store the vector of correlations
   }

   for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
      mean_CCF_squaredreturns_13[r,k+1] = mean(asset_CCF_matrix[r,])
      Max_CCF_squaredreturns_13[r,k+1] = max(asset_CCF_matrix[r,])
      Min_CCF_squaredreturns_13[r,k+1] = min(asset_CCF_matrix[r,])
   }
}


# ... Asset 2 vs Asset 3 (MSFT vs GOOG) ... #

asset_CCF_matrix <- array(0, dim=c(nlags, nRuns))  # Auxiliary array to store the CCF's for one asset (over all runs)

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with CCF of assets 2&3 for each run
      aux_ccf <- ccf(diff(tslogprices[[2+1+j*nAssets+k*nAssets*nRuns]]), diff(tslogprices[[3+1+j*nAssets+k*nAssets*nRuns]]), main="IGNORE (Auxiliary calculation)") 
      asset_CCF_matrix[,j+1] = aux_ccf$acf   # Store the vector of correlations
   }

   for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
      mean_CCF_returns_23[r,k+1] = mean(asset_CCF_matrix[r,])
      Max_CCF_returns_23[r,k+1] = max(asset_CCF_matrix[r,])
      Min_CCF_returns_23[r,k+1] = min(asset_CCF_matrix[r,])
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with CCF of assets 2&3 for each run
      aux_ccf <- ccf(abs(diff(tslogprices[[2+1+j*nAssets+k*nAssets*nRuns]])), abs(diff(tslogprices[[3+1+j*nAssets+k*nAssets*nRuns]])), main="IGNORE (Auxiliary calculation)") 
      asset_CCF_matrix[,j+1] = aux_ccf$acf   # Store the vector of correlations
   }

   for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
      mean_CCF_absreturns_23[r,k+1] = mean(asset_CCF_matrix[r,])
      Max_CCF_absreturns_23[r,k+1] = max(asset_CCF_matrix[r,])
	Min_CCF_absreturns_23[r,k+1] = min(asset_CCF_matrix[r,])
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=0, to=nRuns-1)){     # Calculate matrix with CCF of assets 2&3 for each run
      aux_ccf <- ccf((diff(tslogprices[[2+1+j*nAssets+k*nAssets*nRuns]]))^2, (diff(tslogprices[[3+1+j*nAssets+k*nAssets*nRuns]]))^2, main="IGNORE (Auxiliary calculation)") 
      asset_CCF_matrix[,j+1] = aux_ccf$acf   # Store the vector of correlations
   }

   for (r in seq(from=1, to=nlags)) {   # Select max/min autocorrelation at each lag over all runs
      mean_CCF_squaredreturns_23[r,k+1] = mean(asset_CCF_matrix[r,])
      Max_CCF_squaredreturns_23[r,k+1] = max(asset_CCF_matrix[r,])
      Min_CCF_squaredreturns_23[r,k+1] = min(asset_CCF_matrix[r,])
   }
}




#######################################################################################################

# Open files to write the results

pdf(paste(home.dir, "Trend_Value_LS_Multivariate_ABM_Exp_001_outR.pdf", sep=""))   # Plot diagrams in a pdf file


#####################################################################
#                                                                   #
#           VALIDATION TESTS (Multi-asset stylised facts)           #
#                                                                   #
#####################################################################


# Plots over different runs are shown in a matrix
# If there are more runs than positions in the matrix, 
# only a a selection of the plots is shown


#_________________________________________________________________________________#
#                                                                                 # 
#          TEST VA-Multivariate_ABM-1.0: CCF OF LOG-RETURNS OF DIFFERENT ASSETS          #
#_________________________________________________________________________________#
#                                                                                 #
      
# ------ CCF of log-returns for single runs ------ #

# Objective: For each experiment, plot a selection of CCF of the 
# log-returns of the different pairs of assets for single runs

# ... Asset 1 vs asset 2 (IBM vs MSFT) ... #

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
         ccf(diff(tslogprices[[i+1+1+(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+1+2+(e-1)*nAssets*nRuns]]), ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
      }
   } else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         ccf(diff(tslogprices[[i+1 +(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+2 +(e-1)*nAssets*nRuns]]), ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
      }
   }
   title(paste("VA-Multivariate_ABM-1.0.1 - CCF of log-returns - Asset 1 vs Asset 2 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: CCF should decay quickly to zero (that is, it should lie between the dashed lines).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ... Asset 1 vs asset 3 (IBM vs GOOG) ... #

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
         ccf(diff(tslogprices[[i+1+1+(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+1+3+(e-1)*nAssets*nRuns]]), ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
      }
   } else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         ccf(diff(tslogprices[[i+1 +(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+3 +(e-1)*nAssets*nRuns]]), ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
      }
   }
   title(paste("VA-Multivariate_ABM-1.0.1 - CCF of log-returns - Asset 1 vs Asset 3 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: CCF should decay quickly to zero (that is, it should lie between the dashed lines).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ... Asset 2 vs asset 3 (MSFT vs GOOG) ... #

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
         ccf(diff(tslogprices[[i+1+2+(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+1+3+(e-1)*nAssets*nRuns]]), ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
      }
   } else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         ccf(diff(tslogprices[[i+2 +(e-1)*nAssets*nRuns]]), diff(tslogprices[[i+3 +(e-1)*nAssets*nRuns]]), ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
      }
   }
   title(paste("VA-Multivariate_ABM-1.0.1 - CCF of log-returns - Asset 2 vs Asset 3 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: CCF should decay quickly to zero (that is, it should lie between the dashed lines).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}



# ------ Average CCF of log-returns (over runs) ------ #

# Objective: Plot a summary of the CCF along experiments

# ... Asset 1 vs asset 2 (IBM vs MSFT) ... #

upper_bound = rep(-1/nTicks+2/sqrt(nTicks), nrow(mean_CCF_returns_12))
lower_bound = rep(-1/nTicks-2/sqrt(nTicks), nrow(mean_CCF_returns_12))

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(mean_CCF_returns_12[,e], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Cross-correlations")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")      
}
title(paste("VA-Multivariate_ABM-1.0.1 - Average CCF of log-returns (over runs) - Asset 1 vs Asset 2"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Test description: CCF should decay quickly to zero (that is, it should lie between the dashed lines).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file

# ... Asset 1 vs asset 3 (IBM vs GOOG) ... #

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(mean_CCF_returns_13[,e], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Cross-correlations")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")      
}
title(paste("VA-Multivariate_ABM-1.0.1 - Average CCF of log-returns (over runs) - Asset 1 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Test description: CCF should decay quickly to zero (that is, it should lie between the dashed lines).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file

# ... Asset 2 vs asset 3 (MSFT vs GOOG) ... #

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(mean_CCF_returns_23[,e], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Cross-correlations")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")      
}
title(paste("VA-Multivariate_ABM-1.0.1 - Average CCF of log-returns (over runs) - Asset 2 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Test description: CCF should decay quickly to zero (that is, it should lie between the dashed lines).", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



# ------ Variation in CCF of log-returns ------ #

# Plot the maximum and minimum CCF for each experiment
# Objective: Study the range of variation of CCF over experiments

# ... Asset 1 vs asset 2 (IBM vs MSFT) ... #

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (k in seq(from=0, to=nExp-1)) {
   #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
   xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
   yy <- c(Min_CCF_returns_12[,k+1], rev(Max_CCF_returns_12[,k+1]))
   plot(xx,yy, type="l", main=paste("Exp", k+1), 
   xlab="Lag", ylab=paste("CCF - Asset 1 vs Asset 2"), lwd=1, ylim=c(-1,1))
   polygon(xx, yy, col="gray")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")   
}
title(paste("VA-Multivariate_ABM-1.0.1 - Range of variation of CCF of log-returns - Asset 1 vs Asset 2"), outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the max/min values of ACF of log-returns. It should decay rapidly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


# ... Asset 1 vs asset 3 (IBM vs GOOG) ... #

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (k in seq(from=0, to=nExp-1)) {
   #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
   xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
   yy <- c(Min_CCF_returns_13[,k+1], rev(Max_CCF_returns_13[,k+1]))
   plot(xx,yy, type="l", main=paste("Exp", k+1), 
   xlab="Lag", ylab=paste("CCF - Asset 1 vs Asset 3"), lwd=1, ylim=c(-1,1))
   polygon(xx, yy, col="gray")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")   
}
title(paste("VA-Multivariate_ABM-1.0.1 - Range of variation of CCF of log-returns - Asset 1 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the max/min values of ACF of log-returns. It should decay rapidly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


# ... Asset 2 vs asset 3 (MSFT vs GOOG) ... #

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (k in seq(from=0, to=nExp-1)) {
   #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
   xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
   yy <- c(Min_CCF_returns_23[,k+1], rev(Max_CCF_returns_23[,k+1]))
   plot(xx,yy, type="l", main=paste("Exp", k+1), 
   xlab="Lag", ylab=paste("CCF - Asset 2 vs Asset 3"), lwd=1, ylim=c(-1,1))
   polygon(xx, yy, col="gray")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")   
}
title(paste("VA-Multivariate_ABM-1.0.1 - Range of variation of CCF of log-returns - Asset 2 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the max/min values of ACF of log-returns. It should decay rapidly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file




#________________________________________________________________________________________________#
#                                                                                                # 
#          TEST VA-Multivariate_ABM-1.0: CCF OF ABSOLUTE LOG-RETURNS OF DIFFERENT ASSETS          #
#________________________________________________________________________________________________#
#                                                                                                #
      
# ------ CCF of ABSOLUTE log-returns for single runs ------ #

# Objective: For each experiment, plot a selection of CCF of the 
# absolute log-returns of the different pairs of assets for single runs

# ... Asset 1 vs asset 2 (IBM vs MSFT) ... #

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
         ccf(abs(diff(tslogprices[[i+1+1+(e-1)*nAssets*nRuns]])), abs(diff(tslogprices[[i+1+2+(e-1)*nAssets*nRuns]])), ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
      }
   } else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         ccf(abs(diff(tslogprices[[i+1 +(e-1)*nAssets*nRuns]])), abs(diff(tslogprices[[i+2 +(e-1)*nAssets*nRuns]])), ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
      }
   }
   title(paste("VA-Multivariate_ABM-1.0.1 - CCF of absolute log-returns - Asset 1 vs Asset 2 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: CCF should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ... Asset 1 vs asset 3 (IBM vs GOOG) ... #

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
         ccf(abs(diff(tslogprices[[i+1+1+(e-1)*nAssets*nRuns]])), abs(diff(tslogprices[[i+1+3+(e-1)*nAssets*nRuns]])), ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
      }
   } else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         ccf(abs(diff(tslogprices[[i+1 +(e-1)*nAssets*nRuns]])), abs(diff(tslogprices[[i+3 +(e-1)*nAssets*nRuns]])), ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
      }
   }
   title(paste("VA-Multivariate_ABM-1.0.1 - CCF of absolute log-returns - Asset 1 vs Asset 3 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: CCF should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ... Asset 2 vs asset 3 (MSFT vs GOOG) ... #

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
         ccf(abs(diff(tslogprices[[i+1+2+(e-1)*nAssets*nRuns]])), abs(diff(tslogprices[[i+1+3+(e-1)*nAssets*nRuns]])), ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
      }
   } else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         ccf(abs(diff(tslogprices[[i+2 +(e-1)*nAssets*nRuns]])), abs(diff(tslogprices[[i+3 +(e-1)*nAssets*nRuns]])), ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
      }
   }
   title(paste("VA-Multivariate_ABM-1.0.1 - CCF of absolute log-returns - Asset 2 vs Asset 3 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: CCF should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}



# ------ Average CCF of ABSOLUTE log-returns (over runs) ------ #

# Objective: Plot a summary of the CCF along experiments

# ... Asset 1 vs asset 2 (IBM vs MSFT) ... #

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(mean_CCF_absreturns_12[,e], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Cross-correlations")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")      
}
title(paste("VA-Multivariate_ABM-1.0.1 - Average CCF of absolute log-returns (over runs) - Asset 1 vs Asset 2"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Test description: CCF should remain positive (that is, above the dashed lines) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file

# ... Asset 1 vs asset 3 (IBM vs GOOG) ... #

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(mean_CCF_absreturns_13[,e], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Cross-correlations")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")      
}
title(paste("VA-Multivariate_ABM-1.0.1 - Average CCF of absolute log-returns (over runs) - Asset 1 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Test description: CCF should remain positive (that is, above the dashed lines) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file

# ... Asset 2 vs asset 3 (MSFT vs GOOG) ... #

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(mean_CCF_absreturns_23[,e], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Cross-correlations")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")      
}
title(paste("VA-Multivariate_ABM-1.0.1 - Average CCF of absolute log-returns (over runs) - Asset 2 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Test description: CCF should remain positive (that is, above the dashed lines) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



# ------ Variation in CCF of ABSOLUTE log-returns ------ #

# Plot the maximum and minimum CCF for each experiment
# Objective: Study the range of variation of CCF over experiments

# ... Asset 1 vs asset 2 (IBM vs MSFT) ... #

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (k in seq(from=0, to=nExp-1)) {
   #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
   xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
   yy <- c(Min_CCF_absreturns_12[,k+1], rev(Max_CCF_absreturns_12[,k+1]))
   plot(xx,yy, type="l", main=paste("Exp", k+1), 
   xlab="Lag", ylab=paste("CCF - Asset 1 vs Asset 2"), lwd=1, ylim=c(-1,1))
   polygon(xx, yy, col="gray")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")   
}
title(paste("VA-Multivariate_ABM-1.0.1 - Range of variation of CCF of absolute log-returns - Asset 1 vs Asset 2"), outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the max/min values of ACF of absolute log-returns. It should decay rapidly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


# ... Asset 1 vs asset 3 (IBM vs GOOG) ... #

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (k in seq(from=0, to=nExp-1)) {
   #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
   xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
   yy <- c(Min_CCF_absreturns_13[,k+1], rev(Max_CCF_absreturns_13[,k+1]))
   plot(xx,yy, type="l", main=paste("Exp", k+1), 
   xlab="Lag", ylab=paste("CCF - Asset 1 vs Asset 3"), lwd=1, ylim=c(-1,1))
   polygon(xx, yy, col="gray")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")   
}
title(paste("VA-Multivariate_ABM-1.0.1 - Range of variation of CCF of absolute log-returns - Asset 1 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the max/min values of ACF of absolute log-returns. It should decay rapidly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


# ... Asset 2 vs asset 3 (MSFT vs GOOG) ... #

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (k in seq(from=0, to=nExp-1)) {
   #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
   xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
   yy <- c(Min_CCF_absreturns_23[,k+1], rev(Max_CCF_absreturns_23[,k+1]))
   plot(xx,yy, type="l", main=paste("Exp", k+1), 
   xlab="Lag", ylab=paste("CCF - Asset 2 vs Asset 3"), lwd=1, ylim=c(-1,1))
   polygon(xx, yy, col="gray")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")   
}
title(paste("VA-Multivariate_ABM-1.0.1 - Range of variation of CCF of absolute log-returns - Asset 2 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the max/min values of ACF of absolute log-returns. It should decay rapidly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file





#_______________________________________________________________________________________________#
#                                                                                               # 
#          TEST VA-Multivariate_ABM-1.0: CCF OF SQUARED LOG-RETURNS OF DIFFERENT ASSETS          #
#_______________________________________________________________________________________________#
#                                                                                               #
      
# ------ CCF of SQUARED log-returns for single runs ------ #

# Objective: For each experiment, plot a selection of CCF of the 
# squared log-returns of the different pairs of assets for single runs

# ... Asset 1 vs asset 2 (IBM vs MSFT) ... #

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
         ccf((diff(tslogprices[[i+1+1+(e-1)*nAssets*nRuns]]))^2, (diff(tslogprices[[i+1+2+(e-1)*nAssets*nRuns]]))^2, ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
      }
   } else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         ccf((diff(tslogprices[[i+1 +(e-1)*nAssets*nRuns]]))^2, (diff(tslogprices[[i+2 +(e-1)*nAssets*nRuns]]))^2, ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
      }
   }
   title(paste("VA-Multivariate_ABM-1.0.1 - CCF of squared log-returns - Asset 1 vs Asset 2 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: CCF should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ... Asset 1 vs asset 3 (IBM vs GOOG) ... #

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
         ccf((diff(tslogprices[[i+1+1+(e-1)*nAssets*nRuns]]))^2, (diff(tslogprices[[i+1+3+(e-1)*nAssets*nRuns]]))^2, ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
      }
   } else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         ccf((diff(tslogprices[[i+1 +(e-1)*nAssets*nRuns]]))^2, (diff(tslogprices[[i+3 +(e-1)*nAssets*nRuns]]))^2, ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
      }
   }
   title(paste("VA-Multivariate_ABM-1.0.1 - CCF of squared log-returns - Asset 1 vs Asset 3 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: CCF should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}


# ... Asset 2 vs asset 3 (MSFT vs GOOG) ... #

for (e in seq(from=1, to=nExp)) {
   par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
   if (nRuns>numRows*numCols){   
      for (i in seq(from=step, to=step*numRows*numCols, by=step)) {     
         ccf((diff(tslogprices[[i+1+2+(e-1)*nAssets*nRuns]]))^2, (diff(tslogprices[[i+1+3+(e-1)*nAssets*nRuns]]))^2, ylab = "Cross-correlation", main=paste("Run",  1+i/nAssets), ylim=c(-1,1))
      }
   } else {
      for (i in seq(from=1, to=nAssets*nRuns, by=nAssets)) {
         ccf((diff(tslogprices[[i+2 +(e-1)*nAssets*nRuns]]))^2, (diff(tslogprices[[i+3 +(e-1)*nAssets*nRuns]]))^2, ylab = "Cross-correlation", main=paste("Run", 1+(i-1)/nAssets), ylim=c(-1,1))
      }
   }
   title(paste("VA-Multivariate_ABM-1.0.1 - CCF of squared log-returns - Asset 2 vs Asset 3 ( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
   mtext("Test description: CCF should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
   mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
}



# ------ Average CCF of SQUARED log-returns (over runs) ------ #

# Objective: Plot a summary of the CCF along experiments

# ... Asset 1 vs asset 2 (IBM vs MSFT) ... #

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(mean_CCF_squaredreturns_12[,e], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Cross-correlations")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")      
}
title(paste("VA-Multivariate_ABM-1.0.1 - Average CCF of squared log-returns (over runs) - Asset 1 vs Asset 2"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Test description: CCF should remain positive (that is, above the dashed lines) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file

# ... Asset 1 vs asset 3 (IBM vs GOOG) ... #

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(mean_CCF_squaredreturns_13[,e], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Cross-correlations")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")      
}
title(paste("VA-Multivariate_ABM-1.0.1 - Average CCF of squared log-returns (over runs) - Asset 1 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Test description: CCF should remain positive (that is, above the dashed lines) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file

# ... Asset 2 vs asset 3 (MSFT vs GOOG) ... #

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(mean_CCF_squaredreturns_23[,e], type="l", main=paste("Exp", e), ylim=c(-1,1), xlab="Lag", ylab="Cross-correlations")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")      
}
title(paste("VA-Multivariate_ABM-1.0.1 - Average CCF of squared log-returns (over runs) - Asset 2 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)   
mtext("Test description: CCF should remain positive (that is, above the dashed lines) for a number of lags and decay slowly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file



# ------ Variation in CCF of SQUARED log-returns ------ #

# Plot the maximum and minimum CCF for each experiment
# Objective: Study the range of variation of CCF over experiments

# ... Asset 1 vs asset 2 (IBM vs MSFT) ... #

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (k in seq(from=0, to=nExp-1)) {
   #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
   xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
   yy <- c(Min_CCF_squaredreturns_12[,k+1], rev(Max_CCF_squaredreturns_12[,k+1]))
   plot(xx,yy, type="l", main=paste("Exp", k+1), 
   xlab="Lag", ylab=paste("CCF - Asset 1 vs Asset 2"), lwd=1, ylim=c(-1,1))
   polygon(xx, yy, col="gray")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")   
}
title(paste("VA-Multivariate_ABM-1.0.1 - Range of variation of CCF of squared log-returns - Asset 1 vs Asset 2"), outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the max/min values of ACF of squared log-returns. It should decay rapidly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


# ... Asset 1 vs asset 3 (IBM vs GOOG) ... #

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (k in seq(from=0, to=nExp-1)) {
   #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
   xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
   yy <- c(Min_CCF_squaredreturns_13[,k+1], rev(Max_CCF_squaredreturns_13[,k+1]))
   plot(xx,yy, type="l", main=paste("Exp", k+1), 
   xlab="Lag", ylab=paste("CCF - Asset 1 vs Asset 3"), lwd=1, ylim=c(-1,1))
   polygon(xx, yy, col="gray")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")   
}
title(paste("VA-Multivariate_ABM-1.0.1 - Range of variation of CCF of squared log-returns - Asset 1 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the max/min values of ACF of squared log-returns. It should decay rapidly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


# ... Asset 2 vs asset 3 (MSFT vs GOOG) ... #

#par(mfrow=c(nAssets,nExp), mar=c(3,4,3,1), oma=c(3,3,5,3))
par(mgp=c(1.75,0.5,0))   # Margins adjusted so that title and axes labels are properly shown

par(mfrow=c(numRows,numCols), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (k in seq(from=0, to=nExp-1)) {
   #par(mfrow=c(1,1), mar=c(3,4,3,1), oma=c(3,3,5,3))   # 1 plot per page
   xx <- c(1:nlags, nlags:1)   # Needed to shade the area between max and min
   yy <- c(Min_CCF_squaredreturns_23[,k+1], rev(Max_CCF_squaredreturns_23[,k+1]))
   plot(xx,yy, type="l", main=paste("Exp", k+1), 
   xlab="Lag", ylab=paste("CCF - Asset 2 vs Asset 3"), lwd=1, ylim=c(-1,1))
   polygon(xx, yy, col="gray")
   lines(upper_bound, lty=2, col="blue")
   lines(lower_bound, lty=2, col="blue")   
}
title(paste("VA-Multivariate_ABM-1.0.1 - Range of variation of CCF of squared log-returns - Asset 2 vs Asset 3"), outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Overview of the max/min values of ACF of squared log-returns. It should decay rapidly to 0.", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file





# ----------------------------------------------- #


dev.off()  # Close output files


# ----------------------------------------------- #





