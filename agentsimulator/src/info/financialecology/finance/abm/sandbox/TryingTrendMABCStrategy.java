/**
 * Simple financial systemic risk simulator for Java
 * http://code.google.com/p/systemic-risk/
 * 
 * Copyright (c) 2011, 2012
 * Gilbert Peffer, CIMNE
 * gilbert.peffer@gmail.com
 * All rights reserved
 *
 * This software is open-source under the BSD license; see 
 * http://code.google.com/p/systemic-risk/wiki/SoftwareLicense
 */
package info.financialecology.finance.abm.sandbox;

import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy_old;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy_old.Multiplier;
import info.financialecology.finance.utilities.WorldClock;
import info.financialecology.finance.utilities.datagen.DataGenerator;
import info.financialecology.finance.utilities.datagen.RandomDistDataGenerator;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool;
import info.financialecology.finance.utilities.datagen.SinusDataGenerator;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool.DistributionType;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.VersatileChart;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeries;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeriesCollection;

import org.jfree.data.time.Day;
import org.slf4j.LoggerFactory;



import cern.colt.Timer;
import cern.colt.list.DoubleArrayList;
import cern.jet.random.*;
import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;

/**
 * Testing class for TrendMABCStrategy
 * 
 * @author Gilbert Peffer
 *
 */

/**
 * #################################################################################
 * 
 * This class uses an OLD version of TrendMABCStrategy ('TrendMABCStrategy_old').
 *  
 * #################################################################################
 */

public class TryingTrendMABCStrategy {

