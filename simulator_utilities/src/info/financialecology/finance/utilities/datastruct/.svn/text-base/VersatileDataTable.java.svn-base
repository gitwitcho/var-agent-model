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

package info.financialecology.finance.utilities.datastruct;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;
import org.jfree.data.category.DefaultCategoryDataset;
import org.jfree.data.time.RegularTimePeriod;


/**
 * This class represents data in table form and provides methods to create,
 * transform, and format the table.
 * <p>
 * Tables are based on the <a href="http://tinyurl.com/cmdhzwn">
 * DefaultCategoryDataset</a> from the JFree library, where data 
 * is stored under row and column keys. The keys used in the 
 * <code>VersatileDataTable</code> class are strings.
 * <p>
 * Every column in the table contains values for a particular 
 * variable, and the keys of these variables are related to, 
 * but not identical with the column keys. While the key that 
 * identifies an {@link VersatileTimeSeries} is composed of 
 * the variable name, the dimension indices, and the run and 
 * experiment indices, the column key associated with a 
 * particular variable is composed of the variable name and the
 * dimension indices, while the run and experiment indices are 
 * used to construct the row key.
 *    
 * Example:
 *      
 *             price_1     price_2        
 * ---------------------------------
 *   r1_e1 |   100.34       98.52
 *   r2_e1 |   101.06       96.93
 *   r1_e2 |    99.41       92.23
 *   r2_e2 |    98.30       89.90
 *        
 * @author Gilbert Peffer
 * @see VersatileTimeSeries
 *
 */
public class VersatileDataTable extends DefaultCategoryDataset {

    private static final long serialVersionUID = -1887356362358556552L;
    
    private String id;
    
    /**
     * A map to transform a variable's dimension index, to improve human
     * readability. Used to format output of data tables.
     * @see #newIndexMap(String, String, String...) 
     */
    private static HashMap<String, HashMap<String, String>> indexMap;

//    private HashSet<String> varNames;

    /**====================================================================
     * 
     *      GLOBAL AND INSTANCE-LEVEL PARAMETERS
     *      ------------------------------------
     *      
     *      When writing time series for instance to the console, the 
     *      debug window, or to a text file, the output format is 
     *      determined on the basis of a number of parameters.
     *      
     *      Formatting parameters are defined both on a class level as
     *      well as on an instance level. Parameters are initialised with
     *      predetermined, class level values that can be overwritten,
     *      both on the class level (using the set functions defined in 
     *      StaticInternalParams) as well as on the instance level (using
     *      the overwrite functions defined in InternalParams). Overwriting
     *      parameters on the instance level allows special formatting for
     *      a single time series object.
     *      
     **====================================================================*/

    
    /**
     * The width of the output column for the output of the data points.
     * <p>
     * Allows for adjusting the width depending for instance on the chosen 
     * output accuracy for the data points. The column width together with the 
     * {@link #NUMBER_ACCURACY NUMBER_ACCURACY} and the {@link #NUMBER_TYPE NUMBER_TYPE} 
     * are used to format the standard output of the time series.
     */
    private static int COLUMN_WIDTH = 11;

    /**
     * The number of significant decimals to the right of the decimal point
     * for the output of the data points.
     * <p>
     * The number accuracy together with the {@link #NUMBER_TYPE NUMBER_TYPE} 
     * and the {@link #COLUMN_WIDTH COLUMN_WIDTH} are used to format the standard output 
     * of the time series.
     */
    private static int NUMBER_ACCURACY = 6;
    
    /**
     * The standard numeric format string for the output of the data points.
     * <p>
     * There exist numerous numeric formats such as decimal ("d"), percent ("p")
     * and scientific ("g"). The numeric format string together with the 
     * {@link #NUMBER_ACCURACY NUMBER_ACCURACY} and the {@link #COLUMN_WIDTH COLUMN_WIDTH} 
     * are used to format the standard output of the time series.
     * 
     * @see <a href="http://tinyurl.com/63w7zw">Standard numeric format strings</a>
     */
    private static String NUMBER_TYPE = "g";

