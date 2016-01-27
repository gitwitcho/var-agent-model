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


import info.financialecology.finance.utilities.datastruct.SimulationParameters.Item;

import java.lang.reflect.Type;


/**
 * @author Gilbert Peffer
 *
 */
public interface ParamSequence {

    public String label();
    public Item itemType();
    public String param();
//    public String paramOptionalNotProvided();
    public boolean isOptional();
    public void setParamString(String param);
    public Type type();
    public int length(SimulationParameters params);
}
