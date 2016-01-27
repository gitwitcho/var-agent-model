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
package info.financialecology.finance.utilities.datastruct;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang3.StringUtils;
import org.jfree.data.time.Day;
import org.jfree.data.time.RegularTimePeriod;
import org.jfree.data.time.TimeSeries;
import org.jfree.data.time.TimeSeriesCollection;

import info.financialecology.finance.utilities.Assertion;

/**
 * 
 * TODO [describe chaining]
 * 
 * @author Gilbert Peffer
 *
 */
public class VersatileTimeSeriesCollection extends TimeSeriesCollection {
    
    private static final long serialVersionUID = -2979931889999334305L;

    private String id;

    /**
     * A map to transform a time series dimension index to improve human
     * readability. Used to format output of time series.
     * @see #newIndexMap(String, String, String...) 
     */
    private static HashMap<String, HashMap<String, String>> indexMap;

    /**====================================================================
     * 
     *      GLOBAL AND INSTANCE-LEVEL PARAMETERS
     *      ------------------------------------
     *      
     *      For some parameters, this class offers the possibility to
     *      set values at the class level and overwrite these values at
     *      an instance level.
     *          
     *      Parameters are initialised with predetermined, class level 
     *      values that can be overwritten, both on the class level 
     *      (using the set functions defined in StaticInternalParams) 
     *      as well as on the instance level (using the overwrite 
     *      functions defined in InternalParams). Overwriting parameters 
     *      on the instance level allows special formatting for a single 
     *      time series object.
     *      
     **====================================================================*/


    /**
     * The base line date or time at which the time series in this
     * collection are starting.
     * <p>
     * Used to set the start date when creating a new (set of) time 
     * series populated by a {@link DoubleTimeSeries} or a
     * {@link DoubleTimeSeriesList}.
     */
    private static RegularTimePeriod START_TIME = new Day(1, 1, 2014);
    
    /**
     * The separator for dimension, run, and experiment indices.
     * <p>
     * Used to
     * <ul>
     * <li>generate the key of time series created via 
     * {@link #populateSeries(String, int, DoubleTimeSeries)} and 
     * {@link #populateSeries(String, int, DoubleTimeSeriesList)}</li>
     * <li>split the key of <code>AdvancedTimeSeries</code> objects</li>
     * </ul>
     */
    private static String INDEX_SEPARATOR = "_";
    
    private InternalParams internalParams;
    
    /**
     * The global data structure for time series collection parameters.
     * <p>
     * Provides static setters for the parameters. See the field summary of 
     * {@link VersatileTimeSeriesCollection} for a description of the corresponding 
     * parameters.
     * <p>
     * Local parameters are specific to the object while the global parameters are static
     * and hence have class-level scope. The global parameters are used to set parameter
     * values for all <code>VersatileTimeSeriesCollection</code> objects, while the local
     *  parameters can be used to overwrite the global values for a particular object.   
     */
    public static class StaticInternalParams {
        public static void setStartTime(RegularTimePeriod startTime) {
            START_TIME = startTime;
        }

        public static void setIndexSeperator(String indexSeparator) {
            INDEX_SEPARATOR = indexSeparator;
        }
    }
    
    /**
     * The local data structure for time series format parameters.
     * <p>
     * For an explanation of local vs. global formats, see <code>StaticInternalParams</code>.
     * See the field summary in {@link VersatileTimeSeriesCollection} for an explanation of the
     * format parameters.
     * <p>
     * This class provides getters that return the time series parameter values and 
     * methods that allow overriding global values of these parameters.
     */
    public class InternalParams {
        private RegularTimePeriod startTime;
        private String indexSeparator;
        
        protected InternalParams() {
            startTime = DateUtilities.copy(START_TIME);
            indexSeparator = INDEX_SEPARATOR;
        }
        
        public void overrideStartTime(RegularTimePeriod startTime) {
            this.startTime = DateUtilities.copy(startTime);
        }
        
        public void overrideIndexSeparator(String indexSeparator) {
            this.indexSeparator = indexSeparator;
        }
        
        public RegularTimePeriod getStartTime() {
            return startTime;
        }
        
        public String getIndexSeparator() {
            return indexSeparator;
        }
    }
    

    /**====================================================================
     * 
     *      CONSTRUCTORS, GETTERS, AND SETTERS
     *      ----------------------------------
     *      
     **====================================================================*/

    
    /**
     * Constructs an empty <code>VersatileTimeSeriesCollection</code> object
     * with identifier <code>id</code>.
     * <p>
     * @param id the identifier of this object
     */
    public VersatileTimeSeriesCollection(String id) {
        super();
        this.id = id;
        internalParams = new InternalParams();
        if (indexMap == null)
            indexMap = new HashMap<String, HashMap<String, String>>();
    }

    /**
     * Constructs a <code>VersatileTimeSeriesCollection</code> with time series from the
     * {@code DoubleTimeSeriesList}. The labels are the IDs of the individual time series.
     * <p>
     * @param id the identifier of this object
     */
    public VersatileTimeSeriesCollection(String id, DoubleTimeSeriesList dtsl) {
        super();
        
        this.id = id;
        internalParams = new InternalParams();
        
        if (indexMap == null)
            indexMap = new HashMap<String, HashMap<String, String>>();
        
        for (int i = 0; i < dtsl.size(); i++)
            this.add(dtsl.get(i));
    }

    /**
     * Gets the time series with the specified key.
     * <p>
     * @param key the key of the time series
     * @return the time series with the specified key
     */
    public VersatileTimeSeries getSeries(String key) {
        return (VersatileTimeSeries) super.getSeries(key);
    }
    
    /**
     * Gets the time series for the specified index.
     * <p>
     * @param index the index of the time series
     * @return the time series for the specified index
     */
    public VersatileTimeSeries getSeries(int index) {
        return (VersatileTimeSeries) super.getSeries(index);
    }
    
    /**
     * Creates a new time series collection that consists of those time series in 
     * this collection, which can be considered part of a superset. For details
     * on the exact mechanics, see {@link VersatileTimeSeries#matches(String)}. 
     * <p>
     * <b>Example:</b> Suppose this collection contains four time series with
     * keys <code>price_1_r1</code>, <code>price_1_r2</code>, <code>vol_2_r2</code>
     * and <code>price_2_r2</code>. If <code>superset = price_1</code>, then the 
     * collection that is returned consists of <code>price_1_r1</code> and 
     * <code>price_1_r2</code>. If <code>superset = price_r2</code>, then the 
     * collection that is returned consists of <code>price_1_r2</code> and 
     * <code>price_2_r2</code>. If <code>superset = vol</code>, then the 
     * collection that is returned consists of <code>vol_2_r2</code>. If 
     * <code>superset = price_r3</code>, then the collection that is returned 
     * is empty.
     * <p>  
     * @param superset the key against which subset status of all time series in
     * this collection is tested 
     * @return the time series collection containing all time series that 'belong'
     * to the superset
     * @see VersatileTimeSeries#matches(String)
     */
    public VersatileTimeSeriesCollection getSubset(String superset) {
        VersatileTimeSeriesCollection atsc = new VersatileTimeSeriesCollection("no_name");
        List<VersatileTimeSeries> atsList = getSeries(); // get all series in the collection as a list
        
        for (VersatileTimeSeries ats : atsList)
            if (ats.matches(superset))
                atsc.addSeries(ats);
        
        return atsc;
    }