    /**
     * The symbol separating variables and indices from other indices.
     * <p>
     * Variables can be indexed for a number of reasons. First, variables
     * can be vector-valued and the index indicates the position of the value 
     * in the vector. Second, for experiments consisting of several runs and 
     * for multiple experiments, variables are indexed with the run and the 
     * experiment index.
     * <p>
     * Indexed variables are used as keys to store data and as column headers 
     * for standard output and for data columns in csv files. The index uniquely 
     * identifies a data set in a simulation.
     * <p>
     * <b>Note:</b> To store variables that are time-indexed (i.e. time series)
     * use the {@link VersatileTimeSeries} class.
     * <p>
     * <b>Examples</b>: final_price_1, final_price_2, vol_r4, kurt_e2_r13; note 
     * that these variables are not time-indexed, but store cross-sectional or
     * aggregate data. E.g. vol_r4 might represent the overall volatility of 
     * returns for run 4.
     */
    private static String INDEX_SEPARATOR = "_";
    
    
    private InternalParams internalParams;
    
    /**
     * The global data structure storing data table output format parameters.
     * <p>
     * Provides static setters for the parameters. See the field summary of 
     * {@link VersatileDataTable} for a description of the corresponding parameters.
     * <p>
     * Instance-level (local) parameters are specific to the object while the global 
     * parameters are static and hence have class-level scope. The global parameters 
     * are used to set parameter values for all <code>VersatileDataTable</code> 
     * objects, while the local parameters can be used to overwrite the global values 
     * for a particular object.   
     */
    public static class StaticInternalParams {
        public static void setIndexSeperator(String sIndexSeparator) {
            INDEX_SEPARATOR = sIndexSeparator;
        }
        
        public static void setColumnWidth(int columnWidth) {
            COLUMN_WIDTH = columnWidth;
        }

        public static void setNumberAccuracy(int numberAccuracy) {
            NUMBER_ACCURACY = numberAccuracy;
        }

        public static void setNumberType(String numberType) {
            NUMBER_TYPE = numberType;
        }
    }
    
    /**
     * The local data structure for data table output format parameters.
     * <p>
     * For an explanation of local vs. global formats, see <code>StaticInternalParams</code>.
     * See the field summary in {@link VersatileDataTable} for a description of the
     * format parameters.
     * <p>
     * This class provides getters that return the data table parameter values and 
     * methods that allow overriding global values of these parameters.
     */
    public class InternalParams {
        
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileDataTable#INDEX_SEPARATOR
         */
        private String indexSeparator;

        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileDataTable#COLUMN_WIDTH
         */
        private int columnWidth;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileDataTable#NUMBER_ACCURACY
         */
        private int numberAccuracy;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileDataTable#NUMBER_TYPE
         */
        private String numberType;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see #getNumberFormat()
         */
        private String numberFormat;
        
        /**
         * Initialises local parameters to global (class-level)
         * values.
         */
        protected InternalParams() {
            indexSeparator = INDEX_SEPARATOR;
            columnWidth = COLUMN_WIDTH;
            numberAccuracy = NUMBER_ACCURACY;
            numberType = NUMBER_TYPE;
            numberFormat = generateNumberFormat();
        }
        
        /**
         * Makes a copy of the parameter object.
         * 
         * @param params the original parameter object
         */
        protected InternalParams(InternalParams params) {   // copy constructor
            this.indexSeparator = params.getIndexSeparator();
            this.columnWidth = params.getColumnWidth();
            this.numberAccuracy = params.getNumberAccuracy();
            this.numberType = params.getNumberType();
            this.numberFormat = params.getNumberFormat();
        }
        
        /**
         * Overrides the field {@link VersatileDataTable#INDEX_SEPARATOR}
         * 
         * @param indexSeparator the string symbol separating variable names 
         * and indices from other indices.
         */
        public void overrideIndexSeparator(String sIndexSeparator) {
            indexSeparator = sIndexSeparator;
        }
        
        /**
         * Overrides the field {@link VersatileDataTable#COLUMN_WIDTH}
         * 
         * @param columnWidth the width of the column holding time series data.
         */
        public void overrideColumnWidth(int columnWidth) {
            this.columnWidth = columnWidth;
            this.numberFormat = generateNumberFormat();
        }
        
        /**
         * Overrides the field {@link VersatileDataTable#NUMBER_ACCURACY}
         * 
         * @param numberAccuracy the number of significant decimals to the right 
         * of the decimal point.
         */
        public void overrideNumberAccuracy(int numberAccuracy) {
            this.numberAccuracy = numberAccuracy;
            this.numberFormat = generateNumberFormat();
        }
        
        /**
         * Overrides the field {@link VersatileDataTable#NUMBER_TYPE}
         * 
         * @param numberType the string indicating the number format ("g", "d", etc.)
         */
        public void overrideNumberType(String numberType) {
            this.numberType = numberType;
            this.numberFormat = generateNumberFormat();
        }
        
