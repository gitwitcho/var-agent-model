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
package info.financialecology.finance.abm.model.strategy;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Hashtable;

import info.financialecology.finance.abm.model.strategy.TradingStrategy.Order;
import info.financialecology.finance.abm.model.util.TradingPortfolio;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.WorldClock;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import cern.colt.list.DoubleArrayList;

/**
 * A class that implements the (single asset) trend strategy 
 * described in the book “Quantitative Trading Strategies” 
 * (Kestner, 2003, pp.57-60).
 * 
 * The entry signal is triggered by the crossing of a short- and a 
 * long-term moving average of prices. The exit signal is a channel 
 * breakout criterion: a long position is exited when the price reaches 
 * an n-day low and a short position is exited when the price reaches 
 * an n-day high).
 * 
 * @author Gilbert Peffer
 *
 */

/**
 *  
 * ################################################################
 * 
 * This is an OLD version of TrendMABCStrategy.
 * 
 * Sometimes it does not close the positions at the right time
 * step because of some bugs in the indices (confusion between what 
 * is calculated at t and t-1), which are fixed in 'TrendMABCStrategy'.  
 * 
 * #################################################################
 * 
 */


public class TrendMABCStrategy_old implements TradingStrategy {

    // Logging information and errors
    private static Logger logger = LoggerFactory.getLogger(TrendMABCStrategy_old.class);
    
    /**
     *  Parameters
     *    - maShortTicks: range for short (fast) moving average of prices, in ticks
     *    - maLongTicks: range for long (slow) moving average of prices, in ticks
     *    - maExitTicks: range for exit signal moving average, in ticks
     *    - bcTicks: size of window, in ticks, to calculate high/low of exit MA
     *    - lastEntryTick: tick at which the last order was placed
     *    - capFactor: capital factor, to size the trade
     */
    private int maShortTicks;
    private int maLongTicks;
    private int bcTicks;
    private int lastEntryTick = -1; // tick at which last order was placed - default '-1' indicates there are no previous orders
    private int previousTick = -1;  // flag to ensure trade() is called at every tick
    private double capFactor;       // multiplier for size of investment 
    
    private double warmUpPeriod;    // the warm-up period needed for this trading strategy, in ticks
    
    /**
     * At time t, values for prices and positions available only up to time t-1
     */
    private double maShort_previous_tick = 0;     // given: short-run (fast) moving average at t-2
    private double maLong_previous_tick = 0;      // given: long-run (slow) moving average at t-2
    private double maShort_current_tick = 0;     // compute: short-run moving average at t-1
    private double maLong_current_tick = 0;      // compute: long-run moving average at t-1
    
    private boolean firstMAShortCalculation = true; // the first calculation needs to use the full MA method, after that incremental
    private boolean firstMALongCalculation = true;
    private boolean isSlopeDefined = false;         // to calculate the slope of the MA, we need to wait for the second MA calculation

    private DoubleTimeSeries tsPrice;   // time series of prices - an input to TrendMABC
//    private DoubleTimeSeries tsPos;     // time series of positions - an output of TrendMABC
    
    private int volWindow;        // window for the calculation of volatility
    
    private Multiplier multiplier;            // method to calculate the size of the position
    
    public enum Multiplier {       // Method to calculate the size of the position
        CONSTANT,               // the size of the position is equal to the capital factor capFactor
        FAST_MA_SLOPE,          // the size of the position is proportional to the slope of the short (fast) MA
        MA_SLOPE_DIFFERENCE,    // the size of the position is proportional to the difference of the long and short (slow and fast) MAs
        MA_SLOPE_DIFFERENCE_STDDEV,   // the size of the position is proportional to the difference of the long and short (slow and fast) MAs
                                      // and inversely proportional to the standard deviation of prices
        STDDEV;                 // the size of the position is inversely proportional to the standard deviation of prices    
    }
    
    private Order order;        // the order of the share
        
