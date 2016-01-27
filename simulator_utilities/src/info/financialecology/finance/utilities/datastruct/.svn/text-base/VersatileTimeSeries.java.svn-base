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

import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.Assertion.Level;

import java.text.SimpleDateFormat;
import java.util.ArrayList;

import org.jfree.data.time.Day;
import org.jfree.data.time.RegularTimePeriod;
import org.jfree.data.time.TimeSeries;
import org.jfree.data.time.TimeSeriesDataItem;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;

import cern.colt.list.DoubleArrayList;
import cern.jet.stat.Descriptive;



/**
 * This class represents a time series and provides methods for basic statistical analyses,
 * for time series transformation and output formatting. Formatting behaviour is controlled
 * by class-level (static) parameters that can be overwritten by setting local values of
 * these parameters using the <code>overwrite</code> methods.
 * <p>
 * This class is based on the <a href="http://tinyurl.com/9s3hua8">JFree</a> Java graphics 
 * library and hence can be used directly as input to the JFree graphics classes. The
 * class {@link VersatileChart} contains utilities that facilitate graphing for the 
 * {@link VersatileTimeSeries},{@link VersatileTimeSeriesCollection}, and 
 * {@link VersatileDataTable} classes.  
 * <p>
 * @author Gilbert Peffer
 * @see VersatileTimeSeriesCollection
 * @see VersatileDataTable
 * @see VersatileDataTable
 * @see VersatileChart
 *
 */
public class VersatileTimeSeries extends TimeSeries {
    
    private static final long serialVersionUID = 5456894803155352002L;
        
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
     * The first <code>MAX_OUTPUT_HEAD</code> time series points are written to the standard output.
     * <p>
     * For simulations with a large number of ticks, writing the complete time series out 
     * to the console or to a text file is problematic. We therefore prune the time
     * series and only write the first <code>MAX_OUTPUT_HEAD</code> and last
     * <code>MAX_OUTPUT_TAIL</code> time series points to the console, and separate
     * both with an ellipsis.
     * <p>
     * Example output for <code>MAX_OUTPUT_HEAD = 4</code> and <code>MAX_OUTPUT_TAIL = 2</code>:
     * <p>
     * &nbsp; &nbsp; &nbsp; 12.4 &nbsp; &nbsp; 5.6 &nbsp; &nbsp; 34.7 &nbsp; &nbsp; -8.9 &nbsp; &nbsp; ... &nbsp; &nbsp; 4.0 &nbsp; &nbsp; 54.2
     */
    private static int MAX_OUTPUT_HEAD = 130;
    
    /**
     * The last <code>MAX_OUTPUT_TAIL</code> time series points are written to the standard output.
     * <p>
     * See {@link #MAX_OUTPUT_HEAD MAX_OUTPUT_HEAD} for details.
     */
    private static int MAX_OUTPUT_TAIL = 20;
    
    /**
     * The symbol separating variables and indices from other indices.
     * <p>
     * Time series variables can be indexed for a number of reasons. First, variables
     * can be vector-valued and the index indicates the position of the value 
     * in the vector. Second, for experiments consisting of several runs and 
     * for multiple experiments, variables are indexed with the run and the 
     * experiment index.
     * <p>
     * Indexed variables are used as keys to store time series and as column headers 
     * for standard output and for data columns in csv files. The index uniquely 
     * identifies a time series in a simulation.
     * <p>
     * <b>Note:</b> To store variables that are <b>not</b> time-indexed use the 
     * {@link VersatileDataTable} class.
     * <p>
     * <b>Examples</b>: time-indexed variables, e.g. price_1, price_2, vol_3_r1, 
     * kurt_r10_e3
     */
    private static String INDEX_SEPARATOR = "_";
    
    /**
     * The width of the output column for the output of the time series data points.
     * <p>
     * Allows for adjusting the width depending for instance on the chosen 
     * output accuracy for the data points. The column width together with the 
     * {@link #NUMBER_ACCURACY NUMBER_ACCURACY} and the {@link #NUMBER_TYPE NUMBER_TYPE} 
     * are used to format the standard output of the time series.
     */
    private static int COLUMN_WIDTH = 11;
    
    /**
     * The minimum width of the column containing the row label
     */
    private static int MIN_ROW_LABEL_WIDTH = 8;
    
    /**
     * The number of significant decimals to the right of the decimal point for
     * the output of the time series data points.
     * <p>
     * The number accuracy together with the {@link #NUMBER_TYPE NUMBER_TYPE} 
     * and the {@link #COLUMN_WIDTH COLUMN_WIDTH} are used to format the standard output 
     * of the time series.
     */
    private static int NUMBER_ACCURACY = 5;
    
    /**
     * The standard numeric format string for the output of the time series data points.
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
     * The unit in which simulation ticks are represented.
     */
    private static Period TIME_PERIOD = Period.DAY;
    
    /**
     * Indicates whether the time string is printed in 'tick' units or in 'actual' date units.
     */
    private static String TIME_PERIOD_FORMAT = "tick";
    
    /**
     * The format in which dates are written to the standard output
     */
    private static String DATE_FORMAT = "d MMM yy";
    
    
    private InternalParams internalParams;
    
    /**
     * The units in which simulation ticks can be represented.
     * 
     * @see #TIME_PERIOD
     */
    public enum Period {    // TODO implement the use of periods other than days and ticks
        SECOND,
        MINUTE,
        HOUR,
        DAY,
        WEEK,
        MONTH,
        QUARTER,
        YEAR,
        TICK
    }

    /**
     * The global data structure storing time series output format parameters.
     * <p>
     * Provides static setters for the parameters. See the field summary of 
     * {@link VersatileTimeSeries} for a description of the corresponding parameters.
     * <p>
     * Instance-level (local) parameters are specific to the object while the 
     * global parameters are static and hence have class-level scope. The global 
     * parameters are used to set parameter values for all <code>VersatileTimeSeries</code> 
     * objects, while the local parameters can be used to overwrite the global 
     * values for a particular object.   
     */
    public static class StaticInternalParams {
        public static void setOutputHead(int outputHead) {
            MAX_OUTPUT_HEAD = outputHead;
        }

        public static void setOutputTail(int outputTail) {
            MAX_OUTPUT_TAIL = outputTail;
        }

        public static void setIndexSeperator(String indexSeparator) {
            INDEX_SEPARATOR = indexSeparator;
        }

        public static void setColumnWidth(int columnWidth) {
            COLUMN_WIDTH = columnWidth;
        }

        public static void setMinRowLabelWidth(int minRowLabelWidth) {
            MIN_ROW_LABEL_WIDTH = minRowLabelWidth;
        }

        public static void setNumberAccuracy(int numberAccuracy) {
            NUMBER_ACCURACY = numberAccuracy;
        }

        public static void setNumberType(String numberType) {
            NUMBER_TYPE = numberType;
        }

        public static void setTimePeriod(Period timePeriod) {
            TIME_PERIOD = timePeriod;
        }