        /**
         * Obtain the object-level value of the time series format parameter.
         * 
         * @see #overrideIndexSeparator(String) 
         */
        public String getIndexSeparator() {
            return indexSeparator;
        }

        /**
         * Obtain the object-level value of the time series format parameter.
         * 
         * @see #overrideColumnWidth(int)
         */
        public int getColumnWidth() {
            return columnWidth;
        }

        /**
         * Obtain the object-level value of the time series format parameter.
         * 
         * @see #overrideNumberAccuracy(int)
         */
        public int getNumberAccuracy() {
            return numberAccuracy;
        }

        /**
         * Obtain the object-level value of the time series format parameter.
         * 
         * @see #overrideNumberType(String)
         */
        public String getNumberType() {
            return numberType;
        }

        /**
         * Obtain the object-level value of the time series format parameter.
         * 
         * @see #generateNumberFormat()
         */
        public String getNumberFormat() {
            return numberFormat;
        }
        
        /**
         * Generate the number format string based on the {@link #columnWidth},
         * {@link #numberAccuracy}, and {@link #numberType}. 
         * 
         * @return the format string
         */
        private String generateNumberFormat() {
            return "%" + getColumnWidth() + "." + getNumberAccuracy() + getNumberType();
        }
    }

    
    /**====================================================================
     * 
     *      CONSTRUCTORS
     *      ------------
     *      
     **====================================================================*/

    
    public VersatileDataTable(String id) {
        this.id = id;
        internalParams = new InternalParams(); 
//        varNames = new HashSet<String>();
        if (indexMap == null)
            indexMap = new HashMap<String, HashMap<String, String>>();
    }
    
//    public VersatileDataTable(String id, String... sVarNames) {
//        this(id);
//        
//        for (String varName : sVarNames)
//            varNames.add(varName);
//    }
//    
//    public void addVariable(String sVarName) {
//        Assertion.assertStrict(!varNames.contains(sVarName), Assertion.Level.ERR, "The variable '" + sVarName + "' in the VersatileDataTable '" + thisId + "' already exists");
//        varNames.add(sVarName);
//    }
//    
//    public void addVariables(String... varNames) {
//        
//        for (String varName : varNames) {
//            addVariable(varName);
//        }
//    }
//    
//    public void addVariables(int numIndexed, String... varNames) {
//        Assertion.assertStrict(numIndexed > 0, Assertion.Level.ERR, "The number of indexed variables in the VersatileDataTable '" + thisId + "' has to be larger than '0', but is " + numIndexed);
//        
//        if (numIndexed == 1) addVariables(varNames);
//        
//        for (String varName : varNames) {
//            for (int i = 1; i <= numIndexed; i++)
//                addVariable(varName + internalParams.getIndexSeparator() + i);
//        }
//    }
    
    public InternalParams getInternalParams() {
        return internalParams;
    }
    
    
    /**====================================================================
     * 
     *      ADDING VALUES TO THE TABLE
     *      --------------------------
     *      
     *      Methods that add values to the table.
     *      
     **====================================================================*/

    
    /**
     * Adds a value to the table where the complete variable key is 
     * provided.
     * <p>
     * <b>Example:</b> For <code>order_2_81_r2_e4=100</code>, the value 100 
     * is written into the table cell with column key <code>order_2_81</code>
     * and row key <code>r2_e4</code>. For <code>vol_r1=0.8</code>, the value 0.8 
     * is written into the table cell with column key <code>vol</code>
     * and row key <code>r1</code>.
     * @param key the key that uniquely identifies the variable
     * @param value the value of the variable
     */
    public void addValue(String key, double value) {
        key = key.toLowerCase();
        int iExp = extractExperimentIndex(key);    // TODO centralise extraction methods
        int iRun = extractRunIndex(key);
        String name = extractVariableName(key);
        ArrayList<String> indices = extractVariableIndices(key);
                
        addValue(iExp, iRun, name,  value, generateIndexString(indices));
    }
    
    /**
     * Adds a set of values to the table where the complete variable keys
     * are provided. The variable keys and associated values are provided
     * as a hash map, where the variable key serves as the hash map key.
     * <p>
     * See {@link #addValue(String, double)} for some examples.
     * @param map the hash map that stores the variable values under the
     * unique variable keys
     */
    public void addValue(HashMap<String, Double> map) {
        for (String label : map.keySet()) {
            String name = extractVariableName(label);
            double value = map.get(label);
            int iExp = extractExperimentIndex(label);
            int iRun = extractRunIndex(label);
            ArrayList<String> indices = extractVariableIndices(label);
            
            addValue(iExp, iRun, name, value, generateIndexString(indices));
        }
    }
    
