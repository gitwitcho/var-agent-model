/*
 * Copyright (c) 2024-2025 Gilbert Peffer, Bàrbara Llacay
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

import info.financialecology.finance.abm.model.TrendValueESAbmSimulator;
import info.financialecology.finance.abm.model.agent.Trader;
import info.financialecology.finance.abm.model.agent.Trader.UseVar;
import info.financialecology.finance.abm.model.agent.Trader.UseEs;
import info.financialecology.finance.abm.model.agent.Trader.UseStressedVar;
import info.financialecology.finance.abm.model.agent.Trader.UseStressedEs;
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
import info.financialecology.finance.abm.sandbox.TrendValueESAbmParams;
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
 * @author Gilbert Peffer, Bàrbara Llacay
 */
public class TrendValueESMultiAssetAbmSimulation {

    protected static final String TEST_ID = "TrendValueESMultiAssetAbmSimulation"; 
    
    /**
     * @param args
     * @throws FileNotFoundException 
     */
    public static void main(String[] args) throws FileNotFoundException {
        Timer timerAll  = new Timer();  // a timer to calculate total execution time (cern.colt)
        Timer timer     = new Timer();  // a timer to calculate execution times of particular methods (cern.colt)
        timerAll.start();
        double startTime = System.nanoTime();

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
        
        TrendValueESAbmParams params = TrendValueESAbmParams.readParameters(CmdLineProcessor.process(args));

        /*
         *      PARAMETERS
         */

        int numTicks        = params.nTicks;    // number of ticks per simulation run
        int numRuns         = params.nRuns;     // number of runs per simulation experiment
        int startSeed       = params.seed;      // starting position in the random seed table; -1 for random value (based on internal clock) 
        
        int numTrends       = params.numTrends;    // number of TREND investors
        int numFunds        = params.numFunds;     // number of FUND investors
                
        DoubleArrayList price_0      = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.PRICE_0);
        DoubleArrayList liquidity    = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.LIQUIDITY);

        double confLevelVar = params.confLevelVar;   // confidence level of the VaR model (between 0 and 1)
        double confLevelEs = params.confLevelEs;     // confidence level of the ES model (between 0 and 1)

        double probShortSellingTrend = params.probShortSellingTrend;   // percentage of TRENDs which are allowed to short-sell (between 0 and 1)
        double probShortSellingValue = params.probShortSellingValue;   // percentage of FUNDs which are allowed to short-sell (between 0 and 1)
        
        // Parameters for the exogenous price process. The process is an overlay of a Brownian process and a sinus function
        
//        DoubleArrayList shift_price      = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.SHIFT_PRICE);
        DoubleArrayList amplitude_price  = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.AMPLITUDE_PRICE);
        DoubleArrayList lag_price        = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.LAG_PRICE);
        DoubleArrayList lambda_price     = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.LAMBDA_PRICE);
        
        DoubleArrayList mu_price         = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.MU_PRICE);
        DoubleArrayList sigma_price      = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.SIGMA_PRICE);        
                
        // Parameters for the exogenous market-wide fundamental value process. The process is an overlay of a Brownian process and a sinus function
        
