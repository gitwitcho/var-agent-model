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

import java.text.DecimalFormat;
import java.util.ArrayList;

import org.apache.commons.math3.stat.StatUtils;
import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;

import cern.colt.list.*;
import cern.jet.stat.Descriptive;

/**
 * A time series class that holds doubles. Based on the {@code DoubleArrayList} from {@literal cern.colt.list }
 * 
 * @author Gilbert Peffer
 *
 */
@SuppressWarnings("serial")
public class DoubleTimeSeries extends AbstractDoubleList {
    /**
     * TODO Add a toString method to debug the time series 
     * TODO Remove 'ticks' since gaps are not allowed. Introduce a boolean to indicate where gaps are, 
     * if needed (filling up the values with zeros where no value is provided can be problematic) 
     */
    private final int               MAX_OUPUT_HEAD = 180;     // TODO move output formatting to elsewhere
    private final int               MAX_OUPUT_TAIL = 20;     // TODO move output formatting to elsewhere
    private static DecimalFormat    formatter = new DecimalFormat();
    
    private IntArrayList    ticks;
    private DoubleArrayList values;
    private String          id;
    private int             size = 0;

    public DoubleTimeSeries() {
        this.id = "anonymous_double_time_series";
        
        this.ticks = new IntArrayList();
        this.values = new DoubleArrayList();
    }
    
    public DoubleTimeSeries(String id) {
        this();
        this.id = id;
    }
    
    public DoubleTimeSeries(DoubleArrayList dal) {
        this.id = "anonymous_double_time_series";
        
        this.ticks = new IntArrayList();
        this.values = new DoubleArrayList();
        
        for (int i = 0; i < dal.size(); i++)
            add(dal.get(i));
    }
    
    public DoubleTimeSeries(String id, DoubleArrayList dal) {
        this(dal);
        this.id = id;
    }
    
