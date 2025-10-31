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
import info.financialecology.finance.abm.model.agent.Trader.UseVar;
import info.financialecology.finance.abm.model.agent.Trader.UseStressedVar;
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
public class TrendValueLSVarMultiAssetAbmSimulation_BLTh {

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
        
        int numExp = 10;   // TODO - Delete when this is automatically extracted from the sequences in the param file

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

        VersatileTimeSeriesCollection atcOrdersFund_IBM        = new VersatileTimeSeriesCollection("FUND Orders for IBM");
        VersatileTimeSeriesCollection atcOrdersTrend_IBM       = new VersatileTimeSeriesCollection("TREND Orders for IBM");
        VersatileTimeSeriesCollection atcOrdersLS_IBM          = new VersatileTimeSeriesCollection("LS Orders for IBM");

        VersatileTimeSeriesCollection atcSelloffOrdersFund_IBM    = new VersatileTimeSeriesCollection("FUND sell-off orders for IBM");
        VersatileTimeSeriesCollection atcSelloffOrdersTrend_IBM   = new VersatileTimeSeriesCollection("TREND sell-off orders for IBM");
        VersatileTimeSeriesCollection atcSelloffOrdersLS_IBM      = new VersatileTimeSeriesCollection("LS sell-off orders for IBM");
        VersatileTimeSeriesCollection atcSelloffOrdersFund_GOOG   = new VersatileTimeSeriesCollection("FUND sell-off orders for GOOG");
        VersatileTimeSeriesCollection atcSelloffOrdersTrend_GOOG  = new VersatileTimeSeriesCollection("TREND sell-off orders for GOOG");
        VersatileTimeSeriesCollection atcSelloffOrdersLS_GOOG     = new VersatileTimeSeriesCollection("LS sell-off orders for GOOG");

        VersatileTimeSeriesCollection atcPosReducedFund_IBM    = new VersatileTimeSeriesCollection("FUND reduced positions for IBM");
        VersatileTimeSeriesCollection atcPosReducedFund_GOOG   = new VersatileTimeSeriesCollection("FUND reduced positions for GOOG");
        VersatileTimeSeriesCollection atcPosReducedTrend_IBM   = new VersatileTimeSeriesCollection("TREND reduced positions for IBM");
        VersatileTimeSeriesCollection atcPosReducedTrend_GOOG  = new VersatileTimeSeriesCollection("TREND reduced positions for GOOG");
        VersatileTimeSeriesCollection atcPosReducedLS_IBM      = new VersatileTimeSeriesCollection("LS reduced positions for IBM");
        VersatileTimeSeriesCollection atcPosReducedLS_GOOG     = new VersatileTimeSeriesCollection("LS reduced positions for GOOG");

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
        	
        	double capFactTrend = params.capFactorTrend;
        	
//        	numLS = 0;
//        	capFactTrend = 1;
//        	if (numExp > 1) {
//        		numLS = e*20;
//        		capFactTrend = 1 + e*0.02;
//        		liquidity.set(0, 400 + e*10);
//        		liquidity.set(1, 400 + e*10);
////        		liquidity.set(2, 400 + e*15);
//        	}
//        	System.out.print("numLS = " + numLS + "\n");
//        	System.out.print("capFactTrend = " + capFactTrend + "\n");
//        	System.out.print("liq = " + liquidity + "\n");
        	
        	double varLimitLSMin = params.varLimitLSMin;
        	double varLimitLSMax = params.varLimitLSMax;
        	double varLimitTrendMin = params.varLimitTrendMin;
        	double varLimitTrendMax = params.varLimitTrendMax;
        	double varLimitFundMin = params.varLimitFundMin;
        	double varLimitFundMax = params.varLimitFundMax;
        	
//        	if (numExp > 1) {
//        		varLimitFundMin = 5 + e*5;
//        		varLimitFundMax = 5 + e*5;
//        		varLimitTrendMin = 5 + e*5;
//        		varLimitTrendMax = 5 + e*5;
//        		varLimitLSMin = 5 + e*5;
//        		varLimitLSMax = 5 + e*5;
//        	}
        	System.out.print("varLimit Trend = [" + varLimitTrendMin + ", " + varLimitTrendMax + "]" + "\n");
        	System.out.print("varLimit Fund = [" + varLimitFundMin + ", " + varLimitFundMax + "]" + "\n");
        	System.out.print("varLimit LS = [" + varLimitLSMin + ", " + varLimitLSMax + "]" + "\n");
        	
