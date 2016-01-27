/*
 * Copyright (c) 2011-2014 Gilbert Peffer, B�rbara Llacay
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
import java.util.HashMap;

import info.financialecology.finance.abm.model.TrendValueAbmSimulator;
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
 * @author Gilbert Peffer, B�rbara Llacay
 */
public class TrendValueSingleAssetAbmSimulation {

    protected static final String TEST_ID = "TrendValueSingleAssetAbmSimulation"; 
    
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
        

        /*
         * Read parameters from file
         * 
         * To write a new parameter file template, uncomment the following two lines
         *      TrendAbmParams.writeParamDefinition("param_template.xml");
         *      System.exit(0);
         * 
         */
        
        TrendValueAbmParams params = TrendValueAbmParams.readParameters(CmdLineProcessor.process(args));

        /*
         *      PARAMETERS
         */

        int numTicks        = params.nTicks;   // number of ticks per simulation run
        int numRuns         = params.nRuns;    // number of runs per simulation experiment
        int startSeed       = params.seed;     // starting position in the random seed table; -1 for random value (based on internal clock) 
        
        int numTrends       = params.numTrends;    // number of TREND investors
        int numFunds        = params.numFunds;     // number of FUND investors
        
        double price_0      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.PRICE_0).get(0);
        double liquidity    = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LIQUIDITY).get(0);

        //  Parameters for the exogenous price process. The process is an overlay of a Brownian process and a sinus function
        
        double shift_price      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SHIFT_PRICE).get(0);
        double amplitude_price  = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.AMPLITUDE_PRICE).get(0);
        double lag_price        = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAG_PRICE).get(0);
        double lambda_price     = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAMBDA_PRICE).get(0);
        
        double mu_price         = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.MU_PRICE).get(0);
        double sigma_price      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SIGMA_PRICE).get(0);
//        double sigma_price_2    = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SIGMA_PRICE).get(1).get(0);  // TODO: Polish this
                
        // Parameters for the exogenous market-wide fundamental value process. The process is an overlay of a Brownian process and a sinus function
        
        double shift_value      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SHIFT_VALUE).get(0);
        double amplitude_value  = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.AMPLITUDE_VALUE).get(0);
        double lag_value        = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAG_VALUE).get(0);
        double lambda_value     = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAMBDA_VALUE).get(0);        
        
        double mu_value         = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.MU_VALUE).get(0);
        double sigma_value      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SIGMA_VALUE).get(0);
        
        // Parameters for the TREND strategy
        
        int maShortTicksMin    = params.maShortTicksMin;
        int maShortTicksMax    = params.maShortTicksMax;
        int maLongTicksMin     = params.maLongTicksMin;
        int maLongTicksMax     = params.maLongTicksMax;
        int bcTicksTrendMin    = params.bcTicksTrendMin;
        int bcTicksTrendMax    = params.bcTicksTrendMax;
        
        // Parameters for the FUND strategy
        
        double entryThresholdMin  = params.entryThresholdMin;
        double entryThresholdMax  = params.entryThresholdMax;
        double exitThresholdMin   = params.exitThresholdMin;
        double exitThresholdMax   = params.exitThresholdMax;
        double valueOffset        = params.valueOffset;
        

        // ---------------------------------------------------------------------------------------------------------------
    
        
        // ----- Values of parameters for experiments ----- //

        int numExp = 1;   // TODO - Delete when this is automatically extracted from the sequences in the param file
        
        double sigma_priceMin = sigma_price;              // Experiments for sigma_price
        double sigma_priceMax = sigma_price + 1;

        int numTrendsMin = numTrends;                     // Experiments for numTrends + numFunds
        int numTrendsMax = 400;
        int numFundsMin = 0;
        int numFundsMax = numFunds;
        
        // vector of random seeds where the price in runs with nFunds=400 does not oscillate
//        int randomSeedVector[] = {701, 704, 705, 706, 710, 711, 712, 713, 716, 718, 719, 724, 725, 729, 730, 732, 733, 737, 739, 742, 743, 745, 747, 750, 751};
        
        int maShortTicksMinMin = maShortTicksMin;         // Experiments for TREND short-term MA window
        int maShortTicksMinMax = maShortTicksMin + 20;
        int maShortTicksMaxMin = maShortTicksMax;
        int maShortTicksMaxMax = maShortTicksMax + 20;
        
        int maLongTicksMinMin = maLongTicksMin;           // Experiments for TREND long-term MA window
        int maLongTicksMinMax = maLongTicksMin + 50;
        int maLongTicksMaxMin = maLongTicksMax;
        int maLongTicksMaxMax = maLongTicksMax + 50;
        
        int bcTicksTrendMinMin = bcTicksTrendMin;         // Experiments for TREND exit channel length
        int bcTicksTrendMinMax = bcTicksTrendMin + 80;
        int bcTicksTrendMaxMin = bcTicksTrendMax;
        int bcTicksTrendMaxMax = bcTicksTrendMax + 80;
        
        double entryThresholdMinMin = entryThresholdMin;  // Experiments for FUND entry threshold
        double entryThresholdMinMax = entryThresholdMin + 24;        
        double entryThresholdMaxMin = entryThresholdMax;
        double entryThresholdMaxMax = entryThresholdMax + 24;
        
        double exitThresholdMinMin = exitThresholdMin;    // Experiments for FUND exit threshold
        double exitThresholdMinMax = exitThresholdMin + 4;        
        double exitThresholdMaxMin = exitThresholdMax;
        double exitThresholdMaxMax = exitThresholdMax + 4;

        double valueOffsetMin = valueOffset;              // Experiments for FUND value offset
        double valueOffsetMax = valueOffsetMin + 32;        

        double sigma_valueMin = sigma_value;              // Experiments for sigma_price
        double sigma_valueMax = sigma_value + 1.2;

        
        // ------------------------------------------------ //
        
        TrendValueAbmSimulator simulator;
        
        
        /*
         *      OUTPUT VARIABLES
         */
        
        // Variables for charts
        
        VersatileChart charts = new VersatileChart();
        charts.getInternalParms().autoRange = true;
        charts.getInternalParms().autoRangePadding = 0;
        charts.getInternalParms().ticks = true;
        
