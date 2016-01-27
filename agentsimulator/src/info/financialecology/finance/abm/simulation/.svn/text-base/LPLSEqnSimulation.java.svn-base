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

import info.financialecology.finance.abm.model.FJEqnSimulator;
import info.financialecology.finance.abm.model.LPLSEqnModel;
import info.financialecology.finance.abm.model.LPLSEqnSimulator;
import info.financialecology.finance.abm.model.LPLSRandomGeneratorPool;
import info.financialecology.finance.abm.simulation.LPLSEqnParams.Sequence;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.datastruct.Datastore;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.datastruct.FormattedDoubleArrayList;
import info.financialecology.finance.utilities.datastruct.VersatileDataTable;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeries;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeriesCollection;
import jargs.gnu.CmdLineParser;

import java.io.FileNotFoundException;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.HashMap;
import java.util.Locale;

import org.slf4j.LoggerFactory;
import repast.simphony.random.RandomHelper;

import cern.colt.Timer;
import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;

/**
 * TODO The long-short model
 * 
 * @author Gilbert Peffer
 *
 */
public class LPLSEqnSimulation {

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
        static LPLSEqnParams params;         // model parameters
//        static LPLSquationSimpleParamsRandomiser paramsRand;
        static String verbose;             // verbosity of output: trace, debug, summary, detail, none (default)
        static String paramFilePath;       // path to parameter file
        static String outDirPath;          // path to output directory
    }

    /**
     * The main routine. Sets up the logging facility and the data storage. It also
     * assembles the result time series and writes them to a file.
     * 
     * @param args command line arguments. 
     * @param -p relative path and name of the model parameter file. Example: 
     * <code>./input/lpls_equation_test123.xml</code>
     * @param -o relative or absolute path to output files folder. If omitted
     * the default is the current directory
     * @param -v verbose output (options: trace, debug, detail, summary, none (the default))
     * @param Example <code>java -jar LPLSEqnSimulation.jar -v summary -p ./input/lpls_equation_test123.xml 
     * -o ./output</code>
     */
    public static void main(String[] args) {

        /*
         * Initialise timers and start global timer
         */
        Timer timerGlobal  = new Timer();   // a timer to calculate total execution time of the experiment (cern.colt)
        Timer timer     = new Timer();      // a timer to calculate execution times of particular methods (cern.colt)
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
        LPLSEqnParams params = CmdArgs.params;
//        LPLSqnSimpleParamsRandomiser paramsRand = CmdArgs.paramsRand;   // TODO randomise non-relevant parameters
        
        params.validate();

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

        logger.debug("Setting up LPLS_EQUATION simulation model\n");

        /*
         * Random seed - comment out to generate different random sequences each 
         * time this code is run
         * 
         *      - If set: forces the random generator to produce the same random number 
         *      sequences for each experiment (but a different sequence for each run)
         *      - If not set: seed is set internally using the CPU clock
         */

        int seed = 13341;
        
// TODO NEW RANDOMGENERATORPOOL        LPLSRandomGeneratorPool.getInstance(params, seed);   // initializing the random generator pool using the same seed
//        LPLSRandomGeneratorPool.getInstance(params);   // initializing the random generator pool using an arbitrary seed
        logger.trace("Seed passed to the random generator pool: {}", seed);

        LPLSEqnSimulator simulator;

        /*
         *      SET UP DATA COLLECTIONS
         *      -----------------------
         */
        
        VersatileTimeSeries.StaticInternalParams.setTimePeriodFormat("tick");
        VersatileDataTable.StaticInternalParams.setColumnWidth(15);

        VersatileTimeSeriesCollection tscResults = new VersatileTimeSeriesCollection("time series results");
        VersatileTimeSeries.StaticInternalParams.setTimePeriod(VersatileTimeSeries.Period.DAY);
        
        VersatileDataTable cdsFinalTimeSlice = new VersatileDataTable("final time slice");
        VersatileDataTable cdsAverageOrders = new VersatileDataTable("average orders");
        VersatileDataTable cdsVolatilities = new VersatileDataTable("volatilities");
        VersatileDataTable cdsSkewness = new VersatileDataTable("skewness");
        VersatileDataTable cdsKurtosis = new VersatileDataTable("kurtosis");
        
        /*
         *      PRINT BASIC INFO TO CONSOLE
         *      ---------------------------
         */
        if ((CmdArgs.verbose.compareToIgnoreCase("summary") == 0) || (CmdArgs.verbose.compareToIgnoreCase("detail") == 0) 
                || logger.isTraceEnabled()) {  // only write summary results if -v option is set to 'summary' or 'trace'  
            System.out.println("\n*================================================");
            System.out.println("*");
            System.out.println("*          EXPERIMENT - LPLS_EQUATION");
            System.out.println("*");
            System.out.println("*================================================\n");
    
            System.out.println("Parameter file path: " + CmdArgs.paramFilePath + "\n");
            System.out.println("Specification version of library 'agentsimulator': " + LPLSEqnSimulator.class.getPackage().getSpecificationVersion());
            System.out.println("Liquidity: " + params.liquidity + "\n");
            System.out.println("Random seed: " + seed);
            System.out.println("Number of runs per experiment: " + params.nRuns);
            System.out.println("Number of ticks per run: " + params.nTicks);
            System.out.println("Number of assets: " + params.nAssets);
            System.out.println("Number of agents*: " + params.nAgents);
            System.out.println("Number of value investors: " + params.nValueInvestors);
            System.out.println("Number of trend followers" + params.nTrendFollowers);
            System.out.println("Number of long-short investors: " + params.nLongShortInvestors);
            System.out.println("*If non-zero, then scale the number of agent types proportionally. Otherwise use number of agents of a particular type as-is\n");
        }

        /**====================================================================
         * 
         *      SET OF SIMULATION EXPERIMENTS
         *      -----------------------------
         *      
         *      In a set of simulation experiments, we can change specific
         *      parameters to investigate a system's response.
         *      
         **====================================================================*/
        
        for (int e = 0; e < 1; e++) {
            
            logger.debug("EXPERIMENT #{} - executing...\n", e + 1);

            // Uncomment, to produce the same random number sequences for each experiment (but a different sequence for each run)
         // TODO NEW RANDOMGENERATORPOOL    LPLSRandomGeneratorPool.resetGeneratorPool(LPLSRandomGeneratorPool.getSeed());
            
            /*
             * Set up the current experiment here
             */
            
            // Code here...
        
            /**====================================================================
             * 
             *      SIMULATION EXPERIMENT
             *      ---------------------
             *      
             *      TODO
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
             *      _experiment_ you need to set the random seed above to a 
             *      fixed value. Uncomment the following two lines above:
             *         - LPLSRandomGeneratorPool.getInstance(params, seed);
             *         - LPLSRandomGeneratorPool.resetGeneratorPool(LPLSRandomGeneratorPool.getSeed());
             *      
             **====================================================================*/
            
                
            for (int iRun = 0; iRun < params.nRuns; iRun++) {
                logger.trace("LPLSEqnSimulator: Starting RUN #{}", iRun + 1);
    
                simulator = new LPLSEqnSimulator(params);   // TODO create a method to initialize LPLSEqnSimulator
            
            
                /**====================================================================
                 * 
                 *      SIMULATION RUN
                 *      --------------
                 *      
                 *      A simulation run executes the simulation model over
                 *      nTicks time steps.
                 *      
                 *      The simulator code initialises and runs the model, and 
                 *      stores the results in the corresponding data structures.
                 *      
                 **====================================================================*/
                
                
                timer.start();
                
                simulator.run();
                            
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
                

                logger.trace("Output of results for RUN #{}...\n", iRun + 1);
                
                tscResults.removeAllSeries();
                
               
                tscResults.populateSeries(iRun + 1, "log_price", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.LOG_PRICES), 1);
                tscResults.populateSeries(iRun + 1, "log_ref_value", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.LOG_REFVALUES), 1);
                tscResults.populateSeries(iRun + 1, "volume", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.VOLUME), 1);
                tscResults.populateSeries(iRun + 1, "trades", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.TOTAL_TRADES), 1);
                tscResults.populateSeries(iRun + 1, "cash", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.CASH), 1);
                tscResults.populateSeries(iRun + 1, "orders_FUND", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.ORDER_VALUE), 1);
                tscResults.populateSeries(iRun + 1, "orders_TREND", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.ORDER_TREND), 1);
                tscResults.populateSeries(iRun + 1, "orders_LS", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.ORDER_LONGSHORT), 1);
