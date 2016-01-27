# http://code.google.com/p/systemic-risk/
# 
# Some basic examples of general functionality in R. Inspired 
# by Adler (2010) "R in a nutshell"
#
# Copyright (c) 2011, CIMNE and Gilbert Peffer.
# All rights reserved
#
# This software is open-source under the BSD license; see 
# http://code.google.com/p/systemic-risk/wiki/SoftwareLicense
#
rm(list = ls())     # clear objects
graphics.off()      # close graphics windows
# Setting the path to the data folder (Example "C:/mymodels/simulators/networksimulator/rscripts/sandbox (devel)/data/")
#    root.dir: "C:/mymodels/simulators"
#    data.dir: "/networksimulator/rscripts/sandbox (devel)/data/"
#
# Set the root directory (add your path)
root.dir <- "E:/Thesis/Analyses/Models/Simulators"
# Build the home directory (shouldn't be necessary to change)
home.dir <- paste(root.dir, "/agentsimulator/out/fjsimulation-a/", sep="")

# Read data from csv files
tslogprices <- 
  read.table(paste(home.dir,"list_price_timeseries.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
tslogvalues <- 
  read.table(paste(home.dir,"list_values_timeseries.csv",sep=""),
   header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tspricenoise <- 
  #read.table(paste(home.dir,"list_price_noise_timeseries.csv",sep=""),
   #header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsorderfund <- 
  #read.table(paste(home.dir,"list_order_fund_timeseries.csv",sep=""),
   #header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#tsordertech <- 
  #read.table(paste(home.dir,"list_order_tech_timeseries.csv",sep=""),
   #header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
#
# Create a data frame of prices from log prices
tsprices <- data.frame(lapply(tslogprices, function(x) exp(x)))
tsprices$tick <- 1:dim(tsprices)[1]		# correct tick values
# Change column headers to p_i
numRuns <- dim(tsprices)[2] - 1
names(tsprices)[2:(numRuns + 1)] <- paste(rep("p_", numRuns), c(1:numRuns), sep="")

# TODO (in progress) - creating a dataframe that can be used by the lattice graphics package
# We map the results from the different simulation runs into a single column and add the run
# identifier in a new column. The code presumes that the header of run i is in the format
# headerstr_i to automatically extract the number of the simulation run and generate new
# variable names.

dflist <- c(list(tslogprices), list(tslogvalues), list(tsprices))	# list of dataframes we want to merge
numRuns <- dim(tslogvalues)[2] - 1					# number of runs
numResults <- length(dflist)						# number of results to merge

# Build the merged dataframe based on the 'numResults' individual dataframes
for (i in seq(1:numResults)) {
	dfi <- dflist[[i]]					# the i-th result
	numRuns <- dim(tslogvalues)[2] - 1  # number of runs for this result
	
	for (j in seq(1:numRuns)) {
		dfj <- subset(dfi, select = c(tick, j + 1))			# j-th run of i-th result
		runStrVec <- unlist(strsplit(names(dfj)[2], "_"))	# split the result label along the underscores '_'
		runStr <- tail(runStrVec,1)							# extract the run index
		dfj$run <- rep(runStr, dim(dfi)[1])			# add a 'run' label as a variable, with the run index as the values 
		colName <- paste(runStrVec[-length(runStrVec)], collapse="_")	# create a column name without the run index for the variable...
		names(dfj)[2] <- colName							# ... and assign to the column label
		
		# build the merged dataframe incrementally
		if (j == 1) {
			dfmerged <- dfj
		}
		else {
			dfmerged <- rbind(dfmerged,dfj)
		}
	}

	if (i == 1) {
		dfallmerged <- dfmerged
	}
	else {
		dfallmerged <- merge(dfallmerged, dfmerged)
	}

	rm(dfmerged)
}

dfallmerged <- dfallmerged[order(dfallmerged$run, dfallmerged$tick), ]		# sort the dataframe, first along runs then along ticks

library(lattice)
histogram(~ log_p | factor(run), data = dfallmerged)
dev.new()
histogram(~ log_v | factor(run), data = dfallmerged)
dev.new()
densityplot(~ log_p | factor(run), data = dfallmerged, plot.points = FALSE, ref = TRUE)
dev.new()
densityplot(~ log_v | factor(run), data = dfallmerged, plot.points = FALSE, ref = TRUE)
dev.new()
xyplot(p ~ tick | run, subset(dfallmerged, tick < 2000), type="l")
dev.new()
xyplot(log_p ~ tick | run, subset(dfallmerged, tick < 2000), type="l")

# Plot prices
#plot(tslogvalues, type="l")
#dev.new()
#plot(tslogprices, type="l")
#dev.new()
#plot(tsprices, type="l")
##dev.new()
#plot(tspricenoise, type="l")
#dev.new()
#plot(tsorderfund, type="l")
#dev.new()
#plot(tsordertech, type="l")
#dev.new()
#plot(tstotalorder, type="l")
#