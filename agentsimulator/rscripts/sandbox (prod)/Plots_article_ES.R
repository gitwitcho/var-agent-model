
## ------------- PLOTS FOR THE ES ARTICLE ---------------- ##

# Directory where to save the png of plots
setwd("C:/Users/bllac/eclipse-workspace/eclipse_DB/agentsimulator/out/trend-value-es-abm-simulation/")


#############################################################################
#                                                                           #
#                          DESCRIPTION OF ES CYCLE                          #
#                                                                           #
#############################################################################

nAssets = 1
nRuns = 50
nExp = 11


#-------------------------------------------------------
#
# Price without ES + price with ES
#
#-------------------------------------------------------

run = 4
asset = 1
exp = 1

y_min_P = 75
y_max_P = 105

png("price_with_without_ES.png", width = 24, height = 12, units = "cm", res = 300,
	type = if (capabilities("cairo")) "cairo" else "Xlib",
	bg = "white", pointsize = 10)  # Save to png file

op <- par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0), cex.main=1.4, cex.lab=1.2, cex.axis=1.1)

plot(tsprices[[1+asset+(run-1)*nAssets + (nExp-1)*nAssets*nRuns]], type="l", main="Price", cex.main=1.25, ylab="", col="red", ylim=c(y_min_P, y_max_P), xlab="")
lines(tsprices[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", col="black")
legend("bottomleft", c("Without ES","With ES"), lty=c(1,1), lwd=c(3,3), col=c("black", "red"))
par(op)
dev.off()


## Zoom

t_1 = 1900
t_2 = 2400

y_min_P = 75
y_max_P = 100

x_axis <- seq(t_1,t_2,50)

png("price_with_without_ES_zoom.png", width = 24, height = 12, units = "cm", res = 300,
	type = if (capabilities("cairo")) "cairo" else "Xlib",
	bg = "white", pointsize = 10)  # Save to png file

op <- par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))

plot(tsprices[[1+asset+(run-1)*nAssets + (nExp-1)*nAssets*nRuns]][t_1:t_2], type="l", main="Price", cex.main=1.25, ylab="", col="red", ylim=c(y_min_P, y_max_P), xlab="", xaxt='n')
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
lines(tsprices[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2], type="l", col="black")
legend("bottomleft", c("Without ES","With ES"), lty=c(1,1), lwd=c(3,3), col=c("black", "red"))
par(op)
dev.off()



#-------------------------------------------------------
#
# Volatility + Agent's ES + Selloff orders
#
#-------------------------------------------------------

run = 4
asset = 1
exp = 11

volWindow = 20

### Calculate series of return volatility

tsvolatility <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))
tsvolatility_annualised <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))

for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
   for (i in seq(from=1, to=nTicks-volWindow)) {
      tsvolatility[i+volWindow,j] <- sd(diff(tslogprices[(i+1):(i+volWindow),1+j]), na.rm = FALSE)
   }
}

tsvolatility_annualised <- tsvolatility*sqrt(252)  # annualise volatility


### Plot whole run

t_1=1
t_2=4000

y_min_V = 0
y_max_V = 0.25

y_min_es = 0
y_max_es = 75

y_min_SO = -2
y_max_SO = 0.5

tsESL <- array(40, dim=c(nTicks, 1))

png("Volatility_ES_selloff.png", width = 20, height = 18, units = "cm", res = 300,
	type = if (capabilities("cairo")) "cairo" else "Xlib",
	bg = "white", pointsize = 10)  # Save to png file

op <- par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0), cex.main=1.4, cex.lab=1.2, cex.axis=1.2)

# !! The plot shows AVERAGE sell-off orders --> I divide the total order by the number of FUNDs/TRENDs

plot(tsvolatility_annualised[,asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns][t_1:t_2], type="l", main="Annual volatility", cex.main=1.75, xlab="", ylab="", ylim=c(y_min_V, y_max_V), yaxt='n')
axis(2, at=seq(y_min_V,y_max_V,by=.1), labels=paste(100*seq(y_min_V,y_max_V,by=.1), "%") )  # adjust y axis to show percentages

