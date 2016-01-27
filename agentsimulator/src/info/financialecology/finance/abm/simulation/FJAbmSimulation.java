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

import info.financialecology.finance.abm.model.FJAbmSimulator;
import info.financialecology.finance.abm.model.agent.FJFundamentalTrader;
import info.financialecology.finance.abm.model.agent.FJMarketMaker;
import info.financialecology.finance.abm.model.agent.FJTechnicalTrader;
import info.financialecology.finance.utilities.datastruct.Datastore;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.output.ResultWriter;
import info.financialecology.finance.utilities.output.ResultWriterFactory;

import org.slf4j.LoggerFactory;

import repast.simphony.random.RandomHelper;


import cern.colt.Timer;
import cern.jet.random.*;
import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;

/**
 * The standard Farmer-Joshi model with fundamental and technical traders
 * 
 * @author Gilbert Peffer
 *
 */
public class FJAbmSimulation {

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
        logger.trace("Setting up simulation model");

        FJAbmSimulator                       simulator;            // the Farmer-Joshi simulator
        Normal                            distRefValue;         // noise distribution for reference process of log value
        Uniform                           distOffsetValue;      // distribution for trader-specific value offset
        DoubleTimeSeries                  tsPrices = null;      // contains the number of nodes that failed
        DoubleTimeSeriesList              tsPricesList;         // results of the experiment as a list of time series
        
        int nRuns                 = 2;          // number of simulation runs
        int nTicks                = 5;          // number of ticks per simulation run
        double liquidity          = 5;          // the liquidity of the stock
        int numFundTraders        = 10;         // number of fundamental traders
        int numTechTraders        = 5;          // number of technical traders
        double capFacFundTr       = 0.3;        // capital factor of fundamental traders
        double capFacTechTr       = 1.8;        // capital factor of technical traders
        double initCash           = 100;        // initial cash position of technical and fundamental traders
        double initStock          = 100;        // initial stock position of technical and fundamental traders
        double initPrice          = 100;        // the initial price of the stock
        double refValueMu         = 0;          // mean of noise for reference process of log-value
        double refValueSigma      = 0.35;       // standard deviation of noise for reference process of log-value
        double offsetValueMin     = -2;         // minimum value in uniform distribution for trader-specific value offset
        double offsetValueMax     = 2;          // maximum value in uniform distribution for trader-specific value offset
        
        tsPricesList = new DoubleTimeSeriesList();      // time series list of prices [nRuns x nTicks]
        
        RandomHelper.setSeed(1000);             // forces the generator to produce the same random number sequences for each experiment (but a different sequence for each run) 
        
        /**
         *      SIMULATION EXPERIMENT
         */
        for (int i = 0; i < nRuns; i++) {
            
            /**
             *      SIMULATION
             */
            logger.trace("Starting simulation");
            
            // We need to reset the static variables for each simulation run
            // TODO centralise this in a single method
            Datastore.clean();
            FJAbmSimulator.setAllStatics();
            FJMarketMaker.setAllStatics();
            FJFundamentalTrader.setAllStatics();
            FJTechnicalTrader.setAllStatics();
            
            simulator = new FJAbmSimulator();      // recreating the simulator will also get rid of the old schedule
            
            simulator.setNumTicks(nTicks);
            simulator.setLiquidity(liquidity);
            simulator.createFJFundamentalTraders(numFundTraders);
            simulator.createFJTechnicalTraders(numTechTraders);
            simulator.initialiseFJMarketMaker(initPrice);
            
            distRefValue = RandomHelper.createNormal(refValueMu, refValueSigma);            // distribution of noise for reference process of log value
            distOffsetValue = RandomHelper.createUniform(offsetValueMin, offsetValueMax);   // distribution of trader-specific offset w.r.t. reference process
            
            FJAbmSimulator.setDistOffsetValues(distOffsetValue);
            simulator.initialiseFJFundamentalTraders(capFacFundTr, initCash, initStock, distRefValue);
            simulator.initialiseFJTechnicalTraders(capFacTechTr, initCash, initStock);
            
            timer.start();
            
            simulator.run();
            
            logger.debug("Simulation execution time: {} seconds", timer.elapsedTime());
            
            /**
             *      RESULTS
             */
            logger.trace("Storing results");
            
            // Price time series at run i
            tsPrices = Datastore.getResult(DoubleTimeSeries.class, FJMarketMaker.Results.PRICES);
            tsPrices.setId("run_" + Integer.toString(i+1));
            tsPricesList.add(i, tsPrices);    // time series list of prices [nRuns x nTicks]

            logger.debug("Prices\n\n{}{}", tsPrices, "\n");
            logger.debug("Total execution time: {} seconds", timerAll.elapsedTime());
            logger.debug("----- End of run #{} -----\n", i);
        }

        /**
         *      OUTPUT
         */
        
        // Write results to file for R
        ResultWriter csvwriter = ResultWriterFactory.getCSVWriter("./out/fjsimulation-a/list_price_timeseries.csv");
        csvwriter.write(tsPricesList);

        logger.debug("----- END OF SIMULATION EXPERIMENT -----\n");
        
        System.exit(0);
    }

}
