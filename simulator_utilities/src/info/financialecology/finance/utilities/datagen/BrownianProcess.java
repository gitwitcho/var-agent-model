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

import java.util.ArrayList;

import cern.colt.list.DoubleArrayList;
import cern.jet.random.AbstractDistribution;
import cern.jet.random.Normal;

/**
 * This class generates a vector of Brownian processes:
 * 
 *    S_i+1 = S_i + mu * (t_i+1 - t_i) + sigma * sqrt(t_i+1 - t_i) * z_i
 *   
 * where z_i is drawn from the normal distribution N(0,1) and S_0 = 0. 
 * 
 * The use of the index 'i' ensures that the parameters mu and sigma 
 * are normalised. For instance, if sigma is the annual volatility and
 * the time step is in business days, t_i+1 - t_i = 1/250 and the 
 * annual volatility is correctly normalised to its daily value of
 * sigma / sqrt(250). At the moment, the user needs to do the
 * normalisation when setting up the process object
 * 
 * Preferably use a geometric Brownian motion to model prices.
 * 
 * See http://math.gmu.edu/~tsauer/pre/sde.pdf
 * 
 * @author Gilbert Peffer
 *
 */
public class BrownianProcess implements DataGenerator {
    
    private ArrayList<Double> paramList;
    private ArrayList<Double> lastValues;
    private ArrayList<AbstractDistribution> distList;
        
    private Type type;  // the type of the Brownian process
    
    public enum Type {  // type of Brownian process
        ARITHMETIC,     // this can generate negative values
        GEOMETRIC;      // generally used for prices
    }

    // TODO Add the correlation matrix

    /**
     * Constructor for the Brownian processes.
     * 
     * The parameters mu and sigma have to be normalised to the time step used w.r.t. the interval 
     * for which the parameters are defined (e.g. time step is a day while parameters are annualised).
     * An initial value for the process has to be provided as well.
     * 
     * @param params the list of parameters in the following order: init, mu, sigma
     */
    public BrownianProcess(String name, Type type, Double...params) {
        super();

        Assertion.assertStrict(params.length % 3 == 0, Assertion.Level.ERR, "Number of parameters provided to the constructor" +
        		"of the BrownianProcess class is " + params.length + 
        		", but it should be a multiple of 3 (initial value, mu, sigma");
        
        this.type = type;
        
        int dimensions = (int) Math.floor(0.1 + params.length / 3);    // number of dimensions - a fix to avoid inaccuracy of division
        
        paramList = new ArrayList<Double>();
        lastValues = new ArrayList<Double>();
        distList = new ArrayList<AbstractDistribution>();
        
        for (int i = 0; i < dimensions; i++) {  // Extract parameters
            lastValues.add(params[3*i]);                // initial value
            paramList.add(2*i, params[3*i + 1]);        // mu
            paramList.add(2*i + 1, params[3*i + 2]);    // sigma
        }
        
        Double [] normalParams = new Double[dimensions * 2];
        
        for (int i = 0; i < dimensions; i++) {  // Reset parameters to N(0,1) to generate the z_i
            normalParams[2 * i] = 0.0;
            normalParams[2 * i + 1] = 1.0;
        }
        
        ArrayList<Normal> normalList = RandomGeneratorPool.createNormalMultiGenerator(name, normalParams);
        
        for (Normal normal : normalList)
            distList.add(normal);
    }

    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDouble()
     */
    @Override
    public double nextDouble() {

        Assertion.assertStrict(distList.size() == 1, Assertion.Level.ERR, "Asked for a scalar value, but data generator creates vector values");
        
        AbstractDistribution dist = distList.get(0);
        double nextValue = 0;
        
        if (type == Type.ARITHMETIC)
            nextValue = lastValues.get(0) + paramList.get(0) + paramList.get(1) * dist.nextDouble();
        else if (type == Type.GEOMETRIC)// Type = GEOMETRIC
            nextValue = lastValues.get(0) * (1 + paramList.get(0) + paramList.get(1) * dist.nextDouble());
        else
            Assertion.assertOrKill(false, "Type for Brownian process has to be ARITHMETIC or GEOMETRIC");
        
        lastValues.add(0, nextValue);

        return nextValue;
    }
        
    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDoubleIncrement()
     */
    @Override
    public double nextDoubleIncrement() {
        
        Assertion.assertStrict(distList.size() == 1, Assertion.Level.ERR, "Asked for a scalar value, but data generator creates vector values");
        
        AbstractDistribution dist = distList.get(0);
        double nextDouble = 0;
        double increment = 0;
        
        if (type == Type.ARITHMETIC)
            nextDouble = lastValues.get(0) + paramList.get(0) + paramList.get(1) * dist.nextDouble();
        else if (type == Type.GEOMETRIC)
            nextDouble = lastValues.get(0) * (1 + paramList.get(0) + paramList.get(1) * dist.nextDouble());
        else
            Assertion.assertOrKill(false, "Type for Brownian process has to be ARITHMETIC or GEOMETRIC");

        increment =  nextDouble - lastValues.get(0);
        lastValues.add(0, nextDouble);
        
        return increment;        
    }
        
    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDoubleVector()
     */
    @Override
    public DoubleArrayList nextDoubleVector() {

    	DoubleArrayList nextValues = new DoubleArrayList();
        
    	for (int i = 0; i < distList.size(); i++) {
    	    
    		double value = 0;
    		 
            if (type == Type.ARITHMETIC)
                value = lastValues.get(i) + paramList.get(2*i) + paramList.get(2*i+1) * distList.get(i).nextDouble(); 
            else if (type == Type.GEOMETRIC)
                value = lastValues.get(i) * (1 + paramList.get(2*i) + paramList.get(2*i+1) * distList.get(i).nextDouble()); 
            else
                Assertion.assertOrKill(false, "Type for Brownian process has to be ARITHMETIC or GEOMETRIC");

            nextValues.add(value);            
        }
    	
    	for (int i = 0; i < distList.size(); i++) {   // Update the lastValues for the next iteration
    		lastValues.add(i, nextValues.get(i));
    	}
    	
        return nextValues;         
    }
    
    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDoubleVectorIncrements()
     */
    @Override
    public DoubleArrayList nextDoubleVectorIncrements() {
    	
    	DoubleArrayList nextValues = new DoubleArrayList();
    	DoubleArrayList increments = new DoubleArrayList();
    	
        for (int i = 0; i < distList.size(); i++) {
    		
            double value = 0;

            if (type == Type.ARITHMETIC)
                value = lastValues.get(i) + paramList.get(2*i) + paramList.get(2*i+1) * distList.get(i).nextDouble();
            else if (type == Type.GEOMETRIC)
                value = lastValues.get(i) * (1 + paramList.get(2*i) + paramList.get(2*i+1) * distList.get(i).nextDouble()); 
            else
                Assertion.assertOrKill(false, "Type for Brownian process has to be ARITHMETIC or GEOMETRIC");

            nextValues.add(value);
            increments.add(value - lastValues.get(i));
        }
    	    	
    	for (int i = 0; i < distList.size(); i++) {   // Update the lastValues for the next iteration
    		lastValues.add(i, nextValues.get(i));
    	}
    	
        return increments;        
    }
    
    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDoubles(int)
     */
    @Override
    public DoubleArrayList nextDoubles(int numDoubles) {
        DoubleArrayList dal = new DoubleArrayList();
        
        for (int i = 0; i < numDoubles; i++)
            dal.add(nextDouble());
        
        return dal;
    }
}