//        DoubleArrayList shift_value      = params.getValidatedDoubleSequence(TrendValueLSAbmParams.Sequence.SHIFT_VALUE);
        DoubleArrayList amplitude_value  = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.AMPLITUDE_VALUE);
        DoubleArrayList lag_value        = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.LAG_VALUE);
        DoubleArrayList lambda_value     = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.LAMBDA_VALUE);        
        
        DoubleArrayList mu_value         = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.MU_VALUE);
        DoubleArrayList sigma_value      = params.getValidatedDoubleSequence(TrendValueESAbmParams.Sequence.SIGMA_VALUE);
        
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
        
        int numExp = 16;   // TODO - Delete when this is automatically extracted from the sequences in the param file

        TrendValueESAbmSimulator simulator;

        
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
        VersatileTimeSeriesCollection atcPosFund_IBM        = new VersatileTimeSeriesCollection("FUND Positions for IBM");
        VersatileTimeSeriesCollection atcPosFund_MSFT       = new VersatileTimeSeriesCollection("FUND Positions for MSFT");
        VersatileTimeSeriesCollection atcPosFund_GOOG       = new VersatileTimeSeriesCollection("FUND Positions for GOOG");
        VersatileTimeSeriesCollection atcPosTrend_IBM       = new VersatileTimeSeriesCollection("TREND Positions for IBM");
        VersatileTimeSeriesCollection atcPosTrend_MSFT      = new VersatileTimeSeriesCollection("TREND Positions for MSFT");
        VersatileTimeSeriesCollection atcPosTrend_GOOG      = new VersatileTimeSeriesCollection("TREND Positions for GOOG");

        VersatileTimeSeriesCollection atcOrdersFund_IBM        = new VersatileTimeSeriesCollection("FUND Orders for IBM");
        VersatileTimeSeriesCollection atcOrdersTrend_IBM       = new VersatileTimeSeriesCollection("TREND Orders for IBM");

        VersatileTimeSeriesCollection atcVarSelloffOrdersFund_IBM    = new VersatileTimeSeriesCollection("FUND VaR sell-off orders for IBM");
        VersatileTimeSeriesCollection atcVarSelloffOrdersTrend_IBM   = new VersatileTimeSeriesCollection("TREND VaR sell-off orders for IBM");
        VersatileTimeSeriesCollection atcVarSelloffOrdersFund_GOOG   = new VersatileTimeSeriesCollection("FUND VaR sell-off orders for GOOG");
        VersatileTimeSeriesCollection atcVarSelloffOrdersTrend_GOOG  = new VersatileTimeSeriesCollection("TREND VaR sell-off orders for GOOG");

        VersatileTimeSeriesCollection atcEsSelloffOrdersFund_IBM    = new VersatileTimeSeriesCollection("FUND ES sell-off orders for IBM");
        VersatileTimeSeriesCollection atcEsSelloffOrdersTrend_IBM   = new VersatileTimeSeriesCollection("TREND ES sell-off orders for IBM");
        VersatileTimeSeriesCollection atcEsSelloffOrdersFund_GOOG   = new VersatileTimeSeriesCollection("FUND ES sell-off orders for GOOG");
        VersatileTimeSeriesCollection atcEsSelloffOrdersTrend_GOOG  = new VersatileTimeSeriesCollection("TREND ES sell-off orders for GOOG");

        VersatileTimeSeriesCollection atcVarPosReducedFund_IBM    = new VersatileTimeSeriesCollection("FUND VaR reduced positions for IBM");
        VersatileTimeSeriesCollection atcVarPosReducedFund_GOOG   = new VersatileTimeSeriesCollection("FUND VaR reduced positions for GOOG");
        VersatileTimeSeriesCollection atcVarPosReducedTrend_IBM   = new VersatileTimeSeriesCollection("TREND VaR reduced positions for IBM");
        VersatileTimeSeriesCollection atcVarPosReducedTrend_GOOG  = new VersatileTimeSeriesCollection("TREND VaR reduced positions for GOOG");

        VersatileTimeSeriesCollection atcEsPosReducedFund_IBM    = new VersatileTimeSeriesCollection("FUND ES reduced positions for IBM");
        VersatileTimeSeriesCollection atcEsPosReducedFund_GOOG   = new VersatileTimeSeriesCollection("FUND ES reduced positions for GOOG");
        VersatileTimeSeriesCollection atcEsPosReducedTrend_IBM   = new VersatileTimeSeriesCollection("TREND ES reduced positions for IBM");
        VersatileTimeSeriesCollection atcEsPosReducedTrend_GOOG  = new VersatileTimeSeriesCollection("TREND ES reduced positions for GOOG");

        VersatileTimeSeriesCollection atcPreTradeVarFund       = new VersatileTimeSeriesCollection("FUND VaR - Pre trade");
        VersatileTimeSeriesCollection atcPreTradeVarTrend      = new VersatileTimeSeriesCollection("TREND VaR - Pre trade");
        VersatileTimeSeriesCollection atcPostTradeVarFund      = new VersatileTimeSeriesCollection("FUND VaR - Post trade");
        VersatileTimeSeriesCollection atcPostTradeVarTrend     = new VersatileTimeSeriesCollection("TREND VaR - Post trade");

        VersatileTimeSeriesCollection atcPreTradeEsFund       = new VersatileTimeSeriesCollection("FUND ES - Pre trade");
        VersatileTimeSeriesCollection atcPreTradeEsTrend      = new VersatileTimeSeriesCollection("TREND ES - Pre trade");
        VersatileTimeSeriesCollection atcPostTradeEsFund      = new VersatileTimeSeriesCollection("FUND ES - Post trade");
        VersatileTimeSeriesCollection atcPostTradeEsTrend     = new VersatileTimeSeriesCollection("TREND ES - Post trade");

        VersatileTimeSeriesCollection atcVarLimitFund          = new VersatileTimeSeriesCollection("FUND VaR limit");
        VersatileTimeSeriesCollection atcVarLimitTrend         = new VersatileTimeSeriesCollection("TREND VaR limit");
        
        // Time series
        
        VersatileTimeSeriesCollection atcPrices             = new VersatileTimeSeriesCollection("Prices for shares");        
        VersatileTimeSeriesCollection atcValues             = new VersatileTimeSeriesCollection("Fundamental values");
        VersatileTimeSeriesCollection atcSpreads            = new VersatileTimeSeriesCollection("Spreads for shares");

        VersatileTimeSeriesCollection atcFailures           = new VersatileTimeSeriesCollection("Agent failures");
        
        
        /*
         *      ASSET ID's
         */
        
        ArrayList<String> shareIds = new ArrayList<String>();
        shareIds.add("IBM");                
        if (numAssets > 1) shareIds.add("MSFT");
        if (numAssets > 2) shareIds.add("GOOG");
        if (numAssets > 3) shareIds.add("AAPL");
        
        Assertion.assertOrKill(shareIds.size() == numAssets, numAssets + " share identifiers have to be defined, but only " + shareIds + " are in the list");
               
       
        
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
        	
        	double capFactTrend = params.capFactorTrend;
        	
        	double varLimitTrendMin = params.varLimitTrendMin;
        	double varLimitTrendMax = params.varLimitTrendMax;
        	double varLimitFundMin = params.varLimitFundMin;
        	double varLimitFundMax = params.varLimitFundMax;

        	double esLimitTrendMin = params.esLimitTrendMin;
        	double esLimitTrendMax = params.esLimitTrendMax;
        	double esLimitFundMin = params.esLimitFundMin;
        	double esLimitFundMax = params.esLimitFundMax;
        	
//        	if (numExp > 1) {
//        		esLimitFundMin = 5 + e*3;
//        		esLimitFundMax = 5 + e*3;
//        		esLimitTrendMin = 5 + e*3;
//        		esLimitTrendMax = 5 + e*3;
//        	}
        	System.out.print("varLimit Trend = [" + varLimitTrendMin + ", " + varLimitTrendMax + "]" + "  esLimit Trend = [" + esLimitTrendMin + ", " + esLimitTrendMax + "]" + "\n");
        	System.out.print("varLimit Fund = [" + varLimitFundMin + ", " + varLimitFundMax + "]" + "  esLimit Fund = [" + esLimitFundMin + ", " + esLimitFundMax + "]" + "\n");
        	
        	int volWindowFundMin    = params.volWindowFundMin;
        	int volWindowFundMax    = params.volWindowFundMax;
        	int volWindowTrendMin   = params.volWindowTrendMin;
        	int volWindowTrendMax   = params.volWindowTrendMax;

        	if (numExp > 1) {
        		volWindowFundMin = 5 + e*3;
        		volWindowFundMax = 5 + e*3;
        		volWindowTrendMin = 5 + e*3;
        		volWindowTrendMax = 5 + e*3;
        	}
        	System.out.print("volWindow Trend = [" + volWindowTrendMin + ", " + volWindowTrendMax + "]" + "\n");
        	System.out.print("volWindow Fund = [" + volWindowFundMin + ", " + volWindowFundMax + "]" + "\n");
        	
        	double probVarValue    = params.probVarFund;
        	double probVarTrend    = params.probVarTrend;
        	double probEsValue    = params.probEsFund;
        	double probEsTrend    = params.probEsTrend;
        	
