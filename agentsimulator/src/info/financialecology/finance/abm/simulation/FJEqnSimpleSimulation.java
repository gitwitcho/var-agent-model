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
package info.financialecology.finance.abm.simulation;

import repast.simphony.random.RandomHelper;
import cern.colt.Timer;
import cern.jet.random.*;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import org.slf4j.LoggerFactory;

import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.FormattedDoubleArrayList;
import info.financialecology.finance.utilities.datastruct.VersatileDataTable;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeries;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeriesCollection;
import info.financialecology.finance.utilities.output.ResultWriterFactory;
import jargs.gnu.CmdLineParser;

import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;

/**
 * ### WARNING ### This class contains UNRESOLVED BUGS
 * <p>
 * FJEquationSimple is the first and simplest implementation of the Farmer and 
 * Joshi (2002) market model with a single asset. It is a direct implementation
 * from an existing MATLAB model and does not use agents or other auxiliary 
 * simulation classes except for data and parameter storage, and for writing 
 * results to a file.
 * <p>
 * There are two types of traders in this model: value investors and trend 
 * followers. There are no borrowing and short-selling constraints. Prices are 
 * determined via an impact function and largely depend on total orders emitted 
 * at each time step by both types of trader. Value investors determine their new
 * positions based on the distance of current price to a random value signal that 
 * has a common part and an investor-specific random offset. Trend followers 
 * determine their new position by computing the return over a price window of 
 * investor-specific random length. Log prices are used throughout. The position 
 * sizes are scaled with an investor-specific factor that represents trading capital. 
 * Thresholds, again investor-specific, determine when a trade is entered and exited.
 * <p>
 * There are several random parameters and two random processes, and although we 
 * create separate random distributions for each of them, they are all linked to a 
 * single underlying random generator. Hence, if we wish to replicate random streams 
 * in an experiment, we need to understand that for instance changing the number of 
 * value investors will, in the current set-up, produce totally different random 
 * streams for the trend followers. Or changing the <code>delayMax</code> parameter will 
 * change the random sequences for both trend followers and value investors. 
 * UPDATE: this problem has been solved in later models by creating a pool of 
 * independent random engines.
 * <p>
 * The simulation experiment is repeated <code>nRuns</code> times, and each experiment
 * consists of <code>nTicks</code> time steps. 
 * <p>
 * We store the time series of log prices, log values of the value reference process, 
 * log values of the price noise process, time series of orders of the value investors 
 * and the trend followers, and time series of volume.
 * <p>
 * Farmer, D. J., & Joshi, S. (2002). The price dynamics of common trading strategies. 
 * 
 * @author Gilbert Peffer
 *
 */
public class FJEqnSimpleSimulation {

    /*
     * Class CmdArgs stores the command line options.
     * 
     *  -v (verbose). Indicates the level of detail of the standard output
     *    - trace: writes all information, for debugging
     *    - debug: writes all information, expect for model results
     *    - summary: writes only summary model results
     *    - detail: writes detailed (e.g. run-level) model results
     *    - none: no output (the default)
     *  -p (paramFilePath). Path to parameter file
     *  -o (outDirPath). Path to output folder. Default is current directory
     *      
     */
    private static class CmdArgs {
        static FJEqnSimpleParams params;   // model parameters
//        static FJEquationSimpleParamsRandomiser paramsRand;
        static String verbose;             // verbosity of output: trace, debug, summary, detail, none (default)
        static String paramFilePath;       // path to parameter file
        static String outDirPath;          // path to output directory
    }