//        VersatileChart histogram = new VersatileChart();  // Trying to implement an histogram
//        histogram.getInternalParms().numBins = 20;
        
        // Time series
        
        VersatileTimeSeriesCollection atcWealthTrend    = new VersatileTimeSeriesCollection("TREND Wealth");
        VersatileTimeSeriesCollection atcPosTrend       = new VersatileTimeSeriesCollection("TREND Positions");
        VersatileTimeSeriesCollection atcWealthFund     = new VersatileTimeSeriesCollection("FUND Wealth");
        VersatileTimeSeriesCollection atcPosFund        = new VersatileTimeSeriesCollection("FUND Positions");
        VersatileTimeSeriesCollection atcPrice          = new VersatileTimeSeriesCollection("Prices for sigma");
        VersatileTimeSeriesCollection atcValue          = new VersatileTimeSeriesCollection("Fundamental Values");
        VersatileTimeSeriesCollection atcVolumeFund     = new VersatileTimeSeriesCollection("FUND Volume");
        VersatileTimeSeriesCollection atcVolumeTrend    = new VersatileTimeSeriesCollection("TREND Volume");
        VersatileTimeSeriesCollection atcValuePriceDiff = new VersatileTimeSeriesCollection("Value-Price Difference"); 
        VersatileTimeSeriesCollection atcValuePriceDiff_F1 = new VersatileTimeSeriesCollection("Value-Price Difference of FUND_1");
                
        
        // Variables for manual calculation of normalising factor of FUND and TREND positions        
        
//        DoubleArrayList meanMagnitudeFundIndicator  = new DoubleArrayList();
//        DoubleArrayList meanMagnitudeTrendIndicator = new DoubleArrayList();
//        DoubleArrayList ratioMeanMagnitudeIndicator = new DoubleArrayList();
//        
//        DoubleArrayList maxAbsFundPosition  = new DoubleArrayList();
//        DoubleArrayList maxAbsTrendPosition = new DoubleArrayList();
//        DoubleArrayList ratioMaxAbsPosition = new DoubleArrayList();
//        
//        DoubleArrayList meanMaxAbsFundPosition  = new DoubleArrayList();
//        DoubleArrayList meanMaxAbsTrendPosition = new DoubleArrayList();
//        DoubleArrayList ratioMeanMaxAbsPosition = new DoubleArrayList();
                
        
        // Variables for extracting data to R for each experiment - TODO: Delete when VersatileTimeSeriesCollection works well in CsvResultWriter
        
        DoubleTimeSeriesList tsPricesList            = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsFundValuesList        = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsTotalVolumeList       = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsFundVolumeList        = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsTrendVolumeList       = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsFundTotalOrdersList   = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsTrendTotalOrdersList  = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsTrendAvgWealthIncrementList  = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsFundAvgWealthIncrementList   = new DoubleTimeSeriesList();
        
        
       // Variables for VVUQ tests
        