        public static void setTimePeriodFormat(String timePeriodFormat) {
            if (!timePeriodFormat.equalsIgnoreCase("tick") &&
                !timePeriodFormat.equalsIgnoreCase("actual"))
                Assertion.assertStrict(false, Assertion.Level.ERR, "Unkown time period format '" + timePeriodFormat);
            TIME_PERIOD_FORMAT = timePeriodFormat;
        }        

        public static void setDateFormat(String dateFormat) {
            DATE_FORMAT = dateFormat;
        }

        public static int getOutputHead() {
            return MAX_OUTPUT_HEAD;
        }

        public static int getOutputTail() {
            return MAX_OUTPUT_TAIL;
        }

        public static String getIndexSeperator() {
            return INDEX_SEPARATOR;
        }

        public static int getColumnWidth() {
            return COLUMN_WIDTH;
        }

        public static int getMinRowLabelWidth() {
            return MIN_ROW_LABEL_WIDTH;
        }

        public static int getNumberAccuracy() {
            return NUMBER_ACCURACY;
        }

        public static String getNumberType() {
            return NUMBER_TYPE;
        }

        public static Period getTimePeriod() {
            return TIME_PERIOD;
        }

        public static String getTimePeriodFormat() {
            return TIME_PERIOD_FORMAT;
        }        

        public static String getDateFormat() {
            return DATE_FORMAT;
        }
    }
    
    /**
     * The local data structure for time series output format parameters.
     * <p>
     * For an explanation of local vs. global formats, see <code>StaticInternalParams</code>.
     * See the field summary in {@link VersatileTimeSeries} for a description of the
     * format parameters.
     * <p>
     * This class provides getters that return the time series parameter values and 
     * methods that allow overriding global values of these parameters.
     */
    public class InternalParams {
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileTimeSeries#MAX_OUTPUT_HEAD
         */
        private int outputHead;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileTimeSeries#MAX_OUTPUT_TAIL
         */
        private int outputTail;

        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileTimeSeries#INDEX_SEPARATOR
         */
        private String indexSeparator;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileTimeSeries#COLUMN_WIDTH
         */
        private int columnWidth;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileTimeSeries#MIN_ROW_LABEL_WIDTH
         */
        private int minRowLabelWidth;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileTimeSeries#NUMBER_ACCURACY
         */
        private int numberAccuracy;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileTimeSeries#NUMBER_TYPE
         */
        private String numberType;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see #getNumberFormat()
         */
        private String numberFormat;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileTimeSeries#TIME_PERIOD
         */
        private Period timePeriod;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileTimeSeries#TIME_PERIOD_FORMAT
         */
        private String timePeriodFormat;
        
        /**
         * Local value of time series format parameter.
         * 
         * @see VersatileTimeSeries#DATE_FORMAT
         */
        private String dateFormat;
        
        /**
         * Initialises local parameters to global (class-level)
         * values.
         */
        protected InternalParams() {
            outputHead = MAX_OUTPUT_HEAD;
            outputTail = MAX_OUTPUT_TAIL;
            indexSeparator = INDEX_SEPARATOR;
            columnWidth = COLUMN_WIDTH;
            minRowLabelWidth = MIN_ROW_LABEL_WIDTH;
            numberAccuracy = NUMBER_ACCURACY;
            numberType = NUMBER_TYPE;
            numberFormat = generateNumberFormat();
            timePeriod = TIME_PERIOD;
            timePeriodFormat = TIME_PERIOD_FORMAT;
            dateFormat = DATE_FORMAT;
        }
        
        /**
         * Makes a copy of the parameter object.
         * 
         * @param params the original parameter object
         */
        protected InternalParams(InternalParams params) {   // copy constructor
            this.outputHead = params.getOutputHead();
            this.outputTail = params.getOutputTail();
            this.indexSeparator = params.getIndexSeparator();
            this.columnWidth = params.getColumnWidth();
            this.minRowLabelWidth = params.getMinRowLabelWidth();
            this.numberAccuracy = params.getNumberAccuracy();
            this.numberType = params.getNumberType();
            this.numberFormat = params.getNumberFormat();
            this.timePeriod = params.getTimePeriod();
            this.timePeriodFormat = params.getTimePeriodFormat();
            this.dateFormat = params.getDateFormat();
        }
        
        /**
         * Overrides the field {@link VersatileTimeSeries#MAX_OUTPUT_HEAD}
         * 
         * @param outputHead number of leading time series data when writing to the standard output.
         */
        public void overrideOutputHead(int outputHead) {
            this.outputHead = outputHead;
        }
        
        /**
         * Overrides the field {@link VersatileTimeSeries#MAX_OUTPUT_TAIL}
         * 
         * @param outputTail number of trailing time series data when writing to the standard output.
         */
        public void overrideOutputTail(int outputTail) {
            this.outputTail = outputTail;
        }
        
        /**
         * Overrides the field {@link VersatileTimeSeries#INDEX_SEPARATOR}
         * 
         * @param indexSeparator the string symbol separating variable names 
         * and indices from other indices.
         */
        public void overrideIndexSeparator(String indexSeparator) {
            this.indexSeparator = indexSeparator;
        }

        /**
         * Overrides the field {@link VersatileTimeSeries#COLUMN_WIDTH}
         * 
         * @param columnWidth the width of the column holding time series data.
         */
        public void overrideColumnWidth(int columnWidth) {
            this.columnWidth = columnWidth;
            this.numberFormat = generateNumberFormat();
        }
        
        /**
         * Overrides the field {@link VersatileTimeSeries#MIN_ROW_LABEL_WIDTH}
         * 
         * @param minRowLabelWidth the minimum width of the column holding row labels.
         */
        public void overrideMinRowLabelWidth(int minRowLabelWidth) {
            this.minRowLabelWidth = minRowLabelWidth;
        }
        
        /**
         * Overrides the field {@link VersatileTimeSeries#NUMBER_ACCURACY}
         * 
         * @param numberAccuracy the number of significant decimals to the right 
         * of the decimal point.
         */
        public void overrideNumberAccuracy(int numberAccuracy) {
            this.numberAccuracy = numberAccuracy;
            this.numberFormat = generateNumberFormat();
        }
        
        /**
         * Overrides the field {@link VersatileTimeSeries#NUMBER_TYPE}
         * 
         * @param numberType the string indicating the number format ("g", "d", etc.)
         */
        public void overrideNumberType(String numberType) {
            this.numberType = numberType;
            this.numberFormat = generateNumberFormat();
        }
        
        /**
         * Overrides the field {@link VersatileTimeSeries#TIME_PERIOD}
         * 
         * @param timePeriod the units in which simulation ticks are represented.
         */
        public void overrideTimePeriod(Period timePeriod) {
            this.timePeriod = timePeriod;
        }
        
