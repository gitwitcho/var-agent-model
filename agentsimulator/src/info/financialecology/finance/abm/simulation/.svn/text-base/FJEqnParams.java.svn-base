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

import info.financialecology.finance.utilities.datastruct.SimulationParameters;

import java.io.FileNotFoundException;


/**
 * A simple parameter class that uses xstream to read and write object parameters from and to files.
 * See also:
 *      Xstream: http://tinyurl.com/66o9od
 *      "Use XStream to serialize Java objects into XML": http://tinyurl.com/6ah27g
 *      
 * @author Gilbert Peffer
 *
 */
public class FJEqnParams extends SimulationParameters {

    //      MARKET PARAMETERS

    public int nRuns                 = 0;          // number of simulation runs
    public int nTicks                = 0;       // number of ticks per simulation run
    public int numValueInvestors        = 0;        // number of fundamental traders
    public int numTrendFollowers        = 0;        // number of technical traders
    public double liquidity          = 0;          // the liquidity of the stock
    public double priceNoiseMu       = 0.0;        // mean of noise for reference process of log-value
    public double priceNoiseSigma    = 0.0;        // [0.35] standard deviation of noise for reference process of log-value
    public double price_0            = 0.0;       // price at time t=0
    public boolean constCapFac      = true;       // same capital factor for technical and for fundamental traders    
    
    //      AGENT PARAMETERS

    // Fundamental traders
    public double refValueMu         = 0.0;        // mean of noise for reference process of log-value
    public double refValueSigma      = 0.0;        // [0.35]standard deviation of noise for reference process of log-value
    public double offsetValueMin     = 0.0;       // minimum value in uniform distribution for trader-specific value offset
    public double offsetValueMax     = 0.0;        // maximum value in uniform distribution for trader-specific value offset
    public double TMinValueInv           = 0.0;        // entry threshold for state dependent strategies
    public double TMaxValueInv           = 0.0;          // idem
    public double tauMinValueInv         = 0.0;       // exit threshold for state dependent strategies
    public double tauMaxValueInv         = 0.0;        // idem
    public double aValueInv              = 0.0;     // scale parameter for capital assignment
   
    // Technical trader
    public double TMinTrend           = 0.0;        // entry threshold for state dependent strategies
    public double TMaxTrend           = 0.0;          // idem
    public double tauMinTrend         = 0.0;       // exit threshold for state dependent strategies
    public double tauMaxTrend         = 0.0;        // idem
    public double aTrend              = 0.0;     // scale parameter for capital assignment
    public int delayMin              = 0;          // range for time delay (theta)
    public int delayMax              = 0;        // idem
    
    FJEqnParams() {}
    
    /**
     * Creates an xml file that holds the fields of this object
     * 
     * @param file
     * @throws FileNotFoundException 
     */
    public static void writeParamDefinition(String file) throws FileNotFoundException {
        writeParamsDefinition(file, new FJEqnParams());
    }

    /**
     * Reads values from an xml file and initialises the fields of the newly created parameter object
     * 
     * @param file
     * @return
     * @throws FileNotFoundException 
     */
    public static FJEqnParams readParameters(String file) throws FileNotFoundException {
        return (FJEqnParams) readParams(file, new FJEqnParams());
    }

}
