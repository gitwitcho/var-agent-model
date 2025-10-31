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

import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.HashMap;

import info.financialecology.finance.abm.model.TrendValueAbmSimulator;
import info.financialecology.finance.abm.model.agent.Trader;
import info.financialecology.finance.abm.model.strategy.TradingStrategy;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.MultiplierTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.OrderOrPositionStrategyTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.PositionUpdateTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.ShortSellingTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.VariabilityCapFactorTrend;
import info.financialecology.finance.utilities.CmdLineProcessor;
import info.financialecology.finance.utilities.datagen.OverlayDataGenerator;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool;
import info.financialecology.finance.utilities.datagen.OverlayDataGenerator.GeneratorType;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool.DistributionType;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.datastruct.VersatileChart;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeries;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeriesCollection;
import info.financialecology.finance.utilities.statistics.StatsTimeSeries;
import cern.colt.Timer;
import ch.qos.logback.classic.Logger;

import org.slf4j.LoggerFactory;

/**
 * ######################################################################################
 * 
 * ABM simulation with trend traders 
 * 
 * Version 1.1 of the simulation code. If this is the latest version, use to 
 * adapt other simulation codes.
 * 
 * @author Gilbert Peffer
 *
 * ######################################################################################
 * 
 */
public class TrendSingleAssetAbmSimulation {

    protected static final String TEST_ID = "TrendSingleAssetAbmSimulation"; 
    
