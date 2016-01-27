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
package info.financialecology.finance.utilities.sandbox;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.sandbox.FileReaderFSM.StopEvent;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.Charset;
import java.util.ArrayList;

import com.continuent.tungsten.fsm.core.Action;
import com.continuent.tungsten.fsm.core.Event;
import com.continuent.tungsten.fsm.core.Entity;
import com.continuent.tungsten.fsm.core.Guard;
import com.continuent.tungsten.fsm.core.State;
import com.continuent.tungsten.fsm.core.StateMachine;
import com.continuent.tungsten.fsm.core.StateTransitionMap;
import com.continuent.tungsten.fsm.core.StateType;
import com.continuent.tungsten.fsm.core.Transition;

import com.continuent.tungsten.fsm.core.EntityAdapter;
import com.continuent.tungsten.fsm.core.EventTypeGuard;
import com.continuent.tungsten.fsm.core.StateChangeListener;
import com.continuent.tungsten.fsm.core.StringEvent;

import com.continuent.tungsten.fsm.core.FiniteStateException;
import com.continuent.tungsten.fsm.core.TransitionRollbackException;

import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;

/**
 * This file implements a simple strategy that uses the FSM.
 * The entry and exit criteria are inspired by the LS strategy, but the positions are 
 * simplified and only can take three values: 1, 0 -1.
 * The strategy works as follows:
 * - If the price goes above the 95 percentile, then position = 1
 * - If the price goes below the 5 percentile, then position = -1 
 * - If there is a long position and the price goes below the 50 percentile, then position = 0
 * - If there is a short position and the price goes above the 50 percentile, then position = 0
 * 
 * @author llacay
 *
 */

public class SimpleStrategyCOND {  

    // Monitoring and management
    private static Logger logger = LoggerFactory.getLogger(SimpleStrategyCOND.class);
    
    /**
     *  Parameters
     *    - tau_low: lower channel boundary
     *    - tau_mid: channel mid-point
     *    - tau_high: upper channel boundary
     */
    double tau_low = 1;
    double tau_high = 19;
    double tau_mid = 0.5 * (tau_low + tau_high);
    
    // Current position
    double pos;
        
    // Constructor
    public SimpleStrategyCOND() {
        this.pos = 0.0;
    }
    
    public double newPosition(double p_t, double p_t_prev) {
        
        if ((p_t_prev > tau_low) && (p_t <= tau_low))
            pos = 1;
        
        if ((p_t_prev > tau_mid) && (p_t <= tau_mid) ||
                (p_t_prev < tau_mid) && (p_t >= tau_mid))
            pos = 0;
        
        if ((p_t_prev < tau_high) && (p_t >= tau_high))
            pos = -1;
                
        return pos;
    }
       
        
    public static void main(String[] args) {
		SimpleStrategyCOND strategyCOND = new SimpleStrategyCOND();

	    int nTicks = 200;  // Number of ticks
	    
	    double sinus_shift = 0.0;
	    double sinus_amplitude = 10.0;
	    double sinus_lambda = 50.0;

        double sinus_t_prev = sinus_amplitude + sinus_shift + sinus_amplitude * Math.sin(2 * 0 * Math.PI / sinus_lambda);
                    
        for (int i = 1; i < nTicks; i++) {
            double sinus_t = sinus_amplitude + sinus_shift + sinus_amplitude * Math.sin(2 * i * Math.PI / sinus_lambda);
            
            logger.info("Tick: " + i + ", value: " + sinus_t + ", position: " + strategyCOND.newPosition(sinus_t, sinus_t_prev));
            
            sinus_t_prev = sinus_t;
        }		
    }
}