//        	if (numExp > 1) {
//        		probEsValue = 0 + e*0.1;
//        		probEsTrend = 0 + e*0.1;
//        		probVarValue = 1 - e*0.1;
//        		probVarTrend = 1 - e*0.1;
//        	}
        	System.out.print("probVar Fund = " + probVarValue + "  probEs Fund = " + probEsValue + "\n");
        	System.out.print("probVar Trend = " + probVarTrend + "  probEs Trend = " + probEsTrend + "\n");
        	        	
            VariabilityVarLimit variabilityVarLimit = VariabilityVarLimit.CONSTANT;
//        	VariabilityVarLimit variabilityVarLimit = VariabilityVarLimit.COUNTERCYCLICAL;
        	
            UseStressedVar useStressedVar = UseStressedVar.FALSE;  // !! Ensure that VaR is used before setting stressedVar to 'TRUE' --> Not needed: Stressed VaR is only calculated if useVar == TRUE
            UseStressedEs useStressedEs = UseStressedEs.FALSE;     // !! Ensure that ES is used before setting stressedEs to 'TRUE' --> Not needed: Stressed ES is only calculated if useEs == TRUE
            
        	
        	/*
             * Variables for extracting data to R for each experiment - TODO: Delete when VersatileTimeSeriesCollection works well in CsvResultWriter
             */
            
            DoubleTimeSeriesList tsPricesList                   = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundValuesList               = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTotalVolumeList              = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundVolumeList               = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendVolumeList              = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundTotalOrdersList          = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendTotalOrdersList         = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendAvgWealthIncrementList  = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundAvgWealthIncrementList   = new DoubleTimeSeriesList();

            DoubleTimeSeriesList tsFundVarReducedVolumeList        = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendVarReducedVolumeList       = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsFundVarReducedOrdersList        = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsTrendVarReducedOrdersList       = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundEsReducedVolumeList         = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendEsReducedVolumeList        = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsFundEsReducedOrdersList         = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsTrendEsReducedOrdersList        = new DoubleTimeSeriesList();
            
            DoubleTimeSeriesList tsFundVarSelloffOrdersList        = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendVarSelloffOrdersList       = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundVarSelloffVolumeList        = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendVarSelloffVolumeList       = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundEsSelloffOrdersList         = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendEsSelloffOrdersList        = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundEsSelloffVolumeList         = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendEsSelloffVolumeList        = new DoubleTimeSeriesList();
            
            DoubleTimeSeriesList tsNumberFundsHittingVarLimitList  = new DoubleTimeSeriesList();            
            DoubleTimeSeriesList tsNumberTrendsHittingVarLimitList = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsNumberFundsHittingEsLimitList   = new DoubleTimeSeriesList();            
            DoubleTimeSeriesList tsNumberTrendsHittingEsLimitList  = new DoubleTimeSeriesList();
            
            DoubleTimeSeriesList tsFundAvgVarList               = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendAvgVarList              = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundAvgEsList                = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendAvgEsList               = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundAvgStressedVarList       = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendAvgStressedVarList      = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundAvgStressedEsList        = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendAvgStressedEsList       = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundAvgVarLimitList          = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendAvgVarLimitList         = new DoubleTimeSeriesList();

            DoubleTimeSeriesList tsFundFailureList              = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendFailureList             = new DoubleTimeSeriesList();
            
        
	        for (int run = 0; run < numRuns; run++) {
	        	
	        	System.out.print("RUN:" + run + "\n");
	                        
	            /*
	             * Setting up the simulator
	             */
	        	
	        	simulator = new TrendValueESAbmSimulator();      // recreating the simulator will also get rid of the old schedule
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
                
                simulator.getMarket().setConfLevelVar(confLevelVar);
                simulator.getMarket().setConfLevelEs(confLevelEs);
                
                
	            /*
	             * Setting up the data generators
	             */
	            
	            if (startSeed < 0)
	                RandomGeneratorPool.configureGeneratorPool();
	            else
	                RandomGeneratorPool.configureGeneratorPool(startSeed + run);  // Use consecutive seeds for each run
	
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
	            
	            // Random generator for VaR limit and volatility window
	            RandomDistDataGenerator distVarLimitTrend = new RandomDistDataGenerator("VaR_Limit_Trend", DistributionType.UNIFORM, varLimitTrendMin, varLimitTrendMax);
	            RandomDistDataGenerator distEsLimitTrend = new RandomDistDataGenerator("ES_Limit_Trend", DistributionType.UNIFORM, esLimitTrendMin, esLimitTrendMax);
	            RandomDistDataGenerator distVolWindowTrend = new RandomDistDataGenerator("Vol_Window_Trend", DistributionType.UNIFORM, (double) volWindowTrendMin, (double) volWindowTrendMax);
	            
	            // Uniform distributions U[0,1] to proxy binomial distributions to decide if short-selling is allowed, or VaR is used 
	            RandomDistDataGenerator distUnif01SSTrend = new RandomDistDataGenerator("Unif01_SS_Trend", DistributionType.UNIFORM, 0., 1.);
	            RandomDistDataGenerator distUnif01VarTrend = new RandomDistDataGenerator("Unif01_Var_Trend", DistributionType.UNIFORM, 0., 1.);
	            RandomDistDataGenerator distUnif01EsTrend = new RandomDistDataGenerator("Unif01_Es_Trend", DistributionType.UNIFORM, 0., 1.);
	            
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
//    	            			(int) Math.round(maLongTicks.get(secId).nextDouble()), (int) Math.round(bcTicksTrend.get(secId).nextDouble()), params.capFactorTrend, 
    	            			(int) Math.round(maLongTicks.get(secId).nextDouble()), (int) Math.round(bcTicksTrend.get(secId).nextDouble()), capFactTrend,
    	            			params.volWindowStratTrend, trendMultiplier, positionUpdateTrend, orderOrPositionStrategyTrend, 
    	            			variabilityCapFactorTrend, shortSellingTrend);
	                }
	                
	                // Set VaR and ES parameters
	                UseVar useVarTrend = UseVar.FALSE;
	                UseEs useEsTrend = UseEs.FALSE;
	                double auxRandomVarTrend = distUnif01VarTrend.nextDouble();
	            	if (auxRandomVarTrend <= probVarTrend) 
	            		useVarTrend = UseVar.TRUE;
	            	if (auxRandomVarTrend > probVarTrend && auxRandomVarTrend <= probVarTrend + probEsTrend)
	            		useEsTrend = UseEs.TRUE;
	           	            	
	            	simulator.getTrendFollowers().get("Trend_" + i).setUseVar(useVarTrend);
	            	simulator.getTrendFollowers().get("Trend_" + i).setUseEs(useEsTrend);

