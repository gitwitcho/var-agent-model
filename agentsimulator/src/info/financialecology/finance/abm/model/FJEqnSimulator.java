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

import info.financialecology.finance.abm.simulation.FJEqnParams;
import info.financialecology.finance.utilities.abm.AbstractSimulator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * @author Gilbert Peffer
 *
 */
public class FJEqnSimulator extends AbstractSimulator {
    private FJEqnParams params;
    private FJEqnModel model = null;

    private static final Logger logger = (Logger)LoggerFactory.getLogger(FJAbmSimulator.class.getSimpleName());


    /*
     * Constructor
     * 
     * Several parameters are initialised here and kept constant during the
     * experiments: valueOffset, delay, entryThresh, and exitThresh
     * 
     */
    public FJEqnSimulator(FJEqnParams params) {
        logger.trace("Entering the FJEqnSimulator()");
        
        this.params = params;
        this.model = new FJEqnModel(this, params);        
    }

    /** 
     * Conduct one simulation run of nTicks steps
     **/
    @Override
    public void run() {
        logger.trace("Entry - run()");
        
        /**
         *      SIMULATION 
         */
        for (int t = 1; t <= params.nTicks; t++) {  // TODO we need to deal with the warmup inside the model             
            model.step();
            incrementTick();
        }
    }
}
