/*
 * Copyright (c) 2011-2014 Gilbert Peffer, Bàrbara Llacay
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
package info.financialecology.finance.utilities.datastruct;


import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.Assertion;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.Arrays;

import cern.colt.list.DoubleArrayList;
import cern.colt.list.IntArrayList;

import com.thoughtworks.xstream.XStream;

/**
 * 
 * c(1,2,3,4)
 * c([1,2],[3,4],[5,6])
 * c(1:4) = 1,2,3,4
 * c(1:2:4) = 0.5,1.0,1.5,2.0 - '4' is the repeater argument
 * rep(9,3) = 9,9,9
 * rep([1,4],2) = [1,4],[1,4]
 * 
 * @author Gilbert Peffer
 *
 */
public abstract class SimulationParameters {
    
    private boolean isInitialised = false;

    public enum Item {
        INTEGER,
        DOUBLE,
        INTEGER_INTERVAL,
        DOUBLE_INTERVAL,
        INTEGER_SEQ,
        DOUBLE_SEQ,
        INTEGER_INTERVAL_SEQ,
        DOUBLE_INTERVAL_SEQ;
    }
    
    /**
     * Though there is some redundancy, these functions are still useful because of better readability 
     */
    
    public IntArrayList getValidatedIntegerSequence(ParamSequence sequence) {
        
        Assertion.assertStrict(isInitialised == true, Level.ERR, "Initialise parameters before first use");
        
        ArrayList<IntArrayList> iSeq = getIntegerSequence(sequence);
        
        Assertion.assertOrKill(iSeq.get(0).size() == 1, "Expected a sequence of integers, but found a sequence of intervals");

        validateIntegerSequence(iSeq, sequence);
        
        IntArrayList arr = new IntArrayList();

        for (int i = 0; i < iSeq.size(); i++)
            arr.add(iSeq.get(i).get(0));

        return arr;
    }
    
    public DoubleArrayList getValidatedDoubleSequence(ParamSequence sequence) {
        
        Assertion.assertStrict(isInitialised == true, Level.ERR, "Initialise parameters before first use");
        
        ArrayList<DoubleArrayList> dSeq = getDoubleSequence(sequence);

        Assertion.assertOrKill(dSeq.get(0).size() == 1, "Expected a sequence of doubles, but found a sequence of doubles");

        validateDoubleSequence(sequence);
        
        DoubleArrayList arr = new DoubleArrayList();

        for (int i = 0; i < dSeq.size(); i++)
            arr.add(dSeq.get(i).get(0));

        return arr;
    }
    
    public IntArrayList getValidatedIntegerInterval(ParamSequence sequence) {
        
        Assertion.assertStrict(isInitialised == true, Level.ERR, "Initialise parameters before first use");

        ArrayList<IntArrayList> interval = getValidatedIntegerIntervalSequence(sequence);
        
        Assertion.assertOrKill(interval.size() == 1, "Expected a single interval of integers, but found one of size " + interval.size());
        
        return interval.get(0);
    }
    
    public DoubleArrayList getValidatedDoubleInterval(ParamSequence sequence) {

        Assertion.assertStrict(isInitialised == true, Level.ERR, "Initialise parameters before first use");

        ArrayList<DoubleArrayList> interval = getValidatedDoubleIntervalSequence(sequence);
        
        Assertion.assertOrKill(interval.size() == 1, "Expected a single interval of doubles, but found one of size " + interval.size());
        
        return interval.get(0);
    }
    
    public ArrayList<IntArrayList> getValidatedIntegerIntervalSequence(ParamSequence sequence) {
        Assertion.assertStrict(isInitialised == true, Level.ERR, "Initialise parameters before first use");
        ArrayList<IntArrayList> iSeq = getIntegerSequence(sequence);
        validateIntegerSequence(iSeq, sequence);
        return iSeq;
    }
        
    public ArrayList<DoubleArrayList> getValidatedDoubleIntervalSequence(ParamSequence sequence) {
        Assertion.assertStrict(isInitialised == true, Level.ERR, "Initialise parameters before first use");
//        ArrayList<DoubleArrayList> dSeq = getDoubleSequence(sequence);
        validateDoubleSequence(sequence);
        return getDoubleSequence(sequence);
    }
    