//	            	UseStressedEs useSEsTrend = UseStressedEs.FALSE;
//	            	if (distUnif01EsTrend.nextDouble() < e*0.1)    //Use when the probabiliy of using stressed ES changes along experiments
//	            		useSEsTrend = UseStressedEs.TRUE;
//	            	
//	            	simulator.getTrendFollowers().get("Trend_" + i).setUseStressedEs(useSEsTrend);
	            	simulator.getTrendFollowers().get("Trend_" + i).setUseStressedEs(useStressedEs);
	            	simulator.getTrendFollowers().get("Trend_" + i).setUseStressedVar(useStressedVar);	            	
	            	
	                simulator.getTrendFollowers().get("Trend_" + i).setVarLimit(distVarLimitTrend.nextDouble());
	            	simulator.getTrendFollowers().get("Trend_" + i).setVolWindow((int) Math.round(distVolWindowTrend.nextDouble()));
	            	
//	            	VariabilityVarLimit variabilityVarLimitTrend = VariabilityVarLimit.CONSTANT;
//	            	if (auxRandomVarTrend < e*0.1)    //Use when the probability of using a variable VaR limit changes along experiments
//	            		variabilityVarLimitTrend = VariabilityVarLimit.COUNTERCYCLICAL;
//	            	
//	            	simulator.getTrendFollowers().get("Trend_" + i).setVariabilityVarLimit(variabilityVarLimitTrend);
	            	simulator.getTrendFollowers().get("Trend_" + i).setVariabilityVarLimit(variabilityVarLimit);
	            	
	                simulator.getTrendFollowers().get("Trend_" + i).setEsLimit(distEsLimitTrend.nextDouble());
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
	            RandomDistDataGenerator distVarLimitValue = new RandomDistDataGenerator("VaR_Limit_Value", DistributionType.UNIFORM, varLimitFundMin, varLimitFundMax);
	            RandomDistDataGenerator distEsLimitValue = new RandomDistDataGenerator("ES_Limit_Value", DistributionType.UNIFORM, esLimitFundMin, esLimitFundMax);
	            RandomDistDataGenerator distVolWindowValue = new RandomDistDataGenerator("Vol_Window_Value", DistributionType.UNIFORM, (double) volWindowFundMin, (double) volWindowFundMax);
	            
	            // Uniform distributions U[0,1] to proxy binomial distributions to decide if short-selling is allowed, or VaR is used 
	            RandomDistDataGenerator distUnif01SSValue = new RandomDistDataGenerator("Unif01_SS_Value", DistributionType.UNIFORM, 0., 1.);  // U[0,1] to proxy a binomial distribution to decide if short-selling is allowed
	            RandomDistDataGenerator distUnif01VarValue = new RandomDistDataGenerator("Unif01_Var_Value", DistributionType.UNIFORM, 0., 1.);
	            RandomDistDataGenerator distUnif01EsValue = new RandomDistDataGenerator("Unif01_Es_Value", DistributionType.UNIFORM, 0., 1.);
                	            
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
	                

	                // Set VaR and ES parameters
	                UseVar useVarValue = UseVar.FALSE;
	                UseEs useEsValue = UseEs.FALSE;
	                double auxRandomVarValue = distUnif01VarValue.nextDouble();
	            	if (auxRandomVarValue <= probVarValue) 
	            		useVarValue = UseVar.TRUE;
	            	if (auxRandomVarValue > probVarValue && auxRandomVarValue <= probVarValue + probEsValue)
	            		useEsValue = UseEs.TRUE;

	                simulator.getValueInvestors().get("Value_" + i).setUseVar(useVarValue);
	                simulator.getValueInvestors().get("Value_" + i).setUseEs(useEsValue);

//	            	UseStressedEs useSEsValue = UseStressedEs.FALSE;
//	            	if (distUnif01EsValue.nextDouble() < e*0.1)    //Use when the probabiliy of using stressed ES changes along experiments
//	            		useSEsValue = UseStressedEs.TRUE;
//	            	
//	            	simulator.getValueInvestors().get("Value_" + i).setUseStressedEs(useSEsValue);
	            	simulator.getValueInvestors().get("Value_" + i).setUseStressedEs(useStressedEs);
	            	simulator.getValueInvestors().get("Value_" + i).setUseStressedVar(useStressedVar);
	            	
	                simulator.getValueInvestors().get("Value_" + i).setVarLimit(distVarLimitValue.nextDouble());
	            	simulator.getValueInvestors().get("Value_" + i).setVolWindow((int) Math.round(distVolWindowValue.nextDouble()));
	            	
