/*
 * Copyright (c) 2011-2014 Gilbert Peffer, Bàrbara Llacay
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
package info.financialecology.finance.abm.model.agent;

import info.financialecology.finance.abm.model.ShareMarket;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.datagen.DataGenerator;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.statistics.StatsTimeSeries;

import java.util.ArrayList;
import java.util.HashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import repast.simphony.engine.schedule.ScheduleParameters;
import repast.simphony.engine.schedule.ScheduledMethod;


/**
 * @author Gilbert Peffer
 *
 */
public class ShareMarketMaker extends Agent {

    private static int numInst = 0;
	private int nID;			       // standard ID, incremental numbering of instances
	
	private ShareMarket market;        // market in which the market maker operates
	private ArrayList<String> secIds;  // provide prices for all securities in this list
	private HashMap<String, ArrayList<OrderBookEntry>> orderBook; // order book for the securities traded by the market maker
	
	private HashMap<String, DataGenerator> exoPriceGen;    // data generators for the exogenous price processes of the different assets
	
	   private class OrderBookEntry {
	        private Trader trader;
	        private double order;
	                
	        /**
	         * @param trader
	         * @param double
	         */
	        public OrderBookEntry(Trader trader, double order) {
	            super();
	            this.trader = trader;
	            this.order = order;
	        }
	        
	        /**
	         * @return the fundTrader
	         */
	        public Trader getTrader() {
	            return trader;
	        }
	        /**
	         * @return the order
	         */
	        public double getOrder() {
	            return order;
	        }
	   }
	
    Logger logger = (Logger)LoggerFactory.getLogger(ShareMarketMaker.class.getSimpleName());
    
    
    /**
     * Constructor 
     */
    public ShareMarketMaker() {
        setID();
        
        this.market = null;
        this.secIds = new ArrayList<String>();
        this.exoPriceGen = new HashMap<String, DataGenerator>();
        
        setAllInitPrices(0);
        setAllInitSpreads(0);
        
        orderBook = new HashMap<String, ArrayList<OrderBookEntry>>();
        
        logger.trace("CREATED: {}", this.toString());
    }
    
    /**
     * Constructor
     * 
     * @param market
     */
    public ShareMarketMaker(ShareMarket market) {
        this();
        
        this.market = market;
        
        logger.trace("CREATED: {}", this.toString());
    }
    
//	/**
//	 * Constructor
//	 * 
//	 * @param market
//	 * @param exoPriceGen
//	 */
//	public ShareMarketMaker(ShareMarket market, DataGenerator... exoPriceGenerators) {
//	    this(market);
//	    
//	    for (DataGenerator exo : exoPriceGenerators)
//	        this.exoPriceGen;
//
//        logger.trace("CREATED: {}", this.toString());
//	}
	
	
    /**
     * Enter the market {@code newMarket} to quote prices there. A market maker can only be in one
     * market at a time.
     * 
     * @param newMarket the market in which the market maker quotes prices 
     */
    public void enterMarket(ShareMarket newMarket) {
        this.market = newMarket; 
    }

    
    /**
     * Provide prices for all securities in the share market
     */
    public void makeMarketInAllSecurities() {
        
        for (String secId : market.getTradedShares().keySet()) {
            if (!secIds.contains(secId))
                secIds.add(secId);
        }
    }

    /**
     * Set the same price at time t = 0 for all shares. This method is
     * called by the constructor to ensure that there is an initial price.
     * Users should call this method to initialise prices to the desired 
     * values.
     * 
     * @param price_t_0 the price at t = 0
     */
    public void setAllInitPrices(double price_t_0) {
        
        for (String secId : secIds) {
            ShareMarket.Share share = market.getTradedShares().get(secId);
            share.prices.add(0, price_t_0);
        }
    }

    /**
     * Set the price at time t = 0 for the share secId. This method allows
     * users to set the initial price of share secId. 
     * 
     * @param price_t_0 the price at t = 0
     */
    public void setInitPrice(String secId, double price_t_0) {
        Assertion.assertStrict(market.getTradedShares().containsKey(secId), Level.ERR, "No share with secId = " + secId + " traded in the market.");
        market.getTradedShares().get(secId).prices.add(0, price_t_0);
    }

    /**
     * Set the same value at time t = 0 for all spreads. This method is
     * called by the constructor to ensure that there is an initial spread.
     * Users should call this method to initialise spreads to the desired 
     * values.
     * 
     * @param spread_t_0 the spread at t = 0
     */
    public void setAllInitSpreads(double spread_t_0) {
    	
    	int numAssets = secIds.size();
		for (int i = 1; i < numAssets; i++) {
			DoubleTimeSeries spreads = market.getSpreads(secIds.get(0), secIds.get(i));
			spreads.add(0, spread_t_0);
		}
    }
    
