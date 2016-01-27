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

import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;



/**
 * A central place that pulls in the different resources and that market participants can access and use
 * 
 * @author Gilbert Peffer
 *
 */
public class FJMarket {
    private FJAbmSimulator simulator;      // pointer to the FJSimulator object (e.g. to get tick count)
    
    private double liquidity;           // the liquidity of the stock
    private FJMarketMaker marketMaker;    // The market maker for this market
    private Map<String, FJFundamentalTrader> fundamentalTraders;     // List of the fundamental traders
    private Map<String, FJTechnicalTrader> technicalTraders;       // List of the technical traders
    
    private static final Logger logger = (Logger)LoggerFactory.getLogger(FJMarket.class.getSimpleName());

    public FJMarket(FJAbmSimulator simulator) {
        this.simulator = simulator;
        marketMaker = new FJMarketMaker();
        marketMaker.setMarket(this);            // set pointer to this market
        simulator.getScheduler().schedule(marketMaker);
        fundamentalTraders = new HashMap<String, FJFundamentalTrader>();
        technicalTraders = new HashMap<String, FJTechnicalTrader>();

        logger.trace("CREATED: " + this.toString());
    }
    
    /**
     * @return the liquidity
     */
    public double getLiquidity() {
        return liquidity;
    }

    /**
     * @param liquidity the liquidity to set
     */
    public void setLiquidity(double liquidity) {
        this.liquidity = liquidity;
    }
    
    public FJMarketMaker getMarketMaker() {
        return marketMaker;
    }
    
    /**
     * @return current tick of the simulation, as stored in the schedule
     */
    public long getCurrentTick() {
        return simulator.currentTick();
    }
    
    /**
     * Add a trader to the market
     *  
     * @param numTraders
     */
    public void addTrader(Agent trader) {
        
        if (trader.getClass() == FJFundamentalTrader.class) {
            FJFundamentalTrader ft = (FJFundamentalTrader) trader;
            ft.setMarket(this);
            fundamentalTraders.put(trader.toString(), ft);
        }
        else if (trader.getClass() == FJTechnicalTrader.class) {
            ((FJTechnicalTrader) trader).setMarket(this);
            technicalTraders.put(trader.toString(), (FJTechnicalTrader) trader);
        }
    }
    
    /**
     * @return fundamentalTraders the hash map containing the fundamental traders
     */
    protected Map<String, FJFundamentalTrader> getFundamentalTraders() {
        return fundamentalTraders;
    }
    
    /**
     * @return technicalTraders the hash map containing the technical traders
     */
    protected Map<String, FJTechnicalTrader> getTechnicalTraders() {
        return technicalTraders;
    }
    
    public String toString() {
        return "FJ-Market";
    }

}
