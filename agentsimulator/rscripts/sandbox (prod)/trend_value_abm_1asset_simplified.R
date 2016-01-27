
# http://code.google.com/p/systemic-risk/
# 
# Copyright (c) 2011, CIMNE and Gilbert Peffer.
# All rights reserved
#
# This software is open-source under the BSD license; see 
# http://code.google.com/p/systemic-risk/wiki/SoftwareLicense


# ииииииииииииииииииииииииииииииииииииииииииииииииииииииииииииииииииии
# This script does only a few plots (in particular, ACF graphics of the
# log-returns and volatility) to temptatively explore if the Java program
# 'TrendValueSingleAssetAbmSimulation' reproduces the principal stylised facts
# (non-normality, fat tails, lack of return autocorrelation, clustered volatility)
#
# иииииииииииииииииииииииииииииииииииииииииииииииииииииииииииииииииииии


rm(list = ls())      # clear objects
graphics.off()       # close graphics windows
library(fUtilities)  # calculation of kurtosis, skewness
library(fractal)     # calculation of Hurst exponent, DFA


###################################################################
#                                                                 #
#               'PARAMETERS' & INITIAL INFORMATION                #
#                                                                 #
###################################################################

# Setting the path to the data folder

# Set the root directory (add your path)
root.dir <- "C:/Users/llacay/eclipse"

# Build the home directory (shouldn't be necessary to change)
home.dir <- paste(root.dir, "/agentsimulator/out/trend-value-abm-simulation/", sep="")



# Read data from csv files

