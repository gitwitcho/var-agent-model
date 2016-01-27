
###################################################################
#                                                                 #
#       THESIS - Plot of heatmap of instability indicators        #
#         as function of VaR limit x Volatility window            #
#                                                                 #
###################################################################


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


# ------ 'PARAMETERS' & INITIAL INFORMATION ------ #

nAssets = 1
nRuns = 50
nTicks = 4000
volWindow = 20       # Window used to calculate volatility
warmingWindow = 400  # Warming window for TREND and LS traders


# Setting the path to the data folder

# Set the root directory (add your path)
root.dir <- "C:/Users/llacay/eclipse"

# Build the home directory (shouldn't be necessary to change)
home.dir <- paste(root.dir, "/agentsimulator/out/trend-value-ls-var-abm-simulation/Heatmap/", sep="")


# ------ Create arrays to allocate instability indicators each experiment ------ #

nLVar = 21
nVolW = 16
nExp = nVolW

x = seq(from=1, to=nLVar)
y = seq(from=1, to=nVolW)

volatility_ret_avg_A1 <- array(0, dim=c(nLVar, nVolW))  # Array to store the mean return volatility for each experiment
kurtosis_ret_avg_A1 <- array(0, dim=c(nLVar, nVolW))    # Array to store the mean return kurtosis for each experiment
hill_ret_avg_A1 <- array(0, dim=c(nLVar, nVolW))        # Array to store the mean return Hill index for each experiment
sharpe_avg_A1 <- array(0, dim=c(nLVar, nVolW))          # Array to store the mean Sharpe ratio of agent's wealth for each experiment


###################### Re-RUN CODE BELOW FOR THE DIFFERENT VALUES OF LVAR ####################

set = 21     # Indicate the number of experiments set, to allocate results in the correct row of the arrays


# ------ Read data from csv files for each experiment ------ #

