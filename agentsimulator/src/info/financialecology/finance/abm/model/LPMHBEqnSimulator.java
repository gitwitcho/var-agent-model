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

import info.financialecology.finance.abm.model.LPMHBEqnModel.Results;
import info.financialecology.finance.abm.simulation.LPMHBEqnParams;
import info.financialecology.finance.abm.simulation.LPMHBEqnParams.Sequence;
import info.financialecology.finance.utilities.abm.AbstractSimulator;
import info.financialecology.finance.utilities.datastruct.Datastore;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;

import java.util.ArrayList;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import cern.colt.list.DoubleArrayList;


/**
 * @author Gilbert Peffer
 *
 */
public class LPMHBEqnSimulator extends AbstractSimulator {
    private LPMHBEqnParams params;
    
    private LPMHBEqnModel model = null;
    
    private static final Logger logger = (Logger)LoggerFactory.getLogger(FJAbmSimulator.class.getSimpleName());
    
    public LPMHBEqnSimulator(LPMHBEqnParams params) {
        logger.trace("Entering the LPMHBEquationSimulator()");
        
        this.params = params;
        
        model = new LPMHBEqnModel(this, params);
    }
    
    public LPMHBEqnModel getModel() {
        return model;
    }
    
    private void warmupSimulation() {
        DoubleTimeSeriesList tsLogPrices = Datastore.getResult(DoubleTimeSeriesList.class, Results.LOG_PRICES);
        DoubleTimeSeriesList tsLogRefValues = Datastore.getResult(DoubleTimeSeriesList.class, Results.LOG_REFVALUES);
        DoubleTimeSeriesList tsOrderFUND = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_FUNDAMENTAL);
        DoubleTimeSeriesList tsOrderLS = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_LONGSHORT);
        DoubleTimeSeriesList tsOrderTREND = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_TREND);
        DoubleTimeSeriesList storedNetPosMF = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_MF);
        DoubleTimeSeriesList storedNetPosHF = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_HF);
        DoubleTimeSeriesList storedNetPosB = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_B);
        DoubleTimeSeriesList storedNetPosFUND = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_FUND);
        DoubleTimeSeriesList storedNetPosTREND = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_TREND);
        DoubleTimeSeriesList storedNetPosLS = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_LS);
        DoubleTimeSeriesList tsVolume = Datastore.getResult(DoubleTimeSeriesList.class, Results.VOLUME);
        DoubleTimeSeriesList tsTotalTrades = Datastore.getResult(DoubleTimeSeriesList.class, Results.TOTAL_TRADES);
//        DoubleTimeSeriesList storedProfitAndLoss = Datastore.getResult(DoubleTimeSeriesList.class, Results.PROFIT_AND_LOSS);
        DoubleTimeSeriesList storedPaperProfitAndLoss = Datastore.getResult(DoubleTimeSeriesList.class, Results.PAPER_PROFIT_AND_LOSS);
        DoubleTimeSeriesList storedRealisedProfitAndLoss = Datastore.getResult(DoubleTimeSeriesList.class, Results.REALISED_PROFIT_AND_LOSS);
//        DoubleTimeSeriesList storedProfitAndLossStrategy = Datastore.getResult(DoubleTimeSeriesList.class, Results.PROFIT_AND_LOSS_STRATEGY);
        DoubleTimeSeriesList storedPaperProfitAndLossStrategy = Datastore.getResult(DoubleTimeSeriesList.class, Results.PAPER_PROFIT_AND_LOSS_STRATEGY);
        DoubleTimeSeriesList storedRealisedProfitAndLossStrategy = Datastore.getResult(DoubleTimeSeriesList.class, Results.REALISED_PROFIT_AND_LOSS_STRATEGY);
//        DoubleTimeSeriesList storedTotalCash= Datastore.getResult(DoubleTimeSeriesList.class, Results.CASH);
        
        ArrayList<DoubleArrayList> prices_0 = params.getDoubleNumberSequence(Sequence.PRICE_0);
        
        for (int i = 0; i < params.nAssets; i++) {
            tsLogPrices.get(i).add(Math.log(prices_0.get(i).get(0)));
            tsLogRefValues.get(i).add(Math.log(prices_0.get(i).get(0)));
            tsOrderFUND.get(i).add(0);
            tsOrderLS.get(i).add(0);
            tsOrderTREND.get(i).add(0);
            storedNetPosMF.get(i).add(0);
            storedNetPosHF.get(i).add(0);
            storedNetPosB.get(i).add(0);
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
            storedPaperProfitAndLossStrategy.get(i).add(0);
            storedRealisedProfitAndLossStrategy.get(i).add(0);
        }
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