    /**
     * The main routine. Sets up the logging facility, initialises the model parameters,
     * the random distributions, and the data storage. It then initialises the data 
     * structure representing the traders and runs the simulation. Finally, it assembles 
     * the result time series and writes them to a file.
     * 
     * @param args command line arguments. 
     * @param -p relative path and name of the model parameter file. Example: 
     * <code>./input/fj_equation_test123.xml</code>
     * @param -o relative or absolute path to output files folder. If omitted
     * the default is the current directory
     * @param -v verbose output (options: trace, debug, detail, summary, none (the default))
     * @param Example <code>java -jar FJEquationSimple.jar -v summary -p ./input/fj_equation_test123.xml 
     * -o ./output</code>
     */
    public static void main(String[] args) {
        
        System.out.println("\n##############################################################");
        System.out.println("#");
        System.out.println("#    WARNING!!! - this simulation model still contains BUGS");
        System.out.println("#");
        System.out.println("##############################################################\n");

        /*
         * Initialise timers and start global timer
         */
        Timer timerGlobal  = new Timer();   // global timer to calculate total execution time of the experiment (cern.colt)
        Timer timer     = new Timer();      // local timer to calculate execution times of particular methods (cern.colt)
        timerGlobal.start();

        /*
         * Initialise logging facility and set the level at and above which messages are logged
         */
        Logger root = (Logger)LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        root.setLevel(Level.DEBUG);
        Logger logger = (Logger)LoggerFactory.getLogger("main");
        
        // Set number formats for file/console output 
        DecimalFormat df = new DecimalFormat("0.00000", new DecimalFormatSymbols(Locale.UK));
        DoubleTimeSeries.setFormatter(df);
        FormattedDoubleArrayList.setFormatter(df);

        /*
         * Read command line arguments and process parameter file 
         */
        processCmdLine(args);        // process command line arguments
        FJEqnSimpleParams params = CmdArgs.params;
//        FJEqnSimpleParamsRandomiser paramsRand = CmdArgs.paramsRand;   // TODO randomise non-relevant parameters
        
        /*
         * Define output file names. This basically indicates what results we want 
         * to have written into .csv files rather than just on the screen. These
         * files can then be read by a statistics package such as R. 
         */
        HashMap<String, String> outputFiles = new HashMap<String, String>() {
            private static final long serialVersionUID = 1L;
            {
                put("price", CmdArgs.outDirPath + "price_timeseries.csv");
                put("vol", CmdArgs.outDirPath + "volatilities_run_exp.csv");
            }};


        /**====================================================================
         * 
         *      MODEL SET-UP
         *      
         **====================================================================*/
        
        logger.debug("Setting up FJ_EQUATION_SIMPLE simulation model\n");
        
        /*
         * Random seed - comment out to generate different random sequences each 
         * time this code is run
         * 
         *      - If set: forces the random generator to produce the same random number 
         *      sequences for each experiment (but a different sequence for each run)
         *      - If not set: seed is set internally using the CPU clock
         */
        RandomHelper.setSeed(628098474);
        logger.trace("Seed of the random number generator: {}", RandomHelper.getSeed());
        
        /*
         *      MODEL PARAMETERS
         *      ----------------
         *      
         *      The distributions defined below draw on a single random number stream.
         *      In later models, we use a new class (RandomGeneratorPool) that can
         *      create independent random number streams
         */
        
        /*
         * Market - initialise parameters and random generators
         */
        double logPrice_0         = Math.log(params.price_0);   // log price at time t=0
        Normal distLogPriceNoise  = RandomHelper.createNormal(params.priceNoiseMu, params.priceNoiseSigma); // noise distribution for log price process
        
        /*
         * Fundamental traders - initialise parameters and random generators
         */
        double logValue_0           = logPrice_0; // log value at time t=0
        Normal distRefValue         = RandomHelper.createNormal(params.refValueMu, params.refValueSigma);       // noise distribution for reference process of log value
        Uniform distOffsetValue     = RandomHelper.createUniform(params.offsetValueMin, params.offsetValueMax); // distribution for trader-specific value offset
        Uniform distEntryThreshValueInv = RandomHelper.createUniform(params.TMinValueInv, params.TMaxValueInv);             // distribution of trader-specific entry threshold
        Uniform distExitThreshValueInv  = RandomHelper.createUniform(params.tauMinValueInv, params.tauMaxValueInv);         // distribution of trader-specific exit threshold
        
        /*
         * Technical trader - initialise parameters and random generators
         */
        Uniform distDelayTrend     = RandomHelper.createUniform(params.delayMin, params.delayMax);           // distribution of trader-specific time horizon for technical strategy
        Uniform distEntryThreshTrend = RandomHelper.createUniform(params.TMinTrend, params.TMaxTrend);       // distribution of trader-specific entry threshold
        Uniform distExitThreshTrend  = RandomHelper.createUniform(params.tauMinTrend, params.tauMaxTrend);   // distribution of trader-specific exit threshold

        /*
         *      DATA STORAGE
         *      ------------
         */
        DoubleTimeSeries tsLogPrices        = null;      // log price time series for a single run
        DoubleTimeSeries tsLogRefValues     = null;
        DoubleTimeSeries tsPriceNoise       = null;
        DoubleTimeSeries tsOrderValueInv    = null;
        DoubleTimeSeries tsOrderTrend       = null;
        DoubleTimeSeries tsVolume           = null;
        
        // TODO write a static function in the DoubletimeSeriesList that returns a DoubleTimeSeries (with a given name)
                
        /*
         *      AGENTS
         *      ------
         */
        
        class ValueInvestor {           // nested class for the value investor
            ValueInvestor () {}
            public double position;     // number of assets owned
            public double order;        // number of assets to buy or sell
            public double valueOffset;  // investor-specific offset when computing the current value of the asset
            public double entryThresh;  // threshold in terms of price-value difference at which to enter the trade 
            public double exitThresh;   // threshold in terms of price-value difference at which to exit the trade
            public double capFac;       // factor akin to trading capital to up-or down-scale the new position
        }
        
        class TrendFollower {           // nested class for the trend follower
            TrendFollower () {}
            public double position;
            public double order;
            public int    delay;
            public double entryThresh;
            public double exitThresh;
            public double capFac;
        }
        
        ArrayList<ValueInvestor>   valueInvestors = new ArrayList<ValueInvestor>();      // array of fundamental traders 
        ArrayList<TrendFollower>   trendFollowers = new ArrayList<TrendFollower>();      // array of technical traders
        
        /*
         *      SET UP DATA COLLECTIONS
         *      -----------------------
         */
        
        VersatileTimeSeries.StaticInternalParams.setTimePeriodFormat("actual");      // global format for time in time series
        VersatileDataTable.StaticInternalParams.setColumnWidth(10);            //TODO (?) global column width (???) of output table

        VersatileTimeSeriesCollection tscResults = new VersatileTimeSeriesCollection("time series results");      // collection for time series type results 
        VersatileDataTable cdsVolatilities = new VersatileDataTable("volatilities");                  // volatilities - run-level summary statistics
        VersatileDataTable cdsKurtosis     = new VersatileDataTable("kurtosis");                      // kurtosis (fat tails) - run-level summary statistics
        
        /*
         *      SET UP VALUE INVESTORS AND TREND FOLLOWERS
         *      ------------------------------------------
         */
        for (int j = 0; j < params.numValueInvestors; j++) {   // Value investors
            ValueInvestor valueInvestor = new ValueInvestor();
            valueInvestor.position = 0.0;
            valueInvestor.order = 0.0;
            valueInvestor.valueOffset = distOffsetValue.nextDouble();
            valueInvestor.entryThresh = distEntryThreshValueInv.nextDouble();
            valueInvestor.exitThresh = distExitThreshValueInv.nextDouble();

            if (params.constCapFac)
                valueInvestor.capFac = 4 * params.aValueInv;
            else
                valueInvestor.capFac = 1.6 * params.aValueInv * (distEntryThreshValueInv.nextDouble() - distExitThreshValueInv.nextDouble());  // BUG: (?) should use fundTrader.entryThrash and fundTraderexitThresh
            
            valueInvestors.add(valueInvestor);
        }
        
        for (int j = 0; j < params.numTrendFollowers; j++) {    // Trend followers
            TrendFollower trendFollower = new TrendFollower();
            trendFollower.position = 0.0;
            trendFollower.order = 0.0;
            trendFollower.delay = distDelayTrend.nextInt();
            trendFollower.entryThresh = distEntryThreshTrend.nextDouble();
            trendFollower.exitThresh = distExitThreshTrend.nextDouble();
            
            if (params.constCapFac)
                trendFollower.capFac = 4 * params.aTrend;
            else
                trendFollower.capFac = 1.6 * params.aValueInv * (distEntryThreshTrend.nextDouble() - distExitThreshTrend.nextDouble());  // BUG: (?) should use techTrader.entryThrash and techTraderexitThresh
            
            trendFollowers.add(trendFollower);
        }
        
        
        /*
         *      PRINT BASIC INFO TO CONSOLE
         *      ---------------------------
         */
        if ((CmdArgs.verbose.compareToIgnoreCase("summary") == 0) || (CmdArgs.verbose.compareToIgnoreCase("detail") == 0) 
                || logger.isTraceEnabled()) {  // only write summary results if -v option is set to 'summary' or 'trace'  
            System.out.println("\n*================================================");
            System.out.println("*");
            System.out.println("*          EXPERIMENT - FJ_EQUATION_SIMPLE");
            System.out.println("*");
            System.out.println("*================================================\n");
    
            System.out.println("Specification version of library 'agentsimulator': " + 
                    FJEqnSimpleSimulation.class.getPackage().getSpecificationVersion());
            System.out.println("Parameter file path: " + CmdArgs.paramFilePath + "\n");
            System.out.println("Number of runs per experiment: " + params.nRuns);
            System.out.println("Number of ticks per run: " + params.nTicks);
            System.out.println("Random seed " + RandomHelper.getSeed());
            System.out.println("Number of agents: " + (params.numValueInvestors + params.numTrendFollowers));
            System.out.println("Number of value investors: " + params.numValueInvestors);
            System.out.println("Number of trend followers: " + params.numTrendFollowers);
            System.out.println("Liquidity: " + params.liquidity + "\n");
        }

        /**====================================================================
         * 
         *      SIMULATION EXPERIMENT
         *      ---------------------
         *      
         *      A simulation experiment consists of 'nRuns' consecutive
         *      executions or runs of the simulation model. In run, the
         *      model is initialised and then executed over 'nTicks' time
         *      steps.
         *      
         *      In this simulation experiment, each run resets the agents, 
         *      result data structures, and initial values of log prices
         *      and log reference values over the delay window before
         *      executing the model.
         *      
         *      The number of ticks per run is extended by the warm-up 
         *      phases of 'delayMax' ticks. 'delayMax' is the upper bound
         *      of the uniform random distribution for the delay window
         *      size. 
         *      
         *      Unless the seed is fixed using RandomHelper.setSeed(seed),
         *      the random sequences change with each simulation run.
         *      
         *      To obtain the same results from each run of the simulation 
         *      _experiment_ you need to set the random seed above  to a 
         *      fixed value, e.g. 'RandomHelper.setSeed(628098474)'.
         *      
         **====================================================================*/
        
        
        logger.debug("EXPERIMENT #{} - executing...\n", 0);

        for (int iRun = 0; iRun < params.nRuns; iRun++) {    // run the experiment nRuns times
            
            /**
             *      SETTING UP INITIAL VALUES AND TRADERS 
             */
            
            tsLogPrices = new DoubleTimeSeries("log_p_" + (iRun + 1));          // price process
            tsLogRefValues = new DoubleTimeSeries("log_v_" + (iRun + 1));       // reference process for the fundamental value of the asset
            tsPriceNoise = new DoubleTimeSeries("noise_" + (iRun + 1));         // price noise added to the deterministic linear price equation
            tsOrderValueInv = new DoubleTimeSeries("order_f_" + (iRun + 1));    // time series of total orders of value investors
            tsOrderTrend = new DoubleTimeSeries("order_t_" + (iRun + 1));       // time series of total orders of trend followers
            tsVolume = new DoubleTimeSeries("volume_" + (iRun + 1));
            
            
            /*
             * Initialise the process of log prices and the reference process of 
             * log values for the first 'delayMax' time steps. Why? The trend 
             * follower uses a strategy that uses the price 'delayMax' time steps 
             * prior to the current tick
             */
            double logPrice = logPrice_0;   // initial log price
            double noise;                   // current value of the price noise process
            
            // Initialise log prices over the delay window
            tsLogPrices.add(0, logPrice);
            
            for (int j = 1; j <= params.delayMax; j++) {
                noise = distLogPriceNoise.nextDouble();
                tsPriceNoise.add(j, noise);
                logPrice = tsLogPrices.getValue(j - 1) + noise; 
                tsLogPrices.add(j, logPrice);
            }
            
            // Initialise log of reference values over the delay window 
            double logRefValue = logValue_0;
            tsLogRefValues.add(0, logRefValue);

            for (int j = 1; j <= params.delayMax; j++) {
                logRefValue += distRefValue.nextDouble();
                tsLogRefValues.add(j, logRefValue);
            }
            
            // Initialise remaining time series variables over the delay window
            for (int j = 0; j <= params.delayMax; j++) {
                tsOrderTrend.add(j, 0);
                tsOrderValueInv.add(j,0);
                tsVolume.add(j, 0);
            }
            
            /*
             * Initialising positions and orders of value investors and trend followers
             */
            for (int j = 0; j < params.numValueInvestors; j++) {   // Value investors
                ValueInvestor valueInvestor = valueInvestors.get(j);
                valueInvestor.position = 0.0;
                valueInvestor.order = 0.0;
            }
            
            for (int j = 0; j < params.numTrendFollowers; j++) {    // Trend followers
                TrendFollower trendFollower = new TrendFollower();
                trendFollower.position = 0.0;
                trendFollower.order = 0.0;
            }
            
            
            /**====================================================================
             * 
             *      SIMULATION RUN
             *      --------------
             *      
             *      A simulation run executes the simulation model over
             *      nTicks time steps.
             *      
             *      The code below initialises and runs
             *      the model, and stores the results in the corresponding
             *      data structures.
             *      
             **====================================================================*/
            
            
            timer.start();  // local timer to compute single simulation time
            
            /**
             * Simulation loop of 'nTicks' starting one tick beyond the warm-up 
             * phase marked by the size of the delay window
             */
            logger.debug("RUN #{} - executing...", iRun + 1);

            for (int t = params.delayMax + 1; t <= params.delayMax + params.nTicks; t++) {
                
                double totalOrderValueInv = 0.0;
                double totalOrderTrend = 0.0;
                double totalVolume = 0.0;
                
                logRefValue += distRefValue.nextDouble();   // update reference value for this time step 
                tsLogRefValues.add(t, logRefValue);
                
                /*
                 * Compute orders for all agents
                 */
                
                // Orders from value investors
                for (int k = 0; k < params.numValueInvestors; k++) {
                    ValueInvestor vi = (ValueInvestor) valueInvestors.get(k);
                    double logValueFund = logRefValue + vi.valueOffset;        // value of asset at time t for trader k
                    double diff = logValueFund - tsLogPrices.getValue(t - 1);   // difference between price and value
                    double oldPosition = vi.position;
                    
                    // Entering and exiting the trade
                    if (Math.abs(diff) > vi.entryThresh) {     // BUG these are the wrong conditions according to the transitions defined by the state machine
                        vi.position = vi.capFac * diff;
                    } 
                    else if (Math.abs(diff) < vi.exitThresh) {
                        vi.position = 0.0;
                    }
                    
                    vi.order = vi.position - oldPosition;
                    totalOrderValueInv += vi.order;
                    totalVolume += Math.abs(vi.order);
                }
                
                // Orders from trend followers
                for (int k = 0; k < params.numTrendFollowers; k++) {
                    TrendFollower tf = (TrendFollower) trendFollowers.get(k);
                    double priceDiff = tsLogPrices.getValue(t - 1) - tsLogPrices.getValue(t - tf.delay);  // Slight difference in index to Matlab model
                    double oldPosition = tf.position;
                    
                    if (Math.abs(priceDiff) > tf.entryThresh) {     // BUG these are the wrong conditions according to the transitions defined by the state machine
                        tf.position = tf.capFac * priceDiff;
                    }
                    else if (Math.abs(priceDiff) < tf.exitThresh) {
                        tf.position = 0.0;
                    }
                    
                    tf.order = tf.position - oldPosition;
                    totalOrderTrend += tf.order;
                    totalVolume += Math.abs(tf.order);
                }
                
                /*
                 * Compute new price
                 */
                noise = distLogPriceNoise.nextDouble();
                double logPrice_t = tsLogPrices.getValue(t - 1) + (1 / params.liquidity) * (totalOrderValueInv + totalOrderTrend) + noise;
                
                tsLogPrices.add(t, logPrice_t);
                tsOrderValueInv.add(t, totalOrderValueInv);
                tsOrderTrend.add(t, totalOrderTrend);
                tsVolume.add(t, totalVolume);
            }
            
            logger.debug("RUN #{} - execution time: {} seconds", iRun + 1, timer.elapsedTime());
            
            /**====================================================================
             * 
             *      RESULTS (CURRENT RUN)
             *      ---------------------
             *      
             *      Output:
             *      - Time series: prices, log reference values, total orders and
             *        total positions of value investors and trend followers, and 
             *        volume
             *        
             *      Assembling:
             *      - Summary statistics (run-level): volatility, kurtosis
             *      
             **====================================================================*/
            
            
            /*
             * Populate time series results collection
             */
            tscResults.removeAllSeries();   // clean time series collection
            tscResults.populateSeries(iRun + 1, "log_price", tsLogPrices);          // populate with log prices from current run
            tscResults.populateSeries(iRun + 1, "log_ref_value", tsLogRefValues);
            tscResults.populateSeries(iRun + 1, "orders_VALUE", tsOrderValueInv);
            tscResults.populateSeries(iRun + 1, "orders_TREND", tsOrderTrend);
            tscResults.populateSeries(iRun + 1, "volume", tsVolume);

            /*
             * Generate additional time series
             */
            tscResults.insertSeriesExp("log_price", "price");                   // create a price series and insert into collection
            tscResults.insertSeriesCumulative("orders_VALUE", "pos_VALUE");     // total position of value investors 
            tscResults.insertSeriesCumulative("orders_TREND", "pos_TREND");     // total position of trend followers
            tscResults.insertSeriesDifference("log_price", "log_return");       // log return

            /*
             * Write results for current run to console
             */
            if ((CmdArgs.verbose.compareToIgnoreCase("detail") == 0) || logger.isTraceEnabled()) {  // only write run-level results if -v option is set to 'detail' or 'trace'  
                int FIRST_COLUMN_WIDTH = 22;    // sets the width of row label column
                boolean addHeader = false;      // add a table header?
                
                logger.trace("RUN #{} - Printing results\n", iRun + 1);
                
                if (iRun == 0) {
                    addHeader = true;    // only add a table header at the start of the experiment 
                    System.out.println("*======================================");
                    System.out.println("*");
                    System.out.println("*          RESULTS (PER RUN)");
                    System.out.println("*");
                    System.out.println("*======================================\n\n");
                }
                
                System.out.print(tscResults.getSubset("price").printDecoratedSeries("PRICE", FIRST_COLUMN_WIDTH, addHeader));
                System.out.print(tscResults.getSubset("log_ref_value").printDecoratedSeries("LOG REF_VALUE", FIRST_COLUMN_WIDTH));
                System.out.print(tscResults.getSubset("orders_VALUE").printDecoratedSeries("ORDER_VALUE", FIRST_COLUMN_WIDTH));
                System.out.print(tscResults.getSubset("orders_TREND").printDecoratedSeries("ORDER_TREND", FIRST_COLUMN_WIDTH));
                System.out.print(tscResults.getSubset("pos_VALUE").printDecoratedSeries("POSITION (VALUE INV.)", FIRST_COLUMN_WIDTH));
                System.out.print(tscResults.getSubset("pos_TREND").printDecoratedSeries("POSITION (TEND FOLL.)", FIRST_COLUMN_WIDTH));
                System.out.print(tscResults.getSubset("volume").printDecoratedSeries("VOLUME", FIRST_COLUMN_WIDTH));
                System.out.println();
            }
            
            /*
             * Compute statistics for the current run
             */
            cdsVolatilities.merge(tscResults.getSeriesStdev("log_return", "vol"));
            cdsVolatilities.insertColumnAverage("Mean", "vol");     // BUG for this single asset case, output is incorrect
            cdsVolatilities.insertColumnStdev("Stdev", "vol");
            cdsKurtosis.merge(tscResults.getSeriesUnbiasedExcessKurtosis("log_return", "kurtosis"));
        }
        

        /**====================================================================
         * 
         *      RESULTS (EXPERIMENT)
         *      --------------------
         *      
         *      Output:
         *      - Summary statistics (run-level): volatility, kurtosis
         *      
         **====================================================================*/
        
        
        if ((CmdArgs.verbose.compareToIgnoreCase("summary") == 0) || (CmdArgs.verbose.compareToIgnoreCase("detail") == 0) 
                || logger.isTraceEnabled()) {  // only write summary results if -v option is set to 'summary' or 'trace'  
            System.out.println("\n*======================================");
            System.out.println("*");
            System.out.println("*          RESULTS (EXPERIMENT)");
            System.out.println("*");
            System.out.println("*======================================\n\n");
    
            System.out.println(cdsVolatilities.printDecoratedTable("LOG RETURN VOLATILITY"));
            System.out.println();
            System.out.println(cdsKurtosis.printDecoratedTable("LOG RETURN UNBIASED EXCESS KURTOSIS"));
    
            System.out.println("\nParameter file used:");
            System.out.println("------------------------");
            System.out.println(CmdArgs.paramFilePath);  
            System.out.println("------------------------\n");
        }
        
        
        /**====================================================================
         * 
         *      WRITE RESULTS TO FILE
         *      
         **====================================================================*/

        if ((CmdArgs.verbose.compareToIgnoreCase("summary") == 0) || (CmdArgs.verbose.compareToIgnoreCase("detail") == 0) 
                || logger.isTraceEnabled()) {  // only write summary results if -v option is set to 'summary' or 'trace'
            System.out.println("Writing results to file(s)");            
        }
        
        ResultWriterFactory.getCSVWriter(outputFiles.get("price")).write(tscResults);
        ResultWriterFactory.getCSVWriter(outputFiles.get("vol")).write(cdsVolatilities);

        System.out.println();
        logger.debug("\nEXPERIMENT #{} - execution time: {} seconds\n", 0, timer.elapsedTime());    // TODO extend the logging to multiple experiments
        logger.debug("----- END OF SIMULATION EXPERIMENT -----");
        
        System.out.println("\n##############################################################");
        System.out.println("#");
        System.out.println("#    WARNING!!! - this simulation model still contains BUGS");
        System.out.println("#");
        System.out.println("##############################################################\n");
        
        System.exit(0);
    }
    
