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
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.WorldClock;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.statistics.StatsTimeSeries;
import info.financialecology.finance.abm.model.util.TradingPortfolio;

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
 * mean +- 3 stdev). The position is kept constant until the exit criterion is satisfied.
 * 
 * This class implements the same strategy tested in the Excel spreadsheet 
 * "Simple trading strategy simulator - LS.xlsm" (tab "Heur2-En3-Ex1-Ratio (IND)")
 * in folder "\Dropbox\Modelling journeys\Long-short incident of August 2007\Chunks\Active\C2.1 - Long-short (LS) exploratory evaluation"
 * 
 * @author Barbara Llacay
 */
public class LSMABCStrategy_Excel implements TradingStrategy {

    // Logging information and errors
    private static Logger logger = LoggerFactory.getLogger(LSMABCStrategy_Excel.class);
    
//  /*
//  *  Parameters
//  *    - percWindow: window for the calculation of percentiles (used in the entry threshold)
//  *    - capFactor: multiplier for size of investment
//  */
    private int percWindow = 200;             // window for the calculation of percentiles
    private double capFactor = 1;             // multiplier for size of investment 
    
    private double warmUpPeriod;              // the warm-up period needed for this trading strategy, in ticks    
    
    /*
     * At time t, values for prices and positions available only up to time t-1
     */
    private DoubleTimeSeries tsPrice_1;       // time series of prices which constitute the spread - an input to LSMABC
    private DoubleTimeSeries tsPrice_2;       
//    private DoubleTimeSeries tsPos_1;         // time series of positions in the two assets which constitute the spread - an output of LSMABC
//    private DoubleTimeSeries tsPos_2;
    private DoubleTimeSeries tsAbsOrder_1;    // time series of absolute value of orders
    private DoubleTimeSeries tsAbsOrder_2;
    private DoubleTimeSeries tsOrder_1;       // time series of orders (with sign)
    private DoubleTimeSeries tsOrder_2;
    
    private Order order_1;                    // the order of the two shares which constitute the spread
    private Order order_2;
    private HashSet<String> secIds;           // the security identifier

    int nCrossPerc95 = 0;     // counter for the number of times that the percentile 95 of spread has been crossed since last position
    int nCrossPerc5 = 0;      // counter for the number of times that the percentile 5 of spread has been crossed since last position

//    /** Constructor
//    * 
//    * @param secId_1
//    * @param tsPrice_1
//    * @param secId_2
//    * @param tsPrice_2
//    * @param percWindow
//    * @param capFactor
//    */
    
    public LSMABCStrategy_Excel(String secId_1, 
    						DoubleTimeSeries tsPrice_1,
    						String secId_2,
    						DoubleTimeSeries tsPrice_2,
    						int percWindow,    						
    						double capFactor) {
    
        Assertion.assertStrict((secId_1 != null) && (secId_1.compareTo("") != 0), Level.ERR, "secId_1 cannot be null or an empty string");
        Assertion.assertStrict((secId_2 != null) && (secId_2.compareTo("") != 0), Level.ERR, "secId_2 cannot be null or an empty string");
        Assertion.assertStrict(percWindow > 0, Level.ERR, "percWindow has to be greater than '0'");
        Assertion.assertStrict((tsPrice_1 != null) && (tsPrice_2 != null), Level.ERR, "Price timeseries cannot be null");

    	this.tsPrice_1 = tsPrice_1;
    	this.tsPrice_2 = tsPrice_2;
        this.percWindow = percWindow;
        this.capFactor = capFactor;
    	
//        this.tsPos_1 = new DoubleTimeSeries();
//        this.tsPos_2 = new DoubleTimeSeries();
        this.tsAbsOrder_1 = new DoubleTimeSeries();
        this.tsAbsOrder_2 = new DoubleTimeSeries();
        this.tsOrder_1 = new DoubleTimeSeries();
        this.tsOrder_2 = new DoubleTimeSeries();
        
        this.order_1 = new Order();   // this needs to hold several orders; one order object for each order, incl. if secId is the same
        this.order_2 = new Order();
        this.order_1.setSecId(secId_1);
        this.order_2.setSecId(secId_2);

        this.secIds = new HashSet<String>();
        this.secIds.add(secId_1);
        this.secIds.add(secId_2);
        
        this.warmUpPeriod = percWindow;
    }
    
