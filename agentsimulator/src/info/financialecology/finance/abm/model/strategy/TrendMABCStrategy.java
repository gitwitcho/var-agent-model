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
import java.util.HashSet;

import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.PositionUpdateValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.VariabilityCapFactorValue;
import info.financialecology.finance.abm.model.util.TradingPortfolio;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.WorldClock;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.statistics.StatsTimeSeries;

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

public class TrendMABCStrategy implements TradingStrategy {

    // Logging information and errors
    private static Logger logger = LoggerFactory.getLogger(TrendMABCStrategy.class);
//    private TrendValueAbmSimulator simulator;
    
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
    private int previousTick  = -1; // flag to ensure trade() is called at every tick
    private double capFactor;       // multiplier for size of investment 
    
    private double warmUpPeriod;    // the warm-up period needed for this trading strategy, in ticks
//    private int normPeriod;       // DEPRECATED - window of input data for automatically normalising the orders of VALUE and TREND traders
    
    /**
     * At time t, values for prices and positions available up to time t
     */
    private double maShort_previous_tick    = 0;        // given: short-run (fast) moving average at t-1
    private double maLong_previous_tick     = 0;        // given: long-run (slow) moving average at t-1
    private double maShort_current_tick     = 0;        // compute: short-run moving average at t
    private double maLong_current_tick      = 0;        // compute: long-run moving average at t
    private Boolean forceFullMACalc         = false;    // enforces a full moving average calculation if no trade was made at the previous time step
    
    private boolean firstMAShortCalculation = true;     // the first calculation needs to use the full MA method, after that incremental
    private boolean firstMALongCalculation  = true;
    private boolean isSlopeDefined  = false;            // to calculate the slope of the MA, we need to wait for the second MA calculation

    private DoubleTimeSeries tsPrice;       // time series of prices - an input to TrendMABC
//    private DoubleTimeSeries tsPos;         // time series of positions - an output of TrendMABC
    
    private int volWindowStrat;             // window for the calculation of volatility    
    
    private MultiplierTrend multiplier;            // method to calculate the size of the position
    private PositionUpdateTrend positionUpdate;    // specifies if a position can be modified while open
    private OrderOrPositionStrategyTrend orderOrPositionStrategy;   // specifies if the strategy is order-based or position-based
    private VariabilityCapFactorTrend variabilityCapFactor;         // specifies if the capFactor is constant or varies based on the agent performance
    private ShortSellingTrend shortSelling;             // specifies if short-selling is allowed
    
    public enum MultiplierTrend {    // Method to calculate the size of the position
        CONSTANT,                    // the size of the position is equal to the capital factor capFactor
        FAST_MA_SLOPE,               // the size of the position is proportional to the slope of the short (fast) MA
        MA_SLOPE_DIFFERENCE,         // the size of the position is proportional to the difference of the long and short (slow and fast) MAs
        MA_SLOPE_DIFFERENCE_STDDEV,  // the size of the position is proportional to the difference of the long and short (slow and fast) MAs
                                     // and inversely proportional to the standard deviation of prices
        STDDEV;                      // the size of the position is inversely proportional to the standard deviation of prices    
    }
    
    public enum PositionUpdateTrend {  // Specifies if a position can be modified while open
        CONSTANT,                      // the position is kept constant while it is open
        VARIABLE;                      // the position is modified at each time step while it is open    
    }
    
    public enum OrderOrPositionStrategyTrend {  // Specifies if the strategy is order-based or position-based
        ORDER,                                  // the ORDER is proportional to the TREND indicator
        POSITION;                               // the POSITION is proportional to the TREND indicator    
    }
    
    public enum VariabilityCapFactorTrend {    // Specifies if the capFactor is constant or varies based on the agent performance
        CONSTANT,                              // the capFactor is constant
        VARIABLE;                              // the capFactor is variable and proportional to the variation in wealth    
    }
    
    public enum ShortSellingTrend {    // Specifies if short-selling is allowed
        ALLOWED,                       // Short positions are allowed
        NOT_ALLOWED;                   // Short positions are prohibited    
    }
    
    private Order order;                    // the order of the share 
    private HashSet<String> secIds;         // the security identifier
    