//                tscResults.populateSeries("pl_agents", iRun + 1, Datastore.getResult(DoubleTimeSeriesList.class, LPLSEquationModel.Results.PROFIT_AND_LOSS));
                tscResults.populateSeries(iRun + 1, "paper_pl_agents", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.PAPER_PROFIT_AND_LOSS), 1);
                tscResults.populateSeries(iRun + 1, "realised_pl_agents", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.REALISED_PROFIT_AND_LOSS), 1);
//                tscResults.populateSeries("pl_strategies", iRun + 1, Datastore.getResult(DoubleTimeSeriesList.class, LPLSEquationModel.Results.PROFIT_AND_LOSS_STRATEGY));
//                tscResults.populateSeries(iRun + 1, "paper_pl_strategies", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.PAPER_PROFIT_AND_LOSS_STRATEGY), 1);
//                tscResults.populateSeries(iRun + 1, "realised_pl_strategies", Datastore.getResult(DoubleTimeSeriesList.class, LPLSEqnModel.Results.REALISED_PROFIT_AND_LOSS_STRATEGY), 1);

                
                
                tscResults.insertSeriesExp("log_price", "price");
                tscResults.insertSeriesExp("log_ref_value", "ref_value");
                tscResults.insertSeriesDifference("log_price", "log_return");
                tscResults.insertSeriesCumulative("orders_FUND", "pos_FUND");
                tscResults.insertSeriesCumulative("orders_TREND", "pos_TREND");
                tscResults.insertSeriesCumulative("orders_LS", "pos_LS");