//      double meanPrice = 0;
//      double stdDevPrice = 0;

        
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
            if (numExp == 1) {
                numTrends = numTrendsMin;
            	numFunds = numFundsMax;
            	
            	sigma_price = sigma_priceMin;
            	sigma_value = sigma_valueMin;
            	
        	    entryThresholdMin = entryThresholdMinMin;
        	    entryThresholdMax = entryThresholdMaxMin;        	    
        	    exitThresholdMin = exitThresholdMinMin;
        	    exitThresholdMax = exitThresholdMaxMin;
        	    valueOffset = valueOffsetMin;
        	    
        	    maShortTicksMin = maShortTicksMinMin;
        	    maShortTicksMax = maShortTicksMaxMin;
        	    maLongTicksMin = maLongTicksMinMin;
        	    maLongTicksMax = maLongTicksMaxMin;
        	    bcTicksTrendMin = bcTicksTrendMinMin;
        	    bcTicksTrendMax = bcTicksTrendMaxMin;
            }
            
            else {        	    
//            	numTrends = numTrendsMin + e * (numTrendsMax - numTrendsMin) / (numExp - 1);
//            	numFunds = numFundsMax - e * (numFundsMax - numFundsMin) / (numExp - 1);
            	
//              sigma_price = sigma_priceMin + e * (sigma_priceMax - sigma_priceMin) / (numExp - 1);
            	
//              sigma_value = sigma_valueMin + e * (sigma_valueMax - sigma_valueMin) / (numExp - 1);
        	    
//        	    entryThresholdMin = entryThresholdMinMin + e * (entryThresholdMinMax - entryThresholdMinMin) / (numExp - 1);
//        	    entryThresholdMax = entryThresholdMaxMin + e * (entryThresholdMaxMax - entryThresholdMaxMin) / (numExp - 1);
        	    
//        	    exitThresholdMin = exitThresholdMinMin + e * (exitThresholdMinMax - exitThresholdMinMin) / (numExp - 1);
//        	    exitThresholdMax = exitThresholdMaxMin + e * (exitThresholdMaxMax - exitThresholdMaxMin) / (numExp - 1);
        	    
//        	    valueOffset = valueOffsetMin + e * (valueOffsetMax - valueOffsetMin) / (numExp - 1);

//        	    maShortTicksMin = maShortTicksMinMin + e * (maShortTicksMinMax - maShortTicksMinMin) / (numExp - 1);
//        	    maShortTicksMax = maShortTicksMaxMin + e * (maShortTicksMaxMax - maShortTicksMaxMin) / (numExp - 1);

//        	    maLongTicksMin = maLongTicksMinMin + e * (maLongTicksMinMax - maLongTicksMinMin) / (numExp - 1);
//        	    maLongTicksMax = maLongTicksMaxMin + e * (maLongTicksMaxMax - maLongTicksMaxMin) / (numExp - 1);
        	    
//        	    bcTicksTrendMin = bcTicksTrendMinMin + e * (bcTicksTrendMinMax - bcTicksTrendMinMin) / (numExp - 1);
//        	    bcTicksTrendMax = bcTicksTrendMaxMin + e * (bcTicksTrendMaxMax - bcTicksTrendMaxMin) / (numExp - 1);
            }
            
            
            /*
             * Variables for extracting data to R for each experiment - TODO: Delete when VersatileTimeSeriesCollection works well in CsvResultWriter
             */
            
            tsPricesList                   = new DoubleTimeSeriesList();
            tsFundValuesList               = new DoubleTimeSeriesList();
            tsTotalVolumeList              = new DoubleTimeSeriesList();
            tsFundVolumeList               = new DoubleTimeSeriesList();
            tsTrendVolumeList              = new DoubleTimeSeriesList();
            tsFundTotalOrdersList          = new DoubleTimeSeriesList();
            tsTrendTotalOrdersList         = new DoubleTimeSeriesList();
            tsTrendAvgWealthIncrementList  = new DoubleTimeSeriesList();
            tsFundAvgWealthIncrementList   = new DoubleTimeSeriesList();            

        
	        for (int run = 0; run < numRuns; run++) {
	        	
	        	System.out.print("RUN:" + run + "\n");
	        	System.out.print("sigma_price = " + sigma_price + " / sigma_value = " + sigma_value + "\n");
	        	System.out.print("numTrends = " + numTrends + " / numFunds = " + numFunds + "\n");
	        	System.out.print("maShortTicksMin = " + maShortTicksMin + " / maShortTicksMax = " + maShortTicksMax + "\n");
	        	System.out.print("maLongTicksMin = " + maLongTicksMin + " / maLongTicksMax = " + maLongTicksMax + "\n");
	        	System.out.print("bcTicksTrendMin = " + bcTicksTrendMin + " / bcTicksTrendMax = " + bcTicksTrendMax + "\n");
	        	System.out.print("entryMin = " + entryThresholdMin + " / entryMax = " + entryThresholdMax + "\n");
	        	System.out.print("exitMin = " + exitThresholdMin + " / exitMax = " + exitThresholdMax + "\n");
	        	System.out.print("offset = " + valueOffset + "\n");
	                        
	            /*
	             * Setting up the simulator
	             */
	        	simulator = new TrendValueAbmSimulator();      // recreating the simulator will also get rid of the old schedule
//	            simulator.resetWorldClock(); MOVED TO THE SIMULATOR
	            simulator.addShares("IBM");
	            simulator.getMarketMaker().setInitPrice("IBM", price_0);
	            simulator.getMarket().setInitLogReturn("IBM", 0);
	            simulator.getMarket().setInitValue("IBM", price_0);
	            simulator.getMarket().setLiquidity("IBM", liquidity);
	            simulator.createTrendFollowers(numTrends);
	            simulator.createValueInvestors(numFunds);
	            
	            
	            /*
	             * Setting up the data generators
	             */
	            
	            if (startSeed < 0)
	                RandomGeneratorPool.configureGeneratorPool();
	            else
	                RandomGeneratorPool.configureGeneratorPool(startSeed+run);
	            	//RandomGeneratorPool.configureGeneratorPool(randomSeedVector[run]);
	
	            OverlayDataGenerator prices = new OverlayDataGenerator(
	                    "Price", GeneratorType.SINUS, GeneratorType.ARITHMETIC_BROWNIAN_PROCESS, 
	                    price_0, amplitude_price, lag_price, lambda_price, mu_price, sigma_price);
	            
	            OverlayDataGenerator fundValues = new OverlayDataGenerator(
	                    "FundValue", GeneratorType.SINUS, GeneratorType.ARITHMETIC_BROWNIAN_PROCESS, 
	                    price_0, amplitude_value, lag_value, lambda_value, mu_value, sigma_value);
          
	            simulator.setExogeneousPriceProcess("IBM", prices);
	            simulator.setFundamentalValueProcess("IBM", fundValues);
	
	            
	            /* ***************************************
	             *
	             * Set up the trend strategies. 
	             * The moving average ranges and exit channel are randomised.
	             * 
	             *****************************************/
	            
//	            simulator.addTrendStrategyForAllTraders("IBM", params.maShortTicks, params.maLongTicks, params.bcTicks, params.capFactorTrend, params.volWindowTrend, Multiplier.MA_SLOPE_DIFFERENCE_STDDEV, params.normPeriod);  // DEPRECATED - normPeriod is no longer used
//	            simulator.addTrendStrategyForAllTraders("IBM", params.maShortTicks, params.maLongTicks, params.bcTicks, params.capFactorTrend, params.volWindowTrend, Multiplier.MA_SLOPE_DIFFERENCE_STDDEV, positionUpdateTrend);
	            
	            HashMap<String, Trader> trendFollowers = simulator.getTrendFollowers();
	            
	            // Randomising
	            RandomDistDataGenerator distMaShortTicks    = new RandomDistDataGenerator("MA_Short", DistributionType.UNIFORM, (double) maShortTicksMin, (double) maShortTicksMax);
	            RandomDistDataGenerator distMaLongTicks     = new RandomDistDataGenerator("MA_Long", DistributionType.UNIFORM, (double) maLongTicksMin, (double) maLongTicksMax);
	            RandomDistDataGenerator distBcTicksTrend    = new RandomDistDataGenerator("BC_Ticks_Trend", DistributionType.UNIFORM, (double) bcTicksTrendMin, (double) bcTicksTrendMax);
	            
	            MultiplierTrend trendMultiplier = MultiplierTrend.MA_SLOPE_DIFFERENCE_STDDEV;   // Method to calculate the size of the trend positions
//	            MultiplierTrend trendMultiplier = MultiplierTrend.MA_SLOPE_DIFFERENCE;   // Method to calculate the size of the trend positions
	            PositionUpdateTrend positionUpdateTrend = PositionUpdateTrend.VARIABLE;     // Specifies if a position can be modified while open
	            OrderOrPositionStrategyTrend orderOrPositionStrategyTrend = OrderOrPositionStrategyTrend.POSITION;     // Specifies if the strategy is order-based or position-based
	            VariabilityCapFactorTrend variabilityCapFactorTrend = VariabilityCapFactorTrend.CONSTANT;    // Specifies if the capFactor is constant or varies based on the agent performance
	            ShortSellingTrend shortSellingTrend = ShortSellingTrend.ALLOWED;    // Specifies if short-selling is allowed
	            
	            System.out.print("TREND multiplier: " + trendMultiplier + "\n");
	            
	            int auxT = 0;   // TODO remove this and use a standard for loop below
	            
	            for (Trader trader : trendFollowers.values()) {
	                int trendID = auxT;  
//	            	simulator.addTrendStrategyForOneTrader("IBM", "Trend_" + trendID, (int) Math.round(distMaShortTicks.nextDouble()), (int) Math.round(distMaLongTicks.nextDouble()), (int) Math.round(distBcTicksTrend.nextDouble()), params.capFactorTrend, params.volWindowTrend, trendMultiplier, params.normPeriod);  // DEPRECATED - normPeriod is no longer used
	            	simulator.addTrendStrategyForOneTrendFollower("IBM", "Trend_" + trendID, (int) Math.round(distMaShortTicks.nextDouble()), 
	            			(int) Math.round(distMaLongTicks.nextDouble()), (int) Math.round(distBcTicksTrend.nextDouble()), params.capFactorTrend, 
	            			params.volWindowTrend, trendMultiplier, positionUpdateTrend, orderOrPositionStrategyTrend, 
	            			variabilityCapFactorTrend, shortSellingTrend);
//	            	simulator.addTrendStrategyForOneTrendFollower("IBM", "Trend_" + trendID, (int) Math.round(distMaShortTicks.nextDouble()), (int) Math.round(distMaLongTicks.nextDouble()), (int) Math.round(distBcTicksTrend.nextDouble()), Math.pow(-1, trendID)*params.capFactorTrend, params.volWindowTrend, trendMultiplier, positionUpdateTrend, orderOrPositionStrategyTrend, variabilityCapFactorTrend);  // With contrarian TRENDs
	                auxT ++;
	            }
	    
	            
	            /* ***************************************
	             * 
	             *      Set up the value strategies
	             * 
	             *****************************************/
	                        
//	            simulator.addValueStrategyForAllTraders("IBM", params.entryThreshold, params.exitThreshold, params.valueOffset, params.bcTicks, params.capFactorFund, params.normPeriod);   // DEPRECATED - normPeriod is no longer used
//	            simulator.addValueStrategyForAllTraders("IBM", params.entryThreshold, params.exitThreshold, params.valueOffset, params.bcTicks, params.capFactorFund, positionUpdateValue);
	            
	            HashMap<String, Trader> valueTraders = simulator.getValueInvestors();
	            
	            RandomDistDataGenerator distEntryThreshold = new RandomDistDataGenerator("Entry", DistributionType.UNIFORM, entryThresholdMin, entryThresholdMax);
	            RandomDistDataGenerator distExitThreshold = new RandomDistDataGenerator("Exit", DistributionType.UNIFORM, exitThresholdMin, exitThresholdMax);
	            RandomDistDataGenerator distValueOffset = new RandomDistDataGenerator("Offset", DistributionType.UNIFORM, -valueOffset, valueOffset);
	            RandomDistDataGenerator distBcTicksFund = new RandomDistDataGenerator("BC_Ticks_Fund", DistributionType.UNIFORM, (double) params.bcTicksFundMin, (double) params.bcTicksFundMax);
	            
	            PositionUpdateValue positionUpdateValue = PositionUpdateValue.VARIABLE;     // Specifies if a position can be modified while open
	            OrderOrPositionStrategyValue orderOrPositionStrategyValue = OrderOrPositionStrategyValue.POSITION;   // Specifies if the strategy is order-based or position-based
	            VariabilityCapFactorValue variabilityCapFactorValue = VariabilityCapFactorValue.CONSTANT;    // Specifies if the capFactor is constant or varies based on the agent performance
	            ShortSellingValue shortSellingValue = ShortSellingValue.ALLOWED;    // Specifies if short-selling is allowed
	            
	            int auxV = 0;   // TODO remove this and use a standard for loop below 
	            
	            for (Trader trader : valueTraders.values()) {
	                int valueID = auxV;
//	            	simulator.addValueStrategyForOneTrader("IBM", "Value_" + valueID, distEntryThreshold.nextDouble(), distExitThreshold.nextDouble(), distValueOffset.nextDouble(), (int) Math.round(distBcTicksFund.nextDouble()), params.capFactorFund, params.normPeriod);   // DEPRECATED - normPeriod is no longer used
	            	simulator.addValueStrategyForOneValueInvestor("IBM", "Value_" + valueID, distEntryThreshold.nextDouble(), distExitThreshold.nextDouble(), 
	            	        distValueOffset.nextDouble(), (int) Math.round(distBcTicksFund.nextDouble()), params.capFactorFund, positionUpdateValue, 
	            	        orderOrPositionStrategyValue, variabilityCapFactorValue, shortSellingValue);
	                auxV ++;
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
	
	            DoubleTimeSeriesList dtlPositionsTrend = new DoubleTimeSeriesList();
	            DoubleTimeSeriesList dtlPositionsFund = new DoubleTimeSeriesList();
	            DoubleTimeSeriesList dtlWealthIncrementsTrend = new DoubleTimeSeriesList();
	            DoubleTimeSeriesList dtlWealthIncrementsFund = new DoubleTimeSeriesList();
	                        
	            for (int tr = 0; tr < numTrends/4; tr++) {  // 26 Jun 2014 - Plot only a sample of time series to avoid memory problems in graphics
	                int trendID = tr;
	            	TrendMABCStrategy trend = (TrendMABCStrategy) simulator.getTrendFollowers().get("Trend_" + trendID).getStrategies().get("IBM");
	            	
	            	DoubleTimeSeries Position = trend.getTsPos();
	            	DoubleTimeSeries WealthIncrement = StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), trend.getTsPos());
	            	
	            	dtlPositionsTrend.add(tr, Position);
	            	dtlWealthIncrementsTrend.add(tr, WealthIncrement);
	            }
	            
	            for (int val = 0; val < numFunds/4; val++) {   // 26 Jun 2014 - Plot only a sample of time series to avoid memory problems in graphics
	                int valueID = val;
	            	ValueMABCStrategy fund = (ValueMABCStrategy) simulator.getValueInvestors().get("Value_" + valueID).getStrategies().get("IBM");
	            	
	            	DoubleTimeSeries Position = fund.getTsPos();
	            	DoubleTimeSeries WealthIncrement = StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), fund.getTsPos());
	            	
	            	dtlPositionsFund.add(val, Position);
	            	dtlWealthIncrementsFund.add(val, WealthIncrement);
	            }
	            
	            for (int tr = 0; tr < numTrends/4; tr++) {   // 26 Jun 2014 - Plot only a sample of time series to avoid memory problems in graphics
//	                logger.debug("Positions_T: {}", VersatileTimeSeries.printValues(dtlPositionsTrend.get(tr)));
	                atcWealthTrend.populateSeries(e, run, "wealth_T_" + tr, dtlWealthIncrementsTrend.get(tr));	                
	                atcPosTrend.populateSeries(e, run, "pos_T_" + tr, dtlPositionsTrend.get(tr));
	            }
	                        
	            for (int val = 0; val < numFunds/4; val++) {   // 26 Jun 2014 - Plot only a sample of time series to avoid memory problems in graphics
//	                logger.debug("Positions_F: {}", VersatileTimeSeries.printValues(dtlPositionsFund.get(val)));
	                atcWealthFund.populateSeries(e, run, "wealth_F_" + val, dtlWealthIncrementsFund.get(val));
	                atcPosFund.populateSeries(e, run, "pos_F_" + val, dtlPositionsFund.get(val));
	            }
	            