    // Constructor
    public TrendMABCStrategy_old(String secId,
                             int maShortTicks, 
                             int maLongTicks, 
                             int bcTicks, 
                             double capFactor, 
                             DoubleTimeSeries tsPrice,
                             int volWindow,         // TODO tsPrice should 'live' in a market class, where also volatility should be calculated
                             Multiplier multiplier) {
        
        Assertion.assertStrict((secId != null) && (secId.compareTo("") != 0), Level.ERR, "secId cannot be null or an empty string");
        Assertion.assertStrict(maShortTicks < maLongTicks, Level.ERR, "maLong = " + maLongTicks + " has to be " +
                "strictly greater than maShort = " + maShortTicks);
        Assertion.assertStrict((maShortTicks > 0) && (maLongTicks > 0) && (bcTicks > 0), Level.ERR, "maShort, maLong, " +
        		"and bcTicks have to be greater than '0'");
        Assertion.assertStrict(tsPrice != null, Level.ERR, "Price timeseries cannot be null");
        
        if ((multiplier == Multiplier.MA_SLOPE_DIFFERENCE_STDDEV) || (multiplier == Multiplier.STDDEV)) 
            Assertion.assertStrict(volWindow > 0, Level.ERR, "volWindow has to be greater than '0'");
        
        this.maShortTicks = maShortTicks;
        this.maLongTicks = maLongTicks;
        this.bcTicks = bcTicks;
        this.capFactor = capFactor;
        this.tsPrice = tsPrice;
        this.volWindow = volWindow;
        this.multiplier = multiplier;
        
//        this.tsPos = new DoubleTimeSeries();
        this.order = new Order();
        this.order.setSecId(secId);
        
        this.warmUpPeriod = Math.max(maLongTicks, Math.max(maShortTicks, bcTicks)); // TODO I have removed the '+ 1'
    }
    
    /**
     * @return the warmUpPeriod
     */
    public double getWarmUpPeriod() {
        return warmUpPeriod;
    }

    /**
     * Get the current order for the security
     */
    public ArrayList<Order> getOrders() {
        
        ArrayList<Order> orders = new ArrayList<Order>();
        orders.add(order);

        return orders;
    }
    
    /**
     * Get the secId of the share traded by this strategy
     */
    public HashSet<String> getSecIds() {
        
        return null;
    }
    
    /**
     * Get the unique identifier of this strategy. In the single asset case this is equal to secId
     */
    public String getUniqueId() {
        return order.getSecId();
    }