//	            	VariabilityVarLimit variabilityVarLimitValue = VariabilityVarLimit.CONSTANT;
//	            	if (auxRandomVarValue < e*0.1)    //Use when the probability of using a variable VaR limit changes along experiments
//	            		variabilityVarLimitValue = VariabilityVarLimit.COUNTERCYCLICAL;
//	            	
//	            	simulator.getValueInvestors().get("Value_" + i).setVariabilityVarLimit(variabilityVarLimitValue);
	            	simulator.getValueInvestors().get("Value_" + i).setVariabilityVarLimit(variabilityVarLimit);

	                simulator.getValueInvestors().get("Value_" + i).setEsLimit(distEsLimitValue.nextDouble());
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
	
	            // TODO: Create time series and charts for ES
	            // Create time series for charts - IBM
	            	
		        for (int tr = 0; tr < numTrends/10; tr++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
		        	int trendID = tr;
		        	DoubleTimeSeries positions_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM");
		        	DoubleTimeSeries varPositionsReduced_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolioVarReductions().getTsPosition("IBM");
		        	
		        	DoubleTimeSeries orders_IBM = new DoubleTimeSeries();
		        	orders_IBM.add(0, simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM").get(0));  // Order at t=0
		        	for (int i = 1; i < numTicks; i++) {
		        		orders_IBM.add(i,  simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM").get(i) - simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM").get(i-1));
		        	}
		        	
		        	DoubleTimeSeries varSelloffOrders_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getTsVarSelloff().get("IBM");   // Sell-off orders due to VaR
		        		                
	        		atcPosTrend_IBM.populateSeries(e, run, "IBM", "pos_T_" + tr, positions_IBM);
					atcVarPosReducedTrend_IBM.populateSeries(e, run, "IBM", "pos_Red_T_" + tr, varPositionsReduced_IBM);
					atcOrdersTrend_IBM.populateSeries(e, run, "IBM", "orders_T_" + tr, orders_IBM);
					atcVarSelloffOrdersTrend_IBM.populateSeries(e, run, "IBM", "selloff_T_" + tr, varSelloffOrders_IBM);
	        		atcWealthTrend_IBM.populateSeries(e, run, "IBM", "wealth_T_" + tr, StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), positions_IBM));
		        }

		        for (int val = 0; val < numFunds/10; val++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
		        	int valueID = val;
		        	DoubleTimeSeries positions_IBM = simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM");
		        	DoubleTimeSeries varPositionsReduced_IBM = simulator.getValueInvestors().get("Value_" + valueID).getPortfolioVarReductions().getTsPosition("IBM");
		        	
		        	DoubleTimeSeries orders_IBM = new DoubleTimeSeries();
		        	orders_IBM.add(0, simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM").get(0));  // Order at t=0
		        	for (int i = 1; i < numTicks; i++) {
		        		orders_IBM.add(i,  simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM").get(i) - simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM").get(i-1));
		        	}
		        	
		        	DoubleTimeSeries varSelloffOrders_IBM = simulator.getValueInvestors().get("Value_" + valueID).getTsVarSelloff().get("IBM");   // Sell-off orders due to VaR

	        		atcPosFund_IBM.populateSeries(e, run, "IBM", "pos_F_" + val, positions_IBM);
	        		atcVarPosReducedFund_IBM.populateSeries(e, run, "IBM", "pos_Red_F_" + val, varPositionsReduced_IBM);
					atcOrdersFund_IBM.populateSeries(e, run, "IBM", "orders_F_" + val, orders_IBM);
					atcVarSelloffOrdersFund_IBM.populateSeries(e, run, "IBM", "selloff_F_" + val, varSelloffOrders_IBM);
	        		atcWealthFund_IBM.populateSeries(e, run, "IBM", "wealth_F_" + val, StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), positions_IBM));
		        }

		        atcPrices.populateSeries(e, run, "IBM", "P", simulator.getPrices("IBM"));
	            atcValues.populateSeries(e, run, "IBM", "V", simulator.getFundValues("IBM"));
	            
	            
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
//		        atcPrices.populateSeries(e, run, "MSFT", "P", simulator.getPrices("MSFT"));
//	            atcValues.populateSeries(e, run, "MSFT", "V", simulator.getFundValues("MSFT"));

	            // Create time series for charts - GOOG
            	
//		        for (int tr = 0; tr < numTrends/10; tr++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
//		        	int trendID = tr;
//		        	DoubleTimeSeries positions_GOOG = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("GOOG");
//		        	DoubleTimeSeries varPositionsReduced_GOOG = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolioVarReductions().getTsPosition("GOOG");
//		        	DoubleTimeSeries varSelloffOrders_GOOG = simulator.getTrendFollowers().get("Trend_" + trendID).getTsVarSelloff().get("GOOG");   // Sell-off orders due to VaR
//		        	
//	        		atcPosTrend_GOOG.populateSeries(e, run, "GOOG", "pos_T_" + tr, positions_GOOG);
//					atcVarPosReducedTrend_GOOG.populateSeries(e, run, "GOOG", "pos_Red_T_" + tr, varPositionsReduced_GOOG);
//					atcVarSelloffOrdersTrend_GOOG.populateSeries(e, run, "GOOG", "selloff_T_" + tr, varSelloffOrders_GOOG);
//	        		atcWealthTrend_GOOG.populateSeries(e, run, "GOOG", "wealth_T_" + tr, StatsTimeSeries.deltaWealth(simulator.getPrices("GOOG"), positions_GOOG));
//		        }
//
//		        for (int val = 0; val < numFunds/10; val++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
//		        	int valueID = val;
//		        	DoubleTimeSeries positions_GOOG = simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("GOOG");
//		        	DoubleTimeSeries varPositionsReduced_GOOG = simulator.getValueInvestors().get("Value_" + valueID).getPortfolioVarReductions().getTsPosition("GOOG");
//		        	DoubleTimeSeries varSelloffOrders_GOOG = simulator.getValueInvestors().get("Value_" + valueID).getTsVarSelloff().get("GOOG");   // Sell-off orders due to VaR
//
//	        		atcPosFund_GOOG.populateSeries(e, run, "GOOG", "pos_F_" + val, positions_GOOG);
//					atcVarPosReducedFund_GOOG.populateSeries(e, run, "GOOG", "pos_Red_F_" + val, varPositionsReduced_GOOG);
//					atcVarSelloffOrdersFund_GOOG.populateSeries(e, run, "GOOG", "selloff_F_" + val, varSelloffOrders_GOOG);
//	        		atcWealthFund_GOOG.populateSeries(e, run, "GOOG", "wealth_F_" + val, StatsTimeSeries.deltaWealth(simulator.getPrices("GOOG"), positions_GOOG));
//		        }
//
//		        atcPrices.populateSeries(e, run, "GOOG", "P", simulator.getPrices("GOOG"));
//	            atcValues.populateSeries(e, run, "GOOG", "V", simulator.getFundValues("GOOG"));
//	            
//	            // Create time series for charts - Spreads
//	            
	            DoubleTimeSeries spread_IBM_MSFT = StatsTimeSeries.substraction(simulator.getPrices("IBM"), simulator.getPrices("MSFT"));
