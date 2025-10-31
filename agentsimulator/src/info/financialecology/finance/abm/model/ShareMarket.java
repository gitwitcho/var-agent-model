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
package info.financialecology.finance.abm.model;

import info.financialecology.finance.abm.model.agent.Agent;
import info.financialecology.finance.abm.model.agent.FJFundamentalTrader;
import info.financialecology.finance.abm.model.agent.FJMarketMaker;
import info.financialecology.finance.abm.model.agent.FJTechnicalTrader;
import info.financialecology.finance.abm.model.agent.ShareMarketMaker;
import info.financialecology.finance.abm.model.agent.Trader;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.WorldClock;
import info.financialecology.finance.utilities.datagen.DataGenerator;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import repast.simphony.engine.schedule.ISchedule;
import repast.simphony.engine.schedule.ScheduleParameters;
import repast.simphony.engine.schedule.ScheduledMethod;



/**
 * A central place that pulls in the different resources and that market participants can access and use
 * 
 * @author Gilbert Peffer
 *
 */
public class ShareMarket {
    private static final Logger logger = (Logger)LoggerFactory.getLogger(ShareMarket.class.getSimpleName());
    
    private ShareMarketMaker marketMaker;       // the market maker for this market (sets the prices based on orders)
    private String marketId;                    // an identifier for the market
    private HashMap<String, Trader> traders;    // traders in the market

    public class Share {
        public DoubleTimeSeries prices;
        public DoubleTimeSeries logReturns;
        public DoubleTimeSeries fundValues;
//        public HashMap<String, Double> currentCovariances;    // covariance with all the shares in the market (--> one component is the variance of the share)
        public double liquidity;
        
        public Share() {
            prices = new DoubleTimeSeries();
            logReturns = new DoubleTimeSeries();
            fundValues = new DoubleTimeSeries();
            liquidity = 0;
        }
    }
    
    private HashMap<String, Share> shares;    // prices and liquidity of the shares traded in the market
    private HashMap<String, DoubleTimeSeries> spreads;    // spreads between Asset_1 and the rest of assets traded in the market
    private HashMap<String, DataGenerator> fundValueGen;       // data generators for the generic fundamental value process for the different assets
    
    private double confLevelVar;   // confidence level of the VaR model, as set by regulators
    private double confLevelEs;    // confidence level of the ES model, as set by regulators
    
    
    /**
     * @param id an identifier for this market
     * @param scheduler 
     */
    public ShareMarket(String id, ShareMarketMaker shareMarketMaker) {
        
        marketMaker = shareMarketMaker;
        marketMaker.enterMarket(this);
        
        traders = new HashMap<String, Trader>();
        shares = new HashMap<String, Share>();
        spreads = new HashMap<String, DoubleTimeSeries>();
        fundValueGen = new HashMap<String, DataGenerator>();
        
        setAllInitValues(0);
        
        confLevelVar = 0;
        confLevelEs = 0;
        
        logger.trace("CREATED: " + this.toString());
    }
    
    /**
     * @return the liquidity for share secId
     */
    public double getLiquidity(String secId) {
        
        Assertion.assertStrict(isShareTraded(secId), Level.ERR, "Share with secId '" + secId + "' does not exist");
        
        return shares.get(secId).liquidity;
    }

    /**
     * @param liquidity the liquidity for share SecId
     */
    public void setLiquidity(String secId, double liquidity) {
        
        Assertion.assertStrict(isShareTraded(secId), Level.ERR, "Share with secId '" + secId + "' does not exist");

        shares.get(secId).liquidity = liquidity;
    }
  
    /**
     * @return the prices for share secId
     */
    public DoubleTimeSeries getPrices(String secId) {
        
        Assertion.assertStrict(isShareTraded(secId), Level.ERR, "Share with secId '" + secId + "' does not exist");

        return shares.get(secId).prices;
    }
    
    /**
     * @return the log-returns for share secId
     */
    public DoubleTimeSeries getLogReturns(String secId) {
        
        Assertion.assertStrict(isShareTraded(secId), Level.ERR, "Share with secId '" + secId + "' does not exist");

        return shares.get(secId).logReturns;
    }

    /**
     * @return the spread secId_1 - secId_2
     */
    public DoubleTimeSeries getSpreads(String secId_1, String secId_2) {
        
        Assertion.assertStrict(isShareTraded(secId_1), Level.ERR, "Share with secId '" + secId_1 + "' does not exist");
        Assertion.assertStrict(isShareTraded(secId_2), Level.ERR, "Share with secId '" + secId_2 + "' does not exist");

        return spreads.get(secId_1 + "_" + secId_2);
    }
    
    /**
     * @return the generic fundamental values for share secId
     */
    public DoubleTimeSeries getFundValues(String secId) {
        
        Assertion.assertStrict(isShareTraded(secId), Level.ERR, "Share with secId '" + secId + "' does not exist");

        return shares.get(secId).fundValues;
    }

    /**
     * @return the market maker
     */
    public ShareMarketMaker getMarketMaker() {
        
        return marketMaker;
    }
    
    /**
     * @param fundValueGen the generator of the generic fundamental value process for a given asset 
     */
    public void setFundValueGenerator(String assetId, DataGenerator fundValueGen) {
        this.fundValueGen.put(assetId, fundValueGen);
    }
    