        	int volWindowVarFundMin    = params.volWindowVarFundMin;
        	int volWindowVarFundMax    = params.volWindowVarFundMax;
        	int volWindowVarTrendMin   = params.volWindowVarTrendMin;
        	int volWindowVarTrendMax   = params.volWindowVarTrendMax;
        	int volWindowVarLSMin      = params.volWindowVarLSMin;
        	int volWindowVarLSMax      = params.volWindowVarLSMax;
        	
//        	if (numExp > 1) {
//        		volWindowVarFundMin = 5 + e*3;
//        		volWindowVarFundMax = 5 + e*3;
//        		volWindowVarTrendMin = 5 + e*3;
//        		volWindowVarTrendMax = 5 + e*3;
//        		volWindowVarLSMin = 5 + e*3;
//        		volWindowVarLSMax = 5 + e*3;
//        	}
        	System.out.print("volWindow Trend = [" + volWindowVarTrendMin + ", " + volWindowVarTrendMax + "]" + "\n");
        	System.out.print("volWindow Fund = [" + volWindowVarFundMin + ", " + volWindowVarFundMax + "]" + "\n");
        	System.out.print("volWindow LS = [" + volWindowVarLSMin + ", " + volWindowVarLSMax + "]" + "\n");
        	
        	double probVarValue    = params.probVarFund;
        	double probVarTrend    = params.probVarTrend;
        	double probVarLS       = params.probVarLS;
        	
//        	if (numExp > 1) {
//        		probVarValue = 0 + e*0.1;
//        		probVarTrend = 0 + e*0.1;
//        		probVarLS = 0 + e*0.1;
//        	}
//        	System.out.print("probVar Fund = " + probVarValue + "\n");
//        	System.out.print("probVar Trend = " + probVarTrend + "\n");
//        	System.out.print("probVar LS = " + probVarLS + "\n");
        	
            VariabilityVarLimit variabilityVarLimit = VariabilityVarLimit.CONSTANT;
//        	VariabilityVarLimit variabilityVarLimit = VariabilityVarLimit.COUNTERCYCLICAL;
        	
            UseStressedVar useStressedVar = UseStressedVar.FALSE;  // !! Ensure that VaR is used before setting stressedVar to 'TRUE'
            
        	
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
            
            DoubleTimeSeriesList tsFundSelloffOrdersList        = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendSelloffOrdersList       = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSSelloffOrdersList          = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundSelloffVolumeList        = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendSelloffVolumeList       = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSSelloffVolumeList          = new DoubleTimeSeriesList();
            
            DoubleTimeSeriesList tsFundAvgVarList               = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendAvgVarList              = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSAvgVarList                 = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundAvgStressedVarList       = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendAvgStressedVarList      = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSAvgStressedVarList         = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsFundAvgVarLimitList          = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendAvgVarLimitList         = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSAvgVarLimitList            = new DoubleTimeSeriesList();

            DoubleTimeSeriesList tsFundFailureList              = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsTrendFailureList             = new DoubleTimeSeriesList();
            DoubleTimeSeriesList tsLSFailureList                = new DoubleTimeSeriesList();
            
        
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
	            RandomDistDataGenerator distVolWindowVarTrend = new RandomDistDataGenerator("Vol_Window_Trend", DistributionType.UNIFORM, (double) volWindowVarTrendMin, (double) volWindowVarTrendMax);
	            
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
//    	            			(int) Math.round(maLongTicks.get(secId).nextDouble()), (int) Math.round(bcTicksTrend.get(secId).nextDouble()), params.capFactorTrend, 
    	            			(int) Math.round(maLongTicks.get(secId).nextDouble()), (int) Math.round(bcTicksTrend.get(secId).nextDouble()), capFactTrend,
    	            			params.volWindowStratTrend, trendMultiplier, positionUpdateTrend, orderOrPositionStrategyTrend, 
    	            			variabilityCapFactorTrend, shortSellingTrend);
	                }
	                
	                // Set VaR parameters
	                UseVar useVarTrend = UseVar.TRUE;
	            	if (distUnif01VarTrend.nextDouble() > probVarTrend) 
	            		useVarTrend = UseVar.FALSE;
	            	
	            	simulator.getTrendFollowers().get("Trend_" + i).setUseVar(useVarTrend);
	            	
