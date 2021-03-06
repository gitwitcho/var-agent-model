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

package info.financialecology.finance.utilities.test;

import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.ArrayList;
import java.util.Locale;

import info.financialecology.finance.utilities.CmdLineProcessor;
import info.financialecology.finance.utilities.datagen.RandomDistDataGenerator;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool.DistributionType;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.datastruct.FormattedDoubleArrayList;
import info.financialecology.finance.utilities.datastruct.VersatileChart;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeries;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeriesCollection;

import org.slf4j.LoggerFactory;

import cern.colt.list.DoubleArrayList;
import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;


/**
 * A simple test battery for this class.
 * 
 *    
 * @author Gilbert Peffer
 *
 */

/**
 * Possible validation tests for RandomDistDataGenerator:
 * 
 * UNIFORM DISTRIBUTION
 *   - If Param_1=Param_2, then the obtained series must be constant and equal to the parameters Param_1 or Param_2 
 *   - The mean of the obtained series must be equal to (Param_1 + Param_2)/2
 *   - The variance of the obtained series must be equal to (Param_2 - Param_1)^2/12
 *   - The skewness of the obtained series must be equal to 0
 *   - The excess kurtosis of the obtained series must be equal to -6/5
 *   - The maximum and minimum of the obtained series cannot be greater than Param_2 or Param_1
 *   
 * NORMAL DISTRIBUTION
 *   - If the standard deviation is 0, the obtained series must be constant and equal to the parameter 'mean'
 *   - The mean of the obtained series must be equal to the parameter 'mean'
 *   - The standard deviation of the obtained series must be equal to the parameter 'standard deviation'
 *   - The skewness of the obtained series must be equal to 0
 *   - The excess kurtosis of the obtained series must be equal to 0
 *   - The number of values within [mean-stdev, mean+stdev] should be close to 68%
 *   - The number of values within [mean-2*stdev, mean+2*stdev] should be close to 95.4%
 * 
 * @author llacay
 *
 */

public class TestRandomDistDataGenerator {

    protected static final String TEST_ID = "RandomDistDataGenerator"; 

    /**
     * The main routine testing the random generator RandomDistDataGenerator.
     * Sets up the logging facility and the data storage. It also
     * assembles the result time series and writes them to a file.
     * 
     * @param args command line arguments. 
     * @param -p relative path and name of the model parameter file. Example: 
     * <code>./input/lpls_equation_test123.xml</code>
     * @param -v verbose output (options: trace, debug, detail, summary, none (the default))
     * @param Example <code>java -jar LPLSEqnSimulation.jar -v summary -p ./input/lpls_equation_test123.xml 
     * </code>
     */
    public static void main(String[] args) {

        Logger root = (Logger)LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        root.setLevel(Level.ERROR); // TODO create a program argument to switch to trace
        Logger logger = (Logger)LoggerFactory.getLogger("main");
        

        System.out.println("\nTEST: " + TEST_ID);
        System.out.println("========================\n");
        System.out.println("This is a simple test battery for this class.\n");

        logger.trace("Setting up test for class '{}'\n", TEST_ID);
        
        /*
         * Read parameters from file
         * 
         * To write a new parameter file template, uncomment the following two lines
         *      TestBrownianProcessParams.writeParamDefinition("param_template.xml");
         *      System.exit(0);
         */

        String fileName = CmdLineProcessor.process(args);     // process command line arguments
        TestRandomDistDataGeneratorParams params = null;

        try {
            params = TestRandomDistDataGeneratorParams.readParameters(fileName);
        } catch (Throwable e) {
            logger.error(e.getMessage());
            System.exit(0);
        }
        
        params.validate();
        
        /**
         * Copy distribution parameters into a single array 
         */
        DoubleArrayList means = params.getValidatedDoubleSequence(TestRandomDistDataGeneratorParams.Sequence.DIST_PARAM_1);
        DoubleArrayList stdevs = params.getValidatedDoubleSequence(TestRandomDistDataGeneratorParams.Sequence.DIST_PARAM_2);
        ArrayList<Double> distParams = new ArrayList<Double>();
        
        for (int i = 0; i < means.size(); i++) {
            distParams.add(means.get(i));
            distParams.add(stdevs.get(i));
        }

        // Number formatter for the output
        DecimalFormat df = new DecimalFormat("0.00000", new DecimalFormatSymbols(Locale.UK));
        DoubleTimeSeries.setFormatter(df);
        FormattedDoubleArrayList.setFormatter(df);

        /**
         * Data storage and formatting
         */
        DoubleTimeSeries dts = new DoubleTimeSeries();
        DoubleTimeSeriesList dtsl_1 = new DoubleTimeSeriesList();
        DoubleTimeSeriesList dtsl_2 = new DoubleTimeSeriesList();
        VersatileTimeSeriesCollection atc_1 = new VersatileTimeSeriesCollection("results");        
        VersatileTimeSeriesCollection atc_2 = new VersatileTimeSeriesCollection("results");
        VersatileTimeSeries.StaticInternalParams.setTimePeriodFormat("tick");
        VersatileTimeSeries.StaticInternalParams.setTimePeriod(VersatileTimeSeries.Period.DAY);
        VersatileTimeSeries.StaticInternalParams.setOutputHead(25);
        VersatileTimeSeries.StaticInternalParams.setOutputTail(5);
        int FIRST_COLUMN_WIDTH = 10;
        String baseName = "VALUE";

        /**
         * Setup
         */
        DistributionType distType = DistributionType.NORMAL;
        RandomGeneratorPool.configureGeneratorPool();
        RandomDistDataGenerator gen = new RandomDistDataGenerator(baseName, distType, distParams.toArray(new Double[1]));
        
        int numDistParams = distType.getNumParams();
        int dim = (int) Math.floor(0.1 + distParams.size() / numDistParams); 
                
        for (int i = 0; i < dim; i++) {
            String tsName = baseName;
            if (dim > 1) tsName += "_" + i;
            dtsl_1.add(new DoubleTimeSeries(tsName));
            dtsl_2.add(new DoubleTimeSeries(tsName));
        }
        
        /**
         * Run
         */
        DoubleArrayList vec;
//        DoubleArrayList increments;
        
        for (int i = 0; i < params.nTicks; i++) {
            vec = gen.nextDoubleVector();
//            increments = gen.nextDoubleVectorIncrements();
            
            for (int j = 0; j < dim; j++) {
                dtsl_1.get(j).add(vec.get(j));
//                dtsl_2.get(j).add(increments.get(j));
            }
        }
        
        /**
         * Output - Text
         */
        atc_1.populateSeries(1, baseName, dtsl_1, 0);
//        atc_2.populateSeries(1, "brownian", dtsl_2, 0);
        
        System.out.println(atc_1.printDecoratedSeries(baseName, FIRST_COLUMN_WIDTH, true));
//        System.out.println(atc_2.printDecoratedSeries(baseName, FIRST_COLUMN_WIDTH, true));
        
        /**
         * Output - Graph
         */
        VersatileChart charts_1 = new VersatileChart();
        charts_1.getInternalParms().autoRange = true;
        charts_1.getInternalParms().autoRangePadding = 0;
        charts_1.getInternalParms().ticks = true;

        charts_1.draw(atc_1);
        
//        VersatileChart charts_2 = new VersatileChart();
//        charts_2.getInternalParms().autoRange = true;
//        charts_2.getInternalParms().autoRangePadding = 0;
//        charts_2.getInternalParms().ticks = true;
//
//        charts_2.draw(atc_2);
    }
    
}
