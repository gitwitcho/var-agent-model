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

import info.financialecology.finance.abm.model.TrendValueLSVarAbmSimulator;
import info.financialecology.finance.abm.model.agent.Trader;
import info.financialecology.finance.abm.model.agent.Trader.UseStressedVar;
import info.financialecology.finance.abm.model.agent.Trader.UseVar;
import info.financialecology.finance.abm.model.agent.Trader.VariabilityVarLimit;
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
import info.financialecology.finance.abm.sandbox.TrendValueLSVarAbmParams;
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
public class TrendValueLSVarMultiAssetAbmSimulation_MiniCascade {

    protected static final String TEST_ID = "TrendValueLSVarMultiAssetAbmSimulation"; 
    
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
        System.out.println("=============================================\n");

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
        
        TrendValueLSVarAbmParams params = TrendValueLSVarAbmParams.readParameters(CmdLineProcessor.process(args));

        /*
         *      PARAMETERS
         */

        int numTicks        = params.nTicks;    // number of ticks per simulation run
        int numRuns         = params.nRuns;     // number of runs per simulation experiment
        int startSeed       = params.seed;      // starting position in the random seed table; -1 for random value (based on internal clock) 
        
        int numTrends       = params.numTrends;    // number of TREND investors
        int numFunds        = params.numFunds;     // number of FUND investors
        int numLS           = params.numLS;        // number of LS investors	
        
        DoubleArrayList price_0      = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.PRICE_0);
        DoubleArrayList liquidity    = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.LIQUIDITY);
        
        double probShortSellingTrend = params.probShortSellingTrend;   // percentage of TRENDs which are allowed to short-sell (between 0 and 1)
        double probShortSellingValue = params.probShortSellingValue;   // percentage of FUNDs which are allowed to short-sell (between 0 and 1)
        
        double probVarTrend = params.probVarTrend;   // percentage of TRENDs which use a VaR system (between 0 and 1)
        double probVarValue = params.probVarFund;    // percentage of FUNDs which use a VaR system (between 0 and 1)
        double probVarLS    = params.probVarLS;      // percentage of LS investors which use a VaR system (between 0 and 1)

        // Parameters for the exogenous price process. The process is an overlay of a Brownian process and a sinus function
        
//        DoubleArrayList shift_price      = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.SHIFT_PRICE);
        DoubleArrayList amplitude_price  = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.AMPLITUDE_PRICE);
        DoubleArrayList lag_price        = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.LAG_PRICE);
        DoubleArrayList lambda_price     = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.LAMBDA_PRICE);
        
        DoubleArrayList mu_price         = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.MU_PRICE);
        DoubleArrayList sigma_price      = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.SIGMA_PRICE);        
                
        // Parameters for the exogenous market-wide fundamental value process. The process is an overlay of a Brownian process and a sinus function
        
//        DoubleArrayList shift_value      = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.SHIFT_VALUE);
        DoubleArrayList amplitude_value  = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.AMPLITUDE_VALUE);
        DoubleArrayList lag_value        = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.LAG_VALUE);
        DoubleArrayList lambda_value     = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.LAMBDA_VALUE);        
        
        DoubleArrayList mu_value         = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.MU_VALUE);
        DoubleArrayList sigma_value      = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.SIGMA_VALUE);
        
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

        TrendValueLSVarAbmSimulator simulator;

        
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
        VersatileTimeSeriesCollection atcWealthTrend_IBM    = new VersatileTimeSeriesCollection("TREND Wealth for IBM");
        VersatileTimeSeriesCollection atcWealthLS_IBM       = new VersatileTimeSeriesCollection("LS Wealth for IBM");
        VersatileTimeSeriesCollection atcPosFund_IBM        = new VersatileTimeSeriesCollection("FUND Positions for IBM");
        VersatileTimeSeriesCollection atcPosTrend_IBM       = new VersatileTimeSeriesCollection("TREND Positions for IBM");
        VersatileTimeSeriesCollection atcPosLS_IBM          = new VersatileTimeSeriesCollection("LS Positions for IBM");

        VersatileTimeSeriesCollection atcOrdersFund_IBM        = new VersatileTimeSeriesCollection("FUND Orders for IBM");
        VersatileTimeSeriesCollection atcOrdersTrend_IBM       = new VersatileTimeSeriesCollection("TREND Orders for IBM");
        VersatileTimeSeriesCollection atcOrdersLS_IBM          = new VersatileTimeSeriesCollection("LS Orders for IBM");