//	            	UseStressedVar useSVarTrend = UseStressedVar.FALSE;
//	            	if (distUnif01VarTrend.nextDouble() < e*0.1)    //Use when the probabiliy of using stressed VaR changes along experiments
//	            		useSVarTrend = UseStressedVar.TRUE;
//
//	            	simulator.getTrendFollowers().get("Trend_" + i).setUseStressedVar(useSVarTrend);
	            	simulator.getTrendFollowers().get("Trend_" + i).setUseStressedVar(useStressedVar);
	            	
	                simulator.getTrendFollowers().get("Trend_" + i).setVarLimit(distVarLimitTrend.nextDouble());
	            	simulator.getTrendFollowers().get("Trend_" + i).setVolWindowVar((int) Math.round(distVolWindowVarTrend.nextDouble()));
	            	
//	            	VariabilityVarLimit variabilityVarLimitTrend = VariabilityVarLimit.CONSTANT;
//	            	if (distUnif01VarTrend.nextDouble() < e*0.1)    //Use when the probability of using a variable VaR limit changes along experiments
//	            		variabilityVarLimitTrend = VariabilityVarLimit.COUNTERCYCLICAL;
//	            	
//	            	simulator.getTrendFollowers().get("Trend_" + i).setVariabilityVarLimit(variabilityVarLimitTrend);
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
	            RandomDistDataGenerator distVarLimitValue = new RandomDistDataGenerator("VaR_Limit_Value", DistributionType.UNIFORM, varLimitFundMin, varLimitFundMax);
	            RandomDistDataGenerator distVolWindowVarValue = new RandomDistDataGenerator("Vol_Window_Value", DistributionType.UNIFORM, (double) volWindowVarFundMin, (double) volWindowVarFundMax);
	            
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
	                if (distUnif01VarValue.nextDouble() > probVarValue) 
	            		useVarValue = UseVar.FALSE;
	            	
	                simulator.getValueInvestors().get("Value_" + i).setUseVar(useVarValue);
	                
//	            	UseStressedVar useSVarValue = UseStressedVar.FALSE;
//	            	if (distUnif01VarValue.nextDouble() < e*0.1)    //Use when the probabiliy of using stressed VaR changes along experiments
//	            		useSVarValue = UseStressedVar.TRUE;
//
//	            	simulator.getValueInvestors().get("Value_" + i).setUseStressedVar(useSVarValue);
	            	simulator.getValueInvestors().get("Value_" + i).setUseStressedVar(useStressedVar);
	            	
	                simulator.getValueInvestors().get("Value_" + i).setVarLimit(distVarLimitValue.nextDouble());
	            	simulator.getValueInvestors().get("Value_" + i).setVolWindowVar((int) Math.round(distVolWindowVarValue.nextDouble()));
	            	
//	            	VariabilityVarLimit variabilityVarLimitValue = VariabilityVarLimit.CONSTANT;
//	            	if (distUnif01VarValue.nextDouble() < e*0.1)    //Use when the probability of using a variable VaR limit changes along experiments
//	            		variabilityVarLimitValue = VariabilityVarLimit.COUNTERCYCLICAL;
//	            	
//	            	simulator.getValueInvestors().get("Value_" + i).setVariabilityVarLimit(variabilityVarLimitValue);
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
	            RandomDistDataGenerator distVarLimitLS = new RandomDistDataGenerator("VaR_Limit_LS", DistributionType.UNIFORM, varLimitLSMin, varLimitLSMax);
	            RandomDistDataGenerator distVolWindowVarLS = new RandomDistDataGenerator("Vol_Window_LS", DistributionType.UNIFORM, (double) volWindowVarLSMin, (double) volWindowVarLSMax);
	            
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
	            	if (distUnif01VarLS.nextDouble() > probVarLS) 
	            		useVarLS = UseVar.FALSE;
	            	
	            	simulator.getLSInvestors().get("LS_" + i).setUseVar(useVarLS);
	            	
