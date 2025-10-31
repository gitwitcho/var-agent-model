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

import org.apache.commons.math3.distribution.NormalDistribution;
import org.apache.commons.math3.special.Gamma;
import org.apache.commons.math3.distribution.TDistribution;

import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.Hashtable;
import java.util.Set;

import java.util.Collections;

/**
 * @author Gilbert Peffer
 *
 */
public class TradingPortfolio {   

	private HashMap<String, DoubleTimeSeries> tsPosList;
	private String traderId;
	private NormalDistribution normalDist;
	
//	private double covarianceEWMA_previous_tick    = 0;        // given: EWMA covariance at t-1
//	private double covarianceEWMA_current_tick     = 0;        // compute: EWMA covariance at t
    
    public TradingPortfolio() {
        this.tsPosList = new HashMap<String, DoubleTimeSeries>();
        this.normalDist = new NormalDistribution();  // Normal distribution to calculate VaR and ES. 
        											 // Created here to avoid creating the distribution each time the VaR/ES is calculated
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
    
    public double valueAtRisk_conf99(ShareMarket market) {
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
    	var = Math.sqrt(portfolioVol) * 2.3263478740408408 * portfolioValue;    	
    	
    	return var;
    }   
    

    /*
     * Calculate the value-at-risk of the portfolio at a given confidence level (in dollars)
     */
    
    public double valueAtRisk(ShareMarket market, double confidenceLevel) {
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
    	
    	// Calculate the VaR of the portfolio (in dollar value)
        double zScore_N = this.normalDist.inverseCumulativeProbability(confidenceLevel);                    	
    	double var;
    	var = Math.sqrt(portfolioVol) * zScore_N * portfolioValue;
    	
    	return var;
    }   

    
    /*
     * Calculate the expected shortfall of the portfolio (in dollars).
     * This method uses the parametric approach using a t-Student distribution.
     */
    
/*    public double expectedShortfallParametricTStudent(ShareMarket market, double confidenceLevel) {
        int currentTick = WorldClock.currentTick();
        Set<String> secIds = market.getTradedShares().keySet();

        if (currentTick == 0) return 0;

        // Calculate the current value of the portfolio (with positions in absolute value)
        double portfolioValue = 0;
        for (String secId : secIds) {
            portfolioValue += Math.abs(this.tsPosList.get(secId).get(currentTick)) * market.getPrices(secId).get(currentTick);
        }

        if (portfolioValue == 0) return 0; // If there are no positions in the portfolio --> ES = 0
        
        // Calculate the volatility of the portfolio (with positions in absolute value)
        double portfolioVol = 0;
        
        for (String secId_1 : secIds) {
            double weight1 = Math.abs(this.tsPosList.get(secId_1).get(currentTick)) * market.getPrices(secId_1).get(currentTick) / portfolioValue;
            
            for (String secId_2 : secIds) {
                double weight2 = Math.abs(this.tsPosList.get(secId_2).get(currentTick)) * market.getPrices(secId_2).get(currentTick) / portfolioValue;
                double covariance = market.getTrader(traderId).getCurrentCovariance(secId_1, secId_2);
                portfolioVol += weight1 * weight2 * covariance;
            }
        }
        portfolioVol = Math.sqrt(portfolioVol);
       
    	// Calculate the ES of the portfolio (in dollar value)
    	int degreesOfFreedom = 6;
    	TDistribution tDist = new TDistribution(degreesOfFreedom);
//        double tQuantile = tDist.inverseCumulativeProbability(1-confidenceLevel);
    	double tQuantile = 3.142668402850914;  // Confidence level = 99%
//    	double pdfValue = tDist.density(tQuantile);
    	double pdfValue = 0.01269978285311081;   // Confidence level = 99%
    	//System.out.println("tQuantile: " + tQuantile + "  pdfValue: " + pdfValue + "\n");
    	double es = portfolioValue * portfolioVol * ((degreesOfFreedom + tQuantile * tQuantile) / (degreesOfFreedom - 1)) * (pdfValue / (1-confidenceLevel));
        
        return es;
    }
*/

    /*
     * Calculate the expected shortfall of the portfolio (in dollars).
     * This method uses the parametric approach using a Normal distribution.
     */
    
    public double expectedShortfallParametricNormal(ShareMarket market, double confidenceLevel) {
        int currentTick = WorldClock.currentTick();
        Set<String> secIds = market.getTradedShares().keySet();

        if (currentTick == 0) return 0;

        // Calculate the current value of the portfolio (with positions in absolute value)
        double portfolioValue = 0;
        for (String secId : secIds) {
            portfolioValue += Math.abs(this.tsPosList.get(secId).get(currentTick)) * market.getPrices(secId).get(currentTick);
        }

        if (portfolioValue == 0) return 0; // If there are no positions in the portfolio --> ES = 0
        
        // Calculate the volatility of the portfolio (with positions in absolute value)
        double portfolioVol = 0;
        
        for (String secId_1 : secIds) {
            double weight1 = Math.abs(this.tsPosList.get(secId_1).get(currentTick)) * market.getPrices(secId_1).get(currentTick) / portfolioValue;
            
            for (String secId_2 : secIds) {
                double weight2 = Math.abs(this.tsPosList.get(secId_2).get(currentTick)) * market.getPrices(secId_2).get(currentTick) / portfolioValue;
                double covariance = market.getTrader(traderId).getCurrentCovariance(secId_1, secId_2);
                portfolioVol += weight1 * weight2 * covariance;
            }
        }
        portfolioVol = Math.sqrt(portfolioVol);
       
        // ES with normal distribution
        double zScore_N = this.normalDist.inverseCumulativeProbability(confidenceLevel);
        double pdf_N = this.normalDist.density(zScore_N); // \phi(Z_\alpha)
        double es_N = portfolioValue * portfolioVol * (pdf_N / (1 - confidenceLevel));

        return es_N;
    }

    
    // Historical simulation, gradual approach, o4
    
/*    public double expectedShortfall(ShareMarket market, double confidenceLevel, int lookbackWindow) {
        int currentTick = WorldClock.currentTick();
        Set<String> secIds = market.getTradedShares().keySet();

        if (currentTick < lookbackWindow || secIds.isEmpty()) return 0;

        // Step 1: Calculate the current portfolio value and weights (using absolute positions)
        double portfolioValue = 0;
        HashMap<String, Double> weights = new HashMap<String, Double>();

        for (String secId : secIds) {
            DoubleTimeSeries positions = this.getTsPosition(secId);
            DoubleTimeSeries prices = market.getPrices(secId);

            if (positions != null && prices != null && currentTick < positions.size() && currentTick < prices.size()) {
                double positionValue = Math.abs(positions.get(currentTick)) * prices.get(currentTick);
                weights.put(secId, positionValue);
                portfolioValue += positionValue;
            }
        }

        if (portfolioValue == 0) return 0;

        // Normalize weights to sum up to 1
        for (String secId : weights.keySet()) {
            weights.put(secId, weights.get(secId) / portfolioValue);
        }

        // Step 2: Compute portfolio losses over the lookback period
        ArrayList<Double> portfolioLosses = new ArrayList<Double>();

        for (int t = currentTick - lookbackWindow; t < currentTick; t++) {
            double portfolioLoss = 0;

            for (String secId : secIds) {
                DoubleTimeSeries prices = market.getPrices(secId);

                if (prices != null && t > 0 && t < prices.size()) {
                    double priceChange = (prices.get(t) - prices.get(t - 1)) / prices.get(t - 1);
                    portfolioLoss += weights.get(secId) * priceChange;
                }
            }

            portfolioLosses.add(portfolioLoss);
        }

        if (portfolioLosses.isEmpty()) return 0;

        // Step 3: Sort portfolio losses in ascending order
        java.util.Collections.sort(portfolioLosses);

        // Step 4: Calculate Value at Risk (VaR) threshold
        int varIndex = (int) Math.ceil((1 - confidenceLevel) * portfolioLosses.size());
        double varThreshold = portfolioLosses.get(varIndex - 1);

        // Step 5: Calculate Expected Shortfall (ES) in percentage terms
        double totalLosses = 0;
        int count = 0;

        for (double loss : portfolioLosses) {
            if (loss <= varThreshold) {
                totalLosses += loss;
                count++;
            }
        }

        double esPercentage = (count > 0) ? -totalLosses / count : 0;

        // Step 6: Convert ES to dollar terms
        double expectedShortfall = esPercentage * portfolioValue;

        return expectedShortfall;
    }
*/

    
    // Historical simulation, generated by o4
    
    /**
     * Calculate the Expected Shortfall (ES) of the portfolio at a specified confidence level
     * for the current portfolio positions.
     * 
     * @param market         the ShareMarket object containing price and other market data
     * @param confidenceLevel the confidence level for ES calculation (e.g., 0.99 for 99%)
     * @return               the calculated Expected Shortfall in dollar value
     */
/*    public double expectedShortfall(ShareMarket market, double confidenceLevel) {
        int currentTick = WorldClock.currentTick();
        Set<String> secIds = market.getTradedShares().keySet();

        if (currentTick < 2) return 0; // Need at least two ticks to calculate losses

        // Step 1: Calculate portfolio losses for the current portfolio positions
        ArrayList<Double> portfolioLosses = new ArrayList<Double>();

        for (int t = 1; t < currentTick; t++) {
            double portfolioValuePrev = 0.0;
            double portfolioValueCurr = 0.0;

            // Calculate portfolio value at t-1 and t using the current positions (positions at currentTick)
            for (String secId : secIds) {
                double positionAtCurrentTick = Math.abs(this.tsPosList.get(secId).get(currentTick)); // Position at currentTick
                portfolioValuePrev += positionAtCurrentTick * market.getPrices(secId).get(t - 1);   // Value at time t-1
                portfolioValueCurr += positionAtCurrentTick * market.getPrices(secId).get(t);       // Value at time t
            }

            // Calculate the absolute loss
            double loss = portfolioValueCurr - portfolioValuePrev;
            portfolioLosses.add(loss);
        }

        if (portfolioLosses.isEmpty()) return 0;

        // Step 2: Sort losses in ascending order (worst losses first)
        Collections.sort(portfolioLosses);

        // Step 3: Identify the VaR threshold index
        int varIndex = (int) Math.ceil((1 - confidenceLevel) * portfolioLosses.size());
        double varThreshold = portfolioLosses.get(varIndex - 1);

        // Step 4: Calculate ES as the average of losses beyond the VaR threshold
        double cumulativeLoss = 0.0;
        int count = 0;

        for (int i = 0; i < varIndex; i++) {
            cumulativeLoss += portfolioLosses.get(i);
            count++;
        }

        return count > 0 ? cumulativeLoss / count : 0.0;
    }
*/

    
    /*
     * Calculate the stressed value-at-risk of the portfolio at 99% confidence level (in dollars)
     * This is calculated as normal VaR, but using the highest volatilities since the start of the simulation
     */
    
    public double stressedValueAtRisk_conf99(ShareMarket market) {
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
    	sVar = Math.sqrt(portfolioVol) * 2.3263478740408408 * portfolioValue;
    	
    	return sVar;
    }


    /*
     * Calculate the stressed value-at-risk of the portfolio at a given confidence level (in dollars)
     * This is calculated as normal VaR, but using the highest volatilities since the start of the simulation
     */
    
    public double stressedValueAtRisk(ShareMarket market, double confidenceLevel) {
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
    	
    	// Calculate the stressed VaR of the portfolio (in dollar value)
        double zScore_N = this.normalDist.inverseCumulativeProbability(confidenceLevel);                    	
    	double sVar;
    	sVar = Math.sqrt(portfolioVol) * zScore_N * portfolioValue;
    	
    	return sVar;
    }

    /*
     * Calculate the stressed expected shortfall of the portfolio at a given confidence level (in dollars)
     * This is calculated as normal ES, but using the highest volatilities since the start of the simulation
     */
    
    public double stressedExpectedShortfall(ShareMarket market, double confidenceLevel) {
    	int currentTick = WorldClock.currentTick();
    	Set<String> secIds = market.getTradedShares().keySet();
    	
    	if (currentTick == 0)  return 0;
    	
    	// Calculate the current value of the portfolio (with positions in absolute value)
    	double portfolioValue = 0;
    	
    	for (String secId : secIds) {
    		portfolioValue = portfolioValue + Math.abs(this.tsPosList.get(secId).get(currentTick)) * market.getPrices(secId).get(currentTick);
    	}
    	
    	if (portfolioValue == 0) return 0;  // If there are no positions in the portfolio --> ES = 0
            
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
    	
    	// Calculate the stressed ES of the portfolio, assuming a normal distribution (in dollar value)
        double zScore_N = this.normalDist.inverseCumulativeProbability(confidenceLevel);
        double pdf_N = this.normalDist.density(zScore_N); // \phi(Z_\alpha)
        double sEs_N = portfolioValue * Math.sqrt(portfolioVol) * (pdf_N / (1 - confidenceLevel));
    	
    	return sEs_N;
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
//    	var = Math.sqrt(portfolioVol) * 2.3263478740408408 * portfolioValue;
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
    
    public double preTradeValueAtRisk_conf99(ShareMarket market) {
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
    	var = Math.sqrt(portfolioVol) * 2.3263478740408408 * portfolioValue;
    	
    	return var;
    }


    /*
     * Calculate the value-at-risk of the portfolio at a given confidence level (in dollars) 
     * at the start of the time step, BEFORE any trade is done
     */
    
    public double preTradeValueAtRisk(ShareMarket market, double confidenceLevel) {
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
  	
    	// Calculate the VaR of the portfolio (in dollar value)
        double zScore_N = this.normalDist.inverseCumulativeProbability(confidenceLevel);                    	
    	double var;
    	var = Math.sqrt(portfolioVol) * zScore_N * portfolioValue;
    	
    	return var;
    }

    
    /*
     * Calculate the expected shortfall of the portfolio (in dollars) 
     * at the start of the time step, BEFORE any trade is done.
     * This implementation uses a Student-T distribution.
     */
    
/*    public double preTradeShortfallParametricTStudent(ShareMarket market, double confidenceLevel) {
    	int currentTick = WorldClock.currentTick();
    	Set<String> secIds = market.getTradedShares().keySet();
    	
    	if (currentTick == 0)  return 0;
    	
    	// Calculate the current value of the portfolio (with positions in absolute value)
    	double portfolioValue = 0;
    	
    	for (String secId : secIds) {
    		portfolioValue = portfolioValue + Math.abs(this.tsPosList.get(secId).get(currentTick-1)) * market.getPrices(secId).get(currentTick);
    	}
    	
    	if (portfolioValue == 0) return 0;  // If there are no positions in the portfolio --> ES = 0
            
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
    	
    	// Calculate the ES of the portfolio (in dollar value)
    	int degreesOfFreedom = 6;
    	TDistribution tDist = new TDistribution(degreesOfFreedom);
//      double tQuantile = tDist.inverseCumulativeProbability(1-confidenceLevel);
    	double tQuantile = 3.142668402850914;  // Confidence level = 99%
//  	double pdfValue = tDist.density(tQuantile);
    	double pdfValue = 0.01269978285311081;   // Confidence level = 99%
    	double es = portfolioValue * portfolioVol * ((degreesOfFreedom + tQuantile * tQuantile) / (degreesOfFreedom - 1)) * (pdfValue / (1-confidenceLevel));
        
        return es;
    }
*/

    /*
     * Calculate the expected shortfall of the portfolio (in dollars) 
     * at the start of the time step, BEFORE any trade is done.
     * This implementation uses a normal distribution.
     */
    
    public double preTradeShortfallParametricNormal(ShareMarket market, double confidenceLevel) {
    	int currentTick = WorldClock.currentTick();
    	Set<String> secIds = market.getTradedShares().keySet();
    	
    	if (currentTick == 0)  return 0;
    	
    	// Calculate the current value of the portfolio (with positions in absolute value)
    	double portfolioValue = 0;
    	
    	for (String secId : secIds) {
    		portfolioValue = portfolioValue + Math.abs(this.tsPosList.get(secId).get(currentTick-1)) * market.getPrices(secId).get(currentTick);
    	}
    	
    	if (portfolioValue == 0) return 0;  // If there are no positions in the portfolio --> ES = 0
            
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
    	
        // ES with normal distribution
        double zScore_N = this.normalDist.inverseCumulativeProbability(confidenceLevel);
        double pdf_N = this.normalDist.density(zScore_N); // \phi(Z_\alpha)
        double es_N = portfolioValue * Math.sqrt(portfolioVol) * (pdf_N / (1 - confidenceLevel));

        return es_N;
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


