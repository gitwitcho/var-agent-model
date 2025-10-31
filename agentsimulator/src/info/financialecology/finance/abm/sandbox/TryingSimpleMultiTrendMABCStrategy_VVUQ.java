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

import java.util.ArrayList;

import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy_old;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy_old.Multiplier;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.WorldClock;
import info.financialecology.finance.utilities.datagen.DataGenerator;
import info.financialecology.finance.utilities.datagen.RandomDistDataGenerator;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool;
import info.financialecology.finance.utilities.datagen.SinusDataGenerator;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool.DistributionType;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
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
 * Testing class for the SimpleMultiTrendMABCStrategy
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

public class TryingSimpleMultiTrendMABCStrategy_VVUQ {

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
         * ######################################################################################
         * 
         * Trying VVUQ: performance of different multipliers under Brownian motion plus sinus 
         * 
         *    - How does the performance of the strategy depend on the dominance of the 
         *      underlying sinus (which enforces trend behaviour)?
         *    - How does the performance of the strategy depend on price volatility?
         *    - How does the performance of the strategy depend on the fast MA window?
         *    - How does the performance of the strategy depend on the size of the exit channel?
         * 
         * ######################################################################################
         */
        
        logger.trace("Performance of the multi-trend strategy under changing price volatility"
                + " for three multiplier types: constant, slope, slope difference");
        
        /**
         *      SET-UP
         */
        logger.trace("Setting up test objects and parameters");
        
        int lengthOfTs = 600;
        int startSeed = -1;
        
        /*
         * TODO Change for multi-trend
         * 
         * Parameters for the normal random generators and the sinus generators, 
         * and generate arrays of Brownian motion and sinus values
         */
        double mu = 0;
        //BL double sigmaMin = 4;
        //BL double sigmaMax = 16;
        double sigmaMin = 0;
        double sigmaMax = 0;
        double sigma;
        
        int numAssets = 3;      // number of assets
        
        int runsPerExperiment = 1;
        