    /**
     * Computing the trade at time t relies on values known up to time t-1.
     * Hence at time 'tick', typically no values exist in the price and position
     * arrays.
     *    
     * @param tick tick at which the next trade takes place
     */
    public void trade(TradingPortfolio portfolio) {
        
        int tick = WorldClock.currentTick();
        String secId = order.getSecId();
        DoubleTimeSeries tsPos = portfolio.getTsPosition(secId);
        
        if (tick == previousTick + 1)
            previousTick = tick;
        else    // TODO Will enforcing a method call at each tick always be feasible? E.g. when no TREND trade is made and therefore we cannot call this method. We should call the full MA method when ticks are skipped?   
            Assertion.assertStrict(false, Level.ERR, "The method trade() " +
        		"in the class TrendMABCStrategy has to be called at each tick, otherwise " +
        		"moving average calculations in trade() will break");
        
        if (tick < warmUpPeriod) {
            tsPos.add(tick, 0.0);
            return;
        }
        
        /*
         * Compute the new MAs at t-1. If they are computed for the first time, 
         * use the full MA computation. Otherwise, use the incremental computation.
         * 
         * This requires for now that trade() is called at every tick, which may 
         * not be feasible. See TODO comment above
         * 
         */
        
        if (firstMAShortCalculation) {
            maShort_current_tick = fullMA(tsPrice, maShortTicks);
            firstMAShortCalculation = false;
        }
        else {
            maShort_current_tick = incrementalMA(tsPrice, maShortTicks, maShort_previous_tick);   // TODO Here the t_minus_2 makes sense, but not inside the MA methods            
        }
        
        if (firstMALongCalculation) {
            maLong_current_tick = fullMA(tsPrice, maLongTicks);
            firstMALongCalculation = false;
        }
        else {
            maLong_current_tick = incrementalMA(tsPrice, maLongTicks, maLong_previous_tick);
        }
        
        /*
         *  Selecting the multiplier for the position calculation 
         */
        double position = 0;
        
        if (multiplier == Multiplier.CONSTANT) {
            position = capFactor;
        }
        else if (multiplier == Multiplier.FAST_MA_SLOPE) {  // Computing slope short MA

            if (isSlopeDefined) {   // slope is defined only if more than one MA value is given 
                double slopeShort_t_minus_1 = Math.atan(maShort_current_tick - maShort_previous_tick);
                position = capFactor * Math.abs(slopeShort_t_minus_1);
            }
            else {  // only one MA value is given at this stage
                position = 0;
                isSlopeDefined = true;  // MA slope is defined in next step
            }
        }
        else if (multiplier == Multiplier.MA_SLOPE_DIFFERENCE) {    // Computing slope difference for fast vs slow MA
            
            if (isSlopeDefined) {   // slope is defined only if more than one MA value is given 
                double slopeShort_t_minus_1 = Math.atan(maShort_current_tick - maShort_previous_tick); 
                double slopeLong_t_minus_1 = Math.atan(maLong_current_tick - maLong_previous_tick);
                double deltaSlope_t_minus_1 = slopeShort_t_minus_1 - slopeLong_t_minus_1;
                
                position = capFactor * Math.abs(deltaSlope_t_minus_1);
            }
            else {  // only one MA value is given at this stage
                position = 0;
                isSlopeDefined = true;  // MA slope is defined in next step
            }

        }
        else if (multiplier == Multiplier.MA_SLOPE_DIFFERENCE_STDDEV) {     // Computing slope difference for fast vs slow MA

            if (isSlopeDefined) {   // slope is defined only if more than one MA value is given 
                double slopeShort_t_minus_1 = Math.atan(maShort_current_tick - maShort_previous_tick); 
                double slopeLong_t_minus_1 = Math.atan(maLong_current_tick - maLong_previous_tick);
                double deltaSlope_t_minus_1 = slopeShort_t_minus_1 - slopeLong_t_minus_1;
                double stdDevPrices_t_minus_1 = stdDev(tsPrice, volWindow);         // Computing the standard deviation of prices

                
                position = capFactor * Math.abs(deltaSlope_t_minus_1) / stdDevPrices_t_minus_1;
            }
            else {  // only one MA value is given at this stage
                position = 0;
                isSlopeDefined = true;  // MA slope is defined in next step
            }
        }
        else if (multiplier == Multiplier.STDDEV) {     // Computing the standard deviation of prices

            
            
             double stdDevPrices_t_minus_1 = stdDev(tsPrice, volWindow);
             
             position = capFactor / stdDevPrices_t_minus_1;     // TODO this needs to be normalised and calibrated properly
        }
        else
            Assertion.assertStrict(false, Level.ERR, "The method for multiplier " + 
                    multiplier + " is not implemented");
        
        /**
         *    - Entry condition for long position
         *    - Entry condition for short position
         *    - Exit condition for long and short position
         */
        if ((maShort_previous_tick < maLong_previous_tick) && (maShort_current_tick >= maLong_current_tick) && (tsPos.get(tick - 1) == 0.0)) {
            tsPos.add(tick, position);
            lastEntryTick = tick;            
        }
        else if ((maShort_previous_tick > maLong_previous_tick) && (maShort_current_tick <= maLong_current_tick) && (tsPos.get(tick - 1) == 0.0)) {
            tsPos.add(tick, - position);
            lastEntryTick = tick;
        }
        else if ((tsPos.get(tick - 1) != 0) && (lastEntryTick != -1)) {
            if (lastEntryTick <= tick - bcTicks) {  // last entry, or order, needs to lie outside of bcTicks window
            	
                double maExitMax = maxValue(tsPrice, bcTicks); 
                double maExitMin = minValue(tsPrice, bcTicks);
                
                if (((tsPrice.get(tick - 1) <= maExitMin) && (tsPos.get(tick - 1) > 0)) ||
                    ((tsPrice.get(tick - 1) >= maExitMax) && (tsPos.get(tick - 1) < 0)))
                    tsPos.add(tick, 0.0);
                else
                    tsPos.add(tick, tsPos.get(tsPos.size() - 1));   // no change in the position
            }
            else
                tsPos.add(tick, tsPos.get(tsPos.size() - 1));   // no change in the position
        }
        else
            tsPos.add(tick, tsPos.get(tsPos.size() - 1));   // no change in the position
        
        if (tick == 0)
            order.setOrder(tsPos.get(tick));
        else
            order.setOrder(tsPos.get(tick) - tsPos.get(tick - 1));
        
        logger.trace("(MA_short, MA_long) = ({}, {})", maShort_current_tick, maLong_current_tick);
        logger.trace("Price_{}: {}", tick, tsPrice.get(tick));
        logger.trace("Pos_{}: {}", tick, tsPos.get(tick));
        
        /* ---- DELETE ----*/
        if (tsPos.get(tick-1) != 0 && lastEntryTick <= tick - bcTicks) {
        	logger.trace("(MIN, MAX) = ({}, {})", maxValue(tsPrice, bcTicks), minValue(tsPrice, bcTicks));
        }
        /* ---- DELETE ---- */

        // Shift ma_t_minus_1 to ma_t_minus_2
        maShort_previous_tick = maShort_current_tick;
        maLong_previous_tick = maLong_current_tick;
    }
    