//	            	UseStressedVar useSVarLS = UseStressedVar.FALSE;
//	            	if (distUnif01VarLS.nextDouble() < e*0.1)    //Use when the probabiliy of using stressed VaR changes along experiments
//	            		useSVarLS = UseStressedVar.TRUE;
//	            	
//	            	simulator.getLSInvestors().get("LS_" + i).setUseStressedVar(useSVarLS);
	            	simulator.getLSInvestors().get("LS_" + i).setUseStressedVar(useStressedVar);
	            	
	                simulator.getLSInvestors().get("LS_" + i).setVarLimit(distVarLimitLS.nextDouble());
	                simulator.getLSInvestors().get("LS_" + i).setVolWindowVar((int) Math.round(distVolWindowVarLS.nextDouble()));
	                
//	                VariabilityVarLimit variabilityVarLimitLS = VariabilityVarLimit.CONSTANT;
//	            	if (distUnif01VarLS.nextDouble() < e*0.1)   //Use when the probability of using a variable VaR limit changes along experiments
//	            		variabilityVarLimitLS = VariabilityVarLimit.COUNTERCYCLICAL;
//	                
//	                simulator.getLSInvestors().get("LS_" + i).setVariabilityVarLimit(variabilityVarLimitLS);
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
	
	            // Create time series for charts - IBM
	            	
		        for (int tr = 0; tr < numTrends/10; tr++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
		        	int trendID = tr;
		        	DoubleTimeSeries positions_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM");
		        	DoubleTimeSeries positionsReduced_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolioVarReductions().getTsPosition("IBM");
		        	
		        	DoubleTimeSeries orders_IBM = new DoubleTimeSeries();
		        	orders_IBM.add(0, simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM").get(0));  // Order at t=0
		        	for (int i = 1; i < numTicks; i++) {
		        		orders_IBM.add(i,  simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM").get(i) - simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("IBM").get(i-1));
		        	}
		        	
		        	DoubleTimeSeries selloffOrders_IBM = simulator.getTrendFollowers().get("Trend_" + trendID).getTsVarSelloff().get("IBM");   // Sell-off orders due to VaR
		        		                
	        		atcPosTrend_IBM.populateSeries(e, run, "IBM", "pos_T_" + tr, positions_IBM);
					atcPosReducedTrend_IBM.populateSeries(e, run, "IBM", "pos_Red_T_" + tr, positionsReduced_IBM);
					atcOrdersTrend_IBM.populateSeries(e, run, "IBM", "orders_T_" + tr, orders_IBM);
					atcSelloffOrdersTrend_IBM.populateSeries(e, run, "IBM", "selloff_T_" + tr, selloffOrders_IBM);
	        		atcWealthTrend_IBM.populateSeries(e, run, "IBM", "wealth_T_" + tr, StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), positions_IBM));
		        }

		        for (int val = 0; val < numFunds/10; val++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
		        	int valueID = val;
		        	DoubleTimeSeries positions_IBM = simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM");
		        	DoubleTimeSeries positionsReduced_IBM = simulator.getValueInvestors().get("Value_" + valueID).getPortfolioVarReductions().getTsPosition("IBM");
		        	
		        	DoubleTimeSeries orders_IBM = new DoubleTimeSeries();
		        	orders_IBM.add(0, simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM").get(0));  // Order at t=0
		        	for (int i = 1; i < numTicks; i++) {
		        		orders_IBM.add(i,  simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM").get(i) - simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("IBM").get(i-1));
		        	}
		        	
		        	DoubleTimeSeries selloffOrders_IBM = simulator.getValueInvestors().get("Value_" + valueID).getTsVarSelloff().get("IBM");   // Sell-off orders due to VaR

	        		atcPosFund_IBM.populateSeries(e, run, "IBM", "pos_F_" + val, positions_IBM);
	        		atcPosReducedFund_IBM.populateSeries(e, run, "IBM", "pos_Red_F_" + val, positionsReduced_IBM);
					atcOrdersFund_IBM.populateSeries(e, run, "IBM", "orders_F_" + val, orders_IBM);
					atcSelloffOrdersFund_IBM.populateSeries(e, run, "IBM", "selloff_F_" + val, selloffOrders_IBM);
	        		atcWealthFund_IBM.populateSeries(e, run, "IBM", "wealth_F_" + val, StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), positions_IBM));
		        }

		        for (int ls = 0; ls < numLS/10; ls++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
		        	int lsID = ls;
		        	DoubleTimeSeries positions_IBM = simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("IBM");
		        	DoubleTimeSeries positionsReduced_IBM = simulator.getLSInvestors().get("LS_" + lsID).getPortfolioVarReductions().getTsPosition("IBM");

		        	DoubleTimeSeries orders_IBM = new DoubleTimeSeries();		        	
		        	orders_IBM.add(0, simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("IBM").get(0));  // Order at t=0
		        	for (int i = 1; i < numTicks; i++) {
		        		orders_IBM.add(i,  simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("IBM").get(i) - simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("IBM").get(i-1));
		        	}
		        	
		        	DoubleTimeSeries selloffOrders_IBM = simulator.getLSInvestors().get("LS_" + lsID).getTsVarSelloff().get("IBM");   // Sell-off orders due to VaR

	        		atcPosLS_IBM.populateSeries(e, run, "IBM", "pos_LS_" + ls, positions_IBM);
	        		atcPosReducedLS_IBM.populateSeries(e, run, "IBM", "pos_Red_LS_" + ls, positionsReduced_IBM);
					atcOrdersLS_IBM.populateSeries(e, run, "IBM", "orders_LS_" + ls, orders_IBM);
					atcSelloffOrdersLS_IBM.populateSeries(e, run, "IBM", "selloff_LS_" + ls, selloffOrders_IBM);
		      		atcWealthLS_IBM.populateSeries(e, run, "IBM", "wealth_LS_" + ls, StatsTimeSeries.deltaWealth(simulator.getPrices("IBM"), positions_IBM));
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
            	
//		        for (int tr = 0; tr < numTrends/10; tr++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
//		        	int trendID = tr;
//		        	DoubleTimeSeries positions_GOOG = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolio().getTsPosition("GOOG");
//		        	DoubleTimeSeries positionsReduced_GOOG = simulator.getTrendFollowers().get("Trend_" + trendID).getPortfolioVarReductions().getTsPosition("GOOG");
//		        	DoubleTimeSeries selloffOrders_GOOG = simulator.getTrendFollowers().get("Trend_" + trendID).getTsVarSelloff().get("GOOG");   // Sell-off orders due to VaR
//		        	
//	        		atcPosTrend_GOOG.populateSeries(e, run, "GOOG", "pos_T_" + tr, positions_GOOG);
//					atcPosReducedTrend_GOOG.populateSeries(e, run, "GOOG", "pos_Red_T_" + tr, positionsReduced_GOOG);
//					atcSelloffOrdersTrend_GOOG.populateSeries(e, run, "GOOG", "selloff_T_" + tr, selloffOrders_GOOG);
//	        		atcWealthTrend_GOOG.populateSeries(e, run, "GOOG", "wealth_T_" + tr, StatsTimeSeries.deltaWealth(simulator.getPrices("GOOG"), positions_GOOG));
//		        }
//
//		        for (int val = 0; val < numFunds/10; val++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
//		        	int valueID = val;
//		        	DoubleTimeSeries positions_GOOG = simulator.getValueInvestors().get("Value_" + valueID).getPortfolio().getTsPosition("GOOG");
//		        	DoubleTimeSeries positionsReduced_GOOG = simulator.getValueInvestors().get("Value_" + valueID).getPortfolioVarReductions().getTsPosition("GOOG");
//		        	DoubleTimeSeries selloffOrders_GOOG = simulator.getValueInvestors().get("Value_" + valueID).getTsVarSelloff().get("GOOG");   // Sell-off orders due to VaR
//
//	        		atcPosFund_GOOG.populateSeries(e, run, "GOOG", "pos_F_" + val, positions_GOOG);
//					atcPosReducedFund_GOOG.populateSeries(e, run, "GOOG", "pos_Red_F_" + val, positionsReduced_GOOG);
//					atcSelloffOrdersFund_GOOG.populateSeries(e, run, "GOOG", "selloff_F_" + val, selloffOrders_GOOG);
//	        		atcWealthFund_GOOG.populateSeries(e, run, "GOOG", "wealth_F_" + val, StatsTimeSeries.deltaWealth(simulator.getPrices("GOOG"), positions_GOOG));
//		        }
//
//		        for (int ls = 0; ls < numLS/10; ls++) {  // 10 Nov 2014 - Plot only a sample of time series to avoid memory problems in graphics
//		        	int lsID = ls;
//		        	DoubleTimeSeries positions_GOOG = simulator.getLSInvestors().get("LS_" + lsID).getPortfolio().getTsPosition("GOOG");
//		        	DoubleTimeSeries positionsReduced_GOOG = simulator.getLSInvestors().get("LS_" + lsID).getPortfolioVarReductions().getTsPosition("GOOG");
//		        	DoubleTimeSeries selloffOrders_GOOG = simulator.getLSInvestors().get("LS_" + lsID).getTsVarSelloff().get("GOOG");   // Sell-off orders due to VaR
//		        	
//	        		atcPosLS_GOOG.populateSeries(e, run, "GOOG", "pos_LS_" + ls, positions_GOOG);
//					atcPosReducedLS_GOOG.populateSeries(e, run, "GOOG", "pos_Red_LS_" + ls, positionsReduced_GOOG);
//					atcSelloffOrdersLS_GOOG.populateSeries(e, run, "GOOG", "selloff_LS_" + ls, selloffOrders_GOOG);
//		      		atcWealthLS_GOOG.populateSeries(e, run, "GOOG", "wealth_LS_" + ls, StatsTimeSeries.deltaWealth(simulator.getPrices("GOOG"), positions_GOOG));
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
		        
		        for (int ls = 0; ls < numLS/10; ls++) {  // Plot only a sample of time series to avoid memory problems in graphics
		        	int lsID = ls;
		            DoubleTimeSeries preTradeVar = simulator.getLSInvestors().get("LS_" + lsID).getTsVarPreTrade();
		        	DoubleTimeSeries postTradeVar = simulator.getLSInvestors().get("LS_" + lsID).getTsVarPostTrade();
		        		                
		            atcPreTradeVarLS.populateSeries(e, run, "preVar_LS_" + ls, preTradeVar);
	        		atcPostTradeVarLS.populateSeries(e, run, "postVar_LS_" + ls, postTradeVar);
		        }
		        
		        
//	            // Create time series for charts - Failures
//	            
//	            atcFailures.populateSeries(e, run, "failures_F", simulator.getFundFailures());
//	            atcFailures.populateSeries(e, run, "failures_T", simulator.getTrendFailures());
//	            atcFailures.populateSeries(e, run, "failures_LS", simulator.getLSFailures());
		        
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
//	            	tsFundReducedVolumeList.add(shareIndex + run*numAssets, simulator.getFundReducedVolume(secId));      // time series list of FUND volume reduced due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsTrendReducedVolumeList.add(shareIndex + run*numAssets, simulator.getTrendReducedVolume(secId));    // time series list of TREND volume reduced due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsLSReducedVolumeList.add(shareIndex + run*numAssets, simulator.getLSReducedVolume(secId));          // time series list of LS volume reduced due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsFundReducedOrdersList.add(shareIndex + run*numAssets, simulator.getFundTotalReducedOrders(secId));      // time series list of FUND reduction orders due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsTrendReducedOrdersList.add(shareIndex + run*numAssets, simulator.getTrendTotalReducedOrders(secId));    // time series list of TREND reduction orders due to VaR [(nRuns * nAssets) x nTicks]
//	            	tsLSReducedOrdersList.add(shareIndex + run*numAssets, simulator.getLSTotalReducedOrders(secId));          // time series list of LS reduction orders due to VaR [(nRuns * nAssets) x nTicks]
	            	tsFundSelloffOrdersList.add(shareIndex + run*numAssets, simulator.getFundTotalSelloffOrders(secId));      // time series list of FUND sell-off orders due to VaR [(nRuns * nAssets) x nTicks]
	            	tsTrendSelloffOrdersList.add(shareIndex + run*numAssets, simulator.getTrendTotalSelloffOrders(secId));    // time series list of TREND sell-off orders due to VaR [(nRuns * nAssets) x nTicks]
	            	tsLSSelloffOrdersList.add(shareIndex + run*numAssets, simulator.getLSTotalSelloffOrders(secId));          // time series list of LS sell-off orders due to VaR [(nRuns * nAssets) x nTicks]
	            	tsFundSelloffVolumeList.add(shareIndex + run*numAssets, simulator.getFundSelloffVolume(secId));           // time series list of FUND sell-off volume due to VaR [(nRuns * nAssets) x nTicks]
	            	tsTrendSelloffVolumeList.add(shareIndex + run*numAssets, simulator.getTrendSelloffVolume(secId));         // time series list of TREND sell-off volume due to VaR [(nRuns * nAssets) x nTicks]
	            	tsLSSelloffVolumeList.add(shareIndex + run*numAssets, simulator.getLSSelloffVolume(secId));               // time series list of LS sell-off volume due to VaR [(nRuns * nAssets) x nTicks]
	            }
	            	            
	            tsFundAvgVarList.add(run, simulator.getFundAvgVaR());      // time series list of FUND avg VaR [nRuns x nTicks] (post trade)
	            tsTrendAvgVarList.add(run, simulator.getTrendAvgVaR());    // time series list of TREND avg VaR [nRuns x nTicks] (post trade)
	            tsLSAvgVarList.add(run, simulator.getLSAvgVaR());          // time series list of LS avg VaR [nRuns x nTicks] (post trade)

	            tsFundAvgStressedVarList.add(run, simulator.getFundAvgStressedVaR());      // time series list of FUND avg stressed VaR [nRuns x nTicks] (post trade)
	            tsTrendAvgStressedVarList.add(run, simulator.getTrendAvgStressedVaR());    // time series list of TREND avg stressed VaR [nRuns x nTicks] (post trade)
	            tsLSAvgStressedVarList.add(run, simulator.getLSAvgStressedVaR());          // time series list of LS avg stressed VaR [nRuns x nTicks] (post trade)

