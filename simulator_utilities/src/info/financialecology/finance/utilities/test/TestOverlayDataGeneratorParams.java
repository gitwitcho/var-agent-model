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
import info.financialecology.finance.utilities.datastruct.SimulationParameters.Item;

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

public class TestOverlayDataGeneratorParams extends SimulationParameters {
    
    private static final Logger logger = (Logger)LoggerFactory.getLogger(TestOverlayDataGeneratorParams.class.getSimpleName());
    
    /**
     * 
     *      PARAMETER DECLARATIONS
     *      ======================
     *      
     * 
     */

    public int nTicks           = 0;       // number of ticks in the simulation run
    public String distParam_1;             // first parameter for the distributions
    public String distParam_2;             // second parameter for the distributions 
    public String distParam_3;             // third parameter for the distributions
    public String distParam_4;             // fourth parameter for the distributions
    public String distParam_5;             // fifth parameter for the distributions 
    public String distParam_6;             // sixth parameter for the distributions 
    
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
    	DIST_PARAM_1(Item.DOUBLE_SEQ, false),
    	DIST_PARAM_2(Item.DOUBLE_SEQ, false),
    	DIST_PARAM_3(Item.DOUBLE_SEQ, false),
    	DIST_PARAM_4(Item.DOUBLE_SEQ, false),
    	DIST_PARAM_5(Item.DOUBLE_SEQ, false),
    	DIST_PARAM_6(Item.DOUBLE_SEQ, false);
        
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
    
    TestOverlayDataGeneratorParams() {}
    
    /**
     * Add the string of the sequence, interval, or interval sequence to the corresponding enum
     */
    private void initialiseSequenceParams() {
        Sequence.DIST_PARAM_1.setParamString(distParam_1);
        Sequence.DIST_PARAM_2.setParamString(distParam_2);
        Sequence.DIST_PARAM_3.setParamString(distParam_3);
        Sequence.DIST_PARAM_4.setParamString(distParam_4);
        Sequence.DIST_PARAM_5.setParamString(distParam_5);
        Sequence.DIST_PARAM_6.setParamString(distParam_6);
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

        /**
         * VALIDATE sequences: parameters of the sinus/stepped function and the random generator 
         */
        validateDoubleSequence(Sequence.DIST_PARAM_1);
        validateDoubleSequence(Sequence.DIST_PARAM_2);
        validateDoubleSequence(Sequence.DIST_PARAM_3);
        validateDoubleSequence(Sequence.DIST_PARAM_4);
        validateDoubleSequence(Sequence.DIST_PARAM_5);
        validateDoubleSequence(Sequence.DIST_PARAM_6);
        
        /**
         * Validate combinations of parameters
         */
        boolean validated_1 = false;
        boolean validated_2 = false;
        
        /*
         * Validate sinus/stepped generator and random generator parameters. The 
         * values have to be all omitted or all provided for either the
         * sinus/stepped generator or the random generator.
         *  
         * In the multi-asset case, the same validation applies to all processes.
         */
        validated_1 = (distParam_1.isEmpty() && distParam_2.isEmpty() && distParam_3.isEmpty() && distParam_4.isEmpty()) ||
                      (!distParam_1.isEmpty() && !distParam_2.isEmpty() && !distParam_3.isEmpty() && !distParam_4.isEmpty());
        validated_2 = (distParam_5.isEmpty() && distParam_6.isEmpty()) ||
                      (!distParam_5.isEmpty() && !distParam_6.isEmpty());
        
        Assertion.assertStrict((validated_1 == true) && (validated_2 == true), Level.ERR, "Parameters are not well-defined " +
        		"(some are provided while others are omitted for either the sinus/stepped function or the random generator)");
        
        // TODO The length of the sequences needs to be the same --> validate
        
        // TODO If one sequence param is optional, they all should be optional
        
        return true; 
    }
    
    /**
     * Creates an xml file that holds the fields of this object
     * 
     * @param file
     * @throws FileNotFoundException 
     */
    public static void writeParamDefinition(String file) throws FileNotFoundException {
        writeParamsDefinition(file, new TestOverlayDataGeneratorParams());
    }
    
    
    /**
     * Reads values from an xml file and initialises the fields of the newly created parameter object
     * 
     * @param file
     * @return
     * @throws FileNotFoundException 
     */
    public static TestOverlayDataGeneratorParams readParameters(String file) throws FileNotFoundException {

    	TestOverlayDataGeneratorParams params = (TestOverlayDataGeneratorParams) readParams(file, new TestOverlayDataGeneratorParams());
        params.initialiseSequenceParams();
        params.validate();
        return params;
    }
}