    /**
     * Creates new <a href="http://tinyurl.com/c37gxle"><code>TimeSeries</code></a>
     * objects and adds them to this collection.
     * <p>
     * @param names an arbitrary number of time series keys
     */
    public void newSeries(String... keys) {
        for (String name : keys)
            addSeries(new TimeSeries(name));
    }
    
    /**
     * Creates new <a href="http://tinyurl.com/c37gxle"><code>TimeSeries</code></a>
     * objects and adds them to this collection. For each <code>name</code>, the method
     * generates <code>nIndices</code> time series with keys of the form 
     * <code>name_index</code>.
     * <p>
     * @param nIndices the number of time series generated per name
     * @param names an arbitrary number of time series keys
     */
    public void newIndexedSeries(int nIndices, String... names) {
        for (String name : names) {
            for (int i = 1; i <= nIndices; i++)
                addSeries(new TimeSeries(name + "_" + i));
        }
    }
    
    
    /**
     * Add a new time series to the collection.
     * <p>
     * Creates a new {@link VersatileTimeSeries}, populates it with the values from the 
     * {@link DoubleTimeSeries} {@code dts}, and insert it into the collection.
     * <p>
     * Uses the parameter {@code startTime} to set the time at which the time series starts.
     * Use {@code setStartTime()} and {@code overrideStartTime()} to change the start time.  
     * <p>  
     * 
     * @param dts the {@link DoubleTimeSeries} from which we obtain the values to populate the
     * new time series  
     * @param name the name of the time series variable
     */
    public void add(DoubleTimeSeries dts) {

        String newKey = dts.getId();
                
        Assertion.assertOrKill(getSeries(newKey) == null, "A time series with the key '" + newKey + "' already exists in the collection");
        
        VersatileTimeSeries vts = new VersatileTimeSeries(newKey);

        RegularTimePeriod time = internalParams.getStartTime();

        for (int t = 0; t < dts.size(); t++) {
            vts.add(time, dts.getValue(t));
            time = time.next();
        }
        
        addSeries(vts);
        
        Assertion.assertOrKill(checkConsistency(), "The time series '" + dts.getId() + "' added to "
                + "the collection is not consistent with the already existing time series");
    }

    
    /**
     * Create a new {@link VersatileTimeSeries}, populate it with values of a {@link DoubleTimeSeries}, 
     * and insert into the collection. Experiment, run, and asset indices have to be provided while 
     * the dimension indices are optional. The key of the new time series is constructed using
     * the <code>name</code> and the experiment, run, asset, and dimension indices provided as parameters.
     * <p>
     * The sequence of the method arguments is a bit of a hack, to facilitate passing an arbitrary list of
     * dimension indices.
     * <p>
     * Uses the internal parameters <code>startTime</code> and <code>indexSeparator</code>.
     * <p>  
     * @param dts the {@link DoubleTimeSeries} from which we obtain the values to populate the
     * new time series  
     * @param exp the experiment index
     * @param run the run index
     * @param assset the asset index
     * @param name the name of the time series variable
     * @param indices the dimension indices (may be empty)
     */
    public void populateSeries(int exp, int run, String secId, String name, DoubleTimeSeries dts, int... indices) {
        String newKey = name + internalParams.getIndexSeparator();
        
        Assertion.assertStrict((exp >= 0) && (run >= 0), Assertion.Level.ERR, "Run and experiment index have to be positive");
        
        for (int i : indices) {
            Assertion.assertStrict(i >= 0, Assertion.Level.ERR, "Dimension indices have to be positive");
            newKey += Integer.toString(i) + internalParams.getIndexSeparator();
        }
        
        newKey += secId + internalParams.getIndexSeparator() + "r" + Integer.toString(run) + 
        		internalParams.getIndexSeparator() + "e" + Integer.toString(exp);
        
        VersatileTimeSeries ats = new VersatileTimeSeries(newKey);
        addSeries(ats);

        RegularTimePeriod time = internalParams.getStartTime();

        for (int i = 0; i < dts.size(); i++) {
            ats.add(time, dts.getValue(i));
            time = time.next();
        }
                
    }

    
    /**
     * Create a new {@link VersatileTimeSeries}, populate it with values of a {@link DoubleTimeSeries}, 
     * and insert into the collection. Experiment and run indices have to be provided while 
     * the dimension indices are optional. The key of the new time series is constructed using
     * the <code>name</code> and the experiment, run, and dimension indices provided as parameters.
     * <p>
     * The sequence of the method arguments is a bit of a hack, to facilitate passing an arbitrary list of
     * dimension indices.
     * <p>
     * Uses the internal parameters <code>startTime</code> and <code>indexSeparator</code>.
     * <p>  
     * @param dts the {@link DoubleTimeSeries} from which we obtain the values to populate the
     * new time series  
     * @param exp the experiment index
     * @param run the run index
     * @param name the name of the time series variable
     * @param indices the dimension indices (may be empty)
     */
    public void populateSeries(int exp, int run, String name, DoubleTimeSeries dts, int... indices) {
        String newKey = name + internalParams.getIndexSeparator();
        
        Assertion.assertStrict((exp >= 0) && (run >= 0), Assertion.Level.ERR, "Run and experiment index have to be positive");
        
        for (int i : indices) {
            Assertion.assertStrict(i >= 0, Assertion.Level.ERR, "Dimension indices have to be positive");
            newKey += Integer.toString(i) + internalParams.getIndexSeparator();
        }
        
        newKey += "r" + Integer.toString(run) + internalParams.getIndexSeparator() + "e" + Integer.toString(exp);
        
        VersatileTimeSeries ats = new VersatileTimeSeries(newKey);
        addSeries(ats);

        RegularTimePeriod time = internalParams.getStartTime();

        for (int i = 0; i < dts.size(); i++) {
            ats.add(time, dts.getValue(i));
            time = time.next();
        }
                
    }
    
