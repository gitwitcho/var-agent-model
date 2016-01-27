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

import info.financialecology.finance.abm.model.LPLSEqnModel.Results;
import info.financialecology.finance.abm.simulation.LPLSEqnParams;
import info.financialecology.finance.abm.simulation.LPLSEqnParams.Sequence;
import info.financialecology.finance.utilities.abm.AbstractSimulator;
import info.financialecology.finance.utilities.datastruct.Datastore;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;

import java.util.ArrayList;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


import cern.colt.list.DoubleArrayList;
import cern.jet.random.Normal;
import cern.jet.random.Uniform;


/**
 * @author Gilbert Peffer
 *
 */
public class LPLSEqnSimulator extends AbstractSimulator {
    private LPLSEqnParams params;
    private LPLSEqnModel model = null;
    
    // Market
    Normal distLogPriceNoise;       // noise distribution for log price process
    
    // Fundamental trader
    Normal distRefValue;            // noise distribution for reference process of log value
    Uniform distOffsetValue;        // distribution for trader-specific value offset
    Uniform distEntryThreshFund;    // distribution of trader-specific entry threshold
    Uniform distExitThreshFund;     // distribution of trader-specific exit threshold
    
    // Technical trader
    Uniform distDelayTech;          // distribution of trader-specific time horizon for technical strategy
    Uniform distEntryThreshTech;    // distribution of trader-specific entry threshold
    Uniform distExitThreshTech;     // distribution of trader-specific exit threshold

    private static final Logger logger = (Logger)LoggerFactory.getLogger(FJAbmSimulator.class.getSimpleName());

    // Agents
    
//    class FundTrader {
//        FundTrader () {}
//        public double position;
//        public double order;
//        public double valueOffset;
//        public double entryThresh;
//        public double exitThresh;
//        public double capFac;
//    }
//    
//    class TechTrader {
//        TechTrader () {}
//        public double position;
//        public double order;
//        public int    delay;
//        public double entryThresh;
//        public double exitThresh;
//        public double capFac;
//    }
//    
//    ArrayList<FundTrader>   fundTraders = new ArrayList<FundTrader>();      // array of fundamental traders 
//    ArrayList<TechTrader>   techTraders = new ArrayList<TechTrader>();      // array of technical traders
//    
//    public enum Results implements ResultEnum {
//        LOG_PRICES (DoubleTimeSeries.class),
//        LOG_REFVALUES (DoubleTimeSeries.class),
//        PRICE_NOISE (DoubleTimeSeries.class),
//        ORDER_FUND (DoubleTimeSeries.class),
//        ORDER_TECH (DoubleTimeSeries.class),
//        VOLUME (DoubleTimeSeries.class);
//
//        private final Type mType;
//
//        Results(Type type) {
//            this.mType = type;
//        }
//
//        public Type type() { return mType; }
//    }
    
