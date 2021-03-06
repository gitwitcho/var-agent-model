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
package info.financialecology.finance.utilities.datagen;

import cern.colt.list.DoubleArrayList;

/**
 * @author Gilbert Peffer
 *
 */
public interface DataGenerator {
    
    /**
     * Get the next value in the data stream
     * 
     * @return the next double in the data stream
     * 
     */
    double nextDouble();
    double nextDoubleIncrement();
    DoubleArrayList nextDoubles(int numDoubles);
    DoubleArrayList nextDoubleVector();
    DoubleArrayList nextDoubleVectorIncrements();
}