//	            tsFundAvgVarLimitList.add(run, simulator.getFundAvgVarLimit());         // time series list of FUND avg VaR limit [nRuns x nTicks]
//	            tsTrendAvgVarLimitList.add(run, simulator.getTrendAvgVarLimit());       // time series list of TREND avg VaR limit [nRuns x nTicks]
//	            tsLSAvgVarLimitList.add(run, simulator.getLSAvgVarLimit());             // time series list of LS avg VaR limit [nRuns x nTicks]
	            
//	            tsFundFailureList.add(run, simulator.getFundFailures());       // time series list of FUND failures [nRuns x nTicks]
//	            tsTrendFailureList.add(run, simulator.getTrendFailures());     // time series list of TREND failures [nRuns x nTicks]
//	            tsLSFailureList.add(run, simulator.getLSFailures());           // time series list of LS failures [nRuns x nTicks]
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
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundreducedvolume_timeseries_E" + e + ".csv").write(tsFundReducedVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendreducedvolume_timeseries_E" + e + ".csv").write(tsTrendReducedVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsreducedvolume_timeseries_E" + e + ".csv").write(tsLSReducedVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundreducedorders_timeseries_E" + e + ".csv").write(tsFundReducedOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendreducedorders_timeseries_E" + e + ".csv").write(tsTrendReducedOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsreducedorders_timeseries_E" + e + ".csv").write(tsLSReducedOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundsellofforders_timeseries_E" + e + ".csv").write(tsFundSelloffOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendsellofforders_timeseries_E" + e + ".csv").write(tsTrendSelloffOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lssellofforders_timeseries_E" + e + ".csv").write(tsLSSelloffOrdersList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundselloffvolume_timeseries_E" + e + ".csv").write(tsFundSelloffVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendselloffvolume_timeseries_E" + e + ".csv").write(tsTrendSelloffVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsselloffvolume_timeseries_E" + e + ".csv").write(tsLSSelloffVolumeList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundvar_timeseries_E" + e + ".csv").write(tsFundAvgVarList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendvar_timeseries_E" + e + ".csv").write(tsTrendAvgVarList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsvar_timeseries_E" + e + ".csv").write(tsLSAvgVarList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundstressedvar_timeseries_E" + e + ".csv").write(tsFundAvgStressedVarList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendstressedvar_timeseries_E" + e + ".csv").write(tsTrendAvgStressedVarList);
	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsstressedvar_timeseries_E" + e + ".csv").write(tsLSAvgStressedVarList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundvarlimit_timeseries_E" + e + ".csv").write(tsFundAvgVarLimitList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendvarlimit_timeseries_E" + e + ".csv").write(tsTrendAvgVarLimitList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsvarlimit_timeseries_E" + e + ".csv").write(tsLSAvgVarLimitList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_fundfailures_timeseries_E" + e + ".csv").write(tsFundFailureList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_trendfailures_timeseries_E" + e + ".csv").write(tsTrendFailureList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-ls-var-abm-simulation/list_lsfailures_timeseries_E" + e + ".csv").write(tsLSFailureList);
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
//        	charts.draw(atcWealthLS_GOOG);
//        	charts.draw(atcPosLS_GOOG);
//        	charts.draw(atcPosReducedLS_GOOG);
//        	charts.draw(atcSelloffOrdersLS_GOOG);
//        	charts.draw(atcWealthLS_MSFT);
//        	charts.draw(atcPosLS_MSFT);
        	charts.draw(atcWealthLS_IBM);
        	charts.draw(atcPosLS_IBM);
//        	charts.draw(atcPosReducedLS_IBM);
//        	charts.draw(atcOrdersLS_IBM);
        	charts.draw(atcSelloffOrdersLS_IBM);
        	charts.draw(atcSpreads);
//        	charts.draw(atcPreTradeVarLS);
        	charts.draw(atcPostTradeVarLS);
        }
        
        if (numTrends > 0) {
//        	charts.draw(atcWealthTrend_GOOG);
//            charts.draw(atcPosTrend_GOOG);
//            charts.draw(atcPosReducedTrend_GOOG);
//            charts.draw(atcSelloffOrdersTrend_GOOG);
//            charts.draw(atcWealthTrend_MSFT);
//            charts.draw(atcPosTrend_MSFT);
            charts.draw(atcWealthTrend_IBM);
            charts.draw(atcPosTrend_IBM);
//            charts.draw(atcPosReducedTrend_IBM);
//        	charts.draw(atcOrdersTrend_IBM);
        	charts.draw(atcSelloffOrdersTrend_IBM);
//        	charts.draw(atcPreTradeVarTrend);
            charts.draw(atcPostTradeVarTrend);
            charts.draw(atcVarLimitTrend);
        }
        
        if (numFunds > 0) {
//        	charts.draw(atcWealthFund_GOOG);
//            charts.draw(atcPosFund_GOOG);
//            charts.draw(atcPosReducedFund_GOOG);
//            charts.draw(atcSelloffOrdersFund_GOOG);
//            charts.draw(atcWealthFund_MSFT);
//            charts.draw(atcPosFund_MSFT);
            charts.draw(atcWealthFund_IBM);
            charts.draw(atcPosFund_IBM);
//            charts.draw(atcPosReducedFund_IBM);
//        	charts.draw(atcOrdersFund_IBM);
        	charts.draw(atcSelloffOrdersFund_IBM);
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
       
        
        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
    }

}
