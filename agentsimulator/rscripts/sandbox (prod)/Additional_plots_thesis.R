
REFER FIG 2 ARTICLE

graphics.off()
run = 2
t_1 = 1000
t_2 = 1200


## Zoom on entry conditions + exit conditions + TREND positions

dev.new()
library(TTR)      # calculation of MA's
library(caTools)  # calculation of max/min over a window

par(mfrow=c(3,1), mar=c(4, 7, 2, 2), oma=c(3,3,5,3))
plot(tsprices[t_1:t_2,run], main="Prices + MA10 + MA40", type="l", col="black")
lines(SMA(tsprices[[run]], n=10)[t_1:t_2], type="l", col="red")
lines(SMA(tsprices[[run]], n=40)[t_1:t_2], type="l", col="blue")
plot(tsprices[t_1:t_2,run], main="Prices + Min + Max", type="l", col="black")
lines(runmin(tsprices[t_1:t_2,run],17, align="right"), col="red")
lines(runmax(tsprices[t_1:t_2,run],17, align="right"), col="blue")
plot(cumsum(tsTRENDorders[,run])[t_1:t_2], main="TREND positions + entry + exit", type="l", col="black")


------------------------------------------


#_______________________________________________________________#
#                                                               #
#          SECTION 2.6 - Results of FUND+TREND model            #
#_______________________________________________________________#
#                                                               #

nAssets = 2
nRuns = 25
nExp = 1

#-------------------------------------------------------
#
# Descripción dinámica modelo
#
#-------------------------------------------------------

### Plot of annualised return volatility for thesis

asset = 1
exp = 1
y_min = 0.08
y_max = 0.095

mw = 250  # Length of moving window
tsvolatility <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))
tsvolatility_avg <- array(0, dim=c(nTicks, nAssets*nExp))

for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
   for (i in seq(from=1, to=nTicks-mw)) {
      tsvolatility[i+mw,j] <- sd(diff(tslogprices[(i+1):(i+mw-1),1+j]), na.rm = FALSE)
   }
}

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         tsvolatility_avg[,i+k*nAssets] <- tsvolatility_avg[,i+k*nAssets] + tsvolatility[,i+j*nAssets+k*nAssets*nRuns]
      }
      tsvolatility_avg[,i+k*nAssets] <- tsvolatility_avg[,i+k*nAssets]/nRuns
   }
}

tsvolatility_avg_annualised <- tsvolatility_avg*sqrt(252)  # annualise volatility

plot(tsvolatility_avg_annualised[(mw+1):nTicks, asset+(exp-1)*nAssets], type="l", ylim=c(y_min,y_max), xlab="Tick", ylab="", xaxt="n", yaxt="n")
axis(2, at=seq(y_min,y_max,by=.0025), labels=paste(100*seq(y_min,y_max,by=.0025), "%") )  # adjust y axis to show percentages
axis(1, at=seq(0,nTicks-mw,by=250), labels=seq(mw,nTicks,by=250))

#-------------------------------------------------------------------------


### Plot of FUND and TREND positions (== accumulated orders) (averaged over runs)

y_max = max(max(cumsum(tsFUNDorders_avg[,1:(nAssets*nExp)])), max(cumsum(tsTRENDorders_avg[,1:(nAssets*nExp)])))
y_min = min(min(cumsum(tsFUNDorders_avg[,1:(nAssets*nExp)])), min(cumsum(tsTRENDorders_avg[,1:(nAssets*nExp)])))

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      plot(cumsum(tsFUNDorders_avg[,(e-1)*nAssets+k]), type="l", main="Fundamentalistas", cex.main=1.5, ylim=c(y_min,y_max), xlab="", ylab="", col="darkorange1")
      plot(cumsum(tsTRENDorders_avg[,(e-1)*nAssets+k]), type="l", main="Técnicos", cex.main=1.5, ylim=c(y_min,y_max), xlab="", ylab="", col="seagreen")
   }
}


### Zoom on price + FUND/TREND positions (== accumulated orders) (averaged over runs)

y_max = max(max(cumsum(tsFUNDorders_avg[,1:(nAssets*nExp)])), max(cumsum(tsTRENDorders_avg[,1:(nAssets*nExp)])))
y_min = min(min(cumsum(tsFUNDorders_avg[,1:(nAssets*nExp)])), min(cumsum(tsTRENDorders_avg[,1:(nAssets*nExp)])))

x_min = 2000
x_max = 2250

for (k in seq(from=1, to=nAssets)) {
   par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
   for (e in seq(from=1, to=nExp)) {      
      plot(tsprices_avg[,(e-1)*nAssets+k][x_min:x_max], type="l", main="Precio", cex.main=1.5, xlab="", ylab="", col="black", lwd=2, xaxt="n")
      axis(1, at=seq(0,x_max-x_min,by=50), labels=seq(x_min,x_max,by=50))
      plot(cumsum(tsFUNDorders_avg[,(e-1)*nAssets+k])[x_min:x_max], type="l", main="Posiciones fundamentalistas", cex.main=1.5, xlab="", ylab="", col="darkorange1", lwd=2, xaxt="n")
      axis(1, at=seq(0,x_max-x_min,by=50), labels=seq(x_min,x_max,by=50))
      plot(cumsum(tsTRENDorders_avg[,(e-1)*nAssets+k])[x_min:x_max], type="l", main="Posiciones técnicas", cex.main=1.5, xlab="", ylab="", col="seagreen", lwd=2, xaxt="n")
      axis(1, at=seq(0,x_max-x_min,by=50), labels=seq(x_min,x_max,by=50))
   }   
}



#_______________________________________________________________#
#                                                               #
#              SECTION 3.3 - Results of LS model                #
#_______________________________________________________________#
#                                                               #

nAssets = 2
nRuns = 25
nExp = 1

#-------------------------------------------------------
#
# Descripción dinámica modelo
#
#-------------------------------------------------------


### Plot of FUND, TREND and LS total positions (averaged over runs)

y_min = -500
y_max = 500
asset = 1
exp = 1

