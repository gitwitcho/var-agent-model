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
package info.financialecology.finance.utilities.test;

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
 * Testing the different formats in which parameters can be provided in the XML file 
 * 
 * Single integer: 4
 * Single double: -54.643
 * Single integer interval: [5, 9]
 * Single double interval: [-2.5, 34.2736]
 * 
 * Sequence of integers: 5, 10, -3, 6, 1
 * Sequence of doubles: 1.354, 9.3527, -324.4563
 * Sequence of integer intervals: [3, 6], [-12, -4], [0, 9]
 * Sequence of double intervals: [-0.34, 2.43], [323.34, 5432.342]
 * 
 * Iterator (doubles): c(1:4) = 1, 2, 3, 4
 * Iterator (doubles): c(1:2:4) = 1.0, 1.333, 1.666, 2.0
 * Repeat number (doubles): rep(9, 3) = 9, 9, 9
 * Repeat interval (doubles): rep([1,4],2) = [1,4],[1,4]
 *
 * 
 * @author Gilbert Peffer
 *
 */
public class TestParamsSetup extends SimulationParameters {
    
    private static final Logger logger = (Logger)LoggerFactory.getLogger(TestParamsSetup.class.getSimpleName());
    
    /**
     * 
     *      PARAMETER DECLARATIONS
     *      ======================
     *      
     * 
     */

    public int numberInteger;      // an integer
    public double numberDouble;    // an integer
    
    public String integerInterval   = "NAN";    // an integer interval
    public String doubleInterval    = "NAN";    // a double interval
    
    public String integerSequence   = "NAN";    // an integer sequence
    public String doubleSequence    = "NAN";    // a double sequence
    
    public String integerIntervalSequence   = "NAN";    // an integer interval sequence
    public String doubleIntervalSequence    = "NAN";    // a double interval sequence
    
    public String iteratorTwo       = "NAN";    // an iterator of type c(a:b)
    public String iteratorThree     = "NAN";    // an iterator of type c(a:b:c)
    public String repeatNumber      = "NAN";    // a repeater of type rep(a,b)
    public String repeatInterval    = "NAN";    // a repeater of type rep([a,b],c)
    
    
    /*
     * This enum defines all parameters of non-primitive type. Non-primitive types are declared as 
     * Strings in the XML parameter file and then internally transformed to the corresponding data 
     * types. 
     */
    public enum Sequence implements ParamSequence {
        
        /**
         *  Parameters
         *  ----------
         *      - item type (as defined in enum Item)
         *      - optional: true, if the parameter is optional
         */
        INTEGER_INTERVAL(Item.INTEGER_INTERVAL, false),
        DOUBLE_INTERVAL(Item.DOUBLE_INTERVAL, false),
        INTEGER_SEQUENCE(Item.INTEGER_SEQ, false),
        DOUBLE_SEQUENCE(Item.DOUBLE_SEQ, false),
        INTEGER_INTERVAL_SEQUENCE(Item.INTEGER_INTERVAL_SEQ, false),
        DOUBLE_INTERVAL_SEQUENCE(Item.DOUBLE_INTERVAL_SEQ, false),
        ITERATOR_TWO(Item.DOUBLE_SEQ, false),
        ITERATOR_THREE(Item.DOUBLE_SEQ, false),
        REPEAT_NUMBER(Item.DOUBLE_SEQ, false),
        REPEAT_INTERVAL(Item.DOUBLE_INTERVAL_SEQ, false);

        private String param;
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
    
    TestParamsSetup() {}
    
    
    /**
     * Add the string of the sequence, interval, or interval sequence to the corresponding enum
     */
    private void initialiseSequenceParams() {
        Sequence.INTEGER_INTERVAL.setParamString(integerInterval);
        Sequence.DOUBLE_INTERVAL.setParamString(doubleInterval);
        Sequence.INTEGER_SEQUENCE.setParamString(integerSequence);
        Sequence.DOUBLE_SEQUENCE.setParamString(doubleSequence);
        Sequence.INTEGER_INTERVAL_SEQUENCE.setParamString(integerIntervalSequence);
        Sequence.DOUBLE_INTERVAL_SEQUENCE.setParamString(doubleIntervalSequence);
        Sequence.ITERATOR_TWO.setParamString(iteratorTwo);
        Sequence.ITERATOR_THREE.setParamString(iteratorThree);
        Sequence.REPEAT_NUMBER.setParamString(repeatNumber);
        Sequence.REPEAT_INTERVAL.setParamString(repeatInterval);
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
        
        /**
         * VALIDATE sequences: shift, amplitude, lag, lambda, mu, sigma
         */
        validateDoubleSequence(Sequence.INTEGER_INTERVAL);
        validateDoubleSequence(Sequence.DOUBLE_INTERVAL);
        validateDoubleSequence(Sequence.INTEGER_SEQUENCE);
        validateDoubleSequence(Sequence.DOUBLE_SEQUENCE);
        validateDoubleSequence(Sequence.INTEGER_INTERVAL_SEQUENCE);
        validateDoubleSequence(Sequence.INTEGER_INTERVAL_SEQUENCE);
        
        return true; 
    }

    
    /**
     * Creates an xml file that holds the fields of this object
     * 
     * @param file
     * @throws FileNotFoundException 
     */
    public static void writeParamDefinition(String file) throws FileNotFoundException {
        writeParamsDefinition(file, new TestParamsSetup());
    }

    /**
     * Reads values from an xml file and initialises the fields of the newly created parameter object
     * 
     * @param file
     * @return
     * @throws FileNotFoundException 
     */
    public static TestParamsSetup readParameters(String file) throws FileNotFoundException {

        TestParamsSetup params = (TestParamsSetup) readParams(file, new TestParamsSetup());
        params.initialiseSequenceParams();
        params.validate();
        return params;
    }

    
}