    public void fillWithConstants(int length, double constant) {
        ticks.clear();
        values.clear();
        size = 0;
        
        for (int i = 0; i < length; i++)
            add(constant);
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getId() {
        return id;
    }

    @Override
    public void add(double value) {
        add(size, value);
    }
    
    @Override
    public double get(int index) {
        return values.get(index);
    }

    /**
     * Add a value at location tick. Handles the three cases where the
     * value is appended, where it replaces an existing value, and where
     * it adds a value beyond the bounds of the array and the missing 
     * intermediate values are set to zero.
     * 
     * @param tick
     * @param value
     */
    public void add(int tick, double value) {
        
        if (tick == size) {         // tick is the next in sequence -> append to array
            ticks.add(tick);
            values.add(value);
            size++;
        } else if (tick < size) {   // tick already exists in the sequence -> replace value
            values.set(tick, value);
        } else {                    // tick skips ahead of end of sequence -> insert zeros for the skipped values but emit warning
            Assertion.assertStrict(false, Level.INFO, "Inserting value beyond end of array in DoubleTimeSeries '" + id);
            
            for (int i = size; i < tick; i++) {
                ticks.add(i);
                values.add(0);                
            }
            
            ticks.add(tick);
            values.add(value);
            
            size = tick + 1;
        }
    }
    
    public void addToValue(int tick, double value) {
        double v = this.values.get(tick);
        this.values.set(tick, v + value);
    }

    public void set(int tick, double element) {
        values.set(tick, element);
    }

    public int[] ticks() {
        return ticks.elements();
    }

    public double[] values() {
        return values.elements();
    }
    
    public String ticksToString() {
        String ts = "[";
        int nTicks = ticks.size();
        int headLength = nTicks < MAX_OUPUT_HEAD ? nTicks : MAX_OUPUT_HEAD;
        int tailLength = nTicks < MAX_OUPUT_HEAD ? 0 : nTicks - MAX_OUPUT_HEAD;
        tailLength = tailLength < MAX_OUPUT_TAIL ? tailLength : MAX_OUPUT_TAIL; 
        
        for (int i = 0; i < headLength; i++) {
            ts += String.format("%11d", ticks.get(i));
        }
        
        if (tailLength > 0) ts += "     ... ";
        
        for (int i = nTicks - tailLength; i < nTicks; i++) {
            ts += String.format("%11d", ticks.get(i));       // TODO create a settings xml file for the formatting and other settings
        }

        return ts + "]";
    }

    public int size() {
        return values.size();
    }
    
    public static void setFormatter(DecimalFormat df) {
        formatter = df;
    }

    /* (non-Javadoc)
     * @see cern.colt.list.AbstractDoubleList#ensureCapacity(int)
     */
    @Override
    public void ensureCapacity(int minCapacity) {
        ticks.ensureCapacity(minCapacity);
        values.ensureCapacity(minCapacity);
    }

    public int getTick(int index) {
        return ticks.get(index);
    }
    
    /**
     * Return the last tick of the time series
     * 
     * @param index
     * @return
     */
    public int getLastTick() {
        return ticks.get(ticks.size() - 1);
    }

    public double getValue(int index) {
        return values.get(index);
    }

    /* (non-Javadoc)
     * @see cern.colt.list.AbstractDoubleList#getQuick(int)
     */
    @Override
    protected double getQuick(int index) {
        return values.getQuick(index);
    }

    /* (non-Javadoc)
     * @see cern.colt.list.AbstractDoubleList#setQuick(int, double)
     */
    @Override
    protected void setQuick(int index, double element) {
        //		throw IllegalArgumentException("Not implemented");
    }
    
    /**
     * Compares the following characteristics of two time series:
     * <ul>
     * <li> size of the time series (=number of ticks stored)
     * <li> first tick
     * <li> last tick
     * </ul> 
     * 
     * @return true, if the characteristics of both time series are the same
     */
    public Boolean quickCompare(DoubleTimeSeries ts) {
        if ((this.size() != ts.size()) || 
            (this.getTick(0) != ts.getTick(0)) ||
            (this.getTick(this.size() - 1) != ts.getTick(ts.size() - 1)))
            return false;
        
        return true;
    }
    
    
    /**
     * First order difference of the time series
     * 
     * @return
     */
    public DoubleTimeSeries getFirstDiff() {
        
        Assertion.assertOrKill(this.size() > 1, "Method getFirstDiff() requires the time series to contain more than one data point");
        
        DoubleTimeSeries firstDiff = new DoubleTimeSeries();
        
        for (int t = 1; t < this.size(); t++)
            firstDiff.add(this.get(t) - this.get(t-1));
        
        return firstDiff;
    }
    
    
    public double mean() {
        DescriptiveStatistics stats = new DescriptiveStatistics();

        for (int i = 0; i < this.values.size(); i++)
            stats.addValue(this.values.get(i));
        
        return stats.getMean();
    }

    public double stdev() {
        DescriptiveStatistics   stats = new DescriptiveStatistics();
        for (int i = 0; i < this.values.size(); i++)
            stats.addValue(this.values.get(i));
        
        return stats.getStandardDeviation();
    }

    public double skewness() {
        DescriptiveStatistics   stats = new DescriptiveStatistics();
        for (int i = 0; i < this.values.size(); i++)
            stats.addValue(this.values.get(i));
        
        return stats.getSkewness();
    }

    public double unbiasedExcessKurtosis() {
        DescriptiveStatistics   stats = new DescriptiveStatistics();
        for (int i = 0; i < this.values.size(); i++)
            stats.addValue(this.values.get(i));
        
        return stats.getKurtosis();
    }

    public double excessKurtosis() {
        double s2 = 0, s4 = 0, mean = 0, n = this.values.size();
        
        for (int i = 0; i < n; i++)
            mean += this.values.get(i);

        mean /= n;
        
        for (int i = 0; i < n; i++) {
            s2 += Math.pow(this.values.get(i) - mean, 2);
            s4 += Math.pow(this.values.get(i) - mean, 4);
        }
        
        double m2 = s2 / n;
        double m4 = s4 / n;    
        
        return m4 / Math.pow(m2, 2) - 3;
    }
    
    public double unbiasedExcessKurtosisOverInterval(int start, int length) {
        DescriptiveStatistics   stats = new DescriptiveStatistics();

        for (int i = start; i < start + length; i++)
            stats.addValue(this.values.get(i));
        
        return stats.getKurtosis();
    }

    public double normalisedVolatility() {
        DescriptiveStatistics   stats = new DescriptiveStatistics();

        for (int i = 0; i < this.values.size(); i++)
            stats.addValue(this.values.get(i));
        
        return stats.getStandardDeviation() / Math.sqrt(this.values.size());
    }
    
    
    public DoubleArrayList acf(int maxLag) {
        
        DoubleArrayList acfValues = new DoubleArrayList();

        double mean = Descriptive.mean(values);
        double var = Descriptive.variance(values.size(), Descriptive.sum(values), Descriptive.sumOfSquares(values));
        
        for (int lag = 0; lag <= maxLag; lag++)
            acfValues.add(Descriptive.autoCorrelation(values, lag, mean, var));
        
        return acfValues;
    }

    
    public DoubleArrayList acfAbs(int maxLag) {
        
        DoubleArrayList acfValues = new DoubleArrayList();
        DoubleArrayList absValues = new DoubleArrayList();
        
        for (int i = 0; i < values.size(); i++)
            absValues.add(Math.abs(values.get(i)));

        double mean = Descriptive.mean(absValues);
        double var = Descriptive.variance(absValues.size(), Descriptive.sum(absValues), Descriptive.sumOfSquares(absValues));
        
        for (int lag = 0; lag <= maxLag; lag++)
            acfValues.add(Descriptive.autoCorrelation(absValues, lag, mean, var));
        
        return acfValues;
    }

    
    public DoubleArrayList acfSquared(int maxLag) {
        
        DoubleArrayList acfValues = new DoubleArrayList();
        DoubleArrayList squareValues = new DoubleArrayList();
        
        for (int i = 0; i < values.size(); i++)
            squareValues.add(Math.pow(values.get(i), 2));

        double mean = Descriptive.mean(squareValues);
        double var = Descriptive.variance(squareValues.size(), Descriptive.sum(squareValues), Descriptive.sumOfSquares(squareValues));
        
        for (int lag = 0; lag <= maxLag; lag++)
            acfValues.add(Descriptive.autoCorrelation(squareValues, lag, mean, var));
        
        return acfValues;
    }
    
    
    public double percentile(int percentile, int window) {
    	
    	Assertion.assertStrict(window <= this.values.size(), Level.ERR, "percentile(): Length of time series must be larger than the window (" + window + ").");
    	
        DescriptiveStatistics stats = new DescriptiveStatistics();
        int tsLength = this.values.size();

        for (int i = 0; i < window; i++) {
            stats.addValue(this.values.get(tsLength-i-1));
        }
        
        return stats.getPercentile(percentile);
    }
    
  
    @Override
    public String toString() {
        String ts = "[";
        int nTicks = ticks.size();
        int headLength = nTicks < MAX_OUPUT_HEAD ? nTicks : MAX_OUPUT_HEAD;
        int tailLength = nTicks < MAX_OUPUT_HEAD ? 0 : nTicks - MAX_OUPUT_HEAD;
        tailLength = tailLength < MAX_OUPUT_TAIL ? tailLength : MAX_OUPUT_TAIL; 
        
        for (int i = 0; i < headLength; i++) {
            ts += String.format("%11.5g", values.get(i));
        }
        
        if (tailLength > 0) ts += "     ... ";
        
        for (int i = nTicks - tailLength; i < nTicks; i++) {
            ts += String.format("%11.5g", values.get(i));       // TODO create a settings xml file for the formatting and other settings
        }

        return ts + "]";
    }

}