//        VersatileTimeSeriesCollection atcSelloffOrdersFund_IBM    = new VersatileTimeSeriesCollection("FUND sell-off orders for IBM");
//        VersatileTimeSeriesCollection atcSelloffOrdersTrend_IBM   = new VersatileTimeSeriesCollection("TREND sell-off orders for IBM");
//        VersatileTimeSeriesCollection atcSelloffOrdersLS_IBM      = new VersatileTimeSeriesCollection("LS sell-off orders for IBM");
        
        VersatileTimeSeriesCollection atcStrategySalesFund_IBM    = new VersatileTimeSeriesCollection("FUND strategy sales for IBM");
        VersatileTimeSeriesCollection atcStrategySalesTrend_IBM   = new VersatileTimeSeriesCollection("TREND strategy sales for IBM");
        VersatileTimeSeriesCollection atcStrategySalesLS_IBM      = new VersatileTimeSeriesCollection("LS strategy sales for IBM");
        VersatileTimeSeriesCollection atcVarSalesFund_IBM         = new VersatileTimeSeriesCollection("FUND VaR sales for IBM");
        VersatileTimeSeriesCollection atcVarSalesTrend_IBM        = new VersatileTimeSeriesCollection("TREND VaR sales for IBM");
        VersatileTimeSeriesCollection atcVarSalesLS_IBM           = new VersatileTimeSeriesCollection("LS VaR sales for IBM");
        
        VersatileTimeSeriesCollection atcPosReducedFund_IBM    = new VersatileTimeSeriesCollection("FUND reduced positions for IBM");
        VersatileTimeSeriesCollection atcPosReducedTrend_IBM   = new VersatileTimeSeriesCollection("TREND reduced positions for IBM");
        VersatileTimeSeriesCollection atcPosReducedLS_IBM      = new VersatileTimeSeriesCollection("LS reduced positions for IBM");
        
        VersatileTimeSeriesCollection atcPreTradeVarFund       = new VersatileTimeSeriesCollection("FUND VaR - Pre trade");
        VersatileTimeSeriesCollection atcPreTradeVarTrend      = new VersatileTimeSeriesCollection("TREND VaR - Pre trade");
        VersatileTimeSeriesCollection atcPreTradeVarLS         = new VersatileTimeSeriesCollection("LS VaR - Pre trade");
        VersatileTimeSeriesCollection atcPostTradeVarFund      = new VersatileTimeSeriesCollection("FUND VaR - Post trade");
        VersatileTimeSeriesCollection atcPostTradeVarTrend     = new VersatileTimeSeriesCollection("TREND VaR - Post trade");
        VersatileTimeSeriesCollection atcPostTradeVarLS        = new VersatileTimeSeriesCollection("LS VaR - Post trade");
        
        VersatileTimeSeriesCollection atcVarLimitFund          = new VersatileTimeSeriesCollection("FUND VaR limit");
        VersatileTimeSeriesCollection atcVarLimitTrend         = new VersatileTimeSeriesCollection("TREND VaR limit");
        
        // Time series
        
        VersatileTimeSeriesCollection atcPrices             = new VersatileTimeSeriesCollection("Prices for shares");        
        VersatileTimeSeriesCollection atcValues             = new VersatileTimeSeriesCollection("Fundamental values");
        VersatileTimeSeriesCollection atcSpreads            = new VersatileTimeSeriesCollection("Spreads for shares");

        
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
        	
            VariabilityVarLimit variabilityVarLimit = VariabilityVarLimit.CONSTANT;
        	
        	
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
            DoubleTimeSeriesList tsFundReducedVolumeList        = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendReducedVolumeList       = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSReducedVolumeList          = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundReducedOrdersList        = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendReducedOrdersList       = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSReducedOrdersList          = new DoubleTimeSeriesList();
            