//	            logger.debug("TOTAL_Volume: {}", VersatileTimeSeries.printValues(simulator.getTotalVolume("IBM")));
//	            
//	            logger.debug("{}", VersatileTimeSeries.printDecoratedTicks(simulator.getPrices("IBM"), 0));
	            logger.debug("{}", VersatileTimeSeries.printDecoratedValues(simulator.getPrices("IBM"), "Price", 6));
//	            
//	            logger.debug("{}", VersatileTimeSeries.printDecoratedTicks(simulator.getFundValues("IBM"), 0));
//	            logger.debug("{}", VersatileTimeSeries.printDecoratedValues(simulator.getFundValues("IBM"), "Value", 6));
	            
	            atcPrice.populateSeries(e, run, "IBM_P", simulator.getPrices("IBM"));
	            atcValue.populateSeries(e, run, "IBM_V", simulator.getFundValues("IBM"));
	            atcVolumeFund.populateSeries(e, run, "volume_F", simulator.getFundVolume("IBM"));
	            atcVolumeTrend.populateSeries(e, run, "volume_T", simulator.getTrendVolume("IBM"));
End comment */
           
	                
	            /*
	             * Create time series lists for extraction to R
	             */
	            
	            tsPricesList.add(run, simulator.getPrices("IBM"));              // time series list of prices [nRuns x nTicks]
	            tsFundValuesList.add(run, simulator.getFundValues("IBM"));      // time series list of general fund value [nRuns x nTicks]
	            tsTotalVolumeList.add(run, simulator.getTotalVolume("IBM"));    // time series list of total volume [nRuns x nTicks]
	            tsFundVolumeList.add(run, simulator.getFundVolume("IBM"));      // time series list of FUND volume [nRuns x nTicks]
	            tsTrendVolumeList.add(run, simulator.getTrendVolume("IBM"));    // time series list of TREND volume [nRuns x nTicks]
	            tsFundTotalOrdersList.add(run, simulator.getFundTotalOrders("IBM"));      // time series list of FUND aggregated orders [nRuns x nTicks]
	            tsTrendTotalOrdersList.add(run, simulator.getTrendTotalOrders("IBM"));    // time series list of TREND aggregated orders [nRuns x nTicks]
	            tsFundAvgWealthIncrementList.add(run, simulator.getFundAvgWealthIncrement("IBM"));      // time series list of FUND wealth increment [nRuns x nTicks]
	            tsTrendAvgWealthIncrementList.add(run, simulator.getTrendAvgWealthIncrement("IBM"));    // time series list of TREND wealth increment [nRuns x nTicks]
	            
	            
	            /**
	             * VVUQ tests
	             */
	            
	            // VVUQ - Verification test on the distribution of TREND parameters which are random
