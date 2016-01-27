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

import info.financialecology.finance.abm.model.agent.FJFundamentalTrader;
import info.financialecology.finance.abm.model.agent.FJTechnicalTrader;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.abm.AbstractSimulator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import cern.jet.random.*;

import repast.simphony.engine.schedule.DefaultScheduleFactory;
import repast.simphony.engine.schedule.ISchedule;


/**
 * @author Gilbert Peffer
 *
 */
public class FJAbmSimulator extends AbstractSimulator {
    
    private ISchedule scheduler;                // main scheduler for agent and other actions
    private FJMarket market;                    // The Farmer-Joshi stock market
    
    private static Uniform distOffsetValue = null;     // distribution of fixed offset added to the value reference process - different for each trader 

    private static final Logger logger = (Logger)LoggerFactory.getLogger(FJAbmSimulator.class.getSimpleName());

    public FJAbmSimulator() {
        logger.trace("Entry - FJSimulator()");
        
        // TODO reset static variables in agents
        
        DefaultScheduleFactory factory = new DefaultScheduleFactory();  // TODO move this to to a new class AbstractABMSimulator
        scheduler = factory.createSchedule();
        market = new FJMarket(this);        
    }
        
    /**
     * Set/reset static variables
     */
    public static void setAllStatics() {

        FJAbmSimulator.distOffsetValue = null;
    }
    
    /**
     * @param distOffsetValue distribution of offset values to set
     */
    public static void setDistOffsetValues(Uniform distOffsetValues) {
        FJAbmSimulator.distOffsetValue = distOffsetValues;
    }
    
    /**
     * Create fundamental traders
     *  
     * @param numTraders
     */
    public void createFJFundamentalTraders(int numTraders) {
        FJFundamentalTrader trader = null;
        
        for (int i = 0; i < numTraders; i++) {       // TODO Catch error: scheduler has to be set first
            trader = new FJFundamentalTrader();
            market.addTrader(trader);
            scheduler.schedule(trader);
        }
    }
    
    /**
     * Create technical traders
     *  
     * @param numTraders
     */
    public void createFJTechnicalTraders(int numTraders) {
        FJTechnicalTrader trader = null;
        
        for (int i = 0; i < numTraders; i++) {       // TODO Catch error: scheduler has to be set first
            trader = new FJTechnicalTrader();
            market.addTrader(trader);
            scheduler.schedule(trader);
        }
    }
    
    /**
     * Initialise fundamental traders
     *  
     * @param capitalFactor a constant capital factor
     */
    public void initialiseFJFundamentalTraders(double capitalFactor,
                                             double initCash,
                                             double initStock,
                                             Normal distRefValue) {    // TODO add distOffsetValue as a param
        logger.trace("Entry - initialiseFundamentalTraders(double capitalFactor)");

        if (market.getFundamentalTraders().isEmpty())
            throw new IllegalStateException("there are no fundamental traders in the market");
        
        FJFundamentalTrader.setDistributionRefValue(distRefValue);

        for (FJFundamentalTrader trader : market.getFundamentalTraders().values()) {
            trader.setCapitalFactor(capitalFactor);
            trader.setOffsetValue(distOffsetValue.nextDouble());
            trader.setInitCash(initCash);
            trader.setInitStock(initStock);            
        }
    }
    
    /**
     * Initialise technical traders
     *  
     * @param capitalFactor a constant capital factor
     */
    public void initialiseFJTechnicalTraders(double capitalFactor,
                                           double initCash,
                                           double initStock) {
        logger.trace("Entry - initialiseTechnicalTraders(double capitalFactor)");

        if (market.getTechnicalTraders().isEmpty())
            throw new IllegalStateException("there are no technical traders in the market");

        for (FJTechnicalTrader trader : market.getTechnicalTraders().values()) {
            trader.setCapitalFactor(capitalFactor);
            trader.setInitCash(initCash);
            trader.setInitStock(initStock);
        }
    }    
    
    /**
     * Initialise market maker
     *  
     * @param initPrice the price at the start of the simulation
     */
    public void initialiseFJMarketMaker(double initPrice) {
        logger.trace("Entry - initialiseMarketMaker(double initPrice)");
        
        market.getMarketMaker().setInitPrice(initPrice);
    }

    /**
     * @return the liquidity
     */
    public double getLiquidity() {  // we use pass through functions to implement consistency checks at the simulator level, rather than giving direct access e.g. to FJMarket
        return market.getLiquidity();
    }

    /**
     * @param liquidity the liquidity to set
     */
    public void setLiquidity(double liquidity) {
        market.setLiquidity(liquidity);
    }
    
//    /**
//     * @param cfTechnical the capital factor of fundamental traders
//     */
//    public void setCapFacTechTr(double cfactor) {
//        market.setLiquidity(cfactor);
//    }
    
    /**
     * @return schedule
     */
    protected ISchedule getScheduler() {
        return scheduler;
    }
    
    /**
     * Get current tick and ensure that there are no gaps in the scheduler
     */
    public long currentTick() {
        long currentTick = super.currentTick();
        
        Assertion.assertStrict(super.currentTick() == (long) scheduler.getTickCount(), Level.ERR, "Scheduler has gaps because tick count is out of sync");
        
        return currentTick;
    }
    
    /**
     * Execute the simulation 
     */
    public void run() {
        logger.trace("Entry - run()");
               
        while (currentTick() < nTicks) {
            scheduler.execute();
            incrementTick();            
        }
    }
}
