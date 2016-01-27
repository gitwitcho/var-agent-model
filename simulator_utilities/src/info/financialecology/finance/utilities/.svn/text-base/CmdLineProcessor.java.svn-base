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

import info.financialecology.finance.utilities.test.TestRandomDistDataGeneratorParams;
import jargs.gnu.CmdLineParser;

import org.slf4j.LoggerFactory;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;

/**
 * @author Gilbert Peffer
 *
 */
public class CmdLineProcessor {
    
    private static class CmdArgs {
        static TestRandomDistDataGeneratorParams params;
//        static LPMHBEqnParamsRandomiser paramsRand;
        static Boolean verbose;
    }

    public static String process(String[] args) {
        Logger root = (Logger)LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);

        CmdLineParser parser = new CmdLineParser();
        CmdLineParser.Option verbose = parser.addBooleanOption('v', "verbose");
        CmdLineParser.Option fileName = parser.addStringOption('p', "params");

        try {
            parser.parse(args);
        }
        catch ( CmdLineParser.OptionException e ) {
            System.err.println(e.getMessage());
            printUsage();
            System.exit(2);
        }

        String fileNameValue = (String)parser.getOptionValue(fileName);
        Assertion.assertStrict(fileNameValue != null, Assertion.Level.ERR, "File name argument is missing\n\n" + getUsage() + "\n");
        
        CmdArgs.verbose = (Boolean)parser.getOptionValue(verbose, Boolean.FALSE);

        if (CmdArgs.verbose)
            root.setLevel(Level.TRACE);
        else
            root.setLevel(Level.DEBUG);
                
        return fileNameValue;
    }

    private static void printUsage() {
        System.err.println(getUsage());
    }
    
    private static String getUsage() {
        return "Usage: [TODO - Obtain usage from caller of method process(...)]";
    }
}