    /**
     * @param args
     * @throws FileNotFoundException 
     */
    public static void main(String[] args) throws FileNotFoundException {
        Timer timerAll  = new Timer();  // a timer to calculate total execution time (cern.colt)
        Timer timer     = new Timer();  // a timer to calculate execution times of particular methods (cern.colt)
        timerAll.start();

        /*
         * Enable logging. Root level settings affect logger behavior in all methods.
         * 
         *  To enable trace, use the command line option -v.
         *  
         */
        Logger root = (Logger)LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        root.setLevel(ch.qos.logback.classic.Level.TRACE);
        Logger logger = (Logger)LoggerFactory.getLogger("main");
        
        System.out.println("\nTEST: " + TEST_ID);
        System.out.println("===================================\n");

        logger.trace("Setting up test for class '{}'\n", TEST_ID);
        
        /**
         *      SET-UP
         *      
         *      - Read parameter file
         *      - Assign parameter values
         */
        logger.trace("Reading parameters from file");
        

        /*
         * Read parameters from file
         * 
         * To write a new parameter file template, uncomment the following two lines
         *      TrendAbmParams.writeParamDefinition("param_template.xml");
         *      System.exit(0);
         * 
         */
        
        TrendAbmParams params = TrendAbmParams.readParameters(CmdLineProcessor.process(args));

        /*
         * Assign parameter values
         */

        int numTicks = params.nTicks;   // number of ticks per simulation run
        int numRuns = params.nRuns;     // number of runs per simulation experiment
        int startSeed = params.seed;    // starting position in the random seed table; -1 for random value (based on internal clock) 
        
        int numTrends = params.numTrends;    // number of TREND investors
        
        // Parameters for the exogenous price process. The process is an overlay of a Brownian process and a sinus function            
        double mu = params.getValidatedDoubleSequence(TrendAbmParams.Sequence.MU).get(0);
        double sigma = params.getValidatedDoubleSequence(TrendAbmParams.Sequence.SIGMA).get(0);
        double price_0 = params.getValidatedDoubleSequence(TrendAbmParams.Sequence.PRICE_0).get(0);
        double liquidity = params.getValidatedDoubleSequence(TrendAbmParams.Sequence.LIQUIDITY).get(0);
        
        double sigmaMin = sigma;    // TODO Only for experiments
        double sigmaMax = sigma;
        
        double shift = params.getValidatedDoubleSequence(TrendAbmParams.Sequence.SHIFT).get(0);
        double amplitude = params.getValidatedDoubleSequence(TrendAbmParams.Sequence.AMPLITUDE).get(0);
        double lag = params.getValidatedDoubleSequence(TrendAbmParams.Sequence.LAG).get(0);
        double lambda = params.getValidatedDoubleSequence(TrendAbmParams.Sequence.LAMBDA).get(0);
                
        TrendValueAbmSimulator simulator;
        
        VersatileChart charts_1 = new VersatileChart();
        charts_1.getInternalParms().autoRange = true;
        charts_1.getInternalParms().autoRangePadding = 0;
        charts_1.getInternalParms().ticks = true;

        VersatileChart charts_2 = new VersatileChart();
        charts_2.getInternalParms().autoRange = true;
        charts_2.getInternalParms().autoRangePadding = 0;
        charts_2.getInternalParms().ticks = true;
        
        VersatileChart charts_3 = new VersatileChart();
        charts_3.getInternalParms().autoRange = true;
        charts_3.getInternalParms().autoRangePadding = 0;
        charts_3.getInternalParms().ticks = true;
        
        VersatileChart charts = new VersatileChart();
        charts.getInternalParms().autoRange = true;
        charts.getInternalParms().autoRangePadding = 0;
        charts.getInternalParms().ticks = true;
        VersatileTimeSeriesCollection atcWealth = new VersatileTimeSeriesCollection("Wealth for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcPos = new VersatileTimeSeriesCollection("Positions for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcPrice = new VersatileTimeSeriesCollection("Prices for sigma [" + sigmaMin + "," + sigmaMax + "]");
        
//        double meanPrice = 0;
//        double stdDevPrice = 0;

        
        /**
         *      SIMULATION EXPERIMENT
         *      =====================     
         */
        
        for (int run = 0; run < numRuns; run++) {
                        
            /*
             * Setting up the simulator
             */
        	simulator = new TrendValueAbmSimulator();      // recreating the simulator will also get rid of the old schedule
            simulator.resetWorldClock();
            simulator.addShares("IBM");
            simulator.getMarketMaker().setInitPrice("IBM", price_0);
            simulator.getMarket().setInitLogReturn("IBM", 0);
            simulator.getMarket().setInitValue("IBM", price_0);
            simulator.getMarket().setLiquidity("IBM", liquidity);
            simulator.createTrendFollowers(numTrends);
            
            
            /*
             * Setting the changing parameter values
             */
            
            if (numRuns == 1)
                sigma = sigmaMin;
            else
                sigma = sigmaMin + run * (sigmaMax - sigmaMin) / (numRuns - 1);
    
            /*
             * Setting up the data generators
             */
            
            if (startSeed < 0)
                RandomGeneratorPool.configureGeneratorPool();
            else
                RandomGeneratorPool.configureGeneratorPool(startSeed);

            OverlayDataGenerator prices = new OverlayDataGenerator(
                    "Price", GeneratorType.SINUS, GeneratorType.ARITHMETIC_BROWNIAN_PROCESS, 
                    price_0, amplitude, lag, lambda, mu, sigma);

//            OverlayDataGenerator prices = new OverlayDataGenerator("Price", "sinus", DistributionType.ARITHMETIC_BROWNIAN_PROCESS, price_0, shift, amplitude, lag, lambda, mu, sigma);            
            
            /*
             * Setting up the trend strategy and adding it to the trend traders
             */
            
            simulator.setExogeneousPriceProcess("IBM", prices);            
//            simulator.addTrendStrategyForAllTraders("IBM", params.maShortTicks, params.maLongTicks, params.bcTicks, params.capFactor, params.volWindow, Multiplier.MA_SLOPE_DIFFERENCE_STDDEV);
            
            HashMap<String, Trader> trendFollowers = simulator.getTrendFollowers();
            
            int aux = 0;
            for (Trader trader : trendFollowers.values()) {
//                int trendID = numTrends * run + aux;  
                int trendID = aux;  
//            	simulator.addTrendStrategyForOneTrader("IBM", "Trend_" + trendID, params.maShortTicks, params.maLongTicks, params.bcTicks, params.capFactor, params.volWindow, Multiplier.MA_SLOPE_DIFFERENCE_STDDEV, params.normPeriod);   // DEPRECATED - normPeriod is no longer used
            	simulator.addTrendStrategyForOneTrendFollower("IBM", "Trend_" + trendID, params.maShortTicks, params.maLongTicks, params.bcTicks, params.capFactor, params.volWindow, MultiplierTrend.MA_SLOPE_DIFFERENCE_STDDEV, PositionUpdateTrend.CONSTANT, OrderOrPositionStrategyTrend.POSITION, VariabilityCapFactorTrend.CONSTANT, ShortSellingTrend.ALLOWED);
                aux ++;
            }
            
              
            
//            simulator.addTrendStrategyForOneTrader("IBM", "Trend_1", params.maShortTicks, params.maLongTicks, params.bcTicks, 100, params.volWindow, Multiplier.MA_SLOPE_DIFFERENCE_STDDEV);
//            simulator.addTrendStrategyForOneTrader("IBM", "Trend_2", params.maShortTicks, params.maLongTicks, params.bcTicks, 200, params.volWindow, Multiplier.MA_SLOPE_DIFFERENCE_STDDEV);
//            simulator.addTrendStrategyForOneTrader("IBM", "Trend_3", params.maShortTicks, params.maLongTicks, params.bcTicks, 100, params.volWindow, Multiplier.MA_SLOPE_DIFFERENCE_STDDEV);
//            simulator.addTrendStrategyForOneTrader("IBM", "Trend_4", params.maShortTicks, params.maLongTicks, params.bcTicks, 100, params.volWindow, Multiplier.MA_SLOPE_DIFFERENCE_STDDEV);
//            simulator.addTrendStrategyForOneTrader("IBM", "Trend_5", params.maShortTicks, params.maLongTicks, params.bcTicks, 100, params.volWindow, Multiplier.MA_SLOPE_DIFFERENCE_STDDEV);
            
            /*
             * Running the trading simulation with the trend strategy 
             */
            simulator.setNumTicks(numTicks);
            simulator.run();
            
            /*
             * Printing and graphing the results
             */
           
            DoubleTimeSeriesList dtlPositions = new DoubleTimeSeriesList();
            DoubleTimeSeriesList dtlWealthIncrements = new DoubleTimeSeriesList();
                        
            for (int tr = 0; tr < numTrends; tr++) {
            	
            	int trendID = tr;
            	TrendMABCStrategy trend = (TrendMABCStrategy) simulator.getTrendFollowers().get("Trend_" + trendID).getStrategies().get("IBM");
            	
            	DoubleTimeSeries Position = trend.getTsPos();
            	DoubleTimeSeries WealthIncrement = StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), trend.getTsPos());
            	
            	dtlPositions.add(tr, Position);
            	dtlWealthIncrements.add(tr, WealthIncrement);
            	
            }
            
            for (int tr = 0; tr < numTrends; tr++) {
                logger.debug("Positions: {}", VersatileTimeSeries.printValues(dtlPositions.get(tr)));
            }
            
            for (int tr = 0; tr < numTrends; tr++) {
                atcWealth.populateSeries(run, "wealth_" + tr, dtlWealthIncrements.get(tr));
                atcPos.populateSeries(run, "pos_" + tr, dtlPositions.get(tr));                
            }
            
            atcPrice.populateSeries(run, "IBM", simulator.getPrices("IBM"));
            
            
//            meanPrice = meanPrice + simulator.getPrices("IBM").mean();
//            stdDevPrice = stdDevPrice + simulator.getPrices("IBM").stdev();
//            logger.debug("PRICES, run " + run + " - Mean: {}, StdDev: {}", simulator.getPrices("IBM").mean(), simulator.getPrices("IBM").stdev());
            
            

            
//            DoubleTimeSeries maShortTs = StatsTimeSeries.MA(simulator.getPrices("IBM"), params.maShortTicks);
//            DoubleTimeSeries maLongTs = StatsTimeSeries.MA(simulator.getPrices("IBM"), params.maLongTicks);
//            DoubleTimeSeries maxTs = StatsTimeSeries.maxValue(simulator.getPrices("IBM"), params.bcTicks);
//            DoubleTimeSeries minTs = StatsTimeSeries.minValue(simulator.getPrices("IBM"), params.bcTicks);
//            
//            DoubleTimeSeries WealthIncrement_1 = StatsTimeSeries.WealthIncrement(simulator.getPrices("IBM"), trend_1.getTsPos());
////            DoubleTimeSeries WealthIncrement_2 = StatsTimeSeries.WealthIncrement(simulator.getPrices("IBM"), trend_2.getTsPos());
//            
//            logger.debug("Prices: {}", VersatileTimeSeries.printValues(simulator.getPrices("IBM")));
//            logger.debug("MA_SHORT(Price): {}", VersatileTimeSeries.printValues(maShortTs));
//            logger.debug("MA_LONG(Price): {}", VersatileTimeSeries.printValues(maLongTs));
//            logger.debug("MAX(Price): {}", VersatileTimeSeries.printValues(maxTs));
//            logger.debug("MIN(Price): {}", VersatileTimeSeries.printValues(minTs));
//            logger.debug("Positions_1: {}", VersatileTimeSeries.printValues(trend_1.getTsPos()));
////            logger.debug("Positions_2: {}", VersatileTimeSeries.printValues(trend_2.getTsPos()));
//            logger.debug("WealthIncrement_1: {}", VersatileTimeSeries.printValues(WealthIncrement_1));
////            logger.debug("WealthIncrement_2: {}", VersatileTimeSeries.printValues(WealthIncrement_2));
//            
////            charts_1.draw(new VersatileTimeSeries("Prices", simulator.getPrices("IBM")),
////                    new VersatileTimeSeries("MA(" + params.maShortTicks + ")", maShortTs),
////                    new VersatileTimeSeries("MA(" + params.maLongTicks + ")", maLongTs),
////                    new VersatileTimeSeries("Positions_1", trend_1.getTsPos()),
////                    new VersatileTimeSeries("Positions_2", trend_2.getTsPos()));
////            
////            charts_2.draw(new VersatileTimeSeries("Prices", simulator.getPrices("IBM")),
////                    new VersatileTimeSeries("Max(" + params.bcTicks + ")", maxTs),
////                    new VersatileTimeSeries("Min(" + params.bcTicks + ")", minTs),
////                    new VersatileTimeSeries("Positions_1", trend_1.getTsPos()),
////                    new VersatileTimeSeries("Positions_2", trend_2.getTsPos()));
////            
////            charts_3.draw(new VersatileTimeSeries("WealthIncrement_1", WealthIncrement_1),
////                    new VersatileTimeSeries("WealthIncrement_2", WealthIncrement_2));
//            
//            atcWealth.populateSeries(run, WealthIncrement_1.getId(), WealthIncrement_1);
//            atcPos.populateSeries(run, "pos_1", trend_1.getTsPos());
//            atcPrice.populateSeries(run, "IBM", simulator.getPrices("IBM"));
            

        }
        
//        meanPrice = meanPrice/numRuns;
//        stdDevPrice = stdDevPrice/numRuns;        
//        logger.debug("PRICES - Average statistics - Mean: {}, StdDev: {}", meanPrice, stdDevPrice);
        
        charts.draw(atcWealth);
        charts.draw(atcPos);
        charts.draw(atcPrice);

                
        /**
         *      OUTPUT
         */
        
        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
    }

}
