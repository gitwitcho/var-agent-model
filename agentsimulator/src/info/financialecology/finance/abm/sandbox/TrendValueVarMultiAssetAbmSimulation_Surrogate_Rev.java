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
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
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

import au.com.bytecode.opencsv.CSVReader;

/**
 * An agent-based simulation with trend followers and value investors (deleted LS investors).
 * This program allows to create a set of simulation outputs to subsequently train a ML-based metamodel (this is done in Python).
 * This version has been created for the revision of the article submitted to 'Expert Systems', to distinguish it from the java 
 * simulation file used in the first submission.
 * 
 * @author Gilbert Peffer, Bàrbara Llacay
 */
public class TrendValueVarMultiAssetAbmSimulation_Surrogate_Rev {

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
         *      - Assign parameter values
         *      Those parameters that are not sampled with LHS (and so keep constant along runs) are read from
         *      the param file.
         *      The value of those parameters that are sampled with LHS is read from a CSV file (where values are 
         *      normalised in the [0,1] range) and afterwards it is adjusted to its true range.
         *
         ********************************************************** */
        logger.trace("Reading parameters from file");
        
        TrendValueLSVarAbmParams params = TrendValueLSVarAbmParams.readParameters(CmdLineProcessor.process(args));
        
        // ------------------
        
        /*
         *      READ SAMPLING VALUES FOR CHANGING PARAMETERS
         *      
         *      Sampling LHS values are read from CSV file and stored in an array for later use.
         */

        int nParamsLHS = 10;   // Number of parameters which have been sampled in LHS (= # columns in CSV file)
        int nSamples = 1000;    // Number of samples generated with LHS (= # rows in CSV file)
        String inputFile = "LHS_parameters_" + nParamsLHS + "_" + nSamples + "_center_seed100.csv";
        String CSVFilePath = "./in/params/TrendValueVarAbmSurrogateRev/" + inputFile;  // CSV file containing the parameters values
           
        double[][] paramsLhsNorm = new double[nSamples][nParamsLHS];
           
        try {
           // Construct a reader object from the input file
           CSVReader reader = new CSVReader(new FileReader(CSVFilePath));
           String [] nextLine;
           int lineNumber = 0;
           while ((nextLine = reader.readNext()) != null) {   // nextLine[] is an array of values from the line
              if (lineNumber > 0) {   // Skip the first row as it contains column names
                 // Transform strings to floats and store them in a float array
                 double[] thisRowDoubles = new double[nParamsLHS];
                 for (int c = 1; c < nParamsLHS+1; c++) {   // Skip the first column as it contains the row indices
                    thisRowDoubles[c-1] = Double.parseDouble(nextLine[c]);
                 }              
           	     paramsLhsNorm[lineNumber-1] = thisRowDoubles;
              }
              lineNumber ++;
            }
        }
        catch( IOException ioException ) {
           System.out.println("Exception: " + ioException);
        }
           
        System.out.print("file 0 = " + paramsLhsNorm[0][0] + paramsLhsNorm[0][1] + paramsLhsNorm[0][2] + "\n");
        System.out.print("file 1 = " + paramsLhsNorm[1][0] + paramsLhsNorm[1][1] + paramsLhsNorm[1][2] + "\n");

        // ------------------
                       
       
        /*
         *      PARAMETERS
         */

        int numTicks        = params.nTicks;    // number of ticks per simulation run
        int numRuns;                            // number of runs per simulation experiment
        int startSeed       = params.seed;      // starting position in the random seed table; -1 for random value (based on internal clock) 
        
        int numTrends;                 // number of TREND investors
        int numFunds;                  // number of FUND investors
       
        DoubleArrayList price_0      = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.PRICE_0);
        DoubleArrayList liquidity    = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.LIQUIDITY);
        
        double probShortSellingTrend = params.probShortSellingTrend;   // percentage of TRENDs which are allowed to short-sell (between 0 and 1)
        double probShortSellingValue = params.probShortSellingValue;   // percentage of FUNDs which are allowed to short-sell (between 0 and 1)

    	double capFactTrend = params.capFactorTrend;
    	
    	double varLimitTrendMin = params.varLimitTrendMin;
    	double varLimitTrendMax = params.varLimitTrendMax;
    	double varLimitFundMin = params.varLimitFundMin;
    	double varLimitFundMax = params.varLimitFundMax;
    	
    	int volWindowVarFundMin    = params.volWindowVarFundMin;
    	int volWindowVarFundMax    = params.volWindowVarFundMax;
    	int volWindowVarTrendMin   = params.volWindowVarTrendMin;
    	int volWindowVarTrendMax   = params.volWindowVarTrendMax;
    	
    	double probVarValue    = params.probVarFund;
    	double probVarTrend    = params.probVarTrend;
    	
        VariabilityVarLimit variabilityVarLimit = VariabilityVarLimit.CONSTANT;