        /**
         * Overrides the field {@link VersatileTimeSeries#TIME_PERIOD_FORMAT}
         * 
         * @param timePeriodFormat indicates whether time is represented as ticks 
         * ("ticks") or in the units given by {@link VersatileTimeSeries#TIME_PERIOD} 
         * ("actual"). 
         */
        public void overrideTimePeriodFormat(String timePeriodFormat) {
            if (!timePeriodFormat.equalsIgnoreCase("tick") &&
                    !timePeriodFormat.equalsIgnoreCase("actual"))
                    Assertion.assertStrict(false, Assertion.Level.ERR, "Unkown time period format '" + timePeriodFormat);
            this.timePeriodFormat = timePeriodFormat;
        }
        
        /**
         * Overrides the field {@link VersatileTimeSeries#DATE_FORMAT}
         * 
         * @param dateFormat the format in which dates are written to the standard output. 
         */
        public void overrideDateFormat(String dateFormat) {
            this.dateFormat = dateFormat;
        }
        
        /**
         * Obtain the object-level value of the time series format parameter.
         * 
         * @see #overrideOutputHead(int) 
         */
        public int getOutputHead() {
            return outputHead;
        }
        
        /**
         * Obtain the object-level value of the time series format parameter.
         * 
         * @see #overrideOutputTail(int)
         */
        public int getOutputTail() {
            return outputTail;
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
         * @see #overrideMinRowLabelWidth(int)
         */
        public int getMinRowLabelWidth() {
            return minRowLabelWidth;
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
         * Obtain the object-level value of the time series format parameter.
         * 
         * @see #overrideTimePeriod(AdvancedTimeSeries#Period)
         */
        public Period getTimePeriod() {
            return timePeriod;
        }
        
        /**
         * Obtain the object-level value of the time series format parameter.
         * 
         * @see #overrideTimePeriodFormat(String)
         */
        public String getTimePeriodFormat() {
            return timePeriodFormat;
        }

        /**
         * Obtain the object-level value of the time series format parameter.
         * 
         * @see #overrideDateFormat(String)
         */
        public String getDateFormat() {
            return dateFormat;
        }

        /**
         * Generate the number format string based on the {@link #columnWidth},
         * {@link #numberAccuracy}, and {@link #numberType}. 
         * 
         * @return the format string
         */
        public String generateNumberFormat() {
            return "%" + getColumnWidth() + "." + getNumberAccuracy() + getNumberType();
        }
    }


    /**====================================================================
     * 
     *      CONSTRUCTORS, GETTERS, AND SETTERS
     *      ----------------------------------
     *      
     **====================================================================*/

    
    /**
     * Constructs a time series object with the unique identifier <code>key</code>.
     * 
     * @param key the unique identifier of the time series
     */
    public VersatileTimeSeries(String key) {
        super(key);
        internalParams = new InternalParams();
    }
        
    /**
     * Constructs a time series object with the unique identifier <code>key</code> 
     * and values taken from the double array <code>dal</code>.
     * 
     * @param key the unique identifier of the time series
     * @param dal the values provided as a double array
     * @param startTime optional startTime of the series
     */
    public VersatileTimeSeries(String key, DoubleArrayList dal, RegularTimePeriod... startTimeOpt) {
        super(key);
        internalParams = new InternalParams();
        RegularTimePeriod currentTime;

        if (startTimeOpt.length != 0) {

            Assertion.assertStrict(startTimeOpt.length == 1, Level.ERR, "Only one " +
            		"optional argument allowed for startTime, but " + startTimeOpt.length + " provided");
            currentTime = startTimeOpt[0];
            
            if (currentTime instanceof org.jfree.data.time.Second)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.SECOND);
            else if (currentTime instanceof org.jfree.data.time.Minute)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.MINUTE);
            else if (currentTime instanceof org.jfree.data.time.Hour)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.HOUR);
            else if (currentTime instanceof org.jfree.data.time.Day)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.DAY);
            else if (currentTime instanceof org.jfree.data.time.Week)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.WEEK);
            else if (currentTime instanceof org.jfree.data.time.Month)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.MONTH);
            else if (currentTime instanceof org.jfree.data.time.Quarter)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.QUARTER);
            else if (currentTime instanceof org.jfree.data.time.Year)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.YEAR);
            else
                Assertion.assertOrKill(false, "The time period " + currentTime.getClass() + " is not implemented ");
        }
        else {   // set a default start time if not provided by caller 

            currentTime = new Day(1,1,2014);
            this.getInternalParams().overrideTimePeriod(TIME_PERIOD.DAY);
        }
        
        for (int i = 0; i < dal.size(); i++) {
            this.add(currentTime, dal.get(i));
            currentTime = currentTime.next();
        }
    }
        
    /**
     * Constructs a time series object with the unique identifier <code>key</code> 
     * and values taken from the DoubleTimeSeries <code>dts</code>.
     * 
     * @param key the unique identifier of the time series
     * @param dts the values provided as a {@link DoubleTimeSeries}
     * @param startTime optional startTime of the series
     */
    public VersatileTimeSeries(String key, DoubleTimeSeries dts, RegularTimePeriod... startTimeOpt) {
        super(key);
        internalParams = new InternalParams();
        RegularTimePeriod currentTime;
        
        if (startTimeOpt.length != 0) {

            Assertion.assertOrKill(startTimeOpt.length == 1, "Only one " +
                    "optional argument allowed for startTime, but " + startTimeOpt.length + " provided");
            currentTime = startTimeOpt[0];
            
            if (currentTime instanceof org.jfree.data.time.Second)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.SECOND);
            else if (currentTime instanceof org.jfree.data.time.Minute)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.MINUTE);
            else if (currentTime instanceof org.jfree.data.time.Hour)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.HOUR);
            else if (currentTime instanceof org.jfree.data.time.Day)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.DAY);
            else if (currentTime instanceof org.jfree.data.time.Week)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.WEEK);
            else if (currentTime instanceof org.jfree.data.time.Month)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.MONTH);
            else if (currentTime instanceof org.jfree.data.time.Quarter)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.QUARTER);
            else if (currentTime instanceof org.jfree.data.time.Year)
                this.getInternalParams().overrideTimePeriod(TIME_PERIOD.YEAR);
            else
                Assertion.assertOrKill(false, "The time period " + currentTime.getClass() + " is not implemented ");
        }
        else {    // set a default start time if not provided by caller 

            currentTime = new Day(1,1,2014);    // TODO set this to TICK once the class is implemented
            this.getInternalParams().overrideTimePeriod(TIME_PERIOD.DAY);
        }
        
        for (int i = 0; i < dts.size(); i++) {
            this.add(currentTime, dts.getValue(i));
            currentTime = currentTime.next();
        }
    }
        
    /**
     * Constructs a deep copy of the time series object and labels it <code>name</code>.
     * 
     * @param name the label of the copy
     * @return the copy of the time series
     */
    public VersatileTimeSeries copy(String name) {
        VersatileTimeSeries newAts = new VersatileTimeSeries(name);
        
        newAts.addAndOrUpdate(this);
        internalParams = new InternalParams(this.internalParams);
        
        return newAts;
    }
    
    public InternalParams getInternalParams() {
        return internalParams;
    }
    

    /**
     * Returns the time series as a {@link DoubleTimeSeries}.
     * 
     * @return the time series in {@link DoubleTimeSeries} format
     */