plot(tsFUNDes[[1+run+(exp-1)*nRuns]], type="l", col="darkorange1", main="Average ES", cex.main=1.75, ylab="", xlab="", ylim=c(y_min_es, y_max_es))
lines(tsTRENDes[[1+run+ (exp-1)*nRuns]], type="l", col="seagreen")
lines(tsESL[,1], type="l", col="red", lwd=2)  # Plot a horizontal line for the ES limit
legend("topleft", c("FUND","TREND"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen"), cex=1.2)

plot(tsFUNDessellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2]/200, type="l", col="darkorange1",  main="Fire sales", cex.main=1.75, xlab="", ylab="", ylim=c(y_min_SO, y_max_SO))
lines(tsTRENDessellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2]/200, type="l", col="seagreen")
legend("bottomleft", c("FUND","TREND"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen"), cex=1.2)

par(op)
dev.off()



### Plot a zoom

t_1 = 1900
t_2 = 2400
x_axis <- seq(t_1,t_2,50)

y_min_V = 0
y_max_V = 0.25

y_min_es = 0
y_max_es = 75

y_min_SO = -2
y_max_SO = 0.5

tsESL <- array(40, dim=c(t_2-t_1+1, 1))

png("Volatility_ES_selloff_zoom.png", width = 20, height = 18, units = "cm", res = 300,
	type = if (capabilities("cairo")) "cairo" else "Xlib",
	bg = "white", pointsize = 10)  # Save to png file

op <- par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0), cex.main=1.4, cex.lab=1.2, cex.axis=1.2)

# !! The plot shows AVERAGE sell-off orders --> I divide the total order by the number of FUNDs/TRENDs

plot(tsvolatility_annualised[,asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns][t_1:t_2], type="l", main="Annual volatility", cex.main=1.75, xlab="", ylab="", ylim=c(y_min_V, y_max_V), yaxt='n', , xaxt='n')
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
axis(2, at=seq(y_min_V,y_max_V,by=.1), labels=paste(100*seq(y_min_V,y_max_V,by=.1), "%") )  # adjust y axis to show percentages

plot(tsFUNDes[[1+run+(exp-1)*nRuns]][t_1:t_2], type="l", col="darkorange1", main="Average ES", cex.main=1.75, ylab="", xlab="", ylim=c(y_min_es, y_max_es), xaxt='n')
lines(tsTRENDes[[1+run+ (exp-1)*nRuns]][t_1:t_2], type="l", col="seagreen")
lines(tsESL[,1], type="l", col="red", lwd=2)  # Plot a horizontal line for the ES limit
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
legend("topleft", c("FUND","TREND"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen"), cex=1.2)

plot(tsFUNDessellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2]/200, type="l", col="darkorange1",  main="Fire sales", cex.main=1.75, xlab="", ylab="", ylim=c(y_min_SO, y_max_SO), xaxt='n')
lines(tsTRENDessellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2]/200, type="l", col="seagreen")
legend("bottomleft", c("FUND","TREND"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen"), cex=1.2)
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)

par(op)
dev.off()




#############################################################################
#                                                                           #
#                    BOXPLOTS OF INSTABILITY INDICATORS                     #
#                                                                           #
#############################################################################


#____________________________________________________________________#
#                                                                    #
#                       VOLATILITY OF RETURNS                        #
#____________________________________________________________________#
#                                                                    #

# We plot here the sell-off volume of FUNDs and TRENDs, together
# with the volatility of prices, to see the effect of VaR limits on volatility

nExp = 11
#nExp = 21
#nExp = 16

### Calculate series of return volatility

tslogprices <- base::log(tsprices)
tslogprices[[1]] <- tsprices[[1]]  # The 'tick' column must not change

tsvolatility <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))
mean_tsvolatility_th <- array(0, dim=c(nRuns, nAssets*nExp))

for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
   for (i in seq(from=1, to=nTicks-volWindow)) {
      tsvolatility[i+volWindow,j] <- sd(diff(tslogprices[(i+1):(i+volWindow),1+j]), na.rm = FALSE)
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         mean_tsvolatility_th[j+1,i+k*nAssets] <- mean(tsvolatility[(volWindow+1):nTicks,i+j*nAssets+k*nAssets*nRuns])
      }
   }
}



