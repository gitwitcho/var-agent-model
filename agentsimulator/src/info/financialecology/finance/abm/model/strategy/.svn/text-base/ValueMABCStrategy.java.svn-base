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

import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.WorldClock;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.statistics.StatsTimeSeries;
import info.financialecology.finance.abm.model.util.TradingPortfolio;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * A class that implements a (single asset) fundamental strategy inspired in the fundamental strategy 
 * presented by Farmer and Joshi in their article "The price dynamics of common trading strategies" (2002).
 * 
 * A position is entered when the difference between the fundamental value and the price exceeds an 
 * entry threshold. The position is kept constant until the exit criterion is satisfied: a position 
 * is closed when the difference between the fundamental value and the price lies below an exit threshold.
 * 
 * @author Barbara Llacay
 */
public class ValueMABCStrategy implements TradingStrategy {

    // Logging information and errors
    private static Logger logger = LoggerFactory.getLogger(ValueMABCStrategy.class);
    
    /*
     *  Parameters
     *    - entryThreshold: threshold for the difference between fund value and price to enter a position
     *    - exitThreshold: threshold for the difference between fund value and price to exit a position
     *    - valueOffset: offset added to the value reference process - different for each trader
     *    - capFactor: multiplier for size of investment
     *    - lastEntryTick: tick at which the last order was placed
     *    - previousTick: flag to ensure trade() is called at every tick
     */
    private double entryThreshold;    // threshold for the difference between fund value and price to enter a position
    private double exitThreshold;     // threshold for the difference between fund value and price to exit a position
    private double valueOffset;       // offset added to the value reference process - different for each trader
    private double capFactor;         // multiplier for size of investment
        
    private int bcTicks;              // exit channel: size of window during which a position cannot be closed 
    private int lastEntryTick = -1;   // tick at which last order was placed - default '-1' indicates there are no previous orders
    private PositionUpdateValue positionUpdate;    // specifies if a position can be modified while open
    private OrderOrPositionStrategyValue orderOrPositionStrategy;   // specifies if the strategy is order-based or position-based
    private VariabilityCapFactorValue variabilityCapFactor;         // specifies if the capFactor is constant or varies based on the agent performance
    private ShortSellingValue shortSelling;        // specifies if short-selling is allowed
    
    public enum PositionUpdateValue {   // Method to calculate the size of the position
        CONSTANT,                       // the position is kept constant while it is open
        VARIABLE;                       // the position is modified at each time step while it is open    
    }
    
    public enum OrderOrPositionStrategyValue {  // Specifies if the strategy is order-based or position-based
        ORDER,                                  // the ORDER is proportional to the FUND indicator
        POSITION;                               // the POSITION is proportional to the FUND indicator    
    }
    
    public enum VariabilityCapFactorValue {    // Specifies if the capFactor is constant or varies based on the agent performance
        CONSTANT,                              // the capFactor is constant
        VARIABLE;                              // the capFactor is variable and proportional to the variation in wealth    
    }
    
    public enum ShortSellingValue {    // Specifies if short-selling is allowed
        ALLOWED,                       // Short positions are allowed
        NOT_ALLOWED;                   // Short positions are prohibited    
    }

    
    /*
     * At time t, values for prices and positions available only up to time t-1
     */
    private DoubleTimeSeries tsPrice;       // time series of prices - an input to ValueMABC
    private DoubleTimeSeries tsFundValue;   // time series of generic fundamental values - an input to ValueMABC
//    private DoubleTimeSeries tsPos;         // time series of positions - an output of ValueMABC
    
    private Order order;   // the order of the shares
    private HashSet<String> secIds;          // the security identifier

