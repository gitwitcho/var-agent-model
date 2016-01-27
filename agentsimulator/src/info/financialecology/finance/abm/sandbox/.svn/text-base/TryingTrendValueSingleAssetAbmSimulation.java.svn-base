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
import java.util.HashMap;

import info.financialecology.finance.abm.model.TrendValueAbmSimulator;
import info.financialecology.finance.abm.model.agent.Trader;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.MultiplierTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.OrderOrPositionStrategyTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.PositionUpdateTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.VariabilityCapFactorTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.ShortSellingTrend;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.OrderOrPositionStrategyValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.PositionUpdateValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.VariabilityCapFactorValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.ShortSellingValue;
import info.financialecology.finance.abm.sandbox.TrendValueAbmParams;
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
public class TryingTrendValueSingleAssetAbmSimulation {

    protected static final String TEST_ID = "TryingTrendValueSingleAssetAbmSimulation"; 
    
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
        root.setLevel(ch.qos.logback.classic.Level.DEBUG);
        Logger logger = (Logger)LoggerFactory.getLogger("main");
        
        System.out.println("\nTEST: " + TEST_ID);
        System.out.println("==============================================\n");

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
        int numRuns         = params.nRuns;     // number of runs per simulation experiment
        int startSeed       = params.seed;    // starting position in the random seed table; -1 for random value (based on internal clock) 
        
        int numTrends       = params.numTrends;    // number of TREND investors
        int numFunds        = params.numFunds;      // number of FUND investors
        
