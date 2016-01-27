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
 * Formatting
 * ----------
 * c(1, 2, 3, 4)
 * c([1,2],[3,4],[5,6])
 * c(1:4) = 1, 2, 3, 4
 * c(1:2:4) = 1.0, 1.25, 1.5, 2.0 - '4' is the repeater argument
 * rep(9,3) = 9,9,9
 * rep([1,4],2) = [1,4],[1,4]
 * 
 * @author Gilbert Peffer
 *
 */


/**
 *  
 * ################################################################
 * 
 * Version 1.1
 * 
 * This is the MOST RECENT version of the PARAMS implementation.
 * 
 * Moved common methods to abstract super class SimulationParameters.  
 * 
 * #################################################################
 * 
 */
public class TrendValueLSAbmParams extends SimulationParameters {
    
    private static final Logger logger = (Logger)LoggerFactory.getLogger(TrendValueLSAbmParams.class.getSimpleName());
    
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
    public int numFunds         = 0;        // number of Value investors
    public int numLS            = 0;        // number of LS investors
//    public int normPeriod       = 0;      // DEPRECATED - range of input data for automatically normalising the orders of VALUE and TREND traders, in ticks
    
    /*
     * Price
     */    
    public String shift_price;              // shift parameter of the sinus function (see SinusDataGenerator for details)
    public String amplitude_price;          // amplitude parameter of the sinus function
    public String lag_price;                // lag parameter of the sinus function
    public String lambda_price;             // lambda parameter of the sinus function
    public String mu_price;                 // mu parameter of the normal distribution (for price formation)
    public String sigma_price;              // sigma parameter of the normal distribution (for price formation)
    public String price_0;                  // value of the price at t=0
    public String liquidity;                // asset liquidity
    
    /*
     * Fundamental value
     */
    public String shift_value;              // shift parameter of the sinus function (see SinusDataGenerator for details)
    public String amplitude_value;          // amplitude parameter of the sinus function
    public String lag_value;                // lag parameter of the sinus function
    public String lambda_value;             // lambda parameter of the sinus function
    public String mu_value;                 // mu parameter of the normal distribution (for generic fundamental value formation)
    public String sigma_value;              // sigma parameter of the normal distribution (for generic fundamental value formation)    
    
    
    /*
     * TREND strategy parameters
     */
    public int maShortTicksMin          = 0;     // size of the window for the fast moving MA
    public int maShortTicksMax          = 0;
    public int maLongTicksMin           = 0;     // size of the window for the slow moving MA
    public int maLongTicksMax           = 0;
    public int bcTicksTrendMin          = 0;     // size of the exit channel
    public int bcTicksTrendMax          = 0;
    public double capFactorTrend        = 0;     // capital factor
    public int volWindowTrend           = 0;     // size of the window to compute the volatility
    public double probShortSellingTrend = 0;     // percentage of TRENDs (0-1) allowed to short-sell
    
    /*
     * FUND strategy parameters
     */
    public double entryThresholdMin     = 0;     // entry threshold
    public double entryThresholdMax     = 0;
    public double exitThresholdMin      = 0;     // exit threshold
    public double exitThresholdMax      = 0;
    public double valueOffset           = 0;     // offset added by the trader to the value reference process
    public int bcTicksFundMin           = 0;     // size of the exit channel
    public int bcTicksFundMax           = 0;
    public double capFactorFund         = 0;     // capital factor
    public double probShortSellingValue = 0;     // percentage of FUNDs (0-1) allowed to short-sell

    /*
     * LS strategy parameters
     */
    public int maSpreadShortTicksMin       = 0;     // window to compute short-term mean of spread
    public int maSpreadShortTicksMax       = 0;
    public int maSpreadLongTicksMin        = 0;     // window to compute historical (long-term) mean and stdev of spread
    public int maSpreadLongTicksMax        = 0;
    public int volWindowLS                 = 0;     // size of the window to compute the volatility
    public double entryDivergenceSigmasMin = 0;     // number of sigmas used in the LS entry condition (spread divergence)
    public double entryDivergenceSigmasMax = 0;
    public double exitConvergenceSigmasMin = 0;     // number of sigmas used in the LS exit condition (spread convergence)
    public double exitConvergenceSigmasMax = 0;
    public double exitStopLossSigmasMin    = 0;     // number of sigmas used in the LS exit condition (stop loss)
    public double exitStopLossSigmasMax    = 0;
    public double capFactorLS              = 0;     // capital factor

    
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
        SHIFT_PRICE(Item.DOUBLE_SEQ, false),
        AMPLITUDE_PRICE(Item.DOUBLE_SEQ, false),
        LAG_PRICE(Item.DOUBLE_SEQ, false),
        LAMBDA_PRICE(Item.DOUBLE_SEQ, false),
        MU_PRICE(Item.DOUBLE_SEQ, false),
        SIGMA_PRICE(Item.DOUBLE_SEQ, false),
        PRICE_0(Item.DOUBLE_SEQ, false),
        LIQUIDITY(Item.DOUBLE_SEQ, false),
        SHIFT_VALUE(Item.DOUBLE_SEQ, false),
        AMPLITUDE_VALUE(Item.DOUBLE_SEQ, false),
        LAG_VALUE(Item.DOUBLE_SEQ, false),
        LAMBDA_VALUE(Item.DOUBLE_SEQ, false),
        MU_VALUE(Item.DOUBLE_SEQ, false),
        SIGMA_VALUE(Item.DOUBLE_SEQ, false);

        
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
    
