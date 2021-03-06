/*
 * Copyright (c) 2011-2014 Gilbert Peffer, Barbara Llacay
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
package info.financialecology.finance.utilities.test;

import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.ArrayList;
import java.util.Locale;

import info.financialecology.finance.utilities.CmdLineProcessor;
import info.financialecology.finance.utilities.datagen.BrownianProcess;
import info.financialecology.finance.utilities.datagen.OverlayDataGenerator;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool;
import info.financialecology.finance.utilities.datagen.BrownianProcess.Type;
import info.financialecology.finance.utilities.datagen.OverlayDataGenerator.GeneratorType;
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
 * Possible validation tests for OverlayDistDataGenerator:
 * 
 *   - If distType=UNIFORM and Param_5 (lower bound) = Param_6 (upper bound) (then the random distribution is constant), 
 *     the obtained series is equal to the deterministic process (plus the shift given by Param_5 (lower bound))
 *   - If distType=NORMAL and Param_6=0 (then the random distribution is constant), the obtained series is equal to the
 *     deterministic process (plus the shift given by Param_5 (mean))
 *   - If detType=SINUS and distType=UNIFORM and nTicks is divisible by Param_4 (lambda) (so that there is an integer number of periods), 
 *     the mean of the process must be equal to Param_1 (shift) + (Param_5 (lower bound) + Param_6 (upper bound))/2.
 *   - If detType=SINUS and distType=NORMAL and nTicks is divisible by Param_4 (lambda) (so that there is an integer number of periods), 
 *     the mean of the process must be equal to Param_1 (shift) + Param_5 (mean). 
 *     
 *
 * @author Barbara Llacay, Gilbert Peffer
 *
 */
public class TestOverlayDataGenerator {

    protected static final String TEST_ID = "OverlayDataGenerator"; 

