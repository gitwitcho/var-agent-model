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
import info.financialecology.finance.utilities.datagen.SinusDataGenerator;
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
 * Possible validation tests for SinusDataGenerator:
 * 
 *    - The process must be periodic: sin(t)=sin(t+lambda) for all t
 *    - Values cannot exceed mean+amplitude, mean-amplitude
 *    - The process obtained with shift=0 and shift=n*lambda (for any integer n) must be the same
 *    - If lambda is divisible by 4, the number of points where the process takes the value mean+amplitude (maximum value) must be equal to the number of periods (integer part of nTicks/lambda). Same with the minimum value.
 *    - If nTicks is divisible by lambda (so that there is an integer number of periods), the mean of the process must be equal to 'mean'.
 *    
 * @author llacay
 *
 */

public class TestSinusDataGenerator {

    protected static final String TEST_ID = "SinusDataGenerator"; 

    /**
     * The main routine testing the sinus generator SinusDataGenerator.
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
        TestSinusDataGeneratorParams params = null;

        try {
            params = TestSinusDataGeneratorParams.readParameters(fileName);
        } catch (Throwable e) {
            logger.error(e.getMessage());
            System.exit(0);
        }
        
        params.validate();
        
        /**
         * Copy distribution parameters into a single array 
         */
        DoubleArrayList means = params.getValidatedDoubleSequence(TestSinusDataGeneratorParams.Sequence.MEAN);
        DoubleArrayList amplitudes = params.getValidatedDoubleSequence(TestSinusDataGeneratorParams.Sequence.AMPLITUDE);
        DoubleArrayList shifts = params.getValidatedDoubleSequence(TestSinusDataGeneratorParams.Sequence.SHIFT);
        DoubleArrayList lambdas = params.getValidatedDoubleSequence(TestSinusDataGeneratorParams.Sequence.LAMBDA);
        ArrayList<Double> distParams = new ArrayList<Double>();
        
        for (int i = 0; i < shifts.size(); i++) {
            distParams.add(means.get(i));
            distParams.add(amplitudes.get(i));
            distParams.add(shifts.get(i));
            distParams.add(lambdas.get(i));
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
        VersatileTimeSeries.StaticInternalParams.setOutputTail(10);
        int FIRST_COLUMN_WIDTH = 10;
        String baseName = "SINUS";

        /**
         * Setup
         */
        SinusDataGenerator gen = new SinusDataGenerator(distParams.toArray(new Double[1]));
        
        int dim = (int) Math.floor(0.1 + distParams.size() / 4);  // 4 is the number of parameters of the sinus generator 
                
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
//           	 	dtsl_2.get(j).add(increments.get(j));
            }
        	
        }
        
        
        /**
         * Output - Text
         */
        atc_1.populateSeries(1, "sin", dtsl_1, 0);
//        atc_2.populateSeries(1, "step", dtsl_2, 0);
        
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
