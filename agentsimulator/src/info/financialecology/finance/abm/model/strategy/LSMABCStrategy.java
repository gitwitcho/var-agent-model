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
package info.financialecology.finance.abm.model.strategy;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;

import info.financialecology.finance.abm.model.strategy.TradingStrategy.Order;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.MultiplierTrend;
import info.financialecology.finance.abm.model.util.TradingPortfolio;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.WorldClock;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.statistics.StatsTimeSeries;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * A class that implements a multi-asset long-short strategy. The entry and 
 * exit conditions are inspired in the strategy presented by Chiu in his article 
 * "High-frequency trading" (2011); the calculation of the position on each asset
 * is done with an heuristic ratio tested by us in Excel. 
 * 
 * The entry signal is triggered when the spread crosses the threshold
 * mean +- 2 stdev for the second time, to invest when the spread is assumed to
 * be converging. The exit signal is triggered when the spread converges 
 * (the convergence threshold is set at mean +- 0.5 stdev) or, as a stop loss measure, 
 * also when the spread diverges too much (the divergence threshold is set at 
 * mean +- 3 stdev). 
 * 
 * Differences with LSMABCStrategy_Excel:
 *   - Entry condition based on mean and stdev instead of percentiles.
 *   - The position is updated at each time step between entry and exit.
 * 
 * 
 * @author Barbara Llacay
 */

public class LSMABCStrategy implements TradingStrategy {

    // Logging information and errors
    private static Logger logger = LoggerFactory.getLogger(LSMABCStrategy.class);
    
//    /*
//     *  Parameters
//     *    - histWindow: window for the calculation of historical mean and stddev of the spread (used in the entry/exit thresholds)
//     *    - volWindowStrat: window for the calculation of volatility (used in the formula of position)
//     *    - capFactor: multiplier for size of investment
//     */
    
    private int maSpreadShortTicks;           // short-term window for the mean of the spread
    private int maSpreadLongTicks;            // long-term window for the calculation of historical mean and stddev of the spread (used in the entry/exit thresholds)
    private int volWindowStrat;               // window for the calculation of volatility (used in the formula of position)
    private double capFactor;                 // multiplier for size of investment
    private double entryDivergenceSigmas;     // number of sigmas used in the entry condition (spread divergence) 
    private double exitConvergenceSigmas;     // number of sigmas used in the exit condition (spread convergence)
    private double exitStopLossSigmas;        // number of sigmas used in the exit condition (stop loss)
    private int previousTick  = -1;           // flag to ensure trade() is called at every tick
    
    private double warmUpPeriod;              // the warm-up period needed for this trading strategy, in ticks
    
    private boolean firstMAShortCalculation = true;     // the first calculation needs to use the full MA method, after that incremental
    private boolean firstMALongCalculation  = true;
    
    private MultiplierLS multiplier;          // method to calculate the size of the position
    private PositionUpdateLS positionUpdate;  // specifies if a position can be modified while open
    
    public enum MultiplierLS {        // Method to calculate the size of the position
        DIVERGENCE,         // the size of the position is proportional to the difference between the spread and its mean
        DIVERGENCE_STDDEV;  // the size of the position is proportional to the difference between the spread and its mean
        					// and inversely proportional to the standard deviation of the spread
    }
    
    public enum PositionUpdateLS {      // Method to calculate the size of the position
        CONSTANT,                       // the position is kept constant while it is open
        VARIABLE;                       // the position is modified at each time step while it is open    
    }
    
    public enum UseVaRLS {      // Specifies if the agent uses a value-at-risk system
        YES,                    // The agent uses VaR
        NO;                     // The agent does not use VaR   
    }
    
    /*
     * At time t, values for prices and positions available only up to time t-1
     */
    private double maShort_t_1       = 0;        // given: short-run (fast) moving average at t-1
    private double maLong_t_1        = 0;        // given: long-run (slow) moving average at t-1
    private double maShort_t         = 0;        // compute: short-run moving average at t
    private double maLong_t          = 0;        // compute: long-run moving average at t
    private double maVariance_t_1    = 0;        // given: variance at t-1
    private double maVariance_t      = 0;        // compute: variance at t
    private Boolean forceFullMACalc  = false;    // enforces a full moving average calculation if no trade was made at the previous time step
    
