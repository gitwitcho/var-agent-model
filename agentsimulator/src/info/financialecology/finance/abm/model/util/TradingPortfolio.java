/**
 * Simple financial systemic risk simulator for Java
 * http://code.google.com/p/systemic-risk/
 * 
 * Copyright (c) 2011-2014
 * Gilbert Peffer
 * gilbert.peffer@gmail.com
 * All rights reserved
 *
 * This software is open-source under the BSD license; see 
 * http://code.google.com/p/systemic-risk/wiki/SoftwareLicense
 */
package info.financialecology.finance.abm.model.util;

import info.financialecology.finance.abm.model.ShareMarket;
import info.financialecology.finance.abm.model.agent.Trader;
import info.financialecology.finance.abm.model.strategy.TradingStrategy;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.WorldClock;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.statistics.StatsTimeSeries;
import info.financialecology.finance.abm.model.strategy.TradingStrategy.Order;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Set;

/**
 * @author Gilbert Peffer
 *
 */
public class TradingPortfolio {   

	private HashMap<String, DoubleTimeSeries> tsPosList;
	private String traderId;
	
//	private double covarianceEWMA_previous_tick    = 0;        // given: EWMA covariance at t-1
//	private double covarianceEWMA_current_tick     = 0;        // compute: EWMA covariance at t
    
    public TradingPortfolio() {
        this.tsPosList = new HashMap<String, DoubleTimeSeries>();
    }
    
    public DoubleTimeSeries getTsPosition(String secId) {
        return tsPosList.get(secId);
    }
    
    public void addToPositions(Order order) {
    	int currentTick = WorldClock.currentTick();
    	double position_previous_tick;
    	
        if (currentTick > 0)
        	position_previous_tick = this.getTsPosition(order.getSecId()).get(currentTick - 1);
        else
        	position_previous_tick = 0;
        
        if (this.getTsPosition(order.getSecId()).size() > currentTick) {  // A position has already been introduced for this asset in current tick
        	double position_current_tick = this.getTsPosition(order.getSecId()).get(currentTick); 
        	this.getTsPosition(order.getSecId()).add(currentTick, position_current_tick + order.getOrder());
        }
        else {   // No position introduced for this asset yet in current tick
        	this.getTsPosition(order.getSecId()).add(currentTick, position_previous_tick + order.getOrder());
        }
    }
    
 
    /*
     * Calculate the value-at-risk of the portfolio at 99% confidence level (in dollars)
     */
    
    public double valueAtRisk(ShareMarket market) {
    	int currentTick = WorldClock.currentTick();
    	Set<String> secIds = market.getTradedShares().keySet();
    	
    	if (currentTick == 0)  return 0;
    	
    	// Calculate the current value of the portfolio (with positions in absolute value)
    	double portfolioValue = 0;
    	
    	for (String secId : secIds) {
    		portfolioValue = portfolioValue + Math.abs(this.tsPosList.get(secId).get(currentTick)) * market.getPrices(secId).get(currentTick);
    	}
    	
    	if (portfolioValue == 0) return 0;  // If there are no positions in the portfolio --> VaR = 0
            
    	// Calculate the volatility of the portfolio (with positions in absolute value)
    	double portfolioVol = 0;

    	for (String secId_1 : secIds) {
    		double weight_1 =  Math.abs(this.tsPosList.get(secId_1).get(currentTick)) * market.getPrices(secId_1).get(currentTick) / portfolioValue;  // dollar ratio spent in this asset
    		
        	for (String secId_2 : secIds) {
        		double weight_2 =  Math.abs(this.tsPosList.get(secId_2).get(currentTick)) * market.getPrices(secId_2).get(currentTick) / portfolioValue;  // dollar ratio spent in this asset
        		double covariance = market.getTrader(traderId).getCurrentCovariance(secId_1, secId_2);        		
        		portfolioVol = portfolioVol + weight_1 * weight_2 * covariance;
        	}
    	}
    	
    	// Calculate the VaR at 99% of the portfolio (in dollar value)
    	double var;
    	var = Math.sqrt(portfolioVol) * 2.33 * portfolioValue;
    	
    	return var;
    }

    
    /*
     * Calculate the stressed value-at-risk of the portfolio at 99% confidence level (in dollars)
     * This is calculated as normal VaR, but using the highest volatilities since the start of the simulation
     */
    