### Boxplot of mean of time series of return volatility (along experiments)

x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
#x_axis <- c("5", "8", "11", "14", "17", "20", "23", "26", "29", "32", "35", "38", "41", "44", "47", "50")
#x_axis <- c("100%VaR 0%ES", "", "", "", "", "50%VaR 50%ES", "", "", "", "", "0%VaR 100%ES")

y_min_V = 0.0
y_max_V = 2.2

mean_mean_tsvolatility_th <- array(0, dim=c(nAssets, nExp))

for (k in seq(from=1, to=nAssets)) {   # Calculate means to add them to the boxplots
   for (e in seq(from=0, to=nExp-1)) {
	mean_mean_tsvolatility_th[k, e+1] = mean(mean_tsvolatility_th[,k+e*nAssets])
   }
}

mean_tsvolatility_th_annualised <- mean_tsvolatility_th*sqrt(252)  # annualise volatility
mean_mean_tsvolatility_th_annualised <- mean_mean_tsvolatility_th*sqrt(252)

png("volatility_probEs0_1.png", width = 25, height = 10, units = "cm", res = 300,
#png("volatility_esLimit_5_65.png", width = 20, height = 10, units = "cm", res = 300,
#png("volatility_volWindow_5_50.png", width = 20, height = 10, units = "cm", res = 300,
	type = if (capabilities("cairo")) "cairo" else "Xlib",
	bg = "white", pointsize = 10)  # Save to png file

op <- par(mfrow=c(nAssets,1), mar=c(3,1.5,3,1), oma=c(1,1,0.25,1), mgp=c(1.75,0.5,0), cex.main=1.4, cex.lab=1.2, cex.axis=1.1)

for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(mean_tsvolatility_th_annualised[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="Return volatility", xlab="Percentage of agents using stressed ES", xaxt='n', yaxt='n')
   #boxplot(mean_tsvolatility_th_annualised[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="Return volatility", xlab="ES limit", xaxt='n', yaxt='n')
   #boxplot(mean_tsvolatility_th_annualised[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="Return volatility", xlab="Volatility window", xaxt='n', yaxt='n')
   points(mean_mean_tsvolatility_th_annualised[i,],col="red",pch=18)
   lines(mean_mean_tsvolatility_th_annualised[i,], col="red", lwd=2)
   #lines(mean_mean_tsvolatility_th_annualised_var[i,], col="blue", lwd=2)
   axis(1, at=1:nExp, labels=x_axis)
   axis(2, at=seq(y_min_V,y_max_V,by=.1), labels=paste(100*seq(y_min_V,y_max_V,by=.1), "%") )  # adjust y axis to show percentages
   #legend("topleft", c("Mean with VaR","Mean with ES"), lty=c(1,1), lwd=c(3,3), col=c("blue", "red"), cex=1.2)
}

par(op)
dev.off()


#____________________________________________________________________#
#                                                                    #
#                         KURTOSIS OF RETURNS                        #
#____________________________________________________________________#
#                                                                    #

### Calculate series of return kurtosis

tskurtosis <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))
mean_tskurtosis_th <- array(0, dim=c(nRuns, nAssets*nExp))

for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
   for (i in seq(from=1, to=nTicks-volWindow)) {
      tskurtosis[i+volWindow,j] <- kurtosis(diff(tslogprices[i:(i+volWindow-1),1+j]), na.rm = FALSE, method="excess")[1]
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         mean_tskurtosis_th[j+1,i+k*nAssets] <- mean(tskurtosis[(volWindow+1):nTicks,i+j*nAssets+k*nAssets*nRuns])
      }
   }
}

### Boxplot of mean of time series of return kurtosis (along experiments) [Thesis Ch4]

x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
#x_axis <- c("5", "8", "11", "14", "17", "20", "23", "26", "29", "32", "35", "38", "41", "44", "47", "50")
#x_axis <- c("100%VaR 0%ES", "", "", "", "", "50%VaR 50%ES", "", "", "", "", "0%VaR 100%ES")

mean_mean_tskurtosis_th <- array(0, dim=c(nAssets, nExp))

