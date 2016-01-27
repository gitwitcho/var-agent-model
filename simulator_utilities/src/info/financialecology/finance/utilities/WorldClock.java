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
package info.financialecology.finance.utilities;

/**
 * @author Gilbert Peffer
 *
 */
public class WorldClock {

    private static int tick = 0;
    
    public static void reset() {
        tick = 0;
    }
    
    public static int currentTick() {
        return tick;
    }
    
    public static int incrementTick() {
        tick++;
        
        return tick;
    }
}