    /**
     * @param args
     */
    public static void main(String[] args) {
        Timer timerAll  = new Timer();  // a timer to calculate total execution time (cern.colt)
        Timer timer     = new Timer();  // a timer to calculate execution times of particular methods (cern.colt)
        timerAll.start();

        Logger root = (Logger)LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        root.setLevel(Level.TRACE);
        Logger logger = (Logger)LoggerFactory.getLogger("main");
        
        /**
         *      SET-UP
         */
        logger.trace("Setting up test objects and parameters");
        
        int lengthOfTs = 600;
        int constantTs = 10;
        
        DoubleTimeSeries constTs = new DoubleTimeSeries();
        constTs.fillWithConstants(lengthOfTs, constantTs);

        double unifA, unifB;
        double shift = 50, amplitude = 50, lag = 0, lambda = 100;
        
        RandomGeneratorPool.configureGeneratorPool();
        //RandomGeneratorPool.configureGeneratorPool(4);  // set the random seed to compare simulations
        
        RandomDistDataGenerator randGen;
        SinusDataGenerator sinusGen;
        
        DoubleArrayList dalValues;
        
        TrendMABCStrategy_old trend = new TrendMABCStrategy_old("share", 10, 20, 10, 1.0, constTs, 0, Multiplier.MA_SLOPE_DIFFERENCE);
        
        /**
         * ######################################################################################
         * 
         * Test: minValue(...) and maxValue(...) methods
         * 
         * Creates a series of uniformly distributed data points in [unifA, unifB]
         * and checks that the max and min values calculated with the methods minValue 
         * and maxValue are equal to the max and min values obtained from CERN's sort function.
         * This test does not work with the window argument: it calculates the max and min 
         * of the whole series.
         * 
         * ######################################################################################
         */
        
        // TODO this test would need to be adapted to work with the window argument
        
        logger.trace("Testing the max(...) and min(...) methods");
        
        /*
         * Setting up the uniform random generator and generating values
         */
        unifA = -1000;
        unifB = 500;

        randGen = new RandomDistDataGenerator("gen_1", DistributionType.UNIFORM, unifA, unifB);
        dalValues = randGen.nextDoubles(lengthOfTs);

        /*
         * Comparing min and max values computed in two different ways
         */
        double maxValueTrend, minValueTrend, maxValueSort, minValueSort;

        maxValueTrend = trend.maxValue(dalValues, lengthOfTs);
        minValueTrend = trend.minValue(dalValues, lengthOfTs);
        
        dalValues.sort();
        maxValueSort = dalValues.get(dalValues.size() - 1);
        minValueSort = dalValues.get(0);

        /*
         * Printing the results
         */
        logger.debug("Random values: {}", VersatileTimeSeries.printValues(dalValues));
        logger.debug("Positions: {}", VersatileTimeSeries.printValues(trend.getTsPos()));
        
        logger.debug("TrendMABCStrategy.maxValue() = {} vs last value of DoubleArrayList.sort() = {}", maxValueTrend, maxValueSort);
        logger.debug("TrendMABCStrategy.minValue() = {} vs first value of DoubleArrayList.sort() = {}", minValueTrend, minValueSort);
        
        
        /**
         * ######################################################################################
         * 
         * Test: MA(...) method for random time series
         * 
         * Computes a random time series and its long-term MA, to visually
         * check that it tends to the mean of the random distribution.
         * 
         * ######################################################################################
         */
        
        logger.trace("Testing the MA(...) method for random time series");
        
        /*
         * Setting up the uniform random generator and generating values
         */
        unifA = -1000;
        unifB = 500;

        randGen = new RandomDistDataGenerator("gen_2", DistributionType.UNIFORM, unifA, unifB);
        dalValues = randGen.nextDoubles(lengthOfTs);

        /*
         * Setting up the (incremental) moving average calculation
         */
        int maTicks = 300;   // size of the MA window
        
        DoubleTimeSeries dtsValues = new DoubleTimeSeries();
        DoubleTimeSeries dtsMA = new DoubleTimeSeries();
        
        double ma = 0;

        for (int i = 0; i < lengthOfTs; i++) {
            dtsValues.add(dalValues.get(i));
            
            if (i < maTicks - 1)
                ma = 0;
            else
                ma = trend.incrementalMA(dtsValues, maTicks, ma);
            
            dtsMA.add(ma);
        }
        
        /*
         * Printing and graphing the results
         */
        logger.debug("Random values: {}", VersatileTimeSeries.printValues(dtsValues));
        logger.debug("MA of random values: {}", VersatileTimeSeries.printValues(dtsMA));
        
        VersatileChart charts = new VersatileChart();
        charts.getInternalParms().autoRange = true;
        charts.getInternalParms().autoRangePadding = 0;
        charts.getInternalParms().ticks = true;
        
        /*
        charts.draw(new VersatileTimeSeries("Random Values", dtsValues), new VersatileTimeSeries("MA", dtsMA));
        */
        
        
        /**
         * ######################################################################################
         * 
         * Test: MA(...) method for sinus-shaped time series
         * 
         * Computes two MA series so they can be used to visually
         * check the trade() method, which uses two MA series internally
         * to compute entry and exit signals.
         * 
         * ######################################################################################
         */
        
        logger.trace("Testing the MA(...) method for sinus-shaped time series");
        
        /*
         * Setting up the sinus generator and generating values
         */
        shift = 100;
        amplitude = 20;
        lag = 0;
        lambda = 100;
        
        sinusGen = new SinusDataGenerator(shift, amplitude, lag, lambda);
        dalValues = sinusGen.nextDoubles(lengthOfTs);

        /*
         * Setting up the moving average calculations
         */
        int maTicks_1 = 10;   // This must be equal to maShortTicks
        int maTicks_2 = 40;   // This must be equal to maLongTicks

        int warmUpPeriod = Math.max(maTicks_1, maTicks_2);
        
        dtsValues = new DoubleTimeSeries();
        DoubleTimeSeries dtsMA_1 = new DoubleTimeSeries();
        DoubleTimeSeries dtsMA_2 = new DoubleTimeSeries();
        
        /*
         * Setting up the trend strategy
         */
        trend = new TrendMABCStrategy_old("share", 2, 3, 5, 6, dtsValues, 0, Multiplier.MA_SLOPE_DIFFERENCE);  // arbitrary argument values since they are not used in MA calculations

        /*
         * Computing the 2 moving average series 
         */
        double ma_1 = 0, ma_2 = 0;
        boolean firstMAComputation = true;
        
        for (int i = 0; i < lengthOfTs; i++) {
            dtsValues.add(dalValues.get(i));
            
            if (i < warmUpPeriod - 1) {
                ma_1 = 0;
                ma_2 = 0;
            }
            else {  // force a full MA calculation first time around, then do incremental calculations
                if (firstMAComputation) {
                    ma_1 = trend.fullMA(dtsValues, maTicks_1);
                    ma_2 = trend.fullMA(dtsValues, maTicks_2);
                    firstMAComputation = false;
                } else {
                    ma_1 = trend.incrementalMA(dtsValues, maTicks_1, ma_1);
                    ma_2 = trend.incrementalMA(dtsValues, maTicks_2, ma_2);
                }
            }
            
            dtsMA_1.add(ma_1);
            dtsMA_2.add(ma_2);
        }
        
        /*
         * Printing and graphing the results
         */
        logger.debug("Sinus values: {}", VersatileTimeSeries.printValues(dtsValues));     // TODO Use the time series collection for printing this out since it creates a proper table format for all values
        logger.debug("MA_1 of sinus values: {}", VersatileTimeSeries.printValues(dtsMA_1));
        logger.debug("MA_2 of sinus values: {}", VersatileTimeSeries.printValues(dtsMA_2));
        
        charts = new VersatileChart();
        charts.getInternalParms().autoRange = true;
        charts.getInternalParms().autoRangePadding = 0;
        charts.getInternalParms().ticks = true;
        
/*        charts.draw(new VersatileTimeSeries("Sinus Values", dtsValues), new VersatileTimeSeries("MA_1", dtsMA_1), 
                new VersatileTimeSeries("MA_2", dtsMA_2));
*/
        /**
         * ######################################################################################
         * 
         * Test: trade() method for uniformly distributed prices
         * 
         * Computes a uniform distribution which is used as the input price process
         * for the method trade() to compute entry and exit signals and calculate
         * the positions.
         * 
         * ######################################################################################
         */
        
        logger.trace("Testing the trade() method for a uniformly distributed time series");
        
        WorldClock.reset();
        
        /*
         * Setting up the uniform random generator and generating values
         */
        unifA = -1000;
        unifB = 500;

        randGen = new RandomDistDataGenerator("gen_3", DistributionType.UNIFORM, unifA, unifB);
        dalValues = randGen.nextDoubles(lengthOfTs);
       
        /*
         * Setting up the trend strategy
         */
        int maShortTicks = maTicks_1;
        int maLongTicks = maTicks_2;
        int bcTicks = 10;
        int capFactor = 1;
        
        DoubleTimeSeries uniformTs = new DoubleTimeSeries();
        
        /*
         * Setting up the moving average calculations
         */
        
        warmUpPeriod = Math.max(maShortTicks, maLongTicks);        
        
        dtsValues = new DoubleTimeSeries();
        dtsMA_1 = new DoubleTimeSeries();
        dtsMA_2 = new DoubleTimeSeries();
        
        /*
         * Setting up the trend strategy
         */        
        trend = new TrendMABCStrategy_old("share", maShortTicks, maLongTicks, bcTicks, capFactor, uniformTs, 0, Multiplier.MA_SLOPE_DIFFERENCE);
        
        /*
         * Computing the 2 moving average series 
         */
        ma_1 = 0;
        ma_2 = 0;
        firstMAComputation = true;
        
        for (int i = 0; i < lengthOfTs; i++) {
            dtsValues.add(dalValues.get(i));
            
            if (i < warmUpPeriod - 1) {
                ma_1 = 0;
                ma_2 = 0;
            }
            else {  // force a full MA calculation first time around, then do incremental calculations
                if (firstMAComputation) {
                    ma_1 = trend.fullMA(dtsValues, maShortTicks);
                    ma_2 = trend.fullMA(dtsValues, maLongTicks);
                    firstMAComputation = false;
                } else {
                    ma_1 = trend.incrementalMA(dtsValues, maShortTicks, ma_1);
                    ma_2 = trend.incrementalMA(dtsValues, maLongTicks, ma_2);
                }
            }
            
            dtsMA_1.add(ma_1);
            dtsMA_2.add(ma_2);
        }
        
        /*
         * Computing the max/min series used in the exit condition 
         */
        double max = 0, min = 0;
        dtsValues = new DoubleTimeSeries();
        DoubleTimeSeries dtsMA_max = new DoubleTimeSeries();
        DoubleTimeSeries dtsMA_min = new DoubleTimeSeries();
                
        for (int i = 0; i < lengthOfTs; i++) {
            dtsValues.add(dalValues.get(i));
            
            if (i<bcTicks){
            	max = 0;
            	min = 0;
            }
            else {
            	max = trend.maxValue(dtsValues, bcTicks);
                min = trend.minValue(dtsValues, bcTicks);
            }
                        
            dtsMA_max.add(max);
            dtsMA_min.add(min);
        }
        
        /*
         * Running the trading simulation with the trend strategy 
         */
        int tick = WorldClock.currentTick();
        
        for (int i = 0; i < lengthOfTs; i++) {            
        	uniformTs.add(tick, dalValues.get(tick));
        	trend.trade();            
            tick = WorldClock.incrementTick();
        }
        
        /*
         * Printing and graphing the results
         */
        logger.debug("Positions: {}", VersatileTimeSeries.printValues(trend.getTsPos()));
        
        /*        
        charts.draw(new VersatileTimeSeries("Uniform Values", uniformTs), new VersatileTimeSeries("MA_1", dtsMA_1), 
                new VersatileTimeSeries("MA_2", dtsMA_2),  
                new VersatileTimeSeries("Positions for Uniform", trend.getTsPos()));
        
        charts.draw(new VersatileTimeSeries("Uniform values", uniformTs), new VersatileTimeSeries("max", dtsMA_max), 
                new VersatileTimeSeries("min", dtsMA_min),  
                new VersatileTimeSeries("Positions for Uniform", trend.getTsPos()));
        */
        
        
        /**
         * ######################################################################################
         * 
         * Test: trade() method for a brownian motion
         * 
         * Computes a normal brownian motion which is used as the input price process
         * for the method trade() to compute entry and exit signals and calculate
         * the positions.
         * 
         * ######################################################################################
         */
        
        logger.trace("Testing the trade() method for a brownian motion time series");
        
        WorldClock.reset();
        
        /*
         * Setting up the normal random generator and generating values
         */
        double mu = 0;
        double sigma = 1;

        randGen = new RandomDistDataGenerator("gen_4", DistributionType.NORMAL, mu, sigma);
        dalValues = randGen.nextDoubles(lengthOfTs);
        
        /*
         * Setting up the trend strategy
         */
        maShortTicks = maTicks_1;
        maLongTicks = maTicks_2;
        bcTicks = 10;
        capFactor = 1;
        
        DoubleTimeSeries brownianTs = new DoubleTimeSeries();
        
        /*
         * Setting up the moving average calculations
         */
        
        warmUpPeriod = Math.max(maShortTicks, maLongTicks);        
        
        dtsValues = new DoubleTimeSeries();
        dtsMA_1 = new DoubleTimeSeries();
        dtsMA_2 = new DoubleTimeSeries();
        
        /*
         * Setting up the trend strategy
         */        
        trend = new TrendMABCStrategy_old("share", maShortTicks, maLongTicks, bcTicks, capFactor, brownianTs, 0, Multiplier.MA_SLOPE_DIFFERENCE);
        
        /*
         * Computing the 2 moving average series 
         */
        ma_1 = 0;
        ma_2 = 0;
        firstMAComputation = true;
        
        dtsValues.add(0, dalValues.get(0));
        
        for (int i = 1; i < lengthOfTs; i++) {
            dtsValues.add( dtsValues.get(i-1) + dalValues.get(i));   // Brownian motion  
            
            if (i < warmUpPeriod - 1) {
                ma_1 = 0;
                ma_2 = 0;
            }
            else {  // force a full MA calculation first time around, then do incremental calculations
                if (firstMAComputation) {
                    ma_1 = trend.fullMA(dtsValues, maShortTicks);
                    ma_2 = trend.fullMA(dtsValues, maLongTicks);
                    firstMAComputation = false;
                } else {
                    ma_1 = trend.incrementalMA(dtsValues, maShortTicks, ma_1);
                    ma_2 = trend.incrementalMA(dtsValues, maLongTicks, ma_2);
                }
            }
            
            dtsMA_1.add(ma_1);
            dtsMA_2.add(ma_2);
        }
        
        /*
         * Computing the max/min series used in the exit condition 
         */
        max = 0;
        min = 0;
        dtsValues = new DoubleTimeSeries();
        dtsMA_max = new DoubleTimeSeries();
        dtsMA_min = new DoubleTimeSeries();
        
        dtsValues.add(0, dalValues.get(0));
        dtsMA_max.add(0, 0);
        dtsMA_min.add(0, 0);
                
        for (int i = 1; i < lengthOfTs; i++) {
            dtsValues.add(dtsValues.get(i-1) + dalValues.get(i));
            
            if (i<bcTicks){
            	max = 0;
            	min = 0;
            }
            else {
            	max = trend.maxValue(dtsValues, bcTicks);
                min = trend.minValue(dtsValues, bcTicks);
            }
                        
            dtsMA_max.add(max);
            dtsMA_min.add(min);
        }
        
        /*
         * Running the trading simulation with the trend strategy 
         */
        tick = WorldClock.currentTick();
        
    	brownianTs.add(0, dalValues.get(tick));
        trend.trade();
        tick = WorldClock.incrementTick();
        
        for (int i = 1; i < lengthOfTs; i++) {
        	
        	if (i==316) {
        		logger.trace("hola");        		
        	}
        	
        	brownianTs.add(tick, brownianTs.get(tick-1) + dalValues.get(tick));
        	trend.trade();        	
            tick = WorldClock.incrementTick();
        }
        
        
        
        /*
         * Printing and graphing the results
         */
        logger.debug("Positions: {}", VersatileTimeSeries.printValues(trend.getTsPos()));
        
        charts.draw(new VersatileTimeSeries("Brownian Values", brownianTs), new VersatileTimeSeries("MA_1", dtsMA_1), 
                new VersatileTimeSeries("MA_2", dtsMA_2),  
                new VersatileTimeSeries("Positions for brownian motion", trend.getTsPos()));
        
        charts.draw(new VersatileTimeSeries("Brownian values", brownianTs), new VersatileTimeSeries("max", dtsMA_max), 
                new VersatileTimeSeries("min", dtsMA_min),  
                new VersatileTimeSeries("Positions for brownian motion", trend.getTsPos()));

                

        /**
         * ######################################################################################
         * 
         * Test: trade() method for sinus prices
         * 
         * Computes a sinus wave which is used as the input price process
         * for the method trade() to compute entry and exit signals and calculate
         * the positions. 
         * 
         * ######################################################################################
         */
        
        logger.trace("Testing the trade() method for a sinus time series");
        
        WorldClock.reset();
        
        /*
         * Setting up the sinus generator and generating values
         */
        shift = 100;
        amplitude = 40;
        lag = 0;
        lambda = 100;
        
        sinusGen = new SinusDataGenerator(shift, amplitude, lag, lambda);
        dalValues = sinusGen.nextDoubles(lengthOfTs);

        /*
         * Setting up the trend strategy
         */
        maShortTicks = 10;
        maLongTicks = 40;
        bcTicks = 10;
        capFactor = 100;
        
        DoubleTimeSeries sinusTs = new DoubleTimeSeries();
        
        /*
         * Setting up the moving average calculations
         */
        
        warmUpPeriod = Math.max(maShortTicks, maLongTicks);        
        
        dtsValues = new DoubleTimeSeries();
        dtsMA_1 = new DoubleTimeSeries();
        dtsMA_2 = new DoubleTimeSeries();
        
        /*
         * Setting up the trend strategy
         */
        trend = new TrendMABCStrategy_old("share", maShortTicks, maLongTicks, bcTicks, capFactor, sinusTs, 0, Multiplier.MA_SLOPE_DIFFERENCE);

        /*
         * Computing the 2 moving average series 
         */
        ma_1 = 0;
        ma_2 = 0;
        firstMAComputation = true;
        
        for (int i = 0; i < lengthOfTs; i++) {
            dtsValues.add(dalValues.get(i));
            
            if (i < warmUpPeriod - 1) {
                ma_1 = 0;
                ma_2 = 0;
            }
            else {  // force a full MA calculation first time around, then do incremental calculations
                if (firstMAComputation) {
                    ma_1 = trend.fullMA(dtsValues, maShortTicks);
                    ma_2 = trend.fullMA(dtsValues, maLongTicks);
                    firstMAComputation = false;
                } else {
                    ma_1 = trend.incrementalMA(dtsValues, maShortTicks, ma_1);
                    ma_2 = trend.incrementalMA(dtsValues, maLongTicks, ma_2);
                }
            }
            
            dtsMA_1.add(ma_1);
            dtsMA_2.add(ma_2);
        }
        
        /*
         * Computing the max/min series used in the exit condition 
         */
        max = 0;
        min = 0;
        dtsValues = new DoubleTimeSeries();
        dtsMA_max = new DoubleTimeSeries();
        dtsMA_min = new DoubleTimeSeries();
                
        for (int i = 0; i < lengthOfTs; i++) {
            dtsValues.add(dalValues.get(i));
            
            if (i<bcTicks){
            	max = 0;
            	min = 0;
            }
            else {
            	max = trend.maxValue(dtsValues, bcTicks);
                min = trend.minValue(dtsValues, bcTicks);
            }
                        
            dtsMA_max.add(max);
            dtsMA_min.add(min);
        }
        
        /*
         * Running the trading simulation with the trend strategy 
         */
        tick = WorldClock.currentTick();
        
        for (int i = 0; i < lengthOfTs; i++) {
        	sinusTs.add(tick, dalValues.get(tick));
        	trend.trade();
            tick = WorldClock.incrementTick();
        }
        
        /*
         * Printing and graphing the results
         */
        logger.debug("Positions: {}", VersatileTimeSeries.printValues(trend.getTsPos()));
        
        /*        
        charts.draw(new VersatileTimeSeries("Sinus Values", dtsValues), new VersatileTimeSeries("MA_1", dtsMA_1), 
                new VersatileTimeSeries("MA_2", dtsMA_2),  
                new VersatileTimeSeries("Positions for Sinus", trend.getTsPos()));
        
        charts.draw(new VersatileTimeSeries("Sinus Values", dtsValues), new VersatileTimeSeries("max", dtsMA_max), 
                new VersatileTimeSeries("min", dtsMA_min),  
                new VersatileTimeSeries("Positions for Sinus", trend.getTsPos()));
        */
        
//        charts.draw(new VersatileTimeSeries("Positions for Sinus", trend.getTsPos()));

        
        /**
         *      OUTPUT
         */
        
        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
    }

}