//	            DoubleTimeSeries tsMaShortTicks = new DoubleTimeSeries();
//	            DoubleTimeSeries tsMaLongTicks = new DoubleTimeSeries();
//	            DoubleTimeSeries tsBcTicks = new DoubleTimeSeries();
//	            
//	            for (int tr = 0; tr < numTrends; tr++) {
//	                int trendID = tr;
//	            	TrendMABCStrategy trend = (TrendMABCStrategy) simulator.getTrendFollowers().get("Trend_" + trendID).getStrategies().get("IBM");
//	            	
//	            	tsMaShortTicks.add(trend.getMaShortTicks());
//	            	tsMaLongTicks.add(trend.getMaLongTicks());
//	            	tsBcTicks.add(trend.getBcTicks());
//	            }
//	            
//	            logger.debug("SHORT TICKS - Mean: {}, StdDev: {}", tsMaShortTicks.mean(), tsMaShortTicks.stdev());
//	            logger.debug("LONG TICKS - Mean: {}, StdDev: {}", tsMaLongTicks.mean(), tsMaLongTicks.stdev());
//	            logger.debug("BC TICKS - Mean: {}, StdDev: {}", tsBcTicks.mean(), tsBcTicks.stdev());
	
	            
	            // VVUQ - Verification test on the distribution of FUND parameters which are random