    // TODO make the same changes than for Double sequence 
    protected void validateIntegerSequence(ArrayList<IntArrayList> iSeq, ParamSequence sequence) {  
        Assertion.assertStrict(iSeq.size() > 0, Assertion.Level.ERR, "Parameter missing: '" + sequence.label() + "'");
        
        if ((sequence.itemType() == Item.INTEGER_SEQ) || (sequence.itemType() == Item.DOUBLE_SEQ))
            Assertion.assertStrict((iSeq.get(0).size() == 1), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected numbers, not intervals");
        else if ((sequence.itemType() == Item.INTEGER_INTERVAL_SEQ) || (sequence.itemType() == Item.DOUBLE_INTERVAL_SEQ))
            Assertion.assertStrict((iSeq.get(0).size() == 2), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected intervals, not numbers");
        else if ((sequence.itemType() == Item.INTEGER_INTERVAL) || (sequence.itemType() == Item.DOUBLE_INTERVAL))
            Assertion.assertStrict(((iSeq.get(0).size() == 2) || (iSeq.size() > 1)), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected single interval");
        else
            Assertion.assertStrict(false, Assertion.Level.ERR, "Can't validate for this item type");    // TODO add label (string) to Item to identify item type
        
        expandIntegerSequence(iSeq, sequence);

        Assertion.assertStrict((iSeq.size() == sequence.length(this)) || (sequence.length(this) == 0), Assertion.Level.ERR, "Number of '" + sequence.label() + "' " +
                "parameters (" + iSeq.size() + ") has to be equal to " + sequence.length(this));
    }
    
    protected void validateDoubleSequence(ParamSequence sequence) {
        
        Assertion.assertStrict(sequence.param() != null, Assertion.Level.ERR, "Missing parameter (in param file): '" + sequence.label() + "'");
        Assertion.assertStrict(!sequence.param().isEmpty() || sequence.isOptional(), Level.ERR, "Missing parameter (in param file): '" + sequence.label() + "'");
        
        if ((sequence.param() == null) || (sequence.param().isEmpty()))
            if (sequence.isOptional()) return;
//            else Assertion.assertStrict(false, Level.ERR, "");
        
        ArrayList<DoubleArrayList> dSeq = getDoubleSequence(sequence);
        Assertion.assertStrict(dSeq.size() > 0, Assertion.Level.ERR, "Parameter missing: '" + sequence.label() + "'");
                
        if ((sequence.itemType() == Item.INTEGER_SEQ) || (sequence.itemType() == Item.DOUBLE_SEQ))
            Assertion.assertStrict((dSeq.get(0).size() == 1), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected numbers, not intervals");
        else if ((sequence.itemType() == Item.INTEGER_INTERVAL_SEQ) || (sequence.itemType() == Item.DOUBLE_INTERVAL_SEQ))
            Assertion.assertStrict((dSeq.get(0).size() == 2), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected numbers, not intervals");
        else if ((sequence.itemType() == Item.INTEGER_INTERVAL) || (sequence.itemType() == Item.DOUBLE_INTERVAL))
            Assertion.assertStrict(((dSeq.get(0).size() == 2) || (dSeq.size() > 1)), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': expected single interval");
        else
            Assertion.assertStrict(false, Assertion.Level.ERR, "Can't validate for this item type");    // TODO add label (string) to Item to identify item type
        
        expandDoubleSequence(dSeq, sequence);

        Assertion.assertStrict((dSeq.size() == sequence.length(this)) || (sequence.length(this) == 0), Assertion.Level.ERR, "Number of '" + sequence.label() + "' " +
                "parameters (" + dSeq.size() + ") has to be equal to " + sequence.length(this));
    }
        
    @SuppressWarnings({ "unchecked", "rawtypes" })
    protected void validateMinMaxInterval(ArrayList dSeq, ParamSequence sequence) {
        ArrayList<IntArrayList> ial;
        ArrayList<DoubleArrayList> dal;
        
        if (sequence.type() == Integer.class) {
            ial = (ArrayList<IntArrayList>) dSeq;
            for (int i = 0; i < ial.size(); i++) {
                Assertion.assertStrict(ial.get(i).size() == 2, Assertion.Level.ERR, "Error in 'validateMinMaxInterval': expected interval");
                Assertion.assertStrict(ial.get(i).get(0) <= ial.get(i).get(1), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': " +
                        "the lower bound of intervals has to be smaller or equal to their upper bound");
            }
        }
        else if (sequence.type() == Double.class) {
            dal = (ArrayList<DoubleArrayList>) dSeq;
            for (int i = 0; i < dal.size(); i++) {
                Assertion.assertStrict(dal.get(i).size() == 2, Assertion.Level.ERR, "Error in 'validateMinMaxInterval': expected interval");
                Assertion.assertStrict(dal.get(i).get(0) <= dal.get(i).get(1), Assertion.Level.ERR, "Parameter '" + sequence.label() + "': " +
                        "the lower bound of intervals has to be smaller or equal to their upper bound");
            }
        }
    }
    
    
    /**
     * Transforms a sequence of strings into integers or intervals of integers. Checks whether the sequence
     * contains integers rather than doubles
     * 
     * Returns a sequence of single numbers or of intervals
     */
    protected ArrayList<IntArrayList> getIntegerSequence(ParamSequence sequence) {
        ArrayList<IntArrayList> intSeq = new ArrayList<IntArrayList>();
        ArrayList<String> seq = null;
        String s = sequence.param();
        
//        // TODO use reflection to access the field, based on sequence.label
//        switch (sequence) {
////            case DELAY_TREND: s = delayTREND;
////                break;
////            case MA_WIN_LS: s = mawinLS;
////                break;
////            case R_PERIOD_LS: s = returnPeriodLS;
////                break;
//            default:
//                Assertion.assertStrict(false, Assertion.Level.ERR, "Unknown sequence type passed into 'getIntegerSequence'");
//        }
        
        seq = parseParamSequence(s);
        
        if (s.indexOf("[") == -1) {   // a sequence of numbers, not intervals
            for (int i = 0; i < seq.size(); i++) {
                IntArrayList value = new IntArrayList(new int [] {0});     // forces the array to be initialised, otherwise 'set' won't work
                Assertion.assertStrict(SimulationParameters.isInteger(seq.get(i)), Assertion.Level.ERR, "The values in " + s + " = " + seq + " have to be integers");
                value.set(0, Integer.valueOf(seq.get(i)));
                intSeq.add(value);
            }
        }
        else {        // is it a sequence of intervals?
            String [] item;

            for (int i = 0; i < seq.size(); i++) {
                IntArrayList interval = new IntArrayList(new int [] {0,0});     // forces the array to be initialised, otherwise 'set' won't work
                item = seq.get(i).replace("[", "").split("[\\[\\],]");
                Assertion.assertStrict(SimulationParameters.isInteger(item[0]) && SimulationParameters.isInteger(item[1]), Assertion.Level.ERR, "The values in " + s + " = " +  seq + " have to be integers");
                interval.set(0, Integer.valueOf(item[0]));
                interval.set(1, Integer.valueOf(item[1]));
                intSeq.add(interval);
            }
        }
        
        if ((intSeq.size() == 1) && (sequence.length(this) > 1))   // one item of the sequence is provided, copy if more are required
            expandIntegerSequence(intSeq, sequence);
        
        Assertion.assertStrict((intSeq.size() == sequence.length(this)) || (sequence.length(this) == 0), Assertion.Level.ERR, intSeq.size() + " items in the sequence '" + sequence.label() + 
                "', different to the " + sequence.length(this) + " required");

        return intSeq;
    }
    
    /**
     * Transforms a sequence of strings into doubles or intervals of doubles
     */
    protected ArrayList<DoubleArrayList> getDoubleSequence(ParamSequence sequence) {
        ArrayList<DoubleArrayList> doubleSeq = new ArrayList<DoubleArrayList>();    // An ArrayList of ArrayLists so we can store both single values and intervals
        ArrayList<String> seq = null;
        String s = sequence.param();
        
//        switch (sequence) {
////            case LIQUIDITY: s = liquidity;
////                break;
////            case PRICE_0: s = price_0;
////                break;
////            case CASH: s = cash;
////                break;
////            case PRICE_NOISE: s = priceNoise;
////                break;
////            case REF_VALUE: s = refValue;
////                break;
////            case OFFSET_VALUE: s = offsetValue;
////                break;
////            case ENTRY_VALUE: s = entryVALUE;
////                break;
////            case EXIT_VALUE: s = exitVALUE;
////                break;
////            case ENTRY_LS: s = entryLS;
////                break;
////            case EXIT_LS: s = exitLS;
////                break;
////            case ENTRY_TREND: s = entryTREND;
////                break;
////            case EXIT_TREND: s = exitTREND;
////                break;
//            default:
//                Assertion.assertStrict(false, Assertion.Level.ERR, "Unknown sequence type '" + sequence.label() + "' " +
//                        "passed into 'getDoubleSequence'");
//        }
        
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
        
        Assertion.assertStrict((doubleSeq.size() == sequence.length(this)) || (sequence.length(this) == 0), Assertion.Level.ERR, doubleSeq.size() + " items in the sequence '" + sequence.label() + 
                "', different to the " + sequence.length(this) + " required");
        
        return doubleSeq;
    }
    
    /**
     * The input in the xml parameter files can be introduced in different formats (which are listed below).
     * This method analises and interprets the input string and transforms it into a sequence which can be used by the 
     * other methods.
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
        String s_ext = s + "-";     // closing parenthesis is at last position of string, so for 'split' to work we append an arbitrary character
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
                Assertion.assertStrict(SimulationParameters.isNumber(s), Assertion.Level.ERR, "The expression " + s + " is not a numeric");
                seq.add(s);
            }
            else if (nOpen == 1) {  // an interval
                vec = s.split("[\\[\\],]");
                for (int i = 0; i < vec.length; i++)
                    if (SimulationParameters.isNumber(vec[i]))
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
                    

                    if (!SimulationParameters.isInteger(seq.get(0)) || !SimulationParameters.isInteger(seq.get(1))) {   // if the upper or lower bound is a double, then assume the sequence is a double
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
                
                Assertion.assertStrict(SimulationParameters.isInteger(vec2[1]), Assertion.Level.ERR, "The repeater variable in expression " + s + " has to be integers");
                
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

                Assertion.assertStrict(SimulationParameters.isInteger(seq.get(1)), Assertion.Level.ERR, "The repeater variable in expression " + s + " has to be an integer");

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
    private void expandDoubleSequence(ArrayList<DoubleArrayList> dSeq, ParamSequence sequence) {
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
    private void expandIntegerSequence(ArrayList<IntArrayList> iSeq, ParamSequence sequence) {
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
     * @param file
     * @param params
     */
    protected static void writeParamsDefinition(String file, SimulationParameters params) throws FileNotFoundException {
        XStream xstream = new XStream();
        try {
            FileOutputStream fs = new FileOutputStream(file);
            xstream.toXML(params, fs);
        } catch (FileNotFoundException e1) {
            e1.printStackTrace();
            throw e1;
        }
    }

    /**
     * @param file
     * @param params
     */
    protected static SimulationParameters readParams(String file, SimulationParameters params) throws FileNotFoundException {
        XStream xstream = new XStream();
        try {
            FileInputStream fis = new FileInputStream(file);
            xstream.fromXML(fis, params);
            params.setInitialised(true);
        } catch (FileNotFoundException ex) {
            ex.printStackTrace();
            throw ex;
        }
        
        return params;
    }
    
    /**
     * 
     */
    public SimulationParameters() {
        super();
    }
    
    private void setInitialised(boolean isInitialised) {
        this.isInitialised = isInitialised;
    }

    public static Boolean isInteger(String str) {
        try {
            Integer.parseInt(str);
        } catch (Exception e) {
            return false;
        }
        
        return true;
    }

    public static Boolean isNumber(String str) {
        try {
            Double.parseDouble(str);
        } catch (Exception e) {
            return false;
        }
        
        return true;
    }

}