//    	VariabilityVarLimit variabilityVarLimit = VariabilityVarLimit.COUNTERCYCLICAL;
    	
        UseStressedVar useStressedVar = UseStressedVar.FALSE;  // !! Ensure that VaR is used before setting stressedVar to 'TRUE'

        
        // Parameters for the exogenous price process. The process is an overlay of a Brownian process and a sinus function
        
        DoubleArrayList amplitude_price  = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.AMPLITUDE_PRICE);
        DoubleArrayList lag_price        = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.LAG_PRICE);
        DoubleArrayList lambda_price     = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.LAMBDA_PRICE);
        
        DoubleArrayList mu_price         = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.MU_PRICE);
        DoubleArrayList sigma_price      = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.SIGMA_PRICE);   
                
        // Parameters for the exogenous market-wide fundamental value process. The process is an overlay of a Brownian process and a sinus function
        
        DoubleArrayList amplitude_value  = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.AMPLITUDE_VALUE);
        DoubleArrayList lag_value        = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.LAG_VALUE);
        DoubleArrayList lambda_value     = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.LAMBDA_VALUE);        
        
        DoubleArrayList mu_value         = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.MU_VALUE);
        DoubleArrayList sigma_value      = params.getValidatedDoubleSequence(TrendValueLSVarAbmParams.Sequence.SIGMA_VALUE); 
        
 
        int numExp = 1;
        numRuns = nSamples;

               
        /*
         *      RANGE OF VARIATION OF CHANGING PARAMETERS
         *      
         *      LHS sampling values (read from CSV file) move between 0 and 1. The range of variation of parameters
         *      will allow to 'translate' the sampled value of each parameter to its true range.
         */

        int numTrends_Min = 100;
        int numTrends_Max = 300;
        int numFunds_Min = 100;
        int numFunds_Max = 300;
        double liquidity_Min = 300;
        double liquidity_Max = 500;
//        double sigma_price_Min = 0;
//        double sigma_price_Max = 0.8;
        double sigma_value_Min = 0;
        double sigma_value_Max = 0.8;
        double maShortTicksMin_Min = 2;
        double maShortTicksMin_Max = 10;
        double maLongTicksMin_Min = 20;
        double maLongTicksMin_Max = 60;
        double bcTicksTrendMin_Min = 1;
        double bcTicksTrendMin_Max = 15;
        double entryThresholdMin_Min = 2;
        double entryThresholdMin_Max = 7;
        double exitThresholdMin_Min = -1.5;
        double exitThresholdMin_Max = 0.5;        
        double valueOffset_Min = 1;
        double valueOffset_Max = 20;
        int startSeed_Min = 1;
        int startSeed_Max = 100000;

        // ---------------------------------------------------------------------------------------------------------------
        
        
        // Set number of assets and validate the remaining parameter array lengths 
        int numAssets = price_0.size();
        
        boolean control = ((liquidity.size() == numAssets) && 
                (amplitude_price.size() == numAssets) && (amplitude_value.size() == numAssets) &&
                (lag_price.size() == numAssets) && (lag_value.size() == numAssets) &&
                (lambda_price.size() == numAssets) && (lambda_value.size() == numAssets) &&
                (mu_price.size() == numAssets) && (mu_value.size() == numAssets) &&
                (sigma_price.size() == numAssets) && (sigma_value.size() == numAssets));
        
        Assertion.assertOrKill(control == true, "Wrong number of parameters for " + numAssets + " assets");

        
        TrendValueLSVarAbmSimulator simulator;

    
           
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
        	startSeed = params.seed + e;   // TREURE!
        	        	
        	System.out.print("EXPERIMENT:" + e + "\n");
        	
       	
        	/*
             * Variables for extracting data to R for each experiment - TODO: Delete when VersatileTimeSeriesCollection works well in CsvResultWriter
             */
            
            DoubleTimeSeriesList tsPricesList                   = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsFundValuesList               = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsTotalVolumeList              = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsFundVolumeList               = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsTrendVolumeList              = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsFundTotalOrdersList          = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsTrendTotalOrdersList         = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsTrendAvgWealthIncrementList  = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsFundAvgWealthIncrementList   = new DoubleTimeSeriesList();