    private DoubleTimeSeries tsPrice_1;       // time series of prices which constitute the spread - an input to LSMABC
    private DoubleTimeSeries tsPrice_2;
    private DoubleTimeSeries tsSpread;        // time series of the spread  Price_1 - Price_2
//    private DoubleTimeSeries tsPos_1;         // time series of positions in the two assets which constitute the spread - an output of LSMABC
//    private DoubleTimeSeries tsPos_2;
    
    private Order order_1;                    // the order of the two shares which constitute the spread
    private Order order_2;
    private HashSet<String> secIds;           // the security identifier
    
    int nCrossUpEntryThreshold = 0;           // counter for the number of times that the spread has crossed the upper entry threshold since last position
    int nCrossDownEntryThreshold = 0;         // counter for the number of times that the spread has crossed the lower entry threshold since last position

    private double manualNormFactor = 1.0;    // the (manually calculated) factor to normalise the orders of VALUE and LS traders

//    /** Constructor
//     * 
//     * @param secId_1
//     * @param tsPrice_1
//     * @param secId_2
//     * @param tsPrice_2
//     * @param tsSpread
//     * @param maSpreadShortTicks
//     * @param maSpreadLongTicks
//     * @param volWindowStrat
//     * @param entryDivergenceSigmas
//     * @param exitConvergenceSigmas
//     * @param exitStopLossSigmas    
//     * @param capFactor
//     * @param multiplier
//     * @param positionUpdate
//     */
        
    public LSMABCStrategy(String secId_1, 
    						DoubleTimeSeries tsPrice_1,   // TODO tsPrice should 'live' in a market class, where also volatility should be calculated
    						String secId_2,
    						DoubleTimeSeries tsPrice_2,
    						DoubleTimeSeries tsSpread,
    						int maSpreadShortTicks,
    						int maSpreadLongTicks,
    						int volWindowStrat,
    						double entryDivergenceSigmas,
    						double exitConvergenceSigmas,
    						double exitStopLossSigmas,
    						double capFactor,
    						MultiplierLS multiplier,
    						PositionUpdateLS positionUpdate) {
    
        Assertion.assertStrict((secId_1 != null) && (secId_1.compareTo("") != 0), Level.ERR, "secId_1 cannot be null or an empty string");
        Assertion.assertStrict((secId_2 != null) && (secId_2.compareTo("") != 0), Level.ERR, "secId_2 cannot be null or an empty string");
        Assertion.assertStrict(volWindowStrat > 0, Level.ERR, "volWindowStrat has to be greater than '0'");
        Assertion.assertStrict((maSpreadShortTicks > 0) && (maSpreadLongTicks > 0), Level.ERR, "maShortTicks and maLongTicks have to be greater than '0'");
        Assertion.assertStrict((tsPrice_1 != null) && (tsPrice_2 != null), Level.ERR, "Price timeseries cannot be null");
        Assertion.assertStrict((tsSpread != null), Level.ERR, "Spread timeseries cannot be null");

    	this.tsPrice_1 = tsPrice_1;
    	this.tsPrice_2 = tsPrice_2;
    	this.tsSpread = tsSpread;
        this.maSpreadShortTicks = maSpreadShortTicks;
        this.maSpreadLongTicks = maSpreadLongTicks;
        this.volWindowStrat = volWindowStrat;
        this.entryDivergenceSigmas = entryDivergenceSigmas;
        this.exitConvergenceSigmas = exitConvergenceSigmas;
        this.exitStopLossSigmas = exitStopLossSigmas;
        this.capFactor = capFactor;
    	this.multiplier = multiplier;
        this.positionUpdate = positionUpdate;
    	
//        this.tsPos_1 = new DoubleTimeSeries();
//        this.tsPos_2 = new DoubleTimeSeries();
        
        this.order_1 = new Order();   // this needs to hold several orders; one order object for each order, incl. if secId is the same
        this.order_2 = new Order();
        this.order_1.setSecId(secId_1);
        this.order_2.setSecId(secId_2);

        this.secIds = new HashSet<String>();
        this.secIds.add(secId_1);
        this.secIds.add(secId_2);
        
        if (multiplier == MultiplierLS.DIVERGENCE_STDDEV) {
        	this.warmUpPeriod = Math.max(volWindowStrat, Math.max(maSpreadLongTicks, maSpreadShortTicks));
        }
        else {
        	this.warmUpPeriod = Math.max(maSpreadLongTicks, maSpreadShortTicks);
        }
    }    