//            DoubleTimeSeriesList tsFundSelloffOrdersList        = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsTrendSelloffOrdersList       = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsLSSelloffOrdersList          = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsFundSelloffVolumeList        = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsTrendSelloffVolumeList       = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsLSSelloffVolumeList          = new DoubleTimeSeriesList();
            
            DoubleTimeSeriesList tsFundVarSalesList             = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendVarSalesList            = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSVarSalesList               = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundStrategySalesList        = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendStrategySalesList       = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSStrategySalesList          = new DoubleTimeSeriesList();
            
            DoubleTimeSeriesList tsFundAvgVarList               = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendAvgVarList              = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSAvgVarList                 = new DoubleTimeSeriesList();
        
	        for (int run = 0; run < numRuns; run++) {
	        	
	        	System.out.print("RUN:" + run + "\n");
	                        
	            /*
	             * Setting up the simulator
	             */
	        	
	        	simulator = new TrendValueLSVarAbmSimulator();      // recreating the simulator will also get rid of the old schedule
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
    	
//    	            OverlayDataGenerator fundValues = new OverlayDataGenerator(
//    	                    "FundValue_" + shareIds.get(i), GeneratorType.SINUS, GeneratorType.ARITHMETIC_BROWNIAN_PROCESS, 
//    	                    price_0.get(i), amplitude_value.get(i), lag_value.get(i), lambda_value.get(i), mu_value.get(i), sigma_value.get(i));
 	            
    	            OverlayDataGenerator fundValues = new OverlayDataGenerator(
    	                    "FundValue_" + shareIds.get(i), GeneratorType.STEP, GeneratorType.ARITHMETIC_BROWNIAN_PROCESS, 
    	                    price_0.get(i)+30, -0.0, 3000.0, 1000.0, mu_value.get(i), sigma_value.get(i));

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
	            
	            // Random generator for VaR limit and volatility window
	            RandomDistDataGenerator distVarLimitTrend = new RandomDistDataGenerator("VaR_Limit_Trend", DistributionType.UNIFORM, (double) params.varLimitTrendMin, (double) params.varLimitTrendMax);
//	            RandomDistDataGenerator distVolWindowVarTrend = new RandomDistDataGenerator("Vol_Window_Trend", DistributionType.UNIFORM, (double) params.volWindowVarTrendMin, (double) params.volWindowVarTrendMax);
	            
	            // Uniform distributions U[0,1] to proxy binomial distributions to decide if short-selling is allowed, or VaR is used 
	            RandomDistDataGenerator distUnif01SSTrend = new RandomDistDataGenerator("Unif01_SS_Trend", DistributionType.UNIFORM, 0., 1.);
	            RandomDistDataGenerator distUnif01VarTrend = new RandomDistDataGenerator("Unif01_Var_Trend", DistributionType.UNIFORM, 0., 1.);
	            
	            // Additional parameters - these are identical for all assets
	            MultiplierTrend trendMultiplier = MultiplierTrend.MA_SLOPE_DIFFERENCE;     // Method to calculate the size of the trend positions
	            PositionUpdateTrend positionUpdateTrend = PositionUpdateTrend.VARIABLE;    // Specifies if a position can be modified while open
	            OrderOrPositionStrategyTrend orderOrPositionStrategyTrend = OrderOrPositionStrategyTrend.POSITION;     // Specifies if the strategy is order-based or position-based
	            VariabilityCapFactorTrend variabilityCapFactorTrend = VariabilityCapFactorTrend.CONSTANT;              // Specifies if the capFactor is constant or varies based on the agent performance
	            
	            for (int i = 0; i < trendFollowers.size(); i++) {
	            	// Decide if the trader is allowed to short-sell
	            	ShortSellingTrend shortSellingTrend = ShortSellingTrend.ALLOWED;
	            	if (distUnif01SSTrend.nextDouble() > probShortSellingTrend) 
	            		shortSellingTrend = ShortSellingTrend.NOT_ALLOWED;
	            	
	            	// Create TREND trader
	                for (String secId : shareIds) {
    	            	simulator.addTrendStrategyForOneTrendFollower(secId, "Trend_" + i, (int) Math.round(maShortTicks.get(secId).nextDouble()), 
    	            			(int) Math.round(maLongTicks.get(secId).nextDouble()), (int) Math.round(bcTicksTrend.get(secId).nextDouble()), params.capFactorTrend, 
    	            			params.volWindowStratTrend, trendMultiplier, positionUpdateTrend, orderOrPositionStrategyTrend, 
    	            			variabilityCapFactorTrend, shortSellingTrend);
	                }
	                
	                // Set VaR parameters
	                UseVar useVarTrend = UseVar.TRUE;
	                UseStressedVar useStressedVarTrend = UseStressedVar.FALSE;
	            	if (distUnif01VarTrend.nextDouble() > probVarTrend) 
	            		useVarTrend = UseVar.FALSE;
	            	simulator.getTrendFollowers().get("Trend_" + i).setUseVar(useVarTrend);
	            	simulator.getTrendFollowers().get("Trend_" + i).setUseStressedVar(useStressedVarTrend);
	                simulator.getTrendFollowers().get("Trend_" + i).setVarLimit(distVarLimitTrend.nextDouble());
//	            	simulator.getTrendFollowers().get("Trend_" + i).setVolWindowVar((int) Math.round(distVolWindowVarTrend.nextDouble()));
	                simulator.getTrendFollowers().get("Trend_" + i).setVolWindowVar(45);
	            	simulator.getTrendFollowers().get("Trend_" + i).setVariabilityVarLimit(variabilityVarLimit);
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
                
	            // Random generator for VaR limit and volatility window
	            RandomDistDataGenerator distVarLimitValue = new RandomDistDataGenerator("VaR_Limit_Value", DistributionType.UNIFORM, (double) params.varLimitFundMin, (double) params.varLimitFundMax);
//	            RandomDistDataGenerator distVolWindowVarValue = new RandomDistDataGenerator("Vol_Window_Value", DistributionType.UNIFORM, (double) params.volWindowVarFundMin, (double) params.volWindowVarFundMax);
	            
	            // Uniform distributions U[0,1] to proxy binomial distributions to decide if short-selling is allowed, or VaR is used 
	            RandomDistDataGenerator distUnif01SSValue = new RandomDistDataGenerator("Unif01_SS_Value", DistributionType.UNIFORM, 0., 1.);  // U[0,1] to proxy a binomial distribution to decide if short-selling is allowed
	            RandomDistDataGenerator distUnif01VarValue = new RandomDistDataGenerator("Unif01_Var_Value", DistributionType.UNIFORM, 0., 1.);

                	            
                // Additional parameters - these are identical for all assets
	            PositionUpdateValue positionUpdateValue = PositionUpdateValue.VARIABLE;     // Specifies if a position can be modified while open
	            OrderOrPositionStrategyValue orderOrPositionStrategyValue = OrderOrPositionStrategyValue.POSITION;     // Specifies if the strategy is order-based or position-based
	            VariabilityCapFactorValue variabilityCapFactorValue = VariabilityCapFactorValue.CONSTANT;              // Specifies if the capFactor is constant or varies based on the agent performance
	            	            
	            for (int i = 0; i < valueTraders.size(); i++) {
	            	// Decide if the trader is allowed to short-sell
	            	ShortSellingValue shortSellingValue = ShortSellingValue.ALLOWED;
	            	if (distUnif01SSValue.nextDouble() > probShortSellingValue)
	            		shortSellingValue = ShortSellingValue.NOT_ALLOWED;
	            	
	            	// Create FUND trader
	                for (String secId : shareIds) {	            
    	            	simulator.addValueStrategyForOneValueInvestor(secId, "Value_" + i, entryThreshold.get(secId).nextDouble(), exitThreshold.get(secId).nextDouble(), 
    	            	        valueOffset.get(secId).nextDouble(), (int) Math.round(bcTicksFund.get(secId).nextDouble()), params.capFactorFund, positionUpdateValue, 
    	            	        orderOrPositionStrategyValue, variabilityCapFactorValue, shortSellingValue);
    	            }
	                
	                // Set VaR parameters
	                UseVar useVarValue = UseVar.TRUE;
	                UseStressedVar useStressedVarValue = UseStressedVar.FALSE;
	            	if (distUnif01VarValue.nextDouble() > probVarValue) 
	            		useVarValue = UseVar.FALSE;
	            	simulator.getValueInvestors().get("Value_" + i).setUseVar(useVarValue);
	            	simulator.getValueInvestors().get("Value_" + i).setUseStressedVar(useStressedVarValue);
//	                simulator.getValueInvestors().get("Value_" + i).setVarLimit(distVarLimitValue.nextDouble());
	            	
	            	if (i >= 10 && i < 30) {   // Set discrete VaR limits
	            		simulator.getValueInvestors().get("Value_" + i).setVarLimit(20);
	            	}
	            	else if (i >= 30 && i < 45) {
	            		simulator.getValueInvestors().get("Value_" + i).setVarLimit(40);
	            	}
	            	else {
	            		simulator.getValueInvestors().get("Value_" + i).setVarLimit(52);
	            	}
//	            	simulator.getValueInvestors().get("Value_" + i).setVolWindowVar((int) Math.round(distVolWindowVarValue.nextDouble()));
	            	simulator.getValueInvestors().get("Value_" + i).setVolWindowVar(45);
	            	simulator.getValueInvestors().get("Value_" + i).setVariabilityVarLimit(variabilityVarLimit);
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
                    RandomDistDataGenerator distMaSpreadLongTicks = new RandomDistDataGenerator("maSpreadLongTicks_" + secId, DistributionType.UNIFORM, (double) params.maSpreadLongTicksMin, (double) params.maSpreadLongTicksMax);
                    RandomDistDataGenerator distEntryDivergenceSigmas = new RandomDistDataGenerator("entryDivergenceSigmas_" + secId, DistributionType.UNIFORM, (double) params.entryDivergenceSigmasMin, (double) params.entryDivergenceSigmasMax);
                    RandomDistDataGenerator distExitConvergenceSigmas = new RandomDistDataGenerator("exitConvergenceSigmas_" + secId, DistributionType.UNIFORM, (double) params.exitConvergenceSigmasMin, (double) params.exitConvergenceSigmasMax);
                    RandomDistDataGenerator distExitStopLossSigmas = new RandomDistDataGenerator("exitStopLossSigmas_" + secId, DistributionType.UNIFORM, (double) params.exitStopLossSigmasMin, (double) params.exitStopLossSigmasMax);

                    maSpreadShortTicks.put(secId, distMaSpreadShortTicks);
                    maSpreadLongTicks.put(secId, distMaSpreadLongTicks);
                    entryDivergenceSigmas.put(secId, distEntryDivergenceSigmas);
                    exitConvergenceSigmas.put(secId, distExitConvergenceSigmas);
                    exitStopLossSigmas.put(secId, distExitStopLossSigmas);
                }
                
                // Random generator for VaR limit and volatility window
	            RandomDistDataGenerator distVarLimitLS = new RandomDistDataGenerator("VaR_Limit_LS", DistributionType.UNIFORM, (double) params.varLimitLSMin, (double) params.varLimitLSMax);
//	            RandomDistDataGenerator distVolWindowVarLS = new RandomDistDataGenerator("Vol_Window_LS", DistributionType.UNIFORM, (double) params.volWindowVarLSMin, (double) params.volWindowVarLSMax);
	            
	            // Uniform distributions U[0,1] to proxy binomial distributions to decide if VaR is used
	            RandomDistDataGenerator distUnif01VarLS = new RandomDistDataGenerator("Unif01_Var_LS", DistributionType.UNIFORM, 0., 1.);

	            // Additional parameters - these are identical for all assets
                MultiplierLS LSMultiplier = MultiplierLS.DIVERGENCE;        // Method to calculate the size of the LS positions
	            PositionUpdateLS positionUpdateLS = PositionUpdateLS.VARIABLE;     // Specifies if a position can be modified while open, !![25 Mar 2015] 'CONSTANT' will not work well
	            
	            for (int i = 0; i < LSTraders.size(); i++) {
	            	for (int j = 1; j < numAssets; j++) {  // Add an LS strategy for each spread, where Spread = P_0 - P_j         
    	            	simulator.addLSStrategyForOneLSInvestor(shareIds.get(0), shareIds.get(j), "LS_" + i, 
    	            			(int) Math.round(maSpreadShortTicks.get(shareIds.get(j)).nextDouble()),
    	            			(int) Math.round(maSpreadLongTicks.get(shareIds.get(j)).nextDouble()),
    	            			params.volWindowStratLS, entryDivergenceSigmas.get(shareIds.get(j)).nextDouble(), exitConvergenceSigmas.get(shareIds.get(j)).nextDouble(),
    	            			exitStopLossSigmas.get(shareIds.get(j)).nextDouble(), params.capFactorLS, LSMultiplier, positionUpdateLS);
    	            }
	            	
	            	// Set VaR parameters
	                UseVar useVarLS = UseVar.TRUE;
	                UseStressedVar useStressedVarLS = UseStressedVar.FALSE;
	            	if (distUnif01VarLS.nextDouble() > probVarLS) 
	            		useVarLS = UseVar.FALSE;
	            	simulator.getLSInvestors().get("LS_" + i).setUseVar(useVarLS);
	            	simulator.getLSInvestors().get("LS_" + i).setUseStressedVar(useStressedVarLS);
	                simulator.getLSInvestors().get("LS_" + i).setVarLimit(distVarLimitLS.nextDouble());
//	                simulator.getLSInvestors().get("LS_" + i).setVolWindowVar((int) Math.round(distVolWindowVarLS.nextDouble()));
	                simulator.getLSInvestors().get("LS_" + i).setVolWindowVar(45);
	                simulator.getLSInvestors().get("LS_" + i).setVariabilityVarLimit(variabilityVarLimit);
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
	            // Create time series for charts - IBM
	            	
		        for (int tr = 0; tr < numTrends; tr=tr+5) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
		        	int trendID = tr;
		        	DoubleTimeSeries positions_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM");
		        	DoubleTimeSeries positionsReduced_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolioReductions().getTsPosition("IBM");
		        	
		        	DoubleTimeSeries orders_IBM = new DoubleTimeSeries();
		        	orders_IBM.add(0, simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM").get(0));  // Order at t=0
		        	for (int i = 1; i < numTicks; i++) {
		        		orders_IBM.add(i,  simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM").get(i) - simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM").get(i-1));
		        	}
		        	
//		        	DoubleTimeSeries selloffOrders_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getTsSelloff().get("IBM");   // Sell-off orders due to VaR
//		        	DoubleTimeSeries varSales_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getTsVarSales().get("IBM");   // Short orders due to VaR
//		        	DoubleTimeSeries strategySales_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getTsStrategySales().get("IBM");   // Short orders due to the trading strategy
		        		                
	        		atcPosTrend_IBM.populateSeries(e, run, "IBM", "pos_T_" + tr, positions_IBM);
					atcPosReducedTrend_IBM.populateSeries(e, run, "IBM", "pos_Red_T_" + tr, positionsReduced_IBM);
					atcOrdersTrend_IBM.populateSeries(e, run, "IBM", "orders_T_" + tr, orders_IBM);
//					atcSelloffOrdersTrend_IBM.populateSeries(e, run, "IBM", "selloff_T_" + tr, selloffOrders_IBM);
//					atcVarSalesTrend_IBM.populateSeries(e, run, "IBM", "varSales_T_" + tr, varSales_IBM);
//					atcStrategySalesTrend_IBM.populateSeries(e, run, "IBM", "stratSales_T_" + tr, strategySales_IBM);
	        		atcWealthTrend_IBM.populateSeries(e, run, "IBM", "wealth_T_" + tr, StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), positions_IBM));
		        }

		        for (int val = 0; val < numFunds; val=val+5) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
		        	int valueID = val;
		        	DoubleTimeSeries positions_IBM = simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM");
		        	DoubleTimeSeries positionsReduced_IBM = simulator.getValueInvestors().get("Value_" + valueID).getPortfolioReductions().getTsPosition("IBM");
		        	
		        	DoubleTimeSeries orders_IBM = new DoubleTimeSeries();
		        	orders_IBM.add(0, simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM").get(0));  // Order at t=0
		        	for (int i = 1; i < numTicks; i++) {
		        		orders_IBM.add(i,  simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM").get(i) - simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM").get(i-1));
		        	}
		        	
