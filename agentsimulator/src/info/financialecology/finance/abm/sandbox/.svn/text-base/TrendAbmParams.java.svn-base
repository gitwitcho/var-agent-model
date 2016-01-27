/**
 * Simple financial systemic risk simulator for Java
 * http://code.google.com/p/systemic-risk/
 * 
 * Copyright (c) 2011, 2012
 * Gilbert Peffer, CIMNE
 * gilbert.peffer@gmail.com
 * All rights reserved
 * 
 * Revisions
 *    - 27 Nov 2013 (GP)
 *
 * This software is open-source under the BSD license; see 
 * http://code.google.com/p/systemic-risk/wiki/SoftwareLicense
 */
package info.financialecology.finance.abm.sandbox;

import info.financialecology.finance.abm.sandbox.TrendValueAbmParams.Sequence;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.datastruct.ParamSequence;
import info.financialecology.finance.utilities.datastruct.SimulationParameters;

import java.io.FileNotFoundException;
import java.lang.reflect.Type;
import java.util.ArrayList;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import cern.colt.list.DoubleArrayList;
import cern.colt.list.IntArrayList;


/**
 * A simple parameter class that uses xstream to read and write object parameters from and to files.
 * 
 * See also:
 *      Xstream: http://tinyurl.com/66o9od
 *      "Use XStream to serialize Java objects into XML": http://tinyurl.com/6ah27g
 *      
 * Parser for parameters to read sequences of numbers and sequences of intervals
 * 
 * To create the parameter file from this class, use writeParameterDefinition
 * 
 * Adding a new parameter
 * ----------------------
 *      1. Declare the parameter variable in PARAMETER DECLARATIONS
 *      1a. Intervals and sequences are declared as String and assigned "NAN" as the default value
 *      2. Define an enum for the parameter in Sequence
 *      3. If the parameter is a sequence, add an entry to Sequence.length()
 *      
 *      
 *
 *      
 * @author Gilbert Peffer
 *
 */

public class TrendAbmParams extends SimulationParameters {
    
    private static final Logger logger = (Logger)LoggerFactory.getLogger(TrendAbmParams.class.getSimpleName());
    
    /**
     * 
     *      PARAMETER DECLARATIONS
     *      ======================
     *      
     * 
     */

    public int nTicks           = 0;        // number of ticks per simulation run
    public int nRuns            = 0;        // number of runs per simulation experiment
    public int seed             = -1;       // starting position in the random seed table; -1 for random value (based on internal clock) 
    public int numTrends        = 0;        // number of Trend investors
    public String shift;                    // shift parameter of the sinus function (see SinusDataGenerator for details)
    public String amplitude;                // amplitude parameter of the sinus function
    public String lag;                      // lag parameter of the sinus function
    public String lambda;                   // lambda parameter of the sinus function
    public String mu;                       // mu parameter of the normal distribution
    public String sigma;                    // sigma parameter of the normal distribution
    public String price_0;                  // value of the price at t=0
    public String liquidity;                // asset liquidity
    public int normPeriod       = 0;        // range of input data for normalising the orders of VALUE and TREND traders, in ticks
    
    /*
     * TREND strategy parameters
     */
    public int maShortTicks     = 0;       // size of the window for the fast moving MA
    public int maLongTicks      = 0;       // size of the window for the slow moving MA
    public int bcTicks          = 0;       // size of the exit channel
    public double capFactor     = 0;       // capital factor
    public int volWindowTrend   = 0;       // size of the window to compute the volatility


    
    /*
     * This enum defines all parameters of non-primitive type. Non-primitive 
     * types are declared as Strings in the XML parameter file and then 
     * internally transformed to the corresponding data types.
     * 
     * Example: shift is defined as a sequence of doubles. The length
     * of that sequence is given by the method length(). In this case there
     * are as many shift parameters as there are assets
     */
    public enum Sequence implements ParamSequence {
        
