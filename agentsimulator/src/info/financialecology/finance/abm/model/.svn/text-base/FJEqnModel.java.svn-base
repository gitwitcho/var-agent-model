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

import java.lang.reflect.Type;
import java.util.ArrayList;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import repast.simphony.random.RandomHelper;

import cern.jet.random.Normal;
import cern.jet.random.Uniform;

import info.financialecology.finance.abm.simulation.FJEqnParams;
import info.financialecology.finance.utilities.abm.AbstractSimulator;
import info.financialecology.finance.utilities.datastruct.Datastore;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.ResultEnum;

/**
 * 
 * FJEqnModel is ...
 * 
 * @author Gilbert Peffer
 *
 */
public class FJEqnModel {
    private static final Logger logger = (Logger)LoggerFactory.getLogger(FJEqnModel.class.getSimpleName());

    private AbstractSimulator simulator;
    private FJEqnParams params;
    
    
    /**
     * Declaring labels for the results we want to log in the datastore
     */
    public enum Results implements ResultEnum {
        LOG_PRICES (DoubleTimeSeries.class),
        LOG_REFVALUES (DoubleTimeSeries.class),
        PRICE_NOISE (DoubleTimeSeries.class),
        ORDER_FUND (DoubleTimeSeries.class),
        ORDER_TECH (DoubleTimeSeries.class),
        VOLUME (DoubleTimeSeries.class);

        private final Type mType;

        Results(Type type) {
            this.mType = type;
        }

        public Type type() { return mType; }
    }
    
    /*
     *  Data storage
     */
    private DoubleTimeSeries tsLogPrices;
    private DoubleTimeSeries tsLogRefValues;
    private DoubleTimeSeries tsPriceNoise;
    private DoubleTimeSeries tsOrderValueInv;
    private DoubleTimeSeries tsOrderTrend;
    private DoubleTimeSeries tsVolume;
    
    /*
     * Random distributions
     */
    
    // Market
    Normal distLogPriceNoise;       // noise distribution for log price process
    
    // Value investor
    Normal distRefValue;            // noise distribution for reference process of log value
    Uniform distOffsetValue;        // distribution for trader-specific value offset
    Uniform distEntryThreshFund;    // distribution of trader-specific entry threshold
    Uniform distExitThreshFund;     // distribution of trader-specific exit threshold
    
    // Trend follower
    Uniform distDelayTech;          // distribution of trader-specific time horizon for technical strategy
    Uniform distEntryThreshTech;    // distribution of trader-specific entry threshold
    Uniform distExitThreshTech;     // distribution of trader-specific exit threshold

    /**
     *  Declaring the two agent types: value investors and trend followers
     */
    class ValueInvestor {
        ValueInvestor () {}
        public double position;
        public double order;
        public double valueOffset;
        public double entryThresh;
        public double exitThresh;
        public double capFac;
    }
    
    class TrendFollower {
        TrendFollower () {}
        public double position;
        public double order;
        public int    delay;
        public double entryThresh;
        public double exitThresh;
        public double capFac;
    }
    
    ArrayList<ValueInvestor>   valueInvestors = new ArrayList<ValueInvestor>();      // array of fundamental traders 
    ArrayList<TrendFollower>   trendFollowers = new ArrayList<TrendFollower>();      // array of technical traders
    
    
    /**
     *  Constructor
     * 
     * @param simulator
     * @param params
     */
    public FJEqnModel(AbstractSimulator simulator, FJEqnParams params) {
        logger.trace("CONSTUCTOR");
        
        this.params = params;
        this.simulator = simulator;
        
        /*
         *  Create storage space for time series of results
         */
        Datastore.logAllResults(Results.class);
        tsLogPrices = Datastore.getResult(DoubleTimeSeries.class, Results.LOG_PRICES);
        tsLogRefValues = Datastore.getResult(DoubleTimeSeries.class, Results.LOG_REFVALUES);
        tsPriceNoise = Datastore.getResult(DoubleTimeSeries.class, Results.PRICE_NOISE);
        tsOrderValueInv = Datastore.getResult(DoubleTimeSeries.class, Results.ORDER_FUND);
        tsOrderTrend = Datastore.getResult(DoubleTimeSeries.class, Results.ORDER_TECH);
        tsVolume = Datastore.getResult(DoubleTimeSeries.class, Results.VOLUME);
        
        // Market
        distLogPriceNoise  = RandomHelper.createNormal(params.priceNoiseMu, params.priceNoiseSigma);

        // Fundamental traders
        distRefValue        = RandomHelper.createNormal(params.refValueMu, params.refValueSigma); 
        distOffsetValue     = RandomHelper.createUniform(params.offsetValueMin, params.offsetValueMax);
        distEntryThreshFund = RandomHelper.createUniform(params.TMinValueInv, params.TMaxValueInv);
        distExitThreshFund  = RandomHelper.createUniform(params.tauMinValueInv, params.tauMaxValueInv);
        
        // Technical traders
        distDelayTech     = RandomHelper.createUniform(params.delayMin, params.delayMax);
        distEntryThreshTech = RandomHelper.createUniform(params.TMinTrend, params.TMaxTrend);
        distExitThreshTech  = RandomHelper.createUniform(params.tauMinTrend, params.tauMaxTrend);        

        // Generate fundamental trader population
        for (int j = 0; j < params.numValueInvestors; j++) {
            ValueInvestor valueInvestor = new ValueInvestor();
            valueInvestor.position = 0.0;
            valueInvestor.order = 0.0;
            valueInvestor.valueOffset = distOffsetValue.nextDouble();
            valueInvestor.entryThresh = distEntryThreshFund.nextDouble();
            valueInvestor.exitThresh = distExitThreshFund.nextDouble();

            if (params.constCapFac)
                valueInvestor.capFac = 4 * params.aValueInv;
            else
                valueInvestor.capFac = 1.6 * params.aValueInv * (valueInvestor.entryThresh - valueInvestor.exitThresh);
            
            valueInvestors.add(valueInvestor);
        }
        
        // Generate technical trader population
        for (int j = 0; j < params.numTrendFollowers; j++) {
            TrendFollower trendFollower = new TrendFollower();
            trendFollower.position = 0.0;
            trendFollower.order = 0.0;
            trendFollower.delay = distDelayTech.nextInt();
            trendFollower.entryThresh = distEntryThreshTech.nextDouble();
            trendFollower.exitThresh = distExitThreshTech.nextDouble();

            if (params.constCapFac)
                trendFollower.capFac = 4 * params.aTrend;
            else
                trendFollower.capFac = 1.6 * params.aValueInv * (trendFollower.entryThresh - trendFollower.exitThresh);  // BUG: should use techTrader.entryThrash and techTraderexitThresh
            
            trendFollowers.add(trendFollower);
        }
    }
        

