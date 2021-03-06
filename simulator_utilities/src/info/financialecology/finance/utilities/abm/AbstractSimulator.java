/*
 * Copyright (c) 2011-2014 Gilbert Peffer, B�rbara Llacay
 * 
 * The source code and software releases are available at http://code.google.com/p/systemic-risk/
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package info.financialecology.finance.utilities.abm;

import info.financialecology.finance.utilities.WorldClock;

/**
 * The abstract simulator class that provides some basic methods to manage simulation ticks. Uses the 
 * static class {@link WorldClock}. 
 * 
 * @author Gilbert Peffer
 */
public abstract class AbstractSimulator {
    protected long nTicks;  // number of ticks per simulation run

    /**
     * Constructor
     */
    public AbstractSimulator() {
        nTicks = 0;
    }
    

    /**
     * Get the current tick of the simulation from the {@code WorldClock}
     * 
     * @return the tick
     */
    public long currentTick() {
        return WorldClock.currentTick();
    }
    
    
    /**
     * Increment simulation tick - uses the {@code WorldClock}
     */
    public void incrementTick() {
        WorldClock.incrementTick();
    }
    
    /**
     * Reset the {@code WorldClock}
     */
    public void resetWorldClock() {
        WorldClock.reset();
    }

    /**
     * Get the number of ticks in the simulation run
     * 
     * @return number of ticks
     */
    public long getNumTicks() {
        return nTicks;
    }

    /**
     * Set the number of ticks in the simulation run
     * 
     * @param nTicks number of ticks
     */
    public void setNumTicks(long nTicks) {
        this.nTicks = nTicks;
    }

    /**
     * Execute one simulation run
     */
    public abstract void run();
}
