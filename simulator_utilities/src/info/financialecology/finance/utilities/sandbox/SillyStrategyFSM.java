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

import info.financialecology.finance.utilities.sandbox.FileReaderFSM.StopEvent;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;



import com.continuent.tungsten.fsm.core.Action;
import com.continuent.tungsten.fsm.core.Event;
import com.continuent.tungsten.fsm.core.Entity;
import com.continuent.tungsten.fsm.core.EventTypeGuard;
import com.continuent.tungsten.fsm.core.Guard;
import com.continuent.tungsten.fsm.core.State;
import com.continuent.tungsten.fsm.core.StateMachine;
import com.continuent.tungsten.fsm.core.StateTransitionMap;
import com.continuent.tungsten.fsm.core.StateType;
import com.continuent.tungsten.fsm.core.StringEvent;
import com.continuent.tungsten.fsm.core.Transition;

import com.continuent.tungsten.fsm.core.EntityAdapter;
import com.continuent.tungsten.fsm.core.PositiveGuard;
import com.continuent.tungsten.fsm.core.StateChangeListener;

import com.continuent.tungsten.fsm.core.FiniteStateException;
import com.continuent.tungsten.fsm.core.TransitionRollbackException;

public class SillyStrategyFSM implements StateChangeListener {
  // State machine
  private StateTransitionMap stmap = null;
  private StateMachine sm = null;

  // Monitoring and management
  private static Logger logger = LoggerFactory.getLogger(SillyStrategyFSM.class);

  // Ctor
  public SillyStrategyFSM() throws Exception {
    // Define actions
    Action nullAction = new NullAction();
    Action openPosition = new OpenPosition();

    // Define states
    stmap = new StateTransitionMap();
    State start = new State("START_TRADING", StateType.START);
    State trading = new State("TRADING", StateType.ACTIVE);
    State end = new State("END_TRADING", StateType.END);

    stmap.addState(start);
    stmap.addState(trading);
    stmap.addState(end);
    
    // Define guards
    Guard startGuard = new EventTypeGuard(StartEvent.class);
    Guard longPositionGuard = new EventTypeGuard(LongEvent.class);
    Guard shortPositionGuard = new EventTypeGuard(ShortEvent.class);
    Guard liquidateGuard = new EventTypeGuard(LiquidationEvent.class);
    Guard stopGuard = new EventTypeGuard(StopEvent.class);

/*
    // Define transitions
    stmap.addTransition(new Transition("START-TO-END", new PositiveGuard(),
                                       start, nullAction, end));
*/    
    
    // Define transitions
    //stmap.addTransition(new Transition("START-TO-TRADING", startGuard, start, nullAction, trading));
    stmap.addTransition(new Transition("START-TO-TRADING", new PositiveGuard(), start, nullAction, trading));
    stmap.addTransition(new Transition("START-TO-END", stopGuard, start, nullAction, end));
    //stmap.addTransition(new Transition("TRADING-TO-TRADING", longPositionGuard, trading, openPosition, trading));
    stmap.addTransition(new Transition("TRADING-TO-END", longPositionGuard, trading, nullAction, trading));
    stmap.addTransition(new Transition("TRADING-TO-END", stopGuard, trading, nullAction, end));

    // Create the state machine
    stmap.build();
    sm = new StateMachine(stmap, new EntityAdapter(this));
    sm.addListener(this);
  }

  public StateMachine getStateMachine() {
    return sm;
  }
  
  public void readPrice(double Pt) throws Exception {
	//sm.applyEvent(new StringEvent(Double.toString(Pt)));
	  logger.info("Entered readPrice");
	  sm.applyEvent(new LongEvent());
	  logger.info("I am inside readPrice, after applyEvent");
  }

  public void stop() throws Exception {
	try {
	   sm.applyEvent(new StopEvent());
	} catch (Exception e) {
	  logger.error("Stop operation failed", e);
	  throw new Exception(e.toString());
	}
  }
  

  // Log state changes
  public void stateChanged(Entity entity, State oldState, State newState) {
    logger.info("State changed: " + oldState.getName() + " -> " + newState.getName());
  }

  class StartEvent extends Event
  {
    public StartEvent()
    {
      super(null);
    }
  }
  
  class StopEvent extends Event
  {
    public StopEvent()
    {
      super(null);
    }
  }
  
  class LongEvent extends Event
  {
    public LongEvent()
    {
      super(null);
    }
  }

  class ShortEvent extends Event
  {
    public ShortEvent()
    {
      super(null);
    }
  }

  class LiquidationEvent extends Event
  {
    public LiquidationEvent()
    {
      super(null);
    }
  }


  // Do nothing 
  class NullAction implements Action {
    public void doAction(Event event, Entity entity, Transition transition,
                         int actionType) throws TransitionRollbackException {
    	
    	logger.info("Entered NullAction");
    }
  }

  // Open position
  class OpenPosition implements Action {
    public void doAction(Event event, Entity entity, Transition transition,
                         int actionType) throws TransitionRollbackException {
    	logger.info("Entered OpenPosition");
    	
      try{
    	sm.applyEvent(new LongEvent());
      }
      catch (FiniteStateException e)
      {        
          logger.info("Unexpected state transition processing error (OpenPosition --> FiniteStateException)", e);
      }
      catch (InterruptedException e)
      {          
          logger.info("Unexpected state transition processing error (OpenPosition --> InterruptedException)", e);
      }
      
      logger.info("Event: " + event.getData());
    }
  }

  
  

  public static void main(String[] args) {
    try {
      int nTicks = 200;  // Number of ticks
      double[] sinus = new double[nTicks];    // Price series (= sinus process)
      
      // Create a sinus price process to test the strategy
	  for (int i = 0; i < nTicks; i++) {
		sinus[i] = 100 + 10 * Math.sin(2*i*Math.PI / 50);
	  }
      
      SillyStrategyFSM simpleFSM = new SillyStrategyFSM();
      StateMachine sm = simpleFSM.getStateMachine();
           
      
      logger.info("State: " + sm.getState().getName());
      
      simpleFSM.readPrice(0.0);
      
      logger.info("State: " + sm.getState().getName());
      
      simpleFSM.readPrice(1.0);
      
      logger.info("State: " + sm.getState().getName());
      
      /*
      // Read the price - TEST
   	  for (int i = 0; i < nTicks; i++) {
   		 simpleFSM.readPrice(sinus[i]);
   	  }
   	  */
      
     
     
    } catch (FiniteStateException e) {
      logger.error("Unexpected state transition processing error", e);
    } catch (Exception e) {
      System.err.println(e.getMessage());
      e.printStackTrace();
    }
  }
}