    /**
     * Adds a value to the table where only variable name and optional
     * dimension indices are provided.
     * <p>
     * <b>Note</b> The variable argument list permits zero arguments. 
     * @param varName the variable name (without indices)
     * @param value the value of the variable
     * @param indices the dimension indices (zero or more)
     */
    public void addValue(String varName, double value, int... indices) {
      addValue(0, 0, varName, value, indices);
    }
  
    /**
     * Adds a value to the table where only variable name, run index, and 
     * optional dimension indices are provided.
     * <p>
     * <b>Note</b> The variable argument list permits zero arguments. 
     * @param varName the variable name (without indices)
     * @param value the value of the variable
     * @param iRun the run index
     * @param indices the dimension indices (zero or more)
     */
    public void addValue(int iRun, String varName, double value, int... indices) {
      addValue(0, iRun, varName, value, indices);
    }
  
    /**
     * Adds a value to the table where the variable name, run index, 
     * experiment index and optional dimension indices are provided. Effectively
     * the same than {@link #addValue(String, double), but the variable
     * key in this method is split into its components. 
     * <p>
     * <b>Note</b> The variable argument list permits zero arguments. 
     * @param varName the variable name (without indices)
     * @param value the value of the variable
     * @param iRun the run index
     * @param iExp the run index
     * @param indices the dimension indices (zero or more)
     */
    public void addValue(int iExp, int iRun, String varName, double value, int... indices) {
        addValue(iExp, iRun, varName, value, generateIndexString(indices));
    }

    /**
     * Adds a value to the table when the dimension, run, and 
     * experiment indices are given.
     * <p>
     * Every column in the table contains values for a particular 
     * variable, and the keys of these variables are related to, 
     * but not identical with the column keys. While the key that 
     * identifies an {@link VersatileTimeSeries} is composed of 
     * the variable name, the dimension indices, and the run and 
     * experiment indices, the column key associated with a 
     * particular variable is composed of the variable name and the
     * dimension indices, while the run and experiment indices are 
     * used to construct the row key.
     * <p>
     * <b>Example:</b>
     * <p>
     * &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp price_1 &nbsp price_2  <br>
     * ---------------------------------<br>
     * &nbsp   r1_e1 |   &nbsp 100.34 &nbsp &nbsp 98.52   <br>
     * &nbsp   r2_e1 |   &nbsp 101.06 &nbsp &nbsp 96.93   <br>
     * &nbsp   r1_e2 |   &nbsp 99.41  &nbsp &nbsp &nbsp 92.23   <br>
     * &nbsp   r2_e2 |   &nbsp 98.30  &nbsp &nbsp &nbsp 89.90   <br>
     *      
     * @param varName the name of the variable (without indices)
     * @param value the value of the variable
     * @param iExp the experiment index
     * @param iRun the run index
     * @param indices the dimension indices (as a string, e.g. "1_12_2")
     */
    public void addValue(int iExp, int iRun, String varName, double value, String indices) {
        String rowLabel = "";
        
        if (iRun > 0) {
            rowLabel = "r" + iRun;
            if (iExp > 0)
                rowLabel += internalParams.getIndexSeparator() + "e" + iExp;
        }
        else if (iExp > 0)
            rowLabel = "e" + iExp;
        else
            rowLabel = "Simulation";
        
        varName += internalParams.getIndexSeparator() + indices;
        
        // Insert 'value' into table at row = 'rowLabel' and col = 'varName'
        addValue(value, rowLabel, varName);
    }

