/**
 * Simple financial systemic risk simulator for Java
 * http://code.google.com/p/systemic-risk/
 * 
 * Copyright (c) 2011, CIMNE and Gilbert Peffer.
 * All rights reserved
 *
 * This software is open-source under the BSD license; see 
 * http://code.google.com/p/systemic-risk/wiki/SoftwareLicense
 */
package info.financialecology.finance.utilities.datastruct;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Type;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.*;


/**
 * @author Gilbert Peffer
 * 
 * TODO How shall we store values from multiple runs for the same result enum?
 * TODO Use a logger to manage the output
 */
public class Datastore {

    private static final Set<ResultEnum> availableResults = new HashSet<ResultEnum>();
    private static final Map<Type, HashMap<ResultEnum, Object>> resultMap = new HashMap<Type, HashMap<ResultEnum, Object>>();

    /**
     * Create a data store with the parameters and their default values
     * 
     * @param parameters: The model and simulator parameters and their default values. An Enum type
     */
    public Datastore() { }

    /**
     * Set up the data store for all result fields in the {@code resultSet}
     * 
     * @author Gilbert Peffer
     * 
     */
    public static <T extends Enum<T> & ResultEnum> void logAllResults(Class<T> resultSet) 
    {
        for (ResultEnum re : resultSet.getEnumConstants()) {
            Class<?> c = (Class<?>) re.type();

            if (c.equals(Double.class))
                logResult(re, new Double(0.0));
            else if (c.equals(Integer.class))
                logResult(re, new Integer(0));
            else if (c.equals(Long.class))
                logResult(re, new Long(0));
            else if (c.equals(Float.class))
                logResult(re, new Float((float) 0));
            else if (c.equals(Short.class))
                logResult(re, new Short((short) 0));
            else if (c.equals(Byte.class))
                logResult(re, new Byte((byte) 0));
            else if (c.equals(BigInteger.class))
                logResult(re, new BigInteger ("0"));
            else if (c.equals(BigDecimal.class))
                logResult(re, new BigDecimal (0.0));
            else if (c.equals(Boolean.class))
                logResult(re, new Boolean(false));
            else {   // Infer the constructor without parameters from the class. Expects that for the given class such a constructor is defined
                Constructor<?> con = null;
                try {
                    con = c.getConstructor();
                } catch (SecurityException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                } catch (NoSuchMethodException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }
                try {
                    logResult(re, con.newInstance());
                } catch (IllegalArgumentException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                } catch (InstantiationException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                } catch (IllegalAccessException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                } catch (InvocationTargetException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }
            }
        }
    }

    /**
     * Set up data store for the result {@code re}
     * 
     * @param re enum field representing the result to be stored in the data store
     * @return the result
     * 
     * @author Gilbert Peffer
     */
    private static <T> T logResult(ResultEnum re, T result) {
        availableResults.add(re);
        Type t = re.type();
        if (!t.equals(result.getClass()))
            throw new IllegalArgumentException("Type of result is different to the type defined in the parent class");
        if (!resultMap.containsKey(t))
            resultMap.put(t, new HashMap<ResultEnum, Object>());
        HashMap<ResultEnum, Object> resultsOfType = resultMap.get(t);
        resultsOfType.put(re, result);
        return result;
    }

    /**
     * 
     * @param resultType the class of the retrieved result instance
     * @param re the enum field representing the result
     * @return the stored result
     * 
     * @author Gilbert Peffer
     */
    public static <T> T getResult(Class<T> resultType, ResultEnum re) {
        if (!resultType.equals(re.type()))
            throw new IllegalArgumentException("Type of result is different to type argument 'resultType'");
        Map<ResultEnum, Object> resultsForType = resultMap.get(resultType);
        T result = resultType.cast(resultsForType.get(re));
        return result;
    }
    
    public static void clean() {
        availableResults.clear();
        resultMap.clear();
    }
}