    TrendValueLSAbmParams() {}
    
    
    /**
     * Add the string of the sequence, interval, or interval sequence to the corresponding enum
     */
    private void initialiseSequenceParams() {
        Sequence.SHIFT_PRICE.setParamString(shift_price);
        Sequence.AMPLITUDE_PRICE.setParamString(amplitude_price);
        Sequence.LAG_PRICE.setParamString(lag_price);
        Sequence.LAMBDA_PRICE.setParamString(lambda_price);
        Sequence.MU_PRICE.setParamString(mu_price);
        Sequence.SIGMA_PRICE.setParamString(sigma_price);
        Sequence.PRICE_0.setParamString(price_0);
        Sequence.LIQUIDITY.setParamString(liquidity);
        Sequence.SHIFT_VALUE.setParamString(shift_value);
        Sequence.AMPLITUDE_VALUE.setParamString(amplitude_value);
        Sequence.LAG_VALUE.setParamString(lag_value);
        Sequence.LAMBDA_VALUE.setParamString(lambda_value);
        Sequence.MU_VALUE.setParamString(mu_value);
        Sequence.SIGMA_VALUE.setParamString(sigma_value);
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
        Assertion.assertStrict((numTrends > 0 || numFunds > 0 || numLS > 0), Assertion.Level.ERR, "Either numTrends = " + numTrends 
        		+ "  or numFunds = " + numFunds + "  or numLS = " + numLS + "  need to be '> 0'");
//        Assertion.assertStrict(normPeriod >= 0, Assertion.Level.ERR, "normPeriod = " + normPeriod + ": needs to be '>= 0'");
        Assertion.assertStrict((maLongTicksMin > 0 && maLongTicksMax > 0), Assertion.Level.ERR, "maLongTicks needs to be '> 0'");
        Assertion.assertStrict((maShortTicksMin > 0 && maShortTicksMax > 0), Assertion.Level.ERR, "maShortTicks needs to be '> 0'");
        Assertion.assertStrict((bcTicksTrendMin > 0 && bcTicksTrendMax > 0), Assertion.Level.ERR, "bcTicksTrend needs to be '> 0'");
        Assertion.assertStrict(capFactorTrend > 0, Assertion.Level.ERR, "capFactorTrend needs to be '> 0'");        
        Assertion.assertStrict(volWindowTrend >= 0, Assertion.Level.ERR, "volWindowTrend needs to be '>= 0'");
        Assertion.assertStrict(probShortSellingTrend >= 0 && probShortSellingTrend <= 1 , Assertion.Level.ERR, "probShortSellingTrend needs to be between 0 and 1");
        Assertion.assertStrict((entryThresholdMin > 0 && entryThresholdMax > 0), Assertion.Level.ERR, "entryThreshold needs to be '> 0'");
//        Assertion.assertStrict((exitThresholdMin > 0 && exitThresholdMax > 0), Assertion.Level.ERR, "exitThreshold needs to be '> 0'");
        Assertion.assertStrict((bcTicksFundMin > 0 && bcTicksFundMax > 0), Assertion.Level.ERR, "bcTicksFund needs to be '> 0'");
        Assertion.assertStrict(capFactorFund > 0, Assertion.Level.ERR, "capFactorFund needs to be '> 0'");
        Assertion.assertStrict(probShortSellingValue >= 0 && probShortSellingValue <= 1 , Assertion.Level.ERR, "probShortSellingValue needs to be between 0 and 1");
        Assertion.assertStrict((maSpreadShortTicksMin > 0 && maSpreadShortTicksMax > 0), Assertion.Level.ERR, "maSpreadShortTicks needs to be '> 0'");
        Assertion.assertStrict((maSpreadLongTicksMin > 0 && maSpreadLongTicksMax > 0), Assertion.Level.ERR, "maSpreadLongTicks needs to be '> 0'");
        Assertion.assertStrict(capFactorLS > 0, Assertion.Level.ERR, "capFactorLS needs to be '> 0'");
        Assertion.assertStrict(volWindowLS >= 0, Assertion.Level.ERR, "volWindowLS needs to be '>= 0'");
        Assertion.assertStrict((entryDivergenceSigmasMin > 0 && entryDivergenceSigmasMax > 0), Assertion.Level.ERR, "entryDivergenceSigmas needs to be '> 0'");
        Assertion.assertStrict((exitConvergenceSigmasMin >= 0 && exitConvergenceSigmasMax >= 0), Assertion.Level.ERR, "exitConvergenceSigmas needs to be '> 0'");
        Assertion.assertStrict((exitStopLossSigmasMin > 0 && exitStopLossSigmasMax > 0), Assertion.Level.ERR, "exitStopLossSigmas needs to be '> 0'");

        /**
         * VALIDATE sequences: shift, amplitude, lag, lambda, mu, sigma
         */
        validateDoubleSequence(Sequence.SHIFT_PRICE);
        validateDoubleSequence(Sequence.AMPLITUDE_PRICE);
        validateDoubleSequence(Sequence.LAG_PRICE);
        validateDoubleSequence(Sequence.LAMBDA_PRICE);
        validateDoubleSequence(Sequence.MU_PRICE);
        validateDoubleSequence(Sequence.SIGMA_PRICE);
        validateDoubleSequence(Sequence.PRICE_0);
        validateDoubleSequence(Sequence.LIQUIDITY);
        validateDoubleSequence(Sequence.SHIFT_VALUE);
        validateDoubleSequence(Sequence.AMPLITUDE_VALUE);
        validateDoubleSequence(Sequence.LAG_VALUE);
        validateDoubleSequence(Sequence.LAMBDA_VALUE);
        validateDoubleSequence(Sequence.MU_VALUE);
        validateDoubleSequence(Sequence.SIGMA_VALUE);

        
        /**
         * Validate combinations of parameters
         */
        boolean validated_p1 = false;
        boolean validated_p2 = false;
        boolean validated_v1 = false;
        boolean validated_v2 = false;

        
        /*
         * Validate sinus generator and Brownian process parameters. The 
         * values have to be all omitted or all provided for either the
         * sinus generator or the Brownian process.
         *  
         * In the multi-asset case, the same validation applies to all
         * processes.
         */
        validated_p1 = (shift_price.isEmpty() && amplitude_price.isEmpty() && lag_price.isEmpty() && lambda_price.isEmpty()) ||
                      (!shift_price.isEmpty() && !amplitude_price.isEmpty() && !lag_price.isEmpty() && !lambda_price.isEmpty());
        validated_p2 = (mu_price.isEmpty() && sigma_price.isEmpty() ||
                      (!mu_price.isEmpty() && !sigma_price.isEmpty()));
        
        Assertion.assertStrict((validated_p1 == true) && (validated_p2 == true), Level.ERR, "Parameters for the the exogenous price process are not well-defined " +
        		"(some are provided while others are omitted for either the sinus generator or the Brownian process)");
        
        
        validated_v1 = (shift_value.isEmpty() && amplitude_value.isEmpty() && lag_value.isEmpty() && lambda_value.isEmpty()) ||
        		(!shift_value.isEmpty() && !amplitude_value.isEmpty() && !lag_value.isEmpty() && !lambda_value.isEmpty());
        validated_v2 = (mu_value.isEmpty() && sigma_value.isEmpty() ||
                (!mu_value.isEmpty() && !sigma_value.isEmpty()));
  
        Assertion.assertStrict((validated_v1 == true) && (validated_v2 == true), Level.ERR, "Parameters for the the exogenous value process are not well-defined " +
        		"(some are provided while others are omitted for either the sinus generator or the Brownian process)");

        
        
        // TODO The length of the sequences needs to be the same --> validate
        
        // TODO If one sequence param is optional, they all should be optional
        
        return true; 
    }

    /*
    * DELETE? - This verification is done above, so the next method is not needed
    */
//    public boolean isDefinedExogenousProcess() {
//        
//        boolean isDefined = (!shift.isEmpty() && !amplitude.isEmpty() && !lag.isEmpty() && !lambda.isEmpty()) ||
//                            (!mu_price.isEmpty() && !sigma_price.isEmpty());
//
//        return isDefined;
//    }
    
    
    /**
     * Creates an xml file that holds the fields of this object
     * 
     * @param file
     * @throws FileNotFoundException 
     */
    public static void writeParamDefinition(String file) throws FileNotFoundException {
        writeParamsDefinition(file, new TrendValueLSAbmParams());
    }

    /**
     * Reads values from an xml file and initialises the fields of the newly created parameter object
     * 
     * @param file
     * @return
     * @throws FileNotFoundException 
     */
    public static TrendValueLSAbmParams readParameters(String file) throws FileNotFoundException {

        TrendValueLSAbmParams params = (TrendValueLSAbmParams) readParams(file, new TrendValueLSAbmParams());
        params.initialiseSequenceParams();
        params.validate();
        return params;
    }
    
}