for (k in seq(from=1, to=nAssets)) {   # Calculate means to add them to the boxplots
   for (e in seq(from=0, to=nExp-1)) {
	mean_mean_tskurtosis_th[k, e+1] = mean(mean_tskurtosis_th[,k+e*nAssets])
   }
}

png("kurtosis_probEs0_1.png", width = 25, height = 10, units = "cm", res = 300,
#png("kurtosis_esLimit_5_65.png", width = 20, height = 10, units = "cm", res = 300,
#png("kurtosis_volWindow_5_50.png", width = 20, height = 10, units = "cm", res = 300,
	type = if (capabilities("cairo")) "cairo" else "Xlib",
	bg = "white", pointsize = 10)  # Save to png file

op <- par(mfrow=c(nAssets,1), mar=c(3,1.5,3,1), oma=c(1,1,0.25,1), mgp=c(1.75,0.5,0), cex.main=1.4, cex.lab=1.2, cex.axis=1.1)

for (i in seq(from=1, to=nAssets)) {
   #dev.new()         # Plots each figure in a new window
   boxplot(mean_tskurtosis_th[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="Return kurtosis", xlab="Percentage of agents using stressed ES", xaxt='n')
   #boxplot(mean_tskurtosis_th[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="Return kurtosis", xlab="ES limit", xaxt='n')
   #boxplot(mean_tskurtosis_th[,seq(i,nAssets*nExp,nAssets)], notch=FALSE, range=1.5, main="Return kurtosis", xlab="Volatility window", xaxt='n')
   points(mean_mean_tskurtosis_th[i,],col="red",pch=18)
   lines(mean_mean_tskurtosis_th[i,], col="red", lwd=2)
   axis(1, at=1:nExp, labels=x_axis)
}

par(op)
dev.off()


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

# Calculate Hill index of returns for each run

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

### Boxplot of Hill index along experiments (considering the individual runs)  [Thesis Ch4]

par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0))
x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
#x_axis <- c("5", "8", "11", "14", "17", "20", "23", "26", "29", "32", "35", "38", "41", "44", "47", "50")
#x_axis <- c("100%VaR 0%ES", "", "", "", "", "50%VaR 50%ES", "", "", "", "", "0%VaR 100%ES")

png("hill_probEs0_1.png", width = 25, height = 10, units = "cm", res = 300,
#png("hill_esLimit_5_65.png", width = 20, height = 10, units = "cm", res = 300,
#png("hill_volWindow_5_50.png", width = 20, height = 10, units = "cm", res = 300,
	type = if (capabilities("cairo")) "cairo" else "Xlib",
	bg = "white", pointsize = 10)  # Save to png file

op <- par(mfrow=c(nAssets,1), mar=c(3,1.5,3,1), oma=c(1,1,0.25,1), mgp=c(1.75,0.5,0), cex.main=1.4, cex.lab=1.2, cex.axis=1.1)

for (i in seq(from=1, to=nAssets)) {
   hillreturns_exp <- array(0, dim=c(nRuns, nExp))    # It allocates the Hill indexes corresponding to the same experiment and asset
   mean_hillreturns_exp <- array(0, dim=c(1, nExp))   # Mean Hill index over runs

   for (e in seq(from=1, to=nExp)) {      
      for (j in seq(from=1, to=nRuns)) {
         hillreturns_exp[j,e] <- hillreturns[,i+(j-1)*nAssets+(e-1)*nAssets*nRuns]
      }
      mean_hillreturns_exp[,e] <- mean(hillreturns_exp[,e])
   }
   boxplot(hillreturns_exp[,], notch=FALSE, main="Hill index", range=1.5, xlab="Percentage of agents using stressed ES", xaxt='n')
   #boxplot(hillreturns_exp[,], notch=FALSE, main="Hill index", range=1.5, xlab="ES limit", xaxt='n')
   #boxplot(hillreturns_exp[,], notch=FALSE, main="Hill index", range=1.5, xlab="Volatility window", xaxt='n')
   points(mean_hillreturns_exp[,],col="red",pch=18)
   lines(mean_hillreturns_exp[,], col="red", lwd=2)
   axis(1, at=1:nExp, labels=x_axis)
}
par(op)
dev.off()