//		        DoubleTimeSeries spread_IBM_GOOG = StatsTimeSeries.substraction(simulator.getPrices("IBM"), simulator.getPrices("GOOG"));
		        atcSpreads.populateSeries(e, run, "IBM_MSFT", "S", spread_IBM_MSFT);
//		        atcSpreads.populateSeries(e, run, "IBM_GOOG", "S", spread_IBM_GOOG);
//		        
	            // Create time series for charts - VaR
            	
		        for (int tr = 0; tr < numTrends/10; tr++) {  // Plot only a sample of time series to avoid memory problems in graphics
		        	int trendID = tr;
		        	DoubleTimeSeries preTradeVar = simulator.getTrendFollowers().get("Trend_" + trendID).getTsVarPreTrade();
		        	DoubleTimeSeries postTradeVar = simulator.getTrendFollowers().get("Trend_" + trendID).getTsVarPostTrade();
		        	
		        	atcPreTradeVarTrend.populateSeries(e, run, "preVar_T_" + tr, preTradeVar);
	        		atcPostTradeVarTrend.populateSeries(e, run, "postVar_T_" + tr, postTradeVar);
	        		
	        		atcVarLimitTrend.populateSeries(e, run, "LVar_T_" + tr, simulator.getTrendFollowers().get("Trend_" + trendID).getTsVarLimit());
		        }
		        
		        for (int va = 0; va < numFunds/10; va++) {  // Plot only a sample of time series to avoid memory problems in graphics
		        	int valueID = va;
		        	DoubleTimeSeries preTradeVar = simulator.getValueInvestors().get("Value_" + valueID).getTsVarPreTrade();
		        	DoubleTimeSeries postTradeVar = simulator.getValueInvestors().get("Value_" + valueID).getTsVarPostTrade();
		        		                
		        	atcPreTradeVarFund.populateSeries(e, run, "preVar_F_" + va, preTradeVar);
	        		atcPostTradeVarFund.populateSeries(e, run, "postVar_F_" + va, postTradeVar);
	        		
	        		atcVarLimitFund.populateSeries(e, run, "LVar_F_" + va, simulator.getValueInvestors().get("Value_" + valueID).getTsVarLimit());
		        }
        
//	            // Create time series for charts - Failures
//	            
//	            atcFailures.populateSeries(e, run, "failures_F", simulator.getFundFailures());
//	            atcFailures.populateSeries(e, run, "failures_T", simulator.getTrendFailures());
		        
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
    	            logger.debug("AVG WEALTH INCREMENT - F: {}, T: {}", simulator.getFundAvgWealthIncrement(secId).get(numTicks-1), simulator.getTrendAvgWealthIncrement(secId).get(numTicks-1));
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
	            	tsFundTotalOrdersList.add(shareIndex + run*numAssets, simulator.getFundTotalOrders(secId));      // time series list of FUND aggregated orders [(nRuns * nAssets) x nTicks]
	            	tsTrendTotalOrdersList.add(shareIndex + run*numAssets, simulator.getTrendTotalOrders(secId));    // time series list of TREND aggregated orders [(nRuns * nAssets) x nTicks]
	            	tsFundAvgWealthIncrementList.add(shareIndex + run*numAssets, simulator.getFundAvgWealthIncrement(secId));      // time series list of FUND wealth increment [(nRuns * nAssets) x nTicks]
	            	tsTrendAvgWealthIncrementList.add(shareIndex + run*numAssets, simulator.getTrendAvgWealthIncrement(secId));    // time series list of TREND wealth increment [(nRuns * nAssets) x nTicks]	            	
	            	tsFundVarReducedVolumeList.add(shareIndex + run*numAssets, simulator.getFundVarReducedVolume(secId));      // time series list of FUND volume reduced due to VaR [(nRuns * nAssets) x nTicks]
	            	tsTrendVarReducedVolumeList.add(shareIndex + run*numAssets, simulator.getTrendVarReducedVolume(secId));    // time series list of TREND volume reduced due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsFundVarReducedOrdersList.add(shareIndex + run*numAssets, simulator.getFundTotalVarReducedOrders(secId));      // time series list of FUND reduction orders due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsTrendVarReducedOrdersList.add(shareIndex + run*numAssets, simulator.getTrendTotalVarReducedOrders(secId));    // time series list of TREND reduction orders due to VaR [(nRuns * nAssets) x nTicks]
	            	tsFundVarSelloffOrdersList.add(shareIndex + run*numAssets, simulator.getFundTotalVarSelloffOrders(secId));      // time series list of FUND sell-off orders due to VaR [(nRuns * nAssets) x nTicks]
	            	tsTrendVarSelloffOrdersList.add(shareIndex + run*numAssets, simulator.getTrendTotalVarSelloffOrders(secId));    // time series list of TREND sell-off orders due to VaR [(nRuns * nAssets) x nTicks]
	            	tsFundVarSelloffVolumeList.add(shareIndex + run*numAssets, simulator.getFundVarSelloffVolume(secId));           // time series list of FUND sell-off volume due to VaR [(nRuns * nAssets) x nTicks]
	            	tsTrendVarSelloffVolumeList.add(shareIndex + run*numAssets, simulator.getTrendVarSelloffVolume(secId));         // time series list of TREND sell-off volume due to VaR [(nRuns * nAssets) x nTicks]
	            	tsFundEsReducedVolumeList.add(shareIndex + run*numAssets, simulator.getFundEsReducedVolume(secId));      // time series list of FUND volume reduced due to ES [(nRuns * nAssets) x nTicks]
	            	tsTrendEsReducedVolumeList.add(shareIndex + run*numAssets, simulator.getTrendEsReducedVolume(secId));    // time series list of TREND volume reduced due to ES [(nRuns * nAssets) x nTicks]
