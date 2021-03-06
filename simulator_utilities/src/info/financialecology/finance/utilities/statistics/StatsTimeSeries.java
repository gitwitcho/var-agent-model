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
package info.financialecology.finance.utilities.statistics;

import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;

import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;

/**
 * @author Gilbert Peffer
 *
 */
public class StatsTimeSeries {
    
    public static DoubleTimeSeries MA(DoubleTimeSeries ts, int window) {
        
        Assertion.assertStrict(window > 0, Level.ERR, "Size of MA window is " + window + ". Needs to be greater than zero");
        
        DoubleTimeSeries maTs = new DoubleTimeSeries();
        
        for (int i = 0; i < ts.size(); i++) {
            
            if (i < window - 1)
                maTs.add(0);
            else {
                double sum = 0;

                for (int j = i - window + 1; j <= i; j++)
                    sum += ts.get(j);

                maTs.add(sum / window);
            }            
        }
        
        return maTs;
    }
    
    /**
     * Compute the moving average (MA) of a time series at time t.
     * The length of the MA interval is equal to maTicks.
     * 
     * There need to be maTicks prices in the time series, otherwise the
     * method throws an error.   
     * 
     * @param dts the time series
     * @param maTicks the size of the MA window
     * @param ma_t_minus_1 the last MA value
     * @return the new MA value
     */
    public static double incrementalMA(DoubleTimeSeries dts, int maTicks, double ma_t_minus_1) {
        
        double ma_t = 0.0;
        int numTicksDts = dts.size();
        
        if (numTicksDts > maTicks) {    // subsequent incremental calculations of moving average
            int dropValueTick = numTicksDts - maTicks - 1; // incremental calculation drops tick at the left border of MA window
            ma_t = ma_t_minus_1 + (dts.get(numTicksDts - 1) - dts.get(dropValueTick)) / maTicks;
        }
        else if (numTicksDts == maTicks) {  // TODO REMOVE because it is replaced by fullMA()
            for (int i = 0; i < dts.size(); i++)
                ma_t += dts.getValue(i);
            
            ma_t /= maTicks;
        } else {
            Assertion.assertStrict(false, Level.ERR, "Not enough " +
                    "data points to compute the MA(" + maTicks + ") moving average");            
        }
        
        return ma_t;
    }
    
    
    /**
     * Forces a full MA computation of a time series at time t
     * (see problem mentioned in MA(...) method above)
     * 
     * @param dts the time series
     * @param maTicks the size of the MA window
     * @return the new MA value
     */
    public static double fullMA(DoubleTimeSeries dts, int maTicks) {
        double ma_t = 0.0;
        int numTicksDts = dts.size();
        
        if (numTicksDts < maTicks)
            Assertion.assertStrict(false, Level.ERR, "Not enough " +
                    "data points to compute the MA(" + maTicks + ") moving average");            
            
        for (int i = dts.size() - maTicks; i < dts.size(); i++)
            ma_t += dts.getValue(i);
        
        ma_t /= maTicks;
        
        return ma_t;
    }
    
    /**
     * @param ts Time series of prices
     * @param window Window over which the maximum value is calculated
     * @return Maximum value of the ts time series over a window
     */
    public static DoubleTimeSeries maxValue(DoubleTimeSeries ts, int window) {
    	
        Assertion.assertStrict(window > 0, Level.ERR, "Size of maxValue window is " + window + ". Needs to be greater than zero");
        
        DoubleTimeSeries maxTs = new DoubleTimeSeries();
        
        for (int i = 0; i < ts.size(); i++) {
        	
        	if (i < window - 1)
                maxTs.add(0);
            else {
                double value;
                double maxValue = ts.get(i);
        
                for (int j = 1; j < window; j++) {
                	value = ts.get(i - j);
                	if (maxValue < value)
                		maxValue = value;
                }
                
                maxTs.add(maxValue);
            }
        }
        
        return maxTs;
    }
    