    /**
     * @return the tsAbsOrder_1 (absolute orders in the first share which makes part of the pair)
     */
    public DoubleTimeSeries getTsAbsOrder_1() {
        return tsAbsOrder_1;
    }
    
    /**
     * @return the tsAbsOrder_2 (absolute orders in the second share which makes part of the pair)
     */
    public DoubleTimeSeries getTsAbsOrder_2() {
        return tsAbsOrder_2;
    }
    
    /**
     * @return the tsOrder_1 (orders in the first share which makes part of the pair)
     */
    public DoubleTimeSeries getTsOrder_1() {
        return tsOrder_1;
    }
    
    /**
     * @return the tsOrder_2 (orders in the second share which makes part of the pair)
     */
    public DoubleTimeSeries getTsOrder_2() {
        return tsOrder_2;
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
        DoubleTimeSeries tsSpread = substraction(tsPrice_1, tsPrice_2);  // spread = Price_1 - Price_2
        
        String secId_1 = order_1.getSecId();
        String secId_2 = order_2.getSecId();
        DoubleTimeSeries tsPos_1 = portfolio.getTsPosition(secId_1);
        DoubleTimeSeries tsPos_2 = portfolio.getTsPosition(secId_2);
 
        if (tick < warmUpPeriod) {    // no positions and orders are calculated during warm-up 
            tsPos_1.add(tick, 0.0);
            tsPos_2.add(tick, 0.0);
            tsAbsOrder_1.add(tick, 0.0);
            tsAbsOrder_2.add(tick, 0.0);
            tsOrder_1.add(tick, 0.0);
            tsOrder_2.add(tick, 0.0);
            return;
        }
        
        
        /**
         * ENTRY condition
         * - Calculate the number of crossings of the 95 or 5 percentiles since the last position was closed.
         * - Open a position when the number of crossings is 2 (the spread is then expected to be reversing to
         *   its historical mean value).
         */
        
        double spread_t = tsSpread.get(tick);
        double spread_t_1 = tsSpread.get(tick-1);
        
        double perc95 = tsSpread.percentile(95, percWindow);
        double perc5 = tsSpread.percentile(5, percWindow);
        
        double stdDevSpread_t = StatsTimeSeries.stdDev(tsSpread, percWindow);
        double meanSpread_t = StatsTimeSeries.mean(tsSpread, percWindow);
        
        // Count the crossings of perc95 since last position
        
        if (tsPos_2.get(tick - 1) != 0.0) {  // A position is already open in this spread 
        	                                 // !! This condition assumes that all spreads are defined as Price_0 - Price_i, so they differ in the second asset
        	nCrossPerc95 = 0;
        }
        else {
        	if ((spread_t_1 < perc95) && (spread_t >= perc95))
        		nCrossPerc95 = 1;
        	else if ((nCrossPerc95 == 1) && (spread_t_1 > perc95) && (spread_t <= perc95))
        		nCrossPerc95 = 2;
        }
        
        // Count the crossings of perc5 since last position
        
        if (tsPos_2.get(tick - 1) != 0.0) {  // A position is already open in this spread 
        	                                 // !! This condition assumes that all spreads are defined as Price_0 - Price_i, so they differ in the second asset
        	nCrossPerc5 = 0;
        }
        else {
        	if ((spread_t_1 > perc5) && (spread_t <= perc5))
        		nCrossPerc5 = 1;
        	else if ((nCrossPerc5 == 1) && (spread_t_1 < perc5) && (spread_t >= perc5))
        		nCrossPerc5 = 2;
        }
        
        // Open a position when the percentile is crossed for the second time
        
        double position = capFactor * Math.abs(spread_t - meanSpread_t) / stdDevSpread_t;
        
        if (nCrossPerc95 == 2) {
        	tsPos_1.add(tick, -position);
        	tsPos_2.add(tick, position * tsPrice_1.get(tick) / tsPrice_2.get(tick));  // Position adjusted with price ratio to have the same dollar value
        }
        else if (nCrossPerc5 == 2) {
        	tsPos_1.add(tick, position);
        	tsPos_2.add(tick, -position * tsPrice_1.get(tick) / tsPrice_2.get(tick));  // Position adjusted with price ratio to have the same dollar value
        }
        else {
        	tsPos_1.add(tick, tsPos_1.get(tick-1));
        	tsPos_2.add(tick, tsPos_2.get(tick-1));
        }
        
        
        /**
         * EXIT condition
         * - Close a position when the spread has converged to [mean +- 0.5 std]
         * - Close a position when the spread has diverged beyond [mean +- 3 std]
         */
        
        if (tsPos_2.get(tick - 1) > 0) {   // A position is already opened in the spread due to the double-crossing of Perc95 
        	if ((spread_t < meanSpread_t + 0.5*stdDevSpread_t) || (spread_t > meanSpread_t + 3*stdDevSpread_t)) {  // The spread has converged or diverged too much
        		tsPos_1.add(tick, 0);
        		tsPos_2.add(tick, 0);
        	}
        }
        	
        if (tsPos_2.get(tick - 1) < 0) {   // A position is already opened in the spread due to the double-crossing of Perc5
        	if ((spread_t > meanSpread_t - 0.5*stdDevSpread_t) || (spread_t < meanSpread_t - 3*stdDevSpread_t)) {  // The spread has converged or diverged too much
        		tsPos_1.add(tick, 0);
        		tsPos_2.add(tick, 0);
        	}
        }
        
        
        /**
         * Compute the order and absolute order
         */

        if (tick == 0) {    // TODO this is never reached since when tick = 0, you exit the method in a previous conditional above
            order_1.setOrder(tsPos_1.get(tick));
            order_2.setOrder(tsPos_2.get(tick));
        }
        else {
            order_1.setOrder(tsPos_1.get(tick) - tsPos_1.get(tick - 1));
            order_2.setOrder(tsPos_2.get(tick) - tsPos_2.get(tick - 1));
            tsAbsOrder_1.add(tick, Math.abs(tsPos_1.get(tick) - tsPos_1.get(tick - 1)));
            tsAbsOrder_2.add(tick, Math.abs(tsPos_2.get(tick) - tsPos_2.get(tick - 1)));
            tsOrder_1.add(tick, tsPos_1.get(tick) - tsPos_1.get(tick - 1));
            tsOrder_2.add(tick, tsPos_2.get(tick) - tsPos_2.get(tick - 1));
        }
       
        logger.trace("Price_1_{}: {}", tick, tsPrice_1.get(tick));
        logger.trace("Price_2_{}: {}", tick, tsPrice_2.get(tick));
        logger.trace("Spread_{}: {}", tick, tsSpread.get(tick));
        logger.trace("Pos_1_{}: {}", tick, tsPos_1.get(tick));
        logger.trace("Pos_2_{}: {}", tick, tsPos_2.get(tick));
    }
    
    
    
    /**
     * Calculates the difference between two time series (minuend - subtrahend).
     * @param tsMinuend The first time series in the substraction
     * @param tsSubtrahend The time series to be substracted
     * @return the difference of the two time series, minuend - subtrahend
     */
    public DoubleTimeSeries substraction(DoubleTimeSeries tsMinuend, DoubleTimeSeries tsSubtrahend) {
        
        Assertion.assertOrKill(tsMinuend.size() == tsSubtrahend.size(), "Method substraction() requires the two time series to be the same size");
        
        DoubleTimeSeries tsSubstraction = new DoubleTimeSeries();
        
        for (int t = 0; t < tsMinuend.size(); t++)
            tsSubstraction.add(t, tsMinuend.get(t) - tsSubtrahend.get(t));
        
        return tsSubstraction;
    }


}