    public double stressedValueAtRisk(ShareMarket market) {
    	int currentTick = WorldClock.currentTick();
    	Set<String> secIds = market.getTradedShares().keySet();
    	
    	if (currentTick == 0)  return 0;
    	
    	// Calculate the current value of the portfolio (with positions in absolute value)
    	double portfolioValue = 0;
    	
    	for (String secId : secIds) {
    		portfolioValue = portfolioValue + Math.abs(this.tsPosList.get(secId).get(currentTick)) * market.getPrices(secId).get(currentTick);
    	}
    	
    	if (portfolioValue == 0) return 0;  // If there are no positions in the portfolio --> VaR = 0
            
    	// Calculate the volatility of the portfolio (with positions in absolute value)
    	// Use the maximum volatilities instead of current volatilities
    	double portfolioVol = 0;

    	for (String secId_1 : secIds) {
    		double weight_1 =  Math.abs(this.tsPosList.get(secId_1).get(currentTick)) * market.getPrices(secId_1).get(currentTick) / portfolioValue;  // dollar ratio spent in this asset
    		
        	for (String secId_2 : secIds) {
        		double weight_2 =  Math.abs(this.tsPosList.get(secId_2).get(currentTick)) * market.getPrices(secId_2).get(currentTick) / portfolioValue;  // dollar ratio spent in this asset
        		double covariance = market.getTrader(traderId).getMaxCovariance(secId_1, secId_2);        		
        		portfolioVol = portfolioVol + weight_1 * weight_2 * covariance;
        	}
    	}
    	
    	// Calculate the stressed VaR at 99% of the portfolio (in dollar value)
    	double sVar;
    	sVar = Math.sqrt(portfolioVol) * 2.33 * portfolioValue;
    	
    	return sVar;
    }

    
//    /*
//     * Calculate the value-at-risk of the portfolio at 99% confidence level (in dollars).
//     * This method uses the covariance calculated with the EWMA model.
//     */
//    
//    public double valueAtRisk_EWMA(ShareMarket market, double lambda) {
//    	int currentTick = WorldClock.currentTick();
//    	Set<String> secIds = market.getTradedShares().keySet();
//    	
//    	if (currentTick == 0)  return 0;
//    	
//    	// Calculate the current value of the portfolio (with positions in absolute value)
//    	double portfolioValue = 0;
//    	
//    	for (String secId : secIds) {
//    		portfolioValue = portfolioValue + Math.abs(this.tsPosList.get(secId).get(currentTick)) * market.getPrices(secId).get(currentTick);
//    	}
//    	
//    	if (portfolioValue == 0) return 0;  // If there are no positions in the portfolio --> VaR = 0
//            
//    	// Calculate the (EWMA) volatility of the portfolio (with positions in absolute value)
//    	double portfolioVol = 0;
//
//    	for (String secId_1 : secIds) {
//    		double weight_1 =  Math.abs(this.tsPosList.get(secId_1).get(currentTick)) * market.getPrices(secId_1).get(currentTick) / portfolioValue;  // dollar ratio spent in this asset
//    		
//        	for (String secId_2 : secIds) {
//        		double weight_2 =  Math.abs(this.tsPosList.get(secId_2).get(currentTick)) * market.getPrices(secId_2).get(currentTick) / portfolioValue;  // dollar ratio spent in this asset
//        		double covariance;
//        		
//        		if (currentTick == 0)
//        			covarianceEWMA_current_tick = market.getLogReturns(secId_1).get(currentTick) * market.getLogReturns(secId_2).get(currentTick);
//        		else
//        			covarianceEWMA_current_tick = lambda * covarianceEWMA_previous_tick + (1-lambda) * market.getLogReturns(secId_1).get(currentTick) * market.getLogReturns(secId_2).get(currentTick);
//
//       			portfolioVol = portfolioVol + weight_1 * weight_2 * covarianceEWMA_current_tick;
//        	}
//    	}
//    	
//    	// Calculate the VaR at 99% of the portfolio (in dollar value)
//    	double var;
//    	var = Math.sqrt(portfolioVol) * 2.33 * portfolioValue;
//
//    	// Shift covariance at t-1 to t
//    	covarianceEWMA_previous_tick = covarianceEWMA_current_tick;
//    	
//    	return var;
//    }

    
    /*
     * Calculate the value-at-risk of the portfolio at 99% confidence level (in dollars) 
     * at the start of the time step, BEFORE any trade is done
     */
    
    public double preTradeValueAtRisk(ShareMarket market) {
    	int currentTick = WorldClock.currentTick();
    	Set<String> secIds = market.getTradedShares().keySet();
    	
    	if (currentTick == 0)  return 0;
    	
    	// Calculate the current value of the portfolio (with positions in absolute value)
    	double portfolioValue = 0;
    	
    	for (String secId : secIds) {
    		portfolioValue = portfolioValue + Math.abs(this.tsPosList.get(secId).get(currentTick-1)) * market.getPrices(secId).get(currentTick);
    	}
    	
    	if (portfolioValue == 0) return 0;  // If there are no positions in the portfolio --> VaR = 0
            
    	// Calculate the volatility of the portfolio (with positions in absolute value)
    	double portfolioVol = 0;

    	for (String secId_1 : secIds) {
    		double weight_1 =  Math.abs(this.tsPosList.get(secId_1).get(currentTick-1)) * market.getPrices(secId_1).get(currentTick) / portfolioValue;  // dollar ratio spent in this asset
    		
        	for (String secId_2 : secIds) {
        		double weight_2 =  Math.abs(this.tsPosList.get(secId_2).get(currentTick-1)) * market.getPrices(secId_2).get(currentTick) / portfolioValue;  // dollar ratio spent in this asset
        		double covariance = market.getTrader(traderId).getCurrentCovariance(secId_1, secId_2);
        		
        		portfolioVol = portfolioVol + weight_1 * weight_2 * covariance;
        	}
    	}
    	
    	// Calculate the VaR at 99% of the portfolio (in dollar value)
    	double var;
    	var = Math.sqrt(portfolioVol) * 2.33 * portfolioValue;
    	
    	return var;
    }
  
   
    public void newSecurity(String secId) {
        if(!tsPosList.containsKey(secId))
            tsPosList.put(secId, new DoubleTimeSeries());
    }
    
    public void setTraderId(String traderId) {
        this.traderId = traderId;
    }
        
    public String getTraderId() {
        return this.traderId;
    }

}