tsprices <- 
  read.table(paste(home.dir,"list_price_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsvalues <- 
  read.table(paste(home.dir,"list_fundvalues_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsvolume <- 
  read.table(paste(home.dir,"list_totalvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDvolume <- 
  read.table(paste(home.dir,"list_fundvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDvolume <- 
  read.table(paste(home.dir,"list_trendvolume_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDorders <- 
  read.table(paste(home.dir,"list_fundorders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDorders <- 
  read.table(paste(home.dir,"list_trendorders_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)



# Parameters needed from the java files

nAssets = 1     # TODO Extract nAssets automatically from the CVS headers
nExp = 1       # TODO Extract nExp automatically from the CVS headers
nRuns <- (dim(tsprices)[2] - 1)/(nAssets*nExp)
nTicks <- dim(tsprices)[1]

param_file = "trend_value_abm_001"  # Parameter file

# Plots are distributed in a matrix. Choose here the dimensions of the matrix

numRows <- 1  # Dimensions of matrix of plots
numCols <- 1
step <- as.integer((nRuns-1)/(numRows*numCols))*nAssets  # Selects which plots to draw if there are too many



###################################################################
#                                                                 #
#                     AUXILIARY CALCULATIONS                      #
#                                                                 #
###################################################################

# Calculate logarithmic prices (for returns) and values

tslogprices <- log(tsprices)
tslogprices[[1]] <- tsprices[[1]]  # The 'tick' column must not change

tslogvalues <- log(tsvalues)
tslogvalues[[1]] <- tsvalues[[1]]  # The 'tick' column must not change



###################################################################
#                                                                 #
#         VALIDATION TESTS (Stylised facts for each asset)        #
#               - for each individual asset and run -             #
#                                                                 #
###################################################################


# Open file to write the results in a pdf (to later send it to G)
#pdf(paste(home.dir, "Trend_Value_ABM_VV120514_outR.pdf", sep=""))  # Plot diagrams in a pdf file


# Plots for a single asset (over different runs) are shown in a matrix
# If there are more runs than positions in the matrix, 
# only a a selection of the plots is shown


# ---- Plot decimal prices vs values --- #

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
            plot(tsprices[[i+k +(e-1)*nAssets*nRuns]], type="l", ylab="Decimal price and value", main=paste("Run", 1+(i-1)/nAssets), ylim=c(y_min, y_max))
            lines(tsvalues[[i+k +(e-1)*nAssets*nRuns]], type="l", col="red")  
         }
      }
      title(paste("Decimal price and value - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}

dev.new()



# ----- TEST VA-FJ-1.1: VOLATILITY CLUSTERING ----- #

# ACF of log-returns

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
      title(paste("ACF of log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: ACF should decay quickly to zero (that is, it should lie between the dashed lines)", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}

dev.new()


# VA-FJ-1.1.1 - ACF of absolute log-returns

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
      title(paste("VA-FJ-1.1.1 - ACF of absolute log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: ACF should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}

dev.new()


# VA-FJ-1.1.2 - ACF of squared log-returns

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
      title(paste("VA-FJ-1.1.2 - ACF of squared log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: ACF should remain positive (that is, above the dashed line) for a number of lags and decay slowly to 0", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}

dev.new()


# ----- TEST VA-FJ-1.3: FAT TAILS OF LOG-RETURNS ----- #

# VA-FJ-1.3.1 - QQ plot of log-returns

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
      title(paste("VA-FJ-1.3.1 - Q-Q plot of log-returns - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: The distribution of log-returns should deviate from the diagonal (which corresponds to a normal distribution) in the tails", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file
   }
}

dev.new()


# VA-FJ-1.3.2 - Histogram of log-return distribution

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
      title(paste("VA-FJ-1.3.2 - Histogram of log-returns vs Normal - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: The probability in the tails of the histogram should be higher for the log-return distribution than for the normal one", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file 
   }
}

dev.new()


# ----- TEST VA-FJ-1.4: VOLUME SKEWNESS ----- #

# VA-FJ-1.4.1 - Histogram of volume distribution

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
      title(paste("VA-FJ-1.4.1 - Histogram of volume distribution - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
      mtext("Test description: The distribution of volume should be asymmetrical, with the bulk of values lying at the left of the mean", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
      mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file 
   }
}


# ----------------------------------------------- #


# Histogram of FUND vs TREND volume to compare the distribution of orders

dev.new()

value_max = max(max(tsFUNDvolume[,2]), max(tsTRENDvolume[,2]))
value_min = min(min(tsFUNDvolume[,2]), min(tsTRENDvolume[,2]))
numBins = 100;

for (e in seq(from=1, to=nExp)) {
   breakseq <- seq(value_min, value_max, by=(value_max-value_min)/numBins)
}

par(mfrow=c(1,2), mar=c(3,4,3,1), oma=c(3,3,5,3))
hist(tsFUNDvolume[[2]], main=paste("Run 1 - FUND"), xlab="FUND volume", breaks=breakseq)
hist(tsTRENDvolume[[2]], main=paste("Run 1 - TREND"), xlab="TREND volume", breaks=breakseq)

title(paste("Histogram of FUND vs TREND volume distribution - Asset", k, "( Exp", e, ")"), outer = TRUE, col.main="blue", font.main=2)
mtext("Test description: Compare the volume distribution of FUNDs and TRENDs to see which group sends more orders to the market", side=3, line=0.5, col="blue", cex=0.6, outer=TRUE)  # Add explanation of the test
mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file 


# ----------------------------------------------- #


# Plot volume vs volatility

#dev.new()
#
#par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
#plot(tsFUNDvolume[[2]], type="l", ylab="FUND volume")
#plot(tsTRENDvolume[[2]], type="l", ylab="TREND volume")
#plot(diff(tslogprices[[2]])^2, type="l", ylab="return^2")
#
#title("FUND/TREND volume vs return^2 (volatility)", outer = TRUE, col.main="blue", font.main=2)
#mtext(paste("Parameters:", param_file), side=1, line=3, cex=0.75)  # Add parameter file


# ----------------------------------------------- #


# Hurst exponent

# Scaling exponent of the time series of returns (DFA method)

#dev.new()
#
#DFA.return <- DFA(diff(tslogprices[[2]]), detrend="poly1", sum.order=1)
#print(DFA.return)      # print the results 
#eda.plot(DFA.return, cex = 0.5)   # plot a summary of the results

# Scaling exponent of the time series of absolute returns (DFA method)

#dev.new()
#
#DFA.volatility <- DFA(abs(diff(tslogprices[[2]])), detrend="poly1", sum.order=1)
#print(DFA.volatility)      # print the results 
#eda.plot(DFA.volatility, cex = 0.5)   # plot a summary of the results 


# Hurst exponents

HurstExp_returns <- hurstSpec(diff(tslogprices[[2]]))
print(HurstExp_returns)

HurstExp_volatility <- hurstSpec(abs(diff(tslogprices[[2]])))
print(HurstExp_volatility)


#hurstBlock(diff(tslogprices[[2]]), method="aggAbs")
#hurstBlock(diff(tslogprices[[2]]), method="aggVar")
#hurstBlock(diff(tslogprices[[2]]), method="diffvar")
#hurstBlock(diff(tslogprices[[2]]), method="higuchi") 

#hurstBlock((diff(tslogprices[[2]]))^2, method="aggAbs")
#hurstBlock((diff(tslogprices[[2]]))^2, method="aggVar")
#hurstBlock((diff(tslogprices[[2]]))^2, method="diffvar")
#hurstBlock((diff(tslogprices[[2]]))^2, method="higuchi") 

#library(pracma)
#hurstexp(diff(tslogprices[[2]]), d = 50, display = TRUE)   #This method does not work


# ----------------------------------------------- #


#hill(diff(tslogprices[[2]]), option = "quantile", end = 500, p = 0.999)


# ------------------------------------------------ #

# Complementary Cumulative Distribution Function (CCDF) of log-returns

#dev.new()
#
#X <- abs(diff(tslogprices[[2]]))
#p <- ppoints(100)
#par(mfrow=c(1,3))
#plot(quantile(X,p=p), p, type="l", ylab="P(X < x)", xlab="x", main="CDF")
#plot(quantile(X,p=p), 1-p, type="l", ylab="P(X > x)", xlab="x", main="CCDF")
#plot(log(quantile(X,p=p)), log(1-p), ylab="log[P(X > x)]", xlab="log(x)", main="CCDF: log-log")

##plot(sort(X) , 1-ecdf(X)(sort(X)), log="xy")  # Alternative way to plot the CCDF


# Regression

#df  <- data.frame(x=log(1-p),y=log(quantile(X,p=p)))
#fit <- lm(y~x,df)
#summary(fit)


# ----------------------------------------------- #

head(HurstExp_returns)     # Delete
head(HurstExp_volatility)  # Delete


#dev.off()  # Close output files


# ----------------------------------------------- #