    /**
     * @return the generator of the generic fundamental value process for a given asset
     */
    public DataGenerator getFundValueGenerator(String assetId) {
        return fundValueGen.get(assetId);
    }
    
    
    /**
     * Get the market identifier
     * 
     * @return the identifier
     */
    public String getId() {
        return marketId;
    }
    
    
    /**
     * Set the market identifier
     * 
     * @param id the identifier
     */
    public void setId(String id) {
        marketId = id;
    }
    
    /**
     * @return the confidence level of the VaR model
     */
    public double getConfLevelVar() {
        
        return confLevelVar;
    }
    
    /**
     * @param confLevelVar the confidence level for VaR model
     */
    public void setConfLevelVar(double confLevel) {
        
        confLevelVar = confLevel;
    }

    /**
     * @return the confidence level of the ES model
     */
    public double getConfLevelEs() {
        
        return confLevelEs;
    }
    
    /**
     * @param confLevelVar the confidence level for ES model
     */
    public void setConfLevelEs(double confLevel) {
        
        confLevelEs = confLevel;
    }

    
    /**
     * Set the same fund value at time t = 0 for all shares. This method is
     * called by the constructor to ensure that there is an initial value.
     * Users should call this method to initialise fundamental values to the 
     * desired values.
     * 
     * @param value_t_0 the generic fundamental value at t = 0
     */
    public void setAllInitValues(double value_t_0) {
    	
    	ArrayList<String> secIds = marketMaker.getSecIds();
        
        for (String secId : secIds) {
            ShareMarket.Share share = shares.get(secId);
            share.fundValues.add(0, value_t_0);
        }
    }

    /**
     * Set the fund value at time t = 0 for the share secId. This method allows
     * users to set the initial fundamental value of share secId. 
     * 
     * @param value_t_0 the generic fundamental value at t = 0
     */
    public void setInitValue(String secId, double value_t_0) {
        Assertion.assertStrict(shares.containsKey(secId), Level.ERR, "No share with secId = " + secId + " traded in the market.");
        shares.get(secId).fundValues.add(0, value_t_0);
    }
    
    /**
     * Set the log returns at time t = 0 for the share secId. This method allows
     * users to set the log return of share secId. 
     * 
     * @param logReturn_t_0 the log return at t = 0
     */
    public void setInitLogReturn(String secId, double logReturn_t_0) {
        Assertion.assertStrict(shares.containsKey(secId), Level.ERR, "No share with secId = " + secId + " traded in the market.");
        shares.get(secId).logReturns.add(0, logReturn_t_0);
    }
    

    /**
     * @return current tick of the simulation, as stored in the schedule
     */
    public long currentTick() {
        
        return WorldClock.currentTick();
    }
    
    /**
     * Add a trader to the market
     *  
     * @param numTraders
     */
    public void addTrader(Trader trader) {
        
        trader.enterMarket(this);
        traders.put(trader.getLabel(), trader);
    }
    
    /**
     * Add a new share to the market and create a corresponding price time series
     */
    public void addShare(String secId) {
        
        Assertion.assertStrict(!isShareTraded(secId), Level.ERR, "Share with secId '" + secId + "' already exists in the market");
        
        Share share = new Share();
        share.prices = new DoubleTimeSeries();
        share.logReturns = new DoubleTimeSeries();
        
        shares.put(secId, share);
        
    }
    
    /**
     * Add new shares to the market and create corresponding time series
     */
    public void addShares(String... secIds) {
        
        for (String secId : secIds) {
            addShare(secId);
        }
    }
    
    /**
     * Add a new spread to the market and create a corresponding price time series
     */
    public void addSpread(String spreadId) {
        
        Assertion.assertStrict(!isSpreadTraded(spreadId), Level.ERR, "Spread with spreadId '" + spreadId + "' already exists in the market");
        
        DoubleTimeSeries spread = new DoubleTimeSeries();
        
        spreads.put(spreadId, spread);
    }
    
    /**
     * Add new spreads to the market and create corresponding time series
     */
    public void addSpreads(String... spreadIds) {
        
        for (String spreadId : spreadIds) {
            addSpread(spreadId);
        }
    }
    
    /**
     * Get all shares traded in the market
     */
    public HashMap<String, Share> getTradedShares() {
        return shares;
    }
    
    /**
     * Check if a share is traded in the market
     */
    public boolean isShareTraded(String secId) {
        return shares.containsKey(secId);
    }
    
    /**
     * Check if a spread is traded in the market
     */
    public boolean isSpreadTraded(String spreadId) {
        return spreads.containsKey(spreadId);
    }
    
    /**
     * @return traders the hash map containing the traders
     */
    protected HashMap<String, Trader> getTraders() {
        return traders;
    }
    
    /**
     * Get the trader with name traderId
     */
    public Trader getTrader(String traderId) {
        
        Assertion.assertStrict(traders.containsKey(traderId), Level.ERR, "Trader with id '" + traderId + "' does not exist in market ");

        return traders.get(traderId);
    }
       
    public String toString() {
        return "TrendValue-Market";
    }

}