    public LPLSEqnSimulator(LPLSEqnParams params) {
        logger.trace("Entering the LPLSEquationSimulator()");
        
        this.params = params;
        
        model = new LPLSEqnModel(this, params);
        
//        Datastore.logAllResults(Results.class);
//        tsLogPrices = Datastore.getResult(DoubleTimeSeries.class, Results.LOG_PRICES);
//        tsLogRefValues = Datastore.getResult(DoubleTimeSeries.class, Results.LOG_REFVALUES);
//        tsPriceNoise = Datastore.getResult(DoubleTimeSeries.class, Results.PRICE_NOISE);
//        tsOrderFund = Datastore.getResult(DoubleTimeSeries.class, Results.ORDER_FUND);
//        tsOrderTech = Datastore.getResult(DoubleTimeSeries.class, Results.ORDER_TECH);
//        tsVolume = Datastore.getResult(DoubleTimeSeries.class, Results.VOLUME);
//        
        
        // #############################################
        //
        // TODO RANDOM NUMBER GENERATION NEEDS TO BE ADAPTED TO THE NEW RANDOMGENERATORPOOL
        //
        // #############################################

//        // Market
//        distLogPriceNoise  = RandomHelper.createNormal(params.priceNoiseMu, params.priceNoiseSigma);
//
//        // Fundamental traders
//        distRefValue         = RandomHelper.createNormal(params.refValueMu, params.refValueSigma); 
//        distOffsetValue     = RandomHelper.createUniform(params.offsetValueMin, params.offsetValueMax);
//        distEntryThreshFund = RandomHelper.createUniform(params.TMinFund, params.TMaxFund);
//        distExitThreshFund  = RandomHelper.createUniform(params.tauMinFund, params.tauMaxFund);
//        
//        // Technical traders
//        distDelayTech     = RandomHelper.createUniform(params.delayMin, params.delayMax);
//        distEntryThreshTech = RandomHelper.createUniform(params.TMinTech, params.TMaxTech);
//        distExitThreshTech  = RandomHelper.createUniform(params.tauMinTech, params.tauMaxTech);
//        
//        // Generate fundamental trader population
//        for (int j = 0; j < params.numFundTraders; j++) {
//            FundTrader fundTrader = new FundTrader();
//            fundTrader.position = 0.0;
//            fundTrader.order = 0.0;
//            fundTrader.valueOffset = distOffsetValue.nextDouble();
//            fundTrader.entryThresh = distEntryThreshFund.nextDouble();
//            fundTrader.exitThresh = distExitThreshFund.nextDouble();
//
//            if (params.constCapFac)
//                fundTrader.capFac = 4 * params.aFund;
//            else
//                fundTrader.capFac = 1.6 * params.aFund * (fundTrader.entryThresh - fundTrader.exitThresh);
//            
//            fundTraders.add(fundTrader);
//        }
//        
//        // Generate technical trader population
//        for (int j = 0; j < params.numTechTraders; j++) {
//            TechTrader techTrader = new TechTrader();
//            techTrader.position = 0.0;
//            techTrader.order = 0.0;
//            techTrader.delay = distDelayTech.nextInt(); // BUG: the value offset ought to be constant during the whole experiment
//            techTrader.entryThresh = distEntryThreshTech.nextDouble();  // idem
//            techTrader.exitThresh = distExitThreshTech.nextDouble();    // idem
//
//            if (params.constCapFac)
//                techTrader.capFac = 4 * params.aTech;
//            else
//                techTrader.capFac = 1.6 * params.aFund * (techTrader.entryThresh - techTrader.exitThresh);  // BUG: should use techTrader.entryThrash and techTraderexitThresh
//            
//            techTraders.add(techTrader);
//        }
    }
    
    public LPLSEqnModel getModel() {
        return model;
    }
    
    private void warmupSimulation() {
        DoubleTimeSeriesList tsLogPrices = Datastore.getResult(DoubleTimeSeriesList.class, Results.LOG_PRICES);
        DoubleTimeSeriesList tsLogRefValues = Datastore.getResult(DoubleTimeSeriesList.class, Results.LOG_REFVALUES);
        DoubleTimeSeriesList tsOrderFUND = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_VALUE);
        DoubleTimeSeriesList tsOrderLS = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_LONGSHORT);
        DoubleTimeSeriesList tsOrderTREND = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_TREND);
//        DoubleTimeSeriesList storedNetPosMF = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_MF);
//        DoubleTimeSeriesList storedNetPosHF = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_HF);
//        DoubleTimeSeriesList storedNetPosB = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_B);
        DoubleTimeSeriesList storedNetPosFUND = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_VALUE);
        DoubleTimeSeriesList storedNetPosTREND = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_TREND);
        DoubleTimeSeriesList storedNetPosLS = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_LS);
        DoubleTimeSeriesList tsVolume = Datastore.getResult(DoubleTimeSeriesList.class, Results.VOLUME);
        DoubleTimeSeriesList tsTotalTrades = Datastore.getResult(DoubleTimeSeriesList.class, Results.TOTAL_TRADES);
//        DoubleTimeSeriesList storedProfitAndLoss = Datastore.getResult(DoubleTimeSeriesList.class, Results.PROFIT_AND_LOSS);
        DoubleTimeSeriesList storedPaperProfitAndLoss = Datastore.getResult(DoubleTimeSeriesList.class, Results.PAPER_PROFIT_AND_LOSS);
        DoubleTimeSeriesList storedRealisedProfitAndLoss = Datastore.getResult(DoubleTimeSeriesList.class, Results.REALISED_PROFIT_AND_LOSS);