par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(3,3,5,3))
for (e in seq(from=1, to=nExp)) {      
   plot(cumsum(tsFUNDorders_avg[,(exp-1)*nAssets+asset]), type="l", main="Fundamentalistas", cex.main=1.75, ylim=c(y_min,y_max), ylab="", col="darkorange1")
   plot(cumsum(tsTRENDorders_avg[,(exp-1)*nAssets+asset]), type="l", main="Técnicos", cex.main=1.75, ylim=c(y_min,y_max), xlab="", ylab="", col="seagreen")       
   plot(cumsum(tsLSorders_avg[,(exp-1)*nAssets+asset]), type="l", main="Long-short", cex.main=1.75, ylim=c(y_min,y_max), ylab="", col="royalblue3")
}

#-------------------------------------------------------------------------

### Plot of Price + FUND, TREND and LS total positions (averaged over runs)

asset = 1
exp = 1

t_1 = 3250
t_2 = 3500
x_axis <- seq(t_1,t_2,50)


par(mfrow=c(4,1), mar=c(3,4,3,1), oma=c(1,1,1,1))
plot(tsprices_avg[,(exp-1)*nAssets+asset][t_1:t_2], type="l", main="Precio", cex.main=1.75, ylim=c(100,102.5), ylab="", col="black", xaxt='n', lwd=2)
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
plot(cumsum(tsFUNDorders_avg[,(exp-1)*nAssets+asset])[t_1:t_2], type="l", main="Fundamentalistas", cex.main=1.75, ylim=c(-200,200), ylab="", col="darkorange1", xaxt='n', lwd=2)
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
plot(cumsum(tsTRENDorders_avg[,(exp-1)*nAssets+asset])[t_1:t_2], type="l", main="Técnicos", cex.main=1.75, ylim=c(-400,300), xlab="", ylab="", col="seagreen", xaxt='n', lwd=2)
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
plot(cumsum(tsLSorders_avg[,(exp-1)*nAssets+asset])[t_1:t_2], type="l", main="Long-short", cex.main=1.75, ylim=c(-200,100), ylab="", col="royalblue3", xaxt='n', lwd=2)
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)


#-------------------------------------------------------------------------

### Plot of Price + Spread + LS total positions (averaged over runs)

exp = 1
asset = 1
run = 17
t_1 = 2000
t_2 = 2750
x_axis <- seq(t_1,t_2,50)

tszero <- array(0, dim=c(nTicks, 1))
meanWindow = 225

# Calculate spread A1-A2

tsspread_12 <- array(0, dim=c(nTicks, nExp*nRuns))
tsspread_12_avg <- array(0, dim=c(nTicks, nExp))
tsspread_12_histmean <- array(0, dim=c(nTicks, nExp*nRuns))
tsspread_12_histmean_avg <- array(0, dim=c(nTicks, nExp))


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

# Plot avg time series

par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(1,1,1,1))
plot(tsprices_avg[,(exp-1)*nAssets+1][t_1:t_2], type="l", main="Precios", cex.main=1.75, ylim=c(100,105), ylab="", col="black", xaxt='n')
lines(tsprices_avg[,(exp-1)*nAssets+2][t_1:t_2], type="l", main="", col="blue", xaxt='n')
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
plot(tsspread_12_avg[,exp][t_1:t_2], type="l", main="Spread", cex.main=1.75, ylim=c(-2,0), ylab="", col="black", xaxt='n')
lines(tsspread_12_histmean_avg[,exp][t_1:t_2], type="l", col="red")
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
plot(cumsum(tsLSorders_avg[,(exp-1)*nAssets+asset])[t_1:t_2], type="l", main="Long-short", cex.main=1.75, ylim=c(-200,100), ylab="", col="royalblue3", xaxt='n')
lines(tszero[,][t_1:t_2], type="l", col="gray")
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)

# Plot time series for an individual run

par(mfrow=c(3,1), mar=c(3,4,3,1), oma=c(1,1,1,1))
plot(tsprices[[1+1+(exp-1)*nAssets*nRuns+(run-1)*nAssets]][t_1:t_2], type="l", main="Precios", cex.main=1.75, ylim = c(100,125), ylab="", col="black", xaxt='n')
lines(tsprices[[1+2+(exp-1)*nAssets*nRuns+(run-1)*nAssets]][t_1:t_2], type="l", col="blue")
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
plot(tsspread_12[,run+(exp-1)*nRuns][t_1:t_2], type="l", main="Spread", cex.main=1.75, ylab="", col="black", xaxt='n')
lines(tsspread_12_histmean[,run+(exp-1)*nRuns][t_1:t_2], type="l", col="red")
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
plot(cumsum(tsLSorders[[1+1+(exp-1)*nAssets*nRuns+(run-1)*nAssets]])[t_1:t_2], type="l", main="Posiciones agregadas long-short", cex.main=1.75, ylab="", col="black", xaxt='n')
lines(cumsum(tsLSorders[[1+2+(exp-1)*nAssets*nRuns+(run-1)*nAssets]])[t_1:t_2], type="l", col="blue", xaxt='n')
lines(tszero[,][t_1:t_2], type="l", col="gray")
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)


#-------------------------------------------------------------------------

## Correlation between assets + LS orders

run = 11
asset = 2
exp = 1
t_1 = 2000
t_2 = 3000
x_axis <- seq(t_1,t_2,50)


#### Calculate series of correlations
#
#tscorr_12 <- array(0, dim=c(nTicks, nExp*nRuns))
#tscorr_13 <- array(0, dim=c(nTicks, nExp*nRuns))
#tscorr_23 <- array(0, dim=c(nTicks, nExp*nRuns))
#
#for (e in seq(from=1, to=nExp)) {
#   for (k in seq(from=1, to=nRuns)) {
#      for (i in seq(from=1, to=nTicks-volWindow)) {
#	   tscorr_12[i+volWindow,(e-1)*nRuns+k] <- cor( diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+1]), diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+2]) )
#	   tscorr_13[i+volWindow,(e-1)*nRuns+k] <- cor( diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+1]), diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+3]) )
#	   tscorr_23[i+volWindow,(e-1)*nRuns+k] <- cor( diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+2]), diff(tslogprices[i:(i+volWindow-1),1+(e-1)*nAssets*nRuns+(k-1)*nAssets+3]) )
#      }
#   }
#}


