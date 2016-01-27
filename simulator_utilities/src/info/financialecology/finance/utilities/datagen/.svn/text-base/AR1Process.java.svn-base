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

import info.financialecology.finance.utilities.Assertion;

import cern.colt.list.DoubleArrayList;
import cern.jet.random.Normal;

/**
 * This class generates an AR(1) processe:
 * 
 *    x_t = delta + phi_1 * x_t-1 + w_t
 *   
 * where w_t is drawn from the normal distribution N(0,sigma^2). 
 * 
 * See http://goo.gl/U9tyTc
 * 
 * @author Gilbert Peffer
 *
 */
public class AR1Process implements DataGenerator {
    
    private double delta;
    private double phi;
    private double lastValue;
    private Normal normal;


    /**
     * Constructor for the AR(1) processes.
     * 
     * @param delta a constant
     * @param phi the parameter phi_1 of the AR(1)
     * @param sigma the standard deviation of the normal distribution N(0,sigma^2)
     */
    public AR1Process(String name, double delta, double phi, double sigma) {
        super();

        Assertion.assertOrKill(sigma >= 0, "The standard deviation has to be a positive number, but is" + sigma);
        
        this.delta = delta;
        this.phi = phi;
        this.lastValue = 0;
        
        normal = RandomGeneratorPool.createNormalGenerator("AR1 normal" + name, 0, sigma);
    }

    /**
     * Get the next double from the AR(1) process
     * 
     * @see DataGenerator#nextDouble()
     */
    @Override
    public double nextDouble() {
        
        double newValue = delta + phi * lastValue + normal.nextDouble();
        lastValue = newValue;
        
        return newValue;
    }

    /* (non-Javadoc)
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDoubleIncrement()
     */
    @Override
    public double nextDoubleIncrement() {
        // TODO Auto-generated method stub
        return 0;
    }

    /* (non-Javadoc)
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDoubles(int)
     */
    @Override
    public DoubleArrayList nextDoubles(int numDoubles) {
        
        DoubleArrayList dal = new DoubleArrayList();
        
        for (int i = 0; i < numDoubles; i++)
            dal.add(nextDouble());
        
        return dal;
    }

    /* (non-Javadoc)
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDoubleVector()
     */
    @Override
    public DoubleArrayList nextDoubleVector() {
        // TODO Auto-generated method stub
        return null;
    }

    /* (non-Javadoc)
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDoubleVectorIncrements()
     */
    @Override
    public DoubleArrayList nextDoubleVectorIncrements() {
        // TODO Auto-generated method stub
        return null;
    }
        
}