//		        	DoubleTimeSeries selloffOrders_IBM = simulator.getValueInvestors().get("Value_" + valueID).getTsSelloff().get("IBM");   // Sell-off orders due to VaR
//		        	DoubleTimeSeries varSales_IBM = simulator.getValueInvestors().get("Value_" + valueID).getTsVarSales().get("IBM");   // Short orders due to VaR
//		        	DoubleTimeSeries strategySales_IBM = simulator.getValueInvestors().get("Value_" + valueID).getTsStrategySales().get("IBM");   // Short orders due to the trading strategy

	        		atcPosFund_IBM.populateSeries(e, run, "IBM", "pos_F_" + val, positions_IBM);
	        		atcPosReducedFund_IBM.populateSeries(e, run, "IBM", "pos_Red_F_" + val, positionsReduced_IBM);
					atcOrdersFund_IBM.populateSeries(e, run, "IBM", "orders_F_" + val, orders_IBM);
//					atcSelloffOrdersFund_IBM.populateSeries(e, run, "IBM", "selloff_F_" + val, selloffOrders_IBM);
//					atcVarSalesFund_IBM.populateSeries(e, run, "IBM", "varSales_F_" + val, varSales_IBM);
//					atcStrategySalesFund_IBM.populateSeries(e, run, "IBM", "stratSales_F_" + val, strategySales_IBM);
	        		atcWealthFund_IBM.populateSeries(e, run, "IBM", "wealth_F_" + val, StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), positions_IBM));
		        }

		        for (int ls = 0; ls < numLS/10; ls++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
		        	int lsID = ls;
		        	DoubleTimeSeries positions_IBM = simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("IBM");
		        	DoubleTimeSeries positionsReduced_IBM = simulator.getLSInvestors().get("LS_" + lsID).getPortfolioReductions().getTsPosition("IBM");

		        	DoubleTimeSeries orders_IBM = new DoubleTimeSeries();		        	
		        	orders_IBM.add(0, simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("IBM").get(0));  // Order at t=0
		        	for (int i = 1; i < numTicks; i++) {
		        		orders_IBM.add(i,  simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("IBM").get(i) - simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("IBM").get(i-1));
		        	}
		        	
//		        	DoubleTimeSeries selloffOrders_IBM = simulator.getLSInvestors().get("LS_" + lsID).getTsSelloff().get("IBM");   // Sell-off orders due to VaR
//		        	DoubleTimeSeries varSales_IBM = simulator.getLSInvestors().get("LS_" + lsID).getTsVarSales().get("IBM");   // Short orders due to VaR
//		        	DoubleTimeSeries strategySales_IBM = simulator.getLSInvestors().get("LS_" + lsID).getTsStrategySales().get("IBM");   // Short orders due to the trading strategy

	        		atcPosLS_IBM.populateSeries(e, run, "IBM", "pos_LS_" + ls, positions_IBM);
	        		atcPosReducedLS_IBM.populateSeries(e, run, "IBM", "pos_Red_LS_" + ls, positionsReduced_IBM);
					atcOrdersLS_IBM.populateSeries(e, run, "IBM", "orders_LS_" + ls, orders_IBM);
//					atcSelloffOrdersLS_IBM.populateSeries(e, run, "IBM", "selloff_LS_" + ls, selloffOrders_IBM);
//					atcVarSalesLS_IBM.populateSeries(e, run, "IBM", "varSales_LS_" + ls, varSales_IBM);
//					atcStrategySalesLS_IBM.populateSeries(e, run, "IBM", "stratSales_LS_" + ls, strategySales_IBM);
		      		atcWealthLS_IBM.populateSeries(e, run, "IBM", "wealth_LS_" + ls, StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), positions_IBM));
		        }
		        
		        atcPrices.populateSeries(e, run, "IBM", "P", simulator.getPrices("IBM"));
		        atcPrices.populateSeries(e, run, "IBM", "V", simulator.getFundValues("IBM"));   // DELETE
	            atcValues.populateSeries(e, run, "IBM", "V", simulator.getFundValues("IBM"));
	            
	            
	            // Create time series for charts - VaR
            	
		        for (int tr = 0; tr < numTrends; tr=tr+5) {  // Plot only a sample of time series to avoid memory problems in graphics
		        	int trendID = tr;
		        	DoubleTimeSeries preTradeVar = simulator.getTrendFollowers().get("Trend_" + trendID).getTsVarPreTrade();
		        	DoubleTimeSeries postTradeVar = simulator.getTrendFollowers().get("Trend_" + trendID).getTsVarPostTrade();
		        	
		        	atcPreTradeVarTrend.populateSeries(e, run, "preVar_T_" + tr, preTradeVar);
	        		atcPostTradeVarTrend.populateSeries(e, run, "postVar_T_" + tr, postTradeVar);
	        		
	        		atcVarLimitTrend.populateSeries(e, run, "LVar_T_" + tr, simulator.getTrendFollowers().get("Trend_" + trendID).getTsVarLimit());
		        }
		        
		        for (int va = 0; va < numFunds; va=va+5) {  // Plot only a sample of time series to avoid memory problems in graphics
		        	int valueID = va;
		        	DoubleTimeSeries preTradeVar = simulator.getValueInvestors().get("Value_" + valueID).getTsVarPreTrade();
		        	DoubleTimeSeries postTradeVar = simulator.getValueInvestors().get("Value_" + valueID).getTsVarPostTrade();
		        		                
		        	atcPreTradeVarFund.populateSeries(e, run, "preVar_F_" + va, preTradeVar);
	        		atcPostTradeVarFund.populateSeries(e, run, "postVar_F_" + va, postTradeVar);
	        		
	        		atcVarLimitFund.populateSeries(e, run, "LVar_F_" + va, simulator.getValueInvestors().get("Value_" + valueID).getTsVarLimit());
		        }
		        