// 
//            DoubleTimeSeriesList tsFundAvgVarList               = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsTrendAvgVarList              = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsFundAvgStressedVarList       = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsTrendAvgStressedVarList      = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsFundAvgVarLimitList          = new DoubleTimeSeriesList();
//            DoubleTimeSeriesList tsTrendAvgVarLimitList         = new DoubleTimeSeriesList();
           
        
	        for (int run = 0; run < numRuns; run++) {
	        	
	        	System.out.print("RUN:" + run + "\n");

	            /*
	             * Setting the changing parameter values
	             */
	        	
	        	numTrends = (int) (numTrends_Min + paramsLhsNorm[run][0]* (numTrends_Max - numTrends_Min));
	        	numFunds = (int) (numFunds_Min + paramsLhsNorm[run][1]* (numFunds_Max - numFunds_Min));
	        	liquidity.set(0, liquidity_Min + paramsLhsNorm[run][2]* (liquidity_Max - liquidity_Min));
//	        	sigma_price.set(0, sigma_price_Min + paramsLhsNorm[run][3]* (sigma_price_Max - sigma_price_Min));  //-> Following indices need to be adjusted
	            sigma_value.set(0, sigma_value_Min + paramsLhsNorm[run][3]* (sigma_value_Max - sigma_value_Min));

	            // TREND parameters
	            int maShortTicksMin = (int) (maShortTicksMin_Min + paramsLhsNorm[run][4]* (maShortTicksMin_Max - maShortTicksMin_Min));
	            int maShortTicksMax = maShortTicksMin + 10;
	            int maLongTicksMin = (int) (maLongTicksMin_Min + paramsLhsNorm[run][5]* (maLongTicksMin_Max - maLongTicksMin_Min));
	            int maLongTicksMax = maLongTicksMin + 15;
	            int bcTicksTrendMin = (int) (bcTicksTrendMin_Min + paramsLhsNorm[run][6]* (bcTicksTrendMin_Max - bcTicksTrendMin_Min));
	            int bcTicksTrendMax = bcTicksTrendMin + 25;
	            
	            // FUND parameters
	            double entryThresholdMin = entryThresholdMin_Min + paramsLhsNorm[run][7]* (entryThresholdMin_Max - entryThresholdMin_Min);
	            double entryThresholdMax = entryThresholdMin + 3;
	            double exitThresholdMin = exitThresholdMin_Min + paramsLhsNorm[run][8]* (exitThresholdMin_Max - exitThresholdMin_Min);
	            double exitThresholdMax = exitThresholdMin + 1.5;
	            double valueOff = valueOffset_Min + paramsLhsNorm[run][9]* (valueOffset_Max - valueOffset_Min);  

	            //startSeed = (int) (startSeed_Min + paramsLhsNorm[run][10]* (startSeed_Max - startSeed_Min));

/*	            System.out.print("line i = " + paramsLhsNorm[run][0] + paramsLhsNorm[run][1] + paramsLhsNorm[run][2] + paramsLhsNorm[run][3] + paramsLhsNorm[run][4] + paramsLhsNorm[run][5] + paramsLhsNorm[run][6] + paramsLhsNorm[run][7] + paramsLhsNorm[run][8] + paramsLhsNorm[run][9] + "\n");
	            
	            System.out.print("numTrends = " + numTrends + "\n");
	        	System.out.print("numFunds = " + numFunds + "\n");
	        	System.out.print("liq = " + liquidity + "\n");
	        	System.out.print("sigma_price = " + sigma_price + "\n");
	        	System.out.print("sigma_value = " + sigma_value + "\n");
	        	System.out.print("maShortTicks Trend = [" + maShortTicksMin + ", " + maShortTicksMax + "]" + "\n");
	        	System.out.print("maLongTicks Trend = [" + maLongTicksMin + ", " + maLongTicksMax + "]" + "\n");
	        	System.out.print("bcTicks Trend = [" + bcTicksTrendMin + ", " + bcTicksTrendMax + "]" + "\n");
	        	System.out.print("entryThreshold Fund = [" + entryThresholdMin + ", " + entryThresholdMax + "]" + "\n");
	        	System.out.print("exitThreshold Fund = [" + exitThresholdMin + ", " + exitThresholdMax + "]" + "\n");
	        	System.out.print("valueOffset = " + valueOff + "\n");
*/   	
	            System.out.print("startSeed = " + startSeed + "\n");
	            System.out.print("sigma_price = " + sigma_price + "\n");
	            	        	
	            /*
	             * Setting up the simulator
	             */
	        	
	        	simulator = new TrendValueLSVarAbmSimulator();      // recreating the simulator will also get rid of the old schedule
	        	
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
                
                
	            /*
	             * Setting up the data generators
	             */
	            
	            if (startSeed < 0)
	                RandomGeneratorPool.configureGeneratorPool();
	            else
	                //RandomGeneratorPool.configureGeneratorPool(startSeed + run);  // Use consecutive seeds for each run
	            	RandomGeneratorPool.configureGeneratorPool(startSeed);
	
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
	                //RandomDistDataGenerator distMaShortTicks = new RandomDistDataGenerator("MA_Short_" + secId, DistributionType.UNIFORM, (double) params.maShortTicksMin, (double) params.maShortTicksMax);	                
	            	RandomDistDataGenerator distMaShortTicks = new RandomDistDataGenerator("MA_Short_" + secId, DistributionType.UNIFORM, (double) maShortTicksMin, (double) maShortTicksMax);
	                //RandomDistDataGenerator distMaLongTicks  = new RandomDistDataGenerator("MA_Long_" + secId, DistributionType.UNIFORM, (double) params.maLongTicksMin, (double) params.maLongTicksMax);
	            	RandomDistDataGenerator distMaLongTicks  = new RandomDistDataGenerator("MA_Long_" + secId, DistributionType.UNIFORM, (double) maLongTicksMin, (double) maLongTicksMax);
	                //RandomDistDataGenerator distBcTicksTrend = new RandomDistDataGenerator("BC_Ticks_Trend_" + secId, DistributionType.UNIFORM, (double) params.bcTicksTrendMin, (double) params.bcTicksTrendMax);
	            	RandomDistDataGenerator distBcTicksTrend = new RandomDistDataGenerator("BC_Ticks_Trend_" + secId, DistributionType.UNIFORM, (double) bcTicksTrendMin, (double) bcTicksTrendMax);

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
//	            	if (distUnif01VarTrend.nextDouble() < e*0.1)    //Use when the probability of using stressed VaR changes along experiments
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
                    //RandomDistDataGenerator distEntryThreshold = new RandomDistDataGenerator("Entry_" + secId, DistributionType.UNIFORM, params.entryThresholdMin, params.entryThresholdMax);
                	RandomDistDataGenerator distEntryThreshold = new RandomDistDataGenerator("Entry_" + secId, DistributionType.UNIFORM, entryThresholdMin, entryThresholdMax);
                    //RandomDistDataGenerator distExitThreshold = new RandomDistDataGenerator("Exit_" + secId, DistributionType.UNIFORM, params.exitThresholdMin, params.exitThresholdMax);
                	RandomDistDataGenerator distExitThreshold = new RandomDistDataGenerator("Exit_" + secId, DistributionType.UNIFORM, exitThresholdMin, exitThresholdMax);
                    //RandomDistDataGenerator distValueOffset = new RandomDistDataGenerator("Offset_" + secId, DistributionType.UNIFORM, -params.valueOffset, params.valueOffset);
                    RandomDistDataGenerator distValueOffset = new RandomDistDataGenerator("Offset_" + secId, DistributionType.UNIFORM, -valueOff, valueOff);
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
//	            	if (distUnif01VarValue.nextDouble() < e*0.1)    //Use when the probability of using stressed VaR changes along experiments
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
	             *      Run the simulation
	             *  
	             ****************************************/
	            simulator.setNumTicks(numTicks);
	            simulator.run();
	            
	            
                   
	            for (String secId : shareIds) {
//	            
//    	            /**
//    	             * Print the volatility of log-returns for calibration purposes 
//    	             */
	            	
//    	            logger.debug("PRICE_" + secId + ": {}", simulator.getPrices(secId));
    	            //logger.debug("CORRELATION OF PRICES: {}", StatsTimeSeries.correlation(simulator.getPrices("IBM"), simulator.getPrices(secId)));
    	            logger.debug("VOLATILITY of LOG-RETURNS: {}", simulator.getLogReturns(secId).stdev());
    	            logger.debug("KURTOSIS of LOG-RETURNS: {}", simulator.getLogReturns(secId).excessKurtosis());    	            
    	            //logger.debug("SKEWNESS of LOG-RETURNS: {}", simulator.getLogReturns(secId).skewness());
    	            //logger.debug("MEAN VOLUME - F: {}, T: {}", simulator.getFundVolume(secId).mean(), simulator.getTrendVolume(secId).mean());
    	            logger.debug("AVG WEALTH INCREMENT - F: {}, T: {}", simulator.getFundAvgWealthIncrement(secId).get(numTicks-1), simulator.getTrendAvgWealthIncrement(secId).get(numTicks-1));
    	            logger.debug("\n");
	            }
		        
            
	            
	            /*
	             * Create time series lists for extraction to R
	             */
	            
	            for (String secId : shareIds) {
	            	int shareIndex = shareIds.indexOf(secId);

	            	tsPricesList.add(shareIndex + run*numAssets, simulator.getPrices(secId));              // time series list of prices [(nRuns * nAssets) x nTicks]
//	            	tsFundValuesList.add(shareIndex + run*numAssets, simulator.getFundValues(secId));      // time series list of general fund value [(nRuns * nAssets) x nTicks]
//	            	tsTotalVolumeList.add(shareIndex + run*numAssets, simulator.getTotalVolume(secId));    // time series list of total volume [(nRuns * nAssets) x nTicks]
//	            	tsFundVolumeList.add(shareIndex + run*numAssets, simulator.getFundVolume(secId));      // time series list of FUND volume [(nRuns * nAssets) x nTicks]
//	            	tsTrendVolumeList.add(shareIndex + run*numAssets, simulator.getTrendVolume(secId));    // time series list of TREND volume [(nRuns * nAssets) x nTicks]
//	            	tsFundTotalOrdersList.add(shareIndex + run*numAssets, simulator.getFundTotalOrders(secId));      // time series list of FUND aggregated orders [(nRuns * nAssets) x nTicks]
//	            	tsTrendTotalOrdersList.add(shareIndex + run*numAssets, simulator.getTrendTotalOrders(secId));    // time series list of TREND aggregated orders [(nRuns * nAssets) x nTicks]
//	            	tsFundAvgWealthIncrementList.add(shareIndex + run*numAssets, simulator.getFundAvgWealthIncrement(secId));      // time series list of FUND wealth increment [(nRuns * nAssets) x nTicks]
//	            	tsTrendAvgWealthIncrementList.add(shareIndex + run*numAssets, simulator.getTrendAvgWealthIncrement(secId));    // time series list of TREND wealth increment [(nRuns * nAssets) x nTicks]
	            }
	            	            
//	            tsFundAvgVarList.add(run, simulator.getFundAvgVaR());      // time series list of FUND avg VaR [nRuns x nTicks] (post trade)
//	            tsTrendAvgVarList.add(run, simulator.getTrendAvgVaR());    // time series list of TREND avg VaR [nRuns x nTicks] (post trade)
//
//	            tsFundAvgStressedVarList.add(run, simulator.getFundAvgStressedVaR());      // time series list of FUND avg stressed VaR [nRuns x nTicks] (post trade)
//	            tsTrendAvgStressedVarList.add(run, simulator.getTrendAvgStressedVaR());    // time series list of TREND avg stressed VaR [nRuns x nTicks] (post trade)

	        }

	        
	        /**
	         *      Write results of current experiment to file for further analysis with R
	         */
	        
	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/kk/java_price_timeseries_" + nParamsLHS + "_" + nSamples + "_sigmaP" + sigma_price.get(0) + "_seed" + startSeed + ".csv").write(tsPricesList);
	        //ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_price_timeseries_E" + e + ".csv").write(tsPricesList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_fundvalues_timeseries_E" + e + ".csv").write(tsFundValuesList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_totalvolume_timeseries_E" + e + ".csv").write(tsTotalVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_fundvolume_timeseries_E" + e + ".csv").write(tsFundVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_trendvolume_timeseries_E" + e + ".csv").write(tsTrendVolumeList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_fundorders_timeseries_E" + e + ".csv").write(tsFundTotalOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_trendorders_timeseries_E" + e + ".csv").write(tsTrendTotalOrdersList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_fundwealth_timeseries_E" + e + ".csv").write(tsFundAvgWealthIncrementList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_trendwealth_timeseries_E" + e + ".csv").write(tsTrendAvgWealthIncrementList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_fundvar_timeseries_E" + e + ".csv").write(tsFundAvgVarList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_trendvar_timeseries_E" + e + ".csv").write(tsTrendAvgVarList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_fundstressedvar_timeseries_E" + e + ".csv").write(tsFundAvgStressedVarList);
//	        ResultWriterFactory.getCSVWriter("./out/trend-value-var-abm-surrogate-rev/list_trendstressedvar_timeseries_E" + e + ".csv").write(tsTrendAvgStressedVarList);
        }        
      
        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");        
    }
}