    /**
     * Get the current order for the security
     */
    public ArrayList<Order> getOrders() {
        
        ArrayList<Order> orders = new ArrayList<Order>();
        
        if (order_1 != null)  // if the position didn't change, the order was set to null; add no order object to the array list
            orders.add(order_1);

        if (order_2 != null)  // if the position didn't change, the order was set to null; add no order object to the array list
            orders.add(order_2);

        return orders;
    }
    
    
    /**
     * Get the secId of the share traded by this strategy
     */
    public HashSet<String> getSecIds() {
        
        return secIds;
    }
    
    
    /**
     * Get a unique identifier for the trading strategy. As the strategy involves two assets, the
     * identifier is equal to "secId1_secId2".
     * 
     * @param 
     */
    public String getUniqueId() {
        return order_1.getSecId() + "_" + order_2.getSecId();
    }
    

    /**
     * Compute the position and order for the current trade. If there was no trade placed at the
     * previous tick, then force a full moving average calculation. Otherwise use the more efficient
     * {@code incrementalMA(...)} algorithm
     *     
     */
    public void trade(TradingPortfolio portfolio) {
        
        int tick = WorldClock.currentTick();
        String secId_1 = order_1.getSecId();
        String secId_2 = order_2.getSecId();
        DoubleTimeSeries tsPos_1 = portfolio.getTsPosition(secId_1);
        DoubleTimeSeries tsPos_2 = portfolio.getTsPosition(secId_2);
                
        if (tick == previousTick + 1) { // incremental MA or full MA?
            previousTick = tick;
            forceFullMACalc = false;
        }
        else {
            Assertion.assertStrict(false, Level.INFO, "The method trade() in the class LSMABCStrategy " +
            		"has not been called at the previous tick t=" + previousTick + ", so that the full MA" +
            	    "calculation will be used to compute the new position");
            forceFullMACalc = true;
        }
        
//        DoubleTimeSeries tsSpread = StatsTimeSeries.substraction(tsPrice_1, tsPrice_2);  // spread = Price_1 - Price_2  //!! Deleted because it takes too much time
 
        if (tick < warmUpPeriod) {    // no positions and orders are calculated during warm-up 
            tsPos_1.add(tick, 0.0);
            tsPos_2.add(tick, 0.0);
            return;
        }
        
        // Recalculate the positions entered for this spread in the previous tick
        double pos_1_previous_tick = -tsPos_2.get(tick - 1) * tsPrice_2.get(tick - 1) / tsPrice_1.get(tick - 1);
        double pos_2_previous_tick = tsPos_2.get(tick - 1);
        
        double pos_1_current_tick = 0;
        double pos_2_current_tick = 0;      
        
        // Check if a position has already been entered for asset 1 in current tick
        double pos_1_already_introduced = 0;
        if (tsPos_1.size() == tick + 1)    // a trade has been done in current tick for another spread
        	pos_1_already_introduced = tsPos_1.get(tick);
      

        
        /*
         * Compute the new moving averages at the current tick. If they are computed for the first time, 
         * use the full MA computation. Otherwise, use the incremental computation.
         * 
         * This requires for now that trade() is called at every tick, which may 
         * not be feasible.
         * 
         * 
         */
               
        if (firstMAShortCalculation) {        	        	
            maShort_t = StatsTimeSeries.fullMA(tsSpread, maSpreadShortTicks);
            firstMAShortCalculation = false;
        }
        else {
            if (forceFullMACalc)
                maShort_t = StatsTimeSeries.fullMA(tsSpread, maSpreadShortTicks);
            else
                maShort_t = StatsTimeSeries.incrementalMA(tsSpread, maSpreadShortTicks, maShort_t_1);            
        }
        
        if (firstMALongCalculation) {   // Historical (long-term) mean and stdev of the spread, used in entry/exit thresholds
            maLong_t = StatsTimeSeries.fullMA(tsSpread, maSpreadLongTicks);
            maVariance_t = Math.pow(StatsTimeSeries.stdDev(tsSpread, maSpreadLongTicks), 2);
            firstMALongCalculation = false;
        }
        else {
            if (forceFullMACalc) {
                maLong_t = StatsTimeSeries.fullMA(tsSpread, maSpreadLongTicks);
                maVariance_t = Math.pow(StatsTimeSeries.stdDev(tsSpread, maSpreadLongTicks), 2);
            }
            else {
                maLong_t = StatsTimeSeries.incrementalMA(tsSpread, maSpreadLongTicks, maLong_t_1);
                maVariance_t = StatsTimeSeries.incrementalVariance(tsSpread, maSpreadLongTicks, maVariance_t_1, maLong_t_1);
            }
        }
        
        double longStdDevSpread_t = Math.sqrt(maVariance_t);        
       
        /*
         *  Selecting the multiplier for the position calculation 
         */
        double position = 0;
        
        if (multiplier == MultiplierLS.DIVERGENCE) {
        	position = capFactor * Math.abs(maShort_t - maLong_t);
            manualNormFactor = 1.75;
        }        
        else if (multiplier == MultiplierLS.DIVERGENCE_STDDEV) {
            double stdDevSpread_t = StatsTimeSeries.stdDev(tsSpread, volWindowStrat);    // Short-term mean and stdev of the spread, used in the calculation of positions
                                                                                         // TODO: stdDev should be calculated using the incrementalVariance() method
            position = capFactor * Math.abs(maShort_t - maLong_t) / stdDevSpread_t;
            manualNormFactor = 2.5;
        }        
 
        position = position * manualNormFactor;
        
       
        /**
         * ENTRY condition
         * - Calculate the number of crossings of the entry threshold (mean +- 2 stdev) since the last position was closed.
         * - Open a position when the number of crossings is 2 (the spread is then expected to be reversing to
         *   its historical mean value).
         */
        
        // Count the crossings of upper entry threshold (mean + 2*stdev) since last position
        
        if (tsPos_2.get(tick - 1) != 0.0) {  // A position is already open in this spread 
        	                                 // !! This condition assumes that all spreads are defined as Price_0 - Price_i, so they differ in the second asset
        	nCrossUpEntryThreshold = 0;
        }
        else {
        	double upThreshold = maLong_t + entryDivergenceSigmas * longStdDevSpread_t;
        	if ((maShort_t_1 < upThreshold) && (maShort_t >= upThreshold))
        		nCrossUpEntryThreshold = 1;
        	else if ((nCrossUpEntryThreshold == 1) && (maShort_t_1 > upThreshold) && (maShort_t <= upThreshold))
        		nCrossUpEntryThreshold = 2;
        }
        
        // Count the crossings of lower entry threshold (mean - 2*stdev) since last position
        
        if (tsPos_2.get(tick - 1) != 0.0) {  // A position is already open in this spread 
        	                                 // !! This condition assumes that all spreads are defined as Price_0 - Price_i, so they differ in the second asset
        	nCrossDownEntryThreshold = 0;
        }
        else {
        	double downThreshold = maLong_t - entryDivergenceSigmas * longStdDevSpread_t;
        	if ((maShort_t_1 > downThreshold) && (maShort_t <= downThreshold))
        		nCrossDownEntryThreshold = 1;
        	else if ((nCrossDownEntryThreshold == 1) && (maShort_t_1 < downThreshold) && (maShort_t >= downThreshold))
        		nCrossDownEntryThreshold = 2;
        }
        
        // Open a position when the entry threshold is crossed for the second time
       
        if (nCrossUpEntryThreshold == 2) {
//        	tsPos_1.add(tick, -position);
//        	tsPos_2.add(tick, position * tsPrice_1.get(tick) / tsPrice_2.get(tick));  // Position adjusted with price ratio to have the same dollar value
        	pos_1_current_tick = -position;
        	pos_2_current_tick = position * tsPrice_1.get(tick) / tsPrice_2.get(tick);   // Position adjusted with price ratio to have the same dollar value
        }
        else if (nCrossDownEntryThreshold == 2) {
//        	tsPos_1.add(tick, position);
//        	tsPos_2.add(tick, -position * tsPrice_1.get(tick) / tsPrice_2.get(tick));  // Position adjusted with price ratio to have the same dollar value
        	pos_1_current_tick = position;
        	pos_2_current_tick = -position * tsPrice_1.get(tick) / tsPrice_2.get(tick);   // Position adjusted with price ratio to have the same dollar value
        }
        
        /**
         * EXIT condition
         * - Close a position when the spread has converged to [mean +- 0.5 std]
         * - Close a position when the spread has diverged beyond [mean +- 3 std]
         */
        
        else {  // The entry condition is not satisfied
            if (tsPos_2.get(tick - 1) > 0 && ((maShort_t < maLong_t + exitConvergenceSigmas*longStdDevSpread_t) ||    // The position was opened after double-crossing the UPPER entry threshold
        			(maShort_t > maLong_t + exitStopLossSigmas*longStdDevSpread_t))) {   // The spread has converged or diverged too much

//        		tsPos_1.add(tick, 0);
//        		tsPos_2.add(tick, 0);
            	pos_1_current_tick = 0;
            	pos_2_current_tick = 0;
        	}

            else if (tsPos_2.get(tick - 1) < 0 && ((maShort_t > maLong_t - exitConvergenceSigmas*longStdDevSpread_t) ||    // The position was opened after double-crossing the LOWER entry threshold
        			(maShort_t < maLong_t - exitStopLossSigmas*longStdDevSpread_t))) {  // The spread has converged or diverged too much

//        		tsPos_1.add(tick, 0);
//        		tsPos_2.add(tick, 0);
            	pos_1_current_tick = 0;
            	pos_2_current_tick = 0;
        	}
        	
        	else {
        		if (positionUpdate == PositionUpdateLS.VARIABLE) {        
//        			tsPos_1.add(tick, Math.abs(position) * Math.signum(tsPos_1.get(tick - 1)));
//        			tsPos_2.add(tick, Math.abs(position) * Math.signum(tsPos_2.get(tick - 1)) * tsPrice_1.get(tick) / tsPrice_2.get(tick)); // Position adjusted with price ratio to have the same dollar value
        			pos_1_current_tick = Math.abs(position) * Math.signum(pos_1_previous_tick);
        			pos_2_current_tick = Math.abs(position) * Math.signum(pos_2_previous_tick) * tsPrice_1.get(tick) / tsPrice_2.get(tick);  // Position adjusted with price ratio to have the same dollar value
        		}
        		else if (positionUpdate == PositionUpdateLS.CONSTANT) {        
//        			tsPos_1.add(tick, tsPos_1.get(tick - 1));
//        			tsPos_2.add(tick, tsPos_2.get(tick - 1));
        			pos_1_current_tick = pos_1_previous_tick;  //!!! This does not work well, because one would need to know in which tick the position
        			pos_2_current_tick = pos_2_previous_tick;  //    was opened (to recover the prices at that tick and calculate 'pos_1_previous_tick')
        		}
        		else 
        			Assertion.assertStrict(false, Level.ERR, "The method for positionUpdate " + positionUpdate + " is not implemented");        
        	}
        }
        
        
        /**
         * Compute the order and absolute order
         */
        
//        order_1.setOrder(tsPos_1.get(tick) - tsPos_1.get(tick - 1));
//        order_2.setOrder(tsPos_2.get(tick) - tsPos_2.get(tick - 1));
        order_1.setOrder(pos_1_current_tick - pos_1_previous_tick);
        order_2.setOrder(pos_2_current_tick - pos_2_previous_tick);
        tsPos_1.add(tick, pos_1_already_introduced + pos_1_current_tick);
        tsPos_2.add(tick, pos_2_current_tick);
       
        logger.trace("Price_1_{}: {}", tick, tsPrice_1.get(tick));
        logger.trace("Price_2_{}: {}", tick, tsPrice_2.get(tick));
        logger.trace("Spread_{}: {}", tick, tsSpread.get(tick));
        logger.trace("Pos_1_{}: {}", tick, tsPos_1.get(tick));
        logger.trace("Pos_2_{}: {}", tick, tsPos_2.get(tick));

        
        /**
         * Shift ma_t to ma_t_minus_1
         */
        maShort_t_1 = maShort_t;
        maLong_t_1 = maLong_t;
        maVariance_t_1 = maVariance_t;
    } 
    
    
    /**
     * Compute the new general moving average (MA) of prices at time t.
     * The length of the MA interval is equal to maTicks.
     * 
     * There need to be maTicks prices in the time series, otherwise the
     * method throws an error.   
     * 
     * @param maTicks the size of the MA window
     * @param ma_t_minus_1 the last MA value
     * @return the new MA value
     */
    public double incrementalMA(DoubleTimeSeries dts, int maTicks, double ma_t_minus_1) {
        // TODO put the MA function into a time series utilities package
        // TODO The implicit check of when to do the full vs the incremental MA computation is a bad idea (e.g. when starting off with a dts longer than the MA window). Create two methods and handle the decision outside.
        
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

    
    
}