    /**
     * Adds a value to the data table, where this value is extracted from a
     * time series at a given tick/time/date. The column and row keys are derived
     * from the time series key (the column key is composed of the variable name 
     * plus the dimension indices; the row key is composed of the run and experiment
     * indices, e.g. <code>r3_e5</code>).
     * @param ats the time series
     * @param tick the tick/time/date at which to extract the value
     */
    public void addTimeSlice(VersatileTimeSeries ats, RegularTimePeriod tick) {
        int iExp = 0, iRun = 0;
        double value = ats.getValue(tick).doubleValue();
        String key = (String) ats.getKey();
        String exp = ats.extractExperimentIndex(key);
        String run = ats.extractRunIndex(key);
        String name = ats.extractVariableName(key);
        ArrayList<String> indices = ats.extractVariableIndices(key);
        
//        if (exp != null) {
//            exp = exp.toLowerCase();
//            iExp = Integer.valueOf(StringUtils.remove(exp, 'e'));
//        }
//        
//        if (run != null) {
//            run = run.toLowerCase();
//            iRun = Integer.valueOf(StringUtils.remove(run, 'r'));
//        }
//        
//        if (iExp != 0) {
//            if (iRun != 0)
//                addValue(iExp, iRun, name, value, generateIndexString(indices));
//        }
//        else {
//            if (iRun != 0)
//                addValue(0, iRun, name,  value, generateIndexString(indices));
//            if (iRun == 0)
//                addValue(0, 0, name,  value, generateIndexString(indices));
//        }
        
        addValue(key, value);
    }

    /**
     * Adds values to the data table, where these values are extracted at a 
     * given tick/time/date from a collection of time series. 
     * <p>
     * See {@link #addTimeSlice(VersatileTimeSeries, RegularTimePeriod)} for
     * more details.
     * @param atsc the time series collection
     * @param tick the tick/time/date at which to extract the value
     */
    public void addTimeSlice(VersatileTimeSeriesCollection atsc, RegularTimePeriod tick) {
        List<VersatileTimeSeries> atsList = atsc.getSeries();
        
        for (VersatileTimeSeries ats : atsList)
            addTimeSlice(ats, tick);
    }
    
    
    /**====================================================================
     * 
     *      ALGEBRAIC AND STATISTICAL OPERATORS
     *      -----------------------------------
     *      
     **====================================================================*/

    
    /**
     * Merges a data table with this table. The columns of the table passed
     * as an argument are added to this table.
     * <p>
     * <b>Note:</b> This method does not enforce consistency between both tables.
     * This means that the neither the number of rows nor the row labels have
     * to coincide. 
     * @param acds the table that is to be merged with this table
     */
    public void merge(VersatileDataTable acds) {
        List<String> rowKeys = acds.getRowKeys();
        List<String> columnKeys = acds.getColumnKeys();
        
        // TODO optionally check for row label consistency, via additional bool argument 
        
        for (String rowKey : rowKeys) {
            for (String columnKey : columnKeys) {
                addValue(acds.getValue(rowKey, columnKey), rowKey, columnKey);
            }
        }
    }
    
    /**
     * Multiplies the values of a given subset of the variables in the 
     * table with a factor.
     * <p>
     * String labels passed as arguments are used
     * to match the column keys that identify which variables are to be 
     * multiplied. E.g. the label <code>price</code> matches the column
     * keys <code>price_1</code> and <code>price_2</code>.
     * @param multipler factor with which to multiple the selected columns 
     * @param labels a set of filters to match column keys against
     */
    public void columnMultiply(double multipler, String... labels) {
        List<String> columnKeys = getColumnKeys();
        List<String> rowKeys = getRowKeys();
        
        for (String label : labels) {
            for (String columnKey : columnKeys) {

                if (isSubsetOf(columnKey, label)) {
                    for (String rowKey : rowKeys) {
                        if (!StringUtils.startsWith(rowKey, "#")) {     // exclude calculated elements of the table, e.g. column average
                            double value = getValue(rowKey, columnKey).doubleValue();
                            setValue(value * multipler, rowKey, columnKey);
                        }
                    }
                }
            }
        }
    }
    
    /**
     * Computes the column-wise average of values whose column key matches
     * any of the labels passed as arguments. The result is appended
     * to the bottom of the table and prefixed with a '#' symbol
     * to prevent methods such as {@link #columnMultiply(double, String...)}
     * to operate on them.
     * @param rowLabel the name of the result as it should appear in the
     * leftmost row
     * @param labels a set of filters to match column keys against
     */
    public void insertColumnAverage(String rowLabel, String... labels) {
        List<String> columnKeys = getColumnKeys();
        List<String> rowKeys = getRowKeys();
        rowLabel = "# " + rowLabel;
        
        for (String label : labels) {
            for (String columnKey : columnKeys) {
                double avg = 0, count = 0;

                if (isSubsetOf(columnKey, label)) {
                    for (String rowKey : rowKeys) {
                        if (!StringUtils.startsWith(rowKey, "#")) {
                            avg += getValue(rowKey, columnKey).doubleValue();
                            count++;
                        }
                    }
                }
                
                if (count > 0) {
                    avg = avg / count;
                    setValue(avg, rowLabel, columnKey);
                }
            }
        }
    }
    
