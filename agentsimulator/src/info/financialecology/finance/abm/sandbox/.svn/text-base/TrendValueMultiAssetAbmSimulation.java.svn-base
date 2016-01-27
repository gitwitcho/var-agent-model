/*
 * Copyright (c) 2011-2014 Gilbert Peffer, Bàrbara Llacay
 * 
 * The source code and software releases are available at http://code.google.com/p/systemic-risk/
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package info.financialecology.finance.abm.sandbox;

import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.HashMap;

import info.financialecology.finance.abm.model.TrendValueAbmSimulator;
import info.financialecology.finance.abm.model.agent.Trader;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.MultiplierTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.PositionUpdateTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.OrderOrPositionStrategyTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.ShortSellingTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.VariabilityCapFactorTrend;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.PositionUpdateValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.OrderOrPositionStrategyValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.VariabilityCapFactorValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.ShortSellingValue;
import info.financialecology.finance.abm.sandbox.TrendValueAbmParams;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.CmdLineProcessor;
import info.financialecology.finance.utilities.datagen.OverlayDataGenerator;
import info.financialecology.finance.utilities.datagen.RandomDistDataGenerator;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool;
import info.financialecology.finance.utilities.datagen.OverlayDataGenerator.GeneratorType;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool.DistributionType;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.datastruct.VersatileChart;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeries;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeriesCollection;
import info.financialecology.finance.utilities.output.ResultWriterFactory;
import info.financialecology.finance.utilities.statistics.StatsTimeSeries;
import cern.colt.Timer;
import cern.colt.list.DoubleArrayList;
import ch.qos.logback.classic.Logger;

import org.slf4j.LoggerFactory;

/**
 * An agent-based simulation with trend followers and value investors
 * 
 * Version 1.1 - if this is the latest version, use to adapt the other simulation codes.
 * 
 * @author Gilbert Peffer, Bàrbara Llacay
 */
public class TrendValueMultiAssetAbmSimulation {

    protected static final String TEST_ID = "TrendValueMultiAssetAbmSimulation"; 
    
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
         * To enable verbose output (via logger.trace(...)), use the command line option -v.
         *  
         */
        Logger root = (Logger)LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        root.setLevel(ch.qos.logback.classic.Level.TRACE);
        Logger logger = (Logger)LoggerFactory.getLogger("main");
        
        System.out.println("\nTEST: " + TEST_ID);
        System.out.println("===================================\n");

        logger.trace("Setting up test for class '{}'\n", TEST_ID);
        
        /** *********************************************************
         * 
         *      SET-UP
         *      
         *      - Read parameter file
         *      - Assign parameter values
         *
         ********************************************************** */
        logger.trace("Reading parameters from file");
        
        TrendValueAbmParams params = TrendValueAbmParams.readParameters(CmdLineProcessor.process(args));

        /*
         *      PARAMETERS
         */

        int numTicks        = params.nTicks;    // number of ticks per simulation run
        int numRuns         = params.nRuns;     // number of runs per simulation experiment
        int startSeed       = params.seed;      // starting position in the random seed table; -1 for random value (based on internal clock) 
        
        int numTrends       = params.numTrends;    // number of TREND investors
        int numFunds        = params.numFunds;     // number of FUND investors
        
        DoubleArrayList price_0      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.PRICE_0);
        DoubleArrayList liquidity    = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LIQUIDITY);

        //  Parameters for the exogenous price process. The process is an overlay of a Brownian process and a sinus function
        
//        DoubleArrayList shift_price      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SHIFT_PRICE);
        DoubleArrayList amplitude_price  = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.AMPLITUDE_PRICE);
        DoubleArrayList lag_price        = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAG_PRICE);
        DoubleArrayList lambda_price     = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAMBDA_PRICE);
        
        DoubleArrayList mu_price         = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.MU_PRICE);
        DoubleArrayList sigma_price      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SIGMA_PRICE);
                
        // Parameters for the exogenous market-wide fundamental value process. The process is an overlay of a Brownian process and a sinus function
        