    /**
     * Create a new {@link VersatileTimeSeries}, populate it with values of a 
     * {@link DoubleTimeSeries}, and insert into the collection. The run index 
     * has to be provided while the dimension indices are optional. The key of 
     * the new time series is constructed using the <code>name</code> and the 
     * run and dimension indices provided as parameters.
     * <p>
     * The sequence of the method arguments is a bit of a hack, to facilitate 
     * passing an arbitrary list of dimension indices.
     * <p>
     * Uses the internal parameters <code>startTime</code> and <code>indexSeparator</code>.
     * <p>  
     * @param dts the {@link DoubleTimeSeries} from which we obtain the values to populate the
     * new time series  
     * @param run the run index
     * @param name the name of the time series variable
     * @param indices the dimension indices (may be empty)
     */
    public void populateSeries(int run, String name, DoubleTimeSeries dts, int... indices) {
        String newKey = name + internalParams.getIndexSeparator();
        
        Assertion.assertStrict(run >= 0, Assertion.Level.ERR, "Run index has to be positive");
        
        for (int i : indices) {
            Assertion.assertStrict(i >= 0, Assertion.Level.ERR, "Dimension indices have to be positive");
            newKey += Integer.toString(i) + internalParams.getIndexSeparator();
        }
        
        newKey += "r" + Integer.toString(run);

        VersatileTimeSeries ats = new VersatileTimeSeries(newKey);
        addSeries(ats);

        RegularTimePeriod time = internalParams.getStartTime();

        for (int i = 0; i < dts.size(); i++) {
            ats.add(time, dts.getValue(i));
            time = time.next();
        }
                
    }
    
    
    /**
     * Create a new set of {@link VersatileTimeSeries}, populate them with 
     * values of {@link DoubleTimeSeries} from a {@link DoubleTimeSeriesList},
     * and insert them into this collection. The experiment and run indices 
     * have to be provided together with the index at which the dimension index
     * starts. The keys of the new time series are constructed using the 
     * <code>name</code> and the experiment and run indices provided as parameters.
     * <p>
     * <b>Note:</b> This currently works only for series with a single dimension 
     * index.
     * <p>
     * Uses the internal parameters <code>startTime</code> and <code>indexSeparator</code>.
     * <p>  
     * @param dtl the {@link DoubleTimeSeriesList} from which we obtain the values to 
     * populate the new time series  
     * @param exp the experiment index
     * @param run the run index
     * @param name the name of the time series variable
     * @param startIndex the value at which the dimension index starts 
     */
    public void populateSeries(int exp, int run, String name, DoubleTimeSeriesList dtl, int startIndex) {
        
        Assertion.assertStrict((exp >= 0) && (run >= 0) && (startIndex >= 0), Assertion.Level.ERR, "Start index and run and experiment indices have to be positive");

        for (int i = 0; i < dtl.size(); i++) {
            String newKey = name + internalParams.getIndexSeparator() + Integer.toString(i + startIndex)
                    + internalParams.getIndexSeparator() + "r" + Integer.toString(run) 
                    + internalParams.getIndexSeparator() + "e" + Integer.toString(exp); 
            VersatileTimeSeries ats = new VersatileTimeSeries(newKey);
            addSeries(ats);

            RegularTimePeriod time = internalParams.getStartTime();

            for (int j = 0; j < dtl.get(i).size(); j++) {
                ats.add(time, dtl.get(i).getValue(j));
                time = time.next();
            }
        }
    }
    
    /**
     * Create a new set of {@link VersatileTimeSeries}, populate them with 
     * values of {@link DoubleTimeSeries} from a {@link DoubleTimeSeriesList},
     * and insert them into this collection. The run index has to be provided 
     * together with the index at which the dimension index starts. The keys 
     * of the new time series are constructed using the <code>name</code> and 
     * the run index provided as parameters.
     * <p>
     * <b>Note:</b> This currently works only for series with a single dimension 
     * index.
     * <p>
     * Uses the internal parameters <code>startTime</code> and <code>indexSeparator</code>.
     * <p>  
     * @param dtl the {@link DoubleTimeSeriesList} from which we obtain the values to 
     * populate the new time series  
     * @param run the run index
     * @param name the name of the time series variable
     * @param startIndex the value at which the dimension index starts 
     */
    public void populateSeries(int run, String name, DoubleTimeSeriesList dtl, int startIndex) {
        
        Assertion.assertStrict((run >= 0) && (startIndex >= 0), Assertion.Level.ERR, "Start index and experiment index have to be positive");

        for (int i = 0; i < dtl.size(); i++) {
            String newKey = name + internalParams.getIndexSeparator() + Integer.toString(i + startIndex)
                    + internalParams.getIndexSeparator() + "r" + Integer.toString(run); 
            VersatileTimeSeries ats = new VersatileTimeSeries(newKey);
            addSeries(ats);

            RegularTimePeriod time = internalParams.getStartTime();

            for (int j = 0; j < dtl.get(i).size(); j++) {
                ats.add(time, dtl.get(i).getValue(j));
                time = time.next();
            }
        }
    }
    
    
    /**====================================================================
     * 
     *      FILTERING BY INDEX OR NAME
     *      --------------------------
     *      
     *      A set of methods to extract time series from this collection
     *      whose name or (dimension, run, experiment) index belongs to
     *      a given set of names or indices.
     *      
     **====================================================================*/

    
    /**
     * Creates a new time series collection consisting of only those time series that 
     * belong to a particular set of experiments. The name of the collection is that
     * of this collection marked with "(filtered by experiment)".
     * <p>
     * <b>Note:</b> The times series in the new collection are shallow copies.
     * <p>
     * @param experiments the indices of the experiments that are added to the new
     * time series collection 
     * @return the new time series collection
     */
    public VersatileTimeSeriesCollection filterByExperiment(int... experiments) {
        VersatileTimeSeriesCollection tsc = new VersatileTimeSeriesCollection(id + "(filtered by experiment)");
        
        for (int exp : experiments) {
            String label = "e" + exp;
            
            for (String key : getKeys())  {
                VersatileTimeSeries ats = (VersatileTimeSeries) getSeries(key);
                
                if (ats.matches(label))
                    tsc.addSeries(getSeries(key));
            }
        }
        
        return tsc;
    }
    
    /**
     * Creates a new time series collection consisting of only those time series that 
     * belong to a particular set of runs. The name of the collection is that
     * of this collection marked with "(filtered by run)".
     * <p>
     * <b>Note:</b> The times series in the new collection are shallow copies.
     * <p>
     * @param runs the indices of the runs that are added to the new time series collection 
     * @return the new time series collection
     */
    public VersatileTimeSeriesCollection filterByRun(int... runs) {
        VersatileTimeSeriesCollection tsc = new VersatileTimeSeriesCollection(id + "(filtered by run)");
        
        for (int run : runs) {
            String label = "r" + run;
            
            for (String key : getKeys())  {
                VersatileTimeSeries ats = (VersatileTimeSeries) getSeries(key);
                
                if (ats.matches(label))
                    tsc.addSeries(getSeries(key));
            }
        }
        
        return tsc;
    }
    
    /**
     * Creates a new time series collection consisting of only those time series with 
     * particular variable names. The name of the collection is that
     * of this collection marked with "(filtered by variable name)".
     * <p>
     * <b>Note:</b> The times series in the new collection are shallow copies.
     * <p>
     * @param variables the variable names of the time series that are added to 
     * the new time series collection 
     * @return the new time series collection
     */
    public VersatileTimeSeriesCollection filterByVariableName(String... variables) {
        VersatileTimeSeriesCollection tsc = new VersatileTimeSeriesCollection(id + "(filtered by variable name)");

        for (String key : getKeys())  {
            
            for (String var : variables) {
                VersatileTimeSeries ats = (VersatileTimeSeries) getSeries(key);
                
                if (ats.matches(var))
                    tsc.addSeries(getSeries(key));
            }                    
        }
        
        return tsc;
    }
    
    /**
     * Creates a new time series collection consisting of only those time series  
     * whose first dimension index belongs to one of the values in the argument list
     * <code>indices</code>. The name of the collection is that of this collection 
     * marked with "(filtered by variable index)".
     * <p>
     * <b>Note:</b> The times series in the new collection are shallow copies.
     * <p>
     * @param indices the value of the dimension indices for which a time series 
     * is added to the new collection
     * @return the new time series collection
     */
    public VersatileTimeSeriesCollection filterByVariableIndex(int... indices) {
        return filterByVariableIndex("1", indices);
    }
    