//        DoubleTimeSeriesList storedProfitAndLossStrategy = Datastore.getResult(DoubleTimeSeriesList.class, Results.PROFIT_AND_LOSS_STRATEGY);
//        DoubleTimeSeriesList storedPaperProfitAndLossStrategy = Datastore.getResult(DoubleTimeSeriesList.class, Results.PAPER_PROFIT_AND_LOSS_STRATEGY);
//        DoubleTimeSeriesList storedRealisedProfitAndLossStrategy = Datastore.getResult(DoubleTimeSeriesList.class, Results.REALISED_PROFIT_AND_LOSS_STRATEGY);
        DoubleTimeSeriesList storedTotalCash= Datastore.getResult(DoubleTimeSeriesList.class, Results.CASH);
        
        ArrayList<DoubleArrayList> prices_0 = params.getDoubleNumberSequence(Sequence.PRICE_0);
        
        for (int i = 0; i < params.nAssets; i++) {
            tsLogPrices.get(i).add(Math.log(prices_0.get(i).get(0)));
            tsLogRefValues.get(i).add(Math.log(prices_0.get(i).get(0)));
            tsOrderFUND.get(i).add(0);
            tsOrderLS.get(i).add(0);
            tsOrderTREND.get(i).add(0);
//            storedNetPosMF.get(i).add(0);
//            storedNetPosHF.get(i).add(0);
//            storedNetPosB.get(i).add(0);
            storedNetPosFUND.get(i).add(0);
            storedNetPosTREND.get(i).add(0);
            storedNetPosLS.get(i).add(0);
            tsVolume.get(i).add(0);
            tsTotalTrades.get(i).add(0);
        }
        
        for (int i = 0; i < 3; i++) {    // per agent type {MF, HF, B}
//            storedProfitAndLoss.get(i).add(0);
            storedPaperProfitAndLoss.get(i).add(0);
            storedRealisedProfitAndLoss.get(i).add(0);
        }

        for (int i = 0; i < 3; i++) {    // per strategy type {FUND, TREND, LS}
//            storedProfitAndLossStrategy.get(i).add(0);
//            storedPaperProfitAndLossStrategy.get(i).add(0);
//            storedRealisedProfitAndLossStrategy.get(i).add(0);
        }

        // Market
//        double noise;
//        double logPrice_0 = Math.log(params.price_0); // log price at time t=0
//        double logPrice = logPrice_0;
//        tsLogPrices.add(0, logPrice_0);
//        
//        // Fundamental traders        
//        double logValue_0 = logPrice_0; // log value at time t=0
//        
//        for (int j = 1; j <= params.delayMax; j++) {
//            noise = distLogPriceNoise.nextDouble();
//            tsPriceNoise.add(j, noise);
//            logPrice = tsLogPrices.getValue(j - 1) + noise; 
//            tsLogPrices.add(j, logPrice);
//        }
//        
//        // Log value of reference process at t = delayMax
//        double logRefValue = logValue_0;
//        tsLogRefValues.add(0, logRefValue);
//
//        for (int j = 1; j <= params.delayMax; j++) {
//            logRefValue += distRefValue.nextDouble();
//            tsLogRefValues.add(j, logRefValue);
//        }
//        
//        // Orders in warm-up period are set to zero
//        for (int j = 0; j <= params.delayMax; j++) {
//            tsOrderFund.add(j, 0.0);
//            tsOrderTech.add(j, 0.0);
//            tsVolume.add(j, 0.0);
//        }        

        /**
         * Setting up traders
         */
       
//        // Initialise fundamental traders
//        for (int j = 0; j < params.numFundTraders; j++) {
//            FundTrader fundTrader = fundTraders.get(j);
//            fundTrader.position = 0.0;
//            fundTrader.order = 0.0;
//        }
//        
//        // Initialise technical traders
//        for (int j = 0; j < params.numTechTraders; j++) {
//            TechTrader techTrader = techTraders.get(j);
//            techTrader.position = 0.0;
//            techTrader.order = 0.0;
//        }
    }

    /** 
     * Conduct one simulation run of nTicks steps
     **/
    @Override
    public void run() {
        logger.trace("Entry - run()");
        
        warmupSimulation();
        
        /**
         *      SIMULATION 
         */
        for (int t = 1; t <= params.nTicks; t++) {            
            model.step();
            incrementTick();
        }

    }

}
