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
package info.financialecology.finance.abm.simulation;

import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.datastruct.SimulationParameters;

import java.io.FileNotFoundException;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import cern.colt.list.DoubleArrayList;
import cern.colt.list.IntArrayList;


/**
 * A simple parameter class that uses xstream to read and write object parameters from and to files.
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
public class LPLSEqnParams extends SimulationParameters {
    
    private static final Logger logger = (Logger)LoggerFactory.getLogger(LPLSEqnParams.class.getSimpleName());
    
    /**
     * 
     *      PARAMETER DECLARATIONS
     *      ======================
     *      
     *      Abbreviations
     *      -------------
     *          MF: mutual fund
     *          HF: hedge fund
     *          B: bank
     *          FUND: fundamental strategy
     *          TREND: trend following strategy
     *          LS: long-short strategy
     *          
     *      
     * 
     */

    //      MARKET PARAMETERS

    public int nRuns                = 0;        // number of simulation runs
    public int nTicks               = 0;        // number of ticks per simulation run
    public int nAssets              = 0;        // number of assets
    public int nValueInvestors      = 0;        // number of value investors
    public int nLongShortInvestors  = 0;        // number of long-short investors
    public int nTrendFollowers      = 0;        // number of trend followers
    public int nAgents              = 0;        // optional: total number of agents (proportional - nMutualFunds : nHedgeFunds : nBanks)

    public boolean constCapFac      = true;     // whether agents use a constant capital factor

    // Market - for each ASSET
    public String liquidity         = "NAN";   // asset liquidities: Array{liquidity_i}
    public String price_0           = "NAN";   // initial asset prices: Array{price_0_i} 
    public String priceNoise        = "NAN";   // asset price noise processes: N[mean, vol] 
    public String refValue          = "NAN";   // asset reference log-value processes: N[mean, vol] 

    
    //      AGENT PARAMETERS

    // All agents
    public String cash              = "NAN";    // agent's initial cash: range defined by U[min, max]
    
    // Value investor, for each ASSET
    public String offsetValue       = "NAN";    // asset and investor-specific value offsets: ranges defined by Array{U[min_i, max_i]} 
    
    // Value investor
    public String entryVALUE          = "NAN";    // investor-specific entry threshold: range defined by U[min, max] 
    public String exitVALUE        = "NAN";    // investor-specific exit thresholds: range defined by U[min, max]
    public double aVALUE          = 0.0;      // scale parameter for capital assignment

    public Boolean shortSellingAllowed_VALUE   = false;   // short selling constraint (true: short selling allowed; false: no short selling allowed)
    public Boolean borrowingAllowed_VALUE      = false;   // borrowing constraint (true: can borrow unlimited amounts of cash; false: cannot borrow) 

    // Long-short investor
    public String entryLS                = "NAN";   // interval vector [min, max] for uniform distributions of trader-specific entry thresholds
    public String exitLS              = "NAN";   // interval vector [min, max] for uniform distributions of trader-specific exit thresholds
    public String mawinLS            = "NAN";    // interval vector [min, max] for uniform distributions of trader-specific moving average window
    public String returnPeriodLS     = "NAN";    // interval vector [min, max] for uniform distributions of trader-specific period over which return is calculated
    public double aLS                = 0.0;      // scale parameter for capital assignment
        
    // Trend follower
    public String entryTREND          = "NAN";    // interval vector [min, max] for uniform distributions of trader-specific entry thresholds
    public String exitTREND        = "NAN";    // interval vector [min, max] for uniform distributions of trader-specific exit thresholds
    public String delayTREND      = "NAN";    // interval vector [min, max] for uniform distributions of trader-specific delay
    public double aTREND              = 0.0;   // scale parameter for capital assignment

    public Boolean shortSellingAllowed_TREND   = false;   // short selling constraint (true: short selling allowed; false: no short selling allowed)
    public Boolean borrowingAllowed_TREND      = false;   // borrowing constraint (true: can borrow unlimited amounts of cash; false: cannot borrow) 

    public enum Item {
        NUMBER,
        INTERVAL,
        NUMBER_SEQ,
        INTERVAL_SEQ;
    }

    /*
     * This enum defines all parameters of non-primitive type. Non-primitive 
     * types are declared as Strings in the XML parameter file and then 
     * internally transformed to the corresponding data types.
     * 
     * Example: liquidity is defined as a sequence of doubles. The length
     * of that sequence is given by the method length(). In this case there
     * are as many liquidity parameters as there are assets (params.nAssets) 
     */
    public enum Sequence {
        
        /**
         *  Parameters
         *  ----------
         *      - label
         *      - primitive type
         *      - item type (as defined in enum Item)
         *      
         */
        LIQUIDITY("liquidity", Double.class, Item.NUMBER_SEQ),
        PRICE_0("price_0", Double.class, Item.NUMBER_SEQ),
        PRICE_NOISE("priceNoise",  Double.class, Item.INTERVAL_SEQ),
        REF_VALUE("refValue",  Double.class, Item.INTERVAL_SEQ),
        
        OFFSET_VALUE("offsetValue",  Double.class, Item.INTERVAL_SEQ),
        CASH("cash", Double.class, Item.INTERVAL),
        
        ENTRY_VALUE("entryVALUE", Double.class, Item.INTERVAL),
        EXIT_VALUE("exitVALUE", Double.class, Item.INTERVAL),
        
        ENTRY_LS("entryLS", Double.class, Item.INTERVAL),
        EXIT_LS("exitLS", Double.class, Item.INTERVAL),
        MA_WIN_LS("mawinLS", Integer.class, Item.INTERVAL),
        R_PERIOD_LS("returnPeriodLS", Integer.class, Item.INTERVAL),
        
        ENTRY_TREND("entryTREND", Double.class, Item.INTERVAL),
        EXIT_TREND("exitTREND", Double.class, Item.INTERVAL),
        DELAY_TREND("delayTREND", Integer.class, Item.INTERVAL);
        
        private final String label;
        private final Type type;
        private final Item itemType;

        Sequence(String label, Type type, Item itemType) { 
            this.label = label;
            this.type = type;
            this.itemType = itemType;
        }
        
        public Type type() { return type; }
        public String label() { return label; }
        public Item itemType() { return itemType; }
        
        /**
         * Some parameter sequences have to have a specific length. This method declares the length
         * of a sequence. Where there is no constraint on the length of a sequence, return '0'. Only
         * declare parameters that are sequences, not those that are single numbers or intervals 
         * 
         * @param params the parameter object
         * @return the constraint on the length of the sequence
         * 
         */
        public int length(LPLSEqnParams params) {
            switch (this) {
                case LIQUIDITY: return params.nAssets; 
                case PRICE_0: return params.nAssets;
                case PRICE_NOISE: return params.nAssets; 
                case REF_VALUE: return params.nAssets; 
                case OFFSET_VALUE: return params.nAssets;
                default:
                    if (this.itemType() == Item.INTERVAL)
                        return 1;
                    
                    Assertion.assertStrict(false, Assertion.Level.ERR, "Cannot find sequence type '" + this.label() + "'");
            }
            return -1;
        }
    }
    
    LPLSEqnParams() {}
    
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
        ArrayList<DoubleArrayList> dSeq = null; // sequences of doubles

        /**
         * 
         *      MARKET PARAMETERS
         * 
         */
            
        /**
         * VALIDATE: primitive types (nRuns, nTicks, ...)
         */
        Assertion.assertStrict(nRuns > 0, Assertion.Level.ERR, "nRuns = " + nRuns + ": needs to be '> 0'");
        Assertion.assertStrict(nTicks > 0, Assertion.Level.ERR, "nTicks = " + nTicks + ": needs to be '> 0'");
        Assertion.assertStrict(nAssets > 0, Assertion.Level.ERR, "nAssets = " + nAssets + ": needs to be '> 0'");
        Assertion.assertStrict(nValueInvestors >= 0, Assertion.Level.ERR, "nValueInvestors = " + nValueInvestors + ": needs to be '>= 0'");
        Assertion.assertStrict(nLongShortInvestors >= 0, Assertion.Level.ERR, "nLongShortInvestors = " + nLongShortInvestors + ": needs to be '>= 0'");
        Assertion.assertStrict(nTrendFollowers >= 0, Assertion.Level.ERR, "nBanks = " + nTrendFollowers + ": needs to be greater than '0'");
        Assertion.assertStrict(nAgents >= 0, Assertion.Level.ERR, "nAgents = " + nAgents + ": needs to be greater than '0'");
        
        /**
         * VALIDATE: liquidity {seq-number}
         */
        dSeq = getDoubleSequence(Sequence.LIQUIDITY);
        validateDoubleSequence(dSeq, Sequence.LIQUIDITY);
        
        for (Iterator<DoubleArrayList> i = dSeq.iterator(); i.hasNext(); )
            Assertion.assertStrict((i.next().get(0) > 0), Assertion.Level.ERR, "Parameter '" + 
                                        Sequence.LIQUIDITY.label() + "': has to be '> 0'");

        /**
         * VALIDATE: price_0 {seq-number}
         */
        dSeq = getDoubleSequence(Sequence.PRICE_0);
        validateDoubleSequence(dSeq, Sequence.PRICE_0);
        
        for (Iterator<DoubleArrayList> i = dSeq.iterator(); i.hasNext(); )
            Assertion.assertStrict((i.next().get(0) >= 0), Assertion.Level.ERR, "Parameter '" + 
                                        Sequence.PRICE_0.label() + "': has to be '>= 0'");
        
        /**
         * VALIDATE: priceNoise {seq-interval N[mu, sigma]} (one for each asset)
         */
        dSeq = getDoubleSequence(Sequence.PRICE_NOISE);
        validateDoubleSequence(dSeq, Sequence.PRICE_NOISE);
    
        for (Iterator<DoubleArrayList> i = dSeq.iterator(); i.hasNext(); ) {
            DoubleArrayList dal = i.next();
            Assertion.assertStrict(dal.get(1) >= 0, Assertion.Level.ERR, "Parameter '" + 
                                        Sequence.REF_VALUE.label() + "'(sigma): has to be '>= 0'");
        }
        
        /**
         * VALIDATE: refValue {seq-interval N[mu, sigma]} (one for each asset)
         */
        dSeq = getDoubleSequence(Sequence.REF_VALUE);
        validateDoubleSequence(dSeq, Sequence.REF_VALUE);
        
        for (Iterator<DoubleArrayList> i = dSeq.iterator(); i.hasNext(); ) {
            DoubleArrayList dal = i.next();
            Assertion.assertStrict(dal.get(1) >= 0, Assertion.Level.ERR, "Parameter '" + 
                                        Sequence.REF_VALUE.label() + "'(sigma): has to be '>= 0'");
        }
        
        
        /**
         * 
         *      AGENT PARAMETERS
         * 
         */
            
        /**
         * VALIDATE: cash {seq-number}
         */
        dSeq = getDoubleSequence(Sequence.CASH);
        validateDoubleSequence(dSeq, Sequence.CASH);
        
        /**
         * VALIDATE: offsetValue {seq-interval U[min, max]} (one for each asset)
         */
        dSeq = getDoubleSequence(Sequence.OFFSET_VALUE);
        validateDoubleSequence(dSeq, Sequence.OFFSET_VALUE);
        validateMinMaxInterval(dSeq, Sequence.OFFSET_VALUE);
        
        /**
         * VALIDATE: entryVALUE {interval U[min, max]}
         */
        dSeq = getDoubleSequence(Sequence.ENTRY_VALUE);
        validateDoubleSequence(dSeq, Sequence.ENTRY_VALUE);
        validateMinMaxInterval(dSeq, Sequence.ENTRY_VALUE);
        
        for (Iterator<DoubleArrayList> i = dSeq.iterator(); i.hasNext(); ) {
            DoubleArrayList dal = i.next();
            Assertion.assertStrict((dal.get(0) >= 0) && (dal.get(1) >= 0), Assertion.Level.ERR, "Parameter '" + 
                                        Sequence.ENTRY_VALUE.label() + "': has to be '>= 0'");
        }
        
        /**
         * VALIDATE: exitVALUE {interval U[min, max]}
         */
        dSeq = getDoubleSequence(Sequence.EXIT_VALUE);
        validateDoubleSequence(dSeq, Sequence.EXIT_VALUE);
        validateMinMaxInterval(dSeq, Sequence.EXIT_VALUE);
        
        for (Iterator<DoubleArrayList> i = dSeq.iterator(); i.hasNext(); ) {
            DoubleArrayList dal = i.next();
            // TODO add a check |tau|<|T|
//            Assertion.assertStrict((dal.get(0) >= 0) && (dal.get(1) >= 0), Assertion.Level.ERR, "Parameter '" + 
//                                        Sequence.TAU_FUND_MF.label() + "': has to be '>= 0'");
        }
        
        /**
         * VALIDATE: aVALUE {number}
         */
        Assertion.assertStrict(aVALUE >= 0, Assertion.Level.ERR, "Parameter 'aFUND' has to be '>= 0'");

        /**
        * VALIDATE: entryTREND {interval U[min, max]}
        */
        dSeq = getDoubleSequence(Sequence.ENTRY_TREND);
        validateDoubleSequence(dSeq, Sequence.ENTRY_TREND);
        validateMinMaxInterval(dSeq, Sequence.ENTRY_TREND);

        for (Iterator<DoubleArrayList> i = dSeq.iterator(); i.hasNext(); ) {
            DoubleArrayList dal = i.next();
            Assertion.assertStrict((dal.get(0) >= 0) && (dal.get(1) >= 0), Assertion.Level.ERR, "Parameter '" + 
                    Sequence.ENTRY_TREND.label() + "': has to be '>= 0'");
        }

        /**
         * VALIDATE: exitTREND {interval U[min, max]}
         */
        dSeq = getDoubleSequence(Sequence.EXIT_TREND);
        validateDoubleSequence(dSeq, Sequence.EXIT_TREND);
        validateMinMaxInterval(dSeq, Sequence.EXIT_TREND);

        for (Iterator<DoubleArrayList> i = dSeq.iterator(); i.hasNext(); ) {
            DoubleArrayList dal = i.next();
            Assertion.assertStrict((dal.get(0) >= 0) && (dal.get(1) >= 0), Assertion.Level.ERR, "Parameter '" + 
                    Sequence.EXIT_TREND.label() + "': has to be '>= 0'");
        }

        /**
         * VALIDATE: delayTREND {interval U[min, max]}
         */
        iSeq = getIntegerSequence(Sequence.DELAY_TREND);
        validateIntegerSequence(iSeq, Sequence.DELAY_TREND);
        validateMinMaxInterval(iSeq, Sequence.DELAY_TREND);

        for (Iterator<IntArrayList> i = iSeq.iterator(); i.hasNext(); ) {
            IntArrayList dal = i.next();
            Assertion.assertStrict((dal.get(0) >= 0) && (dal.get(1) >= 0), Assertion.Level.ERR, "Parameter '" + 
                    Sequence.DELAY_TREND.label() + "': has to be '>= 0'");
        }

        /**
         * VALIDATE: aTREND {number}
         */
        Assertion.assertStrict(aTREND >= 0, Assertion.Level.ERR, "Parameter 'aTREND' has to be '>= 0'");

        /**
        * VALIDATE: entryLS {interval U[min, max]}
        */
        dSeq = getDoubleSequence(Sequence.ENTRY_LS);
        validateDoubleSequence(dSeq, Sequence.ENTRY_LS);
        validateMinMaxInterval(dSeq, Sequence.ENTRY_LS);

        for (Iterator<DoubleArrayList> i = dSeq.iterator(); i.hasNext(); ) {
            DoubleArrayList dal = i.next();
            Assertion.assertStrict((dal.get(0) >= 0) && (dal.get(1) >= 0), Assertion.Level.ERR, "Parameter '" + 
                    Sequence.ENTRY_LS.label() + "': has to be '>= 0'");
        }

        /**
        * VALIDATE: exitLS {interval U[min, max]}
        */
        dSeq = getDoubleSequence(Sequence.EXIT_LS);
        validateDoubleSequence(dSeq, Sequence.EXIT_LS);
        validateMinMaxInterval(dSeq, Sequence.EXIT_LS);

        for (Iterator<DoubleArrayList> i = dSeq.iterator(); i.hasNext(); ) {
            DoubleArrayList dal = i.next();
            Assertion.assertStrict((dal.get(0) >= 0) && (dal.get(1) >= 0), Assertion.Level.ERR, "Parameter '" + 
                    Sequence.EXIT_LS.label() + "': has to be '>= 0'");
        }

        /**
         * VALIDATE: mawinLS {interval U[min, max]}
         */
        iSeq = getIntegerSequence(Sequence.MA_WIN_LS);
        validateIntegerSequence(iSeq, Sequence.MA_WIN_LS);
        validateMinMaxInterval(iSeq, Sequence.MA_WIN_LS);

        for (Iterator<IntArrayList> i = iSeq.iterator(); i.hasNext(); ) {
            IntArrayList dal = i.next();
            Assertion.assertStrict((dal.get(0) >= 0) && (dal.get(1) >= 0), Assertion.Level.ERR, "Parameter '" + 
                    Sequence.MA_WIN_LS.label() + "': has to be '>= 0'");
        }

        /**
         * VALIDATE: returnPeriodLS {interval U[min, max]}
         */
        iSeq = getIntegerSequence(Sequence.R_PERIOD_LS);
        validateIntegerSequence(iSeq, Sequence.R_PERIOD_LS);
        validateMinMaxInterval(iSeq, Sequence.R_PERIOD_LS);

        for (Iterator<IntArrayList> i = iSeq.iterator(); i.hasNext(); ) {
            IntArrayList dal = i.next();
            Assertion.assertStrict((dal.get(0) >= 0) && (dal.get(1) >= 0), Assertion.Level.ERR, "Parameter '" + 
                    Sequence.R_PERIOD_LS.label() + "': has to be '>= 0'");
        }

        /**
         * VALIDATE: aLS {number}
         */
        Assertion.assertStrict(aLS >= 0, Assertion.Level.ERR, "Parameter 'aLS' has to be '>= 0'");

        return true; 
    }
    
    private void validateIntegerSequence(ArrayList<IntArrayList> iSeq, Sequence sequence) {
        Assertion.assertStrict(iSeq.size() > 0, Assertion.Level.ERR, "Parameter missing: '" + sequence.label() + "'");
        
        if (sequence.itemType() == Item.NUMBER_SEQ)
            Assertion.assertStrict((iSeq.get(0).size() == 1), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected numbers, not intervals");
        else if (sequence.itemType() == Item.INTERVAL_SEQ)
            Assertion.assertStrict((iSeq.get(0).size() == 2), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected intervals, not numbers");
        else if (sequence.itemType() == Item.INTERVAL)
            Assertion.assertStrict(((iSeq.get(0).size() == 2) || (iSeq.size() > 1)), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected single interval");
        else
            Assertion.assertStrict(false, Assertion.Level.ERR, "Can't validate for this item type");    // TODO add label (string) to Item to identify item type
        
        expandIntegerSequence(iSeq, sequence);

        Assertion.assertStrict((iSeq.size() == sequence.length(this)) && (sequence.length(this) != 0), Assertion.Level.ERR, "Number of '" + sequence.label() + "' " +
                "parameters (" + iSeq.size() + ") has to be equal to " + sequence.length(this));
    }
    
    private void validateDoubleSequence(ArrayList<DoubleArrayList> dSeq, Sequence sequence) {
        Assertion.assertStrict(dSeq.size() > 0, Assertion.Level.ERR, "Parameter missing: '" + sequence.label() + "'");
        
        if (sequence.itemType() == Item.NUMBER_SEQ)
            Assertion.assertStrict((dSeq.get(0).size() == 1), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected numbers, not intervals");
        else if (sequence.itemType() == Item.INTERVAL_SEQ)
            Assertion.assertStrict((dSeq.get(0).size() == 2), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected numbers, not intervals");
        else if (sequence.itemType() == Item.INTERVAL)
            Assertion.assertStrict(((dSeq.get(0).size() == 2) || (dSeq.size() > 1)), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected single interval");
        else
            Assertion.assertStrict(false, Assertion.Level.ERR, "Can't validate for this item type");    // TODO add label (string) to Item to identify item type
        
        expandDoubleSequence(dSeq, sequence);

        Assertion.assertStrict((dSeq.size() == sequence.length(this)) && (sequence.length(this) != 0), Assertion.Level.ERR, "Number of '" + sequence.label() + "' " +
                "parameters (" + dSeq.size() + ") has to be equal to " + sequence.length(this));
    }
        
    @SuppressWarnings({ "unchecked", "rawtypes" })
    private void validateMinMaxInterval(ArrayList dSeq, Sequence sequence) {
        ArrayList<IntArrayList> ial;
        ArrayList<DoubleArrayList> dal;
        
        if (sequence.type == Integer.class) {
            ial = (ArrayList<IntArrayList>) dSeq;
            for (int i = 0; i < ial.size(); i++) {
                Assertion.assertStrict(ial.get(i).size() == 2, Assertion.Level.ERR, "Error in 'validateMinMaxInterval': expected interval");
                Assertion.assertStrict(ial.get(i).get(0) <= ial.get(i).get(1), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': " +
                		"the lower bound of intervals has to be smaller or equal to their upper bound");
            }
        }
        else if (sequence.type == Double.class) {
            dal = (ArrayList<DoubleArrayList>) dSeq;
            for (int i = 0; i < dal.size(); i++) {
                Assertion.assertStrict(dal.get(i).size() == 2, Assertion.Level.ERR, "Error in 'validateMinMaxInterval': expected interval");
                Assertion.assertStrict(dal.get(i).get(0) <= dal.get(i).get(1), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': " +
                        "the lower bound of intervals has to be smaller or equal to their upper bound");
            }
        }
    }
    
    /**
     * Though there is some redundancy, these functions are still useful because of better readability 
     */
    
    public ArrayList<IntArrayList> getIntegerNumberSequence(Sequence sequence) {
        ArrayList<IntArrayList> iSeq = getIntegerSequence(sequence);
        validateIntegerSequence(iSeq, sequence);
        return iSeq;
    }
    
    public ArrayList<IntArrayList> getIntegerInterval(Sequence sequence) {
        return getIntegerIntervalSequence(sequence);
    }
    
    public ArrayList<IntArrayList> getIntegerIntervalSequence(Sequence sequence) {
        ArrayList<IntArrayList> iSeq = getIntegerSequence(sequence);
        validateIntegerSequence(iSeq, sequence);
        return iSeq;
    }
        
    public ArrayList<DoubleArrayList> getDoubleNumberSequence(Sequence sequence) {
        ArrayList<DoubleArrayList> dSeq = getDoubleSequence(sequence);
        validateDoubleSequence(dSeq, sequence);
        return dSeq;
    }
    
    public ArrayList<DoubleArrayList> getDoubleInterval(Sequence sequence) {
        return getDoubleIntervalSequence(sequence);
    }
    
    public ArrayList<DoubleArrayList> getDoubleIntervalSequence(Sequence sequence) {
        ArrayList<DoubleArrayList> dSeq = getDoubleSequence(sequence);
        validateDoubleSequence(dSeq, sequence);
        return dSeq;
    }
    
    /**
     * Transforms a sequence of strings into integers or intervals of integers. Checks whether the sequence
     * contains integers rather than doubles
     * 
     * Returns a sequence of single numbers or of intervals
     */
    private ArrayList<IntArrayList> getIntegerSequence(Sequence sequence) {
        ArrayList<IntArrayList> intSeq = new ArrayList<IntArrayList>();
        ArrayList<String> seq = null;
        String s = null;
        
        // TODO use reflection to access the field, based on sequence.label
        switch (sequence) {
            case DELAY_TREND: s = delayTREND;
                break;
            case MA_WIN_LS: s = mawinLS;
                break;
            case R_PERIOD_LS: s = returnPeriodLS;
                break;
            default:
                Assertion.assertStrict(false, Assertion.Level.ERR, "Unkown sequence type passed into 'getIntegerSequence'");
        }
        
        seq = parseParamSequence(s);
        
        if (s.indexOf("[") == -1) {   // a sequence of numbers, not intervals
            for (int i = 0; i < seq.size(); i++) {
                IntArrayList value = new IntArrayList(new int [] {0});     // forces the array to be initialised, otherwise 'set' won't work
                Assertion.assertStrict(isInteger(seq.get(i)), Assertion.Level.ERR, "The values in " + s + " = " + seq + " have to be integers");
                value.set(0, Integer.valueOf(seq.get(i)));
                intSeq.add(value);
            }
        }
        else {        // is it a sequence of intervals?
            String [] item;

            for (int i = 0; i < seq.size(); i++) {
                IntArrayList interval = new IntArrayList(new int [] {0,0});     // forces the array to be initialised, otherwise 'set' won't work
                item = seq.get(i).replace("[", "").split("[\\[\\],]");
                Assertion.assertStrict(isInteger(item[0]) && isInteger(item[1]), Assertion.Level.ERR, "The values in " + s + " = " +  seq + " have to be integers");
                interval.set(0, Integer.valueOf(item[0]));
                interval.set(1, Integer.valueOf(item[1]));
                intSeq.add(interval);
            }
        }
        
        if ((intSeq.size() == 1) && (sequence.length(this) > 1))   // one item of the sequence is provided, copy if more are required
            expandIntegerSequence(intSeq, sequence);
        
        Assertion.assertStrict((intSeq.size() == sequence.length(this)) && (sequence.length(this) != 0), Assertion.Level.ERR, intSeq.size() + " items in the sequence '" + sequence.label + 
                "', different to the " + sequence.length(this) + " required");

        return intSeq;
    }
    
    /**
     * Transforms a sequence of strings into doubles or intervals of doubles
     */
    private ArrayList<DoubleArrayList> getDoubleSequence(Sequence sequence) {
        ArrayList<DoubleArrayList> doubleSeq = new ArrayList<DoubleArrayList>();
        ArrayList<String> seq = null;
        String s = null;
        
        switch (sequence) {
            case LIQUIDITY: s = liquidity;
                break;
            case PRICE_0: s = price_0;
                break;
            case CASH: s = cash;
                break;
            case PRICE_NOISE: s = priceNoise;
                break;
            case REF_VALUE: s = refValue;
                break;
            case OFFSET_VALUE: s = offsetValue;
                break;
            case ENTRY_VALUE: s = entryVALUE;
                break;
            case EXIT_VALUE: s = exitVALUE;
                break;
            case ENTRY_LS: s = entryLS;
                break;
            case EXIT_LS: s = exitLS;
                break;
            case ENTRY_TREND: s = entryTREND;
                break;
            case EXIT_TREND: s = exitTREND;
                break;
            default:
                Assertion.assertStrict(false, Assertion.Level.ERR, "Unkown sequence type '" + sequence.label() + "' " +
                		"passed into 'getDoubleSequence'");
        }
        
        seq = parseParamSequence(s);
        
        if (s.indexOf("[") == -1) {   // a sequence of numbers, not intervals
            for (int i = 0; i < seq.size(); i++) {
                DoubleArrayList value = new DoubleArrayList(new double [] {0.0});     // forces the array to be initialised, otherwise 'set' won't work
                value.set(0, Double.valueOf(seq.get(i)));
                doubleSeq.add(value);
            }
        }
        else {        // is it a sequence of intervals?
            String [] item;

            for (int i = 0; i < seq.size(); i++) {
                DoubleArrayList interval = new DoubleArrayList(new double [] {0.0,0.0});     // forces the array to be initialised, otherwise 'set' won't work
                item = seq.get(i).replace("[", "").split("[\\[\\],]");
                interval.set(0, Double.valueOf(item[0]));
                interval.set(1, Double.valueOf(item[1]));
                doubleSeq.add(interval);
            }
        }
        
        if ((doubleSeq.size() == 1) && (sequence.length(this) > 1))   // one item of the sequence is provided, copy if more are required
            expandDoubleSequence(doubleSeq, sequence);
        
        Assertion.assertStrict((doubleSeq.size() == sequence.length(this)) && (sequence.length(this) != 0), Assertion.Level.ERR, doubleSeq.size() + " items in the sequence '" + sequence.label + 
                "', different to the " + sequence.length(this) + " required");
        
        return doubleSeq;
    }
    
    /**
     * 
     * @param s
     * @return
     */
    private static ArrayList<String> parseParamSequence(String s) {
        ArrayList<String> seq = new ArrayList<String>();
        String [] vec = null;
        String [] vec2 = null;
        String [] vec3 = null;

        s = s.replaceAll("\\s","");                 // remove all white spaces
               
//        logger.trace("{}", s + "-");
        String s_ext = s + "-";     // closing paranethesis is at last position of sting, so for 'split' to work we append an arbitrary character
//        logger.trace("{} {}", s_ext.split("\\(").length, s_ext.split("\\)").length);
        Assertion.assertStrict(s_ext.split("\\(").length == s_ext.split("\\)").length, Assertion.Level.ERR, "The number of open and close parentheses doesn't coincide in '" + s + "'");
        Assertion.assertStrict(s.split("\\(").length <= 2, Assertion.Level.ERR, "The expression '" + s + "' has to contain no or exactly one set of round parentheses");
        
        int nOpen = s.split("\\[").length - 1;
        int nClose = s.split("\\]").length - 1;
        int nColons = 0;
        
        if ((s.startsWith("[")) && (s.endsWith("]")))    // a single interval
            nOpen = nClose = 1;
        
        Assertion.assertStrict(nOpen == nClose, Assertion.Level.ERR, "The number of open and close square brackets doesn't coincide");

        vec = s.split("\\(");     // Command
        if (vec.length > 1)
            nColons = vec[1].split(":").length - 1;
        
        /**
         * Parsing sequences
         * 
         * c(1,2,3,4)
         * c([1,2],[3,4],[5,6])
         * c(1:4) = 1,2,3,4
         * c(1:2:4) = 0.5,1.0,1.5,2.0 - '4' is the repeater argument
         * rep(9,3) = 9,9,9
         * rep([1,4],2) = [1,4],[1,4]
         * 
         */
        if (vec.length == 1) {   // either a single number or interval
            if (nOpen == 0) {   // a single number
                Assertion.assertStrict(isNumber(s), Assertion.Level.ERR, "The expression " + s + " is not a numeric");
                seq.add(s);
            }
            else if (nOpen == 1) {  // an interval
                vec = s.split("[\\[\\],]");
                for (int i = 0; i < vec.length; i++)
                    if (isNumber(vec[i]))
                        seq.add(vec[i]);
                Assertion.assertStrict(seq.size() == 2, Assertion.Level.ERR, "The interval " + s + " has to contain two numbers");
                String interval = "[" + seq.get(0) + "," + seq.get(1) + "]";
                seq.clear();
                seq.add(interval);
            }
        }
        else if (vec[0].equalsIgnoreCase("c")) {

            if (nOpen == 0) {       // single numbers, not intervals
                if (nColons == 0) {    // no repeaters
                    vec2 = vec[1].split("[\\),]");
                    seq = new ArrayList<String>(Arrays.asList(vec2));
                }
                else {      // single numbers, repeaters
                    double start, end;
                    int points;
                    Assertion.assertStrict(nColons <= 2, Assertion.Level.ERR, "There cannot be more than two columns in the expression for command 'c'");
                    vec2 = vec[1].split("[\\):]");
                    seq = new ArrayList<String>(Arrays.asList(vec2));
                    Boolean isDoubleSequence = false;
                    

                    if (!isInteger(seq.get(0)) || !isInteger(seq.get(1))) {   // if the upper or lower bound is a double, then assume the sequence is a double
                        isDoubleSequence = true;
                        Assertion.assertStrict(nColons == 2, Assertion.Level.ERR, "You must specify the number of elements for a sequence of doubles");
                        points = Integer.valueOf(seq.get(2));
                    }
                    else {  // upper an lower bound are both integers
                        points = Integer.valueOf(seq.get(1)) - Integer.valueOf(seq.get(0)) + 1;

                        if (nColons == 1) {     // if no repeater is provided, the sequence is integer
                            isDoubleSequence = false;
                        }
                        else {  // a repeater is provided
                            if (((Math.abs(points) - 1) % (Integer.valueOf(seq.get(2)) - 1)) != 0)
                                isDoubleSequence = true;   // if the repeater doesn't split the interval along integer points, the sequence is double
                            points = Integer.valueOf(seq.get(2));
                        }
                    }
                    
                    start = Double.valueOf(seq.get(0));     // for integer sequences, we convert all numbers to integers further below
                    end = Double.valueOf(seq.get(1));
                    
                    if (nColons == 2) {
                        Assertion.assertStrict(Math.abs(points) > 1, Assertion.Level.ERR, "Error in expression " + s + ". Number of points to generate " +
                                "has to be greater than '0'");
                        if ((points > 0) && (start > end))
                            Assertion.assertStrict(false, Assertion.Level.ERR, "Error in expression " + s + ". End has to be greater than start, " +
                                "for an increasing sequence");
                        else if ((points < 0) && (start < end))
                            Assertion.assertStrict(false, Assertion.Level.ERR, "Error in expression " + s + ". Start has to be greater than end, " +
                                "for a decreasing sequence");
                    }
                    
                    seq.clear();
                    
                    double interval = (double) end - (double) start;
                    double value;
                    
                    //  Example sequence in interval 1:9 and with three points: |1| 2 3 4 |5| 6 7 8 |9|
                    
                    for (int i = 0; i < Math.abs(points); i++) {
                        value = (double) start + (interval / (double) (Math.abs(points) - 1)) * i;
                        if (isDoubleSequence == true)
                            seq.add(Double.toString(value));
                        else
                            seq.add(Integer.toString((int) value));
                    }
                } 
            }
            else if (nOpen > 0) {        // a sequence of intervals
                Assertion.assertStrict(nColons == 0, Assertion.Level.ERR, "A sequence of intervals cannot contain a column ':'");
                vec2 = vec[1].split("[\\[\\]\\)]");
                
                for (int i = 0; i < vec2.length; i++) {
                    vec3 = vec2[i].split(",");
                    if (vec3.length == 2)
                        seq.add(vec2[i]);
                }
            }
        }
        else if (vec[0].equalsIgnoreCase("rep")) {
            
            if (nOpen == 0) {
                Assertion.assertStrict(nColons == 0, Assertion.Level.ERR, "A sequence of intervals cannot contain a column ':'");
                
                vec2 = vec[1].split("[\\),]");
                seq = new ArrayList<String>();
                
                Assertion.assertStrict(isInteger(vec2[1]), Assertion.Level.ERR, "The repeater variable in expression " + s + " has to be integers");
                
                int repeat = Integer.valueOf(vec2[1]);
               
                for (int i = 0; i < repeat; i++)
                    seq.add(vec2[0]);
            }
            else if (nOpen > 0) {
                Assertion.assertStrict(nOpen == 1, Assertion.Level.ERR, "Error in expression " + s + ". There can only be one pair of square brackets");
                vec2 = vec[1].split("[\\[\\]\\)]");

                for (int i = 0; i < vec2.length; i++) {
                    vec3 = vec2[i].split("[,]+");
                    if (vec3.length == 2) {
                        if ((vec3[0].length() == 0) && (vec3[1].length() != 0))
                            seq.add(vec3[1]);
                        else if ((vec3[1].length() == 0) && (vec3[0].length() != 0))
                            seq.add(vec3[0]);
                        else if ((vec3[0].length() != 0) && (vec3[1].length() != 0))
                            seq.add(vec2[i]);
                    }
                }
             
                Assertion.assertStrict(seq.size() == 2, Assertion.Level.ERR, "Error in expression " + s);

                Assertion.assertStrict(isInteger(seq.get(1)), Assertion.Level.ERR, "The repeater variable in expression " + s + " has to be an integer");

                String interval = "[" + seq.get(0) + "]";
                int repeat = Integer.valueOf(seq.get(1));
                seq.clear();
                
                for (int i = 0; i < repeat; i++)
                    seq.add(interval);
            }
        }
            
        return seq;
    }
    
    
    /**
     * If only one number or interval is provided where a sequence is expected, automatically add the required number of copies
     * 
     * @param dSeq
     * @param size
     */
    private void expandDoubleSequence(ArrayList<DoubleArrayList> dSeq, Sequence sequence) {
        int size = sequence.length(this);
        if ((dSeq.size() == 1) && size > 1) {    // expand sequence if only one item is provided 
            DoubleArrayList dal;            
            for (int i = 1; i < size; i++) {
                dal = new DoubleArrayList();
                dal.add(dSeq.get(0).get(0));
                if (dSeq.get(0).size() == 2)
                    dal.add(dSeq.get(0).get(1));
                dSeq.add(dal);    
            }    
        }
        else if ((dSeq.size() != size) && (sequence.length(this) != 0))
            Assertion.assertStrict(false, Assertion.Level.ERR, "Trying to expand sequence '" + sequence.label() + "' that " +
            		"contains more than one number or interval");
    }
    
    /**
     * If only one number or interval is provided where a sequence is expected, automatically add the required number of copies
     * 
     * @param iSeq
     * @param size
     */
    private void expandIntegerSequence(ArrayList<IntArrayList> iSeq, Sequence sequence) {
        int size = sequence.length(this);
        if ((iSeq.size() == 1) && size > 1) {    // expand sequence if only one item is provided 
            IntArrayList dal;            
            for (int i = 1; i < size; i++) {
                dal = new IntArrayList();
                dal.add(iSeq.get(0).get(0));
                if (iSeq.get(0).size() == 2)
                    dal.add(iSeq.get(0).get(1));
                iSeq.add(dal);    
            }    
        }
        else if ((iSeq.size() != size) && (sequence.length(this) != 0))
            Assertion.assertStrict(false, Assertion.Level.ERR, "Trying to expand sequence '" + sequence.label() + "' that " +
            		"contains more than one number or interval");
    }
    
    /**
     * Creates an xml file that holds the fields of this object
     * 
     * @param file
     * @throws FileNotFoundException 
     */
    public static void writeParamDefinition(String file) throws FileNotFoundException {
        writeParamsDefinition(file, new LPLSEqnParams());
    }

    /**
     * Reads values from an xml file and initialises the fields of the newly created parameter object
     * 
     * @param file
     * @return
     * @throws FileNotFoundException 
     */
    public static LPLSEqnParams readParameters(String file) throws FileNotFoundException {
        return (LPLSEqnParams) readParams(file, new LPLSEqnParams());
    }

    
}
