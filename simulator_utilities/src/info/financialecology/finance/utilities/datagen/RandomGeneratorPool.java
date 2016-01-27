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

import cern.jet.random.Normal;
import cern.jet.random.Uniform;
import cern.jet.random.engine.RandomEngine;
import cern.jet.random.engine.RandomSeedTable;
import repast.simphony.random.RandomHelper;

/**
 * Singleton.
 * 
 * @author Gilbert Peffer
 *
 */
public class RandomGeneratorPool {

    private static Boolean isPoolConfigured = false;   // TRUE if the generator pool has been set up using the configure methods
    private static int nextSeedIndex = 0;              // index pointing to the next usable seed in RandomSeedTable
    
    public enum DistributionType {
        UNIFORM (2),
        NORMAL (2);
        
        private final int mNumParams;
        
        DistributionType(int numParams) {
            this.mNumParams = numParams;
        }
        
        public int getNumParams() { return mNumParams; }
    }
    
    protected RandomGeneratorPool() {}
    
    /**
     * Get the unique instance of RandomGeneratorPool. In case the 
     * generator pool does not yet exist, create the unique instance.
     * 
     * This method creates a generator pool that produces sequences 
     * starting at a random seed. This is useful when executing a 
     * simulation program manually and where different runs should 
     * produce different random sequences to create variation for 
     * visual verification.
     * 
     * @return the unique instance of RandomGeneratorPool 
     */
    public static void configureGeneratorPool() {

        clearGeneratorPool((int) System.currentTimeMillis());
        isPoolConfigured = true;
    }
        
    /**
     * Get the unique instance of RandomGeneratorPool. In case the 
     * generator pool does not yet exist, create the unique instance.
     * 
     * This method creates a generator pool that for a fixed seed index
     * provide random generators that produce the same random sequences 
     * every time the program is executed or the generator pool reset.
     * Specifying the seed index for the RandomSeedTable rather than
     * always starting at index 0 has the advantage of being able to 
     * make comparisons between simulation runs/experiments when executing
     * manually, for visual verification.
     * 
     * @param seedIndex the starting index in the seed table RandomSeedTable 
     * @return the unique instance of RandomGeneratorPool
     */
    public static void configureGeneratorPool(int startSeedIndex) {
        
        clearGeneratorPool(startSeedIndex);
        isPoolConfigured = true;
    }
        
    /**
     * Reset the generator pool and restart random number streams using as the first
     * seed the entry the table RandomSeedTable to which iSeedStartIndex points 
     * 
     * @param iSeedStartIndex the index pointing to the entry in the RandomSeedTable
     * that is to be used as the first seed
     */
    protected static void clearGeneratorPool(int startSeedIndex) {
        
        RandomHelper.getRegistry().reset();
        nextSeedIndex = Math.abs(startSeedIndex);
    }
    
    
    /**
     * Creates a uniform distribution with the given minimum and maximum values.
     * 
     * @param name Registration name for the random number generator
     * @param from Minimum value of the uniform distribution
     * @param to Maximum value of the uniform distribution
     * @return Uniform distribution
     */    
    public static Uniform createUniformGenerator(String name, double from, double to) {
        Assertion.assertStrict(isPoolConfigured, Assertion.Level.ERR, "Random generator pool " + 
                "not configured. Use the configureGeneratorPool(...) methods to create a generator pool");
        getNextIndex();
        int seed = RandomSeedTable.getSeedAtRowColumn(nextSeedIndex, 0);
        
        checkForDuplicateName(name);
        
        RandomEngine generator = RandomHelper.registerGenerator(name, seed);
        Uniform distribution = new Uniform(from, to, generator);
        RandomHelper.registerDistribution(name, distribution);
        
        return distribution;
    }
    
