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

import info.financialecology.finance.abm.model.TrendValueLSAbmSimulator;
import info.financialecology.finance.abm.model.agent.Trader;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.MultiplierTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.PositionUpdateTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.OrderOrPositionStrategyTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.VariabilityCapFactorTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.ShortSellingTrend;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.PositionUpdateValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.OrderOrPositionStrategyValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.VariabilityCapFactorValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.ShortSellingValue;
import info.financialecology.finance.abm.model.strategy.LSMABCStrategy;
import info.financialecology.finance.abm.model.strategy.LSMABCStrategy.PositionUpdateLS;
import info.financialecology.finance.abm.model.strategy.LSMABCStrategy.MultiplierLS;
import info.financialecology.finance.abm.sandbox.TrendValueLSAbmParams;
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
 * An agent-based simulation with trend followers, value investors and LS investors
 * 
 * @author Gilbert Peffer, Bàrbara Llacay
 */
public class TrendValueLSMultiAssetAbmSimulation {

    protected static final String TEST_ID = "TrendValueLSMultiAssetAbmSimulation"; 
    
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
        System.out.println("==========================================\n");

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
        
        TrendValueLSAbmParams params = TrendValueLSAbmParams.readParameters(CmdLineProcessor.process(args));

        /*
         *      PARAMETERS
         */

        int numTicks        = params.nTicks;    // number of ticks per simulation run
        int numRuns         = params.nRuns;     // number of runs per simulation experiment
        int startSeed       = params.seed;      // starting position in the random seed table; -1 for random value (based on internal clock) 
        
        int numTrends       = params.numTrends;    // number of TREND investors
        int numFunds        = params.numFunds;     // number of FUND investors
        int numLS           = params.numLS;        // number of LS investors	
        
        DoubleArrayList price_0      = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.PRICE_0);
        DoubleArrayList liquidity    = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.LIQUIDITY);
        
        double probShortSellingTrend = params.probShortSellingTrend;   // percentage of TRENDs which are allowed to short-sell (between 0 and 1)
        double probShortSellingValue = params.probShortSellingValue;   // percentage of FUNDs which are allowed to short-sell (between 0 and 1)

        // Parameters for the exogenous price process. The process is an overlay of a Brownian process and a sinus function
        
//        DoubleArrayList shift_price      = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.SHIFT_PRICE);
        DoubleArrayList amplitude_price  = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.AMPLITUDE_PRICE);
        DoubleArrayList lag_price        = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.LAG_PRICE);
        DoubleArrayList lambda_price     = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.LAMBDA_PRICE);
        
        DoubleArrayList mu_price         = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.MU_PRICE);
        DoubleArrayList sigma_price      = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.SIGMA_PRICE);        
                
        // Parameters for the exogenous market-wide fundamental value process. The process is an overlay of a Brownian process and a sinus function
        
//        DoubleArrayList shift_value      = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.SHIFT_VALUE);
        DoubleArrayList amplitude_value  = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.AMPLITUDE_VALUE);
        DoubleArrayList lag_value        = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.LAG_VALUE);
        DoubleArrayList lambda_value     = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.LAMBDA_VALUE);        
        
        DoubleArrayList mu_value         = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.MU_VALUE);
        DoubleArrayList sigma_value      = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.SIGMA_VALUE);
        
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
        
//        DoubleArrayList sigmaMin = sigma_price;    // TODO Only for experiments
//        DoubleArrayList sigmaMax = sigma_price;
                
        TrendValueLSAbmSimulator simulator;

        
        /*
         *      OUTPUT VARIABLES
         */
        
        // Variables for charts
        
        VersatileChart charts = new VersatileChart();
        charts.getInternalParms().autoRange = true;
        charts.getInternalParms().autoRangePadding = 0;
        charts.getInternalParms().ticks = true;
        
        // Time series
        
        VersatileTimeSeriesCollection atcWealthFund_IBM     = new VersatileTimeSeriesCollection("FUND Wealth for IBM");
        VersatileTimeSeriesCollection atcWealthFund_MSFT    = new VersatileTimeSeriesCollection("FUND Wealth for MSFT");
        VersatileTimeSeriesCollection atcWealthFund_GOOG    = new VersatileTimeSeriesCollection("FUND Wealth for GOOG");
        VersatileTimeSeriesCollection atcWealthTrend_IBM    = new VersatileTimeSeriesCollection("TREND Wealth for IBM");
        VersatileTimeSeriesCollection atcWealthTrend_MSFT   = new VersatileTimeSeriesCollection("TREND Wealth for MSFT");
        VersatileTimeSeriesCollection atcWealthTrend_GOOG   = new VersatileTimeSeriesCollection("TREND Wealth for GOOG");
        VersatileTimeSeriesCollection atcWealthLS_IBM       = new VersatileTimeSeriesCollection("LS Wealth for IBM");
        VersatileTimeSeriesCollection atcWealthLS_MSFT      = new VersatileTimeSeriesCollection("LS Wealth for MSFT");
        VersatileTimeSeriesCollection atcWealthLS_GOOG      = new VersatileTimeSeriesCollection("LS Wealth for GOOG");
        VersatileTimeSeriesCollection atcPosFund_IBM        = new VersatileTimeSeriesCollection("FUND Positions for IBM");
        VersatileTimeSeriesCollection atcPosFund_MSFT       = new VersatileTimeSeriesCollection("FUND Positions for MSFT");
        VersatileTimeSeriesCollection atcPosFund_GOOG       = new VersatileTimeSeriesCollection("FUND Positions for GOOG");
        VersatileTimeSeriesCollection atcPosTrend_IBM       = new VersatileTimeSeriesCollection("TREND Positions for IBM");
        VersatileTimeSeriesCollection atcPosTrend_MSFT      = new VersatileTimeSeriesCollection("TREND Positions for MSFT");
        VersatileTimeSeriesCollection atcPosTrend_GOOG      = new VersatileTimeSeriesCollection("TREND Positions for GOOG");
        VersatileTimeSeriesCollection atcPosLS_IBM          = new VersatileTimeSeriesCollection("LS Positions for IBM");
        VersatileTimeSeriesCollection atcPosLS_MSFT         = new VersatileTimeSeriesCollection("LS Positions for MSFT");
        VersatileTimeSeriesCollection atcPosLS_GOOG         = new VersatileTimeSeriesCollection("LS Positions for GOOG");
        VersatileTimeSeriesCollection atcValuePriceDiff = new VersatileTimeSeriesCollection("Value-Price Difference"); 
        VersatileTimeSeriesCollection atcValuePriceDiff_F1 = new VersatileTimeSeriesCollection("Value-Price Difference of FUND_1");
        
        // Time series
        
        VersatileTimeSeriesCollection atcPrices             = new VersatileTimeSeriesCollection("Prices for shares");        
        VersatileTimeSeriesCollection atcValues             = new VersatileTimeSeriesCollection("Fundamental values");
        VersatileTimeSeriesCollection atcSpreads            = new VersatileTimeSeriesCollection("Spreads for shares");
        
        VersatileTimeSeriesCollection atcSpread_1EN         = new VersatileTimeSeriesCollection("Spread IBM_MSFT");
        VersatileTimeSeriesCollection atcSpread_1EX         = new VersatileTimeSeriesCollection("Spread IBM_MSFT");
        VersatileTimeSeriesCollection atcSpread_2EN         = new VersatileTimeSeriesCollection("Spreads IBM_GOOG");
        VersatileTimeSeriesCollection atcSpread_2EX         = new VersatileTimeSeriesCollection("Spreads IBM_GOOG");
        
        
        // Variables for manual calculation of normalising factor of FUND and LS positions        

        DoubleArrayList meanMagnitudeFundIndicator  = new DoubleArrayList();
        DoubleArrayList meanMagnitudeLSIndicator    = new DoubleArrayList();
        DoubleArrayList ratioMeanMagnitudeIndicator = new DoubleArrayList();

        DoubleArrayList maxAbsFundPosition  = new DoubleArrayList();
        DoubleArrayList maxAbsLSPosition    = new DoubleArrayList();
        DoubleArrayList ratioMaxAbsPosition = new DoubleArrayList();

        DoubleArrayList meanMaxAbsFundPosition  = new DoubleArrayList();
        DoubleArrayList meanMaxAbsLSPosition    = new DoubleArrayList();
        DoubleArrayList ratioMeanMaxAbsPosition = new DoubleArrayList();
              
        
        /*
         *      ASSET ID's
         */
        
        ArrayList<String> shareIds = new ArrayList<String>();
        shareIds.add("IBM");                
        if (numAssets > 1) shareIds.add("MSFT");
        if (numAssets > 2) shareIds.add("GOOG");
        if (numAssets > 3) shareIds.add("AAPL");
        
        Assertion.assertOrKill(shareIds.size() == numAssets, numAssets + " share identifiers have to be defined, but only " + shareIds + " are in the list");
        Assertion.assertOrKill((numLS == 0 || numAssets > 1), "There needs to be at least 2 assets for the LS strategy to work");
               
       
        
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

