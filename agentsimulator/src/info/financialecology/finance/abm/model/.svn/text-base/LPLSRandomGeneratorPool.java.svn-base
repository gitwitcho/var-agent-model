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
package info.financialecology.finance.abm.model;

import info.financialecology.finance.abm.simulation.LPLSEqnParams;
import info.financialecology.finance.abm.simulation.LPLSEqnParams.Sequence;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.datagen.RandomGeneratorPool;
import cern.jet.random.AbstractDistribution;


/**
 * @author Gilbert Peffer
 *
 */
public class LPLSRandomGeneratorPool extends RandomGeneratorPool {
    
    final static int MAX_NUM_ASSETS = 1000;
    
    static LPLSEqnParams params = null;
    
    /**
     * Declaring the distributions 
     */
    public enum Distributions {
        LOG_PRICE_NOISE     (1, MAX_NUM_ASSETS, Sequence.PRICE_NOISE),
        LOG_REF_VALUE       (2, MAX_NUM_ASSETS, Sequence.REF_VALUE),
        CASH                (3, Sequence.CASH),
        ENTRY_VALUE         (4, Sequence.ENTRY_VALUE),
        EXIT_VALUE          (5, Sequence.EXIT_VALUE),
        OFFSET_VALUE        (6, MAX_NUM_ASSETS, Sequence.OFFSET_VALUE),
        ENTRY_LS            (7, Sequence.ENTRY_LS),
        EXIT_LS             (8, Sequence.EXIT_LS),
        MA_WIN_LS           (9, Sequence.MA_WIN_LS),
        R_PERIOD_LS         (10, Sequence.R_PERIOD_LS),
        ENTRY_TREND         (11, Sequence.ENTRY_TREND),
        EXIT_TREND          (12, Sequence.EXIT_TREND),
        DELAY_TREND         (13, Sequence.DELAY_TREND);
        
        static { Assertion.assertStrict(validateUniqueness(), Assertion.Level.ERR, "Base keys in enumerate 'Distributions' are not unique") ; }

        private final int mBaseKey;
        private final int mOffset;
        private final Sequence mSequence;
//        private Boolean mInitialised = false;

        Distributions(int baseKey, Sequence sequence) {
            this.mBaseKey = baseKey;
            this.mOffset = 1;
            this.mSequence = sequence;
        }

        Distributions(int baseKey, int offset, Sequence sequence) {
            this.mBaseKey = baseKey;
            this.mOffset = offset;
            this.mSequence = sequence;
        }
        
        public Sequence getSequence() { return mSequence; }
        public int getOffset() { return mOffset; }

        /**
         * A distribution with a given baseKey has to use a generator whose seed is always the same.
         * For a given baseKey, the start index points to the same location in the random seed table
         * and ensures that the associated generator(s) always have the same seed 
         *  
         * @return the index into the random seed table at which to start the seed (for a single generator)
         * or seeds (in case of multiple generators)
         * 
         */
        public int getStartIndex() {
            int startIndex = 1;
            
            for (Distributions dist : Distributions.values()) {                
                if (dist.mBaseKey < mBaseKey)
                    startIndex += mOffset;
            }
            
            return startIndex;
        }
        
        /**
         * Check whether the base keys defined in this enum are unique
         * 
         * @return true, if all base keys have unique values  
         */
        public static Boolean validateUniqueness() {
            Boolean valid = true;
            
            for (Distributions dist : Distributions.values()) {
                int key = dist.mBaseKey;
                int count = 0;
                
                for (Distributions innerDist : Distributions.values()) {
                    if (dist.mBaseKey == innerDist.mBaseKey)
                        count++;
                }
                
                if (count > 1) valid = false;
            }
            
            return valid;
        }
    }

    protected LPLSRandomGeneratorPool() {
        initDistributions();
    }
    
    protected LPLSRandomGeneratorPool(int iSeedIndex) {
        configureGeneratorPool(iSeedIndex);     // TODO not tested with this class
        initDistributions();
    }
    
    private void initDistributions() {
        // TODO this should be automated based on the enum list and by adding a parameter indicating the required number of distributions
//        generateUniqueNormals(Distributions.LOG_PRICE_NOISE, params.nAssets, params);
//        generateUniqueNormals(Distributions.LOG_REF_VALUE, params.nAssets, params);
//        generateUniqueUniform(Distributions.CASH, params);
//        generateUniqueUniform(Distributions.ENTRY_VALUE, params);
//        generateUniqueUniform(Distributions.EXIT_VALUE, params);
//        generateUniqueUniforms(Distributions.OFFSET_VALUE, params.nAssets, params);
//        generateUniqueUniform(Distributions.ENTRY_LS, params);
//        generateUniqueUniform(Distributions.EXIT_LS, params);
//        generateUniqueUniform(Distributions.MA_WIN_LS, params);
//        generateUniqueUniform(Distributions.R_PERIOD_LS, params);
//        generateUniqueUniform(Distributions.DELAY_TREND, params);
//        generateUniqueUniform(Distributions.ENTRY_TREND, params);
//        generateUniqueUniform(Distributions.EXIT_TREND, params);
    }
    
//    public static LPLSRandomGeneratorPool getInstance() {
//        Assertion.assertStrict(params != null, Assertion.Level.ERR, "Parameters have not been set for the generator pool. Use the method 'getInstance(LPLSEquationParams)'");
//        
//        if (RandomGeneratorPool.getInstance() == null)
//            RandomGeneratorPool.setInstance(new LPLSRandomGeneratorPool());
//        
//        return (LPLSRandomGeneratorPool) RandomGeneratorPool.getInstance();
//    }
//    
//    public static LPLSRandomGeneratorPool getInstance(LPLSEqnParams oParams) {
//        Assertion.assertStrict(params == null, Assertion.Level.ERR, "Parameters have already been set for the generator pool. Use the method 'getInstance()' instead");
//        params = oParams;
//        return LPLSRandomGeneratorPool.getInstance();
//    }
//    
//    public static LPLSRandomGeneratorPool getInstance(LPLSEqnParams oParams, int iSeedIndex) {
//        Assertion.assertStrict(params == null, Assertion.Level.ERR, "Parameters have already been set for the generator pool. Use the method 'getInstance()' instead");
//        params = oParams;
//        RandomGeneratorPool.setInstance(new LPLSRandomGeneratorPool(iSeedIndex));
//        return LPLSRandomGeneratorPool.getInstance();
//    }
    
//    public static AbstractDistribution getDistribution(Distributions dist) {
//        Assertion.assertStrict(dist.getOffset() == 1, Assertion.Level.ERR, "You need to provide an index for list of distributions '" + dist.name() + "'. Use 'getDistribution(Distributions dist, int index)'");
//        return RandomGeneratorPool.getDistribution(dist.name());
//    }
//
//    public static AbstractDistribution getDistribution(Distributions dist, int index) {
//        // TODO check index is not out of bounds
//        return RandomGeneratorPool.getDistribution(dist.name() + "_" + index);
//    }
//    
//    public static void resetGeneratorPool(int iSeedIndex) {
//        // TODO recreate existing distributions (done already?)
//        RandomGeneratorPool.setInstance(new LPLSRandomGeneratorPool());
//    }

}