//		        for (int ls = 0; ls < numLS/10; ls++) {  // Plot only a sample of time series to avoid memory problems in graphics
//		        	int lsID = ls;
//		            DoubleTimeSeries preTradeVar = simulator.getLSInvestors().get("LS_" + lsID).getTsVarPreTrade();
//		        	DoubleTimeSeries postTradeVar = simulator.getLSInvestors().get("LS_" + lsID).getTsVarPostTrade();
//		        		                
//		            atcPreTradeVarLS.populateSeries(e, run, "preVar_LS_" + ls, preTradeVar);
//	        		atcPostTradeVarLS.populateSeries(e, run, "postVar_LS_" + ls, postTradeVar);
//		        }
		        
//End comment */
                   
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
	            	tsFundReducedVolumeList.add(shareIndex + run*numAssets, simulator.getFundReducedVolume(secId));      // time series list of FUND volume reduced due to VaR [(nRuns * nAssets) x nTicks]
	            	tsTrendReducedVolumeList.add(shareIndex + run*numAssets, simulator.getTrendReducedVolume(secId));    // time series list of TREND volume reduced due to VaR [(nRuns * nAssets) x nTicks]
	            	tsLSReducedVolumeList.add(shareIndex + run*numAssets, simulator.getLSReducedVolume(secId));          // time series list of LS volume reduced due to VaR [(nRuns * nAssets) x nTicks]
	            	tsFundReducedOrdersList.add(shareIndex + run*numAssets, simulator.getFundTotalReducedOrders(secId));      // time series list of FUND reduction orders due to VaR [(nRuns * nAssets) x nTicks]
	            	tsTrendReducedOrdersList.add(shareIndex + run*numAssets, simulator.getTrendTotalReducedOrders(secId));    // time series list of TREND reduction orders due to VaR [(nRuns * nAssets) x nTicks]
	            	tsLSReducedOrdersList.add(shareIndex + run*numAssets, simulator.getLSTotalReducedOrders(secId));          // time series list of LS reduction orders due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsFundSelloffOrdersList.add(shareIndex + run*numAssets, simulator.getFundTotalSelloffOrders(secId));      // time series list of FUND sell-off orders due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsTrendSelloffOrdersList.add(shareIndex + run*numAssets, simulator.getTrendTotalSelloffOrders(secId));    // time series list of TREND sell-off orders due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsLSSelloffOrdersList.add(shareIndex + run*numAssets, simulator.getLSTotalSelloffOrders(secId));          // time series list of LS sell-off orders due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsFundSelloffVolumeList.add(shareIndex + run*numAssets, simulator.getFundSelloffVolume(secId));           // time series list of FUND sell-off volume due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsTrendSelloffVolumeList.add(shareIndex + run*numAssets, simulator.getTrendSelloffVolume(secId));         // time series list of TREND sell-off volume due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsLSSelloffVolumeList.add(shareIndex + run*numAssets, simulator.getLSSelloffVolume(secId));               // time series list of LS sell-off volume due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsFundVarSalesList.add(shareIndex + run*numAssets, simulator.getFundTotalVarSales(secId));                // time series list of FUND short orders due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsTrendVarSalesList.add(shareIndex + run*numAssets, simulator.getTrendTotalVarSales(secId));              // time series list of TREND short orders due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsLSVarSalesList.add(shareIndex + run*numAssets, simulator.getLSTotalVarSales(secId));                    // time series list of LS short orders due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsFundStrategySalesList.add(shareIndex + run*numAssets, simulator.getFundTotalStrategySales(secId));      // time series list of FUND short orders due to trading strategy [(nRuns * nAssets) x nTicks]