//        	double liq_IBM;
//        	if (numExp > 1) {
//        		liq_IBM = 650 + e * 50;
//        		liquidity.set(0, liq_IBM);
//        		liquidity.set(1, liq_IBM);
//        		liquidity.set(2, liq_IBM);
//        	}
        	
//        	double exitMin = 3;
//        	double exitMax = 3;
//        	if (numExp > 1) {
////        		exitMin = 0.5 - e * 0.10;
//        		exitMax = 3 + e * 0.5;
//        	}
//        	System.out.print("exitSigmas = [" + exitMin + ", " + exitMax + "]" + "\n");
        	
//        	double capFact = 1.3;
//        	if (numExp > 1) {
//        		capFact = 1.3 + e * 0.1;
//        	}
//        	System.out.print("capFactor = " + capFact + "\n");
        	
//        	int maLongMin = 50;
//        	int maLongMax = 200;
//        	if (numExp > 1) {
//        		maLongMin = 50 + e * 50;
//        		maLongMax = 200 + e * 50;
//        	}
//        	System.out.print("maLong = [" + maLongMin + ", " + maLongMax + "]" + "\n");
//        	
//        	int maShortMin = 1;
//        	int maShortMax = 1;
//        	if (numExp > 1) {
//        		maShortMax = 1 + e;
//        	}
//        	System.out.print("maShort = [" + maShortMin + ", " + maShortMax + "]" + "\n");