//	            DoubleTimeSeries tsValueEntryThresholds = new DoubleTimeSeries();
//	            DoubleTimeSeries tsValueExitThresholds = new DoubleTimeSeries();
//	            DoubleTimeSeries tsValueOffsets = new DoubleTimeSeries();
//	            
//	            for (int val = 0; val < numFunds; val++) {
//	                int valueID = val;
//	            	ValueMABCStrategy fund = (ValueMABCStrategy) simulator.getValueTraders().get("Value_" + valueID).getStrategies().get("IBM");
//	            	
//	            	tsValueEntryThresholds.add(fund.getEntryThreshold());
//	            	tsValueExitThresholds.add(fund.getExitThreshold());
//	            	tsValueOffsets.add(fund.getValueOffset());
//	            }
//	            
//	            logger.debug("ENTRY THRESHOLD - Mean: {}, StdDev: {}", tsValueEntryThresholds.mean(), tsValueEntryThresholds.stdev());
//	            logger.debug("EXIT THRESHOLD - Mean: {}, StdDev: {}", tsValueExitThresholds.mean(), tsValueExitThresholds.stdev());
//	            logger.debug("VALUE OFFSET - Mean: {}, StdDev: {}", tsValueOffsets.mean(), tsValueOffsets.stdev());
	            
	            
	            
	            // VVUQ - Graphic to verify that the FUND enters and exits a position in the due time steps
//	            DoubleTimeSeries tsValueMinusPrice = new DoubleTimeSeries();
//	            DoubleTimeSeries tsEntryThreshold_Pos = new DoubleTimeSeries();
//	            DoubleTimeSeries tsEntryThreshold_Neg = new DoubleTimeSeries();
//	            DoubleTimeSeries tsExitThreshold_Pos = new DoubleTimeSeries();
//	            DoubleTimeSeries tsExitThreshold_Neg = new DoubleTimeSeries();
//	            
//	            for (int k = 0; k < numTicks; k++) {
//	            	double ValueMinusPrice = simulator.getFundValues("IBM").get(k) - simulator.getPrices("IBM").get(k);
//	            	
//	            	tsValueMinusPrice.add(k, ValueMinusPrice);
//	            	tsEntryThreshold_Pos.add(k, entryThresholdMax);
//	            	tsEntryThreshold_Neg.add(k, -entryThresholdMax);
//	            	tsExitThreshold_Pos.add(k, exitThresholdMin);
//	            	tsExitThreshold_Neg.add(k, -exitThresholdMin);
//	            }
//	            
//	            atcValuePriceDiff.populateSeries(e, run, "IBM_VP", tsValueMinusPrice);
//	            atcValuePriceDiff.populateSeries(e, run, "Entry_Pos", tsEntryThreshold_Pos);
//	            atcValuePriceDiff.populateSeries(e, run, "Entry_Neg", tsEntryThreshold_Neg);
//	            atcValuePriceDiff.populateSeries(e, run, "Exit_Pos", tsExitThreshold_Pos);
//	            atcValuePriceDiff.populateSeries(e, run, "Exit_Neg", tsExitThreshold_Neg);
	            
	            
	            // Auxiliary graphic to analyse the positions of an individual FUND trader