//	            	tsTrendStrategySalesList.add(shareIndex + run*numAssets, simulator.getTrendTotalStrategySales(secId));    // time series list of TREND short orders due to trading strategy [(nRuns * nAssets) x nTicks]
//	            	tsLSStrategySalesList.add(shareIndex + run*numAssets, simulator.getLSTotalStrategySales(secId));          // time series list of LS short orders due to trading strategy [(nRuns * nAssets) x nTicks]
	            }
	            
	            
	            tsFundAvgVarList.add(run, simulator.getFundAvgVaR());      // time series list of FUND avg VaR [nRuns x nTicks] (post trade)
	            tsTrendAvgVarList.add(run, simulator.getTrendAvgVaR());    // time series list of TREND avg VaR [nRuns x nTicks] (post trade)
	            tsLSAvgVarList.add(run, simulator.getLSAvgVaR());          // time series list of LS avg VaR [nRuns x nTicks] (post trade)
	        }

	        
	        /**
	         *      Write results of current experiment to file for further analysis with R
	         */
	        
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_price_timeseries_E" + e + ".csv").write(tsPricesList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundvalues_timeseries_E" + e + ".csv").write(tsFundValuesList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_totalvolume_timeseries_E" + e + ".csv").write(tsTotalVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundvolume_timeseries_E" + e + ".csv").write(tsFundVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendvolume_timeseries_E" + e + ".csv").write(tsTrendVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsvolume_timeseries_E" + e + ".csv").write(tsLSVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundorders_timeseries_E" + e + ".csv").write(tsFundTotalOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendorders_timeseries_E" + e + ".csv").write(tsTrendTotalOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsorders_timeseries_E" + e + ".csv").write(tsLSTotalOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundwealth_timeseries_E" + e + ".csv").write(tsFundAvgWealthIncrementList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendwealth_timeseries_E" + e + ".csv").write(tsTrendAvgWealthIncrementList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lswealth_timeseries_E" + e + ".csv").write(tsLSAvgWealthIncrementList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundreducedvolume_timeseries_E" + e + ".csv").write(tsFundReducedVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendreducedvolume_timeseries_E" + e + ".csv").write(tsTrendReducedVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsreducedvolume_timeseries_E" + e + ".csv").write(tsLSReducedVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundreducedorders_timeseries_E" + e + ".csv").write(tsFundReducedOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendreducedorders_timeseries_E" + e + ".csv").write(tsTrendReducedOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsreducedorders_timeseries_E" + e + ".csv").write(tsLSReducedOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundsellofforders_timeseries_E" + e + ".csv").write(tsFundSelloffOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendsellofforders_timeseries_E" + e + ".csv").write(tsTrendSelloffOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lssellofforders_timeseries_E" + e + ".csv").write(tsLSSelloffOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundselloffvolume_timeseries_E" + e + ".csv").write(tsFundSelloffVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendselloffvolume_timeseries_E" + e + ".csv").write(tsTrendSelloffVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsselloffvolume_timeseries_E" + e + ".csv").write(tsLSSelloffVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundvarsales_timeseries_E" + e + ".csv").write(tsFundVarSalesList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendvarsales_timeseries_E" + e + ".csv").write(tsTrendVarSalesList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsvarsales_timeseries_E" + e + ".csv").write(tsLSVarSalesList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundstrategysales_timeseries_E" + e + ".csv").write(tsFundStrategySalesList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendstrategysales_timeseries_E" + e + ".csv").write(tsTrendStrategySalesList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsstrategysales_timeseries_E" + e + ".csv").write(tsLSStrategySalesList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundvar_timeseries_E" + e + ".csv").write(tsFundAvgVarList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendvar_timeseries_E" + e + ".csv").write(tsTrendAvgVarList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsvar_timeseries_E" + e + ".csv").write(tsLSAvgVarList);
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
        if (numLS > 0) {
//        	charts.draw(atcWealthLS_IBM);
//        	charts.draw(atcPosLS_IBM);
//        	charts.draw(atcPosReducedLS_IBM);
//        	charts.draw(atcOrdersLS_IBM);
//        	charts.draw(atcSelloffOrdersLS_IBM);
        	charts.draw(atcVarSalesLS_IBM);
//        	charts.draw(atcStrategySalesLS_IBM);
        	charts.draw(atcSpreads);
        	charts.draw(atcPreTradeVarLS);
        	charts.draw(atcPostTradeVarLS);
        }
        
        if (numTrends > 0) {
//            charts.draw(atcWealthTrend_IBM);
            charts.draw(atcPosTrend_IBM);
            charts.draw(atcPosReducedTrend_IBM);
        	charts.draw(atcOrdersTrend_IBM);
//        	charts.draw(atcSelloffOrdersTrend_IBM);
//        	charts.draw(atcVarSalesTrend_IBM);
//        	charts.draw(atcStrategySalesTrend_IBM);
        	charts.draw(atcPreTradeVarTrend);
            charts.draw(atcPostTradeVarTrend);
            charts.draw(atcVarLimitTrend);
        }
        
        if (numFunds > 0) {
            charts.draw(atcWealthFund_IBM);
            charts.draw(atcPosFund_IBM);
            charts.draw(atcPosReducedFund_IBM);
        	charts.draw(atcOrdersFund_IBM);
//        	charts.draw(atcSelloffOrdersFund_IBM);
//        	charts.draw(atcVarSalesFund_IBM);
//        	charts.draw(atcStrategySalesFund_IBM);
            charts.draw(atcValues);            
            charts.draw(atcPreTradeVarFund);
            charts.draw(atcPostTradeVarFund);
            charts.draw(atcVarLimitFund);
        }
        
        charts.draw(atcPrices);
//End comment */
       
        
        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
    }

}