    /**
     * Compute the new general moving average (MA) of prices at time t-1.
     * The length of the MA interval is equal to maTicks.
     * 
     * There need to be maTicks prices in the time series, otherwise the
     * method throws an error.   
     * 
     * @param maTicks the size of the MA window
     * @param ma_t_minus_2 the last MA value
     * @return the new MA value
     */
    public double incrementalMA(DoubleTimeSeries dts, int maTicks, double ma_t_minus_2) {
        // TODO put the MA function into a time series utilities package
        // TODO The implicit check of when to do the full vs the incremental MA computation is a bad idea (e.g. when starting off with a dts longer than the MA window). Create two methods and handle the decision outside.
        // TODO ma_t_minus_2 and ma_t_minus_1 might be confusing terminology; this should be resolved on the caller level, which is the place where it needs to be consistent with other time-indexed variables
        
        double ma_t_minus_1 = 0.0;
        int numTicksDts = dts.size();
        
        if (numTicksDts > maTicks) {    // subsequent incremental calculations of moving average
            int dropValueTick = numTicksDts - maTicks - 1; // incremental calculation drops tick at the left border of MA window
            ma_t_minus_1 = ma_t_minus_2 + (dts.get(numTicksDts - 1) - dts.get(dropValueTick)) / maTicks;
        }
        else if (numTicksDts == maTicks) {  // TODO REMOVE because it is replaced by fullMA()
            for (int i = 0; i < dts.size(); i++)
                ma_t_minus_1 += dts.getValue(i);
            
            ma_t_minus_1 /= maTicks;
        } else {
            Assertion.assertStrict(false, Level.ERR, "Not enough " +
                    "data points to compute the MA(" + maTicks + ") moving average");            
        }
        
        return ma_t_minus_1;
    }
    
    /**
     * Forces a full MA computation (see problem mentioned in MA(...) method above)
     * @param dts
     * @param maTicks
     * @return
     */
    public double fullMA(DoubleTimeSeries dts, int maTicks) {
        double ma = 0.0;
        int numTicksDts = dts.size();
        
        if (numTicksDts < maTicks)
            Assertion.assertStrict(false, Level.ERR, "Not enough " +
                    "data points to compute the MA(" + maTicks + ") moving average");            
            
        for (int i = dts.size() - maTicks; i < dts.size(); i++)
            ma += dts.getValue(i);
        
        ma /= maTicks;
        
        return ma;
    }
    
    /**
     * Calculates the standard deviation of a time series over a given window.
     * @param dts Input time series
     * @param window Window over which the stdDev is calculated
     * @return
     */
    public double stdDev(DoubleTimeSeries dts, int window) {
    	DoubleTimeSeries dtsPartial = new DoubleTimeSeries();   // Will allocate the values of dts in the chosen window
    	
    	int numTicksDts = dts.size();
    	if (numTicksDts < window) {
            Assertion.assertStrict(false, Level.ERR, "Not enough data points to compute the stdDev of " + dts);
    	}
    	
    	for (int i = dts.size() - window; i < dts.size(); i++) {
            dtsPartial.add(dts.getValue(i));
    	}
    	
        return dtsPartial.stdev();
    }
    
    
    public double maxValue(DoubleArrayList values, int window) {
        double value;
        double maxValue = values.get(values.size() - 1);
        
        for (int i = 1; i < window; i++) {
            value = values.get(values.size() - 1 - i);
            if (maxValue < value)
                maxValue = value;
        }
        
        return maxValue;
    }
    
    public double maxValue(DoubleTimeSeries values, int window) {
        double value;
        double maxValue = values.get(values.size() - 1);
        
        for (int i = 1; i < window; i++) {
            value = values.get(values.size() - 1 - i);
            if (maxValue < value)
                maxValue = value;
        }
        
        return maxValue;
    }
    
    public double minValue(DoubleArrayList values, int window) {
        double value;
        double minValue = values.get(values.size() - 1);
        
        for (int i = 1; i < window; i++) {
            value = values.get(values.size() - 1 - i);
            if (minValue > value)
                minValue = value;
        }
        
        return minValue;
    }
    
    public double minValue(DoubleTimeSeries values, int window) {
        double value;
        double minValue = values.get(values.size() - 1);
        
        for (int i = 1; i < window; i++) {
            value = values.get(values.size() - 1 - i);
            if (minValue > value)
                minValue = value;
        }
        
        return minValue;
    }
}