#______________________________________________________________#
#                                                              #
#              SHARPE RATIO OF FINAL WEALTH                    #
#______________________________________________________________#
#                                                              # 

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
}

i=1
y_max = max(max(Sharpe_FUND[,i]), max(Sharpe_TREND[,i]))
y_min = min(min(Sharpe_FUND[,i]), min(Sharpe_TREND[,i]))
x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
#x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
#x_axis <- c("5", "8", "11", "14", "17", "20", "23", "26", "29", "32", "35", "38", "41", "44", "47", "50")
#x_axis <- c("100%VaR 0%ES", "", "", "", "", "50%VaR 50%ES", "", "", "", "", "0%VaR 100%ES")

png("sharpe_probEs0_1.png", width = 25, height = 10, units = "cm", res = 300,
#png("sharpe_esLimit_5_65.png", width = 20, height = 10, units = "cm", res = 300,
#png("sharpe_volWindow_5_50.png", width = 20, height = 10, units = "cm", res = 300,
	type = if (capabilities("cairo")) "cairo" else "Xlib",
	bg = "white", pointsize = 10)  # Save to png file

op <- par(mfrow=c(nAssets,1), mar=c(3,1.5,3,1), oma=c(1,1,0.25,1), mgp=c(1.75,0.5,0), cex.main=1.4, cex.lab=1.2, cex.axis=1.1)