//        	numLS = 0;
//        	double capFactTrend = 1;
////        	double liq_IBM = 400;
//        	if (numExp > 1) {
//        		numLS = e*40;
//        		capFactTrend = 1 + e*0.1;
////        		liq_IBM = 400 + e*20;
//        		liquidity.set(0, 400 + e*40);
//        		liquidity.set(1, 400 + e*30);
//        		liquidity.set(2, 400 + e*30);
//        	}
//        	System.out.print("numLS = " + numLS + "\n");
//        	System.out.print("capFactTrend = " + capFactTrend + "\n");
//        	System.out.print("liq = " + liquidity + "\n");
        	
        	if (numExp > 1) {
        		probShortSellingTrend = e * 0.1;
        		probShortSellingValue = e * 0.1;
        	}
        	System.out.print("probSS = [" + probShortSellingTrend + ", " + probShortSellingValue + "]" + "\n");
        	
        	
        	/*
             * Variables for extracting data to R for each experiment - TODO: Delete when VersatileTimeSeriesCollection works well in CsvResultWriter
             */
            
            DoubleTimeSeriesList tsPricesList                   = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundValuesList               = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTotalVolumeList              = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundVolumeList               = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendVolumeList              = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSVolumeList                 = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundTotalOrdersList          = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendTotalOrdersList         = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSTotalOrdersList            = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendAvgWealthIncrementList  = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundAvgWealthIncrementList   = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSAvgWealthIncrementList     = new DoubleTimeSeriesList();
        	
        
	        for (int run = 0; run < numRuns; run++) {
	        	
	        	System.out.print("RUN:" + run + "\n");
	                        
	            /*
	             * Setting up the simulator
	             */
	        	
	        	simulator = new TrendValueLSAbmSimulator();      // recreating the simulator will also get rid of the old schedule
//	            simulator.resetWorldClock(); MOVED TO THE SIMULATOR
                
                for (int i = 0; i < numAssets; i++) {
                    simulator.addShares(shareIds.get(i));
                    simulator.getMarketMaker().setInitPrice(shareIds.get(i), price_0.get(i));
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
                simulator.createLSInvestors(numLS);
                
	  
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
	            
	            RandomDistDataGenerator distUnif01Trend = new RandomDistDataGenerator("Unif01_Trend", DistributionType.UNIFORM, 0., 1.);  // U[0,1] to proxy a binomial distribution to decide if short-selling is allowed
	            
	            // Additional parameters - these are identical for all assets
	            MultiplierTrend trendMultiplier = MultiplierTrend.MA_SLOPE_DIFFERENCE;     // Method to calculate the size of the trend positions
	            PositionUpdateTrend positionUpdateTrend = PositionUpdateTrend.VARIABLE;    // Specifies if a position can be modified while open
	            OrderOrPositionStrategyTrend orderOrPositionStrategyTrend = OrderOrPositionStrategyTrend.POSITION;     // Specifies if the strategy is order-based or position-based
	            VariabilityCapFactorTrend variabilityCapFactorTrend = VariabilityCapFactorTrend.CONSTANT;              // Specifies if the capFactor is constant or varies based on the agent performance
	            
	            for (int i = 0; i < trendFollowers.size(); i++) {
	            	// Decide if the trader is allowed to short-sell
	            	ShortSellingTrend shortSellingTrend = ShortSellingTrend.ALLOWED;
	            	if (distUnif01Trend.nextDouble() > probShortSellingTrend) 
	            		shortSellingTrend = ShortSellingTrend.NOT_ALLOWED;
	            	
	            	// Create TREND trader
	                for (String secId : shareIds) {
    	            	simulator.addTrendStrategyForOneTrendFollower(secId, "Trend_" + i, (int) Math.round(maShortTicks.get(secId).nextDouble()), 
    	            			(int) Math.round(maLongTicks.get(secId).nextDouble()), (int) Math.round(bcTicksTrend.get(secId).nextDouble()), params.capFactorTrend, 
//    	            			(int) Math.round(maLongTicks.get(secId).nextDouble()), (int) Math.round(bcTicksTrend.get(secId).nextDouble()), capFactTrend,
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
                
                RandomDistDataGenerator distUnif01Value = new RandomDistDataGenerator("Unif01_Value", DistributionType.UNIFORM, 0., 1.);  // U[0,1] to proxy a binomial distribution to decide if short-selling is allowed
                	            
                // Additional parameters - these are identical for all assets
	            PositionUpdateValue positionUpdateValue = PositionUpdateValue.VARIABLE;     // Specifies if a position can be modified while open
	            OrderOrPositionStrategyValue orderOrPositionStrategyValue = OrderOrPositionStrategyValue.POSITION;     // Specifies if the strategy is order-based or position-based
	            VariabilityCapFactorValue variabilityCapFactorValue = VariabilityCapFactorValue.CONSTANT;              // Specifies if the capFactor is constant or varies based on the agent performance
	            	            
	            for (int i = 0; i < valueTraders.size(); i++) {
	            	// Decide if the trader is allowed to short-sell
	            	ShortSellingValue shortSellingValue = ShortSellingValue.ALLOWED;
	            	if (distUnif01Value.nextDouble() > probShortSellingValue)
	            		shortSellingValue = ShortSellingValue.NOT_ALLOWED;
	            	
	            	// Create FUND trader
	                for (String secId : shareIds) {	            
    	            	simulator.addValueStrategyForOneValueInvestor(secId, "Value_" + i, entryThreshold.get(secId).nextDouble(), exitThreshold.get(secId).nextDouble(), 
    	            	        valueOffset.get(secId).nextDouble(), (int) Math.round(bcTicksFund.get(secId).nextDouble()), params.capFactorFund, positionUpdateValue, 
    	            	        orderOrPositionStrategyValue, variabilityCapFactorValue, shortSellingValue);
    	            }
	            }   
	            
	            
	            
	            /* ***************************************
	             * 
	             *      Set up the LS strategies
	             * 
	             *****************************************/
	            
	            HashMap<String, Trader> LSTraders = simulator.getLSInvestors();
	            
                // Random generators for parameters of window size
                // Separate generators for the different assets, to allow replication of individual asset prices when number of assets changes
                HashMap<String, RandomDistDataGenerator> maSpreadShortTicks = new HashMap<String, RandomDistDataGenerator>();
                HashMap<String, RandomDistDataGenerator> maSpreadLongTicks = new HashMap<String, RandomDistDataGenerator>();
                HashMap<String, RandomDistDataGenerator> entryDivergenceSigmas = new HashMap<String, RandomDistDataGenerator>();
                HashMap<String, RandomDistDataGenerator> exitConvergenceSigmas = new HashMap<String, RandomDistDataGenerator>();
                HashMap<String, RandomDistDataGenerator> exitStopLossSigmas = new HashMap<String, RandomDistDataGenerator>();
                
                for (String secId : shareIds) {
                    RandomDistDataGenerator distMaSpreadShortTicks = new RandomDistDataGenerator("maSpreadShortTicks_" + secId, DistributionType.UNIFORM, (double) params.maSpreadShortTicksMin, (double) params.maSpreadShortTicksMax);
//                    RandomDistDataGenerator distMaSpreadShortTicks = new RandomDistDataGenerator("maSpreadShortTicks_" + secId, DistributionType.UNIFORM, (double) maShortMin, (double) maShortMax);
                    RandomDistDataGenerator distMaSpreadLongTicks = new RandomDistDataGenerator("maSpreadLongTicks_" + secId, DistributionType.UNIFORM, (double) params.maSpreadLongTicksMin, (double) params.maSpreadLongTicksMax);
//                    RandomDistDataGenerator distMaSpreadLongTicks = new RandomDistDataGenerator("maSpreadLongTicks_" + secId, DistributionType.UNIFORM, (double) maLongMin, (double) maLongMax);
                    RandomDistDataGenerator distEntryDivergenceSigmas = new RandomDistDataGenerator("entryDivergenceSigmas_" + secId, DistributionType.UNIFORM, (double) params.entryDivergenceSigmasMin, (double) params.entryDivergenceSigmasMax);
//                    RandomDistDataGenerator distEntryDivergenceSigmas = new RandomDistDataGenerator("entryDivergenceSigmas_" + secId, DistributionType.UNIFORM, (double) entryMin, (double) entryMax);
                    RandomDistDataGenerator distExitConvergenceSigmas = new RandomDistDataGenerator("exitConvergenceSigmas_" + secId, DistributionType.UNIFORM, (double) params.exitConvergenceSigmasMin, (double) params.exitConvergenceSigmasMax);
//                    RandomDistDataGenerator distExitConvergenceSigmas = new RandomDistDataGenerator("exitConvergenceSigmas_" + secId, DistributionType.UNIFORM, (double) exitMin, (double) exitMax);
                    RandomDistDataGenerator distExitStopLossSigmas = new RandomDistDataGenerator("exitStopLossSigmas_" + secId, DistributionType.UNIFORM, (double) params.exitStopLossSigmasMin, (double) params.exitStopLossSigmasMax);
//                    RandomDistDataGenerator distExitStopLossSigmas = new RandomDistDataGenerator("exitStopLossSigmas_" + secId, DistributionType.UNIFORM, (double) exitMin, (double) exitMax);

                    maSpreadShortTicks.put(secId, distMaSpreadShortTicks);
                    maSpreadLongTicks.put(secId, distMaSpreadLongTicks);
                    entryDivergenceSigmas.put(secId, distEntryDivergenceSigmas);
                    exitConvergenceSigmas.put(secId, distExitConvergenceSigmas);
                    exitStopLossSigmas.put(secId, distExitStopLossSigmas);
                }
                
                MultiplierLS LSMultiplier = MultiplierLS.DIVERGENCE;        // Method to calculate the size of the LS positions
	            PositionUpdateLS positionUpdateLS = PositionUpdateLS.VARIABLE;     // Specifies if a position can be modified while open
	            
	            for (int i = 0; i < LSTraders.size(); i++) {
	            	for (int j = 1; j < numAssets; j++) {  // Add an LS strategy for each spread, where Spread = P_0 - P_j         
    	            	simulator.addLSStrategyForOneLSInvestor(shareIds.get(0), shareIds.get(j), "LS_" + i, 
    	            			(int) Math.round(maSpreadShortTicks.get(shareIds.get(j)).nextDouble()),
    	            			(int) Math.round(maSpreadLongTicks.get(shareIds.get(j)).nextDouble()),
    	            			params.volWindowLS, entryDivergenceSigmas.get(shareIds.get(j)).nextDouble(), exitConvergenceSigmas.get(shareIds.get(j)).nextDouble(),
    	            			exitStopLossSigmas.get(shareIds.get(j)).nextDouble(), params.capFactorLS, LSMultiplier, positionUpdateLS);
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
	
	            // Create time series for charts - IBM
	            	
//		        for (int tr = 0; tr < numTrends/10; tr++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
//		        	int trendID = tr;
//		        	DoubleTimeSeries positions_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM");
//		        		                
//	        		atcPosTrend_IBM.populateSeries(e, run, "IBM", "pos_T_" + tr, positions_IBM);
//	        		atcWealthTrend_IBM.populateSeries(e, run, "IBM", "wealth_T_" + tr, StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), positions_IBM));
//		        }
//
//		        for (int val = 0; val < numFunds/10; val++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
//		        	int valueID = val;
//		        	DoubleTimeSeries positions_IBM = simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM");
//
//	        		atcPosFund_IBM.populateSeries(e, run, "IBM", "pos_F_" + val, positions_IBM);
//	        		atcWealthFund_IBM.populateSeries(e, run, "IBM", "wealth_F_" + val, StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), positions_IBM));
//		        }
//
//		        for (int ls = 0; ls < numLS/10; ls++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
//		        	int lsID = ls;
//		        	DoubleTimeSeries positions_IBM = simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("IBM");
//		        	
//	        		atcPosLS_IBM.populateSeries(e, run, "IBM", "pos_LS_" + ls, positions_IBM);
//		      		atcWealthLS_IBM.populateSeries(e, run, "IBM", "wealth_LS_" + ls, StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), positions_IBM));
//		        }
//		        
//		        atcPrices.populateSeries(e, run, "IBM", "P", simulator.getPrices("IBM"));
//	            atcValues.populateSeries(e, run, "IBM", "V", simulator.getFundValues("IBM"));
	            
	            
	            // Create time series for charts - MSFT
            	
//		        for (int tr = 0; tr < numTrends/10; tr++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
//		        	int trendID = tr;
//		        	DoubleTimeSeries positions_MSFT = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("MSFT");
//		        		                
//	        		atcPosTrend_MSFT.populateSeries(e, run, "MSFT", "pos_T_" + tr, positions_MSFT);
//	        		atcWealthTrend_MSFT.populateSeries(e, run, "MSFT", "wealth_T_" + tr, StatsTimeSeries.deltaWealth(simulator.getPrices("MSFT"), positions_MSFT));
//		        }
//
//		        for (int val = 0; val < numFunds/10; val++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
//		        	int valueID = val;
//		        	DoubleTimeSeries positions_MSFT = simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("MSFT");
//
//	        		atcPosFund_MSFT.populateSeries(e, run, "MSFT", "pos_F_" + val, positions_MSFT);
//	        		atcWealthFund_MSFT.populateSeries(e, run, "MSFT", "wealth_F_" + val, StatsTimeSeries.deltaWealth(simulator.getPrices("MSFT"), positions_MSFT));
//		        }
//
//		        for (int ls = 0; ls < numLS/10; ls++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
//		        	int lsID = ls;
//		        	DoubleTimeSeries positions_MSFT = simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("MSFT");
//		        	
//	        		atcPosLS_MSFT.populateSeries(e, run, "MSFT", "pos_LS_" + ls, positions_MSFT);
//		      		atcWealthLS_MSFT.populateSeries(e, run, "MSFT", "wealth_LS_" + ls, StatsTimeSeries.deltaWealth(simulator.getPrices("MSFT"), positions_MSFT));
//		        }
//		        
//		        atcPrices.populateSeries(e, run, "MSFT", "P", simulator.getPrices("MSFT"));
//	            atcValues.populateSeries(e, run, "MSFT", "V", simulator.getFundValues("MSFT"));

	            // Create time series for charts - GOOG
            	
		        for (int tr = 0; tr < numTrends/10; tr++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
		        	int trendID = tr;
		        	DoubleTimeSeries positions_GOOG = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("GOOG");
		        		                
	        		atcPosTrend_GOOG.populateSeries(e, run, "GOOG", "pos_T_" + tr, positions_GOOG);
	        		atcWealthTrend_GOOG.populateSeries(e, run, "GOOG", "wealth_T_" + tr, StatsTimeSeries.deltaWealth(simulator.getPrices("GOOG"), positions_GOOG));
		        }

		        for (int val = 0; val < numFunds/10; val++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
		        	int valueID = val;
		        	DoubleTimeSeries positions_GOOG = simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("GOOG");

	        		atcPosFund_GOOG.populateSeries(e, run, "GOOG", "pos_F_" + val, positions_GOOG);
	        		atcWealthFund_GOOG.populateSeries(e, run, "GOOG", "wealth_F_" + val, StatsTimeSeries.deltaWealth(simulator.getPrices("GOOG"), positions_GOOG));
		        }

		        for (int ls = 0; ls < numLS/10; ls++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
		        	int lsID = ls;
		        	DoubleTimeSeries positions_GOOG = simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("GOOG");
		        	
	        		atcPosLS_GOOG.populateSeries(e, run, "GOOG", "pos_LS_" + ls, positions_GOOG);
		      		atcWealthLS_GOOG.populateSeries(e, run, "GOOG", "wealth_LS_" + ls, StatsTimeSeries.deltaWealth(simulator.getPrices("GOOG"), positions_GOOG));
		        }
		        
		        atcPrices.populateSeries(e, run, "GOOG", "P", simulator.getPrices("GOOG"));
	            atcValues.populateSeries(e, run, "GOOG", "V", simulator.getFundValues("GOOG"));
	            
	            // Create time series for charts - Spreads
	            
	            DoubleTimeSeries spread_IBM_MSFT = StatsTimeSeries.substraction(simulator.getPrices("IBM"), simulator.getPrices("MSFT"));
		        DoubleTimeSeries spread_IBM_GOOG = StatsTimeSeries.substraction(simulator.getPrices("IBM"), simulator.getPrices("GOOG"));
		        atcSpreads.populateSeries(e, run, "IBM_MSFT", "S", spread_IBM_MSFT);
		        atcSpreads.populateSeries(e, run, "IBM_GOOG", "S", spread_IBM_GOOG);
		        
//End comment */
		        
		        
	            /**
	             * Calculation of normalisation factor of FUND and LS positions 
	             */
	            
//	            // ---- Using the mean of FUND/LS entry indicators ----
//	            
//	            int warmUpPeriod = Math.max(params.bcTicksFundMax, Math.max(params.volWindowLS, params.histWindowMax));
//	            int valueID = 0;   // TODO - Randomly choose a trader from the set of Funds
//	            String normAssetId = "MSFT";  // Asset used for the normalisation calculations (!! Use MSFT or GOOG, as afterwards the spread is created with the IBM asset)
//	        	ValueMABCStrategy fund = (ValueMABCStrategy) simulator.getValueInvestors().get("Value_" + valueID).getStrategies().get(normAssetId);
//
//	            double meanFundInd = simulator.magnitudeValueIndicator(normAssetId, numTicks, fund.getValueOffset());
//	            meanMagnitudeFundIndicator.add(meanFundInd);
//	            
//	            int LSID = 0;   // TODO - Randomly choose a trader from the set of LS
//	            LSMABCStrategy ls = (LSMABCStrategy) simulator.getLSInvestors().get("LS_" + LSID).getStrategies().get("IBM_" + normAssetId);
//	            double meanLSInd = simulator.magnitudeLSIndicator(normAssetId, numTicks - warmUpPeriod, ls.getHistWindow(), ls.getVolWindow(), LSMultiplier);
//	            meanMagnitudeLSIndicator.add(meanLSInd);
//	            
//	            ratioMeanMagnitudeIndicator.add(meanFundInd/meanLSInd);
//	            
//	            logger.debug("MeanMagnitudeIndicator_F: {}", meanFundInd);   //TEST
//	            logger.debug("MeanMagnitudeIndicator_LS: {}", meanLSInd);   //TEST
//	            logger.debug("ratioMeanMagnitudeIndicator: {}", meanFundInd/meanLSInd);   //TEST
//	            
//	            // ---- Using the maximum position of an individual FUND/LS ----
//	            
//	        	DoubleTimeSeries fundPos = fund.getTsPos();
//	            double maxFundPosition = StatsTimeSeries.maxAbsValue(fundPos);
//	            
//	            DoubleTimeSeries LSPos = ls.getTsPos_2();  // Position in the asset which only makes part of 1 spread
//	            double maxLSPosition = StatsTimeSeries.maxAbsValue(LSPos);
//	            
//	            maxAbsFundPosition.add(maxFundPosition);
//	            maxAbsLSPosition.add(maxLSPosition);
//	            ratioMaxAbsPosition.add(maxFundPosition/maxLSPosition);
//	            
//	            logger.debug("ratioMaxPosition: {}", maxFundPosition/maxLSPosition);   //TEST
//	            
//	            // ---- Using the mean of maximum position over all FUNDs/LSs ----
//	            
//	            double meanMaxLSPosition = 0;
//	            double meanMaxFundPosition = 0;
//	            
//	            for (int val = 0; val < numFunds; val++) {
//	            	
//	                int valueID2 = val;
//	            	ValueMABCStrategy fund2 = (ValueMABCStrategy) simulator.getValueInvestors().get("Value_" + valueID2).getStrategies().get(normAssetId);
//	            	
//	            	DoubleTimeSeries fundPos2 = fund2.getTsPos();
//	            	
//	            	meanMaxFundPosition = meanMaxFundPosition + StatsTimeSeries.maxAbsValue(fundPos2);
//	            }
//	            
//	            meanMaxAbsFundPosition.add(meanMaxFundPosition / numFunds);
//	            
//	            for (int l = 0; l < numLS; l++) {
//	            	
//	                int lsID2 = l;
//	            	LSMABCStrategy ls2 = (LSMABCStrategy) simulator.getLSInvestors().get("LS_" + lsID2).getStrategies().get("IBM_" + normAssetId);
//	            	
//	            	DoubleTimeSeries LSPos2 = ls2.getTsPos_2();
//	            	
//	            	meanMaxLSPosition = meanMaxLSPosition + StatsTimeSeries.maxAbsValue(LSPos2);
//	            }
//	            
//	            meanMaxAbsLSPosition.add(meanMaxLSPosition / numLS);
//	            
//	            ratioMeanMaxAbsPosition.add( (meanMaxFundPosition / numFunds) / (meanMaxLSPosition / numLS) );
//	            
//	            logger.debug("ratioMeanMaxPosition: {}", (meanMaxFundPosition / numFunds) / (meanMaxLSPosition / numLS));   //TEST

	            /**
	             * VVUQ tests
	             */
	            
	            // VE - Entry condition for LS traders  --> DELETE
		        
//		        DoubleTimeSeries spread_IBM_MSFT_meanPlus2Std = new DoubleTimeSeries();
//		        DoubleTimeSeries spread_IBM_MSFT_meanMinus2Std = new DoubleTimeSeries();
//		        DoubleTimeSeries spread_IBM_GOOG_meanPlus2Std = new DoubleTimeSeries();
//		        DoubleTimeSeries spread_IBM_GOOG_meanMinus2Std = new DoubleTimeSeries();
//		        		        
//		        for (int k = 0; k < (params.histWindowMin + params.histWindowMax)/2; k++) {
//		        	spread_IBM_MSFT_meanPlus2Std.add(k, 0);
//		        	spread_IBM_MSFT_meanMinus2Std.add(k, 0);
//		        	spread_IBM_GOOG_meanPlus2Std.add(k, 0);
//		        	spread_IBM_GOOG_meanMinus2Std.add(k, 0);
//		        }
//		        
//		        for (int k = (params.histWindowMin + params.histWindowMax)/2 - 1; k < numTicks; k++) {
//		        	DoubleTimeSeries spread_IBM_MSFT_window = new DoubleTimeSeries();
//		        	DoubleTimeSeries spread_IBM_GOOG_window = new DoubleTimeSeries();
//		        	for (int m = 0; m < (params.histWindowMin + params.histWindowMax)/2; m++) {
//		        		spread_IBM_MSFT_window.add(m, spread_IBM_MSFT.get(k-m));
//		        		spread_IBM_GOOG_window.add(m, spread_IBM_GOOG.get(k-m));
//		        	}
//		        	spread_IBM_MSFT_meanPlus2Std.add(k, spread_IBM_MSFT_window.mean() + 2*spread_IBM_MSFT_window.stdev());
//		        	spread_IBM_MSFT_meanMinus2Std.add(k, spread_IBM_MSFT_window.mean() - 2*spread_IBM_MSFT_window.stdev());
//		        	spread_IBM_GOOG_meanPlus2Std.add(k, spread_IBM_GOOG_window.mean() + 2*spread_IBM_GOOG_window.stdev());
//		        	spread_IBM_GOOG_meanMinus2Std.add(k, spread_IBM_GOOG_window.mean() - 2*spread_IBM_GOOG_window.stdev());
//		        }
//		        
//		        atcSpread_1EN.populateSeries(e, run, "IBM_MSFT", "S", spread_IBM_MSFT);
//		        atcSpread_1EN.populateSeries(e, run, "IBM_MSFT", "Mean+2Std", spread_IBM_MSFT_meanPlus2Std);
//		        atcSpread_1EN.populateSeries(e, run, "IBM_MSFT", "Mean-2Std", spread_IBM_MSFT_meanMinus2Std);
//		        
//		        atcSpread_2EN.populateSeries(e, run, "IBM_GOOG", "S", spread_IBM_GOOG);
//		        atcSpread_2EN.populateSeries(e, run, "IBM_GOOG", "Mean+2Std", spread_IBM_GOOG_meanPlus2Std);
//		        atcSpread_2EN.populateSeries(e, run, "IBM_GOOG", "Mean-2Std", spread_IBM_GOOG_meanMinus2Std);
//		        
//	            // VE - Exit condition for LS traders  --> DELETE
//		        
//		        DoubleTimeSeries spread_IBM_MSFT_meanPlus05Std = new DoubleTimeSeries();
//		        DoubleTimeSeries spread_IBM_MSFT_meanMinus05Std = new DoubleTimeSeries();
//		        DoubleTimeSeries spread_IBM_MSFT_meanPlus3Std = new DoubleTimeSeries();
//		        DoubleTimeSeries spread_IBM_MSFT_meanMinus3Std = new DoubleTimeSeries();
//
//		        DoubleTimeSeries spread_IBM_GOOG_meanPlus05Std = new DoubleTimeSeries();
//		        DoubleTimeSeries spread_IBM_GOOG_meanMinus05Std = new DoubleTimeSeries();
//		        DoubleTimeSeries spread_IBM_GOOG_meanPlus3Std = new DoubleTimeSeries();
//		        DoubleTimeSeries spread_IBM_GOOG_meanMinus3Std = new DoubleTimeSeries();
//		        
//		        for (int k = 0; k < (params.histWindowMin + params.histWindowMax)/2; k++) {
//		        	spread_IBM_MSFT_meanPlus05Std.add(k, 0);
//		        	spread_IBM_MSFT_meanMinus05Std.add(k, 0);
//		        	spread_IBM_MSFT_meanPlus3Std.add(k, 0);
//		        	spread_IBM_MSFT_meanMinus3Std.add(k, 0);
//		        	spread_IBM_GOOG_meanPlus05Std.add(k, 0);
//		        	spread_IBM_GOOG_meanMinus05Std.add(k, 0);
//		        	spread_IBM_GOOG_meanPlus3Std.add(k, 0);
//		        	spread_IBM_GOOG_meanMinus3Std.add(k, 0);
//		        }
//		        
//		        for (int k = (params.histWindowMin + params.histWindowMax)/2 - 1; k < numTicks; k++) {
//		        	DoubleTimeSeries spread_IBM_MSFT_window = new DoubleTimeSeries();
//		        	DoubleTimeSeries spread_IBM_GOOG_window = new DoubleTimeSeries();
//		        	for (int m = 0; m < (params.histWindowMin + params.histWindowMax)/2; m++) {
//		        		spread_IBM_MSFT_window.add(m, spread_IBM_MSFT.get(k-m));
//		        		spread_IBM_GOOG_window.add(m, spread_IBM_GOOG.get(k-m));
//		        	}
//		        	spread_IBM_MSFT_meanPlus05Std.add(k, spread_IBM_MSFT_window.mean() + 0.5*spread_IBM_MSFT_window.stdev());
//		        	spread_IBM_MSFT_meanMinus05Std.add(k, spread_IBM_MSFT_window.mean() - 0.5*spread_IBM_MSFT_window.stdev());
//		        	spread_IBM_MSFT_meanPlus3Std.add(k, spread_IBM_MSFT_window.mean() + 3*spread_IBM_MSFT_window.stdev());
//		        	spread_IBM_MSFT_meanMinus3Std.add(k, spread_IBM_MSFT_window.mean() - 3*spread_IBM_MSFT_window.stdev());
//		        	spread_IBM_GOOG_meanPlus05Std.add(k, spread_IBM_GOOG_window.mean() + 0.5*spread_IBM_GOOG_window.stdev());
//		        	spread_IBM_GOOG_meanMinus05Std.add(k, spread_IBM_GOOG_window.mean() - 0.5*spread_IBM_GOOG_window.stdev());
//		        	spread_IBM_GOOG_meanPlus3Std.add(k, spread_IBM_GOOG_window.mean() + 3*spread_IBM_GOOG_window.stdev());
//		        	spread_IBM_GOOG_meanMinus3Std.add(k, spread_IBM_GOOG_window.mean() - 3*spread_IBM_GOOG_window.stdev());
//		        }
//		        
//		        atcSpread_1EX.populateSeries(e, run, "IBM_MSFT", "S", spread_IBM_MSFT);
//		        atcSpread_1EX.populateSeries(e, run, "IBM_MSFT", "Mean+0.5Std", spread_IBM_MSFT_meanPlus05Std);
//		        atcSpread_1EX.populateSeries(e, run, "IBM_MSFT", "Mean-0.5Std", spread_IBM_MSFT_meanMinus05Std);
//		        atcSpread_1EX.populateSeries(e, run, "IBM_MSFT", "Mean+3Std", spread_IBM_MSFT_meanPlus3Std);
//		        atcSpread_1EX.populateSeries(e, run, "IBM_MSFT", "Mean-3Std", spread_IBM_MSFT_meanMinus3Std);
//		        
//		        atcSpread_2EX.populateSeries(e, run, "IBM_GOOG", "S", spread_IBM_GOOG);
//		        atcSpread_2EX.populateSeries(e, run, "IBM_GOOG", "Mean+0.5Std", spread_IBM_GOOG_meanPlus05Std);
//		        atcSpread_2EX.populateSeries(e, run, "IBM_GOOG", "Mean-0.5Std", spread_IBM_GOOG_meanMinus05Std);
//		        atcSpread_2EX.populateSeries(e, run, "IBM_GOOG", "Mean+3Std", spread_IBM_GOOG_meanPlus3Std);
//		        atcSpread_2EX.populateSeries(e, run, "IBM_GOOG", "Mean-3Std", spread_IBM_GOOG_meanMinus3Std);    

	            
	                   
	            for (String secId : shareIds) {
//    	            logger.debug("{}", VersatileTimeSeries.printDecoratedTicks(simulator.getPrices(secId), 0));
//    	            logger.debug("{}", VersatileTimeSeries.printDecoratedValues(simulator.getPrices(secId), "Price " + secId, 6));
//    	            
////    	            logger.debug("{}", VersatileTimeSeries.printDecoratedTicks(simulator.getFundValues(secId), 0));
////    	            logger.debug("{}", VersatileTimeSeries.printDecoratedValues(simulator.getFundValues(secId), "Value " + secId, 6));
//
//	            
//    	            /**
//    	             * Print the volatility of log-returns for calibration purposes 
//    	             */
	            	
//    	            logger.debug("PRICE_" + secId + ": {}", simulator.getPrices(secId));
    	            logger.debug("CORRELATION OF PRICES: {}", StatsTimeSeries.correlation(simulator.getPrices("IBM"), simulator.getPrices(secId)));
    	            logger.debug("VOLATILITY of LOG-RETURNS: {}", simulator.getLogReturns(secId).stdev());
    	            logger.debug("KURTOSIS of LOG-RETURNS: {}", simulator.getLogReturns(secId).excessKurtosis());
//    	            logger.debug("SKEWNESS of LOG-RETURNS: {}", simulator.getLogReturns(secId).skewness());
    	            logger.debug("MEAN VOLUME - F: {}, T: {}", simulator.getFundVolume(secId).mean(), simulator.getTrendVolume(secId).mean());
    	            logger.debug("MEAN VOLUME - LS: {}", simulator.getLSVolume(secId).mean());
    	            logger.debug("AVG WEALTH INCREMENT - F: {}, T: {}", simulator.getFundAvgWealthIncrement(secId).get(numTicks-1), simulator.getTrendAvgWealthIncrement(secId).get(numTicks-1));
	            	logger.debug("AVG WEALTH INCREMENT - LS: {}", simulator.getLSAvgWealthIncrement(secId).get(numTicks-1));
    	            logger.debug("\n");
	            }
		        
//		        logger.debug("POSITIONS IBM: {}", simulator.getLSInvestors().get("LS_0").getPortfolio().getTsPosition("IBM"));
//		        logger.debug("POSITIONS MSFT: {}", simulator.getLSInvestors().get("LS_0").getPortfolio().getTsPosition("MSFT"));
//		        logger.debug("POSITIONS GOOG: {}", simulator.getLSInvestors().get("LS_0").getPortfolio().getTsPosition("GOOG"));

	            
	            
	            /*
	             * Create time series lists for extraction to R
	             */
	            
	            for (String secId : shareIds) {
	            	int shareIndex = shareIds.indexOf(secId);

	            	tsPricesList.add(shareIndex + run*numAssets, simulator.getPrices(secId));              // time series list of prices [(nRuns * nAssets) x nTicks]
	            	tsFundValuesList.add(shareIndex + run*numAssets, simulator.getFundValues(secId));      // time series list of general fund value [(nRuns * nAssets) x nTicks]
	            	tsTotalVolumeList.add(shareIndex + run*numAssets, simulator.getTotalVolume(secId));    // time series list of total volume [(nRuns * nAssets) x nTicks]
	            	tsFundVolumeList.add(shareIndex + run*numAssets, simulator.getFundVolume(secId));      // time series list of FUND volume [(nRuns * nAssets) x nTicks]
	            	tsTrendVolumeList.add(shareIndex + run*numAssets, simulator.getTrendVolume(secId));    // time series list of TREND volume [(nRuns * nAssets) x nTicks]
	            	tsLSVolumeList.add(shareIndex + run*numAssets, simulator.getLSVolume(secId));          // time series list of LS volume [(nRuns * nAssets) x nTicks]
	            	tsFundTotalOrdersList.add(shareIndex + run*numAssets, simulator.getFundTotalOrders(secId));      // time series list of FUND aggregated orders [(nRuns * nAssets) x nTicks]
	            	tsTrendTotalOrdersList.add(shareIndex + run*numAssets, simulator.getTrendTotalOrders(secId));    // time series list of TREND aggregated orders [(nRuns * nAssets) x nTicks]
	            	tsLSTotalOrdersList.add(shareIndex + run*numAssets, simulator.getLSTotalOrders(secId));          // time series list of LS aggregated orders [(nRuns * nAssets) x nTicks]
	            	tsFundAvgWealthIncrementList.add(shareIndex + run*numAssets, simulator.getFundAvgWealthIncrement(secId));      // time series list of FUND wealth increment [(nRuns * nAssets) x nTicks]
	            	tsTrendAvgWealthIncrementList.add(shareIndex + run*numAssets, simulator.getTrendAvgWealthIncrement(secId));    // time series list of TREND wealth increment [(nRuns * nAssets) x nTicks]
	            	tsLSAvgWealthIncrementList.add(shareIndex + run*numAssets, simulator.getLSAvgWealthIncrement(secId));          // time series list of LS wealth increment [(nRuns * nAssets) x nTicks]
	            }
	        }

	        
	        /**
	         *      Write results of current experiment to file for further analysis with R
	         */
	        
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_price_timeseries_E" + e + ".csv").write(tsPricesList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_fundvalues_timeseries_E" + e + ".csv").write(tsFundValuesList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_totalvolume_timeseries_E" + e + ".csv").write(tsTotalVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_fundvolume_timeseries_E" + e + ".csv").write(tsFundVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_trendvolume_timeseries_E" + e + ".csv").write(tsTrendVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_lsvolume_timeseries_E" + e + ".csv").write(tsLSVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_fundorders_timeseries_E" + e + ".csv").write(tsFundTotalOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_trendorders_timeseries_E" + e + ".csv").write(tsTrendTotalOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_lsorders_timeseries_E" + e + ".csv").write(tsLSTotalOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_fundwealth_timeseries_E" + e + ".csv").write(tsFundAvgWealthIncrementList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_trendwealth_timeseries_E" + e + ".csv").write(tsTrendAvgWealthIncrementList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/list_lswealth_timeseries_E" + e + ".csv").write(tsLSAvgWealthIncrementList);
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

        if (numLS > 0) {
        	charts.draw(atcWealthLS_GOOG);
        	charts.draw(atcPosLS_GOOG);
//        	charts.draw(atcWealthLS_MSFT);
//        	charts.draw(atcPosLS_MSFT);
//        	charts.draw(atcWealthLS_IBM);
//        	charts.draw(atcPosLS_IBM);
        	charts.draw(atcSpreads);       
//        	charts.draw(atcSpread_1EN);   // DELETE
//        	charts.draw(atcSpread_1EX);   // DELETE
//        	charts.draw(atcSpread_2EN);   // DELETE
//        	charts.draw(atcSpread_2EX);   // DELETE        	
        }
        
        if (numTrends > 0) {
        	charts.draw(atcWealthTrend_GOOG);
            charts.draw(atcPosTrend_GOOG);
//            charts.draw(atcWealthTrend_MSFT);
//            charts.draw(atcPosTrend_MSFT);
//            charts.draw(atcWealthTrend_IBM);
//            charts.draw(atcPosTrend_IBM);
        }
        
        if (numFunds > 0) {
        	charts.draw(atcWealthFund_GOOG);
            charts.draw(atcPosFund_GOOG);
//            charts.draw(atcWealthFund_MSFT);
//            charts.draw(atcPosFund_MSFT);
//            charts.draw(atcWealthFund_IBM);
//            charts.draw(atcPosFund_IBM);
            charts.draw(atcValues);            
//            charts.draw(atcValuePriceDiff);
//            charts.draw(atcValuePriceDiff_F1);
        }
        
        charts.draw(atcPrices);
//        charts.draw(atcVolumeFund);
//        charts.draw(atcVolumeTrend);
//End comment */
        
      
        /**
         *      Write data on mean positions to R to calculate the normalisation factor of LS investors
         */
//        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/normFactor/list_lsIndicator_divergencestdev_50L50F.csv").write(meanMagnitudeLSIndicator);
//        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/normFactor/list_fundIndicator_divergencestdev_50L50F.csv").write(meanMagnitudeFundIndicator);
//        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/normFactor/list_ratioIndicator_divergencestdev_50L50F.csv").write(ratioMeanMagnitudeIndicator);
//        
//        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/normFactor/list_lsMaxPosition_divergencestdev_50L50F.csv").write(maxAbsLSPosition);
//        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/normFactor/list_fundMaxPosition_divergencestdev_50L50F.csv").write(maxAbsFundPosition);
//        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/normFactor/list_ratioMaxPosition_divergencestdev_50L50F.csv").write(ratioMaxAbsPosition);
//        
//        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/normFactor/list_lsMeanMaxPosition_divergencestdev_50L50F.csv").write(meanMaxAbsLSPosition);
//        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/normFactor/list_fundMeanMaxPosition_divergencestdev_50L50F.csv").write(meanMaxAbsFundPosition);
//        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-abm-simulation/normFactor/list_ratioMeanMaxPosition_divergencestdev_50L50F.csv").write(ratioMeanMaxAbsPosition);
  
        
        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
    }

}