    /**
     * Computes the column-wise standard deviation of values whose column 
     * key matches any of the labels passed as arguments. The result is 
     * appended to the bottom of the table and prefixed with a '#' symbol
     * to prevent methods such as {@link #columnMultiply(double, String...)}
     * to operate on them.
     * @param rowLabel the name of the result as it should appear in the
     * leftmost row
     * @param labels a set of filters to match column keys against
     */
    public void insertColumnStdev(String rowLabel, String... labels) {
        DescriptiveStatistics   stats = new DescriptiveStatistics();
        
        List<String> columnKeys = getColumnKeys();
        List<String> rowKeys = getRowKeys();
        rowLabel = "# " + rowLabel;
        
        for (String label : labels) {
            for (String columnKey : columnKeys) {

                if (isSubsetOf(columnKey, label)) {
                    for (String rowKey : rowKeys) {
                        if (!StringUtils.startsWith(rowKey, "#")) {
                            stats.addValue(getValue(rowKey, columnKey).doubleValue());
                        }
                    }
                }
                
                setValue(stats.getStandardDeviation(), rowLabel, columnKey);
                stats.clear();
            }
        }
    }
    
    
    
    /**====================================================================
     * 
     *      'KEY' OPERATORS
     *      ---------------
     *      
     *      Key operators are methods that operate on the column key.
     *      
     **====================================================================*/
    
    
    // TODO move these methods to a utility class since they are also defined in the class AdvancedTimeSeries
    
    /**
     * Extracts the string representing the variable name from the <code>key</code>.
     * For instance, the variable name for the label <code>price_2_r3_e1</code>
     * is <code>price</code>.
     * <p>  
     * @param key the label from which we want to extract the variable name
     * @return the variable name or null if not found
     */
    public String extractVariableName(String key) {
        String [] tokens = key.split(internalParams.getIndexSeparator());
        int count = 0;
        String varName = null;

        for (String token : tokens) {
            if (isInteger(token))
                break;
            else if (token.startsWith("e") && isInteger(token.substring(1)))    
                break;
            else if (token.startsWith("r") && isInteger(token.substring(1)))    
                break;
            
            count++;
        }
        
        if (count == tokens.length)
            varName = key;
        else if (count != 0) {
            varName = tokens[0];
            for (int i = 1; i < count; i++)
                varName += internalParams.getIndexSeparator() + tokens[i]; 
        }

        return varName;
    }

    /**
     * Extracts the dimension indices from the <code>key</code> and adds them 
     * to an array. For instance, the indices for the key
     * <code>order_4_825_r12</code> are "4" and "825".
     * <p>
     * @param key the label from which we want to extract the dimension indices
     * @return an <code>ArrayList</code> of dimension indices
     */
    public ArrayList<String> extractVariableIndices(String key) {
        String [] tokens = key.split(internalParams.getIndexSeparator());
        ArrayList<String> varIndices = new ArrayList<String>();

        for (String token : tokens) {
            if (isInteger(token))
                varIndices.add(token);
        }
        
        return varIndices;
    }

    /**
     * Extracts the experiment index from the <code>key</code>. For instance
     * the index for the label <code>vol_r1_e5</code> is "e5".
     * <p>
     * @param key the label from which we want to extract the experiment index
     * @return the experiment index
     */
    public int extractExperimentIndex(String key) {
        String [] tokens = key.split(internalParams.getIndexSeparator());
        int expIndex = -1;

        for (String token : tokens) {
            if (token.startsWith("e") && isInteger(token.substring(1)))
                expIndex = Integer.valueOf(token.substring(1));
        }
        
        return expIndex;
    }

    /**
     * Extracts the run index from the <code>key</code>. For instance
     * the index for the label <code>vol_r1_e5</code> is "r1".
     * <p>
     * @param key the label from which we want to extract the run index
     * @return the run index
     */
    public int extractRunIndex(String key) {
        String [] tokens = key.split(internalParams.getIndexSeparator());
        int runIndex = -1;

        for (String token : tokens) {
            if (token.startsWith("r") && isInteger(token.substring(1)))
                runIndex = Integer.valueOf(token.substring(1));
        }
        
        return runIndex;
    }

    private String generateIndexString(ArrayList<String> indices) {
        String sep = "";
        
        for (int i = 0; i < indices.size(); i++) {
            if (i < indices.size() - 1)
                sep += indices.get(i) + internalParams.getIndexSeparator();
            else
                sep += indices.get(i);
        }
        
        return sep;
    }