#dev.new()
plot(Sharpe_FUND[,i], type="l", main="Strength index", xlab="Percentage of agents using stressed ES", ylab="", ylim=c(y_min,y_max), lwd=2, col="darkorange1", xaxt='n')
#plot(Sharpe_FUND[,i], type="l", main="Strength index", xlab="ES limit", ylab="", ylim=c(y_min,y_max), lwd=2, col="darkorange1", xaxt='n')
#plot(Sharpe_FUND[,i], type="l", main="Strength index", xlab="Volatility window", ylab="", ylim=c(y_min,y_max), lwd=2, col="darkorange1", xaxt='n')
lines(Sharpe_TREND[,i], type="l", col="seagreen", lwd=2)
axis(1, at=1:nExp, labels=x_axis)
legend("topleft", c("FUND","TREND"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen"), cex=1.2)

par(op)
dev.off()



#############################################################################
#                                                                           #
#         BOXPLOT OF VAR/ES CYCLES (Number of cycles and duration)          #
#                                                                           #
#############################################################################

## Run this after detect_cycles_*_all(...), i.e. after you have:
##   var_results <- detect_cycles_var_all(...)
##   es_results  <- detect_cycles_es_all(...)

## ---------- Helpers ---------------------------------------------------- ##

collect_cycle_durations <- function(det_all) {
  out <- list(); k <- 1L
  for (e in seq_len(nExp)) for (r in seq_len(nRuns)) for (a in seq_len(nAssets)) {
    det <- det_all$per_era_cycles[[e]][[r]][[a]]
    if (!is.null(det) && nrow(det) > 0) {
      out[[k]] <- data.frame(experiment = e, run = r, asset = a, duration = det$duration)
      k <- k + 1L
    }
  }
  if (length(out) == 0)
    return(data.frame(experiment=integer(0), run=integer(0), asset=integer(0), duration=numeric(0)))
  do.call(rbind, out)
}

ylim_from_values <- function(x, fallback = c(0, 1)) {
  x <- x[is.finite(x)]
  if (length(x) == 0) return(fallback)
  rng <- range(x)
  if (diff(rng) == 0) rng <- rng + c(-0.5, 0.5)
  rng
}

## Results into tidy bits
var_counts    <- var_results$summary[, c("experiment","run","asset","n_cycles")]
es_counts     <- es_results$summary[,  c("experiment","run","asset","n_cycles")]
var_durations <- collect_cycle_durations(var_results)
es_durations  <- collect_cycle_durations(es_results)

## X-axis labels (edit to yours if you already have one called x_axis)
if (!exists("x_axis")) {
  x_axis <- paste0(seq_len(nExp) - 1L, "0%")  # e.g. 0%, 10%, … if you have 11 experiments
  if (length(x_axis) != nExp) x_axis <- paste0("E", seq_len(nExp))
}

## ---------- Plotters (safe with missing/empty experiments) ------------- ##
plot_counts_box <- function(df, main_title, ylab="Count") {
  df$experiment <- factor(df$experiment, levels = seq_len(nExp))
  ylims <- ylim_from_values(df$n_cycles, fallback = c(0, 1))
  boxplot(n_cycles ~ experiment, data=df, notch=FALSE, range=1.5,
          xaxt="n", main=main_title, xlab="Percentage of agents using VaR and ES", ylab=ylab, ylim=ylims)
  axis(1, at=seq_len(nExp), labels=x_axis)
  means <- tapply(df$n_cycles, df$experiment, mean, na.rm=TRUE)
  points(seq_len(nExp), means, col="red", pch=18)
  lines(seq_len(nExp), means, col="red", lwd=2)
}

plot_durations_box <- function(df, main_title, ylab="Duration (ticks)") {
  # Which experiments actually have cycles?
  exps <- sort(unique(df$experiment))
  if (length(exps) == 0) {
    plot.new(); title(main_title)
    mtext("No cycles detected", side=3, line=0.5, col="red")
    axis(1, at=seq_len(nExp), labels=x_axis); box()
    return(invisible())
  }
  df$experiment <- factor(df$experiment, levels = exps)
  ylims <- ylim_from_values(df$duration, fallback = c(0, 1))
  boxplot(duration ~ experiment, data=df, notch=FALSE, range=1.5,
          xaxt="n", main=main_title, xlab="Experiment", ylab=ylab, ylim=ylims)
  axis(1, at=seq_along(exps), labels=x_axis[exps])
  means <- tapply(df$duration, df$experiment, mean, na.rm=TRUE)
  points(seq_along(exps), means, col="red", pch=18)
  lines(seq_along(exps),  means, col="red", lwd=2)
}

make_grouped_boxes <- function(df_left, df_right, value_col, main_title, ylab) {
  # Union of experiments that have data in either side
  exps <- sort(unique(c(df_left$experiment, df_right$experiment)))
  if (length(exps) == 0) {
    plot.new(); title(main_title)
    mtext("No cycles detected (VaR & ES empty)", side=3, line=0.5, col="red")
    axis(1, at=seq_len(nExp), labels=x_axis); box()
    return(invisible())
  }
  # split into per-experiment vectors (may be length 0 for one side)
  L <- lapply(exps, function(e) df_left [df_left$experiment  == e, value_col])
  R <- lapply(exps, function(e) df_right[df_right$experiment == e, value_col])

  # y-limits from all finite values
  all_vals <- c(unlist(L, use.names = FALSE), unlist(R, use.names = FALSE))
  ylims <- ylim_from_values(all_vals, fallback = c(0, 1))

  # x positions for paired boxes
  centers  <- seq_along(exps) * 2
  at_left  <- centers - 0.6
  at_right <- centers + 0.6

  # draw
  boxplot(L, at = at_left,  xaxt = "n", yaxt = "t", boxwex = 0.9,
          col = "white", border = "black", range = 1.5,
          main = main_title, ylab = ylab, xlab = "Experiment", ylim = ylims)
  boxplot(R, at = at_right, xaxt = "n", yaxt = "n", boxwex = 0.9,
          add = TRUE, col = "grey85", border = "black", range = 1.5)

  axis(1, at = centers, labels = x_axis[exps])
  # mean lines (skip experiments that have no values on a side)
  mean_left  <- sapply(L, function(x) if (length(x)) mean(x, na.rm=TRUE) else NA_real_)
  mean_right <- sapply(R, function(x) if (length(x)) mean(x, na.rm=TRUE) else NA_real_)

  if (any(is.finite(mean_left))) {
    points(at_left,  mean_left,  col="red",  pch=18)
    lines(at_left,   mean_left,  col="red",  lwd=2)
  }
  if (any(is.finite(mean_right))) {
    points(at_right, mean_right, col="blue", pch=18)
    lines(at_right,  mean_right, col="blue", lwd=2)
  }

  legend("topleft", inset = 0.01,
         legend = c("VaR", "ES"),
         fill   = c("white","grey85"),
         border = "black", bty = "n")
}


## ===================== Plots for the article ========================= ##

##  ---- Number of cycles ---- ##

# Adjustment to avoid that there are no cycles in the first boxplot (prop_ES = 0)
es_counts_aux <- es_counts
es_counts_aux[1:50,4] <- var_counts[1:50,4]

png("number_cycles.png", width = 24, height = 12, units = "cm", res = 300,
	type = if (capabilities("cairo")) "cairo" else "Xlib",
	bg = "white", pointsize = 10)  # Save to png file

op <- par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0), cex.main=1.4, cex.lab=1.2, cex.axis=1.05)