tsprices <- read.table(paste(home.dir,"list_price_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsFUNDwealth <- read.table(paste(home.dir,"list_fundwealth_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsTRENDwealth <- read.table(paste(home.dir,"list_trendwealth_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tsLSwealth <- read.table(paste(home.dir,"list_lswealth_timeseries_E0.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)


if (nExp > 1) {   # Read data for single experiments and merge them
   for (e in seq(from=1, to=nExp-1)) {
      tsprices_exp <- read.table(paste(home.dir, paste("list_price_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsprices <- merge(tsprices, tsprices_exp, by="tick")

      tsFUNDwealth_exp <- read.table(paste(home.dir, paste("list_fundwealth_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsFUNDwealth <- merge(tsFUNDwealth, tsFUNDwealth_exp, by="tick")

      tsTRENDwealth_exp <- read.table(paste(home.dir, paste("list_trendwealth_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsTRENDwealth <- merge(tsTRENDwealth, tsTRENDwealth_exp, by="tick")

      tsLSwealth_exp <- read.table(paste(home.dir, paste("list_lswealth_timeseries_E",e,".csv", sep=""), sep=""),
         header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
      tsLSwealth <- merge(tsLSwealth, tsLSwealth_exp, by="tick")
   }
}


# ------ Calculate logarithmic prices (for returns) and values ------ #

tslogprices <- log(tsprices)
tslogprices[[1]] <- tsprices[[1]]  # The 'tick' column must not change


# ------ CALCULATE INSTABILITY INDICATORS ------ #

# ... Volatility of returns ... #

vol_avg <- array(0, dim=c(1, nAssets*nExp))    # Averages the volatility of returns obtained on each run

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         vol_avg[,i+k*nAssets] <- vol_avg[,i+k*nAssets] + sd(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]), na.rm = FALSE)
      }
      vol_avg[,i+k*nAssets] <- vol_avg[,i+k*nAssets]/nRuns
   }
}

vol_avg <- vol_avg * sqrt(252)  # annualise volatility

volatility_ret_avg_A1[set,] <- vol_avg[,seq(from=1, to=(nExp-1)*nAssets+1, by=nAssets)]


# ... Return kurtosis ... #

kurt_avg <- array(0, dim=c(1, nAssets*nExp))    # Averages the kurtosis of log-returns obtained on each run

for (k in seq(from=0, to=nExp-1)) {
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         kurt_avg[,i+k*nAssets] <- kurt_avg[,i+k*nAssets] + kurtosis(diff(tslogprices[[i+1+j*nAssets+k*nAssets*nRuns]]), na.rm = FALSE, method="excess")[1]
      }
      kurt_avg[,i+k*nAssets] <- kurt_avg[,i+k*nAssets]/nRuns
   }
}

kurtosis_ret_avg_A1[set,] <- kurt_avg[,seq(from=1, to=(nExp-1)*nAssets+1, by=nAssets)]



# ... Hill index of returns ... #

hillreturns <- array(0, dim=c(1, nAssets*nExp*nRuns))
hillreturns_avg <- array(0, dim=c(1, nAssets*nExp))
sample_size = 0.1 * nTicks

for (j in seq(from=1, to=nAssets*nExp*nRuns)) {
   hillreturns[1,j] <- hill(diff(tslogprices[[1+j]]), option = "alpha", end = sample_size, p = NA)$y[1]
}

for (k in seq(from=0, to=nExp-1)) {       # Averages the Hill index of log-returns obtained on each run
   for (i in seq(from=1, to=nAssets)) {
      for (j in seq(from=0, to=nRuns-1)) {
         hillreturns_avg[1,i+k*nAssets] <- hillreturns_avg[1,i+k*nAssets] + hillreturns[1,i+j*nAssets+k*nAssets*nRuns]
      }
      hillreturns_avg[1,i+k*nAssets] <- hillreturns_avg[1,i+k*nAssets]/nRuns
   }
}

hill_ret_avg_A1[set,] <- hillreturns_avg[,seq(from=1, to=(nExp-1)*nAssets+1, by=nAssets)]



# ... Sharpe ratio of agents' wealth (strength indicator) ... #

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
      if (sd(final_FUND_wealth) > 0) {
         Sharpe_FUND[e,i] = mean(final_FUND_wealth)/sd(final_FUND_wealth)
      }
      if (sd(final_TREND_wealth) > 0) {
         Sharpe_TREND[e,i] = mean(final_TREND_wealth)/sd(final_TREND_wealth)
      }
   }   
}

mean_Sharpe <- (Sharpe_FUND + Sharpe_TREND)/2

sharpe_avg_A1[set,] <- mean_Sharpe[,1]


################################## COPY TILL HERE ###############################################



#volatility_ret_avg_A1_const <- volatility_ret_avg_A1
#kurtosis_ret_avg_A1_const <- kurtosis_ret_avg_A1
#hill_ret_avg_A1_const <- hill_ret_avg_A1
#sharpe_avg_A1_const <- sharpe_avg_A1




# ------ Draw the heat map for each indicator ------ #

x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
y_axis <- c("5", "", "", "14", "", "", "23", "", "", "32", "", "", "41", "", "", "50")

z <- volatility_ret_avg_A1_const
filled.contour(x, y, z, nlevels=9, color = function(x)rev(heat.colors(x)),
	plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
	plot.title = title(main = "Return volatility",
		     xlab = "VaR limit", ylab = "Volatility window", cex.lab=1.5, cex.main=1.75) )

z <- kurtosis_ret_avg_A1_const
filled.contour(x, y, z, nlevels=9, color = function(x)rev(heat.colors(x)),
	plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
	plot.title = title(main = "Return kurtosis",
		     xlab = "VaR limit", ylab = "Volatility window", cex.lab=1.5, cex.main=1.75) )

z <- hill_ret_avg_A1_const
filled.contour(x, y, z, nlevels=9, color = heat.colors,
	plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
	plot.title = title(main = "Return Hill index",
		     xlab = "VaR limit", ylab = "Volatility window", cex.lab=1.5, cex.main=1.75) )

z <- sharpe_avg_A1_const
filled.contour(x, y, z, nlevels=9, color = heat.colors,
	plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
	plot.title = title(main = "Agent strength index",
		     xlab = "VaR limit", ylab = "Volatility window", cex.lab=1.5, cex.main=1.75) )


# ------ Draw the surface plot for each indicator ------ #

x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
y_axis <- c("5", "", "", "14", "", "", "23", "", "", "32", "", "", "41", "", "", "50")

theseCol = function(x)rev(heat.colors(x))  ## Color


z <- volatility_p_avg_A1
wireframe(z, shade = FALSE, aspect = c(25/20, 20/25), xlab = "Límite VaR", ylab = "Ventana volatilidad", zlab="", 
   main = "Volatilidad precio", scales = list(arrows = FALSE, col = 1), drape = TRUE, col.regions=theseCol(150), 
   par.settings = list(axis.line = list(col = "transparent")), screen = list(z = 5, x = -90, y = 3) )





# ------ Improved contour plot to show several plots with the same legend  ------ #


########### Definition of filled.contour3 ##############
# Source: http://wiki.cbr.washington.edu/qerm/sites/qerm/images/1/16/Filled.contour3.R
#
filled.contour3 <-
  function (x = seq(0, 1, length.out = nrow(z)),
            y = seq(0, 1, length.out = ncol(z)), z, xlim = range(x, finite = TRUE), 
            ylim = range(y, finite = TRUE), zlim = range(z, finite = TRUE), 
            levels = pretty(zlim, nlevels), nlevels = 20, color.palette = cm.colors, 
            col = color.palette(length(levels) - 1), plot.title, plot.axes, 
            key.title, key.axes, asp = NA, xaxs = "i", yaxs = "i", las = 1, 
            axes = TRUE, frame.plot = axes,mar, ...) 
{
  # modification by Ian Taylor of the filled.contour function
  # to remove the key and facilitate overplotting with contour()
  # further modified by Carey McGilliard and Bridget Ferris
  # to allow multiple plots on one page

  if (missing(z)) {
    if (!missing(x)) {
      if (is.list(x)) {
        z <- x$z
        y <- x$y
        x <- x$x
      }
      else {
        z <- x
        x <- seq.int(0, 1, length.out = nrow(z))
      }
    }
    else stop("no 'z' matrix specified")
  }
  else if (is.list(x)) {
    y <- x$y
    x <- x$x
  }
  if (any(diff(x) <= 0) || any(diff(y) <= 0)) 
    stop("increasing 'x' and 'y' values expected")
 # mar.orig <- (par.orig <- par(c("mar", "las", "mfrow")))$mar
 # on.exit(par(par.orig))
 # w <- (3 + mar.orig[2]) * par("csi") * 2.54
 # par(las = las)
 # mar <- mar.orig
 plot.new()
 # par(mar=mar)
  plot.window(xlim, ylim, "", xaxs = xaxs, yaxs = yaxs, asp = asp)
  if (!is.matrix(z) || nrow(z) <= 1 || ncol(z) <= 1) 
    stop("no proper 'z' matrix specified")
  if (!is.double(z)) 
    storage.mode(z) <- "double"
  .Internal(filledcontour(as.double(x), as.double(y), z, as.double(levels), 
                          col = col))
  if (missing(plot.axes)) {
    if (axes) {
      title(main = "", xlab = "", ylab = "")
      Axis(x, side = 1)
      Axis(y, side = 2)
    }
  }
  else plot.axes
  if (frame.plot) 
    box()
  if (missing(plot.title)) 
    title(...)
  else plot.title
  invisible()
}
#
########################################################


########### Definition of filled.contour3 ##############
# Source: http://wiki.cbr.washington.edu/qerm/sites/qerm/images/2/25/Filled.legend.R
#
filled.legend <-
  function (x = seq(0, 1, length.out = nrow(z)), y = seq(0, 1, 
    length.out = ncol(z)), z, xlim = range(x, finite = TRUE), 
    ylim = range(y, finite = TRUE), zlim = range(z, finite = TRUE), 
    levels = pretty(zlim, nlevels), nlevels = 20, color.palette = cm.colors, 
    col = color.palette(length(levels) - 1), plot.title, plot.axes, 
    key.title, key.axes, asp = NA, xaxs = "i", yaxs = "i", las = 1, 
    axes = TRUE, frame.plot = axes, ...) 
{
  # modification of filled.contour by Carey McGilliard and Bridget Ferris
  # designed to just plot the legend
    if (missing(z)) {
        if (!missing(x)) {
            if (is.list(x)) {
                z <- x$z
                y <- x$y
                x <- x$x
            }
            else {
                z <- x
                x <- seq.int(0, 1, length.out = nrow(z))
            }
        }
        else stop("no 'z' matrix specified")
    }
    else if (is.list(x)) {
        y <- x$y
        x <- x$x
    }
    if (any(diff(x) <= 0) || any(diff(y) <= 0)) 
        stop("increasing 'x' and 'y' values expected")
  #  mar.orig <- (par.orig <- par(c("mar", "las", "mfrow")))$mar
  #  on.exit(par(par.orig))
  #  w <- (3 + mar.orig[2L]) * par("csi") * 2.54
    #layout(matrix(c(2, 1), ncol = 2L), widths = c(1, lcm(w)))
  #  par(las = las)
  #  mar <- mar.orig
  #  mar[4L] <- mar[2L]
  #  mar[2L] <- 1
  #  par(mar = mar)
   # plot.new()
    plot.window(xlim = c(0, 1), ylim = range(levels), xaxs = "i", 
        yaxs = "i")
    rect(0, levels[-length(levels)], 1, levels[-1L], col = col)
    if (missing(key.axes)) {
        if (axes) 
            axis(4)
    }
    else key.axes
    box()
}
    #
#    if (!missing(key.title)) 
#        key.title
#    mar <- mar.orig
#    mar[4L] <- 1
#    par(mar = mar)
#    plot.new()
#    plot.window(xlim, ylim, "", xaxs = xaxs, yaxs = yaxs, asp = asp)
#    if (!is.matrix(z) || nrow(z) <= 1L || ncol(z) <= 1L) 
#        stop("no proper 'z' matrix specified")
#    if (!is.double(z)) 
#        storage.mode(z) <- "double"
#    .Internal(filledcontour(as.double(x), as.double(y), z, as.double(levels), 
#        col = col))
#    if (missing(plot.axes)) {
#        if (axes) {
#            title(main = "", xlab = "", ylab = "")
#            Axis(x, side = 1)
#            Axis(y, side = 2)
#        }
#    }
#    else plot.axes
#    if (frame.plot) 
#        box()
#    if (missing(plot.title)) 
#        title(...)
#    else plot.title
#    invisible()
#}
#
########################################################

x_axis <- c("5", "", "11", "", "17", "", "23", "", "29", "", "35", "", "41", "", "47", "", "53", "", "59", "", "65")
y_axis <- c("5", "", "", "14", "", "", "23", "", "", "32", "", "", "41", "", "", "50")

#plot.new() is necessary if using the modified versions of filled.contour
plot.new()

#I am organizing where the plots appear on the page using the "plt" argument in "par()"
#par(new = "TRUE",plt = c(0.1,0.4,0.60,0.95),las = 1,cex.axis = 1)

par(mfrow=c(1,3), mar=c(4, 4, 4, 8), oma=c(1,1,1,1))




# Return volatility

z_min <- min(volatility_ret_avg_A1_const, volatility_ret_avg_A1_counter, volatility_ret_avg_A1_stress)
z_max <- max(volatility_ret_avg_A1_const, volatility_ret_avg_A1_counter, volatility_ret_avg_A1_stress)

z <- volatility_ret_avg_A1_const
filled.contour3(x, y, z, color=function(x)rev(heat.colors(x)), xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "Límite constante",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

z <- volatility_ret_avg_A1_counter
filled.contour3(x, y, z, color=function(x)rev(heat.colors(x)), xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "Límite anticíclico",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

z <- volatility_ret_avg_A1_stress
filled.contour3(x, y, z, color=function(x)rev(heat.colors(x)), xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "VaR estresado",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

#Add a legend:
par(new = "TRUE",plt = c(0.85,0.9,0.25,0.85),las = 1,cex.axis = 1)
filled.legend(x, y, z, color = function(x)rev(heat.colors(x)), xlab = "", ylab = "", xlim = c(min(xintercepts),max(xintercepts)),ylim = c(min(slopes),max(slopes)),zlim = c(z_min,z_max))



# Return kurtosis

z_min <- min(kurtosis_ret_avg_A1_const, kurtosis_ret_avg_A1_counter, kurtosis_ret_avg_A1_stress)
z_max <- max(kurtosis_ret_avg_A1_const, kurtosis_ret_avg_A1_counter, kurtosis_ret_avg_A1_stress)

z <- kurtosis_ret_avg_A1_const
filled.contour3(x, y, z, color=function(x)rev(heat.colors(x)), xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "Límite constante",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

z <- kurtosis_ret_avg_A1_counter
filled.contour3(x, y, z, color=function(x)rev(heat.colors(x)), xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "Límite anticíclico",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

z <- kurtosis_ret_avg_A1_stress
filled.contour3(x, y, z, color=function(x)rev(heat.colors(x)), xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "VaR estresado",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

#Add a legend:
par(new = "TRUE",plt = c(0.85,0.9,0.25,0.85),las = 1,cex.axis = 1)
filled.legend(x, y, z, color = function(x)rev(heat.colors(x)), xlab = "", ylab = "", xlim = c(min(xintercepts),max(xintercepts)),ylim = c(min(slopes),max(slopes)),zlim = c(z_min,z_max))



# Hill index

z_min <- min(hill_ret_avg_A1_const, hill_ret_avg_A1_counter, hill_ret_avg_A1_stress)
z_max <- max(hill_ret_avg_A1_const, hill_ret_avg_A1_counter, hill_ret_avg_A1_stress)

z <- hill_ret_avg_A1_const
filled.contour3(x, y, z, color=heat.colors, xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "Límite constante",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

z <- hill_ret_avg_A1_counter
filled.contour3(x, y, z, color=heat.colors, xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "Límite anticíclico",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

z <- hill_ret_avg_A1_stress
filled.contour3(x, y, z, color=heat.colors, xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "VaR estresado",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

#Add a legend:
par(new = "TRUE",plt = c(0.85,0.9,0.25,0.85),las = 1,cex.axis = 1)
filled.legend(x, y, z, color = heat.colors, xlab = "", ylab = "", xlim = c(min(xintercepts),max(xintercepts)),ylim = c(min(slopes),max(slopes)),zlim = c(z_min,z_max))




# Sharpe

z_min <- min(sharpe_avg_A1_const, sharpe_avg_A1_counter, sharpe_avg_A1_stress)
z_max <- max(sharpe_avg_A1_const, sharpe_avg_A1_counter, sharpe_avg_A1_stress)

z <- sharpe_avg_A1_const
filled.contour3(x, y, z, color=heat.colors, xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "Límite constante",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

z <- sharpe_avg_A1_counter
filled.contour3(x, y, z, color=heat.colors, xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "Límite anticíclico",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

z <- sharpe_avg_A1_stress
filled.contour3(x, y, z, color=heat.colors, xlab = "",ylab = "", xlim = c(min(x),max(x)), ylim = c(min(y),max(y)), zlim = c(z_min,z_max),
      plot.axes={axis(1,at=1:nLVar, labels=x_axis, cex.axis=1.25)
		     axis(2,at=1:nVolW, labels=y_axis, cex.axis=1.25)},
      plot.title = title(main = "VaR estresado",
		     xlab = "Límite VaR", ylab = "Ventana volatilidad", cex.lab=1.5, cex.main=1.75) )

#Add a legend:
par(new = "TRUE",plt = c(0.85,0.9,0.25,0.85),las = 1,cex.axis = 1)
filled.legend(x, y, z, color = heat.colors, xlab = "", ylab = "", xlim = c(min(xintercepts),max(xintercepts)),ylim = c(min(slopes),max(slopes)),zlim = c(z_min,z_max))




##_________________________________________________________________#
##                                                                 #
##         Search for ways to plot surface/contour plots           #
##_________________________________________________________________#
##                                                                 #
#
### Preparation: create matrix. Example:
#
#x = seq(from=1, to=nRuns)
#y = seq(from=1, to=nExp)
#
#for (a in seq(from=1, to=nAssets)) {
#   test_matrix <- array(0, dim=c(nRuns, nExp))  # Array to store the volatility of each run
#
#   for (k in seq(from=0, to=nExp-1)) {
#      for (j in seq(from=0, to=nRuns-1)){
#         test_matrix[j+1,k+1] = sd(diff(tslogprices[[a+1+j*nAssets+k*nAssets*nRuns]]))
#      }
#   }
#}
#
#z = test_matrix
#
##---
#
#df_test <- melt(test_matrix)
#colnames(df_test) <- c("Run", "Experiment", "value")
#
#ggplot(df_test, aes(x, y, fill = value)) + geom_tile() +
#  xlab("Run") + ylab("Experiment") +
#  opts(title = "Return volatility") +
#  scale_fill_gradient(limits = c(0, 0.01), low = "yellow", high = "red") +
#  scale_x_continuous(expand = c(0,0)) +
#  scale_y_continuous(expand = c(0,0))
#
##---
#
### ~ Heatmap
#
#image(x, y, z, xlab = "Run", ylab = "Experiment", main = "Volatility")
#box()
#
##---
#
### Surface plot B/W (3D)
#
#persp(x,y,z,theta=90,phi=30,ticktype="detailed") 
#
##---
#
### Surface plot with colours (3D)
#
#theseCol = function(x)rev(heat.colors(x))  ## Color
#
#wireframe(z, shade = FALSE, aspect = c(25/20, 20/25), xlab = "Run", ylab = "Experiment", zlab="", 
#   main = "Return volatility", scales = list(arrows = FALSE, col = 1), drape = TRUE, col.regions=theseCol(150), 
#   par.settings = list(axis.line = list(col = "transparent")))
#
##---
#
### Contour plots (2D)
#
## (?) I do not know how to change the colours:
#contourplot(z, cuts = 10, region = TRUE, xlab = "Run", ylab = "Experiment",
#            labels = NULL, main = "Return volatility", col=brewer.pal(6,"YlOrRd"))
#
## Better option:
#filled.contour(x, y, z, nlevels=6, col=brewer.pal(6,"YlOrRd"))
#
#filled.contour(x, y, z, nlevels=9, color = function(x)rev(heat.colors(x)))
#