//	            	tsFundEsReducedOrdersList.add(shareIndex + run*numAssets, simulator.getFundTotalEsReducedOrders(secId));      // time series list of FUND reduction orders due to ES [(nRuns * nAssets) x nTicks]
//	            	tsTrendEsReducedOrdersList.add(shareIndex + run*numAssets, simulator.getTrendTotalEsReducedOrders(secId));    // time series list of TREND reduction orders due to ES [(nRuns * nAssets) x nTicks]
	            	tsFundEsSelloffOrdersList.add(shareIndex + run*numAssets, simulator.getFundTotalEsSelloffOrders(secId));      // time series list of FUND sell-off orders due to ES [(nRuns * nAssets) x nTicks]
	            	tsTrendEsSelloffOrdersList.add(shareIndex + run*numAssets, simulator.getTrendTotalEsSelloffOrders(secId));    // time series list of TREND sell-off orders due to ES [(nRuns * nAssets) x nTicks]
	            	tsFundEsSelloffVolumeList.add(shareIndex + run*numAssets, simulator.getFundEsSelloffVolume(secId));           // time series list of FUND sell-off volume due to ES [(nRuns * nAssets) x nTicks]
	            	tsTrendEsSelloffVolumeList.add(shareIndex + run*numAssets, simulator.getTrendEsSelloffVolume(secId));         // time series list of TREND sell-off volume due to ES [(nRuns * nAssets) x nTicks]
	            	tsNumberFundsHittingVarLimitList.add(shareIndex + run*numAssets, simulator.getNumberFundsHittingVarLimit(secId));     // time series list of FUNDs triggering their VaR limit [(nRuns * nAssets) x nTicks]
	            	tsNumberTrendsHittingVarLimitList.add(shareIndex + run*numAssets, simulator.getNumberTrendsHittingVarLimit(secId));   // time series list of TRENDs triggering their VaR limit [(nRuns * nAssets) x nTicks]
	            	tsNumberFundsHittingEsLimitList.add(shareIndex + run*numAssets, simulator.getNumberFundsHittingEsLimit(secId));     // time series list of FUNDs triggering their ES limit [(nRuns * nAssets) x nTicks]
	            	tsNumberTrendsHittingEsLimitList.add(shareIndex + run*numAssets, simulator.getNumberTrendsHittingEsLimit(secId));   // time series list of TRENDs triggering their ES limit [(nRuns * nAssets) x nTicks]
	            }
	            	            
	            tsFundAvgVarList.add(run, simulator.getFundAvgVaR());      // time series list of FUND avg VaR [nRuns x nTicks] (post trade)
	            tsTrendAvgVarList.add(run, simulator.getTrendAvgVaR());    // time series list of TREND avg VaR [nRuns x nTicks] (post trade)
	            tsFundAvgEsList.add(run, simulator.getFundAvgEs());        // time series list of FUND avg ES [nRuns x nTicks] (post trade)
	            tsTrendAvgEsList.add(run, simulator.getTrendAvgEs());      // time series list of TREND avg ES [nRuns x nTicks] (post trade)

	            tsFundAvgStressedVarList.add(run, simulator.getFundAvgStressedVaR());      // time series list of FUND avg stressed VaR [nRuns x nTicks] (post trade)
	            tsTrendAvgStressedVarList.add(run, simulator.getTrendAvgStressedVaR());    // time series list of TREND avg stressed VaR [nRuns x nTicks] (post trade)
	            tsFundAvgStressedEsList.add(run, simulator.getFundAvgStressedEs());        // time series list of FUND avg stressed ES [nRuns x nTicks] (post trade)
	            tsTrendAvgStressedEsList.add(run, simulator.getTrendAvgStressedEs());      // time series list of TREND avg stressed ES [nRuns x nTicks] (post trade)

//	            tsFundAvgVarLimitList.add(run, simulator.getFundAvgVarLimit());         // time series list of FUND avg VaR limit [nRuns x nTicks]
//	            tsTrendAvgVarLimitList.add(run, simulator.getTrendAvgVarLimit());       // time series list of TREND avg VaR limit [nRuns x nTicks]
	            