    /**
     * Creates a new time series collection consisting of only those time series  
     * whose dimension index at location <code>loc</code> belongs to one of the 
     * values in the argument list <code>indices</code>. The name of the collection 
     * is that of this collection marked with "(filtered by variable index)".
     * <p>
     * <b>Note:</b> The times series in the new collection are shallow copies.
     * <p>
     * @param loc the location at which to test the index (starting at '1', not '0')
     * @param indices the value of the dimension indices for which a time series 
     * is added to the new collection
     * @return the new time series collection
     */
    public VersatileTimeSeriesCollection filterByVariableIndex(String loc, int... indices) {
        VersatileTimeSeriesCollection tsc = new VersatileTimeSeriesCollection(id + "(filtered by variable index)");
        
        Assertion.assertStrict(Integer.valueOf(loc) > 0, Assertion.Level.ERR, "The index location has to be greater than '0'");
        
        // TODO change this method, to use isSubsetOf(String) of the AdvancedTimeSeries
        
        for (String key : getKeys())  {
            String [] tmp = key.split(internalParams.getIndexSeparator());
            int count = 1;
            int iLoc = Integer.valueOf(loc);

            for (int i = 0; i < tmp.length; i++) {
                Boolean isNumber = isNumeric(tmp[i]);
                
                if (isNumber && (count == iLoc)) {
                    for (int index : indices)
                        if (index == Integer.valueOf(tmp[i]))
                            tsc.addSeries(getSeries(key));
                    break;
                }
                
                if (isNumber)
                    count++;
            }
        }
        
        return tsc;
    }
    


    /**====================================================================
     * 
     *      ALGEBRAIC AND STATISTICAL OPERATORS
     *      INSERTING AND RETURNING TIME SERIES
     *      -----------------------------------
     *      
     *      Various methods for mathematical transformations and basic 
     *      statistical computations. These methods either return or
     *      insert a time series into this collection.
     *      
     *      Note: If you want to operate on a subset only for, say, a 
     *      particular experiment, use a filter first.

     *      Note: Category datasets are basically tables used to store 
     *      non-time series values.
     *      
     **====================================================================*/

    
    /**
     * Inserts a time series created by the item-wise sum of a subset of time
     * series in this collection.
     * <p>
     * @param newKey the key of the new time series
     * @param supersets a list of superset keys to test whether a given time series
     * belongs to the subset
     * @see #getSumOfSeries(String, String...)
     */
    public void insertSumOfSeries(String newKey, String... supersets) {
        VersatileTimeSeries ats = getSumOfSeries(newKey, supersets);       
        addSeries(ats);
    }
    
    /**
     * Create a new time series that is the item-wise sum of a given subset of time
     * series in this collection. Whether a time series belongs to this subset depends 
     * on the superset keys provided by the argument list <code>supersets</code>. 
     * <p>
     * @param newKey the key of the new time series
     * @param supersets a list of superset keys to test whether a given time series
     * belongs to the subset
     * @return the new time series
     * 
     */
    public VersatileTimeSeries getSumOfSeries(String newKey, String... supersets) {
        VersatileTimeSeries newAts;
        ArrayList<VersatileTimeSeries> atsList = new ArrayList<VersatileTimeSeries>();
        
        // Find the time series in this collection that match the superset keys
        for (String key : getKeys()) {
            VersatileTimeSeries ats = (VersatileTimeSeries) getSeries(key);
            for (String superset : supersets) {
                if (ats.matches(superset))
                    atsList.add(ats);
            }
        }
        
        newAts = VersatileTimeSeries.createSumOfSeries(newKey, atsList.toArray(new VersatileTimeSeries[atsList.size()]));
        
        return newAts;
    }


    /**====================================================================
     * 
     *      ALGEBRAIC AND STATISTICAL OPERATORS
     *      INSERTING AND RETURNING TIME SERIES
     *      COLLECTIONS
     *      -----------------------------------
     *      
     *      Various methods for mathematical transformations and basic 
     *      statistical computations. These methods either return a 
     *      time series collection or insert the time series contained
     *      in the time series collection into this collection. 
     *      
     *      Note: If you want to operate on a subset only for, say, a 
     *      particular experiment, use a filter first.
     * 
     **====================================================================*/

    
    /**
     * Create cumulative time series based on existing time series and
     * insert in this collection.
     * <p>
     * See {@link #getSeriesCumulative(String...)} for more details.
     * <p>
     * @param namePairs the existing and new variable name pairs for the 
     * existing and new time series
     */
    public void insertSeriesCumulative(String... namePairs) {
        VersatileTimeSeriesCollection atsc = getSeriesCumulative(namePairs);
        
        for (String key : atsc.getKeys())
            addSeries(atsc.getSeries(key));
    }
    
    /**
     * Create difference time series based on existing time series and
     * insert in this collection.
     * <p>
     * See {@link #getSeriesDifference(String...)} for more details.
     * <p>
     * @param namePairs the existing and new variable name pairs for the 
     * existing and new time series
     */
    public void insertSeriesDifference(String... namePairs) {
        VersatileTimeSeriesCollection atsc = getSeriesDifference(namePairs);
        
        for (String key : atsc.getKeys())
            addSeries(atsc.getSeries(key));
    }
    
    /**
     * Create exponential value time series based on existing time series and
     * insert in this collection.
     * <p>
     * See {@link #getSeriesExp(String...)} for more details.
     * <p>
     * @param namePairs the existing and new variable name pairs for the 
     * existing and new time series
     */
    public void insertSeriesExp(String... namePairs) {
        VersatileTimeSeriesCollection atsc = getSeriesExp(namePairs);
        
        for (String key : atsc.getKeys())
            addSeries(atsc.getSeries(key));
    }
    
    /**
     * Create natural log value time series based on existing time series and
     * insert in this collection.
     * <p>
     * See {@link #getSeriesLn(String...)} for more details.
     * <p>
     * @param namePairs the existing and new variable name pairs for the 
     * existing and new time series
     */
    public void insertSeriesLn(String... namePairs) {
        VersatileTimeSeriesCollection atsc = getSeriesLn(namePairs);
        
        for (String key : atsc.getKeys())
            addSeries(atsc.getSeries(key));
    }
    
    /**
     * Generate new time series with values equal to the cumulative values of a set
     * of given time series. The variable names of the given time series and the 
     * variable names of the new time series are given as namePairs.
     * <p>
     * <b>Example:</b> For two existing time series with variable names <code>price</code>
     * and <code>vol</code> we choose for instance <code>cumulPrice</code> and <code>cumulVol</code>
     * as the variable names of the new time series. The method is then called as follows:
     * <code>getSeriesCumulative("price", "cumulPrice", "vol", "cumulVol")</code>
     * <p>
     * <b>Note:</b> If you want to operate only on a time series subset, say, for a  
     * particular experiment, use a filter first.
     * <p> 
     * @param namePairs the existing and new variable name pairs for the existing and new
     * time series
     * @return a collection containing the new time series
     * 
     */
    public VersatileTimeSeriesCollection getSeriesCumulative(String... namePairs) {
        VersatileTimeSeriesCollection newAtsc = new VersatileTimeSeriesCollection(id + "('cumulative' operator)");
        List<VersatileTimeSeries> atsc = getSeries();
        
        if ((namePairs == null) || (namePairs.length == 0)) {   // especially for filtered intermediate results, providing names isn't always necessary
            for (VersatileTimeSeries ats : atsc)
                newAtsc.addSeries(ats.operatorCumulative((String) ats.getKey()));
        }
        else {
            for (int i = 0; i < namePairs.length; i += 2) {
                for (VersatileTimeSeries ats : atsc) {
                    
                    if (ats.matches(namePairs[i])) {
                        // Generate a key by swapping the name part of the key of the original time series with the new name
                        String newKey = ((String) ats.getKey()).replace(namePairs[i], namePairs[i + 1]);
                        newAtsc.addSeries(ats.operatorCumulative(newKey));
                    }
                }
            }
        }
        return newAtsc;
    }
    
