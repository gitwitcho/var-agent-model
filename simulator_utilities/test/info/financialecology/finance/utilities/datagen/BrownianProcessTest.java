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
import info.financialecology.finance.utilities.datagen.BrownianProcess.Type;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.VersatileChart;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeries;

import org.junit.Before;
import org.junit.Test;

import cern.colt.list.DoubleArrayList;
import cern.jet.stat.Descriptive;

/**
 * @author Gilbert Peffer
 *
 */
public class BrownianProcessTest {

    /**
     * @throws java.lang.Exception
     */
    @Before
    public void setUp() throws Exception {
    }

    @Test
    public void nextDouble_geometric_distributional() {

        System.out.println();
        System.out.println("VALIDATION TEST: Geometric Brownian process - nextDoubles_distributional");
        System.out.println();
        
        int numData = 50000;
        int maxLag = 10;
        
        double init_value = 100.0;
        double mu = 0.001;
        double sigma = 0.1 / Math.sqrt(252);
        
        DoubleArrayList data = new DoubleArrayList();
        
        RandomGeneratorPool.configureGeneratorPool(364);
        
        BrownianProcess p = new BrownianProcess("geometric brownian", Type.GEOMETRIC, init_value, mu, sigma);
        
        double lastValue = init_value;
        double nextValue;

        // Computing the relative values
        for (int i = 0; i < numData; i++) {
            nextValue = p.nextDouble();
            data.add( ( nextValue / lastValue ) - 1 );
            lastValue = nextValue;
        }
        
        double meanOfSample = Descriptive.mean(data);
        double varOfSample = Descriptive.variance(data.size(), Descriptive.sum(data), 
                                Descriptive.sumOfSquares(data));
        
        double diffMean = Math.abs(mu - meanOfSample);
        double diffVar = Math.abs(sigma * sigma - varOfSample);

        DoubleArrayList autocorrOfSample = new DoubleArrayList();
        
        for (int lag = 0; lag <= maxLag; lag++) // TODO the data still need to be de-trended because of the drift mu
            autocorrOfSample.add(Descriptive.autoCorrelation(data, lag, meanOfSample, varOfSample));

        /**
         * Printing values for visual inspection
         */
        System.out.println("Sample mean: " + meanOfSample + " - Expected: " + mu + " - Diff: " + diffMean);
        System.out.println("Sample var: " + varOfSample + " - Expected: " + sigma * sigma + " - Diff: " + diffVar);
        System.out.println("ACF: " + VersatileTimeSeries.printValues(autocorrOfSample));
//        System.out.println("Data: " + VersatileTimeSeries.printValues(data));
        
    }

}