//	            tsFundFailureList.add(run, simulator.getFundFailures());       // time series list of FUND failures [nRuns x nTicks]
//	            tsTrendFailureList.add(run, simulator.getTrendFailures());     // time series list of TREND failures [nRuns x nTicks]
	        }

	        
	        /**
	         *      Write results of current experiment to file for further analysis with R
	         */
	        
	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_price_timeseries_E" + e + ".csv").write(tsPricesList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundvalues_timeseries_E" + e + ".csv").write(tsFundValuesList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_totalvolume_timeseries_E" + e + ".csv").write(tsTotalVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundvolume_timeseries_E" + e + ".csv").write(tsFundVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendvolume_timeseries_E" + e + ".csv").write(tsTrendVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundorders_timeseries_E" + e + ".csv").write(tsFundTotalOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendorders_timeseries_E" + e + ".csv").write(tsTrendTotalOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundwealth_timeseries_E" + e + ".csv").write(tsFundAvgWealthIncrementList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendwealth_timeseries_E" + e + ".csv").write(tsTrendAvgWealthIncrementList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundvarreducedvolume_timeseries_E" + e + ".csv").write(tsFundVarReducedVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendvarreducedvolume_timeseries_E" + e + ".csv").write(tsTrendVarReducedVolumeList);
////	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundvarreducedorders_timeseries_E" + e + ".csv").write(tsFundVarReducedOrdersList);
////	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendvarreducedorders_timeseries_E" + e + ".csv").write(tsTrendVarReducedOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundvarsellofforders_timeseries_E" + e + ".csv").write(tsFundVarSelloffOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendvarsellofforders_timeseries_E" + e + ".csv").write(tsTrendVarSelloffOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundvarselloffvolume_timeseries_E" + e + ".csv").write(tsFundVarSelloffVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendvarselloffvolume_timeseries_E" + e + ".csv").write(tsTrendVarSelloffVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundesreducedvolume_timeseries_E" + e + ".csv").write(tsFundEsReducedVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendesreducedvolume_timeseries_E" + e + ".csv").write(tsTrendEsReducedVolumeList);
////	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundesreducedorders_timeseries_E" + e + ".csv").write(tsFundEsReducedOrdersList);
////	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendesreducedorders_timeseries_E" + e + ".csv").write(tsTrendEsReducedOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundessellofforders_timeseries_E" + e + ".csv").write(tsFundEsSelloffOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendessellofforders_timeseries_E" + e + ".csv").write(tsTrendEsSelloffOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundesselloffvolume_timeseries_E" + e + ".csv").write(tsFundEsSelloffVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendesselloffvolume_timeseries_E" + e + ".csv").write(tsTrendEsSelloffVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundvar_timeseries_E" + e + ".csv").write(tsFundAvgVarList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendvar_timeseries_E" + e + ".csv").write(tsTrendAvgVarList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundes_timeseries_E" + e + ".csv").write(tsFundAvgEsList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendes_timeseries_E" + e + ".csv").write(tsTrendAvgEsList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundstressedvar_timeseries_E" + e + ".csv").write(tsFundAvgStressedVarList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendstressedvar_timeseries_E" + e + ".csv").write(tsTrendAvgStressedVarList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundstressedes_timeseries_E" + e + ".csv").write(tsFundAvgStressedEsList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendstressedes_timeseries_E" + e + ".csv").write(tsTrendAvgStressedEsList);
////	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundvarlimit_timeseries_E" + e + ".csv").write(tsFundAvgVarLimitList);
////	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendvarlimit_timeseries_E" + e + ".csv").write(tsTrendAvgVarLimitList);
////	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundfailures_timeseries_E" + e + ".csv").write(tsFundFailureList);
////	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendfailures_timeseries_E" + e + ".csv").write(tsTrendFailureList);
//	        
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundshittingVar_timeseries_E" + e + ".csv").write(tsNumberFundsHittingVarLimitList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendshittingVar_timeseries_E" + e + ".csv").write(tsNumberTrendsHittingVarLimitList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_fundshittingEs_timeseries_E" + e + ".csv").write(tsNumberFundsHittingEsLimitList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-es-abm-simulation/list_trendshittingEs_timeseries_E" + e + ".csv").write(tsNumberTrendsHittingEsLimitList);
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
//        	charts.draw(atcWealthTrend_GOOG);
//            charts.draw(atcPosTrend_GOOG);
//            charts.draw(atcVarPosReducedTrend_GOOG);
//            charts.draw(atcVarSelloffOrdersTrend_GOOG);
//            charts.draw(atcWealthTrend_MSFT);
//            charts.draw(atcPosTrend_MSFT);
            charts.draw(atcWealthTrend_IBM);
            charts.draw(atcPosTrend_IBM);
//            charts.draw(atcVarPosReducedTrend_IBM);
//        	charts.draw(atcOrdersTrend_IBM);
        	charts.draw(atcVarSelloffOrdersTrend_IBM);
//        	charts.draw(atcPreTradeVarTrend);
            charts.draw(atcPostTradeVarTrend);
            charts.draw(atcVarLimitTrend);
        }
        
        if (numFunds > 0) {
//        	charts.draw(atcWealthFund_GOOG);
//            charts.draw(atcPosFund_GOOG);
//            charts.draw(atcVarPosReducedFund_GOOG);
//            charts.draw(atcVarSelloffOrdersFund_GOOG);
//            charts.draw(atcWealthFund_MSFT);
//            charts.draw(atcPosFund_MSFT);
            charts.draw(atcWealthFund_IBM);
            charts.draw(atcPosFund_IBM);
//            charts.draw(atcVarPosReducedFund_IBM);
//        	charts.draw(atcOrdersFund_IBM);
        	charts.draw(atcVarSelloffOrdersFund_IBM);
            charts.draw(atcValues);            
//            charts.draw(atcValuePriceDiff);
//            charts.draw(atcValuePriceDiff_F1);
//            charts.draw(atcPreTradeVarFund);
            charts.draw(atcPostTradeVarFund);
            charts.draw(atcVarLimitFund);
        }
        
        charts.draw(atcPrices);
//        charts.draw(atcVolumeFund);
//        charts.draw(atcVolumeTrend);
//        charts.draw(atcFailures);
//End comment */
       
        double stopTime = System.nanoTime();
        System.out.println("Execution time: " + (stopTime - startTime)/1000000000 + " seconds");
        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
    }

}