    /**
     * Generate new time series with values equal to the absolute values of a set
     * of given time series. The variable names of the given time series and the 
     * variable names of the new time series are given as namePairs.
     * <p>
     * <b>Example:</b> see {@link #getSeriesCumulative(String...)} 
     * <p>
     * <b>Note:</b> If you want to operate only on a time series subset, say, for a  
     * particular experiment, use a filter first.
     * <p> 
     * @param namePairs the existing and new variable name pairs for the existing and new
     * time series
     * @return a collection containing the new time series
     */
    public VersatileTimeSeriesCollection getSeriesAbs(String... namePairs) {
        VersatileTimeSeriesCollection newAtsc = new VersatileTimeSeriesCollection(id + "('absolute value' operator)");
        List<VersatileTimeSeries> atsc = getSeries();
        
        if ((namePairs == null) || (namePairs.length == 0)) {   // especially for filtered intermediate results, providing names isn't always necessary
            for (VersatileTimeSeries ats : atsc)
                newAtsc.addSeries(ats.operatorAbs((String) ats.getKey()));
        }
        else {
            for (int i = 0; i < namePairs.length; i += 2) {
                for (VersatileTimeSeries ats : atsc) {
                    
                    if (ats.matches(namePairs[i])) {
                        String newKey = ((String) ats.getKey()).replace(namePairs[i], namePairs[i + 1]);
                        newAtsc.addSeries(ats.operatorAbs(newKey));
                    }
                }
            }
        }
        
        return newAtsc;
    }
    
    /**
     * Generate new time series with values equal to the first difference of a set
     * of given time series. The first difference is the difference between the value
     * at time <code>t+1</code> and at <code>t</code>. The variable names of the 
     * given time series and the variable names of the new time series are given as 
     * namePairs.
     * <p>
     * <b>Example:</b> see {@link #getSeriesCumulative(String...)} 
     * <p>
     * <b>Note:</b> If you want to operate only on a time series subset, say, for a  
     * particular experiment, use a filter first.
     * <p> 
     * @param namePairs the existing and new variable name pairs for the existing and new
     * time series
     * @return a collection containing the new time series
     */
    public VersatileTimeSeriesCollection getSeriesDifference(String... namePairs) {
        VersatileTimeSeriesCollection newAtsc = new VersatileTimeSeriesCollection(id + "('difference' operator)");
        List<VersatileTimeSeries> atsc = getSeries();
        
        if ((namePairs == null) || (namePairs.length == 0)) {   // especially for filtered intermediate results, providing names isn't always necessary
            for (VersatileTimeSeries ats : atsc)
                newAtsc.addSeries(ats.operatorDifference((String) ats.getKey()));
        }
        else {
            for (int i = 0; i < namePairs.length; i += 2) {
                for (VersatileTimeSeries ats : atsc) {
                    
                    if (ats.matches(namePairs[i])) {
                        String newKey = ((String) ats.getKey()).replace(namePairs[i], namePairs[i + 1]);
                        newAtsc.addSeries(ats.operatorDifference(newKey));
                    }
                }
            }
        }        
        return newAtsc;
    }
    
    /**
     * Generate new time series with values equal to the exponential value of a set
     * of given time series. The variable names of the given time series and the 
     * variable names of the new time series are given as namePairs.
     * <p>
     * <b>Example:</b> see {@link #getSeriesCumulative(String...)} 
     * <p>
     * <b>Note:</b> If you want to operate only on a time series subset, say, for a  
     * particular experiment, use a filter first.
     * <p> 
     * @param namePairs the existing and new variable name pairs for the existing and new
     * time series
     * @return a collection containing the new time series
     */
    public VersatileTimeSeriesCollection getSeriesExp(String... namePairs) {
        VersatileTimeSeriesCollection newAtsc = new VersatileTimeSeriesCollection(id + "('exponential' operator)");
        List<VersatileTimeSeries> atsc = getSeries();
        
        if ((namePairs == null) || (namePairs.length == 0)) {   // especially for filtered intermediate results, providing names isn't always necessary
            for (VersatileTimeSeries ats : atsc)
                newAtsc.addSeries(ats.operatorExp((String) ats.getKey()));
        }
        else {
            for (int i = 0; i < namePairs.length; i += 2) {
                for (VersatileTimeSeries ats : atsc) {
                    
                    if (ats.matches(namePairs[i])) {
                        String newKey = ((String) ats.getKey()).replace(namePairs[i], namePairs[i + 1]);
                        newAtsc.addSeries(ats.operatorExp(newKey));
                    }
                }
            }
        }        
        return newAtsc;
    }
    
    /**
     * Generate new time series with values equal to the natura logarithm of the
     * values of a set of given time series. The variable names of the given time 
     * series and the variable names of the new time series are given as namePairs.
     * <p>
     * <b>Example:</b> see {@link #getSeriesCumulative(String...)} 
     * <p>
     * <b>Note:</b> If you want to operate only on a time series subset, say, for a  
     * particular experiment, use a filter first.
     * <p> 
     * @param namePairs the existing and new variable name pairs for the existing and new
     * time series
     * @return a collection containing the new time series
     */
    public VersatileTimeSeriesCollection getSeriesLn(String... namePairs) {
        VersatileTimeSeriesCollection newAtsc = new VersatileTimeSeriesCollection(id + "('natural logarithm' operator)");
        List<VersatileTimeSeries> atsc = getSeries();
        
        if ((namePairs == null) || (namePairs.length == 0)) {   // especially for filtered intermediate results, providing names isn't always necessary
            for (VersatileTimeSeries ats : atsc)
                newAtsc.addSeries(ats.operatorLn((String) ats.getKey()));
        }
        else {
            for (int i = 0; i < namePairs.length; i += 2) {
                for (VersatileTimeSeries ats : atsc) {
                    
                    if (ats.matches(namePairs[i])) {
                        String newKey = ((String) ats.getKey()).replace(namePairs[i], namePairs[i + 1]);
                        newAtsc.addSeries(ats.operatorLn(newKey));
                    }
                }
            }
        }        
        return newAtsc;
    }
    
//    public VersatileTimeSeriesCollection getSeriesExp(String varName, String newVarName) {
//        VersatileTimeSeriesCollection newAtsc = new VersatileTimeSeriesCollection(id + "('ln' operator)");
//        
//        // TODO this is not always working, e.g. for a variable "foo_bar", "foo" would erroneously match it 
//        for (String key : getKeys())
//            if (key.startsWith(varName)) {
//                String newKey = key.replace(varName, newVarName);
//                AdvancedTimeSeries ats = (AdvancedTimeSeries) this.getSeries(key);
//                newAtsc.addSeries(ats.operatorExp(newKey));
//            }
//
//        return newAtsc;
//    }
//    
//    public VersatileTimeSeriesCollection getSeriesLn(String varName, String newVarName) {
//        VersatileTimeSeriesCollection newAtsc = new VersatileTimeSeriesCollection(id + "('ln' operator)");
//        
//        // TODO this is not always working, e.g. for a variable "foo_bar", "foo" would erroneously match it 
//        for (String key : getKeys())
//            if (key.startsWith(varName)) {
//                String newKey = key.replace(varName, newVarName);
//                AdvancedTimeSeries ats = (AdvancedTimeSeries) this.getSeries(key);
//                newAtsc.addSeries(ats.operatorLn(newKey));
//            }
//
//        return newAtsc;
//    }
    