dev.new()
par(mfrow=c(2,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))

plot(tscorr_13[,run +(exp-1)*nRuns][t_1:t_2], type="l", ylim=c(-1,1), ylab="Correlación", xaxt='n')
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
plot(tsLSorders[[1+asset + (run-1)*nAssets +(exp-1)*nAssets*nRuns]][t_1:t_2], type="l", col="blue", ylab="Órdenes LS", xaxt='n')
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)


#-------------------------------------------------------------------------

## Matrix of correlations between asset returns

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

run = 11
asset = 2
exp = 1

#aux <- array(0, dim=c(nTicks-1, 3))
aux <- array(0, dim=c(nTicks-1, 2))
aux[,1] <- diff(tslogprices[[1+1 + (run-1)*nAssets +(exp-1)*nAssets*nRuns]])
aux[,2] <- diff(tslogprices[[1+2 + (run-1)*nAssets +(exp-1)*nAssets*nRuns]])
#aux[,3] <- diff(tslogprices[[1+3 + (run-1)*nAssets +(exp-1)*nAssets*nRuns]])

#pairs(aux, labels = c("Asset 1", "Asset 2", "Asset 3"), oma=c(5,5,7,5), lower.panel=panel.smooth, upper.panel=panel.cor)
pairs(aux, labels = c("Asset 1", "Asset 2"), oma=c(5,5,7,5), lower.panel=panel.smooth, upper.panel=panel.cor)


#-------------------------------------------------------------------------

## Cross-correlation of returns at lag 0 - Averaged over runs

# Calculate cross-correlations

nlags = 67
asset_CCF_matrix <- array(0, dim=c(nlags, nRuns))  # Auxiliary array to store the CCF's for one asset (over all runs)

mean_CCF_returns_12 <- array(0, dim=c(nlags, nExp))
Max_CCF_returns_12 <- array(0, dim=c(nlags, nExp))
Min_CCF_returns_12 <- array(0, dim=c(nlags, nExp))

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

upper_bound = rep(-1/nTicks+2/sqrt(nTicks), nrow(mean_CCF_returns_12))
lower_bound = rep(-1/nTicks-2/sqrt(nTicks), nrow(mean_CCF_returns_12))

x_1 = 0
x_2 = 200
x_axis <- seq(x_1,x_2,20)

plot(mean_CCF_returns_12[34,], type="l", main="", ylim=c(-1,1), xlab="Número de inversores long-short", ylab="Correlación", lwd=2, xaxt='n')
lines(upper_bound, lty=2, col="blue")
lines(lower_bound, lty=2, col="blue")
axis(1, at=1:nExp, labels=x_axis)


#-------------------------------------------------------------------------

## Distance between assets (--> spread) / between spreads and their mean

run = 11
exp = 1
t_1 = 1
t_2 = 4000
x_axis <- seq(t_1,t_2,50)


# Calculate series of spreads and their mean

spread_12 <- array(0, dim=c(nTicks, nRuns))
#spread_13 <- array(0, dim=c(nTicks, nRuns))
spread_12_mean <- array(0, dim=c(nTicks, nRuns))
#spread_13_mean <- array(0, dim=c(nTicks, nRuns))

for (i in seq(from=1, to=nRuns)) {
   spread_12[,i] <- tsprices[[1+2 + (i-1)*nAssets +(exp-1)*nAssets*nRuns]] - tsprices[[1+1 + (i-1)*nAssets +(exp-1)*nAssets*nRuns]]
   #spread_13[,i] <- tsprices[[1+3 + (i-1)*nAssets +(exp-1)*nAssets*nRuns]] - tsprices[[1+1 + (i-1)*nAssets +(exp-1)*nAssets*nRuns]]
}

LSwindow = 200
for (j in seq(from=1, to=nExp*nRuns)) {
   for (i in seq(from=1, to=nTicks-LSwindow)) {
      spread_12_mean[i+LSwindow,j] <- mean(spread_12[i:(i+LSwindow-1),j])
      #spread_13_mean[i+LSwindow,j] <- mean(spread_13[i:(i+LSwindow-1),j])
   }
}


# Plot spreads vs mean spread

par(mfrow=c(2,1), mar=c(3,4,3,1), oma=c(3,3,3,3))

plot(spread_12[,run][t_1:t_2], type="l", ylab="Spread A1-A2")
lines(spread_12_mean[,run][t_1:t_2], type="l", col="red")
dist = sqrt(sum((spread_12[,run]-spread_12_mean[,run])^2))/nTicks
norm = sqrt(sum((spread_12[,run])^2))/nTicks
mtext(paste("dist = ", round(dist,3), " / norm = ", round(norm, 3)), side=3, line=0.1, cex=0.6, col="red")

#plot(spread_13[,run][t_1:t_2], type="l", ylab="Spread A1-A3")
#lines(spread_13_mean[,run][t_1:t_2], type="l", col="red")
#dist = sqrt(sum((spread_13[,run]-spread_13_mean[,run])^2))/nTicks
#norm = sqrt(sum((spread_13[,run])^2))/nTicks
#mtext(paste("dist = ", round(dist,3), " / norm = ", round(norm, 3)), side=3, line=0.1, cex=0.6, col="red")




#_______________________________________________________________#
#                                                               #
#              SECTION 4.5 - Results of VaR model               #
#_______________________________________________________________#
#                                                               #

nAssets = 2
nRuns = 25
nExp = 12


#-------------------------------------------------------
#
# Descripción ciclo VaR
#
#-------------------------------------------------------


## Price without VaR + price with VaR

run = 9
asset = 1
exp = 1
t_1 = 2900
t_2 = 3200
volWindow = 20
x_axis <- seq(t_1,t_2,50)

y_min_P = 90
y_max_P = 110

dev.new()
par(mfrow=c(2,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))
plot(tsprices[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2], type="l", main="Precio sin VaR", cex.main=1.25, ylab="", ylim=c(y_min_P, y_max_P), xlab="", xaxt='n')
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
plot(tsprices[[1+asset+(run-1)*nAssets + (nExp-1)*nAssets*nRuns]][t_1:t_2], type="l", main="Precio con VaR", cex.main=1.25, ylab="", ylim=c(y_min_P, y_max_P), xlab="", xaxt='n')
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)