//    public DoubleTimeSeries getDoubleTimeSeries() {
//        
//        DoubleTimeSeries dts = new DoubleTimeSeries();
//        
//        for (int i = 0; i < this.getItemCount(); i++) {
//            this.getDataItem(i).getPeriod().getStart();
//        }
//        
//    }
    
    
    /**
     * Creates a new time series by adding up several existing time series.
     * The value of at any given time is the sum of values of the existing
     * time series at that time.
     *   
     * @param newVarName the label of the new time series
     * @param atsSet an arbitrary number of existing time series
     * @return the new time series
     */
    public static VersatileTimeSeries createSumOfSeries(String newVarName, VersatileTimeSeries... atsSet) {
        VersatileTimeSeries newAts = null;
        int count = 1;
        
        // Create a new time series object as the sum of the existing time series
        for (VersatileTimeSeries ats : atsSet) {
            if (count == 1) {   // create the new time series object only once
                newAts = ats.copy(newVarName);
                count++;
            }
            else {
                double update;
                
                // For each time point, increase value of new time series with that of current time series 
                for (int i = 0; i < newAts.getItemCount(); i++) {
                    update = newAts.getValue(i).doubleValue() + ats.getValue(i).doubleValue();
                    newAts.update(i, update);
                }
            }
                
        }

        return newAts;
    }
        

    /**====================================================================
     * 
     *      ALGEBRAIC AND STATISTICAL OPERATORS
     *      -----------------------------------
     *      
     **====================================================================*/

    
    /**
     * Computes the sum of the data points of this time series.
     *
     * @return the sum of all data points in this time series
     */
    public double operatorSum() {
        double sum = 0;
        
        for (int i = 0; i < this.getItemCount(); i++)
            sum += getValue(i).doubleValue();
        
        return sum;
    }
    
    /**
     * Computes the mean of the data points this time series.
     * 
     * @return the mean (or average) of this time series
     */
    public double operatorMean() {
        DescriptiveStatistics   stats = new DescriptiveStatistics();
        
        for (int i = 0; i < this.getItemCount(); i++)
            stats.addValue(getValue(i).doubleValue());
        
        return stats.getMean();
    }
    
    /**
     * Computes the standard deviation of the data points in this time series.
     * 
     * @return the standard deviation of this time series
     */
    public double operatorStdev() {
        DescriptiveStatistics   stats = new DescriptiveStatistics();
        
        for (int i = 0; i < this.getItemCount(); i++)
            stats.addValue(getValue(i).doubleValue());
        
        return stats.getStandardDeviation();
    }
    
    /**
     * Computes the skewness of the data points in this time series.
     * 
     * @return the skewness of this time series
     */
    public double operatorSkewness() {
        DescriptiveStatistics   stats = new DescriptiveStatistics();
        
        for (int i = 0; i < this.getItemCount(); i++)
            stats.addValue(getValue(i).doubleValue());
        
        return stats.getSkewness();
    }

    /**
     * Computes the auto-correlation of the time series up to lag {@code maxLag}.
     * 
     * @return the auto-correlation vector up to lag {@code maxLag} for the time series
     * @see <a href=”http://goo.gl/d0HAut”>CERN Descriptive class</a>
     */
    public DoubleArrayList operatorAutoCorrelation(int maxLag) {
        
        DoubleArrayList values = new DoubleArrayList();
        DoubleArrayList autocorr = new DoubleArrayList();
        
        for (int i = 0; i < getItemCount(); i++)
            values.add(getValue(i).doubleValue());
        
        double mean = Descriptive.mean(values);
        double var = Descriptive.variance(getItemCount(), Descriptive.sum(values), Descriptive.sumOfSquares(values));
        
        for (int lag = 0; lag <= maxLag; lag++)
            autocorr.add(Descriptive.autoCorrelation(values, lag, mean, var));
        
        return autocorr;
    }

    
    /**
     * Computes the unbiased excess kurtosis of the data points in this time series.
     * 
     * @return the unbiased excess kurtosis of this time series
     * @see <a href=”http://tinyurl.com/d4cajfw”>Unbiased excess kurtosis</a>
     */
    public double operatorUnbiasedExcessKurtosis() {
        DescriptiveStatistics   stats = new DescriptiveStatistics();
        
        for (int i = 0; i < this.getItemCount(); i++)
            stats.addValue(getValue(i).doubleValue());
        
        return stats.getKurtosis();
    }


    /**
     * Creates a new time series by applying the first-order backward difference 
     * operator to this time series. This can be used for instance to compute the 
     * log returns series from log prices.
     * 
     * @param name the label of the new time series
     * @return a new time series with the difference values
     */
    public VersatileTimeSeries operatorDifference(String name) {
        VersatileTimeSeries ats = new VersatileTimeSeries(name);
        RegularTimePeriod currentTime = getTimePeriod(0);
        RegularTimePeriod startTime = getTimePeriod(0);

        ats.add(currentTime, 0);
        
        for (int i = 1; i < this.getItemCount(); i++) {
            currentTime = currentTime.next();
            ats.add(currentTime, this.getValue(i).doubleValue() - this.getValue(i - 1).doubleValue());
        }
        
        ats.update(startTime, ats.getValue(1));     // Difference not defined for first data point, so choose the simplest interpolation

        return ats;
    }
    
    /**
     * Creates a new time series by applying the integral operator to this time series. 
     * The value of a data point in the new time series is equal to the sum of the values
     * up to that point in time. This can be used for instance to compute the current asset 
     * position as the sum of all prior orders.
     * 
     * @param name the label of the new time series
     * @return a new time series with the difference values
     */
    public VersatileTimeSeries operatorCumulative(String name) {
        VersatileTimeSeries ats = new VersatileTimeSeries(name);
        RegularTimePeriod currentTime = getTimePeriod(0);

        ats.add(new TimeSeriesDataItem(currentTime, this.getValue(0)));
        
        for (int i = 1; i < this.getItemCount(); i++) {
            currentTime = currentTime.next();
            ats.add(currentTime, ats.getValue(i - 1).doubleValue() + this.getValue(i).doubleValue());
        }
        
        return ats;
    }
    
    /**
     * Creates a new time series with the absolute values of each data point of this time
     * series. This can be used for instance to calculate trading volume from total 
     * orders. 
     * 
     * @param name the label of the new time series
     * @return a new time series with the absolute values
     */
    public VersatileTimeSeries operatorAbs(String name) {
        VersatileTimeSeries ats = new VersatileTimeSeries(name);
        RegularTimePeriod currentTime = getTimePeriod(0);

        for (int i = 0; i < this.getItemCount(); i++) {
            ats.add(currentTime, Math.abs(this.getValue(i).doubleValue()));
            currentTime = currentTime.next();
        }
        
        return ats;
    }
    
    /**
     * Creates a new time series with the exponential values of each data point of this time
     * series. Since many models work with log prices, this method can be used to calculate 
     * the corresponding prices, which are easier to interpret when inspecting the results.  
     * 
     * @param name the label of the new time series
     * @return a new time series with the exponential values
     */
    public VersatileTimeSeries operatorExp(String name) {
        VersatileTimeSeries ats = new VersatileTimeSeries(name);
        RegularTimePeriod currentTime = getTimePeriod(0);

        for (int i = 0; i < this.getItemCount(); i++) {
            ats.add(currentTime, Math.exp(this.getValue(i).doubleValue()));
            currentTime = currentTime.next();
        }
        
        return ats;
    }
    
    /**
     * Creates a new time series with the natural logarithm (base e) of values of each data 
     * point of this time series.  
     * 
     * @param name the label of the new time series
     * @return a new time series with the log values
     */
    public VersatileTimeSeries operatorLn(String name) {
        VersatileTimeSeries ats = new VersatileTimeSeries(name);
        RegularTimePeriod currentTime = getTimePeriod(0);

        for (int i = 0; i < this.getItemCount(); i++) {
            ats.add(currentTime, Math.log(this.getValue(i).doubleValue()));
            currentTime = currentTime.next();
        }
        
        return ats;
    }
    

    /**====================================================================
     * 
     *      KEY OPERATORS
     *      -------------
     *      
     *      Methods that operate on the time series key
     *      
     **====================================================================*/
    
    
    /**
     * Checks whether this time series is part of larger set of 
     * time series. We do this by determining whether the label
     * of this time series is comprised by the label 
     * <code>superset</code>, which represents the larger set.
     * For this time series to be a subset, any index (dimension, 
     * run, or experiment) present in <code>superset</code> has 
     * to be present in the label of this time series as well.
     * See example below.
     * <p>
     * Each time series has a label consisting of the variable 
     * name, and, if applicable, a dimension index (if the time 
     * series is vector-valued), a run index and an experiment
     * index. The run index and experiment index distinguish
     * time series of different simulation runs and experiments
     * respectively. When forming determining the subset status,
     * none of the indices has preference over the others. Any
     * of the indices not present in the subset isn't tested for,
     * independently of the presence or absence of any other
     * indices.
     * <p>
     * <b>Note:</b> To ignore any of the dimension indices, 
     * set the corresponding indices in <code>superset</code> 
     * to <code>-1</code>.
     * <p>
     * <b>Note:</b> A simulation study can involve a single run 
     * (e.g. we can generate a single time series of prices and 
     * orders for the purpose of verifying the software implementation 
     * of the model), several runs, also called 'experiment' (e.g. 
     * to analyse the distributional characteristics of the asset 
     * return), or a set of experiments (e.g. to analyse the 
     * sensitivity of the return distribution to changes in certain 
     * parameters). 
     * <p>
     * <b>Examples</b> of indexed time series variables:
     * <ul>
     * <li>Price of the third asset: <code>price_3</code></li>
     * <li>Order of the first asset for the 25th trader: <code>order_1_25</code></li>
     * <li>Total wealth in the economy during the fourth run: <code>wealth_tot_r4</code></li>
     * <li>Return volatility of the second asset during the first run and second experiment: <code>vol_2_r1_e2</code></li>
     * </ul>
     * <b>Example</b> of sub/superset: Suppose we run 10 experiments 
     * of 500 runs each and compute prices for three assets. Assume 
     * the label of this time series object is <code>price_2_r242</code>. In that 
     * case, this time series object belongs to the supersets labeled
     * <code>price</code>, <code>price_2</code>, and even <code>price_2_r242</code>,
     * but not to those labeled <code>vol</code>, <code>price_1</code>, or
     * <code>price_2_r2</code>.
     * <p>
     * <b>Note:</b> You can also test purely for experiment or run without
     * naming a variable. Hence <code>superset="e4"</code> is permissible
     * and tests whether this timeseries belongs to experiment 4.  
     * <p>
     * Non-time series variables are stored in the class {@link VersatileDataTable}, 
     * where you can find more examples.
     * <p>
     * @param subset
     * @return
     */
    public Boolean matches(String superset) {
        String key = (String) getKey();
        
        // TODO create a regex method to test for well-formed time series keys or labels; ought to be tested at creation stage
        // TODO rename method to 'matches'
                
        // Do the variable names coincide?
        String testForVariableName = extractVariableName(superset);

        if (testForVariableName != null) {
            if (!extractVariableName(key.toLowerCase()).equalsIgnoreCase(testForVariableName))
                return false; 
        }
        
        // Does the experiment coincide? Ignore if no experiment label is present in superset
        String testForExperiment = extractExperimentIndex(superset);

        if (testForExperiment != null) {
            String thisExperiment = extractExperimentIndex(key.toLowerCase());
            if (thisExperiment == null)
                return false;
            else if (!thisExperiment.equalsIgnoreCase(testForExperiment))
                return false;
        }
        
        // Does the run coincide? Ignore if no run label is present in superset
        String testForRun = extractRunIndex(superset);

        if (testForRun != null) {
            String thisRun = extractRunIndex(key.toLowerCase());
            if (thisRun == null)
                return false;
            else if (!thisRun.equalsIgnoreCase(testForRun))
                return false;
        }

        // Do the dimension indices coincide? (indices that ought to be ignored should be set to '-1' in superset
        ArrayList<String> testForIndices = extractVariableIndices(superset);
        ArrayList<String> theseIndices = extractVariableIndices(key);

        for (int i = 0; i < testForIndices.size(); i++) {
            int index = Integer.valueOf(testForIndices.get(i));
            
            if (index != -1)    // ignore indices that are set to -1
                if (index != Integer.valueOf(theseIndices.get(i)))
                    return false;
        }
        
        return true;    // all dimension indices 
    }
    
    /**
     * Extracts the string representing the variable name from the <code>key</code>
     * label. For instance, the variable name for the label <code>price_2_r3_e1</code>
     * is <code>price</code>.
     * <p>  
     * @param key the label from which we want to extract the variable name
     * @return the variable name or null if not found
     */
    public String extractVariableName(String key) {
        String [] tokens = key.split(internalParams.getIndexSeparator());
        int count = 0;
        String varName = null;

        // We find the first occurrence of a dimensional, run, or experiment index
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
        else if (count != 0) {  // reconstruct the variable name from tokens up to first occurrence of dimension, run, or experiment index
            varName = tokens[0];
            for (int i = 1; i < count; i++)
                varName += internalParams.getIndexSeparator() + tokens[i]; 
        }

        return varName;
    }
    
    /**
     * Extracts the dimension indices from the label <code>key</code> and adds them 
     * to an array. For instance, the indices for the label
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
     * Extracts the experiment index from the label <code>key</code>. For instance
     * the index for the label <code>vol_r1_e5</code> is "e5".
     * <p>
     * @param key the label from which we want to extract the experiment index
     * @return the experiment index
     */
    public String extractExperimentIndex(String key) {
        String [] tokens = key.split(internalParams.getIndexSeparator());
        String expIndex = null;

        for (String token : tokens) {
            if (token.startsWith("e") && isInteger(token.substring(1)))
                expIndex = token;
        }
        
        return expIndex;
    }

    /**
     * Extracts the run index from the label <code>key</code>. For instance
     * the index for the label <code>vol_r1_e5</code> is "r1".
     * <p>
     * @param key the label from which we want to extract the run index
     * @return the run index
     */
    public String extractRunIndex(String key) {
        String [] tokens = key.split(internalParams.getIndexSeparator());
        String runIndex = null;

        for (String token : tokens) {
            if (token.startsWith("r") && isInteger(token.substring(1)))
                runIndex = token;
        }
        
        return runIndex;
    }

    
    /**====================================================================
     * 
     *      UTILITIES
     *      ---------
     *      
     **====================================================================*/
    
    
    /**
     * Compares this time series with the time series passed as an argument. It compares ticks, 
     * values, and essential internal parameters (only TIME_PERIOD - all other parameters are
     * used to format output).
     * 
     * @param vts the external @link VersatileTimeSeries} used in the comparison
     * @return true if both time series are the same (on account of the comparison criteria: ticks,
     * values, TIME_PERIOD).
     */
    public Boolean equals(VersatileTimeSeries vts) {
        
        // Time unit the same?
        if (vts.getInternalParams().getTimePeriod() != this.getInternalParams().getTimePeriod()) return false;
        
        // Same number of data items?
        if (vts.getItemCount() != this.getItemCount()) return false;
        
        // Time stamps and values the same?
        for (int t = 0; t < this.getItemCount(); t++) {
            if (vts.getTimePeriod(t).compareTo(this.getTimePeriod(t)) != 0) return false;
            if (vts.getValue(t).doubleValue() != this.getValue(t).doubleValue()) return false;  // TODO this might not work if value computations method differs between both series 
        }
        
        return true;
    }
    
    /**
     * Gets the last tick in this time series as a RegularTimePeriod object (hour, day, week, etc.) 
     *  
     * @return the last tick in this time series, as a RegularTimePeriod object. RegularTimePeriod is 
     * an abstract class from the <a href="http://tinyurl.com/9s3hua8">JFree</a> Java graphics 
     * library that represents time units such as hours, weeks, and years, and provides utilities 
     * for date calculation and conversion.
     * 
     * @see <a href="http://tinyurl.com/9s3hua8">Class RegularTimePeriod</a>
     */
    public RegularTimePeriod lastTick() {
        return getTimePeriod(getItemCount() - 1);
    }
    
    /**
     * Checks whether the string <code>str</code> represents an integer value.
     * 
     * @param str the string for which we determine whether it represents an integer
     * @return true if <code>str</code> represents an integer
     */
    private Boolean isInteger(String str) {
        try {
            Integer.parseInt(str);
        } catch (Exception e) {
            return false;
        }
        
        return true;
    }
    

