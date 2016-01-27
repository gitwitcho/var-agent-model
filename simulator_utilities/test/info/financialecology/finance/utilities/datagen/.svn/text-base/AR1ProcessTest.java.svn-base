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
package info.financialecology.finance.utilities.datagen;

import static org.junit.Assert.*;

import org.junit.Before;
import org.junit.Test;

import cern.colt.list.DoubleArrayList;
import cern.jet.stat.Descriptive;

/**
 * @author Gilbert Peffer
 *
 */
public class AR1ProcessTest {

    /**
     * @throws java.lang.Exception
     */
    @Before
    public void setUp() throws Exception {
    }

    /**
     * Test method for {@link AR1Process#nextDoubles(int)}. Calculates the distributional parameters 
     * and compares them to the theoretical values.
     */
    @Test
    public void nextDoubles_distributional() {
        
        System.out.println();
        System.out.println("VALIDATION TEST: AR(1) process - nextDoubles_distributional");
        System.out.println();
        
        int numData = 10000000;
        int maxLag = 10;
        
        RandomGeneratorPool.configureGeneratorPool(3747);

        double delta = 100;
        double phi = 0.4;
        double sigma = 0.6;
        
        /**
         * Theoretical distribution parameters of the process
         */
        double mean = delta / (1 - phi);
        double var = sigma * sigma / (1 - phi * phi);
        
        DoubleArrayList autocorr = new DoubleArrayList();
        
        for (int lag = 0; lag <= maxLag; lag++)
            autocorr.add(Math.pow(phi, lag));
                
        /**
         * Numerical distribution parameters of the process
         */
        AR1Process ar1 = new AR1Process("ar1", delta, phi, sigma);
        
        DoubleArrayList ar1TimeSeries = ar1.nextDoubles(numData);

        double meanOfSample = Descriptive.mean(ar1TimeSeries);
        double varOfSample = Descriptive.variance(ar1TimeSeries.size(), Descriptive.sum(ar1TimeSeries), 
                                Descriptive.sumOfSquares(ar1TimeSeries));
        
        double diffMean = Math.abs(mean - meanOfSample);
        double diffVar = Math.abs(var - varOfSample);
        
        DoubleArrayList autocorrOfSample = new DoubleArrayList();
        DoubleArrayList diffAutocorrOfSample = new DoubleArrayList();
        
        for (int lag = 0; lag <= maxLag; lag++) {
            autocorrOfSample.add(Descriptive.autoCorrelation(ar1TimeSeries, lag, meanOfSample, varOfSample));
            diffAutocorrOfSample.add(autocorr.get(lag) - autocorrOfSample.get(lag));
        }
        
        /**
         * Printing values for visual inspection
         */
        System.out.println("Sample mean: " + meanOfSample + " - Expected: " + mean + " - Diff: " + diffMean);
        System.out.println("Sample var: " + varOfSample + " - Expected: " + var + " - Diff: " + diffVar);
        
        for (int lag = 0; lag <= maxLag; lag++)
            System.out.println("Sample autocorr for lag " + lag + ": " + autocorrOfSample.get(lag) + 
                    " - Expected: " + autocorr.get(lag) + " - Diff: " + diffAutocorrOfSample.get(lag));

        assertEquals("The difference between the mean of the sample and the mean of the AR(1) "
                + "process should be approx. 1.371783E-4", 1.371783E-4, diffMean, 1E-10);
        assertEquals("The difference between the variance of the sample and the variance of the AR(1) "
                + "process should be approx. 6.602723E-4", 6.602723E-4, diffVar, 1E-10);
        assertEquals("The difference between the lag 0 autocorrelation of the sample and that of the AR(1) "
                + "process should be approx. -4.675013E-10", -4.675013E-10, diffAutocorrOfSample.get(0), 1E-16);
        assertEquals("The difference between the lag 1 autocorrelation of the sample and that of the AR(1) "
                + "process should be approx. 3.980385E-5", 3.980385E-5, diffAutocorrOfSample.get(1), 1E-11);
        assertEquals("The difference between the lag 2 autocorrelation of the sample and that of the AR(1) "
                + "process should be approx. -1.043077E-4", -1.043077E-4, diffAutocorrOfSample.get(2), 1E-10);
        assertEquals("The difference between the lag 3 autocorrelation of the sample and that of the AR(1) "
                + "process should be approx. 4.907050E-5", 4.907050E-5, diffAutocorrOfSample.get(3), 1E-11);
        assertEquals("The difference between the lag 4 autocorrelation of the sample and that of the AR(1) "
                + "process should be approx. 8.288177E-5", 8.288177E-5, diffAutocorrOfSample.get(4), 1E-11);
        assertEquals("The difference between the lag 5 autocorrelation of the sample and that of the AR(1) "
                + "process should be approx. 9.694461E-5", 9.694461E-5, diffAutocorrOfSample.get(5), 1E-11);
        assertEquals("The difference between the lag 6 autocorrelation of the sample and that of the AR(1) "
                + "process should be approx. -1.841221E-4", -1.841221E-4, diffAutocorrOfSample.get(6), 1E-10);
        assertEquals("The difference between the lag 7 autocorrelation of the sample and that of the AR(1) "
                + "process should be approx. -4.238065E-4", -4.238065E-4, diffAutocorrOfSample.get(7), 1E-10);
        assertEquals("The difference between the lag 8 autocorrelation of the sample and that of the AR(1) "
                + "process should be approx. 7.055056E-5", 7.055056E-5, diffAutocorrOfSample.get(8), 1E-11);
        assertEquals("The difference between the lag 9 autocorrelation of the sample and that of the AR(1) "
                + "process should be approx. 2.203333E-4", 2.203333E-4, diffAutocorrOfSample.get(9), 1E-10);
        assertEquals("The difference between the lag 10 autocorrelation of the sample and that of the AR(1) "
                + "process should be approx. 3.663939E-4", 3.663939E-4, diffAutocorrOfSample.get(10), 1E-10);

        System.out.println();
        System.out.println("Success");
    }

}