//        DoubleArrayList shift_value      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SHIFT_VALUE);
        DoubleArrayList amplitude_value  = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.AMPLITUDE_VALUE);
        DoubleArrayList lag_value        = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAG_VALUE);
        DoubleArrayList lambda_value     = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAMBDA_VALUE);        
        
        DoubleArrayList mu_value         = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.MU_VALUE);
        DoubleArrayList sigma_value      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SIGMA_VALUE);
        
        // TODO Change the [min, max] values for thresholds and other parameters to INTERVAL form 
        
        // Set number of assets and validate the remaining parameter array lengths 
        // TODO Create a separate parameter file with numAssets as one of the parameters, and validate directly there
        int numAssets = price_0.size();
        
        boolean control = ((liquidity.size() == numAssets) && 
                (amplitude_price.size() == numAssets) && (amplitude_value.size() == numAssets) &&
                (lag_price.size() == numAssets) && (lag_value.size() == numAssets) &&
                (lambda_price.size() == numAssets) && (lambda_value.size() == numAssets) &&
                (mu_price.size() == numAssets) && (mu_value.size() == numAssets) &&
                (sigma_price.size() == numAssets) && (sigma_value.size() == numAssets));
        
        Assertion.assertOrKill(control == true, "Wrong number of parameters for " + numAssets + " assets");

        // ---------------------------------------------------------------------------------------------------------------
        
        int numExp = 1;   // TODO - Delete when this is automatically extracted from the sequences in the param file
        
        DoubleArrayList sigmaMin = sigma_price;    // TODO Only for experiments
        DoubleArrayList sigmaMax = sigma_price;
                
        TrendValueAbmSimulator simulator;

        
        /*
         *      OUTPUT VARIABLES
         */
        
        // Variables for charts
        
        VersatileChart charts = new VersatileChart();
        charts.getInternalParms().autoRange = true;
        charts.getInternalParms().autoRangePadding = 0;
        charts.getInternalParms().ticks = true;
        
        // Time series
        
        VersatileTimeSeriesCollection atcWealthTrend    = new VersatileTimeSeriesCollection("TREND Wealth for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcPosTrend       = new VersatileTimeSeriesCollection("TREND Positions for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcWealthFund     = new VersatileTimeSeriesCollection("FUND Wealth for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcPosFund        = new VersatileTimeSeriesCollection("FUND Positions for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcVolumeFund     = new VersatileTimeSeriesCollection("FUND Volume");
        VersatileTimeSeriesCollection atcVolumeTrend    = new VersatileTimeSeriesCollection("TREND Volume");
        VersatileTimeSeriesCollection atcValuePriceDiff = new VersatileTimeSeriesCollection("Value-Price Difference"); 
        VersatileTimeSeriesCollection atcValuePriceDiff_F1 = new VersatileTimeSeriesCollection("Value-Price Difference of FUND_1");
        
        // Time series
        
        VersatileTimeSeriesCollection atcPrices          = new VersatileTimeSeriesCollection("Prices for shares");
        VersatileTimeSeriesCollection atcValues          = new VersatileTimeSeriesCollection("Fundamental Values");
        
        
        // Variables for extracting data to R - TODO: Delete when VersatileTimeSeriesCollection works well in CsvResultWriter
        
        DoubleTimeSeriesList tsPricesList            = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsFundValuesList        = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsTotalVolumeList       = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsFundVolumeList        = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsTrendVolumeList       = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsFundTotalOrdersList   = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsTrendTotalOrdersList  = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsTrendAvgWealthIncrementList  = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsFundAvgWealthIncrementList   = new DoubleTimeSeriesList();

        
        /** ************************************************************
         * 
         *      SIMULATION EXPERIMENTS
         *           
         *************************************************************** */
        
        for (int e = 0; e < numExp; e++) {
        	
        	System.out.print("EXPERIMENT:" + e + "\n");
        	
            /*
             * Setting the changing parameter values
             */            
        	
        	// TODO Change so it works with multiple assets
//            if (numExp == 1)
//                sigma_price = sigmaMin;
//            else
//                sigma_price = sigmaMin + e * (sigmaMax - sigmaMin) / (numExp - 1);

        
	        for (int run = 0; run < numRuns; run++) {
	        	
	        	System.out.print("RUN:" + run + "\n");
	                        
	            /*
	             * Setting up the simulator
	             */
	        	ArrayList<String> shareIds = new ArrayList<String>();
                shareIds.add("IBM");                
                if (numAssets > 1) shareIds.add("MSFT");
                if (numAssets > 2) shareIds.add("GOOG");
                
                
                Assertion.assertOrKill(shareIds.size() == numAssets, numAssets + " share identifiers have to be defined, but only " + shareIds + " are in the list");
	        	
	        	simulator = new TrendValueAbmSimulator();      // recreating the simulator will also get rid of the old schedule
//	            simulator.resetWorldClock(); MOVED TO THE SIMULATOR
                
                for (int i = 0; i < numAssets; i++) {
                    simulator.addShares(shareIds.get(i));
                    simulator.getMarketMaker().setInitPrice(shareIds.get(i), price_0.get(i));    // TODO Move the share identifiers to the parameter file
                    simulator.getMarket().setInitLogReturn(shareIds.get(i), 0);
                    simulator.getMarket().setInitValue(shareIds.get(i), price_0.get(i));
                    simulator.getMarket().setLiquidity(shareIds.get(i), liquidity.get(i));
                }
                                
                for (int i = 1; i < numAssets; i++) {
                	simulator.addSpreads(shareIds.get(0) + "_" + shareIds.get(i));
                    simulator.getMarketMaker().setInitSpread(shareIds.get(0), price_0.get(0), shareIds.get(i), price_0.get(i)); 
                }
	            simulator.createTrendFollowers(numTrends);
	            simulator.createValueInvestors(numFunds);

	            
	            /*
	             * Setting up the data generators
	             */
	            
	            if (startSeed < 0)
	                RandomGeneratorPool.configureGeneratorPool();
	            else
	                RandomGeneratorPool.configureGeneratorPool(startSeed + run);  //TEST "+run"
	
	            for (int i = 0; i < numAssets; i++) {
	            
    	            OverlayDataGenerator prices = new OverlayDataGenerator(
    	                    "Price_" + shareIds.get(i), GeneratorType.SINUS, GeneratorType.ARITHMETIC_BROWNIAN_PROCESS, 
    	                    price_0.get(i), amplitude_price.get(i), lag_price.get(i), lambda_price.get(i), mu_price.get(i), sigma_price.get(i));
    	
    	            OverlayDataGenerator fundValues = new OverlayDataGenerator(
    	                    "FundValue_" + shareIds.get(i), GeneratorType.SINUS, GeneratorType.ARITHMETIC_BROWNIAN_PROCESS, 
    	                    price_0.get(i), amplitude_value.get(i), lag_value.get(i), lambda_value.get(i), mu_value.get(i), sigma_value.get(i));
    	
                    simulator.setExogeneousPriceProcess(shareIds.get(i), prices);
                    simulator.setFundamentalValueProcess(shareIds.get(i), fundValues);
	            }


	            
	            /* ************************************************************
	             *
	             *     Set up the trend strategies. 
	             * 
	             *     The moving average ranges and exit channel are randomised.
	             * 
	             **************************************************************/
            
	            HashMap<String, Trader> trendFollowers = simulator.getTrendFollowers();
	            
	            // Random generators for parameters of long and short MA, and exit channel window sizes
	            // Separate generators for the different assets, to allow replication of individual asset prices when number of assets changes
                HashMap<String, RandomDistDataGenerator> maShortTicks = new HashMap<String, RandomDistDataGenerator>();
                HashMap<String, RandomDistDataGenerator> maLongTicks  = new HashMap<String, RandomDistDataGenerator>();
                HashMap<String, RandomDistDataGenerator> bcTicksTrend = new HashMap<String, RandomDistDataGenerator>();
	            
	            for (String secId : shareIds) {
	                RandomDistDataGenerator distMaShortTicks = new RandomDistDataGenerator("MA_Short_" + secId, DistributionType.UNIFORM, (double) params.maShortTicksMin, (double) params.maShortTicksMax);	                
	                RandomDistDataGenerator distMaLongTicks  = new RandomDistDataGenerator("MA_Long_" + secId, DistributionType.UNIFORM, (double) params.maLongTicksMin, (double) params.maLongTicksMax);
	                RandomDistDataGenerator distBcTicksTrend = new RandomDistDataGenerator("BC_Ticks_Trend_" + secId, DistributionType.UNIFORM, (double) params.bcTicksTrendMin, (double) params.bcTicksTrendMax);

                    maShortTicks.put(secId, distMaShortTicks);
                    maLongTicks.put(secId, distMaLongTicks);
                    bcTicksTrend.put(secId, distBcTicksTrend);
	            }
	            
	            // Additional parameters - these are identical for all assets
	            MultiplierTrend trendMultiplier = MultiplierTrend.MA_SLOPE_DIFFERENCE_STDDEV;        // Method to calculate the size of the trend positions
	            PositionUpdateTrend positionUpdateTrend = PositionUpdateTrend.VARIABLE;    // Specifies if a position can be modified while open
	            OrderOrPositionStrategyTrend orderOrPositionStrategyTrend = OrderOrPositionStrategyTrend.POSITION;     // Specifies if the strategy is order-based or position-based
	            VariabilityCapFactorTrend variabilityCapFactorTrend = VariabilityCapFactorTrend.CONSTANT;              // Specifies if the capFactor is constant or varies based on the agent performance
	            ShortSellingTrend shortSellingTrend = ShortSellingTrend.ALLOWED;     // Specifies if short-selling is allowed
	            
	            
	            for (int i = 0; i < trendFollowers.size(); i++) {
	                
	                for (String secId : shareIds) {
    	            	simulator.addTrendStrategyForOneTrendFollower(secId, "Trend_" + i, (int) Math.round(maShortTicks.get(secId).nextDouble()), 
    	            			(int) Math.round(maLongTicks.get(secId).nextDouble()), (int) Math.round(bcTicksTrend.get(secId).nextDouble()), params.capFactorTrend, 
    	            			params.volWindowTrend, trendMultiplier, positionUpdateTrend, orderOrPositionStrategyTrend, 
    	            			variabilityCapFactorTrend, shortSellingTrend);
	                }
	            }
	    
	            
	            /* ***************************************
	             * 
	             *      Set up the value strategies
	             * 
	             *****************************************/
	                        
                HashMap<String, Trader> valueTraders = simulator.getValueInvestors();
	            
	            // Random generators for parameters of long and short MA, and exit channel window sizes
                // Separate generators for the different assets, to allow replication of individual asset prices when number of assets changes
                HashMap<String, RandomDistDataGenerator> entryThreshold = new HashMap<String, RandomDistDataGenerator>();
                HashMap<String, RandomDistDataGenerator> exitThreshold = new HashMap<String, RandomDistDataGenerator>();
                HashMap<String, RandomDistDataGenerator> valueOffset = new HashMap<String, RandomDistDataGenerator>();
                HashMap<String, RandomDistDataGenerator> bcTicksFund = new HashMap<String, RandomDistDataGenerator>();
                
                for (String secId : shareIds) {
                    RandomDistDataGenerator distEntryThreshold = new RandomDistDataGenerator("Entry_" + secId, DistributionType.UNIFORM, params.entryThresholdMin, params.entryThresholdMax);
                    RandomDistDataGenerator distExitThreshold = new RandomDistDataGenerator("Exit_" + secId, DistributionType.UNIFORM, params.exitThresholdMin, params.exitThresholdMax);
                    RandomDistDataGenerator distValueOffset = new RandomDistDataGenerator("Offset_" + secId, DistributionType.UNIFORM, -params.valueOffset, params.valueOffset);
                    RandomDistDataGenerator distBcTicksFund = new RandomDistDataGenerator("BC_Ticks_Fund_" + secId, DistributionType.UNIFORM, (double) params.bcTicksFundMin, (double) params.bcTicksFundMax);

                    entryThreshold.put(secId, distEntryThreshold);
                    exitThreshold.put(secId, distExitThreshold);
                    valueOffset.put(secId, distValueOffset);
                    bcTicksFund.put(secId, distBcTicksFund);
                }
                	            
                // Additional parameters - these are identical for all assets
	            PositionUpdateValue positionUpdateValue = PositionUpdateValue.VARIABLE;     // Specifies if a position can be modified while open
	            OrderOrPositionStrategyValue orderOrPositionStrategyValue = OrderOrPositionStrategyValue.POSITION;     // Specifies if the strategy is order-based or position-based
	            VariabilityCapFactorValue variabilityCapFactorValue = VariabilityCapFactorValue.CONSTANT;              // Specifies if the capFactor is constant or varies based on the agent performance
	            ShortSellingValue shortSellingValue = ShortSellingValue.ALLOWED;     // Specifies if short-selling is allowed
	            
	            
	            for (int i = 0; i < valueTraders.size(); i++) {
	                
	                for (String secId : shareIds) {	            
    	            	simulator.addValueStrategyForOneValueInvestor(secId, "Value_" + i, entryThreshold.get(secId).nextDouble(), exitThreshold.get(secId).nextDouble(), 
    	            	        valueOffset.get(secId).nextDouble(), (int) Math.round(bcTicksFund.get(secId).nextDouble()), params.capFactorFund, positionUpdateValue, 
    	            	        orderOrPositionStrategyValue, variabilityCapFactorValue, shortSellingValue);
    	            }
	            }
	
	            
	            /* ***************************************
	             * 
	             *      Run the simulation
	             *  
	             ****************************************/
	            simulator.setNumTicks(numTicks);
	            simulator.run();
	            
	            
	            /* ***************************************
	             * 
	             *      Print result and create graphs
	             *      
	             ****************************************/
	            
/*  Comment to avoid memory problems when using many runs
*/	
//	            DoubleTimeSeriesList dtlPositionsTrend = new DoubleTimeSeriesList();
//	            DoubleTimeSeriesList dtlPositionsFund = new DoubleTimeSeriesList();
//	            DoubleTimeSeriesList dtlWealthIncrementsTrend = new DoubleTimeSeriesList();
//	            DoubleTimeSeriesList dtlWealthIncrementsFund = new DoubleTimeSeriesList();
//	                        
//	            for (int tr = 0; tr < numTrends; tr++) {
//	                int trendID = tr;
//	            	TrendMABCStrategy trend = (TrendMABCStrategy) simulator.getTrendFollowers().get("Trend_" + trendID).getStrategies().get("IBM");
//	            	
//	            	DoubleTimeSeries Position = trend.getTsPos();
//	            	DoubleTimeSeries WealthIncrement = StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), trend.getTsPos());
//	            	
//	            	dtlPositionsTrend.add(tr, Position);
//	            	dtlWealthIncrementsTrend.add(tr, WealthIncrement);
//	            }
//	            
//	            for (int val = 0; val < numFunds; val++) {
//	                int valueID = val;
//	            	ValueMABCStrategy fund = (ValueMABCStrategy) simulator.getValueInvestors().get("Value_" + valueID).getStrategies().get("IBM");
//	            	
//	            	DoubleTimeSeries Position = fund.getTsPos();
//	            	DoubleTimeSeries WealthIncrement = StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), fund.getTsPos());
//	            	
//	            	dtlPositionsFund.add(val, Position);
//	            	dtlWealthIncrementsFund.add(val, WealthIncrement);
//	            }
//	            
//	            for (int tr = 0; tr < numTrends; tr++) {
//	                logger.debug("Positions_T: {}", VersatileTimeSeries.printValues(dtlPositionsTrend.get(tr)));
//	                atcWealthTrend.populateSeries(e, run, "wealth_T_" + tr, dtlWealthIncrementsTrend.get(tr));	                
//	                atcPosTrend.populateSeries(e, run, "pos_T_" + tr, dtlPositionsTrend.get(tr));
//	            }
//	                        
//	            for (int val = 0; val < numFunds; val++) {
//	                logger.debug("Positions_F: {}", VersatileTimeSeries.printValues(dtlPositionsFund.get(val)));
//	                atcWealthFund.populateSeries(e, run, "wealth_F_" + val, dtlWealthIncrementsFund.get(val));
//	                atcPosFund.populateSeries(e, run, "pos_F_" + val, dtlPositionsFund.get(val));
//	            }
//	            
//	            logger.debug("TOTAL_Volume: {}", VersatileTimeSeries.printValues(simulator.getTotalVolume("IBM")));
	            

//	            for (String secId : shareIds) {
//    	            logger.debug("{}", VersatileTimeSeries.printDecoratedTicks(simulator.getPrices(secId), 0));
//    	            logger.debug("{}", VersatileTimeSeries.printDecoratedValues(simulator.getPrices(secId), "Price " + secId, 6));
//    	            
//    	            logger.debug("{}", VersatileTimeSeries.printDecoratedTicks(simulator.getFundValues(secId), 0));
//    	            logger.debug("{}", VersatileTimeSeries.printDecoratedValues(simulator.getFundValues(secId), "Value " + secId, 6));
//    	            
//                  atcPrices.populateSeries(run, secId + "_P", simulator.getPrices(secId));
//    	            atcValues.populateSeries(run, secId + "_V", simulator.getFundValues(secId));
//    	            
//    	            /**
//    	             * Print the volatility of log-returns for calibration purposes 
//    	             */            
//    	            DoubleTimeSeries tsLogReturns = new DoubleTimeSeries();
//    	            
//    	            for (int k = 1; k < numTicks; k++) {
//    	            	double price_current_tick = simulator.getPrices(secId).get(k);
//    	            	double price_previous_tick = simulator.getPrices(secId).get(k-1);
//    	            	tsLogReturns.add(Math.log(price_current_tick) - Math.log(price_previous_tick));
//    	            }
//    	            
//    	            logger.debug("VOLATILITY of LOG-RETURNS: {}", tsLogReturns.stdev());
//    	            logger.debug("KURTOSIS of LOG-RETURNS: {}", tsLogReturns.excessKurtosis());
//    	            logger.debug("SKEWNESS of LOG-RETURNS: {}", tsLogReturns.skewness());
//    	            logger.debug("MEAN VOLUME - F: {}, T: {}", simulator.getFundVolume(secId).mean(), simulator.getTrendVolume(secId).mean());
//    	            logger.debug("AVG WEALTH INCREMENT - F: {}, T: {}", simulator.getFundAvgWealthIncrement(secId).get(numTicks-1), simulator.getTrendAvgWealthIncrement(secId).get(numTicks-1));
//	            }
//End comment */
	            
	            
	            /*
	             * Create time series lists for extraction to R
	             */
	            
	            for (String secId : shareIds) {	            
//	            	tsPricesList.add(run, simulator.getPrices(secId));         // <-- !! this writes the series in a wrong order
	            	tsPricesList.add(simulator.getPrices(secId));              // time series list of prices [(nRuns x nAssets) x nTicks]
	            	tsFundValuesList.add(simulator.getFundValues(secId));      // time series list of general fund value [(nRuns x nAssets) x nTicks]
	            	tsTotalVolumeList.add(simulator.getTotalVolume(secId));    // time series list of total volume [(nRuns x nAssets) x nTicks]
	            	tsFundVolumeList.add(simulator.getFundVolume(secId));      // time series list of FUND volume [(nRuns x nAssets) x nTicks]
	            	tsTrendVolumeList.add(simulator.getTrendVolume(secId));    // time series list of TREND volume [(nRuns x nAssets) x nTicks]
	            	tsFundTotalOrdersList.add(simulator.getFundTotalOrders(secId));      // time series list of FUND aggregated orders [(nRuns x nAssets) x nTicks]
	            	tsTrendTotalOrdersList.add(simulator.getTrendTotalOrders(secId));    // time series list of TREND aggregated orders [(nRuns x nAssets) x nTicks]
	            	tsFundAvgWealthIncrementList.add(simulator.getFundAvgWealthIncrement(secId));      // time series list of FUND wealth increment [(nRuns x nAssets) x nTicks]
	            	tsTrendAvgWealthIncrementList.add(simulator.getTrendAvgWealthIncrement(secId));    // time series list of TREND wealth increment [(nRuns x nAssets) x nTicks]
	            }
	        } 
        }
        
        
        
        /** **************************************************
         * 
         *               OUTPUT
         *      
         **************************************************** */ 
                
        /**
         * Charts
         */        
/* Comment to avoid exceptions when using many runs
*/
//        if (numTrends > 0) {
//        	charts.draw(atcWealthTrend);
//            charts.draw(atcPosTrend);
//        }
//        
//        if (numFunds > 0) {
//        	charts.draw(atcWealthFund);
//            charts.draw(atcPosFund);
//            charts.draw(atcValue);
////            charts.draw(atcValuePriceDiff);
////            charts.draw(atcValuePriceDiff_F1);
//        }        
        
//        charts.draw(atcPriceIBM);
//        charts.draw(atcPriceMSFT);
//        charts.draw(atcPriceGOOG);
//        charts.draw(atcVolumeFund);
//        charts.draw(atcVolumeTrend);
//End comment */
        
        
        
        /**
         *      Write results to file for further analysis with R
         */

        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_price_timeseries.csv").write(tsPricesList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_fundvalues_timeseries.csv").write(tsFundValuesList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_totalvolume_timeseries.csv").write(tsTotalVolumeList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_fundvolume_timeseries.csv").write(tsFundVolumeList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_trendvolume_timeseries.csv").write(tsTrendVolumeList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_fundorders_timeseries.csv").write(tsFundTotalOrdersList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_trendorders_timeseries.csv").write(tsTrendTotalOrdersList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_fundwealth_timeseries.csv").write(tsFundAvgWealthIncrementList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_trendwealth_timeseries.csv").write(tsTrendAvgWealthIncrementList);
        
        
        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
    }

}