    /**
     * Creates a normal distribution with the given mean and standard deviation.
     * 
     * @param name Registration name for the random number generator
     * @param mean Mean of the normal distribution
     * @param stdev Standard deviation of the normal distribution
     * @return Normal distribution
     */    
    public static Normal createNormalGenerator(String name, double mean, double stdev) {
        Assertion.assertStrict(isPoolConfigured, Assertion.Level.ERR, "Random generator pool " + 
                "not configured. Use the configureGeneratorPool(...) methods to create a generator pool");
        getNextIndex();
        int seed = RandomSeedTable.getSeedAtRowColumn(nextSeedIndex, 0);

        checkForDuplicateName(name);
        
        RandomEngine generator = RandomHelper.registerGenerator(name, seed);
        Normal distribution = new Normal(mean, stdev, generator);
        RandomHelper.registerDistribution(name, distribution);
        
        return distribution;
    }
    
    /**
     * Creates a list of uniform distributions with the given minimum and maximum values.
     * 
     * @param baseName Base name for the random number generator. The name with which the generator is stored is 
     *                 baseName_i, where 'i' runs from '0' to the number of generators.
     * @param params List of minimum and maximum values of the uniform distributions
     * @return Array of uniform distributions
     */    
    public static ArrayList<Uniform> createUniformMultiGenerator(String baseName, Double...params) {
        Assertion.assertStrict(isPoolConfigured, Assertion.Level.ERR, "Random generator pool " + 
                "not configured. Use the configureGeneratorPool(...) methods to create a generator pool");

        ArrayList<Uniform> distList = new ArrayList<Uniform>();
        
        Assertion.assertStrict(params.length % 2 == 0, Assertion.Level.ERR, "Number of distribution parameters " + 
                "is " + params.length + ", but it should be an even number (left and right hand bounds of the " +
                "uniform distribution");

        int dim = (int) Math.floor(0.1 + params.length / 2);    // number of dimensions - a fix to avoid inaccuracy of division
        
        for (int i = 0; i < dim; i++) {
            String name = baseName;
            int iFrom = i * 2;
            int iTo = i * 2 + 1;

            if (dim > 1) name += "_" + i;
            
            distList.add(createUniformGenerator(name, params[iFrom], params[iTo]));
        }
        
        return distList;
    }
    
    /**
     * Creates a list of normal distributions with the given means and standard deviations.
     * 
     * @param baseName Base registration name for the random number generator
     * @param params List of mean and standard deviations of the normal distributions
     * @return Array of normal distributions
     */  
    public static ArrayList<Normal> createNormalMultiGenerator(String baseName, Double...params) {
        Assertion.assertStrict(isPoolConfigured, Assertion.Level.ERR, "Random generator pool " + 
                "not configured. Use the configureGeneratorPool(...) methods to create a generator pool");

        ArrayList<Normal> distList = new ArrayList<Normal>();
        
        Assertion.assertStrict(params.length % 2 == 0, Assertion.Level.ERR, "Number of distribution parameters " + 
                "is " + params.length + ", but it should be an even number (mean and standard deviation of the " +
                "normal distribution");

        int dim = (int) Math.floor(0.1 + params.length / 2);    // number of dimensions - a fix to avoid inaccuracy of division
        
        for (int i = 0; i < dim; i++) {
            String name = baseName;
            int iMean = i * 2;
            int iStdev = i * 2 + 1;
            
            if (dim > 1) name += "_" + i;

            distList.add(createNormalGenerator(name, params[iMean], params[iStdev]));
        }
        
        return distList;
    }
    
    
    private static int getNextIndex() {
        int currentIndex = nextSeedIndex;
        nextSeedIndex++;
        return (currentIndex) % Integer.MAX_VALUE;
    }
    
    private static void checkForDuplicateName(String name) {
        
        try {
            RandomHelper.getGenerator(name);
            Assertion.assertStrict(false, Assertion.Level.ERR, 
                    "Random generator with name '" + name + "' already exists in the generator pool.");
        } catch (Exception e) {
            // do nothing
        }
    }    
}