    /**
     * @param ts Time series of prices
     * @param window Window over which the minimum value is calculated
     * @return Minimum value of the ts time series over a window
     */
    public static DoubleTimeSeries minValue(DoubleTimeSeries ts, int window) {
    	
        Assertion.assertStrict(window > 0, Level.ERR, "Size of minValue window is " + window + ". Needs to be greater than zero");
        
        DoubleTimeSeries minTs = new DoubleTimeSeries();
        
        for (int i = 0; i < ts.size(); i++) {
        	
        	if (i < window - 1)
                minTs.add(0);
            else {
                double value;
                double minValue = ts.get(i);
        
                for (int j = 1; j < window; j++) {
                	value = ts.get(i - j);
                	if (minValue > value)
                		minValue = value;
                }
                
                minTs.add(minValue);
            }
        }
        
        return minTs;
    }
    

    /**
     * @param ts Time series of prices
     * @return Maximum value of the ts time series (in absolute value)
     */
    public static double maxAbsValue(DoubleTimeSeries ts) {
        
        double maxAbsTs = Math.abs(ts.get(0));
        
        for (int i = 1; i < ts.size(); i++) {
        	
        	if (maxAbsTs < Math.abs(ts.get(i))) {
        		maxAbsTs = Math.abs(ts.get(i));
        	}
        }
        
        return maxAbsTs;
    }
    
    /**
     * @param ts Time series of prices
     * @param window Window over which the mean is calculated
     * @return Mean of the ts time series over a window
     */
    public static double mean(DoubleTimeSeries ts, int window) {
    	
        Assertion.assertStrict(window > 0, Level.ERR, "Size of mean window is " + window + ". Needs to be greater than zero");
        
        DoubleTimeSeries dtsPartial = new DoubleTimeSeries();   // Will allocate the values of dts in the chosen window        

        if (ts.size() < window) {
            Assertion.assertStrict(false, Level.ERR, "Not enough data points to compute the mean of " + ts);
    	}
    	
    	for (int i = ts.size() - window; i < ts.size(); i++) {
            dtsPartial.add(ts.getValue(i));
    	}
    	
        return dtsPartial.mean();
    }
    
    
    /**
     * @param ts Time series of prices
     * @param window Window over which the standard deviation is calculated
     * @return Standard deviation of the ts time series over a window
     */
    public static double stdDev(DoubleTimeSeries ts, int window) {
    	
        Assertion.assertStrict(window > 0, Level.ERR, "Size of stdDev window is " + window + ". Needs to be greater than zero");
        
        DoubleTimeSeries dtsPartial = new DoubleTimeSeries();   // Will allocate the values of dts in the chosen window        

        if (ts.size() < window) {
            Assertion.assertStrict(false, Level.ERR, "Not enough data points to compute the stdDev of " + ts);
    	}
    	
    	for (int i = ts.size() - window; i < ts.size(); i++) {
            dtsPartial.add(ts.getValue(i));
    	}
    			
        return dtsPartial.stdev();
//    	return dtsPartial.stdev() * Math.sqrt(window-1)/Math.sqrt(window);   // VERIFICATION TEST
    }
    

    
    /**
     * Compute the variance (over a window) of a time series 
     * at time t, in an incremental way to reduce the simulation time.
     * 
     * This method uses the following formula:
     *      Variance = <X^2> - (<X>)^2
     * 
     * @param dts the time series
     * @param window the size of the window
     * @param variance_t_minus_1 the last value of the variance
     * @param mean_t_minus_1 the last value of the mean, to also calculate the mean incrementally
     * @return the new standard deviation value
     */
    public static double incrementalVariance(DoubleTimeSeries dts, int window, double variance_t_minus_1, double mean_t_minus_1) {
        
        double mean_t = 0.0;
        double variance_t = 0.0;
        double squares_t = 0.0;
        int numTicksDts = dts.size();
        
        if (numTicksDts > window) {    // subsequent incremental calculations of variance
            int dropValueTick = numTicksDts - window - 1;  // incremental calculation drops tick at the left border of variance window
            mean_t = mean_t_minus_1 + (dts.get(numTicksDts - 1) - dts.get(dropValueTick)) / window;
            variance_t = variance_t_minus_1 + Math.pow(mean_t_minus_1, 2) - Math.pow(mean_t, 2) + (Math.pow(dts.get(numTicksDts - 1), 2) - Math.pow(dts.get(dropValueTick), 2)) / window;  
        }
        else if (numTicksDts == window) {  // Use the full calculation of variance
            for (int i = 0; i < dts.size(); i++) {
                squares_t += Math.pow(dts.getValue(i), 2);
                mean_t += dts.getValue(i);
            }
            squares_t /= window;
            mean_t /= window;
            variance_t = squares_t - Math.pow(mean_t, 2);
            
        } else {
            Assertion.assertStrict(false, Level.ERR, "Not enough " +
                    "data points to compute the incremental variance over window = " + window);            
        }
        
        return variance_t;
    }

    
    
