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

package info.financialecology.finance.utilities.datagen;

import info.financialecology.finance.utilities.Assertion;

import java.util.ArrayList;
import java.util.List;

import cern.colt.list.DoubleArrayList;

/**
 * This class generates a stream of doubles based on the following equation:
 * 
 *    mean + amplitude * sin(2*pi * (shift + t) / lambda)
 *   
 * The first value returned by the generator is for t = 0.
 *    
 * The 4 parameters are provided via the constructor in the following order:
 * 
 *    mean, amplitude, shift, lambda
 * 
 * @author Gilbert Peffer
 *
 */
public class SinusDataGenerator implements DataGenerator {
    
	private List<Double> params;
    private int tick;
    private ArrayList<Double> lastValues = new ArrayList<Double>();

    /**
     * Constructor for the sinus generator.
     * 
     * @param params the list of parameters in the following order: mean, amplitude, shift, lambda
     */
    public SinusDataGenerator(Double...paramList) {
        super();

        Assertion.assertStrict(paramList.length % 4 == 0, Assertion.Level.ERR, "Number of parameters provided to the constructor" +
        		"of the SinusDataGenerator class is " + paramList.length + 
        		", but it should be a multiple of 4 (mean, amplitude, shift, lambda");
        
        tick = 0;
        
        int dim = (int) Math.floor(0.1 + paramList.length / 4);    // number of dimensions - a fix to avoid inaccuracy of division
        for (int i = 0; i < dim; i++)
            lastValues.add(0.0);
        
        setParams(paramList);
    }
    
    
    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDouble()
     */
    @Override
    public double nextDouble() {
        double nextValue = params.get(0) + params.get(1) * Math.sin(2 * Math.PI * ( params.get(2) + tick ) / params.get(3) );
        lastValues.add(0, nextValue);
        
        tick++;
         
        return nextValue;
    }
    
    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDouble()
     */
    @Override
    public double nextDoubleIncrement() {

    	double lastValue = lastValues.get(0);
    	double nextValue = nextDouble();
        double increment =  nextValue - lastValue;
                
        return increment;
    }

    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDoubleVector()
     */
    @Override
    public DoubleArrayList nextDoubleVector() {

        DoubleArrayList values = new DoubleArrayList();
        
        int dim = (int) Math.floor(0.1 + params.size() / 4);    // number of dimensions - a fix to avoid inaccuracy of division
        
        for (int i = 0; i < dim; i++) {
            int iMean = i * 4;
            int iAmplitude = i * 4 + 1;
            int iShift = i * 4 + 2;
            int iLambda = i * 4 + 3;
            
            values.add(params.get(iMean) + params.get(iAmplitude) * Math.sin(2 * Math.PI * ( params.get(iShift) + tick ) / params.get(iLambda) ) );
        }
        
        for (int i = 0; i < dim; i++) {   // Update the lastValues for the next iteration
    		lastValues.add(i, values.get(i));
    	}
        
        tick++;
        
        return values;
    }
    
    @Override
    public DoubleArrayList nextDoubleVectorIncrements() {
    	
    	int dim = (int) Math.floor(0.1 + params.size() / 4);    // number of dimensions - a fix to avoid inaccuracy of division
    	DoubleArrayList copyLastValues = new DoubleArrayList();
    	
    	for (int i = 0; i < dim; i++) {   // Update the lastValues for the next iteration
    		copyLastValues.add(lastValues.get(i));
    	}
    	
    	DoubleArrayList nextValues = nextDoubleVector();
    	DoubleArrayList increments = new DoubleArrayList();
    	
    	for (int i = 0; i < dim; i++) {    		
    		increments.add(nextValues.get(i) - copyLastValues.get(i));
        }
   	
        return increments;        
    }   
    
    /**
     * Add the parameters for the generator equation to the parameter list
     * 
     * @param paramList the parameter list provided via the constructor
     */
    private void setParams(Double...paramList) {
        params = new ArrayList<Double>();
        
        for(Double item : paramList) {
            params.add(item);
        }
            
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