    /** 
     * Execute one simulation step
     **/
    public void step() {
        double noise, logPrice, logRefValue;        
        int t = (int) simulator.currentTick();

        if (t <= params.delayMax) {     // warm-up phase
            if (t == 0) {
                tsLogPrices.add(0, Math.log(params.price_0));
                tsLogRefValues.add(0, Math.log(params.price_0));

                // Initialise fundamental traders
                for (int j = 0; j < params.numValueInvestors; j++) {
                    ValueInvestor valueInvestor = valueInvestors.get(j);
                    valueInvestor.position = 0.0;
                    valueInvestor.order = 0.0;
                }
                
                // Initialise technical traders
                for (int j = 0; j < params.numTrendFollowers; j++) {
                    TrendFollower trendFollower = trendFollowers.get(j);
                    trendFollower.position = 0.0;
                    trendFollower.order = 0.0;
                }
            } else {
                noise = distLogPriceNoise.nextDouble();
                tsPriceNoise.add(t, noise);
                logPrice = tsLogPrices.getValue(t - 1) + noise; 
                tsLogPrices.add(t, logPrice);

                logRefValue = tsLogRefValues.getValue(t - 1) + distRefValue.nextDouble();
                tsLogRefValues.add(t, logRefValue);
            }
            
            tsOrderValueInv.add(t, 0.0);
            tsOrderTrend.add(t, 0.0);
            tsVolume.add(t, 0.0);
        } else {
            /**
             * Initialising positions and orders before each simulation run. The other
             * parameters, in particular the ones related to thresholds, delay window
             * etc. are kept constant over the experiment.
             */
           
            double totalOrderFund = 0.0;
            double totalOrderTech = 0.0;
            double totalVolume = 0.0;
            
            logRefValue = tsLogRefValues.getValue(t - 1) + distRefValue.nextDouble();   // update reference value for this time step 
            tsLogRefValues.add(t, logRefValue);
            
            // Orders from fundamental traders
            for (int k = 0; k < params.numValueInvestors; k++) {
                ValueInvestor fund = (ValueInvestor) valueInvestors.get(k);
                double logValueFund = logRefValue + fund.valueOffset;  // value of asset at time t for trader k
                double diff = logValueFund - tsLogPrices.getValue(t - 1);
                double oldPosition = fund.position;
                
                if (Math.abs(diff) > fund.entryThresh) {
                    fund.position = fund.capFac * diff;
                } 
                else if (Math.abs(diff) < fund.exitThresh) {
                    fund.position = 0.0;
                }
                
                fund.order = fund.position - oldPosition;
                totalOrderFund += fund.order;
                totalVolume += Math.abs(fund.order);
            }
            
            // Orders from technical traders
            for (int k = 0; k < params.numTrendFollowers; k++) {
                TrendFollower tech = (TrendFollower) trendFollowers.get(k);
                double priceDiff = tsLogPrices.getValue(t - 1) - tsLogPrices.getValue(t - tech.delay);  // Slight difference in index to Matlab model
                double oldPosition = tech.position;
                
                if (Math.abs(priceDiff) > tech.entryThresh) {
                    tech.position = tech.capFac * priceDiff;
                }
                else if (Math.abs(priceDiff) < tech.exitThresh) {
                    tech.position = 0.0;
                }
                
                tech.order = tech.position - oldPosition;
                totalOrderTech += tech.order;
                totalVolume += Math.abs(tech.order);
            }
            
            // Price dynamics
            noise = distLogPriceNoise.nextDouble();
            double logPrice_t = tsLogPrices.getValue(t - 1) + (1 / params.liquidity) * (totalOrderFund + totalOrderTech) + noise;
            
//            logger.trace("Total orders: {}", totalOrderFund + totalOrderTech);
//            logger.trace("Log price: {}", logPrice_t);
//            logger.trace("Price: {}", Math.exp(logPrice_t));

            tsLogPrices.add(t, logPrice_t);
            tsPriceNoise.add(t, noise);
            tsOrderValueInv.add(t, totalOrderFund);
            tsOrderTrend.add(t, totalOrderTech);
            tsVolume.add(t, totalVolume);
        }
    }    
}
