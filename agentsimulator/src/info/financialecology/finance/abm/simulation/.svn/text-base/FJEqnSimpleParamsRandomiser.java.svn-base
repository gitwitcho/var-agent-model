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

import info.financialecology.finance.abm.model.FJAbmSimulator;
import info.financialecology.finance.utilities.datastruct.SimulationParameters;

import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import repast.simphony.random.RandomHelper;


import cern.jet.random.*;

/**
 * @author Gilbert Peffer
 *
 */
public class FJEqnSimpleParamsRandomiser extends SimulationParameters {
    FJEqnSimpleParams params = null;
    Pattern p = Pattern.compile("(-?\\d*\\.?\\d+),?(-?\\d*\\.?\\d+)?,?(-?\\d*\\.?\\d+)?");
    
    private String price_0 = "0.0";

    private Uniform distUniform = RandomHelper.createUniform();
    
    private static final Logger logger = (Logger)LoggerFactory.getLogger(FJAbmSimulator.class.getSimpleName());
    
    public FJEqnSimpleParamsRandomiser() {}
        
    private ArrayList<String> splitInterval(String method, String s, Class clazz) {
        ArrayList<String> group = new ArrayList<String>();
        s = s.replaceAll("\\s","");     // remove all white spaces        
        Matcher m = p.matcher(s);
        
        if (!m.matches()) {
            logger.error("Format: a, b, c. b and c are optional. Only 'a': specific value. 'a' and 'b': interval. 'c' step szie for interval.");
            // TODO throw an exception
        }
        else {
            String s1 = m.group(1);
            String s2 = m.group(2);
            String s3 = m.group(3);
            
            group.add(s1);
            
            if (s2 != null)
                group.add(s2);
            else
                s2 = "0";
            
            if (s3 != null)
                group.add(s3);
            else
                s3 = "0";
                        
            if (clazz == Integer.class) {
                if (!isInteger(s1) || !isInteger(s2) || !isInteger(s3))
                    logger.error("Wrong number format - expected integer, found double");
            }
        }
        
        return group;
    }
    
    private int sampleIntegerUniform(ArrayList<String> interval) {
        if (interval.size() == 1)
            return Integer.valueOf(interval.get(0));
        else if (interval.size() == 2) {
            int min = Integer.valueOf(interval.get(0));
            int max = Integer.valueOf(interval.get(1));
            return distUniform.nextIntFromTo(min, max);
        }
        else if (interval.size() == 3) {
            // TODO currently not implemented - number of intervals (not sure whether this is actually useful)
        }
        
        return (int) Double.NaN;
    }
    
    private double sampleDoubleUniform(ArrayList<String> interval) {
        if (interval.size() == 1)
            return Double.valueOf(interval.get(0));
        else if (interval.size() == 2) {
            double min = Double.valueOf(interval.get(0));
            double max = Double.valueOf(interval.get(1));
            return distUniform.nextDoubleFromTo(min, max);
        }
        else if (interval.size() == 3) {
            // TODO currently not implemented - number of intervals (not sure whether this is actually useful)
        }
        
        return (int) Double.NaN;
    }
    
    public void samplePrice() {
        ArrayList<String> interval = splitInterval("price_0", price_0, Double.class);
        params.price_0 = sampleDoubleUniform(interval);
        // TODO check that the price is positive
    }
    
    public void randomise(FJEqnSimpleParams params) {
        this.params = params;
        
        samplePrice();
    }

    /**
     * Creates an xml file that holds the fields of this object
     * 
     * @param file
     * @throws FileNotFoundException 
     */
    public static void writeParamDefinition(String file) throws FileNotFoundException {
        writeParamsDefinition(file, new FJEqnSimpleParams());
    }

    /**
     * Reads values from an xml file and initialises the fields of the newly created parameter object
     * 
     * @param file
     * @return
     * @throws FileNotFoundException 
     */
    public static FJEqnSimpleParamsRandomiser readParameters(String file) throws FileNotFoundException {
        return (FJEqnSimpleParamsRandomiser) readParams(file, new FJEqnSimpleParamsRandomiser());
    }


}