        /**
         *  Parameters
         *  ----------
         *      - label
         *      - primitive type
         *      - item type (as defined in enum Item)
         *      - optional: true, if the parameter is optional
         *      
         */
        SHIFT(Item.DOUBLE_SEQ, false),
        AMPLITUDE(Item.DOUBLE_SEQ, false),
        LAG(Item.DOUBLE_SEQ, false),
        LAMBDA(Item.DOUBLE_SEQ, false),
        MU(Item.DOUBLE_SEQ, false),
        SIGMA(Item.DOUBLE_SEQ, false),
        PRICE_0(Item.DOUBLE_SEQ, false),
        LIQUIDITY(Item.DOUBLE_SEQ, false);
        
        private String param;
//        private final String paramOptionalNotProvided = "NA";
        private boolean optional;
        private final String label;
        private final Item itemType;
        
        Sequence(Item itemType, boolean optional) {
            this.param = "missing";     // overridden when parameter file is read
            this.optional = optional;
            this.label = this.toString();
            this.itemType = itemType;
        }
        
        public String label() { return label; }
        public Item itemType() { return itemType; }
        public String param() { return param; }
//        public String paramOptionalNotProvided() { return paramOptionalNotProvided; }
        public boolean isOptional() { return optional; }
        
        public void setParamString(String param) {
            this.param = param;
        }
        
        public Type type() {
            Type type = Object.class;
            
            if ((this.itemType == Item.DOUBLE) ||
                    (this.itemType == Item.DOUBLE_SEQ) ||
                    (this.itemType == Item.DOUBLE_INTERVAL) ||
                    (this.itemType == Item.DOUBLE_INTERVAL_SEQ)) {
                type = Double.class;
            } else if ((this.itemType == Item.INTEGER) ||
                    (this.itemType == Item.INTEGER_SEQ) ||
                    (this.itemType == Item.INTEGER_INTERVAL) ||
                    (this.itemType == Item.INTEGER_INTERVAL_SEQ)) {
                type = Integer.class;
            }
            
            return type;
        }
        
        /**
         * Some parameter sequences have to have a specific length. This method declares the length
         * of a sequence. Where there is no constraint on the length of a sequence, return '0'. Only
         * declare parameters that are sequences, not those that are single numbers or intervals 
         * 
         * @param params the parameter object
         * @return the constraint on the length of the sequence
         * 
         */
        // TODO In our case here, the parameter sequences need to have he same length. Check in validations below?
        public int length(SimulationParameters params) {
            switch (this) {
//                case LIQUIDITY: return params.nAssets; 
//                case PRICE_0: return params.nAssets;
//                case PRICE_NOISE: return params.nAssets; 
//                case REF_VALUE: return params.nAssets; 
//                case OFFSET_VALUE: return params.nAssets;
                default:
                    if ((this.itemType() == Item.INTEGER) ||
                            (this.itemType() == Item.INTEGER_INTERVAL) ||
                            (this.itemType() == Item.DOUBLE) ||
                            (this.itemType() == Item.DOUBLE_INTERVAL))
                        return 1;

//                    Assertion.assertStrict(false, Assertion.Level.ERR, "Cannot find sequence type '" + this.label() + "'");
//            }
//            return -1;
            }
            return 0;
        }
    }
    
    TrendAbmParams() {}
    
    
    /**
     * Add the string of the sequence, interval, or interval sequence to the corresponding enum
     */
    private void initialiseSequenceParams() {
        Sequence.SHIFT.setParamString(shift);
        Sequence.AMPLITUDE.setParamString(amplitude);
        Sequence.LAG.setParamString(lag);
        Sequence.LAMBDA.setParamString(lambda);
        Sequence.MU.setParamString(mu);
        Sequence.SIGMA.setParamString(sigma);
        Sequence.PRICE_0.setParamString(price_0);
        Sequence.LIQUIDITY.setParamString(liquidity);
    }
    