    private double automaticNormFactor    = 1.0;  // the (automatically calculated) factor to normalise the orders of VALUE and TREND traders 
    private double manualNormFactor = 1.0;  // the (manually calculated) factor to normalise the orders of VALUE and TREND traders
        
    // Constructor
    public TrendMABCStrategy(String secId,
                             int maShortTicks, 
                             int maLongTicks, 
                             int bcTicks, 
                             double capFactor, 
                             DoubleTimeSeries tsPrice,
                             int volWindowStrat,         // TODO tsPrice should 'live' in a market class, where also volatility should be calculated
                             MultiplierTrend multiplier,
                             PositionUpdateTrend positionUpdate,
                             OrderOrPositionStrategyTrend orderOrPositionStrategy,
                             VariabilityCapFactorTrend variabilityCapFactor,
                             ShortSellingTrend shortSelling) {
        
        Assertion.assertStrict((secId != null) && (secId.compareTo("") != 0), Level.ERR, "secId cannot be null or an empty string");
        Assertion.assertStrict(maShortTicks < maLongTicks, Level.ERR, "maLong = " + maLongTicks + " has to be " +
                "strictly greater than maShort = " + maShortTicks);
        Assertion.assertStrict((maShortTicks > 0) && (maLongTicks > 0) && (bcTicks > 0), Level.ERR, "maShort, maLong, " +
        		"and bcTicks have to be greater than '0'");
        Assertion.assertStrict(tsPrice != null, Level.ERR, "Price timeseries cannot be null");
        
        if ((multiplier == MultiplierTrend.MA_SLOPE_DIFFERENCE_STDDEV) || (multiplier == MultiplierTrend.STDDEV)) 
            Assertion.assertStrict(volWindowStrat > 0, Level.ERR, "volWindow has to be greater than '0'");
        
        this.maShortTicks = maShortTicks;
        this.maLongTicks = maLongTicks;
        this.bcTicks = bcTicks;
        this.capFactor = capFactor;
        this.tsPrice = tsPrice;
        this.volWindowStrat = volWindowStrat;
        this.multiplier = multiplier;
        this.positionUpdate = positionUpdate;
        this.orderOrPositionStrategy = orderOrPositionStrategy;
        this.variabilityCapFactor = variabilityCapFactor;
        this.shortSelling = shortSelling;
//        this.normPeriod = normPeriod;   // DEPRECATED - normPeriod is no longer used
        
//        this.tsPos = new DoubleTimeSeries();

        this.order = new Order();   // this needs to hold several orders; one order object for each order, incl. if secId is the same
        this.order.setSecId(secId);
        this.secIds = new HashSet<String>();
        this.secIds.add(secId);
        
        if ((multiplier == MultiplierTrend.MA_SLOPE_DIFFERENCE_STDDEV) || (multiplier == MultiplierTrend.STDDEV)) {   // TODO no need to compare with maShortTicks
        	this.warmUpPeriod = Math.max(volWindowStrat, Math.max(maLongTicks, Math.max(maShortTicks, bcTicks)));
        }
        else {
        	this.warmUpPeriod = Math.max(maLongTicks, Math.max(maShortTicks, bcTicks));    // TODO idem
        }
    }
    
    
    /**
     * The warm-up period is equal to the number of ticks where no prices can be calculated since 
     * because of a lack of data points, moving averages and volatilities cannot be computed
     * 
     * @return the warmUpPeriod, in ticks
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
        
        return secIds;
    }
    
    /**
     * Get the unique identifier of this strategy. In the single asset case this is equal to secId
     */
    public String getUniqueId() {
        return order.getSecId();
    }
    
    /**
     * Get the maShortTicks used by the strategy
     */
    public int getMaShortTicks() {
        return maShortTicks;
    }
    
    /**
     * Get the maLongTicks used by the strategy
     */
    public int getMaLongTicks() {
        return maLongTicks;
    }
    
    /**
     * Get the bcTicks used by the strategy
     */
    public int getBcTicks() {
        return bcTicks;
    }