    /**====================================================================
     * 
     *      ALGEBRAIC AND STATISTICAL OPERATORS
     *      RETURNING CATEGORY DATASETS
     *      -----------------------------------
     *      
     *      Various methods for mathematical transformations and basic 
     *      statistical computations. These methods either return a 
     *      category dataset. 
     *      
     *      Category datasets are basically tables used to store 
     *      non-time series values.
     *      
     **====================================================================*/

    
    /**
     * Create a table (as an {@link VersatileDataTable}) to store the total
     * sum of values of a set of time series.
     * <p>
     * <b>Note:</b> For an example of the argument namePairs, see e.g.
     * {@link #getSeriesCumulative(String...)}
     * <p>
     * @param namePairs the existing and new variable name pairs for the existing and new
     * time series
     * @return a dataset containing the sums
     *
     */
    public VersatileDataTable getSeriesSum(String... namePairs) {
        VersatileDataTable acdsSums = new VersatileDataTable("sums of series");
        List<VersatileTimeSeries> atsc = getSeries();
                
        if ((namePairs == null) || (namePairs.length == 0)) {   // especially for filtered intermediate results, providing names isn't always necessary
            for (VersatileTimeSeries ats : atsc)
                acdsSums.addValue((String) ats.getKey(), ats.operatorSum());
        }
        else {
            for (int i = 0; i < namePairs.length; i += 2) {
                for (VersatileTimeSeries ats : atsc) {
                    if (ats.matches(namePairs[i])) {
                        String newKey = ((String) ats.getKey()).replace(namePairs[i], namePairs[i + 1]);
                        acdsSums.addValue(newKey, ats.operatorSum());
                    }
                }
            }
        }
        
        return acdsSums;
    }
    
    /**
     * Create a table (as an {@link VersatileDataTable}) to store the standard
     * deviations of a set of time series.
     * <p>
     * <b>Note:</b> For an example of the argument namePairs, see e.g.
     * {@link #getSeriesCumulative(String...)}
     * <p>
     * @param namePairs the existing and new variable name pairs for the existing and new
     * time series
     * @return a dataset containing the standard deviations
     *
     */
    public VersatileDataTable getSeriesStdev(String... namePairs) {
        VersatileDataTable acdsSums = new VersatileDataTable("standard deviation of series");
        List<VersatileTimeSeries> atsc = getSeries();
                
        if ((namePairs == null) || (namePairs.length == 0)) {   // especially for filtered intermediate results, providing names isn't always necessary
            for (VersatileTimeSeries ats : atsc)
                acdsSums.addValue((String) ats.getKey(), ats.operatorStdev());
        }
        else {
            for (int i = 0; i < namePairs.length; i += 2) {
                for (VersatileTimeSeries ats : atsc) {
                    if (ats.matches(namePairs[i])) {
                        String newKey = ((String) ats.getKey()).replace(namePairs[i], namePairs[i + 1]);
                        acdsSums.addValue(newKey, ats.operatorStdev());
                    }
                }
            }
        }
        
        return acdsSums;
    }
    
    /**
     * Create a table (as an {@link VersatileDataTable}) to store the skewness
     * of a set of time series.
     * <p>
     * <b>Note:</b> For an example of the argument namePairs, see e.g.
     * {@link #getSeriesCumulative(String...)}
     * <p>
     * @param namePairs the existing and new variable name pairs for the existing and new
     * time series
     * @return a dataset containing the skewness values
     *
     */
    public VersatileDataTable getSeriesSkewness(String... namePairs) {
        VersatileDataTable acdsSums = new VersatileDataTable("skewness of series");
        List<VersatileTimeSeries> atsc = getSeries();
                
        if ((namePairs == null) || (namePairs.length == 0)) {   // especially for filtered intermediate results, providing names isn't always necessary
            for (VersatileTimeSeries ats : atsc)
                acdsSums.addValue((String) ats.getKey(), ats.operatorSkewness());
        }
        else {
            for (int i = 0; i < namePairs.length; i += 2) {
                for (VersatileTimeSeries ats : atsc) {
                    if (ats.matches(namePairs[i])) {
                        String newKey = ((String) ats.getKey()).replace(namePairs[i], namePairs[i + 1]);
                        acdsSums.addValue(newKey, ats.operatorSkewness());
                    }
                }
            }
        }
        
        return acdsSums;
    }
    
    /**
     * Create a table (as an {@link VersatileDataTable}) to store the kurtosis
     * of a set of time series.
     * <p>
     * <b>Note:</b> For an example of the argument namePairs, see e.g.
     * {@link #getSeriesCumulative(String...)}
     * <p>
     * @param namePairs the existing and new variable name pairs for the existing and new
     * time series
     * @return a dataset containing the kurtosis values
     *
     */
    public VersatileDataTable getSeriesUnbiasedExcessKurtosis(String... namePairs) {
        VersatileDataTable acdsSums = new VersatileDataTable("kurtosis of series");
        List<VersatileTimeSeries> atsc = getSeries();
                
        if ((namePairs == null) || (namePairs.length == 0)) {   // especially for filtered intermediate results, providing names isn't always necessary
            for (VersatileTimeSeries ats : atsc)
                acdsSums.addValue((String) ats.getKey(), ats.operatorUnbiasedExcessKurtosis());
        }
        else {
            for (int i = 0; i < namePairs.length; i += 2) {
                for (VersatileTimeSeries ats : atsc) {
                    if (ats.matches(namePairs[i])) {
                        String newKey = ((String) ats.getKey()).replace(namePairs[i], namePairs[i + 1]);
                        acdsSums.addValue(newKey, ats.operatorUnbiasedExcessKurtosis());
                    }
                }
            }
        }
        
        return acdsSums;
    }
    
    
    /**====================================================================
     * 
     *      INDEX MAPPING
     *      -------------
     *      
     *      A number of methods are provided to transform indices into
     *      more human readable formats. This is used mainly for output
     *      formatting. For instance, rather than print 'cash_1', we can
     *      use the method {@link #newIndexMap(String, String, String...)}
     *      to map index "1" into a new index "bank". This has only an
     *      effect on how the labels are written to the output.
     *      
     *      The method {@link #printDecoratedSeries(String, int) for 
     *      instance uses the index map when printing out formatted
     *      time series tables.
     *      
     **====================================================================*/

    
    /**
     * Creates a table of mappings from original to new indices.
     * <p>
     * The principal use of this method is to provide a way of transforming
     * dimension indices into something more human readable. It only has
     * effects in terms of how labels are written to the output.
     * <p>
     * The method {@link #printDecoratedSeries(String, int)} uses the index 
     * map when printing out formatted time series tables.
     * <p>
     * <b>Example:</b> The method call <code>newIndexMap("cash", "1", "1", 
     * "bank", "2", "fund")</code> will create an index map for the 
     * dimension index at location "1", for all time series with variable 
     * name "cash". Index "1" is mapped into "bank" and index "2" into 
     * "fund". So, for instance "cash_2_12" becomes "cash_fund_12" when 
     * writing the time series to the output using {@link #printDecoratedSeries
     * (String, int)}.
     * <p>
     * <b>Note:</b> The keys under which the new indices are stored are of the
     * form 'a-b', where 'a' is the index location and 'b' is the numeric index
     * value. E.g. '2-12' for second dimensional index and index value 12.
     * @param name the variable name of the time series whose index is 
     * mapped
     * @param loc the location of the dimension index that is mapped
     * @param mappings the pairs of index names
     */
    public void newIndexMap(String name, String loc, String... mappings) {
        HashMap<String, String> map = new HashMap<String, String>();
        indexMap.put(name, map);

        for (int i = 0; i < mappings.length; i += 2)
            map.put(loc + "-" + mappings[i], mappings[i + 1]);
    }
    