    /**
     * Validate the parameters
     *  - constraints on their value
     *  - constraints on sequences of parameters, e.g. their number is equal to the number of assets 
     * 
     * @return true, if the parameter object is valid
     * 
     */
    public Boolean validate() {
        ArrayList<IntArrayList> iSeq = null;       // integer sequences
        ArrayList<DoubleArrayList> dSeq = null;    // sequences of doubles
        
        /**
         * VALIDATE: primitive types (nRuns, nTicks, ...)
         */
        Assertion.assertStrict(nTicks > 0, Assertion.Level.ERR, "nTicks = " + nTicks + ": needs to be '> 0'");
        Assertion.assertStrict(nRuns > 0, Assertion.Level.ERR, "nRuns = " + nRuns + ": needs to be '> 0'");
        Assertion.assertStrict(normPeriod >= 0, Assertion.Level.ERR, "normPeriod = " + normPeriod + ": needs to be '>= 0'");
        Assertion.assertStrict(numTrends > 0, Assertion.Level.ERR, "numTrends = " + numTrends + ": needs to be '> 0'");
        Assertion.assertStrict(maLongTicks > 0, Assertion.Level.ERR, "maLongTicks needs to be '> 0'");
        Assertion.assertStrict(maShortTicks > 0, Assertion.Level.ERR, "maShortTicks needs to be '> 0'");
        Assertion.assertStrict(bcTicks > 0, Assertion.Level.ERR, "bcTicks needs to be '> 0'");
        Assertion.assertStrict(capFactor > 0, Assertion.Level.ERR, "capFactor needs to be '> 0'");
        Assertion.assertStrict(volWindowTrend >= 0, Assertion.Level.ERR, "volWindowTrend needs to be '>= 0'");

        /**
         * VALIDATE sequences: shift, amplitude, lag, lambda, mu, sigma 
         */
        validateDoubleSequence(Sequence.SHIFT);
        validateDoubleSequence(Sequence.AMPLITUDE);
        validateDoubleSequence(Sequence.LAG);
        validateDoubleSequence(Sequence.LAMBDA);
        validateDoubleSequence(Sequence.MU);
        validateDoubleSequence(Sequence.SIGMA);
        validateDoubleSequence(Sequence.PRICE_0);
        validateDoubleSequence(Sequence.LIQUIDITY);
        
        /**
         * Validate combinations of parameters
         */
        boolean validated_1 = false;
        boolean validated_2 = false;
        
        /*
         * Validate sinus generator and Brownian process parameters. The 
         * values have to be all omitted or all provided for either the
         * sinus generator or the Brownian process.
         *  
         * In the multi-asset case, the same validation applies to all
         * processes.
         */
        validated_1 = (shift.isEmpty() && amplitude.isEmpty() && lag.isEmpty() && lambda.isEmpty()) ||
                      (!shift.isEmpty() && !amplitude.isEmpty() && !lag.isEmpty() && !lambda.isEmpty());
        validated_2 = (mu.isEmpty() && sigma.isEmpty()) ||
                      (!mu.isEmpty() && !sigma.isEmpty());
        
        Assertion.assertStrict((validated_1 == true) && (validated_2 == true), Level.ERR, "Parameters for the the exogenous process are not well-defined " +
        		"(some are provided while others are omitted for either the sinus generator or the Brownian process)");
        
        // TODO The length of the sequences needs to be the same --> validate
        
        // TODO If one sequence param is optional, they all should be optional
        
        return true; 
    }
    
    public boolean isDefinedExogenousProcess() {
        
        boolean isDefined = (!shift.isEmpty() && !amplitude.isEmpty() && !lag.isEmpty() && !lambda.isEmpty()) ||
                            (!mu.isEmpty() && !sigma.isEmpty());

        return isDefined;
    }
    
    
    /**
     * Creates an xml file that holds the fields of this object
     * 
     * @param file
     * @throws FileNotFoundException 
     */
    public static void writeParamDefinition(String file) throws FileNotFoundException {
        writeParamsDefinition(file, new TrendAbmParams());
    }

    /**
     * Reads values from an xml file and initialises the fields of the newly created parameter object
     * 
     * @param file
     * @return
     * @throws FileNotFoundException 
     */
    public static TrendAbmParams readParameters(String file) throws FileNotFoundException {

        TrendAbmParams params = (TrendAbmParams) readParams(file, new TrendAbmParams());
        params.initialiseSequenceParams();
        params.validate();
        return params;
    }

    
}