//	            DoubleTimeSeries tsValueMinusPrice_F1 = new DoubleTimeSeries();
//	            DoubleTimeSeries tsEntryThreshold_Pos_F1 = new DoubleTimeSeries();
//	            DoubleTimeSeries tsEntryThreshold_Neg_F1 = new DoubleTimeSeries();
//	            DoubleTimeSeries tsExitThreshold_Pos_F1 = new DoubleTimeSeries();
//	            DoubleTimeSeries tsExitThreshold_Neg_F1 = new DoubleTimeSeries();
//	            
//	            int fund1_ID = 0;   // ID of the first FUND trader (just to choose an individual FUND)
//	            ValueMABCStrategy fund_1 = (ValueMABCStrategy) simulator.getValueInvestors().get("Value_" + fund1_ID).getStrategies().get("IBM");
//	            
//	            for (int k = 0; k < numTicks; k++) {
//	            	double ValueMinusPrice_F1 = simulator.getFundValues("IBM").get(k) + fund_1.getValueOffset() - simulator.getPrices("IBM").get(k);
//	            	
//	            	tsValueMinusPrice_F1.add(k, ValueMinusPrice_F1);
//	            	tsEntryThreshold_Pos_F1.add(k, fund_1.getEntryThreshold());
//	            	tsEntryThreshold_Neg_F1.add(k, -fund_1.getEntryThreshold());
//	            	tsExitThreshold_Pos_F1.add(k, fund_1.getExitThreshold());
//	            	tsExitThreshold_Neg_F1.add(k, -fund_1.getExitThreshold());
//	            }
//	            
//	            atcValuePriceDiff_F1.populateSeries(e, run, "IBM_VP", tsValueMinusPrice_F1);
//	            atcValuePriceDiff_F1.populateSeries(e, run, "Entry_Pos", tsEntryThreshold_Pos_F1);
//	            atcValuePriceDiff_F1.populateSeries(e, run, "Entry_Neg", tsEntryThreshold_Neg_F1);
//	            atcValuePriceDiff_F1.populateSeries(e, run, "Exit_Pos", tsExitThreshold_Pos_F1);
//	            atcValuePriceDiff_F1.populateSeries(e, run, "Exit_Neg", tsExitThreshold_Neg_F1);
	            
	            
	            // VVUQ - Verification test on the distribution of prices
//	            meanPrice = meanPrice + simulator.getPrices("IBM").mean();
//	            stdDevPrice = stdDevPrice + simulator.getPrices("IBM").stdev();
//	            logger.debug("PRICES, run " + run + " - Mean: {}, StdDev: {}", simulator.getPrices("IBM").mean(), simulator.getPrices("IBM").stdev());
	            
	            	
	            /**
	             * Calculation of normalisation factor of FUND and TREND positions 
	             */
	            
	            // ---- Using the mean of FUND/TREND entry indicators ----
	            
//	            int warmUpPeriod = Math.max(params.volWindowTrend, Math.max(Math.max(bcTicksTrendMax, bcTicksFundMax), Math.max(maShortTicksMin, maLongTicksMin)));
//	            int valueID = 1;   // TODO - Randomly choose a trader from the set of Funds
//	        	  ValueMABCStrategy fund = (ValueMABCStrategy) simulator.getValueInvestors().get("Value_" + valueID).getStrategies().get("IBM");
//	            double meanFundInd = simulator.magnitudeValueIndicator("IBM", numTicks, fund.getValueOffset());
//	            meanMagnitudeFundIndicator.add(meanFundInd);
//	            
//	            int trendID = 1;  ;  // TODO - Randomly choose a trader from the set of Trends
//	            TrendMABCStrategy trend = (TrendMABCStrategy) simulator.getTrendFollowers().get("Trend_" + trendID).getStrategies().get("IBM");
//	            double meanTrendInd = simulator.magnitudeTrendIndicator("IBM", numTicks - warmUpPeriod, trend.getMaShortTicks(), trend.getMaLongTicks(), params.volWindowTrend, trendMultiplier);
//	            meanMagnitudeTrendIndicator.add(meanTrendInd);
//	            
//	            ratioMeanMagnitudeIndicator.add(meanFundInd/meanTrendInd);
//	            
//	            logger.debug("MeanMagnitudeIndicator_F: {}", meanFundInd);   //TEST
//	            logger.debug("MeanMagnitudeIndicator_T: {}", meanTrendInd);   //TEST
//	            logger.debug("ratioMeanMagnitudeIndicator: {}", meanFundInd/meanTrendInd);   //TEST
//	            
//	            // ---- Using the maximum position of an individual FUND/TREND ----
//	            
//	        	DoubleTimeSeries fundPos = fund.getTsPos();
//	            double maxFundPosition = StatsTimeSeries.maxAbsValue(fundPos);
//	            
//	            DoubleTimeSeries trendPos = trend.getTsPos();
//	            double maxTrendPosition = StatsTimeSeries.maxAbsValue(trendPos);
//	            
//	            maxAbsFundPosition.add(maxFundPosition);
//	            maxAbsTrendPosition.add(maxTrendPosition);
//	            ratioMaxAbsPosition.add(maxFundPosition/maxTrendPosition);
//	            
//	            
//	            // ---- Using the mean of maximum position over all FUNDs/TRENDs ----
//	            
//	            double meanMaxTrendPosition = 0;
//	            double meanMaxFundPosition = 0;
//	            
//	            for (int val = 0; val < numFunds; val++) {
//	            	
//	                int valueID2 = val;
//	            	ValueMABCStrategy fund2 = (ValueMABCStrategy) simulator.getValueInvestors().get("Value_" + valueID2).getStrategies().get("IBM");
//	            	
//	            	DoubleTimeSeries fundPos2 = fund2.getTsPos();
//	            	
//	            	meanMaxFundPosition = meanMaxFundPosition + StatsTimeSeries.maxAbsValue(fundPos2);
//	            }
//	            
//	            meanMaxAbsFundPosition.add(meanMaxFundPosition / numFunds);
//	            
//	            for (int tr = 0; tr < numTrends; tr++) {
//	            	
//	                int trendID2 = tr;
//	            	TrendMABCStrategy trend2 = (TrendMABCStrategy) simulator.getTrendFollowers().get("Trend_" + trendID2).getStrategies().get("IBM");
//	            	
//	            	DoubleTimeSeries trendPos2 = trend2.getTsPos();
//	            	
//	            	meanMaxTrendPosition = meanMaxTrendPosition + StatsTimeSeries.maxAbsValue(trendPos2);
//	            }
//	            
//	            meanMaxAbsTrendPosition.add(meanMaxTrendPosition / numTrends);
//	            
//	            ratioMeanMaxAbsPosition.add( (meanMaxFundPosition / numFunds) / (meanMaxTrendPosition / numTrends) );
	            
	            
	            /**
	             * Print the volatility of log-returns for calibration purposes 
	             */            
	            DoubleTimeSeries tsLogReturns = new DoubleTimeSeries();
	            
	            for (int k = 1; k < numTicks; k++) {
	            	double price_current_tick = simulator.getPrices("IBM").get(k);
	            	double price_previous_tick = simulator.getPrices("IBM").get(k-1);
	            	tsLogReturns.add(Math.log(price_current_tick) - Math.log(price_previous_tick));
	            }
	            
	            logger.debug("VOLATILITY of LOG-RETURNS: {}", tsLogReturns.stdev());
	            logger.debug("KURTOSIS of LOG-RETURNS: {}", tsLogReturns.excessKurtosis());
	            logger.debug("SKEWNESS of LOG-RETURNS: {}", tsLogReturns.skewness());
	            logger.debug("MEAN VOLUME - F: {}, T: {}", simulator.getFundVolume("IBM").mean(), simulator.getTrendVolume("IBM").mean());
	            logger.debug("AVG WEALTH INCREMENT - F: {}, T: {}", simulator.getFundAvgWealthIncrement("IBM").get(numTicks-1), simulator.getTrendAvgWealthIncrement("IBM").get(numTicks-1));
	            logger.debug("VOLATILITY of PRICES: {}", simulator.getPrices("IBM").stdev());
	                        
	        }
       
            // VVUQ - Verification test on the distribution of prices (cont'd)