    /**
     * A method to extract the options from the command line and read the 
     * input parameters from the file provided by the option <code>-p</code>.
     * This method uses GNU's JArgs command line option parsing suite. 
     * <p>
     * Example for path format: <code>./input/fj_equation_test123.xml</code>
     * <p>
     * See also:
     *      JArgs (by GNU): <code>http://tinyurl.com/bp2tomx.</code>
     *      "This tiny project provides a convenient, compact, pre-packaged and 
     *      comprehensively documented suite of command line option parsers for 
     *      the use of Java programmers"
     *      
     */      
    private static void processCmdLine(String[] args) {
        Logger root = (Logger)LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        Logger logger = (Logger)LoggerFactory.getLogger("main");

        /*
         * Set up and initialise the command line parser
         */
        CmdLineParser parser = new CmdLineParser();
        CmdLineParser.Option verbose = parser.addStringOption('v', "verbose");
        CmdLineParser.Option paramFilePath = parser.addStringOption('p', "params");
        CmdLineParser.Option outDirPath = parser.addStringOption('o', "outdir");

        /*
         * Parse the command line
         */
        try {
            parser.parse(args);
        }
        catch ( CmdLineParser.OptionException e ) {
            System.err.println(e.getMessage());
            printUsage();
            System.exit(2);
        }

        /*
         * Extract the arguments from the parsed command line and fix if needed.
         */
        
        // Extract name of parameter file and validate
        CmdArgs.paramFilePath = (String)parser.getOptionValue(paramFilePath);
        Assertion.assertStrict(CmdArgs.paramFilePath != null, Assertion.Level.ERR, "File name argument is missing\n\n" + getUsage() + "\n");    
        
        // Extract and fix name of output directory or assign the current directory as a default
        CmdArgs.outDirPath = (String)parser.getOptionValue(outDirPath, ".");
        if (!CmdArgs.outDirPath.endsWith("/")) CmdArgs.outDirPath += "/";
        
        // Extract verbose output type. See comment of CmdArgs class above for detaiils
        CmdArgs.verbose = (String)parser.getOptionValue(verbose, "none");
        
        // Set the logging level. WARN and ERROR levels are somewhat misused
        // here to indicate that only model results are wanted
        if (CmdArgs.verbose.compareToIgnoreCase("none") == 0)
            root.setLevel(Level.OFF);
        else if (CmdArgs.verbose.compareToIgnoreCase("trace") == 0)
            root.setLevel(Level.TRACE);
        else if (CmdArgs.verbose.compareToIgnoreCase("debug") == 0)
            root.setLevel(Level.DEBUG);
        else
            root.setLevel(Level.OFF);
        
        /*
         * Read parameter file and extract parameters
         */
        FJEqnSimpleParams params = null;
//        FJEqnSimpleParamsRandomiser paramsRand = null;

        try {
            params = FJEqnSimpleParams.readParameters(CmdArgs.paramFilePath);            
//            if (fileNameRandValue != null) paramsRand = FJEqnSimpleParamsRandomiser.readParameters(fileNameRandValue);
        } catch (Throwable e) {
            logger.error(e.getMessage());
            System.exit(0);
        }
        
        CmdArgs.params = params;
//        CmdArgs.paramsRand = paramsRand;
        
    }
    
    /**
     * Prints command line options for this executable jar to the console
     */
    private static void printUsage() {
        System.err.println(getUsage());
    }
    
    /**
     * Defines the command line options for this executable jar
     * 
     * @return the command line options, some of which might be optional or have default values
     */
    private static String getUsage() {
        return "Usage: FJEquationSimple [{-v,--verbose}] {-p,--params} a_filename, [{-o, --output} a_directory]";
    }
}


