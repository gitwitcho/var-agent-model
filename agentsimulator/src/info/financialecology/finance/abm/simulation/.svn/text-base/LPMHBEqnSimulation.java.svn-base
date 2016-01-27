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
package info.financialecology.finance.abm.simulation;

import info.financialecology.finance.abm.model.LPMHBEqnModel;
import info.financialecology.finance.abm.model.LPMHBEqnSimulator;
import info.financialecology.finance.abm.simulation.LPMHBEqnParams.Sequence;
import info.financialecology.finance.utilities.datastruct.Datastore;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.output.ResultWriterFactory;

import java.io.FileNotFoundException;

import org.slf4j.LoggerFactory;
import repast.simphony.random.RandomHelper;

import cern.colt.Timer;
import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;

/**
 * The long-short model
 * 
 * 
 * 
 * @author Gilbert Peffer
 *
 */
public class LPMHBEqnSimulation {

    /**
     * @param args
     */
    public static void main(String[] args) {
        Timer timerAll  = new Timer();  // a timer to calculate total execution time (cern.colt)
        Timer timer     = new Timer();  // a timer to calculate execution times of particular methods (cern.colt)
        timerAll.start();

        Logger root = (Logger)LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        root.setLevel(Level.TRACE);
        Logger logger = (Logger)LoggerFactory.getLogger("main");

        /**
         *      MODEL SET-UP
         */
        logger.trace("Setting up LSLPEquationSimulation");
        
        RandomHelper.setSeed(628098474);                    // forces the generator to produce the same random number sequences for each experiment (but a different sequence for each run)
        logger.trace("Seed of the random number generator: {}", RandomHelper.getSeed());
        
        //      MODEL PARAMETERS
        
        // TODO use processCmdLine() method from LPMHBEquation_VE_LPMHB_4_1_2
        String file = "./in/params/lpmhb_equation_simulation.xml";
        LPMHBEqnParams params = null;
                
        try {
            params = LPMHBEqnParams.readParameters(file);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        
        params.validate();
        
        logger.debug("{} : {}", Sequence.LIQUIDITY.label(), params.getDoubleNumberSequence(Sequence.LIQUIDITY));
        logger.debug("{} : {}", Sequence.PRICE_0.label(), params.getDoubleNumberSequence(Sequence.PRICE_0));
        logger.debug("{} : {}", Sequence.PRICE_NOISE.label(), params.getDoubleIntervalSequence(Sequence.PRICE_NOISE));
        logger.debug("{} : {}", Sequence.REF_VALUE.label(), params.getDoubleIntervalSequence(Sequence.REF_VALUE));
        logger.debug("{} : {}", Sequence.OFFSET_VALUE.label(), params.getDoubleIntervalSequence(Sequence.OFFSET_VALUE));
        logger.debug("{} : {}", Sequence.T_FUND_MF.label(), params.getDoubleIntervalSequence(Sequence.T_FUND_MF));
        logger.debug("{} : {}", Sequence.TAU_FUND_MF.label(), params.getDoubleIntervalSequence(Sequence.TAU_FUND_MF));
        logger.debug("{} : {}", Sequence.T_TREND_MF.label(), params.getDoubleIntervalSequence(Sequence.T_TREND_MF));
        logger.debug("{} : {}", Sequence.TAU_TREND_MF.label(), params.getDoubleIntervalSequence(Sequence.TAU_TREND_MF));
        logger.debug("{} : {}", Sequence.DELAY_TREND_MF.label(), params.getIntegerIntervalSequence(Sequence.DELAY_TREND_MF));
        logger.debug("{} : {}", Sequence.MA_WIN_LS_HF.label(), params.getIntegerIntervalSequence(Sequence.MA_WIN_LS_HF));
        logger.debug("{} : {}", Sequence.T_FUND_B.label(), params.getDoubleIntervalSequence(Sequence.T_FUND_B));
        logger.debug("{} : {}", Sequence.TAU_FUND_B.label(), params.getDoubleIntervalSequence(Sequence.TAU_FUND_B));
        logger.debug("{} : {}", Sequence.T_TREND_B.label(), params.getDoubleIntervalSequence(Sequence.T_TREND_B));
        logger.debug("{} : {}", Sequence.TAU_TREND_B.label(), params.getDoubleIntervalSequence(Sequence.TAU_TREND_B));
        logger.debug("{} : {}", Sequence.DELAY_TREND_B.label(), params.getIntegerIntervalSequence(Sequence.DELAY_TREND_B));
        logger.debug("{} : {}", Sequence.MA_WIN_LS_B.label(), params.getIntegerIntervalSequence(Sequence.MA_WIN_LS_B));
        
        LPMHBEqnSimulator simulator;
        
        //      RESULT STORAGE
        
        DoubleTimeSeriesList   tsLogPricesList = null;
        DoubleTimeSeriesList   tsLogRefValuesList = null;
        DoubleTimeSeriesList   tsOrderFUNDList = null;
        DoubleTimeSeriesList   tsOrderTRENDList = null;
        DoubleTimeSeriesList   tsOrderLSList = null;
        DoubleTimeSeriesList   tsVolumeList = null;
        
        /**
         *      SIMULATION EXPERIMENT
         */
        for (int i = 0; i < params.nRuns; i++) {
            
 
            /**
             *      SIMULATION
             */
            logger.trace("Starting simulation");

            simulator = new LPMHBEqnSimulator(params);

            timer.start();
            
            simulator.run();
            
            logger.debug("Simulation execution time: {} seconds", timer.elapsedTime());
            
            /**
             *      RESULTS
             */
            logger.trace("Storing results");
            
            tsLogPricesList = Datastore.getResult(DoubleTimeSeriesList.class, LPMHBEqnModel.Results.LOG_PRICES);
            tsLogRefValuesList = Datastore.getResult(DoubleTimeSeriesList.class, LPMHBEqnModel.Results.LOG_REFVALUES);
            tsOrderFUNDList = Datastore.getResult(DoubleTimeSeriesList.class, LPMHBEqnModel.Results.ORDER_FUNDAMENTAL);
            tsOrderTRENDList = Datastore.getResult(DoubleTimeSeriesList.class, LPMHBEqnModel.Results.ORDER_TREND);
            tsOrderLSList = Datastore.getResult(DoubleTimeSeriesList.class, LPMHBEqnModel.Results.ORDER_LONGSHORT);
            tsVolumeList = Datastore.getResult(DoubleTimeSeriesList.class, LPMHBEqnModel.Results.VOLUME);
            
//            // Price time series at run i
//            tsLogPricesList.add(i, tsLogPrices);    // time series list of log prices [nRuns x nTicks]
//            tsLogValuesList.add(i, tsLogRefValues);
//            tsPriceNoiseList.add(i, tsPriceNoise);
//            tsOrderFundList.add(i, tsOrderFund);
//            tsOrderTechList.add(i, tsOrderTech);
//            tsVolumeList.add(i, tsVolume);
            
//            logger.debug("Prices\n\n{}{}", tsLogPrices, "\n");
            logger.debug("Total execution time: {} seconds", timerAll.elapsedTime());
            logger.debug("----- End of run #{} -----\n", i + 1);
        }
        

        /**
         *      OUTPUT
         */
        
        // Write results to file for R
        ResultWriterFactory.getCSVWriter("./out/lpmhb-equation-simulation/list_log_price_timeseries.csv").write(tsLogPricesList);
        ResultWriterFactory.getCSVWriter("./out/lpmhb-equation-simulation/list_ref_values_timeseries.csv").write(tsLogRefValuesList);
        ResultWriterFactory.getCSVWriter("./out/lpmhb-equation-simulation/list_order_fundamental_timeseries.csv").write(tsOrderFUNDList);
        ResultWriterFactory.getCSVWriter("./out/lpmhb-equation-simulation/list_order_trend_timeseries.csv").write(tsOrderTRENDList);
        ResultWriterFactory.getCSVWriter("./out/lpmhb-equation-simulation/list_order_long_short_timeseries.csv").write(tsOrderLSList);
//        ResultWriterFactory.newCsvWriter("./out/lpmhb-equation-simulation/list_price_noise_timeseries.csv").write(tsOrderLSList);
        ResultWriterFactory.getCSVWriter("./out/lpmhb-equation-simulation/list_volume_timeseries.csv").write(tsVolumeList);

        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
        System.exit(0);
    }

}