x_axis <- c("100%VaR 0%ES", "", "", "", "", "50%VaR 50%ES", "", "", "", "", "0%VaR 100%ES")
plot_counts_box(es_counts_aux, main_title = "Number of instability cycles per run")
axis(1, at=1:nExp, labels=x_axis)
par(op)
dev.off()


##  ---- Average duration of cycles ---- ##

# Adjustment to avoid that there are no cycles in the first scenario (prop_ES = 0)

es_durations_aux <- bind_rows(
  var_durations %>% filter(experiment == 1),
  es_durations  %>% filter(experiment > 1)
)

mean_durations <- es_durations_aux %>%
  group_by(experiment) %>%
  summarise(mean_duration = mean(duration, na.rm = TRUE), .groups = "drop") %>%
  arrange(experiment) %>%
  pull(mean_duration)

png("duration_cycles.png", width = 24, height = 12, units = "cm", res = 300,
	type = if (capabilities("cairo")) "cairo" else "Xlib",
	bg = "white", pointsize = 10)  # Save to png file

op <- par(mfrow=c(nAssets,1), mar=c(3,4,3,1), oma=c(1,1,2,1), mgp=c(1.75,0.5,0), cex.main=1.4, cex.lab=1.2, cex.axis=1.05)

x_axis <- c("100%VaR 0%ES", "", "", "", "", "50%VaR 50%ES", "", "", "", "", "0%VaR 100%ES")
y_min_dur = 20
y_max_dur = 50

stopifnot(length(mean_durations) == length(x_axis))  # sanity check

plot(as.numeric(mean_durations),
     type = "o", pch = 16, lwd = 2, col="red", ylim=c(y_min_dur, y_max_dur), 
     xaxt = "n", xlab ="Percentage of agents using VaR and ES", ylab = "Ticks",
     main = "Mean duration of instability cycles")
axis(1, at = seq_along(mean_durations), labels = x_axis)
par(op)
dev.off()


### ============================= 1) VaR only ============================== ##
#
#par(mfrow = c(2,1), mar = c(3,4,3,1), oma = c(1,1,2,1), mgp = c(2,0.6,0))
#plot_counts_box   (var_counts,    main_title = "VaR: Number of cycles per run")
#plot_durations_box(var_durations, main_title = "VaR: Cycle durations")
#mtext("VaR results", outer = TRUE, cex = 1.2, font = 2)
#
### ============================= 2) ES only =============================== ##
#
#par(mfrow = c(2,1), mar = c(3,4,3,1), oma = c(1,1,2,1), mgp = c(2,0.6,0))
#plot_counts_box   (es_counts,     main_title = "ES: Number of cycles per run")
#plot_durations_box(es_durations,  main_title = "ES: Cycle durations")
#mtext("ES results", outer = TRUE, cex = 1.2, font = 2)
#
### ========================== 3) VaR vs ES together ======================= ##
#
#par(mfrow = c(2,1), mar = c(3,4,3,1), oma = c(1,1,2,1), mgp = c(2,0.6,0))
#make_grouped_boxes(var_counts,    es_counts,    value_col = "n_cycles",
#                   main_title = "Number of cycles: VaR (white) vs ES (grey)",
#                   ylab = "Count")
#make_grouped_boxes(var_durations, es_durations, value_col = "duration",
#                   main_title = "Cycle durations: VaR (white) vs ES (grey)",
#                   ylab = "Duration (ticks)")
#mtext("VaR vs ES", outer = TRUE, cex = 1.2, font = 2)
