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
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool.DistributionType;

import java.util.ArrayList;

import cern.colt.list.DoubleArrayList;
import cern.jet.random.AbstractDistribution;
import cern.jet.random.Normal;
import cern.jet.random.Uniform;

/**
 * This data generator creates one or several independent streams of random 
 * numbers drawn from given distributions. The streams are created by the 
 * class RandomGeneratorPool using non-repeated seeds provided by class 
 * RandomSeedTable. The data generator can create both scalar and vector 
 * random values.
 *  
 * @author Gilbert Peffer
 *
 */
public class RandomDistDataGenerator implements DataGenerator {

    private ArrayList<AbstractDistribution> distList = new ArrayList<AbstractDistribution>();
    private ArrayList<Double> lastValues;

    /**
     * Constructor for the scalar random data generator.
     * 
     * @param params the list of parameters for the requested distribution(s)
     */
    public RandomDistDataGenerator(String name, DistributionType distType, Double...params) {
        super();
        
        lastValues = new ArrayList<Double>();

        if (distType == DistributionType.UNIFORM) {
            ArrayList<Uniform> uniformList = RandomGeneratorPool.createUniformMultiGenerator(name, params);
            
            for (Uniform uniform : uniformList) {
                distList.add(uniform);
                lastValues.add(0.0);
            }            
        }
        else if (distType == DistributionType.NORMAL) {
            ArrayList<Normal> normalList = RandomGeneratorPool.createNormalMultiGenerator(name, params);
            
            for (Normal normal : normalList) {
                distList.add(normal);
                lastValues.add(0.0);
            }            
        }
    }

    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDouble()
     */
    @Override
    public double nextDouble() {
        
        Assertion.assertStrict(distList.size() == 1, Assertion.Level.ERR, "Asked for a scalar value, but data generator creates vector values");
        AbstractDistribution dist = distList.get(0);
        
        double nextValue = dist.nextDouble();
        lastValues.add(0, nextValue);
        
        return nextValue;
    }
    
    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDouble()
     */
    @Override
    public double nextDoubleIncrement() {

        Assertion.assertStrict(distList.size() == 1, Assertion.Level.ERR, "Asked for a scalar value, but data generator creates vector values");
        AbstractDistribution dist = distList.get(0);
        
        double nextDouble = dist.nextDouble();
        double increment =  nextDouble - lastValues.get(0);
        lastValues.add(0, nextDouble);
        
        return increment;
    }

    /**
     * @see info.financialecology.finance.utilities.datagen.DataGenerator#nextDoubleVector()
     */
    @Override
    public DoubleArrayList nextDoubleVector() {
        
        DoubleArrayList nextValues = new DoubleArrayList();
        
        for (AbstractDistribution dist : distList) {
            nextValues.add(dist.nextDouble());
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
    		
    		double value = distList.get(i).nextDouble(); 
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