    /**
     * Creates a prefix for the first dimension index.
     * <p>
     * See {@link #setIndexPrefix(String, String, String) for
     * details.
     * @param name the variable name of the time series
     * @param prefix the label used as a prefix
    */
    public void setIndexPrefix(String name, String prefix) {
        setIndexPrefix(name, "1", prefix);
    }
    
    /**
     * Creates a prefix for a given dimension index.
     * <p>
     * While the method {@link #newIndexMap(String, String, String...)}
     * replaces a numeric dimension index with a custom label, this
     * method prefixes a custom label, leaving the index values intact.
     * This is useful when different index values are of the same category.
     * <p>
     * <b>Example:</b> Suppose the keys of the time series of asset prices 
     * stored in this collection are <code>price_1</code>, <code>price_2</code>,
     * and <code>price_3</code>. The indices 1, 2, and 3 all refer to an
     * asset. Hence we might wish to indicate this in the output when these
     * indices appear on their own. For instance we might want to prefix
     * 'a' to indicate that  the indices refer to assets. The output then
     * becomes a1, a2, and a3 respectively. 
     * @param name the variable name of the time series
     * @param loc the location of the index for which you wish to add a prefix 
     * @param prefix the label used as a prefix
     */
    public void setIndexPrefix(String name, String loc, String prefix) {
        HashMap<String, String> map = indexMap.get(name);
        int index = 1;
        
        if (map == null) {
            map = new HashMap<String, String>();
            indexMap.put(name, map);
        }
        
        for (String key : getKeys()) {
            VersatileTimeSeries ats = getSeries(key);
            String varName = ats.extractVariableName(key.toLowerCase());
            
            if (varName.equalsIgnoreCase(name)) {
                map.put(loc + "-" + index, prefix + index);
                index++;
            }
        }
    }
    
    /**
     * Creates an dimension index string of a time series based
     * on the index map. 
     * <p>
     * <b>Example:</b> Consider the time series <code>order_2_65</code>. 
     * If no index map is defined for this particular order series, then
     * the string returned by this method will be something like "2 &nbsp 
     * 65". If a map is defined for the first index, e.g. (...,"2", 
     * "hedge",...), the string returned will be "hedge &nbsp 65"
     * <p>
     * <b>Note:</b> This method produces index strings with padded values. 
     * The size of the padding is not parameterised here.
     * @param ats the time series whose indices should be mapped, if 
     * applicable
     * @return the string containing the mapped, partially mapped, or
     * original dimension indices
     */
    private String mapIndices(VersatileTimeSeries ats) { 
        String mappedIndex = "";
        String key = (String) ats.getKey();
        String mapKey = "";
        String variableName = ats.extractVariableName(key);
        HashMap<String, String> map = indexMap.get(variableName);
        
        ArrayList<String> indices = ats.extractVariableIndices(key);    // gets the list of dimension indices
        
        // TODO leave the padding to the printDecorated method and use getIndexSeparator
        
        for (int i = 1; i <= indices.size(); i++) {
            if (map == null)    // if this time series has not mapped the index values, use the values themselves
                mappedIndex += StringUtils.leftPad(indices.get(i - 1), 5);
            else {
                mapKey = i + "-" + indices.get(i - 1);
                String entry = map.get(mapKey);
                if (entry == null)  // if the mapping is not defined, use the original index values
                    mappedIndex += StringUtils.leftPad(indices.get(i - 1), 5);
                else    // if a map is provided for the index, use the new index label
                    mappedIndex += StringUtils.leftPad(entry, 5);
            }
            
            if ((i < indices.size()) && (i != indices.size())) mappedIndex += internalParams.getIndexSeparator(); // chaining indices for multiple dimension indices
        }
        
        return mappedIndex;
    }
        
    /**====================================================================
     * 
     *      UTILITIES
     *      ---------
     *      
     *      Miscellaneous methods. 
     *      
     **====================================================================*/

    
    /**
     * Ensure that all time series have identical time stamps. This uses the method {@code compareTo()} of
     * the class {@link RegularTimePeriod}. {@link RegularTimePeriod} is an abstract class subclassed
     * by classes {@code Day, FixedMillisecond, Hour, Millisecond, Minute, Month, Quarter, Second, Week, Year}.
     * 
     * @return true if all time series in the collection have identical time stamps
     */
    public Boolean checkConsistency() {
        
        int numTs = this.getSeriesCount();
        
        Assertion.assertOrKill(numTs > 0, "Cannot use method checkConsistency() for empty time series collection");
        
        if (numTs == 1) return true;    // just one time series?
        
        TimeSeries baseTs = this.getSeries(0);  // the base time series with which all others in this collection are compared
        
        for (int i = 1; i < this.getSeriesCount(); i++) {
            
            TimeSeries ts = this.getSeries(i);
            
            if (ts.getItemCount() != baseTs.getItemCount()) return false;   // different lengths?
            
            for (int t = 0; t < ts.getItemCount(); t++)   // check all time stamps 
                if (ts.getTimePeriod(t).compareTo(baseTs.getTimePeriod(t)) != 0) return false;
        }
        
        return true;
    }