    /** Constructor
     * 
     * @param secId
     * @param entryThreshold
     * @param exitThreshold
     * @param valueOffset
     * @param bcTicks
     * @param capFactor
     * @param tsPrice
     * @param tsFundValue
     * @param positionUpdate
     * @param orderOrPositionStrategy
     * @param variabilityCapFactor
     * @param shortSelling
     */
    public ValueMABCStrategy(String secId,
                             double entryThreshold, 
                             double exitThreshold, 
                             double valueOffset, 
                             int bcTicks,
                             double capFactor, 
                             DoubleTimeSeries tsPrice,       // TODO tsPrice should 'live' in a market class, where also volatility should be calculated
                             DoubleTimeSeries tsFundValue,
                             PositionUpdateValue positionUpdate,
                             OrderOrPositionStrategyValue orderOrPositionStrategy,
                             VariabilityCapFactorValue variabilityCapFactor,
                             ShortSellingValue shortSelling) {
        
        Assertion.assertStrict((secId != null) && (secId.compareTo("") != 0), Level.ERR, "secId cannot be null or an empty string");
        Assertion.assertStrict(exitThreshold < entryThreshold, Level.ERR, "entryThreshold = " + entryThreshold + " has to be " +
                "strictly greater than exitThreshold = " + exitThreshold);
        Assertion.assertStrict((entryThreshold > 0), Level.ERR, "entryThreshold has to be greater than '0'");
//        Assertion.assertStrict((exitThreshold > 0), Level.ERR, "exitThreshold has to be greater than '0'");
        Assertion.assertStrict(tsPrice != null, Level.ERR, "Price timeseries cannot be null");
        Assertion.assertStrict(tsFundValue != null, Level.ERR, "Value timeseries cannot be null");
        
        this.entryThreshold = entryThreshold;
        this.exitThreshold = exitThreshold;
        this.valueOffset = valueOffset;
        this.bcTicks = bcTicks;
        this.capFactor = capFactor;
        this.tsPrice = tsPrice;
        this.tsFundValue = tsFundValue;
        this.positionUpdate = positionUpdate;
        this.orderOrPositionStrategy = orderOrPositionStrategy;
        this.variabilityCapFactor = variabilityCapFactor;
        this.shortSelling = shortSelling;
        
//        this.tsPos = new DoubleTimeSeries();
        
        this.order = new Order();   // this needs to hold several orders; one order object for each order, incl. if secId is the same
        this.order.setSecId(secId);
        this.secIds = new HashSet<String>();
        this.secIds.add(secId);
    }

   
    /**
     * Get the current order for the security
     */
    public ArrayList<Order> getOrders() {
        
        ArrayList<Order> orders = new ArrayList<Order>();
        
        if (order != null)  // if the position didn't change, the order was set to null; add no order object to the array list
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
     * Get a unique identifier for the trading strategy. In the single share case this is equal to the secId string.
     * 
     * @param 
     */
    public String getUniqueId() {
        return order.getSecId();
    }
    
    
    /**
     * Get the entryThreshold used by the strategy
     */
    public double getEntryThreshold() {
        return entryThreshold;
    }
    
    
    /**
     * Get the exitThreshold used by the strategy
     */
    public double getExitThreshold() {
        return exitThreshold;
    }
    
    
    /**
     * Get the valueOffset used by the strategy
     */
    public double getValueOffset() {
        return valueOffset;
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
        
        /*
         *    - Entry condition for long position
         *    - Entry condition for short position
         *    - Exit condition for long and short position
         */        
        double position = 0;
        double ownValue_t = tsFundValue.get(tick) + valueOffset;
        double price_t = tsPrice.get(tick);
        
       
        // Set which FUNDs are informed and so receive first the shock to fundamental value
        // The rest of FUNDs receive the shock with delay
        
        int numInformed = 10;
        int numFunds = 50;
        
//        for (int va = 0; va < numInformed; va++) {  // Shock in value perceived by informed FUNDs (used in the mini-cascade simulations)
//        	if (portfolio.getTraderId().equals("Value_" + va) && tick >= 1000) 
//            		ownValue_t = ownValue_t - 30;
//        }

//        for (int va = numInformed; va < numFunds; va++) {  // Shock in value perceived by stupid FUNDs (used in the mini-cascade simulations)
//        	if (portfolio.getTraderId().equals("Value_" + va) && tick >= 1020) 
//            		ownValue_t = ownValue_t - 30;
//        }
        
        if (tick == 0) {    // positions and orders are set to '0' at the first tick
            tsPos.add(tick, 0.0);
            return;
        }
       
        
//        if (tick == 1) {    // Initial position to avoid jumps when the initial value is modified (used in the mini-cascade simulations)
//            tsPos.add(tick, 30.0);
//            return;
//        }

        
        // Factor to update capFactor IF this varies based on performance
        double wealthFactor = 1;        
        if (variabilityCapFactor == VariabilityCapFactorValue.VARIABLE && tick != 0) {
	        double deltaWealth = StatsTimeSeries.deltaWealth(tsPrice, tsPos).get(tick-1);
	        if (deltaWealth > 1) {
	        	wealthFactor = 1 + Math.log(deltaWealth);
	        }
	        if (deltaWealth < 0) {
	        	wealthFactor = Math.exp(deltaWealth);
	        }
        }
        
        
//        // ---- TEST: If the volatility is above a given threshold, the FUND trader does nothing  ----- //
//        
//        // Calculate volatility -->  TODO: needs to be extracted from the market
//        
//        int volWindowStrat = 45;  // Needs to be extracted from the parameter file 
//        DoubleTimeSeries tsLastReturns = new DoubleTimeSeries();   // Will allocate the values of log-returns in the chosen window
//        double volatility;
//
//        if (tick <= volWindowStrat) {
//        	volatility = 0;
//    	}
//    	
//        else {
//    	    for (int i = tsPrice.size()-volWindowStrat; i < tsPrice.size(); i++) {
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
        
    
        // {position = 0} AND {underpriced/overpriced enough} --> open a long or short position
        if (((ownValue_t - price_t) > entryThreshold) && (tsPos.get(tick - 1) == 0.0)) {        	
//        else if (((ownValue_t - price_t) > entryThreshold) && (tsPos.get(tick - 1) == 0.0)) {
        	position = capFactor * (ownValue_t - price_t) * wealthFactor;   // Long position
        	tsPos.add(tick, position);
        	lastEntryTick = tick;
        }
        else if ((shortSelling == ShortSellingValue.ALLOWED) && ((ownValue_t - price_t) < -entryThreshold) && (tsPos.get(tick - 1) == 0.0)) {
          	position = capFactor * (ownValue_t - price_t) * wealthFactor;   // Short position
          	tsPos.add(tick, position);
          	lastEntryTick = tick;
        }
        // {long position} AND {overpriced enough} AND {waited enough after last trade} --> close long position
        else if ((ownValue_t - price_t < exitThreshold) && (tsPos.get(tick - 1) > 0.0)) {
        	if (lastEntryTick <= tick - bcTicks) {
        		tsPos.add(tick, 0.0);
        	}
        	else {     
        		tsPos.add(tick, tsPos.get(tick - 1));
        	}
        }
        // {long position} AND {overpriced enough} AND {waited enough after last trade} --> close long position
        // Remark: case added to avoid that non-short-selling agents enter a negative position when updating below because 
        // v-p is negative but still higher than the (negative) exitThreshold
        else if ((shortSelling == ShortSellingValue.NOT_ALLOWED) && (ownValue_t - price_t < Math.max(exitThreshold, 0)) && (tsPos.get(tick - 1) > 0.0)) {
        	if (lastEntryTick <= tick - bcTicks) {
        		tsPos.add(tick, 0.0);
        	}
        	else {     
        		tsPos.add(tick, tsPos.get(tick - 1));
        	}
        }
        // {short position} AND {underpriced enough} AND {waited enough after last trade} --> close short position
        else if ((ownValue_t - price_t > -exitThreshold) && (tsPos.get(tick - 1) < 0.0)) {
        	if (lastEntryTick <= tick - bcTicks) {
        		tsPos.add(tick, 0.0);      
        	}
        	else { 
        		tsPos.add(tick, tsPos.get(tick - 1));
        	}
        }
        
        // If the open position can be updated: {long/short position} AND {exit condition not satisfied yet} --> update the position
        else if ( (((ownValue_t - price_t > exitThreshold) && (tsPos.get(tick - 1) > 0.0)) || ((ownValue_t - price_t < -exitThreshold) && (tsPos.get(tick - 1) < 0.0)) ) 
    		   && (positionUpdate == PositionUpdateValue.VARIABLE)) {
        	position = capFactor * (ownValue_t - price_t) * wealthFactor;
        	if (orderOrPositionStrategy == OrderOrPositionStrategyValue.POSITION)  // the new position is proportional to the indicator
        	    tsPos.add(tick, position);
        	else if (orderOrPositionStrategy == OrderOrPositionStrategyValue.ORDER)   // the new order is proportional to the indicator
        	    tsPos.add(tick, tsPos.get(tick - 1) + position);
        	else 
            	Assertion.assertStrict(false, Level.ERR, "The method for orderOrPositionStrategy " + 
                        orderOrPositionStrategy + " is not implemented");
        }
        
        // keep position 'as is'
        else {
            tsPos.add(tick, tsPos.get(tick - 1));
        }
      
        // Compute the order and absolute order
        if (tick == 0) {    // TODO this is never reached since when tick = 0, you exit the method in a previous conditional above
            order.setOrder(tsPos.get(tick));
        }
        else {
            order.setOrder(tsPos.get(tick) - tsPos.get(tick - 1));
        }
        
        logger.trace("Price_{}: {}", tick, tsPrice.get(tick));
        logger.trace("Generic value_{}: {}", tick, tsFundValue.get(tick));
        logger.trace("Own value_{}: {}", tick, ownValue_t);
        logger.trace("Pos_{}: {}", tick, tsPos.get(tick));
    }
    
}