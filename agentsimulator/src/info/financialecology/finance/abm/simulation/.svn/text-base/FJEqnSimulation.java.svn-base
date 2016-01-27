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

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import org.slf4j.LoggerFactory;

import info.financialecology.finance.abm.model.FJEqnModel;
import info.financialecology.finance.abm.model.FJEqnSimulator;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.datastruct.Datastore;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.FormattedDoubleArrayList;
import info.financialecology.finance.utilities.datastruct.VersatileDataTable;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeries;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeriesCollection;
import info.financialecology.finance.utilities.output.ResultWriterFactory;
import jargs.gnu.CmdLineParser;

import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.HashMap;
import java.util.Locale;

/**
 * ### WARNING ### This class contains UNRESOLVED BUGS
 * <p>
 * FJEquation builds on FJEquationSimple, the first and simplest implementation 
 * of the Farmer and Joshi (2002) market model with a single asset. 
 * <p>
 * In this implementation, we have divided the simulation code into three parts: 
 * the actual simulation (this class), the simulator where we set up the 
 * simulation, and the model where we do the computations. Otherwise, the
 * code is exactly the same than FJEquationSimpleSimulation.
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
public class FJEqnSimulation {

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
        static FJEqnParams params;         // model parameters
//        static FJEquationSimpleParamsRandomiser paramsRand;
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
     * <code>./input/fj_equation_test123.xml</code>
     * @param -o relative or absolute path to output files folder. If omitted
     * the default is the current directory
     * @param -v verbose output (options: trace, debug, detail, summary, none (the default))
     * @param Example <code>java -jar FJEqnSimulation.jar -v summary -p ./input/fj_equation_test123.xml 
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
        FJEqnParams params = CmdArgs.params;
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
         *      SET UP DATA COLLECTIONS
         *      -----------------------
         */
        
        VersatileTimeSeries.StaticInternalParams.setTimePeriodFormat("actual");      // global format for time in time series
        VersatileDataTable.StaticInternalParams.setColumnWidth(10);            //TODO (?) global column width (???) of output table

        VersatileTimeSeriesCollection tscResults = new VersatileTimeSeriesCollection("time series results");      // collection for time series type results 
        VersatileDataTable cdsVolatilities = new VersatileDataTable("volatilities");                  // volatilities - run-level summary statistics
        VersatileDataTable cdsKurtosis     = new VersatileDataTable("kurtosis");                      // kurtosis (fat tails) - run-level summary statistics
        
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
                    FJEqnSimulation.class.getPackage().getSpecificationVersion());
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

        for (int iRun = 0; iRun < params.nRuns; iRun++) {
            logger.trace("Starting simulation - FJEqnSimulator");

            FJEqnSimulator simulator = new FJEqnSimulator(params);
            
            
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
            
            
            /*
             * Retrieve results from the datastore
             */
            DoubleTimeSeries tsLogPrices = Datastore.getResult(DoubleTimeSeries.class, FJEqnModel.Results.LOG_PRICES);
            DoubleTimeSeries tsLogRefValues = Datastore.getResult(DoubleTimeSeries.class, FJEqnModel.Results.LOG_REFVALUES);
            DoubleTimeSeries tsOrderValueInv = Datastore.getResult(DoubleTimeSeries.class, FJEqnModel.Results.ORDER_FUND);
            DoubleTimeSeries tsOrderTrend = Datastore.getResult(DoubleTimeSeries.class, FJEqnModel.Results.ORDER_TECH);
            DoubleTimeSeries tsVolume = Datastore.getResult(DoubleTimeSeries.class, FJEqnModel.Results.VOLUME);
            
            tsLogPrices.setId("log_p_" + (iRun + 1));
            tsLogRefValues.setId("log_v_" + (iRun + 1));
            tsOrderValueInv.setId("order_v_" + (iRun + 1));
            tsOrderTrend.setId("order_t__" + (iRun + 1));
            tsVolume.setId("volume_" + (iRun + 1));

            /*
             * Populate time series results collection
             */
            tscResults.removeAllSeries();   // clean time series collection
            tscResults.populateSeries(iRun + 1, "log_price", tsLogPrices);
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
        FJEqnParams params = null;
//        FJEqnSimpleParamsRandomiser paramsRand = null;

        try {
            params = FJEqnParams.readParameters(CmdArgs.paramFilePath);            
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
