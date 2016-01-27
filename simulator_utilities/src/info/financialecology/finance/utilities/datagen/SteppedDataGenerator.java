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
 * This class generates a stream of doubles based on a stepped function.
 * It is based on the following equation:
 * 
 *    shift + stepHeight * [t-Floor(t/(stepWidth + valleyWidth))*(stepWidth + valleyWidth)<(stepWidth + valleyWidth)] * [t-Floor(t/(stepWidth + valleyWidth))*(stepWidth + valleyWidth)>= valleyWidth],
 *    
 *    where [p]=1 if p is true, [p]=0 otherwise
 *     
 *  The first value returned by the generator is for t = 0.
 *  
 *  The 4 parameters are provided via the constructor in the following order:
 *     shift, stepHeight, stepWidth, valleyWidth
 *  
 *  @author llacay
 *  
 */

public class SteppedDataGenerator implements DataGenerator {
    
    private List<Double> params;
    private int tick;
    private ArrayList<Double> lastValues = new ArrayList<Double>();

    /**
     * Constructor for the stepped data generator.
     * 
     * @param params the list of parameters in the following order: shift, stepHeight, stepWidth, valleyWidth
     */
    public SteppedDataGenerator(Double...paramList) {
        super();
        
        Assertion.assertStrict(paramList.length % 4 == 0, Assertion.Level.ERR, "Number of parameters provided to the constructor" +
        		"of the SteppedDataGenerator class is " + paramList.length + 
        		", but it should be a multiple of 4 (shift, stepHeight, stepWidth, valleyWidth");
        
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

    	// Conditions that indicate if in the current time step the process lies in a step (instead of a valley)
    	// The boolean conditions are transformed to numerical variables for the subsequent calculations
    	// Absolute value is taken for the stepWidth and valleyWidth parameters, because a negative value for these parameters makes no sense 
    	   	
    	int stepStarted = (tick - Math.floor(tick/(Math.abs(params.get(2))+Math.abs(params.get(3)))) * (Math.abs(params.get(2))+Math.abs(params.get(3))) >= Math.abs(params.get(3)) == true ? 1 : 0);
    	int stepNotFinished = (tick - Math.floor(tick/(Math.abs(params.get(2))+Math.abs(params.get(3)))) * (Math.abs(params.get(2))+Math.abs(params.get(3))) < (Math.abs(params.get(2))+Math.abs(params.get(3))) == true ? 1 : 0);
    	
    	// Calculate a new value for the stepped process
    	double nextValue = params.get(0) + params.get(1) * stepStarted * stepNotFinished;
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
            int iShift = i * 4;
            int iStepHeight = i * 4 + 1;
            int iStepWidth = i * 4 + 2;
            int iValleyWidth = i * 4 + 3;
            
            // Conditions that indicate if in the current time step the process lies in a step (instead of a valley)
        	// The boolean conditions are transformed to numerical variables for the subsequent calculations    	
        	int stepStarted = (tick - Math.floor(tick/(params.get(iStepWidth)+params.get(iValleyWidth))) * (params.get(iStepWidth)+params.get(iValleyWidth)) >= params.get(iValleyWidth) == true ? 1 : 0);
        	int stepNotFinished = (tick - Math.floor(tick/(params.get(iStepWidth)+params.get(iValleyWidth))) * (params.get(iStepWidth)+params.get(iValleyWidth)) < (params.get(iStepWidth)+params.get(iValleyWidth)) == true ? 1 : 0);
        	
        	// Calculate a new value for the stepped process            
            values.add(params.get(iShift) + params.get(iStepHeight) * stepStarted * stepNotFinished);
        }
        
        for (int i = 0; i < dim; i++) {   // Update the lastValues for the next iteration
    		lastValues.add(i, values.get(i));
    	}
        
        tick++;
        
        return values;
    }
    
    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDoubleVectorIncrements()
     */
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