#-------------------------------------------------------------------------

## Price + agents' VaR

run = 9
asset = 1
exp = 11
t_1 = 1
t_2 = 4000
volWindow = 20

y_min_P = 85
y_max_P = 130

y_min_var = 0
y_max_var = 150

tsVarL <- array(40, dim=c(nTicks, 1))

dev.new()
par(mfrow=c(2,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))

plot(tsprices[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", main="Precio con VaR", cex.main=1.25, ylab="", xlab="", ylim=c(y_min_P, y_max_P))
plot(tsFUNDvar[[1+run+(exp-1)*nRuns]], type="l", col="darkorange1", main="VaR promedio", cex.main=1.25, ylab="", xlab="", ylim=c(y_min_var, y_max_var))
lines(tsTRENDvar[[1+run+ (exp-1)*nRuns]], type="l", col="seagreen")
lines(tsLSvar[[1+run+(exp-1)*nRuns]], type="l", col="royalblue3")
lines(tsVarL[,1], type="l", col="red", lwd=2)  # Plot a horizontal line for the VaR limit
legend("topleft", c("Fundamentalistas","Técnicos", "Long-short"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen", "royalblue3"))


#-------------------------------------------------------------------------


## Price + return volatility + sell-off orders

run = 9
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


dev.new()
par(mfrow=c(3,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))

# !! The plot shows AVERAGE sell-off orders --> I divide the total order by the number of FUNDs/TRENDs/LS

# Plot whole run

t_1=1
t_2=4000

y_min_P = 85
y_max_P = 130

y_min_V = 0
y_max_V = 0.35

y_min_SO = -6
y_max_SO = 2

par(mfrow=c(3,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))

plot(tsprices[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2], type="l", main="Precio", cex.main=1.75, xlab="", ylab="", ylim=c(y_min_P, y_max_P))
plot(tsvolatility_annualised[,asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns][t_1:t_2], type="l", main="Volatilidad anual", cex.main=1.75, xlab="", ylab="", ylim=c(y_min_V, y_max_V), yaxt='n')
axis(2, at=seq(y_min_V,y_max_V,by=.1), labels=paste(100*seq(y_min_V,y_max_V,by=.1), "%") )  # adjust y axis to show percentages
plot(tsFUNDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2]/200, type="l", col="darkorange1",  main="Reducciones de posiciones", cex.main=1.75, xlab="", ylab="", ylim=c(y_min_SO, y_max_SO))
lines(tsTRENDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2]/200, type="l", col="seagreen")
lines(tsLSsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2]/200, type="l", col="royalblue3")


# Plot a zoom

t_1 = 2900
t_2 = 3200
x_axis <- seq(t_1,t_2,50)

y_min_P = 85
y_max_P = 110

y_min_V = 0
y_max_V = 0.35

y_min_SO = -6
y_max_SO = 2

par(mfrow=c(3,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))

plot(tsprices[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2], type="l", main="Precio", cex.main=1.75, xlab="", ylab="", ylim=c(y_min_P, y_max_P), xaxt='n')
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
plot(tsvolatility_annualised[,asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns][t_1:t_2], type="l", main="Volatilidad anual", cex.main=1.75, xlab="", ylab="", ylim=c(y_min_V, y_max_V), xaxt='n', yaxt='n')
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)
axis(2, at=seq(y_min_V,y_max_V,by=.1), labels=paste(100*seq(y_min_V,y_max_V,by=.1), "%") )  # adjust y axis to show percentages
plot(tsFUNDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2]/200, type="l", col="darkorange1", main="Reducciones de posiciones", cex.main=1.75, xlab="", ylab="", ylim=c(y_min_SO, y_max_SO), xaxt='n')
lines(tsTRENDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2]/200, type="l", col="seagreen")
lines(tsLSsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2]/200, type="l", col="royalblue3")
axis(1, at=seq(1,(t_2-t_1+1),50), labels=x_axis)



#-------------------------------------------------------
#
# Efecto en la estabilidad del mercado
#
#-------------------------------------------------------


## Price + sell-off orders + price volatility

run = 9
asset = 1
exp = 1
t_1 = 1
t_2 = 4000
volWindow = 20

#### Calculate series of price volatility
#
#tsvolatility <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))
#
#for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
#   for (i in seq(from=1, to=nTicks-volWindow)) {
#      tsvolatility[i+volWindow,j] <- sd(tsprices[(i+1):(i+volWindow),1+j], na.rm = FALSE)
#   }
#}


y_min_P = 60
y_max_P = 130

y_max_SO = 6000
y_min_SO = -3000

y_min_V = 0
y_max_V = 4.5

x_axis <- seq(1,nTicks,1)

dev.new()
par(mfrow=c(2,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))

# Plot price
plot(x=x_axis, y=tsprices[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2], type="l", main="Precio + Reducción de posiciones", cex.main=1.25, 
          ylim=c(y_min_P,y_max_P), xlab="", ylab="", col="black", xaxt='n', yaxt='n')
axis(2, pretty(c(y_min_P, y_max_P)), col="black")