//    private boolean isNumeric(String number) {  
//        boolean isValid = false;  
//        /*Explaination: 
//                [-+]?: Can have an optional - or + sign at the beginning. 
//                [0-9]*: Can have any numbers of digits between 0 and 9 
//                \\.? : the digits may have an optional decimal point. 
//            [0-9]+$: The string must have a digit at the end. 
//            If you want to consider x. as a valid number change 
//                the expression as follows. (but I treat this as an invalid number.). 
//               String expression = "[-+]?[0-9]*\\.?[0-9\\.]+$"; 
//         */  
//        CharSequence inputStr = number;  
//        Pattern pattern = Pattern.compile("^[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?$");  
//        Matcher matcher = pattern.matcher(inputStr);  
//        if(matcher.matches()){  
//            isValid = true;  
//        }  
//        return isValid;  
//    }

    
    /**====================================================================
     * 
     *      FORMATTED OUTPUT OF TIME SERIES
     *      -------------------------------
     *      
     *      A number of methods are available for formatted output of
     *      time series
     *         - Row separator: separating e.g. two time series
     *         - Ticks or times/dates: 
     *      
     *      There is a raw version and a decorated version of each method.
     *      The decorated version for time series values for instance adds
     *      a leading and a trailing label to the output.
     *      
     *      Note: To print time series that are stored in a collection 
     *      of type VersatileTimeSeriesCollection, use the methods of that
     *      collection:
     *         - 
     * 
     **====================================================================*/

    
    /**
     * Prints this time series with ticks, row separator, and values using full decoration with 
     * labels (see below for details on decorated output. Uses the key of this time series as
     * the row label. The width of the column with the label is inferred from the size of the
     * label.
     * 
     * @param width the width of the column containing the left-hand labels
     * @return the formatted string of the time series
     */
    public String printDecorated() {
        
        int widthLabelRow = ((String) getKey()).length();
        
        if (widthLabelRow + 4 < internalParams.getMinRowLabelWidth())
            widthLabelRow = internalParams.getMinRowLabelWidth(); 
        else
            widthLabelRow += 4;
        
        String output = printDecoratedTicks(widthLabelRow) + "\n" + printDecoratedRowSeparator(widthLabelRow)
                        + "\n" + printDecoratedValues(widthLabelRow);
        return output;
    }

        
    /**
     * Prints this time series with ticks, row separator, and values using full decoration with 
     * labels (see below for details on decorated output. Uses the key of this time series as
     * the row label. The width of the column with the label is inferred from the size of the
     * label.
     * 
     * @param width the width of the column containing the left-hand labels
     * @return the formatted string of the time series
     */
    public String printDecorated(String label) {
        
        int widthLabelRow = label.length();
        
        if (widthLabelRow + 4 < internalParams.getMinRowLabelWidth()) 
            widthLabelRow = internalParams.getMinRowLabelWidth();
        else
            widthLabelRow += 4;
        
        String output = printDecoratedTicks(widthLabelRow) + "\n" + printDecoratedRowSeparator(widthLabelRow)
                        + "\n" + printDecoratedValues(widthLabelRow);
        return output;
    }

        
    /**
     * Prints the time, date, or tick of a time series or collection of time series, 
     * plus the row label 'TICK' (if the parameter <code>timePeriodFormat</code> is set 
     * to  or 'DATE'. See {@link #printTicks()} for more details and for parameter
     * dependencies.
     * <p>
     * @param width the width of the right-hand row label
     * @return the sequence of ticks, times, or dates from the time series and the right-hand
     * label 'TICK' or 'DATE'
     * @see #printTicks()
     */
    public String printDecoratedTicks(int width) {
        String timePeriodFormat = "";
        
        if (internalParams.getTimePeriodFormat().equalsIgnoreCase("tick"))
            timePeriodFormat = "TICK";
        else if (internalParams.getTimePeriodFormat().equalsIgnoreCase("actual"))
            timePeriodFormat = "DATE";  // TODO for time period units of second, minute and hour, add the label 'TIME'
        
        String ts = StringUtils.rightPad(timePeriodFormat, width - 2);
        ts += printTicks();
        return ts;
    }
    

    /**
     * Prints a sequence of '-' characters with a total width covering the length of the time
     * series plus a left-hand row label. 
     * <p>
     * @param width the width of the space to contain the left-hand row label
     * @return a sequence of '-' characters covering the time series plus row label
     * @see #printRowSeparator()
     */
    public String printDecoratedRowSeparator(int width) {
        String ts = StringUtils.repeat('-', width + 9); // TODO extend to include right-hand row label
        ts += printRowSeparator();
        return ts;
    }
    

    /**
     * Prints the formatted values of the time series plus a left-hand and 
     * right-hand row label. The method uses the time series key as the
     * label. See {@link #printValues()} for more details and for parameter 
     * dependencies.
     * <p>
     * @param width the width of the column containing the left-hand row label
     * @return the sequence of formatted time series values plus the left-hand
     * and right-hand row labels
     * @see #printValues()
     * @see VersatileTimeSeriesCollection#printDecoratedSeries(String, int)
     */
    public String printDecoratedValues(int width) {
        return printDecoratedValues((String) getKey(), width);
    }
    
    
    /**
     * Prints the formatted values of the time series plus a left-hand and 
     * right-hand row label. See {@link #printValues()} for more details 
     * and for parameter dependencies.
     * <p>
     * @param width the width of the column containing the left-hand row label
     * @param label the row label used in the output (rather than the time 
     * series key
     * @return the sequence of formatted time series values plus the left-hand
     * and right-hand row labels
     * @see #printValues()
     * @see VersatileTimeSeriesCollection#printDecoratedSeries(String, int)
     */
    public String printDecoratedValues(String label, int width) {
        String ts = "";
        ts += StringUtils.rightPad(label, width);
        ts += printValues();
        ts += " - " + label;
        
        return ts;
    }
    
    
    /**
     * STATIC versions of the decorated output methods for DoubleTimeSeries
     */
    public static String printDecorated(DoubleTimeSeries dts) {
        
        VersatileTimeSeries vts = new VersatileTimeSeries(dts.getId(), dts);
        
        return vts.printDecorated();
    }
    
    
    public static String printDecorated(DoubleTimeSeries dts, String label) {
        
        VersatileTimeSeries vts = new VersatileTimeSeries(label, dts);
        
        return vts.printDecorated();
    }
    
    
    public static String printDecoratedTicks(DoubleTimeSeries dts, int width) {
        
        VersatileTimeSeries vts = new VersatileTimeSeries("time series", dts);
        
        return vts.printDecoratedTicks(width);     
    }


    public static String printDecoratedRowSeparator(DoubleTimeSeries dts, int width) {
        
        VersatileTimeSeries vts = new VersatileTimeSeries("time series", dts);
        
        return vts.printDecoratedRowSeparator(width);
    }


    public static String printDecoratedValues(DoubleTimeSeries dts, int width) {
        
        VersatileTimeSeries vts = new VersatileTimeSeries(dts.getId(), dts);
        
        return vts.printDecoratedValues(width);        
    }


    public static String printDecoratedValues(DoubleTimeSeries dts, String label, int width) {
        
        VersatileTimeSeries ppts = new VersatileTimeSeries(label, dts);
        
        return ppts.printDecoratedValues(width);        
    }


    /**
     * STATIC versions of the decorated output methods for DoubleArrayList
     */
    public static String printDecorated(DoubleArrayList dal, String label) {
        
        VersatileTimeSeries vts = new VersatileTimeSeries(label, dal);
        
        return vts.printDecorated();
    }
    
    
    public static String printDecoratedTicks(DoubleArrayList dal, int width) {
        
        VersatileTimeSeries vts = new VersatileTimeSeries("time series", dal);
        
        return vts.printDecoratedTicks(width);     
    }

    
    public static String printDecoratedRowSeparator(DoubleArrayList dal, int width) {
        
        VersatileTimeSeries vts = new VersatileTimeSeries("time series", dal);
        
        return vts.printDecoratedRowSeparator(width);
    }


    public static String printDecoratedValues(DoubleArrayList dal, String label, int width) {
        
        VersatileTimeSeries ppts = new VersatileTimeSeries(label, dal);
        
        return ppts.printDecoratedValues(width);        
    }

    /**
     * STATIC versions of the non-decorated output methods
     */
    
    /**
     * Prints the ticks of the {@link DoubleTimeSeries} <code>dts</code>. 
     * The output is restricted to a maximum number of leading values and 
     * trailing values, separated by elipses '...'.
     * 
     * @return the formatted string of {@link DoubleTimeSeries} ticks
     * @see #printTicks()
     * 
     */
    public static String printTicks(DoubleTimeSeries dts) {
        VersatileTimeSeries ppts = new VersatileTimeSeries("TS", dts);
        
        return ppts.printTicks();        
    }
    

    /**
     * Prints the values of the {@link DoubleTimeSeries} <code>dts</code>. 
     * The output is restricted to a maximum number of leading values and 
     * trailing values, separated by elipses '...'.
     * 
     * @return the formatted string of {@link DoubleTimeSeries} values
     * @see #printValues()
     * 
     */
    public static String printValues(DoubleTimeSeries dts) {
        VersatileTimeSeries ppts = new VersatileTimeSeries("TS", dts);
        
        return ppts.printValues();        
    }
    

    /**
     * Prints the values of the {@link DoubleArrayList} <code>dal</code>. 
     * The output is restricted to a maximum number of leading values and 
     * trailing values, separated by elipses '...'.
     * 
     * @return the formatted string of {@link DoubleArrayList} values
     * @see #printValues()
     * 
     */
    public static String printValues(DoubleArrayList dal) {
        VersatileTimeSeries ppts = new VersatileTimeSeries("TS", dal);
        
        return ppts.printValues();        
    }


    /**
     * Prints the time, date, or tick header of a time series or collection of time series. The output 
     * is restricted to a maximum number of leading and trailing ticks, times, or dates, separated by 
     * elipses '...'.
     * <p>
     * The format of the string of ticks, times, or dates depends on the following parameters
     * <ul>
     * <li><code>outputHead</code>: max number of leading time series values in the output string</li>
     * <li><code>outputTail</code>: max number of trailing time series values in the output string</li>
     * <li><code>columnWidth</code>: minimum width of the output column</li>
     * <li><code>timePeriodFormat</code>: either "tick" (for a tick representation) or "actual"
     * (for time or date representation, using parameter <code>dateFormat</code>
     * <li><code>dateFormat</code>: indicates the format of the times or dates if <code>timePeriodFormat</code> 
     * is set to "actual"</li>
     * </ul>
     * <p>
     * <b>Examples</b>
     * <ul>
     * <li>&nbsp &nbsp &nbsp 1 &nbsp &nbsp &nbsp 2 &nbsp &nbsp &nbsp 3 &nbsp  ... &nbsp 998 
     * &nbsp &nbsp &nbsp 999 &nbsp &nbsp 1000</li>
     * <li>&nbsp &nbsp &nbsp 1 March 2014 &nbsp &nbsp &nbsp 2 March 2014 &nbsp &nbsp &nbsp 
     * 3 March 2014 &nbsp  ... &nbsp 13 September 2024 &nbsp &nbsp &nbsp 14 September 2024 
     * &nbsp &nbsp 15 September 2024</li>
     * </ul>
     * <p>
     * @return the formatted sequence of time series ticks, times, or dates
     * @see #printDecoratedTicks(int)
     */
    public String printTicks() {
        String ts = "   ";
        int nItems = getItemCount();
        
        // Determine length of time series head and tail, given 
        int headLength = nItems < internalParams.getOutputHead() ? nItems : internalParams.getOutputHead();
        int tailLength = nItems < internalParams.getOutputHead() ? 0 : nItems - internalParams.getOutputHead();
        tailLength = tailLength < internalParams.getOutputTail() ? tailLength : internalParams.getOutputTail(); 
        
        // Construct the header in 'tick' format (= sequence of integers)
        if (internalParams.getTimePeriodFormat().equalsIgnoreCase("tick")) {
            for (int i = 0; i < headLength; i++)
                ts += String.format(" %" + internalParams.getColumnWidth() + "d", i);
            
            if (tailLength > 0) ts += "     ... ";
            
            for (int i = nItems - tailLength; i < nItems; i++)
                ts += String.format(" %" + internalParams.getColumnWidth() + "d", i);
        }
        // Construct the header in desired time or date format (e.g. 12 March 2012). Set the format via parameter DATE_FORMAT
        else if (internalParams.getTimePeriodFormat().equalsIgnoreCase("actual")) {
            SimpleDateFormat dateFormat = new SimpleDateFormat(internalParams.getDateFormat()); // sets the desired format of the time or date
            
            for (int i = 0; i < headLength; i++)
                ts += " " + StringUtils.leftPad(dateFormat.format(getTimePeriod(i).getStart()), internalParams.getColumnWidth());
            
            if (tailLength > 0) ts += "     ... ";
            
            for (int i = nItems - tailLength; i < nItems; i++)
                ts += " " + StringUtils.leftPad(dateFormat.format(getTimePeriod(i).getStart()), internalParams.getColumnWidth());
        }
        
        return ts + " ";
    }
    
    
    /**
     * Prints a sequence of '-' characters with a total width covering the length of the time
     * series plus a left-hand row label. 
     * <p>
     * @return a sequence of '-' characters covering the time series plus row label
     * @see #printDecoratedRowSeparator(int)
     */
    public String printRowSeparator() {
        String ts = "-";
        int nItems = getItemCount();
        int headLength = nItems < internalParams.getOutputHead() ? nItems : internalParams.getOutputHead();
        int tailLength = nItems < internalParams.getOutputHead() ? 0 : nItems - internalParams.getOutputHead();
        tailLength = tailLength < internalParams.getOutputTail() ? tailLength : internalParams.getOutputTail(); 
                
        // Covering the time series head with '-'
        for (int i = 0; i < headLength; i++) {
            ts += StringUtils.repeat('-', internalParams.getColumnWidth() + 1);
        }
        
        if (tailLength > 0) ts += "---------";  // to cover the intermediate '...'
        
        // Covering the time series tail
        for (int i = nItems - tailLength; i < nItems; i++) {
            ts += StringUtils.repeat('-', internalParams.getColumnWidth() + 1);
        }

        return ts + "-";
    }
    
        
    /**
     * Prints the values of the time series. The output is restricted to a
     * maximum number of leading values and trailing values, separated by 
     * elipses '...'.
     * <p>
     * The format of the string of time series values depends on the following parameters
     * <ul>
     * <li><code>outputHead</code>: max number of leading time series values in the output string</li>
     * <li><code>outputTail</code>: max number of trailing time series values in the output string</li>
     * <li><code>numberFormat</code>: the output format for the time series values, e.g. %12.6g </li>
     * </ul>
     * <p>
     * <b>Example</b>
     * <ul>
     * <li>[&nbsp 12.3 &nbsp &nbsp &nbsp 342.3 &nbsp &nbsp &nbsp 0.04 &nbsp  ... &nbsp 12.98 
     * &nbsp &nbsp &nbsp 9.654 &nbsp &nbsp 45.89 ]</li>
     * </ul>
     * <p>
     * @return the formatted string of time series values
     * @see #printDecoratedValues(int)
     * @see VersatileTimeSeriesCollection#printDecoratedSeries(String, int)
     */
    public String printValues() {
        String ts = "[";
        int nItems = getItemCount();
        int headLength = nItems < internalParams.getOutputHead() ? nItems : internalParams.getOutputHead();
        int tailLength = nItems < internalParams.getOutputHead() ? 0 : nItems - internalParams.getOutputHead();
        tailLength = tailLength < internalParams.getOutputTail() ? tailLength : internalParams.getOutputTail(); 
                
        for (int i = 0; i < headLength; i++) {
            ts += String.format(" " + internalParams.getNumberFormat(), getValue(i));
        }
        
        if (tailLength > 0) ts += "     ... ";
        
        for (int i = nItems - tailLength; i < nItems; i++) {
            ts += String.format(" " + internalParams.getNumberFormat(), getValue(i));       // TODO create a settings xml file for the formatting and other settings
        }

        return ts + "]";
    }
    
    
    /**
     * @deprecated Use the methods {@link #printDecoratedRowSeparator(int)} or {@link #printDecoratedRowSeparator(String, int)}. 
     */
    public String toString() {
        String ts = "[";
        int nItems = getItemCount();
        int headLength = nItems < internalParams.getOutputHead() ? nItems : internalParams.getOutputHead();
        int tailLength = nItems < internalParams.getOutputHead() ? 0 : nItems - internalParams.getOutputHead();
        tailLength = tailLength < internalParams.getOutputTail() ? tailLength : internalParams.getOutputTail(); 
        
        for (int i = 0; i < headLength; i++) {
            ts += "{" + i + "}" + String.format(" %6.4g", getValue(i)) + ", ";
        }
        
        if (tailLength > 0) ts += " ... ";
        
        for (int i = nItems - tailLength; i < nItems; i++) {
            ts += "{" + i + "}" + String.format("% 6.4g", getValue(i)) + ", ";       // TODO create a settings xml file for the formatting and other settings
        }

        return ts + "]\n";
    }
    
}