    /**====================================================================
     * 
     *      FORMATTED OUTPUT OF TIME SERIES COLLECTIONS
     *      -------------------------------------------
     *      
     *      Methods to generate formatted tables of time series. Use
     *      the print methods from the AdvancedTimeSeries class. 
     *      
     **====================================================================*/

    
    /**
     * A static method to print the DoubleTimeSeriesList. The formatting for the collection 
     * is that of the {@code VersatileTimeSeries}.
     * 
     * @param dtsl the set of DoubleTimeSeries
     * @return the output string
     */
    public static String printDecorated(DoubleTimeSeriesList dtsl) {
                
        VersatileTimeSeriesCollection vtsc = new VersatileTimeSeriesCollection("time series collection", dtsl);
                
        /**
         *  Compute width of the row label column
         */
        int maxWidthRowLabel = 0;
        
        for (int i = 0; i < dtsl.size(); i++)
            if (dtsl.get(i).getId().length() > maxWidthRowLabel) maxWidthRowLabel = dtsl.get(i).getId().length();
                        
        if (maxWidthRowLabel + 4 < VersatileTimeSeries.StaticInternalParams.getMinRowLabelWidth())
            maxWidthRowLabel = VersatileTimeSeries.StaticInternalParams.getMinRowLabelWidth();
        else
            maxWidthRowLabel += 4;
        
        /**
         * The width of the columns is equal to the parameter value COLUMN_WIDTH of the {@code VersatileTimeSeries}  
         */
        int width = VersatileTimeSeries.StaticInternalParams.getColumnWidth();
        
        String output = VersatileTimeSeries.printDecoratedTicks(dtsl.get(0), maxWidthRowLabel) + "\n";
        output += VersatileTimeSeries.printDecoratedRowSeparator(dtsl.get(0), maxWidthRowLabel) + "\n";
        
        for (int i = 0; i < dtsl.size(); i++)            
            output += VersatileTimeSeries.printDecoratedValues(dtsl.get(i), dtsl.get(i).getId(), maxWidthRowLabel) + "\n";
        
        return output;
    }
    
        
    /**
     * A static method to print the set of DoubleTimeSeries, provided as optional arguments. The formatting 
     * for the collection is that of the {@code VersatileTimeSeries}.
     * 
     * @param dtsArgs one or several DoubleTimeSeries 
     * @return the output string
     */
    public static String printDecorated(DoubleTimeSeries... dtsArgs) {
        
        DoubleTimeSeriesList dtsl = new DoubleTimeSeriesList();
        
        for (DoubleTimeSeries dts : dtsArgs)
            dtsl.add(dts);
        
        return printDecorated(dtsl);
    }

    /**
     * Prints all time series of this collection in a formatted table without
     * a tick, times, or dates header.
     * @param baseName the label used to indicate the variable name
     * @param width the width of the columns that hold the time series values
     * @return the string containing the formatted time series table
     */
    public String printDecoratedSeries(String baseName, int width) {
        return printDecoratedSeries(baseName, width, false);
    }
    
    /**
     * Prints all time series of this collection in a formatted table.
     * <p>
     * Uses the print methods from {@link VersatileTimeSeries}, but
     * adds the index map functionality (see {@link #newIndexMap(
     * String, String, String...)}) and the run and experiment 
     * indices. Rather than just printing one time series, it 
     * prints all time series in a formatted table form, with
     * ticks, times, or dates and an optional row separator.
     * <p>
     * <b>Note:</b> Currently this method uses a single label 
     * (<code>baseName</code>) as the variable name and hence cannot
     * be used to print out a collection that contains time series
     * of different variables. For such a collection, you first need
     * to obtain subsets of time series belonging to the same variable
     * using {@link #getSubset(String)} before printing. You can chain
     * the operations.
     * <p>
     * <b>Example:</b> Operations that return a collection can be chained. 
     * If <code>tscResults</code> is for instance a collection of time 
     * series that include prices, you can print these out by invoking
     * <code>tscResults.getSubset("price").printDecoratedSeries("PRICE", 
     * FIRST_COLUMN_WIDTH)</code> 
     * @param baseName the label used to indicate the variable name
     * @param width the width of the columns that hold the time series values
     * @param ticks true, if ticks, times, or dates are to be shown in a header
     * separated by a row separator. 
     * @return the string containing the formatted time series table
     */
    public String printDecoratedSeries(String baseName, int width, Boolean ticks) {
        List<VersatileTimeSeries> atsList = getSeries();
        String atsString ="";
        Boolean isHeaderPrinted = false;
        
        for (VersatileTimeSeries ats : atsList) {    // loops through all time series in this collection
            String label ="";
            String key = (String) ats.getKey();
//            ArrayList<String> indices = ats.extractVariableIndices(key);
//            String varName = ats.extractVariableName(key);
//            HashMap<String, String> map = indexMap.get(varName);
            String exp = ats.extractExperimentIndex(key);
            String run = ats.extractRunIndex(key);
            
            if (ticks && !isHeaderPrinted) {    // print the header only if requested and only once for this table
                atsString = ats.printDecoratedTicks(width) + "\n";
                atsString += ats.printDecoratedRowSeparator(width) + "--------------------\n";
                isHeaderPrinted = true;
            }
            
            // Generate the variable name and dimension indices (which might be mapped)
            label += StringUtils.rightPad(baseName, width);
            label += mapIndices(ats) + " | ";
            
            // Generate the run and experiment labels
            if ((exp != null) && (run != null))
                label += "{";
            
            if (exp != null) {
                label += StringUtils.capitalize(exp);
                if (run != null)
                    label += ", ";
            }
            
            if (run != null)
                label += StringUtils.capitalize(run);
            
            if ((exp != null) && (run != null))
                label += "}";

            atsString += label + " " + ats.printValues() + "   | " + label + "  " + "\n"; // assemble the output line 
        }
        
        return atsString;   // output string; typically consists of several lines 
    }
    
    
    /**====================================================================
     * 
     *      UTILITIES
     *      ---------
     *      
     **====================================================================*/
    
    
    /**
     * Returns the last tick of the first time series in the collection.
     * This is a hack to get the last tick. Currently there is no validation
     * as to whether all time series have the same tick, time, or date points.
     * @return the last tick as a RegularTimePeriod object
     * @see <a href="http://tinyurl.com/9s3hua8">RegularTimePeriod</a>
     */
    public RegularTimePeriod lastTick() {   // last tick of the first time series in set
        VersatileTimeSeries ats = (VersatileTimeSeries) getSeries(0);
        return ats.getTimePeriod(ats.getItemCount() - 1);
    }
    
    /**
     * Obtains a list of keys of all time series in this collection
     * @return the list of time series keys
     */
    private List<String> getKeys() {
        ArrayList<String> keys = new ArrayList<String>();
        List<VersatileTimeSeries> atsc = getSeries();
        
        for (VersatileTimeSeries ats : atsc)
            keys.add((String) ats.getKey());

        return keys;
    }
    
    /**
     * Checks whether a string represents a numeric
     * @param number the string that is to be tested
     * @return true if the string represents a numeric
     */
    private boolean isNumeric(String number) {  
        boolean isValid = false;  
        /*Explaination: 
                [-+]?: Can have an optional - or + sign at the beginning. 
                [0-9]*: Can have any numbers of digits between 0 and 9 
                \\.? : the digits may have an optional decimal point. 
            [0-9]+$: The string must have a digit at the end. 
            If you want to consider x. as a valid number change 
                the expression as follows. (but I treat this as an invalid number.). 
               String expression = "[-+]?[0-9]*\\.?[0-9\\.]+$"; 
         */  
        CharSequence inputStr = number;  
        Pattern pattern = Pattern.compile("^[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?$");  
        Matcher matcher = pattern.matcher(inputStr);  
        if(matcher.matches()){  
            isValid = true;  
        }  
        return isValid;  
    }
    
    /**
     * Default string representation of the collection as a list of time series
     * keys
     * @return a string of all time series keys
     */
    public String toString() {
        List<String> keys = getKeys();
        return keys.toString();
    }
}