# Plot sell-off volume in the same axes
par(new=T)  # Plot second time series
plot(x=x_axis, y=tsFUNDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
lines(tsTRENDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", col="seagreen")
lines(tsLSsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", col="royalblue3")
axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

# Add x axis
axis(1, pretty(range(x_axis)))

# Plot price volatility
plot(tsvolatility[,asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns][t_1:t_2], type="l",  main="Volatilidad precio", cex.main=1.25, ylab="", xlab="", ylim=c(y_min_V, y_max_V))


#-------------------------------------------------------------------------


## Price + sell-off orders + return volatility

run = 9
asset = 1
exp = 1
t_1 = 1
t_2 = 4000
volWindow = 20

#### Calculate series of return volatility
#
#tsvolatility <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))
#
#for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
#   for (i in seq(from=1, to=nTicks-volWindow)) {
#      tsvolatility[i+volWindow,j] <- sd(diff(tslogprices[(i+1):(i+volWindow),1+j]), na.rm = FALSE)
#   }
#}

tsvolatility_annualised <- tsvolatility*sqrt(252)  # annualise volatility


y_min_P = 60
y_max_P = 130

y_max_SO = 6000
y_min_SO = -3000

y_min_V = 0
y_max_V = 0.7

x_axis <- seq(1,nTicks,1)

dev.new()
par(mfrow=c(2,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))

# Plot price
plot(x=x_axis, y=tsprices[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2], type="l", main="Precio + Reducción de posiciones", cex.main=1.25, 
          ylim=c(y_min_P,y_max_P), xlab="", ylab="", col="black", xaxt='n', yaxt='n')
axis(2, pretty(c(y_min_P, y_max_P)), col="black")

# Plot sell-off volume in the same axes
par(new=T)  # Plot second time series
plot(x=x_axis, y=tsFUNDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
lines(tsTRENDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", col="seagreen")
lines(tsLSsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", col="royalblue3")
axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

# Add x axis
axis(1, pretty(range(x_axis)))

# Plot return volatility
plot(tsvolatility_annualised[,asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns][t_1:t_2], type="l",  main="Volatilidad rentabilidades", cex.main=1.25, ylab="", xlab="", ylim=c(y_min_V, y_max_V), yaxt="n")
axis(2, at=seq(y_min_V,y_max_V,by=.05), labels=paste(100*seq(y_min_V,y_max_V,by=.05), "%") )  # adjust y axis to show percentages


#-------------------------------------------------------------------------


## Price + sell-off orders + return kurtosis

run = 9
asset = 1
exp = 1
t_1 = 1
t_2 = 4000
volWindow = 20

#### Calculate series of return kurtosis
#
#tskurtosis <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))
#
#for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
#   for (i in seq(from=1, to=nTicks-volWindow)) {
#      tskurtosis[i+volWindow,j] <- kurtosis(diff(tslogprices[i:(i+volWindow-1),1+j]), na.rm = FALSE)
#   }
#}

y_min_P = 60
y_max_P = 130

y_max_SO = 6000
y_min_SO = -3000

y_min_kurt = -2
y_max_kurt = 9

x_axis <- seq(1,nTicks,1)

dev.new()
par(mfrow=c(2,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))

# Plot price
plot(x=x_axis, y=tsprices[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2], type="l", main="Precio + Reducción de posiciones", cex.main=1.25, 
          ylim=c(y_min_P,y_max_P), xlab="", ylab="", col="black", xaxt='n', yaxt='n')
axis(2, pretty(c(y_min_P, y_max_P)), col="black")

# Plot sell-off volume in the same axes
par(new=T)  # Plot second time series
plot(x=x_axis, y=tsFUNDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
lines(tsTRENDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", col="seagreen")
lines(tsLSsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", col="royalblue3")
axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

# Add x axis
axis(1, pretty(range(x_axis)))

# Plot return kurtosis
plot(tskurtosis[,asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns][t_1:t_2], type="l",  main="Curtosis rentabilidades", cex.main=1.25, ylab="", xlab="", ylim=c(y_min_kurt, y_max_kurt))


#-------------------------------------------------------------------------


## Price + price volatility with different windows

run = 9
asset = 1
exp = 1
t_1 = 3500
t_2 = 4000
volWindow = 20
x_axis <- seq(t_1,t_2,200)


#### Calculate series of price volatility with different windows

tsvolatility_5 <- array(0, dim=c(nTicks, 1))
tsvolatility_50 <- array(0, dim=c(nTicks, 1))
tsvolatility_250 <- array(0, dim=c(nTicks, 1))

j = asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns

for (i in seq(from=1, to=nTicks-5)) {
   tsvolatility_5[i+5] <- sd(tsprices[(i+1):(i+5),1+j], na.rm = FALSE)
}

for (i in seq(from=1, to=nTicks-50)) {
   tsvolatility_50[i+50] <- sd(tsprices[(i+1):(i+50),1+j], na.rm = FALSE)
}

for (i in seq(from=1, to=nTicks-250)) {
   tsvolatility_250[i+250] <- sd(tsprices[(i+1):(i+250),1+j], na.rm = FALSE)
}


y_min_P = 87
y_max_P = 103

y_min_V = 0
y_max_V = 7

dev.new()
par(mfrow=c(2,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))

plot(tsprices[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2], type="l", ylab="", xlab="", main="Precio", cex.main=1.25, ylim=c(y_min_P, y_max_P), xaxt='n')
axis(1, at=seq(1,(t_2-t_1+1),200), labels=x_axis)
plot(tsvolatility_5[t_1:t_2], type="l", ylab="", xlab="", main="Volatilidad precio", cex.main=1.25, ylim=c(y_min_V, y_max_V), col="indianred", xaxt='n')
lines(tsvolatility_50[t_1:t_2], type="l", col="blue")
lines(tsvolatility_250[t_1:t_2], type="l", col="darkgreen")
axis(1, at=seq(1,(t_2-t_1+1),200), labels=x_axis)
legend("topleft", c("w=5","w=50", "w=250"), lty=c(1,1), lwd=c(3,3), col=c("indianred", "blue", "darkgreen"))


#-------------------------------------------------------------------------

## VaR & Stressed VaR + positions

run = 9
exp = 1
asset = 1

y_min_var = 0
y_max_var = 1000

y_max_pos = 6000
y_min_pos = -2000

x_axis <- seq(1,nTicks,1)

# Plot VaR + Stressed VaR

grid.newpage()
pushViewport(viewport(layout=grid.layout(2,1)))
vplayout <- function(x,y) viewport(layout.pos.row=x,layout.pos.col=y)

df = data.frame(seq(1:nTicks), tsFUNDstressedvar[,1+run+(exp-1)*nRuns], tsFUNDvar[,1+run+(exp-1)*nRuns])
     colnames(df) <- c("tick", "SVar", "Var")

df <- reshape(df, varying = c("SVar", "Var"), v.names = "value", timevar = "group", 
      times = c("SVar", "Var"), direction = "long")

df$group <- factor(df$group, levels = c("Var", "SVar"))   # Change the order of stacks (VaR below, SVar on top)
            
# Plot VaR & SVar in stacked area plot
graph = ggplot(df, aes(x=tick, y=value, fill=group)) + geom_area(position = 'stack') +
 	labs(x = "", y = "VaR + VaR estresado", title = "VaR + VaR estresado") + 
      scale_fill_manual(values=c("darkorange1", "coral4"), name = "", 
    	breaks = c("SVar", "Var"), labels = c("SVaR", "VaR")) + ylim(y_min_var, y_max_var) + theme_bw()

# Plot positions in 2 assets

df_2 = data.frame(seq(1:nTicks), cumsum(tsFUNDorders[,1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]))
     colnames(df_2) <- c("tick", "Posiciones")

df_2 <- reshape(df_2, varying = c("Posiciones"), v.names = "value", timevar = "group", 
      times = c("Posiciones"), direction = "long")

#Plot positions in line plot
graph_2= ggplot(df_2, aes(x=tick, y=value, group=1)) + geom_line(colour="darkorange1") +
 	labs(x = "", y = "Posiciones", title = "Posiciones") +
      ylim(y_min_pos, y_max_pos) + theme_bw()

print(graph,vp=vplayout(1,1))
print(graph_2,vp=vplayout(2,1))


#-------------------------------------------------------------------------

## Compare the size of positions for different VaR limits

run = 9
asset = 1
t_1 = 1
t_2 = 4000

y_max = 7000
y_min = -3500

dev.new()
par(mfrow=c(3,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))

# Plot positions in exp=1
plot(cumsum(tsFUNDorders[,1+asset+(run-1)*nAssets + (1-1)*nAssets*nRuns]), type="l", main="LVaR = 5", cex.main=1.25, ylab="", xlab="", ylim=c(y_min, y_max), col="darkorange1")
lines(cumsum(tsTRENDorders[,1+asset+(run-1)*nAssets + (1-1)*nAssets*nRuns]), type="l", col="seagreen")
lines(cumsum(tsLSorders[,1+asset+(run-1)*nAssets+ (1-1)*nAssets*nRuns]), type="l", col="royalblue3")
legend("topright", c("Fundamentalistas","Técnicos", "Long-short"), lty=c(1,1), lwd=c(3,3), col=c("darkorange1", "seagreen", "royalblue3"))

# Plot positions in exp=6
plot(cumsum(tsFUNDorders[,1+asset+(run-1)*nAssets + (6-1)*nAssets*nRuns]), type="l", main="LVaR = 30", cex.main=1.25,ylab="", xlab="", ylim=c(y_min, y_max), col="darkorange1")
lines(cumsum(tsTRENDorders[,1+asset+(run-1)*nAssets + (6-1)*nAssets*nRuns]), type="l", col="seagreen")
lines(cumsum(tsLSorders[,1+asset+(run-1)*nAssets + (6-1)*nAssets*nRuns]), type="l", col="royalblue3")

# Plot positions in exp=16
plot(cumsum(tsFUNDorders[,1+asset+(run-1)*nAssets + (16-1)*nAssets*nRuns]), type="l", main="LVaR = 80", cex.main=1.25,ylab="", xlab="", ylim=c(y_min, y_max), col="darkorange1")
lines(cumsum(tsTRENDorders[,1+asset+(run-1)*nAssets + (16-1)*nAssets*nRuns]), type="l", col="seagreen")
lines(cumsum(tsLSorders[,1+asset+(run-1)*nAssets + (16-1)*nAssets*nRuns]), type="l", col="royalblue3")


#-------------------------------------------------------------------------


## Price + sell-off orders + variable VaR limit + price volatility

run = 9
asset = 1
exp = 1
t_1 = 1
t_2 = 4000
volWindow = 20

### Calculate series of price volatility

tsvolatility <- array(0, dim=c(nTicks, nAssets*nExp*nRuns))

for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
   for (i in seq(from=1, to=nTicks-volWindow)) {
      tsvolatility[i+volWindow,j] <- sd(tsprices[(i+1):(i+volWindow),1+j], na.rm = FALSE)
   }
}

### Read time series of VaR limits

tsFUNDvarlimit <- read.table(paste(home.dir,"list_fundvarlimit_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDvarlimit <- read.table(paste(home.dir,"list_trendvarlimit_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsLSvarlimit <- read.table(paste(home.dir,"list_lsvarlimit_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)

if (nExp > 1) {   # Read data for single experiments and merge them
   for (e in seq(from=1, to=nExp-1)) {
      tsFUNDvarlimit_exp <- read.table(paste(home.dir, paste("list_fundvarlimit_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDvarlimit <- merge(tsFUNDvarlimit, tsFUNDvarlimit_exp, by="tick")

      tsTRENDvarlimit_exp <- read.table(paste(home.dir, paste("list_trendvarlimit_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDvarlimit <- merge(tsTRENDvarlimit, tsTRENDvarlimit_exp, by="tick")

      tsLSvarlimit_exp <- read.table(paste(home.dir, paste("list_lsvarlimit_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsLSvarlimit <- merge(tsLSvarlimit, tsLSvarlimit_exp, by="tick")
   }
}


### Draw the plot

y_min_P = 60
y_max_P = 130

y_max_SO = 6000
y_min_SO = -3000

y_min_V = -5
y_max_V = 4.5

y_min_var = 10
y_max_var = 130


x_axis <- seq(1,nTicks,1)

dev.new()
par(mfrow=c(2,1), mar=c(4, 7, 2, 2), oma=c(1,1,2,1))

# Plot price
plot(x=x_axis, y=tsprices[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]][t_1:t_2], type="l", main="Precio + Reducción de posiciones", cex.main=1.25, 
          ylim=c(y_min_P,y_max_P), xlab="", ylab="", col="black", xaxt='n', yaxt='n')
axis(2, pretty(c(y_min_P, y_max_P)), col="black")

# Plot sell-off volume in the same axes
par(new=T)  # Plot second time series
plot(x=x_axis, y=tsFUNDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", main="", ylim=c(y_min_SO,y_max_SO), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
lines(tsTRENDsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", col="seagreen")
lines(tsLSsellofforders[[1+asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns]], type="l", col="royalblue3")
axis(4, pretty(c(y_min_SO, y_max_SO)), col="darkorange1")

# Add x axis
axis(1, pretty(range(x_axis)))

# Plot price volatility
plot(x=x_axis, y=tsvolatility[,asset+(run-1)*nAssets + (exp-1)*nAssets*nRuns][t_1:t_2], type="l",  main="Volatilidad precio + Límite VaR", cex.main=1.25, ylab="", xlab="", ylim=c(y_min_V, y_max_V), xaxt='n', yaxt='n')
axis(2, pretty(c(y_min_V, y_max_V)), col="black")


# Plot var limits in the same axes
par(new=T)  # Plot second time series
plot(x=x_axis, y=tsFUNDvarlimit[[1+run+(exp-1)*nRuns]], type="l", main="", ylim=c(y_min_var,y_max_var), xlab="", 
		ylab="", col="darkorange1", xaxt='n', axes=F)
axis(4, pretty(c(y_min_var, y_max_var)), col="darkorange1")

# Add x axis
axis(1, pretty(range(x_axis)))




#-------------------------------------------------------
#
# Efecto en la eficiencia del mercado
#
#-------------------------------------------------------


### Plot of prices vs values (averaged over runs)

asset = 1
exp = 1

y_max = 106
y_min = 97
   
plot(tsprices_avg[,(exp-1)*nAssets+asset], type="l", main="", ylim=c(y_min,y_max), xlab="", ylab="")
lines(tsvalues_avg[,(exp-1)*nAssets+asset], type="l", col="red")

#-------------------------------------------------------------------------

### Plot average distance (L1) of each asset price to values (for each experiment)

dist_prices_values <- array(0, dim=c(nExp, nAssets))   # Array to store the mean distance between price and fundamental value over all runs (for each asset and experiment)
distance_vector <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the distance d(P,V) for one asset (over all runs)
#x_axis <- c("5", "", "", "20", "", "", "35", "", "", "50", "", "", "65", "", "", "80", "", "", "95", "")
x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with distance d(P,V) of asset i for each run
         #distance_vector[,j+1] = sqrt(sum((tsprices[[i+1+j*nAssets+k*nAssets*nRuns]] - tsvalues[[i+1+j*nAssets+k*nAssets*nRuns]])^2))/nTicks
         distance_vector[,j+1] = (sum(abs(tsprices[[i+1+j*nAssets+k*nAssets*nRuns]] - tsvalues[[i+1+j*nAssets+k*nAssets*nRuns]])))/nTicks
      }
      dist_prices_values[k+1,i] = mean(distance_vector)
   }
}

matplot(dist_prices_values[,1], type="l", lty=1, col = 1:10, xlab="Porcentaje de agentes con VaR estresado", ylab="", main="", lwd=2, xaxt='n')
axis(1, at=1:nExp, labels=x_axis)


### Compare the plot average distance (L1) of an asset price to values, when agents use 
### countercyclical limits or stressed VaR

asset = 1
dist_prices_values <- array(0, dim=c(nExp, 2))   # Array to store the mean distance between price and fundamental value over all runs (for countercyclical limits or stressed VaR)
distance_vector_counter <- array(0, dim=c(1, nRuns))  # Auxiliary vector to store the distance d(P,V) for one asset (over all runs)
distance_vector_stress <- array(0, dim=c(1, nRuns))

x_axis <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")

for (k in seq(from=0, to=nExp-1)) {
   for (j in seq(from=0, to=nRuns-1)){     # Calculate vector with distance d(P,V) of asset i for each run
      #distance_vector[,j+1] = sqrt(sum((tsprices[[i+1+j*nAssets+k*nAssets*nRuns]] - tsvalues[[i+1+j*nAssets+k*nAssets*nRuns]])^2))/nTicks
      distance_vector_counter[,j+1] = (sum(abs(tsprices_counter[[asset+1+j*nAssets+k*nAssets*nRuns]] - tsvalues_counter[[asset+1+j*nAssets+k*nAssets*nRuns]])))/nTicks
      distance_vector_stress[,j+1] = (sum(abs(tsprices_stress[[asset+1+j*nAssets+k*nAssets*nRuns]] - tsvalues_stress[[asset+1+j*nAssets+k*nAssets*nRuns]])))/nTicks
   }
   dist_prices_values[k+1,1] = mean(distance_vector_counter)
   dist_prices_values[k+1,2] = mean(distance_vector_stress)
}

matplot(dist_prices_values, type="l", lty=1, xlab="", ylab="", main="", col=c("orchid4", "chartreuse4"), lwd=2, xaxt='n')
axis(1, at=1:nExp, labels=x_axis)




#-------------------------------------------------------
#
# Resumen con boxplots comparativos
#
#-------------------------------------------------------

volatility_p_counter_stress <- array(0, dim=c(nRuns, 2*nAssets*nExp))   # Auxiliary arrays to store instability indicators for each run
volatility_ret_counter_stress <- array(0, dim=c(nRuns, 2*nAssets*nExp))
kurtosis_counter_stress <- array(0, dim=c(nRuns, 2*nAssets*nExp))
hill_counter_stress <- array(0, dim=c(nRuns, 2*nAssets*nExp))
var_counter_stress <- array(0, dim=c(nRuns, 2*nAssets*nExp))


# Instabiliy indicators for countercyclical limits and stressed VaR for each run are allocated in a single matrix to plot the parallel boxplots
for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      volatility_p_counter_stress[,1+2*(i-1)+2*k*nAssets] = mean_tsvolatility_p_counter[,i+k*nAssets]    # Odd columns allocate results with countercyclical limits
      volatility_p_counter_stress[,2+2*(i-1)+2*k*nAssets] = mean_tsvolatility_p_stress[,i+k*nAssets]     # Even columns allocate results from stressed VaR

      volatility_ret_counter_stress[,1+2*(i-1)+2*k*nAssets] = mean_tsvolatility_ret_counter[,i+k*nAssets]    # Odd columns allocate results with countercyclical limits
      volatility_ret_counter_stress[,2+2*(i-1)+2*k*nAssets] = mean_tsvolatility_ret_stress[,i+k*nAssets]     # Even columns allocate results from stressed VaR

      kurtosis_counter_stress[,1+2*(i-1)+2*k*nAssets] = mean_tskurtosis_counter[,i+k*nAssets]    # Odd columns allocate results with countercyclical limits
      kurtosis_counter_stress[,2+2*(i-1)+2*k*nAssets] = mean_tskurtosis_stress[,i+k*nAssets]     # Even columns allocate results from stressed VaR

      for (j in seq(from=1, to=nRuns)) {
         hill_counter_stress[j,1+2*(i-1)+2*k*nAssets] <- hillreturns_counter[,i+(j-1)*nAssets+k*nAssets*nRuns]
         hill_counter_stress[j,2+2*(i-1)+2*k*nAssets] <- hillreturns_stress[,i+(j-1)*nAssets+k*nAssets*nRuns]
      }

      var_counter_stress[,1+2*(i-1)+2*k*nAssets] = (mean_tsFUNDvar_counter[,k+1] + mean_tsTRENDvar_counter[,k+1] + mean_tsLSvar_counter[,k+1])/3    # Odd columns allocate results with countercyclical limits
      var_counter_stress[,2+2*(i-1)+2*k*nAssets] = (mean_tsFUNDvar_stress[,k+1] + mean_tsTRENDvar_stress[,k+1] + mean_tsLSvar_stress[,k+1])/3    # Even columns allocate results from stressed VaR
   }
}

volatility_p_counter_stress[,2] <- volatility_p_counter_stress[,1]  # Trick to avoid any difference in the first experiment
volatility_p_counter_stress[,4] <- volatility_p_counter_stress[,3] 
volatility_ret_counter_stress[,2] <- volatility_ret_counter_stress[,1]
volatility_ret_counter_stress[,4] <- volatility_ret_counter_stress[,3]
kurtosis_counter_stress[,2] <- kurtosis_counter_stress[,1]
kurtosis_counter_stress[,4] <- kurtosis_counter_stress[,3]
hill_counter_stress[,2] <- hill_counter_stress[,1]
hill_counter_stress[,4] <- hill_counter_stress[,3]
var_counter_stress[,2] <- var_counter_stress[,1]

volatility_ret_counter_stress <- volatility_ret_counter_stress*sqrt(252)  # annualise volatility

indices <- c(1,2)
x_axis <- c("0%", "", "10%", "", "20%", "", "30%", "", "40%", "", "50%", "", "60%", "", "70%", "", "80%", "", "90%", "", "100%", "")

position_labels <- c(1,2)

for (e in seq(from=1, to=nExp-1)) {
   indices <- append(indices, 1+e*2*nAssets)    # Sequence of indices of columns to be plot for asset 1
   indices <- append(indices, 2+e*2*nAssets)

   position_labels <- append(position_labels, 1+e*3)   # Position of boxplots (leave space between different experiments)
   position_labels <- append(position_labels, 2+e*3)
}

#dev.new()         # Plots each figure in a new window
asset = 1

# Volatility of prices
boxplot(volatility_p_counter_stress[,(2*(asset-1)+indices)], notch=FALSE, col=c("orchid4", "chartreuse4"), names=x_axis,
   at=position_labels, main="Volatilidad precio", cex.main=1.25, xlim = c(0, nExp*3),	xlab="", ylab ="")
legend("topright", c("Límites anticíclicos","VaR estresado"), lty=c(1,1), lwd=c(3,3), col=c("orchid4", "chartreuse4"))

# Volatility of returns
y_min_V = 0.0
y_max_V = 0.7
boxplot(volatility_ret_counter_stress[,(2*(asset-1)+indices)], notch=FALSE, col=c("orchid4", "chartreuse4"), names=x_axis,
   at=position_labels, main="Volatilidad rentabilidades", cex.main=1.25, xlim = c(0, nExp*3),	xlab="", ylab ="", yaxt='n')
axis(2, at=seq(y_min_V,y_max_V,by=.05), labels=paste(100*seq(y_min_V,y_max_V,by=.05), "%") )  # adjust y axis to show percentages
legend("topright", c("Límites anticíclicos","VaR estresado"), lty=c(1,1), lwd=c(3,3), col=c("orchid4", "chartreuse4"))

# Kurtosis of returns
boxplot(kurtosis_counter_stress[,(2*(asset-1)+indices)], notch=FALSE, col=c("orchid4", "chartreuse4"), names=x_axis,
   at=position_labels, main="Curtosis rentabilidades", cex.main=1.25, xlim = c(0, nExp*3),	xlab="", ylab ="")
legend("topright", c("Límites anticíclicos","VaR estresado"), lty=c(1,1), lwd=c(3,3), col=c("orchid4", "chartreuse4"))

# Hill index of returns
boxplot(hill_counter_stress[,(2*(asset-1)+indices)], notch=FALSE, col=c("orchid4", "chartreuse4"), names=x_axis,
   at=position_labels, main="Índice de Hill", cex.main=1.25, xlim = c(0, nExp*3),	xlab="", ylab ="")
#legend("topright", c("Límites anticíclicos","VaR estresado"), lty=c(1,1), lwd=c(3,3), col=c("orchid4", "chartreuse4"))

# Sharpe ratio averaged over the three strategies
x_axis_2 <- c("0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%")
plot(Sharpe_FUND_counter[,asset], type="l", col="orchid4", main="Índice de solidez medio", cex.main=1.25, xlab="", ylab="", lwd=2, xaxt='n', ylim=c(0.5,3))
lines(Sharpe_FUND_stress[,asset], type="l", col="chartreuse4", lwd=2, xaxt='n')
axis(1, at=1:nExp, labels=x_axis_2)
legend("topleft", c("Límites anticíclicos","VaR estresado"), lty=c(1,1), lwd=c(3,3), col=c("orchid4", "chartreuse4"))

# VaR averaged over the three strategies
boxplot(var_counter_stress[,(2*(asset-1)+indices)], notch=FALSE, col=c("orchid4", "chartreuse4"), names=x_axis,
   at=position_labels, main="VaR medio", xlim = c(0, nExp*3),	xlab="", ylab ="")
legend("topright", c("Límites anticíclicos","VaR estresado"), lty=c(1,1), lwd=c(3,3), col=c("orchid4", "chartreuse4"))