        double price_0      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.PRICE_0).get(0);
        double liquidity    = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LIQUIDITY).get(0);

        //  Parameters for the exogenous price process. The process is an overlay of a Brownian process and a sinus function
        
        double shift_price      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SHIFT_PRICE).get(0);
        double amplitude_price  = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.AMPLITUDE_PRICE).get(0);
        double lag_price        = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAG_PRICE).get(0);
        double lambda_price     = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAMBDA_PRICE).get(0);
        
        double mu_price         = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.MU_PRICE).get(0);
        double sigma_price      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SIGMA_PRICE).get(0);
                
        // Parameters for the exogenous market-wide fundamental value process. The process is an overlay of a Brownian process and a sinus function
        
        double shift_value      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SHIFT_VALUE).get(0);
        double amplitude_value  = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.AMPLITUDE_VALUE).get(0);
        double lag_value        = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAG_VALUE).get(0);
        double lambda_value     = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.LAMBDA_VALUE).get(0);        
        
        double mu_value         = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.MU_VALUE).get(0);
        double sigma_value      = params.getValidatedDoubleSequence(TrendValueAbmParams.Sequence.SIGMA_VALUE).get(0);

        // ---------------------------------------------------------------------------------------------------------------
        
        double sigmaMin = sigma_price;    // TODO Only for experiments
        double sigmaMax = sigma_price;
        
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
        
        VersatileTimeSeriesCollection atcWealthTrend    = new VersatileTimeSeriesCollection("TREND Wealth for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcPosTrend       = new VersatileTimeSeriesCollection("TREND Positions for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcWealthFund     = new VersatileTimeSeriesCollection("FUND Wealth for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcPosFund        = new VersatileTimeSeriesCollection("FUND Positions for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcPrice          = new VersatileTimeSeriesCollection("Prices for sigma [" + sigmaMin + "," + sigmaMax + "]");
        VersatileTimeSeriesCollection atcValue          = new VersatileTimeSeriesCollection("Fundamental Values");
        VersatileTimeSeriesCollection atcVolumeFund     = new VersatileTimeSeriesCollection("FUND Volume");
        VersatileTimeSeriesCollection atcVolumeTrend    = new VersatileTimeSeriesCollection("TREND Volume");
        VersatileTimeSeriesCollection atcValuePriceDiff = new VersatileTimeSeriesCollection("Value-Price Difference"); 
        VersatileTimeSeriesCollection atcValuePriceDiff_F1 = new VersatileTimeSeriesCollection("Value-Price Difference of FUND_1");
        VersatileTimeSeriesCollection vtscPriceAndMA    = new VersatileTimeSeriesCollection("Price and MAs");
        VersatileTimeSeriesCollection vtscACF           = new VersatileTimeSeriesCollection("Autocorrelation Functions");

                
        // Variables for extracting data to R - TODO: Delete when VersatileTimeSeriesCollection works well in CsvResultWriter
        
        DoubleTimeSeriesList tsPricesList       = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsFundValuesList   = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsTotalVolumeList  = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsFundVolumeList   = new DoubleTimeSeriesList();
        DoubleTimeSeriesList tsTrendVolumeList  = new DoubleTimeSeriesList();
        
       // Variables for VVUQ tests
        
//      double meanPrice = 0;
//      double stdDevPrice = 0;

        
        /** ************************************************************
         * 
         *      SIMULATION EXPERIMENT      
         *           
         *************************************************************** */
        
        for (int run = 0; run < numRuns; run++) {
        	
        	System.out.print("RUN:" + run + "\n");
                        
            /*
             * Setting up the simulator
             */
        	simulator = new TrendValueAbmSimulator();      // recreating the simulator will also get rid of the old schedule
            simulator.addShares("IBM");
            simulator.getMarketMaker().setInitPrice("IBM", price_0);
            simulator.getMarket().setInitLogReturn("IBM", 0);
            simulator.getMarket().setInitValue("IBM", price_0);
            simulator.getMarket().setLiquidity("IBM", liquidity);
            simulator.createTrendFollowers(numTrends);
            simulator.createValueInvestors(numFunds);
            
            /*
             * Setting the changing parameter values
             */
            
            if (numRuns == 1)
                sigma_price = sigmaMin;
            else
                sigma_price = sigmaMin + run * (sigmaMax - sigmaMin) / (numRuns - 1);
    
            /*
             * Setting up the data generators
             */
            
            if (startSeed < 0)
                RandomGeneratorPool.configureGeneratorPool();
            else
                RandomGeneratorPool.configureGeneratorPool(startSeed);

            OverlayDataGenerator exoPrices = new OverlayDataGenerator(
                    "Price", GeneratorType.SINUS, GeneratorType.GEOMETRIC_BROWNIAN_PROCESS, 
                    price_0, amplitude_price, lag_price, lambda_price, mu_price, sigma_price);

            OverlayDataGenerator fundValues = new OverlayDataGenerator(
                    "FundValue", GeneratorType.SINUS, GeneratorType.GEOMETRIC_BROWNIAN_PROCESS, 
                    price_0, amplitude_value, lag_value, lambda_value, mu_value, sigma_value);

            simulator.setExogeneousPriceProcess("IBM", exoPrices);
            simulator.setFundamentalValueProcess("IBM", fundValues);

            
            /* ***************************************
             *
             * Set up the trend strategies. 
             * The moving average ranges and exit channel are randomised.
             * 
             *****************************************/
            
            HashMap<String, Trader> trendFollowers = simulator.getTrendFollowers();
            
            // Randomising
            RandomDistDataGenerator distMaShortTicks    = new RandomDistDataGenerator("MA_Short", DistributionType.UNIFORM, (double) params.maShortTicksMin, (double) params.maShortTicksMax);
            RandomDistDataGenerator distMaLongTicks     = new RandomDistDataGenerator("MA_Long", DistributionType.UNIFORM, (double) params.maLongTicksMin, (double) params.maLongTicksMax);
            RandomDistDataGenerator distBcTicksTrend    = new RandomDistDataGenerator("BC_Ticks_Trend", DistributionType.UNIFORM, (double) params.bcTicksTrendMin, (double) params.bcTicksTrendMax);
            
//            Multiplier trendMultiplier = Multiplier.MA_SLOPE_DIFFERENCE_STDDEV;   // Method to calculate the size of the trend positions
            MultiplierTrend trendMultiplier = MultiplierTrend.CONSTANT;   // Method to calculate the size of the trend positions

            PositionUpdateTrend positionUpdateTrend = PositionUpdateTrend.VARIABLE;         // Specifies if a position can be modified while open
            OrderOrPositionStrategyTrend orderOrPositionStrategyTrend = OrderOrPositionStrategyTrend.POSITION;   // Specifies if the strategy is order-based or position-based
            VariabilityCapFactorTrend variabilityCapFactorTrend = VariabilityCapFactorTrend.CONSTANT;    // Specifies if the capFactor is constant or varies based on the agent performance
            ShortSellingTrend shortSellingTrend = ShortSellingTrend.ALLOWED;    // Specifies if short-selling is allowed
                        
            for (int i = 0; i < trendFollowers.size(); i++) {
            	simulator.addTrendStrategyForOneTrendFollower("IBM", "Trend_" + i, (int) Math.round(distMaShortTicks.nextDouble()), 
            			(int) Math.round(distMaLongTicks.nextDouble()), (int) Math.round(distBcTicksTrend.nextDouble()), params.capFactorTrend, 
            			params.volWindowTrend, trendMultiplier, positionUpdateTrend, orderOrPositionStrategyTrend, variabilityCapFactorTrend, shortSellingTrend);
            }
    
            
            /* ***************************************
             * 
             *      Set up the value strategies
             * 
             *****************************************/
                        
            HashMap<String, Trader> valueInvestors = simulator.getValueInvestors();
            
            RandomDistDataGenerator distEntryThreshold = new RandomDistDataGenerator("Entry", DistributionType.UNIFORM, params.entryThresholdMin, params.entryThresholdMax);
            RandomDistDataGenerator distExitThreshold = new RandomDistDataGenerator("Exit", DistributionType.UNIFORM, params.exitThresholdMin, params.exitThresholdMax);
            RandomDistDataGenerator distValueOffset = new RandomDistDataGenerator("Offset", DistributionType.UNIFORM, -params.valueOffset, params.valueOffset);
            RandomDistDataGenerator distBcTicksFund = new RandomDistDataGenerator("BC_Ticks_Fund", DistributionType.UNIFORM, (double) params.bcTicksFundMin, (double) params.bcTicksFundMax);
            
            PositionUpdateValue positionUpdateValue = PositionUpdateValue.VARIABLE;     // Specifies if a position can be modified while open
            OrderOrPositionStrategyValue orderOrPositionStrategyValue = OrderOrPositionStrategyValue.POSITION;   // Specifies if the strategy is order-based or position-based
            VariabilityCapFactorValue variabilityCapFactorValue = VariabilityCapFactorValue.CONSTANT;    // Specifies if the capFactor is constant or varies based on the agent performance
            ShortSellingValue shortSellingValue = ShortSellingValue.ALLOWED;    // Specifies if short-selling is allowed
                        
            for (int i = 0; i < valueInvestors.size(); i++)
            	simulator.addValueStrategyForOneValueInvestor("IBM", "Value_" + i, distEntryThreshold.nextDouble(), distExitThreshold.nextDouble(), 
            	        distValueOffset.nextDouble(), (int) Math.round(distBcTicksFund.nextDouble()), params.capFactorFund, positionUpdateValue, 
            	        orderOrPositionStrategyValue, variabilityCapFactorValue, shortSellingValue);

            
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
            DoubleTimeSeriesList dtlPositionsTrend = new DoubleTimeSeriesList();
            DoubleTimeSeriesList dtlPositionsFund = new DoubleTimeSeriesList();
            DoubleTimeSeriesList dtlWealthIncrementsTrend = new DoubleTimeSeriesList();
            DoubleTimeSeriesList dtlWealthIncrementsFund = new DoubleTimeSeriesList();
            
            DoubleTimeSeries position;
            DoubleTimeSeries wealthIncrement;
            
            String secId = "IBM";
            
            /**
             * Positions and wealth changes for trend followers
             */
            for (int tr = 0; tr < numTrends; tr++) {
                            	
                String trendID = "Trend_" + tr;
            	
            	TrendMABCStrategy trend = (TrendMABCStrategy) simulator.getTrendFollowers().get(trendID).getStrategies().get(secId);
            	
            	position = simulator.getTrendFollowers().get(trendID).getPortfolio().getTsPosition(secId);
            	position.setId("Position: " + trendID);
            	
            	wealthIncrement = StatsTimeSeries.deltaWealth(simulator.getPrices(secId), position);
            	wealthIncrement.setId("Delta Wealth: " + trendID);
            	
            	dtlPositionsTrend.add(position);
            	dtlWealthIncrementsTrend.add(wealthIncrement);
            }
            
            if (numTrends >  0) {
                System.out.println();
                System.out.println(VersatileTimeSeriesCollection.printDecorated(dtlPositionsTrend));
                System.out.println(VersatileTimeSeriesCollection.printDecorated(dtlWealthIncrementsTrend));
            }

            
            /**
             * Positions and wealth changes for value investors
             */
            for (int val = 0; val < numFunds; val++) {
                
            	String valueID = "Value_" + val;
            	
            	ValueMABCStrategy fund = (ValueMABCStrategy) simulator.getValueInvestors().get(valueID).getStrategies().get(secId);
            	
            	position = simulator.getValueInvestors().get(valueID).getPortfolio().getTsPosition(secId);
                position.setId("Position: " + valueID);

                wealthIncrement = StatsTimeSeries.deltaWealth(simulator.getPrices(secId), position);
                wealthIncrement.setId("Delta Wealth: " + valueID);
            	
            	dtlPositionsFund.add(position);
            	dtlWealthIncrementsFund.add(wealthIncrement);
            }
            
            if (numFunds >  0) {
                System.out.println();
                System.out.println(VersatileTimeSeriesCollection.printDecorated(dtlPositionsFund));
                System.out.println(VersatileTimeSeriesCollection.printDecorated(dtlWealthIncrementsFund));
            }

            for (int tr = 0; tr < numTrends; tr++) {
                atcWealthTrend.populateSeries(run, "wealth_T_" + tr, dtlWealthIncrementsTrend.get(tr));
                atcPosTrend.populateSeries(run, "pos_T_" + tr, dtlPositionsTrend.get(tr));                
            }
                        
            for (int val = 0; val < numFunds; val++) {
                atcWealthFund.populateSeries(run, "wealth_F_" + val, dtlWealthIncrementsFund.get(val));
                atcPosFund.populateSeries(run, "pos_F_" + val, dtlPositionsFund.get(val));
            }
            
            /**
             * Prices, values, and volumes 
             */
            DoubleTimeSeries prices = simulator.getPrices(secId);
            DoubleTimeSeries values = simulator.getFundValues(secId);
            DoubleTimeSeries trendVolume = simulator.getTrendVolume(secId);
            DoubleTimeSeries fundVolume = simulator.getFundVolume(secId);
            DoubleTimeSeries totalVolume = simulator.getTotalVolume(secId);
            
            prices.setId("Price of " + secId + ":");
            values.setId("Value of " + secId + ":");
            trendVolume.setId("Total TREND volume of " + secId + ":");
            fundVolume.setId("Total FUND volume of " + secId + ":");
            totalVolume.setId("Total volume of " + secId + ":");
            
            System.out.println();
            System.out.println(VersatileTimeSeriesCollection.printDecorated(prices, values, trendVolume, 
                    fundVolume, totalVolume));
            
            
            atcPrice.populateSeries(run, secId + " Price", prices);
            atcValue.populateSeries(run, secId + " Value", values);
            atcVolumeFund.populateSeries(run, "volume_F", simulator.getFundVolume("IBM"));
            atcVolumeTrend.populateSeries(run, "volume_T", simulator.getTrendVolume("IBM"));
//End comment */
            
            
            /*
             * Create time series lists for extraction to R
             */
            
            tsPricesList.add(run, simulator.getPrices("IBM"));              // time series list of prices [nRuns x nTicks]
            tsFundValuesList.add(run, simulator.getFundValues("IBM"));      // time series list of general fund value [nRuns x nTicks]
            tsTotalVolumeList.add(run, simulator.getTotalVolume("IBM"));    // time series list of total volume [nRuns x nTicks]
            tsFundVolumeList.add(run, simulator.getFundVolume("IBM"));      // time series list of FUND volume [nRuns x nTicks]
            tsTrendVolumeList.add(run, simulator.getTrendVolume("IBM"));    // time series list of TREND volume [nRuns x nTicks]
            
            // Auxiliary graphic to analyse the positions of an individual FUND trader
            DoubleTimeSeries tsValueMinusPrice_F1 = new DoubleTimeSeries();
            DoubleTimeSeries tsEntryThreshold_Pos_F1 = new DoubleTimeSeries();
            DoubleTimeSeries tsEntryThreshold_Neg_F1 = new DoubleTimeSeries();
            DoubleTimeSeries tsExitThreshold_Pos_F1 = new DoubleTimeSeries();
            DoubleTimeSeries tsExitThreshold_Neg_F1 = new DoubleTimeSeries();
            
            // Results for fund investors, if present
            if (numFunds > 0) {
                ValueMABCStrategy fund_1 = (ValueMABCStrategy) simulator.getValueInvestors().get("Value_0").getStrategies().get("IBM");
                
                for (int k = 0; k < numTicks; k++) {
                	double ValueMinusPrice_F1 = simulator.getFundValues("IBM").get(k) + fund_1.getValueOffset() - simulator.getPrices("IBM").get(k);
                	
                	tsValueMinusPrice_F1.add(k, ValueMinusPrice_F1);
                	tsEntryThreshold_Pos_F1.add(k, fund_1.getEntryThreshold());
                	tsEntryThreshold_Neg_F1.add(k, -fund_1.getEntryThreshold());
                	tsExitThreshold_Pos_F1.add(k, fund_1.getExitThreshold());
                	tsExitThreshold_Neg_F1.add(k, -fund_1.getExitThreshold());
                }
                
                atcValuePriceDiff_F1.populateSeries(run, "IBM_VP", tsValueMinusPrice_F1);
                atcValuePriceDiff_F1.populateSeries(run, "Entry_Pos", tsEntryThreshold_Pos_F1);
                atcValuePriceDiff_F1.populateSeries(run, "Entry_Neg", tsEntryThreshold_Neg_F1);
                atcValuePriceDiff_F1.populateSeries(run, "Exit_Pos", tsExitThreshold_Pos_F1);
                atcValuePriceDiff_F1.populateSeries(run, "Exit_Neg", tsExitThreshold_Neg_F1);
            }
            
            
            /**
             * Long and short moving averages for price
             */
            vtscPriceAndMA.populateSeries(run, "price", simulator.getPrices(secId));
            vtscPriceAndMA.populateSeries(run, "long MA", StatsTimeSeries.MA(simulator.getPrices(secId), params.maLongTicksMin));
            vtscPriceAndMA.populateSeries(run, "short MA", StatsTimeSeries.MA(simulator.getPrices(secId), params.maShortTicksMin));
            
            
            /**
             * Print the volatility of log-returns for calibration purposes 
             */            
            DoubleTimeSeries tsLogReturns = new DoubleTimeSeries("Log return");
            
            for (int k = 1; k < numTicks; k++) {
            	double price_current_tick = simulator.getPrices(secId).get(k);
            	double price_previous_tick = simulator.getPrices(secId).get(k-1);
            	tsLogReturns.add(Math.log(price_current_tick) - Math.log(price_previous_tick));
            }
            
            /**
             * Autocorrelation functions: standard, absolute, squared
             */
            int maxLagAcf = 30;
            
            DoubleTimeSeries tsAcf = new DoubleTimeSeries("ACF", tsLogReturns.acf(maxLagAcf));
            DoubleTimeSeries tsAcfAbs = new DoubleTimeSeries("abs(ACF)", tsLogReturns.acfAbs(maxLagAcf));
            DoubleTimeSeries tsAcfSquared = new DoubleTimeSeries("ACF^2", tsLogReturns.acfSquared(maxLagAcf));
            
            vtscACF.add(tsAcf);
            vtscACF.add(tsAcfAbs);
            vtscACF.add(tsAcfSquared);
            
            logger.debug("VOLATILITY of LOG-RETURNS: {}", tsLogReturns.stdev());
            logger.debug("KURTOSIS of LOG-RETURNS  : {}", tsLogReturns.excessKurtosis());
            logger.debug("SKEWNESS of LOG-RETURNS  : {}", tsLogReturns.skewness());
            logger.debug("MEAN VOLUME - F: {}, T: {}", simulator.getFundVolume("IBM").mean(), simulator.getTrendVolume("IBM").mean());
            
            System.out.println();
            System.out.println(VersatileTimeSeries.printDecorated(tsLogReturns));

            System.out.println();
            System.out.println(VersatileTimeSeriesCollection.printDecorated(tsAcf, tsAcfAbs, tsAcfSquared));
        

        
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
        if (numTrends > 0) {
        	charts.draw(atcWealthTrend);
            charts.draw(atcPosTrend);
            charts.draw(vtscPriceAndMA);
        }
        
        if (numFunds > 0) {
        	charts.draw(atcWealthFund);
            charts.draw(atcPosFund);
            charts.draw(atcValue);
//            charts.draw(atcValuePriceDiff);
            charts.draw(atcValuePriceDiff_F1);
        }        
        
        charts.draw(atcPrice);
        charts.draw(vtscACF);
        charts.draw(atcVolumeFund);
        charts.draw(atcVolumeTrend);
        
//        histogram.drawSimpleHistogram(atcVolumeFund.getSeries(0));   //TODO: adjust index when numRuns > 1
//        histogram.drawSimpleHistogram(atcVolumeTrend.getSeries(0));
//End comment */
        
        
        
        
               
        
        /**
         *      Write data on mean positions to R to calculate the normalisation factor
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
          
        
        /**
         *      Write results to file for further analysis with R
         */

        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_price_timeseries.csv").write(tsPricesList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_fundvalues_timeseries.csv").write(tsFundValuesList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_totalvolume_timeseries.csv").write(tsTotalVolumeList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_fundvolume_timeseries.csv").write(tsFundVolumeList);
        ResultWriterFactory.getCSVWriter("./out/trend-value-abm-simulation/list_trendvolume_timeseries.csv").write(tsTrendVolumeList);
        
        
        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
    }
    }
}