        VersatileChart charts = new VersatileChart();
        charts.getInternalParms().autoRange = true;
        charts.getInternalParms().autoRangePadding = 0;
        charts.getInternalParms().ticks = true;
        VersatileTimeSeriesCollection atcWealth = new VersatileTimeSeriesCollection("Wealth for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcPos = new VersatileTimeSeriesCollection("Positions for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcPrice = new VersatileTimeSeriesCollection("Prices for sigma [" + sigmaMin + "," + sigmaMax + "]");

        /**
         *      SIMULATION EXPERIMENT
         *      =====================     
         */
        
        for (int run = 0; run < runsPerExperiment; run++) {
            
            WorldClock.reset();
            
            int tick = WorldClock.currentTick();
            
            // TODO We need to be careful because sometimes we use '0' as the start index and sometimes tick

            if (runsPerExperiment == 1)
                sigma = sigmaMin;
            else
                sigma = sigmaMin + run * (sigmaMax - sigmaMin) / (runsPerExperiment - 1);
    
            if (startSeed == -1)
                RandomGeneratorPool.configureGeneratorPool();
            else
                RandomGeneratorPool.configureGeneratorPool(startSeed);

            /*
             * Setting up the data generators
             */
            ArrayList<DoubleArrayList> alDalBrownianPlusSinusValues = new ArrayList<DoubleArrayList>();
            
            /*
            double shift = 100;     // TODO Vary these or the strategy parameters below over the different assets
            double amplitude = 20;
            double lag = 0;
            double lambda = 100;
            */
            
            double[ ] shifts = { 100, 100, 100 };   // Parameters for the sinus processes. Number of components must be equal to numAssets
            double[ ] amplitudes = { 20, 30, 10 };
            double[ ] lags = { 0, 0.2, 0.75 };
            double[ ] lambdas = { 200, 100, 100 };
            
            if (shifts.length != numAssets || amplitudes.length != numAssets || lags.length != numAssets ||
            		lambdas.length != numAssets){
            	logger.error("The number of shifts, amplitudes, lags and lambdas for the sinus process " +
        				"must be equal to " + numAssets);
            }            
           
            for (int a = 0; a < numAssets; a++) {
                RandomDistDataGenerator randGen = new RandomDistDataGenerator("gen_" + a, DistributionType.NORMAL, mu, sigma);                
                SinusDataGenerator sinusGen = new SinusDataGenerator(shifts[a], amplitudes[a], lags[a], lambdas[a]);
                
                DoubleArrayList dalBrownianPlusSinusValues = new DoubleArrayList();
                double brownianValue = 0;
                
                for (int i = 0; i < lengthOfTs; i++) {
                    brownianValue += randGen.nextDouble();
                    dalBrownianPlusSinusValues.add(brownianValue + sinusGen.nextDouble());
                }
                
                alDalBrownianPlusSinusValues.add(a, dalBrownianPlusSinusValues);
            }
                        
            /*
             * Setting up the multi-trend strategy
             */
            int maShortTicks = 10;
            int maLongTicks = 40;
            int bcTicks = 10;
            double capFactor = 100;
            int volWindow = 25;
            
            DoubleTimeSeriesList dtlBrownianPlusSinus = new DoubleTimeSeriesList();
            DoubleTimeSeriesList dtlWealth = new DoubleTimeSeriesList();
            ArrayList<TrendMABCStrategy_old> trends = new ArrayList<TrendMABCStrategy_old>();
            
            for (int a = 0; a < numAssets; a++) {
                DoubleTimeSeries dtBrownianPlusSinus = new DoubleTimeSeries("price_" + a);
                dtlBrownianPlusSinus.add(a, dtBrownianPlusSinus);
                
                TrendMABCStrategy_old trend = new TrendMABCStrategy_old("share_" + a, maShortTicks, maLongTicks, bcTicks, capFactor, dtBrownianPlusSinus, volWindow, Multiplier.MA_SLOPE_DIFFERENCE_STDDEV);
                trends.add(a, trend);

                DoubleTimeSeries wealth = new DoubleTimeSeries("wealth_" + a);
                dtlWealth.add(a, wealth);
            }
                                
            /*
             * Running the trading simulation with the trend strategies for all assets 
             */
            
            
            // Initialise at first tick
            for (int a = 0; a < numAssets; a++) {
                dtlBrownianPlusSinus.get(a).add(tick, alDalBrownianPlusSinusValues.get(a).get(tick));  // price at t = 0
                dtlWealth.get(a).add(tick, 0);

                trends.get(a).trade();    // position at t = 0
            }        	
            
            tick = WorldClock.incrementTick();
            
            for (int i = 1; i < lengthOfTs; i++) {
                
                for (int a = 0; a < numAssets; a++) {
                	
                	dtlBrownianPlusSinus.get(a).add(tick, alDalBrownianPlusSinusValues.get(a).get(tick));    // price at t = i
                	trends.get(a).trade();  // position at t = i 
                    
                    double deltaWealth = trends.get(a).getTsPos().get(tick) * (dtlBrownianPlusSinus.get(a).get(tick) - dtlBrownianPlusSinus.get(a).get(tick - 1));
                    dtlWealth.get(a).add(tick, dtlWealth.get(a).get(tick - 1) + deltaWealth);
                }

                tick = WorldClock.incrementTick();
            }
            
            /*
             * Printing and graphing the results
             */
            
            for (int a = 0; a < numAssets; a++) {   // TODO this function should move outside of the experiment loop and use the VersatileTimeSeriesCollection print function
                logger.debug("Positions: {}", VersatileTimeSeries.printValues(trends.get(a).getTsPos()));
            }
            
            for (int a = 0; a < numAssets; a++) {
                atcWealth.populateSeries(run, dtlWealth.get(a).getId(), dtlWealth.get(a));
                atcPos.populateSeries(run, "pos_" + a, trends.get(a).getTsPos());
                atcPrice.populateSeries(run, dtlBrownianPlusSinus.get(a).getId(), dtlBrownianPlusSinus.get(a));
            }
            
          
            

            
                        
//            charts.draw(new VersatileTimeSeries("Brownian + Sinus (r = " + run + ")", brownianPlusSinusTs),  
//                    new VersatileTimeSeries("Positions (r = " + run + ")", trend.getTsPos()));
//            charts.draw(new VersatileTimeSeries("Wealth (r = " + run + ")", wealth));
        }
        
        charts.draw(atcWealth);
        charts.draw(atcPos);
        charts.draw(atcPrice);

                
        /**
         *      OUTPUT
         */
        
        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
    }

}