    /**
     * Compute the position and order for the current trade. If there was no trade placed at the
     * previous tick, then force a full moving average calculation. Otherwise use the more efficient
     * {@code incrementalMA(...)} algorithm
     *     
     */
    public void trade(TradingPortfolio portfolio) {
        
        int tick = WorldClock.currentTick();
        
        String secId = order.getSecId();
        DoubleTimeSeries tsPos = portfolio.getTsPosition(secId);
        
        if (tick == previousTick + 1) { // incremental MA or full MA?
            previousTick = tick;
            forceFullMACalc = false;
        }
        else {
            Assertion.assertStrict(false, Level.INFO, "The method trade() in the class TrendMABCStrategy " +
            		"has not been called at the previous tick t=" + previousTick + ", so that the full MA" +
            	    "calculation will be used to compute the new position");
            forceFullMACalc = true;
        }
        
        if (tick < warmUpPeriod) {  // no positions and orders are calculated during warm-up 
            tsPos.add(tick, 0.0);
            return;
        }
        
        
        /*
         * Compute the new moving averages at the current tick. If they are computed for the first time, 
         * use the full MA computation. Otherwise, use the incremental computation.
         * 
         * This requires for now that trade() is called at every tick, which may 
         * not be feasible. See TODO comment above
         * 
         */
        if (firstMAShortCalculation) {
            maShort_current_tick = StatsTimeSeries.fullMA(tsPrice, maShortTicks);
            firstMAShortCalculation = false;
        }
        else {
            if (forceFullMACalc)
                maShort_current_tick = StatsTimeSeries.fullMA(tsPrice, maShortTicks);
            else
                maShort_current_tick = StatsTimeSeries.incrementalMA(tsPrice, maShortTicks, maShort_previous_tick);            
        }
        
        if (firstMALongCalculation) {
            maLong_current_tick = StatsTimeSeries.fullMA(tsPrice, maLongTicks);
            firstMALongCalculation = false;
        }
        else {
            if (forceFullMACalc)
                maLong_current_tick = StatsTimeSeries.fullMA(tsPrice, maLongTicks);
            else
                maLong_current_tick = StatsTimeSeries.incrementalMA(tsPrice, maLongTicks, maLong_previous_tick);
        }
        
 
        /*
         *  Selecting the multiplier for the position calculation 
         */
        double position = 0;
        
        if (multiplier == MultiplierTrend.CONSTANT) {
            position = capFactor;
            manualNormFactor = 12;
        }
        else if (multiplier == MultiplierTrend.FAST_MA_SLOPE) {  // Computing slope short MA

            if (isSlopeDefined) {   // slope is defined only if more than one MA value is given 
                double slopeShort_t = Math.atan(maShort_current_tick - maShort_previous_tick);
                position = capFactor * Math.abs(slopeShort_t);
                manualNormFactor = 16;
            }
            else {  // only one MA value is given at this stage
                position = 0;
                isSlopeDefined = true;  // MA slope is defined in next step
            }
        }
        else if (multiplier == MultiplierTrend.MA_SLOPE_DIFFERENCE) {    // Computing slope difference for fast vs slow MA
            
            if (isSlopeDefined) {   // slope is defined only if more than one MA value is given 
                double slopeShort_t = Math.atan(maShort_current_tick - maShort_previous_tick); 
                double slopeLong_t = Math.atan(maLong_current_tick - maLong_previous_tick);
                double deltaSlope_t = slopeShort_t - slopeLong_t;
                
                position = capFactor * Math.abs(deltaSlope_t);
//                manualNormFactor = 16;
                manualNormFactor = 25;
            }
            else {  // only one MA value is given at this stage
                position = 0;
                isSlopeDefined = true;  // MA slope is defined in next step
            }
            
        }
        else if (multiplier == MultiplierTrend.MA_SLOPE_DIFFERENCE_STDDEV) {     // Computing slope difference for fast vs slow MA

            if (isSlopeDefined) {   // slope is defined only if more than one MA value is given 
                double slopeShort_t = Math.atan(maShort_current_tick - maShort_previous_tick); 
                double slopeLong_t = Math.atan(maLong_current_tick - maLong_previous_tick);
                double deltaSlope_t = slopeShort_t - slopeLong_t;
                double stdDevPrices_t = StatsTimeSeries.stdDev(tsPrice, volWindowStrat);   // Computing the standard deviation of prices
                																		   // TODO: stdDev should be calculated using the incrementalVariance() method
                
                position = capFactor * Math.abs(deltaSlope_t) / stdDevPrices_t;
                manualNormFactor = 25;
            }
            else {  // only one MA value is given at this stage
                position = 0;
                isSlopeDefined = true;  // MA slope is defined in next step
            }
        }
        else if (multiplier == MultiplierTrend.STDDEV) {     // Computing the standard deviation of prices
            
            double stdDevPrices_t = StatsTimeSeries.stdDev(tsPrice, volWindowStrat);   // TODO: stdDev should be calculated using the incrementalVariance() method
             
            position = capFactor / stdDevPrices_t;     // TODO this needs to be normalised and calibrated properly
            manualNormFactor = 8;
        }
        else
            Assertion.assertStrict(false, Level.ERR, "The method for multiplier " + 
                    multiplier + " is not implemented");
        
        /*
         * Factor to update capFactor IF this varies based on performance 
         */
        double wealthFactor = 1;        
        if (variabilityCapFactor == VariabilityCapFactorTrend.VARIABLE) {
	        double deltaWealth = StatsTimeSeries.deltaWealth(tsPrice, tsPos).get(tick-1);
	        if (deltaWealth > 1) {
	        	wealthFactor = 1 + Math.log(deltaWealth);
	        }
	        if (deltaWealth < 0) {
	        	wealthFactor = Math.exp(deltaWealth);
	        }
        }   
        
//        position = position * automaticNormFactor * wealthFactor;    // Normalise the positions so that TREND and FUND orders have the same order of magnitude
        position = position * manualNormFactor * wealthFactor;
        
                 
        /**
         *    - Entry condition for long position
         *    - Entry condition for short position
         *    - Exit condition for long and short position
         */
        
        
//        // ---- TEST: If the volatility is above a given threshold, the TREND trader does nothing  ----- //
//        
//        // Calculate volatility -->  TODO: needs to be extracted from the market
//        
//        int volWindowVar = 45;  // Needs to be extracted from the parameter file 
//        DoubleTimeSeries tsLastReturns = new DoubleTimeSeries();   // Will allocate the values of log-returns in the chosen window
//        double volatility;
//
//        if (tick <= volWindowVar) {
//        	volatility = 0;
//    	}
//    	
//        else {
//    	    for (int i = tsPrice.size()-volWindowVar; i < tsPrice.size(); i++) {
//                tsLastReturns.add(Math.log(tsPrice.get(i)) - Math.log(tsPrice.get(i-1)));
//    	    }
//    	    volatility = tsLastReturns.stdev();
//        }
//        
//        if (volatility >= 0.003) {  // If the volatility is too high, the TREND agent simply keeps the same position
//        	tsPos.add(tick, tsPos.get(tick-1));
//        }
//        
//        // ------------------------------------------------------------------------------- //
        
        
        if ((maShort_previous_tick < maLong_previous_tick) && (maShort_current_tick >= maLong_current_tick) && (tsPos.get(tick - 1) == 0.0)) {
//        else if ((maShort_previous_tick < maLong_previous_tick) && (maShort_current_tick >= maLong_current_tick) && (tsPos.get(tick - 1) == 0.0)) {
            tsPos.add(tick, position);
            lastEntryTick = tick;
        }
        else if ((shortSelling == ShortSellingTrend.ALLOWED) && (maShort_previous_tick > maLong_previous_tick) && (maShort_current_tick <= maLong_current_tick) && (tsPos.get(tick - 1) == 0.0)) {
            tsPos.add(tick, - position);
            lastEntryTick = tick;
        }
        else if ((tsPos.get(tick - 1) != 0) && (lastEntryTick != -1)) {
            if (lastEntryTick <= tick - bcTicks) {  // last entry, or order, needs to lie outside of bcTicks window
            	
                double maExitMax = maxValue(tsPrice, bcTicks); 
                double maExitMin = minValue(tsPrice, bcTicks);
                
                if (((tsPrice.get(tick) <= maExitMin) && (tsPos.get(tick - 1) > 0)) ||
                    ((tsPrice.get(tick) >= maExitMax) && (tsPos.get(tick - 1) < 0)))
                    tsPos.add(tick, 0.0);
                else { 
                    if (positionUpdate == PositionUpdateTrend.CONSTANT)
                    	tsPos.add(tick, tsPos.get(tsPos.size() - 1));   // no change in the position
                    else if (positionUpdate == PositionUpdateTrend.VARIABLE) {    // position is modified while open
                    	if (orderOrPositionStrategy == OrderOrPositionStrategyTrend.POSITION)
                    	    tsPos.add(tick, Math.abs(position) * Math.signum(tsPos.get(tick - 1)));   // the new position is proportional to the indicator
                    	else if (orderOrPositionStrategy == OrderOrPositionStrategyTrend.ORDER)
                            tsPos.add(tick, tsPos.get(tick - 1) + Math.abs(position) * Math.signum(tsPos.get(tick - 1)));   // the new order is proportional to the indicator
                    	else 
                    		Assertion.assertStrict(false, Level.ERR, "The method for orderOrPositionStrategy " + 
                                orderOrPositionStrategy + " is not implemented");
                    }
                    else 
                    	Assertion.assertStrict(false, Level.ERR, "The method for positionUpdate " + 
                                positionUpdate + " is not implemented");
                }
            }
            else { 
                if (positionUpdate == PositionUpdateTrend.CONSTANT)
                	tsPos.add(tick, tsPos.get(tsPos.size() - 1));   // no change in the position
                else if (positionUpdate == PositionUpdateTrend.VARIABLE) {  // position is modified while open
                	if (orderOrPositionStrategy == OrderOrPositionStrategyTrend.POSITION)
                	    tsPos.add(tick, Math.abs(position) * Math.signum(tsPos.get(tick - 1)));  // the new position is proportional to the indicator
                	else if (orderOrPositionStrategy == OrderOrPositionStrategyTrend.ORDER)
                	    tsPos.add(tick, tsPos.get(tick - 1) + Math.abs(position) * Math.signum(tsPos.get(tick - 1)));   // the new order is proportional to the indicator
                	else 
                    	Assertion.assertStrict(false, Level.ERR, "The method for orderOrPositionStrategy " + 
                                orderOrPositionStrategy + " is not implemented");
                }
                else 
                	Assertion.assertStrict(false, Level.ERR, "The method for positionUpdate " + 
                            positionUpdate + " is not implemented");
            }
        }
        else
            tsPos.add(tick, tsPos.get(tsPos.size() - 1));   // no change in the position
        
        
        if (tick == 0) {
            order.setOrder(tsPos.get(tick));
        }
        else {            
            order.setOrder(tsPos.get(tick) - tsPos.get(tick - 1));
        }
        
        logger.trace("(MA_short, MA_long) = ({}, {})", maShort_current_tick, maLong_current_tick);
        logger.trace("Price_{}: {}", tick, tsPrice.get(tick));
        logger.trace("Pos_{}: {}", tick, tsPos.get(tick));
        
        if (tsPos.get(tick-1) != 0 && lastEntryTick <= tick - bcTicks) {
        	logger.trace("(MIN, MAX) = ({}, {})", minValue(tsPrice, bcTicks), maxValue(tsPrice, bcTicks));
        }
        
        // Shift ma_t to ma_t_minus_1
        maShort_previous_tick = maShort_current_tick;
        maLong_previous_tick = maLong_current_tick;
    }    

    
    
    /**
     * Calculates the maximum value of a time series over a given window.
     * @param values Input time series
     * @param window Window over which the maximum value is calculated
     * @return the maximum of the time series over the given window
     */
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
    
//    /**
//     * Calculates the minimum value of a list of values over a given window.
//     * @param values List of values
//     * @param window Window over which the minimum value is calculated
//     * @return the minimum of the list of values over the given window
//     */
//    public double minValue(DoubleArrayList values, int window) {
//        double value;
//        double minValue = values.get(values.size() - 1);
//        
//        for (int i = 1; i < window; i++) {
//            value = values.get(values.size() - 1 - i);
//            if (minValue > value)
//                minValue = value;
//        }
//        
//        return minValue;
//    }
    
    /**
     * Calculates the minimum value of a time series over a given window.
     * @param values Input time series
     * @param window Window over which the minimum value is calculated
     * @return the minimum of the time series over the given window
     */   
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