    /**
     * Set the spread at time t = 0 for the shares secId_1 and secId_2. 
     * This method allows users to set the initial value of spread secId_1-secId_2. 
     * 
     * @param price1_t_0 the price of first asset at t = 0
     * @param price2_t_0 the price of second asset at t = 0
     */
    public void setInitSpread(String secId_1, double price1_t_0, String secId_2, double price2_t_0) {
        Assertion.assertStrict(market.getTradedShares().containsKey(secId_1), Level.ERR, "No share with secId = " + secId_1 + " traded in the market.");
        Assertion.assertStrict(market.getTradedShares().containsKey(secId_2), Level.ERR, "No share with secId = " + secId_2 + " traded in the market.");
        market.getSpreads(secId_1, secId_2).add(0, price1_t_0 - price2_t_0);
    }
    
    /**
     * Set the exogenous price generator for a given asset
     */
    public void setExogenousPriceGenerator(String assetId, DataGenerator generator) {
        this.exoPriceGen.put(assetId, generator);
    }
    
    /**
     * @return the array of secIds
     */
    public ArrayList<String> getSecIds() {
        
        return secIds;
    }

    /**
     *  Service for traders to post their orders to the market maker
     */
    public void placeOrder(Trader trader, String secId, double order){
        OrderBookEntry entry = new OrderBookEntry(trader, order);
        
        if (!orderBook.containsKey(secId))
            orderBook.put(secId, new ArrayList<OrderBookEntry>());
        
        orderBook.get(secId).add(entry);
    }
    
    /**
     *  Clear the market based on the orders from the traders
     */
	@ScheduledMethod(start=0, interval=1, priority = ScheduleParameters.FIRST_PRIORITY)
	public void clearMarket() {
		
		int currentTick = (int) market.currentTick();
		
		logger.trace("t = {} | {}", currentTick, this.toString());

		for (String secId : secIds) {     // loop over all shares and determine their prices
			
		    ArrayList<OrderBookEntry> entries = orderBook.get(secId); // get all orders for share secId
		    double totalOrders = 0;
		    double exoPriceChange = 0;
		    DoubleTimeSeries prices = market.getPrices(secId);
		    DoubleTimeSeries logReturns = market.getLogReturns(secId);
		    
		    if (entries != null) {
    		    for (OrderBookEntry entry : entries) {    // total orders for share secId 
    		        totalOrders += entry.getOrder();
    		    }
		    }
		
    		// Calculate new price for share secId + update logReturns and volatility
    		if (currentTick == 0) {
    		    Assertion.assertOrKill(prices.size() == 1, "An initial price for share with secId '" + 
    		            secId + "' has not been set. Use the method setInitPrice(...)");
    		    
    		    prices.add(0, prices.get(0));
    		    logReturns.add(0, 0);
    		}
    		else {
                if (exoPriceGen != null)
                    // TODO there has to be one generator for each share / secId
                    exoPriceChange = exoPriceGen.get(secId).nextDoubleIncrement();
                
                prices.add(currentTick, prices.get(currentTick - 1) + totalOrders / market.getLiquidity(secId) + exoPriceChange);
                logReturns.add(currentTick, Math.log(prices.get(currentTick)) - Math.log(prices.get(currentTick-1)) );
            }
		}
		
		// Update the spreads using the new prices
		int numAssets = secIds.size();
		for (int i = 1; i < numAssets; i++) {
			DoubleTimeSeries spreads = market.getSpreads(secIds.get(0), secIds.get(i));
			double price_1 = market.getPrices(secIds.get(0)).get(currentTick);
			double price_2 = market.getPrices(secIds.get(i)).get(currentTick);
			spreads.add(currentTick, price_1 - price_2);
		}
				
		// Remove all order book entries
		orderBook.clear();
	}
	
	
    /**
     *  Update the generic fundamental value process at each time step
     *  
     *  TODO: The methods related to the generic fundamental value live within the
     *  ShareMarket class, but the update to be done at each time step must
     *  be called by an agent so that the @ScheduledMethod works. For this reason 
     *  I have moved it here.
     */
	@ScheduledMethod(start=0, interval=1, priority = ScheduleParameters.FIRST_PRIORITY)
	public void updateFundValue() {
		
		int currentTick = (int) market.currentTick();
		
		for (String secId : secIds) {     // loop over all shares

		    DoubleTimeSeries fundValues = market.getFundValues(secId);
		
    		// Calculate new fund value for share secId
		    fundValues.add(currentTick, market.getFundValueGenerator(secId).nextDouble());
		}
	}
		
	
	
//	// Provide the current market price
//	public double getCurrentPrice(String secId) {
//		return market.getPrices(secId).get((int) market.currentTick());
//	}
	
	
    // Generate numeric ID from number of instances created
	private void setID() {
		numInst++;
		nID = numInst;		
	}
	
	/**
	 * @param numInst the numInst to set
	 */
	public static void resetNumInst() {
		ShareMarketMaker.numInst = 0;
	}
	
    public String toString() {
        return "MarketMaker_" + nID;
    }
}