//                tscResults.insertSeriesCumulative("pl_agents", "cpl_ag");
                tscResults.insertSeriesCumulative("paper_pl_agents", "paper_cpl_ag");
                tscResults.insertSeriesCumulative("realised_pl_agents", "realised_cpl_ag");
//                tscResults.insertSeriesCumulative("pl_strategies", "cpl_st");
                tscResults.insertSeriesCumulative("paper_pl_strategies", "paper_cpl_st");
                tscResults.insertSeriesCumulative("realised_pl_strategies", "realised_cpl_st");
                
                if (logger.isTraceEnabled()) {
                    tscResults.newIndexMap("cash", "1", "1", "MF", "2", "HF", "3", "B");
                    tscResults.setIndexPrefix("price", "a");
                    
                    int FIRST_COLUMN_WIDTH = 32;
                    
                    System.out.println(tscResults.getSubset("price").printDecoratedSeries("PRICE", FIRST_COLUMN_WIDTH, true));
                    System.out.println(tscResults.getSubset("log_return").printDecoratedSeries("LOG RETURN", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("log_ref_value").printDecoratedSeries("LOG REF VALUE", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("trades").printDecoratedSeries("TRADES", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("volume").printDecoratedSeries("VOLUME", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("cash").printDecoratedSeries("CASH", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("orders_FUND").printDecoratedSeries("ORDERS (FUND)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("orders_TREND").printDecoratedSeries("ORDERS (TREND)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("orders_LS").printDecoratedSeries("ORDERS (LS)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("pos_FUND").printDecoratedSeries("POSITION (FUND)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("pos_TREND").printDecoratedSeries("POSITION (TREND)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("pos_LS").printDecoratedSeries("POSITION (LS)", FIRST_COLUMN_WIDTH));
//                    System.out.println(tscResults.getSeriesSet("pl_agents").printDecoratedSeries("P&L (AGENTS)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("paper_pl_agents").printDecoratedSeries("PAPER P&L (AGENTS)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("realised_pl_agents").printDecoratedSeries("REALISED P&L (AGENTS)", FIRST_COLUMN_WIDTH));
//                    System.out.println(tscResults.getSeriesSet("pl_strategies").printDecoratedSeries("P&L (STRATEGIES)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("paper_pl_strategies").printDecoratedSeries("PAPER P&L (STRATEGIES)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("realised_pl_strategies").printDecoratedSeries("REALISED P&L (STRATEGIES)", FIRST_COLUMN_WIDTH));
//                    System.out.println(tscResults.getSeriesSet("cpl_ag").printDecoratedSeries("CUMUL P&L (AGENTS)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("paper_cpl_ag").printDecoratedSeries("PAPER CUMUL P&L (AGENTS)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("realised_cpl_ag").printDecoratedSeries("REALISED CUMUL P&L (AGENTS)", FIRST_COLUMN_WIDTH));
//                    System.out.println(tscResults.getSeriesSet("cpl_st").printDecoratedSeries("CUMUL P&L (STRATEGIES)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("paper_cpl_st").printDecoratedSeries("PAPER CUMUL P&L (STRATEGIES)", FIRST_COLUMN_WIDTH));
                    System.out.println(tscResults.getSubset("realised_cpl_st").printDecoratedSeries("REALISED CUMUL P&L (STRATEGIES)", FIRST_COLUMN_WIDTH));
                }

                

        
        
        
        }
        

        /**
         *      OUTPUT
         */
        
        // Write results to file for R
//        ResultWriterFactory.newCsvWriter("./out/lpls-equation-simulation/list_log_price_timeseries.csv").write(tsLogPricesList);
//        ResultWriterFactory.newCsvWriter("./out/lpls-equation-simulation/list_ref_values_timeseries.csv").write(tsLogRefValuesList);
//        ResultWriterFactory.newCsvWriter("./out/lpls-equation-simulation/list_order_fundamental_timeseries.csv").write(tsOrderFUNDList);
//        ResultWriterFactory.newCsvWriter("./out/lpls-equation-simulation/list_order_trend_timeseries.csv").write(tsOrderTRENDList);
//        ResultWriterFactory.newCsvWriter("./out/lpls-equation-simulation/list_order_long_short_timeseries.csv").write(tsOrderLSList);
////        ResultWriterFactory.newCsvWriter("./out/lpls-equation-simulation/list_price_noise_timeseries.csv").write(tsOrderLSList);
//        ResultWriterFactory.newCsvWriter("./out/lpls-equation-simulation/list_volume_timeseries.csv").write(tsVolumeList);

        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        }
        
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
        LPLSEqnParams params = null;
//        LPLSqnSimpleParamsRandomiser paramsRand = null;

        try {
            params = LPLSEqnParams.readParameters(CmdArgs.paramFilePath);            
//            if (fileNameRandValue != null) paramsRand = LPLSqnSimpleParamsRandomiser.readParameters(fileNameRandValue);
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
        return "Usage: LPLSquationSimple [{-v,--verbose}] {-p,--params} a_filename, [{-o, --output} a_directory]";
    }
}
