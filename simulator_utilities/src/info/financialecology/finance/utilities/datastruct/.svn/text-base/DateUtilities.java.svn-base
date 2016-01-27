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

import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.Assertion.Level;

import org.jfree.data.time.Day;
import org.jfree.data.time.RegularTimePeriod;



/**
 * @author Gilbert Peffer
 *
 */
public class DateUtilities {

    public static RegularTimePeriod copy(RegularTimePeriod period) {
        RegularTimePeriod newPeriod = null;
        
        if (period.getClass() == Day.class) {
            Day day = (Day) period;
            newPeriod = new Day(day.getStart());
        }
        else
            Assertion.assertStrict(false, Assertion.Level.ERR, "Class '" + period.getClass() + "' not recognised by DateUtilities");
        
        return newPeriod;
    }
}