    public static void main(String[] args) {

        Logger root = (Logger)LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        root.setLevel(Level.ERROR); // TODO create a program argument to switch to trace
        Logger logger = (Logger)LoggerFactory.getLogger("main");
        

        System.out.println("\n#############################");
        System.out.println("#  TEST: " + TEST_ID);
        System.out.println("#############################\n");

        logger.trace("Setting up test for class '{}'\n", TEST_ID);
        
        int numTicks = 1000;
        
        double initialValue = 100;  // the mean of the sine or step generator will be set to this value 

        // Sine generator
        double amplitude = 20;      // amplitude of the sine function
        double shift = 0;           // left-shift of the sine function
        double lambda = 200;        // wave-length of the sine function
        
        //Step generator
        double stepHeight = amplitude;
        double stepWidth = lambda / 4;
        double valleyWidth = lambda / 2;
        
        // Map step generator to sine-likeness
        double initialValueStep = initialValue - stepHeight;
        stepHeight *= 2;
        
        double mu = 0;              // drift of the Brownian process
        double sigma = 0;           // volatility of the Brownian process

        String baseName = "VALUE";

        // Number formatter for the output
        DecimalFormat df = new DecimalFormat("0.00000", new DecimalFormatSymbols(Locale.UK));
        DoubleTimeSeries.setFormatter(df);
        FormattedDoubleArrayList.setFormatter(df);

        // Data storage and formatting
        VersatileTimeSeries.StaticInternalParams.setTimePeriodFormat("tick");
        VersatileTimeSeries.StaticInternalParams.setTimePeriod(VersatileTimeSeries.Period.DAY);
        VersatileTimeSeries.StaticInternalParams.setOutputHead(25);
        VersatileTimeSeries.StaticInternalParams.setOutputTail(10);
        

        /**
         * SETUP
         */
        RandomGeneratorPool.configureGeneratorPool(5344);

        
        /**
         * RUN 1 - Pure sine generator
         */
        OverlayDataGenerator gen = new OverlayDataGenerator(baseName + "_pure-sine", GeneratorType.SINUS, 
                GeneratorType.ARITHMETIC_BROWNIAN_PROCESS, initialValue, amplitude, shift, lambda,
                mu, sigma);
        
        DoubleTimeSeries dts_pure_sine = new DoubleTimeSeries("Pure sine");
        
        for (int i = 0; i < numTicks; i++)
            dts_pure_sine.add(gen.nextDouble());
        
        
        /**
         * RUN 2 - Multiple sine generators
         */
        gen = new OverlayDataGenerator(baseName + "_multi-sine", GeneratorType.SINUS, 
                GeneratorType.GEOMETRIC_BROWNIAN_PROCESS, 
                initialValue, amplitude, shift, lambda, mu, sigma,
                80.0, amplitude, shift, lambda, mu, sigma,
                initialValue, 30.0, shift, lambda, mu, sigma,
                initialValue, amplitude, -40.0, lambda, mu, sigma,
                initialValue, amplitude, shift, 200.0, mu, sigma);
        
        DoubleTimeSeriesList dtsl_multi_sine = new DoubleTimeSeriesList();
        DoubleArrayList nextSineValues = new DoubleArrayList();
        
        for (int s = 0; s < gen.numberOfDatastreams(); s++)
            dtsl_multi_sine.add(new DoubleTimeSeries("multi-sine_" + s));
        
        for (int i = 0; i < numTicks; i++) {
            nextSineValues = gen.nextDoubleVector();
            
            for (int s = 0; s < gen.numberOfDatastreams(); s++)
                dtsl_multi_sine.get(s).add(nextSineValues.get(s));            
        }

        
        /**
         * RUN 3 - Pure step generator
         */
        gen = new OverlayDataGenerator(baseName + "_pure-step", GeneratorType.STEP, 
                GeneratorType.UNIFORM, initialValueStep, stepHeight, stepWidth, valleyWidth,
                mu, sigma);
        
        DoubleTimeSeries dts_pure_step = new DoubleTimeSeries("Pure step");
        
        for (int i = 0; i < numTicks; i++)
            dts_pure_step.add(gen.nextDouble());
        
        
        /**
         * RUN 4 - Multiple step generators
         */
        gen = new OverlayDataGenerator(baseName, GeneratorType.STEP, 
                GeneratorType.NORMAL, 
                initialValueStep, stepHeight, stepWidth, valleyWidth, mu, sigma,
                100.0, stepHeight, stepWidth, valleyWidth, mu, sigma,
                initialValueStep, 30.0 * 2, stepWidth, valleyWidth, mu, sigma,
                initialValueStep, stepHeight, 200.0, valleyWidth, mu, sigma,
                initialValueStep, stepHeight, stepWidth, 100.0, mu, sigma);
        
        DoubleTimeSeriesList dtsl_multi_step = new DoubleTimeSeriesList();
        DoubleArrayList nextStepValues = new DoubleArrayList();
        
        for (int s = 0; s < gen.numberOfDatastreams(); s++)
            dtsl_multi_step.add(new DoubleTimeSeries("multi-step_" + s));
        
        for (int i = 0; i < numTicks; i++) {
            nextStepValues = gen.nextDoubleVector();
            
            for (int s = 0; s < gen.numberOfDatastreams(); s++)
                dtsl_multi_step.get(s).add(nextStepValues.get(s));            
        }

        
        /**
         * RUN 5 - Step generator with uniform random number overlay
         */
        double lower = -10;
        double upper = 0;
        
        gen = new OverlayDataGenerator(baseName + "_step-plus-uniform", GeneratorType.STEP, 
                GeneratorType.UNIFORM, initialValueStep, stepHeight, stepWidth, valleyWidth,
                lower, upper);
        
        DoubleTimeSeries dts_step_plus_uniform = new DoubleTimeSeries("Step plus uniform");
        
        for (int i = 0; i < numTicks; i++)
            dts_step_plus_uniform.add(gen.nextDouble());

        
        /**
         * RUN 6 - Step generator with normal random number overlay
         */
        mu = 10;
        sigma = 5;
        
        gen = new OverlayDataGenerator(baseName + "_step-plus-normal", GeneratorType.STEP, 
                GeneratorType.NORMAL, initialValueStep, stepHeight, stepWidth, valleyWidth,
                mu, sigma);
        
        DoubleTimeSeries dts_step_plus_normal = new DoubleTimeSeries("Step plus normal");
        
        for (int i = 0; i < numTicks; i++)
            dts_step_plus_normal.add(gen.nextDouble());

        
        /**
         * RUN 7 - Step generator with arithmetic Brownian process overlay
         */
        mu = 0 / 250;
        sigma = 10 / Math.sqrt(250);
        
        RandomGeneratorPool.configureGeneratorPool(4637);

        gen = new OverlayDataGenerator(baseName + "_step-plus-abp", GeneratorType.STEP, 
                GeneratorType.ARITHMETIC_BROWNIAN_PROCESS, initialValue, stepHeight, stepWidth, valleyWidth,
                mu, sigma);
        
        DoubleTimeSeries dts_step_plus_abp = new DoubleTimeSeries("Step plus arithmetic Brownian process");
        
        for (int i = 0; i < numTicks; i++)
            dts_step_plus_abp.add(gen.nextDouble());

        
        /**
         * RUN 8 - Step generator with geometric Brownian process overlay
         */
        mu = 0;
        sigma = 0.1 / Math.sqrt(250);
        
        RandomGeneratorPool.configureGeneratorPool(4637);

        gen = new OverlayDataGenerator(baseName + "_step-plus-gbp", GeneratorType.STEP, 
                GeneratorType.GEOMETRIC_BROWNIAN_PROCESS, initialValue, stepHeight, stepWidth, valleyWidth,
                mu, sigma);
        
        DoubleTimeSeries dts_step_plus_gbp = new DoubleTimeSeries("Step plus geometric Brownian process");
        
        for (int i = 0; i < numTicks; i++)
            dts_step_plus_gbp.add(gen.nextDouble());

        
        /**
         * RUN 9 - Comparing arithmetic and geometric Brownian process
         */
        int numTicksComp = 1000;
        double mu_abp = 0;
        double mu_gbp = 0;
        double sigma_abp = 10 / Math.sqrt(250);
        double sigma_gbp = 0.1 / Math.sqrt(250);
        
        RandomGeneratorPool.configureGeneratorPool(4637);
        OverlayDataGenerator gen_abp = new OverlayDataGenerator(baseName + "_abp_comp", GeneratorType.SINUS, 
                GeneratorType.ARITHMETIC_BROWNIAN_PROCESS, initialValue, 0.0, shift, lambda,
                mu_abp, sigma_abp);
        
        RandomGeneratorPool.configureGeneratorPool(4637);
        OverlayDataGenerator gen_gbp = new OverlayDataGenerator(baseName + "_gbp_comp", GeneratorType.SINUS, 
                GeneratorType.GEOMETRIC_BROWNIAN_PROCESS, initialValue, 0.0, shift, lambda,
                mu_gbp, sigma_gbp);

        DoubleTimeSeries dts_comp_abp = new DoubleTimeSeries("ABP");
        DoubleTimeSeries dts_comp_gbp = new DoubleTimeSeries("GBP");
        
        dts_comp_abp.add(initialValue);
        dts_comp_gbp.add(initialValue);
        
        for (int i = 1; i < numTicksComp; i++) {
            dts_comp_abp.add(gen_abp.nextDouble());
            dts_comp_gbp.add(gen_gbp.nextDouble());
        }
        

        /**
         * OUTPUT - Text
         */
        System.out.println("RUN 1 - Pure sine generator");
        System.out.println("===========================\n");
        System.out.println(VersatileTimeSeries.printDecorated(dts_pure_sine));
        
        System.out.println("RUN 2 - Multiple sine generators");
        System.out.println("===========================\n");
        System.out.println(VersatileTimeSeriesCollection.printDecorated(dtsl_multi_sine));
        
        System.out.println("RUN 3 - Pure step generator");
        System.out.println("===========================\n");
        System.out.println(VersatileTimeSeries.printDecorated(dts_pure_step));
        
        System.out.println("RUN 4 - Multiple step generators");
        System.out.println("===========================\n");
        System.out.println(VersatileTimeSeriesCollection.printDecorated(dtsl_multi_step));
        
        System.out.println("RUN 5 - Step generator with uniform random number overlay");
        System.out.println("===========================\n");
        System.out.println(VersatileTimeSeries.printDecorated(dts_step_plus_uniform));
        
        System.out.println("RUN 6 - Step generator with normal random number overlay");
        System.out.println("===========================\n");
        System.out.println(VersatileTimeSeries.printDecorated(dts_step_plus_normal));
        
        System.out.println("RUN 7 - Step generator with arithmetic Brownian process overlay");
        System.out.println("===========================\n");
        System.out.println(VersatileTimeSeries.printDecorated(dts_step_plus_abp));
        
        System.out.println("RUN 8 - Step generator with geometric Brownian process overlay");
        System.out.println("===========================\n");
        System.out.println(VersatileTimeSeries.printDecorated(dts_step_plus_gbp));
        
        System.out.println("RUN 9 - Comparing arithmetic and geometric Brownian processes");
        System.out.println("=========================================================\n");
        System.out.println(VersatileTimeSeries.printDecorated(dts_comp_abp));
        System.out.println(VersatileTimeSeries.printDecorated(dts_comp_gbp));
        

        /**
         * OUTPUT - Graphs
         */
        VersatileChart charts = new VersatileChart();
        charts.getInternalParms().autoRange = true;
        charts.getInternalParms().autoRangePadding = 0;
        charts.getInternalParms().ticks = true;

        // RUN 1 - Pure sine generator
        charts.draw(new VersatileTimeSeries("Pure sine", dts_pure_sine));

        // RUN 2 - Multiple sine generators
        charts.draw(new VersatileTimeSeriesCollection("Multi sine", dtsl_multi_sine));

        // RUN 3 - Pure step generator
        charts.draw(new VersatileTimeSeries("Pure step", dts_pure_step));

        // RUN 4 - Multiple sine generators
        charts.draw(new VersatileTimeSeriesCollection("Multi step", dtsl_multi_step));

        // RUN 5 - Step generator with uniform random number overlay
        charts.draw(new VersatileTimeSeries("Step plus uniform", dts_step_plus_uniform),
                    new VersatileTimeSeries("Pure step", dts_pure_step));

        // RUN 6 - Step generator with normal random number overlay
        charts.draw(new VersatileTimeSeries("Step plus normal", dts_step_plus_normal),
                    new VersatileTimeSeries("Pure step", dts_pure_step));

        // RUN 7 - Step generator with arithmetic Brownian process overlay
        charts.draw(new VersatileTimeSeries("Step plus arithmetic Brownian process", dts_step_plus_abp),
                    new VersatileTimeSeries("Pure step", dtsl_multi_step.get(1)));

        // RUN 8 - Step generator with geometric Brownian process overlay
        charts.draw(new VersatileTimeSeries("Step plus geometric Brownian process", dts_step_plus_gbp),
                    new VersatileTimeSeries("Pure step", dtsl_multi_step.get(1)));

        // RUN 9 - Comparing arithmetic and geometric Brownian processes
        charts.draw(new VersatileTimeSeries("ABP", dts_comp_abp), new VersatileTimeSeries("GBP", dts_comp_gbp));

    }
    
}