    /**
     * Generates a index string based on numeric indices. Used to construct
     * a string representation of a variable's dimension indices.
     * <p>
     * <b>Example:</b> For dimension indices 4 and 56, the string 
     * representation is "4_56" (index separator is '_' in this case)
     * @param indices a set of indices
     * @return a string representation of the dimension indices
     */
    private String generateIndexString(int... indices) {
        String sep = "";
        
        // TODO validate number of indices > 0
        
        for (int i = 0; i < indices.length; i++) {
            if (i < indices.length - 1)
                sep += indices[i] + internalParams.getIndexSeparator();
            else
                sep += indices[i];
        }
        
        return sep;
    }
    
    /**
     * Checks whether one string matches another using the 'variable name,
     * dimension indices, run index, experiment index' pattern. This method is
     * very similar to {@link VersatileTimeSeries#matches(String)}, but without
     * run and experiment matching.
     * <p>
     * See {@link VersatileTimeSeries#matches(String)} for more details
     * <p>
     * <b>Example:</b> The string <code>price_4</code> matches the string
     * <code>price</code>.
     * @param subset the string to match
     * @param superset the string against which to match
     * @return true, if there is a match
     * @see VersatileTimeSeries#matches(String)
     */
    public Boolean isSubsetOf(String subset, String superset) {
        //      String key = (String) getKey();
        
        // TODO rename method to 'matches'
        // TODO the method in AdvancedTimeSeries is almost the same and can actually be used here; move both to a utility class for index matching and construction

        // Does the variable name coincide?
        String testForVariableName = extractVariableName(subset);

        if (testForVariableName != null) {
            if (!extractVariableName(superset.toLowerCase()).equalsIgnoreCase(testForVariableName))
                return false; 
        }

        // Does the index coincide? (indices that ought to be ignored should be set to '-1' in subset
        ArrayList<String> subsetIndices = extractVariableIndices(subset);
        ArrayList<String> supersetIndices = extractVariableIndices(superset);

        for (int i = 0; i < supersetIndices.size(); i++) {
            int supersetIndex = Integer.valueOf(supersetIndices.get(i));

            if (supersetIndex != -1)
                if (subsetIndices.size() < i + 1)
                    return false;
                else if (supersetIndex != Integer.valueOf(subsetIndices.get(i)))
                    return false;
        }

        return true;
    }

    
    /**====================================================================
     * 
     *      INDEX MAPPING
     *      -------------
     *      
     *      A number of methods are provided to transform indices into
     *      more human readable formats. This is used mainly for output
     *      formatting. For instance, rather than print 'cash_1', we can
     *      use the method <code>newIndexMap</code> to map index "1" into 
     *      a new index "bank". This has only an effect on how the labels 
     *      are written to the output.
     *      
     *      The method <code>printDecoratedTable()</code> for 
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
     * The method {@link #printDecoratedTable()} uses the index 
     * map when printing out formatted time series tables.
     * <p>
     * See {@link VersatileTimeSeriesCollection#newIndexMap(String, String, String...)}
     * for more details
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
     * Creates an dimension index string of a variable based
     * on the index map. 
     * <p>
     * <b>Example:</b> Consider the variable <code>order_2_65</code>. 
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
    private String mapIndices(String columnKey) { 
        String mappedIndex = "";
        String mapKey = "";
        String variableName = extractVariableName(columnKey);
        HashMap<String, String> map = indexMap.get(variableName);
        
        ArrayList<String> indices = extractVariableIndices(columnKey);
        
        // TODO use getIndexSeparator

        for (int i = 1; i <= indices.size(); i++) {
            if (map == null)
                mappedIndex += "_" + indices.get(i - 1);
            else {
                mapKey = i + "-" + indices.get(i - 1);
                String entry = map.get(mapKey);
                if (entry == null)
                    mappedIndex += "_" + indices.get(i - 1);
                else
                    mappedIndex += "_" + entry;
            }
            
//            if (i < indices.size()) mappedIndex += " ";
        }
        
        return mappedIndex;
    }
    
    
    /**====================================================================
     * 
     *      UTILITIES
     *      ---------
     *      
     **====================================================================*/
    
    
    /**
     * Checks whether a given string represents an integer 
     * @param str the string that is to be tested
     * @return true, if the string represents an integer
     */
    private Boolean isInteger(String str) {
        try {
            Integer.parseInt(str);
        } catch (Exception e) {
            return false;
        }
        
        return true;
    }
    