//          meanPrice = meanPrice/numRuns;
//          stdDevPrice = stdDevPrice/numRuns;        
//          logger.debug("PRICES - Average statistics - Mean: {}, StdDev: {}", meanPrice, stdDevPrice);
	        
	                               
	        /**
	         *      Write results of current experiment to file for further analysis with R
	         */
            
            ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_price_timeseries_E" + e + ".csv").write(tsPricesList);
            ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_fundvalues_timeseries_E" + e + ".csv").write(tsFundValuesList);
            ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_totalvolume_timeseries_E" + e + ".csv").write(tsTotalVolumeList);
            ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_fundvolume_timeseries_E" + e + ".csv").write(tsFundVolumeList);
            ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_trendvolume_timeseries_E" + e + ".csv").write(tsTrendVolumeList);
            ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_fundorders_timeseries_E" + e + ".csv").write(tsFundTotalOrdersList);
            ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_trendorders_timeseries_E" + e + ".csv").write(tsTrendTotalOrdersList);
            ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_fundwealth_timeseries_E" + e + ".csv").write(tsFundAvgWealthIncrementList);
            ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_trendwealth_timeseries_E" + e + ".csv").write(tsTrendAvgWealthIncrementList);
            	    	        
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

        if (numTrends > 0) {
        	charts.draw(atcWealthTrend);
            charts.draw(atcPosTrend);
        }
        
        if (numFunds > 0) {
        	charts.draw(atcWealthFund);
            charts.draw(atcPosFund);
            charts.draw(atcValue);
//            charts.draw(atcValuePriceDiff);
//            charts.draw(atcValuePriceDiff_F1);
        }        
        
        charts.draw(atcPrice);
//        charts.draw(atcVolumeFund);
//        charts.draw(atcVolumeTrend);
        
//        histogram.drawSimpleHistogram(atcVolumeFund.getSeries(0));   //TODO: adjust index when numRuns > 1
//        histogram.drawSimpleHistogram(atcVolumeTrend.getSeries(0));
End comment */
        
               
        
        /**
         *      Write data on mean positions to R to calculate the normalisation factor of TREND followers
         */
//        ResultWriterFactory.newCsvWriter("./out/trend-value-abm-simulation/normFactor/list_trendIndicator_slopediffstdev_50T50F.csv").write(meanMagnitudeTrendIndicator);
//        ResultWriterFactory.newCsvWriter("./out/trend-value-abm-simulation/normFactor/list_fundIndicator_slopediffstdev_50T50F.csv").write(meanMagnitudeFundIndicator);
//        ResultWriterFactory.newCsvWriter("./out/trend-value-abm-simulation/normFactor/list_ratioIndicator_slopediffstdev_50T50F.csv").write(ratioMeanMagnitudeIndicator);
//        
//        ResultWriterFactory.newCsvWriter("./out/trend-value-abm-simulation/normFactor/list_trendMaxPosition_slopediffstdev_50T50F.csv").write(maxAbsTrendPosition);
//        ResultWriterFactory.newCsvWriter("./out/trend-value-abm-simulation/normFactor/list_fundMaxPosition_slopediffstdev_50T50F.csv").write(maxAbsFundPosition);
//        ResultWriterFactory.newCsvWriter("./out/trend-value-abm-simulation/normFactor/list_ratioMaxPosition_slopediffstdev_50T50F.csv").write(ratioMaxAbsPosition);
//        
//        ResultWriterFactory.newCsvWriter("./out/trend-value-abm-simulation/normFactor/list_trendMeanMaxPosition_slopediffstdev_50T50F.csv").write(meanMaxAbsTrendPosition);
//        ResultWriterFactory.newCsvWriter("./out/trend-value-abm-simulation/normFactor/list_fundMeanMaxPosition_slopediffstdev_50T50F.csv").write(meanMaxAbsFundPosition);
//        ResultWriterFactory.newCsvWriter("./out/trend-value-abm-simulation/normFactor/list_ratioMeanMaxPosition_slopediffstdev_50T50F.csv").write(ratioMeanMaxAbsPosition);
          

        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
    }

}