    /**
     * The time series of increments in wealth
     * 
     * @param prices time series of prices
     * @param positions time series of positions
     * @return increment in wealth at every time step, which is equal to the position multiplied by the gain/loss due to price changes
     */
    public static DoubleTimeSeries deltaWealth(DoubleTimeSeries prices, DoubleTimeSeries positions) {
        
        DoubleTimeSeries dtsWealthIncrement = new DoubleTimeSeries("wealth");
        
        dtsWealthIncrement.add(0);  // initialise the wealth increment at t=0
        
        for (int i = 1; i < prices.size(); i++) {
//        	double deltaWealth = positions.get(i) * (prices.get(i) - prices.get(i-1));
        	double deltaWealth = positions.get(i-1) * (prices.get(i) - prices.get(i-1));  // fixed the formula because the price is updated before the position
            dtsWealthIncrement.add(dtsWealthIncrement.get(i-1) + deltaWealth);
        }
                
        return dtsWealthIncrement;
    }
    
    /**
     * @param tsSeries_1 first time series
     * @param tsSeries_2 second time series
     * @return Pearson correlation between the two time series
     */
    public static double correlation(DoubleTimeSeries tsSeries_1, DoubleTimeSeries tsSeries_2) {
    	
    	Assertion.assertStrict(tsSeries_1.size() == tsSeries_2.size(), Level.ERR, "correlation: Size of time series must be the same");
    	
    	double correlation;
    	double productSum = 0.0;
    	double mean_1 = tsSeries_1.mean();
    	double mean_2 = tsSeries_2.mean();
    	double stdev_1 = tsSeries_1.stdev();
    	double stdev_2 = tsSeries_2.stdev();
    	int nObs = tsSeries_1.size();
    	
    	for (int i = 0; i < tsSeries_1.size(); i++) {
    		productSum = productSum + tsSeries_1.get(i) * tsSeries_2.get(i);
        }
    	
    	correlation = (productSum - nObs * mean_1 * mean_2) / ((nObs - 1) * stdev_1 * stdev_2);
                
        return correlation;
    }
    
    
    /**
     * @param tsSeries_1 first time series
     * @param tsSeries_2 second time series
     * @param window Window over which the correlation is calculated
     * @return Pearson correlation between the two time series over a window
     */
    public static double correlation(DoubleTimeSeries tsSeries_1, DoubleTimeSeries tsSeries_2, int window) {
    	
    	Assertion.assertStrict(tsSeries_1.size() == tsSeries_2.size(), Level.ERR, "correlation: Size of time series must be the same");
    	
    	double correlation;
    	double productSum = 0.0;
    	double mean_1 = mean(tsSeries_1, window);
    	double mean_2 = mean(tsSeries_2, window);
    	double stdev_1 = stdDev(tsSeries_1, window);
    	double stdev_2 = stdDev(tsSeries_2, window);
    	
    	for (int i = tsSeries_1.size() - window; i < tsSeries_1.size(); i++) {
    		productSum = productSum + tsSeries_1.get(i) * tsSeries_2.get(i);
        }
    	
    	correlation = (productSum - window * mean_1 * mean_2) / ((window - 1) * stdev_1 * stdev_2);
                
        return correlation;
    }
    
    
    /**
     * @param tsSeries_1 first time series
     * @param tsSeries_2 second time series
     * @param window Window over which the covariance is calculated
     * @return Covariance between the two time series over a window
     */
    public static double covariance(DoubleTimeSeries tsSeries_1, DoubleTimeSeries tsSeries_2, int window) {
    	
    	Assertion.assertStrict(tsSeries_1.size() == tsSeries_2.size(), Level.ERR, "covariance: Size of time series must be the same");
    	
    	double covariance;
    	double productSum = 0.0;
    	double mean_1 = mean(tsSeries_1, window);
    	double mean_2 = mean(tsSeries_2, window);

        if (tsSeries_1.size() < window) {
            Assertion.assertStrict(false, Level.ERR, "Not enough data points to compute the covariance of " + tsSeries_1 + "and " + tsSeries_2);
    	}
    	
    	for (int i = tsSeries_1.size() - window; i < tsSeries_1.size(); i++) {
    		productSum = productSum + (tsSeries_1.get(i) - mean_1) * (tsSeries_2.get(i) - mean_2);
    	}

    	covariance = productSum / (window - 1); 
//    	covariance = productSum / (window);   // VERIFICATION TEST
                
        return covariance;
    }
    
    
    /**
     * Compute the covariance (over a window) of two time series 
     * at time t, in an incremental way to reduce the simulation time.
     * 
     * This method uses the following formula:
     *      Covariance(X,Y) = <X*Y> - <X>*<Y>
     * 
     * @param dts1 first time series
     * @param dts2 second time series
     * @param window Window over which the covariance is calculated
     * @param covariance_t_minus_1 the last value of covariance
     * @param mean_dts1_t_minus_1 the last value of the mean of first time series, to also calculate its mean incrementally
     * @param mean_dts2_t_minus_1 the last value of the mean of second time series, to also calculate its mean incrementally
     * @return the new standard deviation value
     */
    public static double incrementalCovariance(DoubleTimeSeries dts1, DoubleTimeSeries dts2, int window, double covariance_t_minus_1, double mean_dts1_t_minus_1, double mean_dts2_t_minus_1) {
        
    	Assertion.assertStrict(dts1.size() == dts2.size(), Level.ERR, "incrementalCovariance: Size of time series must be the same");
    	
        double mean_dts1_t = 0.0;
        double mean_dts2_t = 0.0;
        double covariance_t = 0.0;
        double product_t = 0.0;
        int numTicksDts = dts1.size();
        
        if (numTicksDts > window) {    // subsequent incremental calculations of covariance
            int dropValueTick = numTicksDts - window - 1;  // incremental calculation drops tick at the left border of covariance window
            mean_dts1_t = mean_dts1_t_minus_1 + (dts1.get(numTicksDts - 1) - dts1.get(dropValueTick)) / window;
            mean_dts2_t = mean_dts2_t_minus_1 + (dts2.get(numTicksDts - 1) - dts2.get(dropValueTick)) / window;
            covariance_t = covariance_t_minus_1 + mean_dts1_t_minus_1 * mean_dts2_t_minus_1 - mean_dts1_t * mean_dts2_t + 
            		(dts1.get(numTicksDts - 1) * dts2.get(numTicksDts - 1) - dts1.get(dropValueTick) * dts2.get(dropValueTick)) / window;  
        }
        else if (numTicksDts == window) {  // Use the full calculation of covariance
            for (int i = 0; i < numTicksDts; i++) {
                product_t += dts1.getValue(i) * dts2.getValue(i);
                mean_dts1_t += dts1.getValue(i);
                mean_dts2_t += dts2.getValue(i);
            }
            product_t /= window;
            mean_dts1_t /= window;
            mean_dts2_t /= window;
            covariance_t = product_t - mean_dts1_t + mean_dts2_t;
            
        } else {
            Assertion.assertStrict(false, Level.ERR, "Not enough " +
                    "data points to compute the incremental covariance over window = " + window);            
        }
        
        return covariance_t;
    }

    
    /**
     * Calculates the difference between two time series (minuend - subtrahend).
     * @param tsMinuend The first time series in the substraction
     * @param tsSubtrahend The time series to be substracted
     * @return the difference of the two time series, minuend - subtrahend
     */
    public static DoubleTimeSeries substraction(DoubleTimeSeries tsMinuend, DoubleTimeSeries tsSubtrahend) {
        
        Assertion.assertOrKill(tsMinuend.size() == tsSubtrahend.size(), "Method substraction() requires the two time series to be the same size");
        
        DoubleTimeSeries tsSubstraction = new DoubleTimeSeries();
        
        for (int t = 0; t < tsMinuend.size(); t++)
            tsSubstraction.add(t, tsMinuend.get(t) - tsSubtrahend.get(t));
        
        return tsSubstraction;
    }

}