    /**====================================================================
     * 
     *      FORMATTED OUTPUT OF DATA TABLE
     *      ------------------------------
     *      
     *      Methods to generate formatted data tables.
     *      
     **====================================================================*/

    
    /**
     * Prints the table without title 
     * @return the string containing the formatted table
     */
    public String printDecoratedTable() {
        return printDecoratedTable(null);
    }
    
    /**
     * Prints the table with a title.
     * <p>
     * The table consists of a title, a header, and the values.
     * @return the string containing the formatted table
     */
    public String printDecoratedTable(String title) {
        String ts = "";
//        int padding = 8;
//        int margin = 2;
//        
//        if ((title != null) && !title.equalsIgnoreCase("")) {
//            ts += StringUtils.repeat(' ', margin) + StringUtils.repeat('*', 2 + 2 * padding + title.length()) + "\n";
//            ts += StringUtils.repeat(' ', margin) + "*" + StringUtils.repeat(' ', padding) + title + StringUtils.repeat(' ', padding) + "*\n";
//            ts += StringUtils.repeat(' ', margin) + StringUtils.repeat('*', 2 + 2 * padding + title.length()) + "\n\n";        
//        }

        ts += printRowSeparator("=") + "\n";
        ts += "  " + title + "\n";
        ts += printRowSeparator("-") + "\n";
        ts += printHeaders() + "\n";
        ts += printRowSeparator("-") + "\n";
        ts += printValues();
        return ts;
    }

    /**
     * Prints a horizontal separator. Used for instance to separate 
     * the header row from the values. The total width of the separator
     * depends on the column width parameter.
     * @param sep the separator symbol
     * @return a sequence of separator strings
     */
    public String printRowSeparator(String sep) {
        String ts = sep;
        int nItems = getColumnCount();
        
        ts += StringUtils.repeat(sep, 12);  // TODO the value '12' should be a parameter
        
        for (int i = 0; i < nItems; i++) {
            ts += sep + StringUtils.repeat(sep, internalParams.getColumnWidth() + 1);
        }
        
        return ts + sep;
    }
    
    /**
     * Prints a header row. The total width of the header row
     * depends on the column width parameter.
     * @return the header
     */
    public String printHeaders() {
        String ts = " ";
        int nItems = getColumnCount();
        
        ts += StringUtils.repeat(' ', 12);
        
        for (int i = 0; i < nItems; i++) {
            String columnKey = (String) getColumnKey(i);
            String label = extractVariableName(columnKey);
            label += mapIndices(columnKey);
            
            ts += " " + StringUtils.leftPad(label, internalParams.getColumnWidth() + 1);
        }
        
        return ts += " ";
    }
    
    /**
     * Prints all rows containing values.
     * @return the header
     */
    public String printValues() {
        String ts = "";
        String tsLast = "";
        List<String> rowKeys = getRowKeys();
        List<String> columnKeys = getColumnKeys();
        
        for (String rowKey : rowKeys) {
            if (StringUtils.startsWith(rowKey, "#")) {
                tsLast += "  " + StringUtils.rightPad(rowKey, 8) + " | ";   // TODO leftmost column width should be a parameter
                for (String columnKey : columnKeys)
                    tsLast += " " + String.format(" " + internalParams.getNumberFormat(), getValue(rowKey, columnKey).doubleValue());
                tsLast += "\n";
            }
            else {
                ts += "  " + StringUtils.rightPad(rowKey, 8) + " | ";
                for (String columnKey : columnKeys)
                    ts += " " + String.format(" " + internalParams.getNumberFormat(), getValue(rowKey, columnKey).doubleValue());
                ts += "\n";
            }
        }

//        for (int i = 0; i < getRowCount(); i++) {
//            ts += "  " + StringUtils.rightPad((String) getRowKey(i), 4) + " | ";
//            for (int j = 0; j < getColumnCount(); j++)
//                ts += " " + String.format(" " + internalParams.getNumberFormat(), getValue(i, j).doubleValue());
//            ts += "\n";
//        }
        
        if (!tsLast.equalsIgnoreCase(""))
            ts += printRowSeparator(".") + "\n" + tsLast;
        
        return ts + " ";
    }

    /**
     * Calls {@link #printDecoratedTable(String)}.
     * @return a string with the formatted table
     */
    public String toString() {
        return printDecoratedTable(this.id);
    }
}
