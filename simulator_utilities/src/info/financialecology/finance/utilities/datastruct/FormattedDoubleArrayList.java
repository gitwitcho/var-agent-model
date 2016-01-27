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
package info.financialecology.finance.utilities.datastruct;

import java.text.DecimalFormat;
import cern.colt.list.DoubleArrayList;

/**
 * @author Gilbert Peffer
 *
 */
public class FormattedDoubleArrayList extends DoubleArrayList {    
    private static final long serialVersionUID = -1923511355119365551L;
    
    private static DecimalFormat    formatter = new DecimalFormat();
    
    public FormattedDoubleArrayList() {
        super();
    }
    
    public static void setFormatter(DecimalFormat df) {
        formatter = df;
    }
    
    @Override
    public String toString() {
        String fdal = "[";
        double n = super.size();
        
        for (int i = 0; i < n; i++) {
            fdal += formatter.format(super.get(i));
            if (i != n - 1) fdal += ", ";
        }
        
        return fdal + "]";
    }

}
