/*
 * Copyright (c) 2011-2014 Gilbert Peffer
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
package info.financialecology.finance.utilities;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * A simple class with methods to assert the truth value of a logical statement. It provides a 
 * standard way of enforcing conditions that need to met by the code. Uses the SLF4J logging
 * infrastructure.
 * 
 * @author Gilbert Peffer
 */
public class Assertion {
    
    private static final Logger logger = (Logger)LoggerFactory.getLogger(Assertion.class.getSimpleName());

    /**
     * The assertion type
     */
    public enum Level {
        /**
         * Informs why the assertion fails and continues execution
         */
        INFO,
        
        /**
         * Informs why the assertion fails and then stopps execution
         */
        ERR;
    }
    
    /**
     * Ensure that the logical condition {@code a} is true, otherwise stop the execution
     *  
     * @param a the logical condition, for instance {@code length <= 5}
     * @param err the error message
     */
    public static void assertOrKill (Boolean a, String err) {
        assertStrict (a, Level.ERR, err);
    }
    
    /**
     * Ensure that the logical condition {@code a} is true, otherwise, depending on the 
     * assertion type {@code level}, print a message and return false or print a message 
     * and stop the execution.
     *  
     * @param a the logical condition, for instance {@code isNumber(val)}
     * @param level the assertion type (see {@link Level})
     * @param err the error message
     */
    public static Boolean assertStrict (Boolean a, Level level, String err) {
        if (a == false) {
            logger.error("ASSERT FAILED: {}", err);

            if (level == Level.ERR) {
                logger.error("----- EXITING PROGRAMME -----");
                System.exit(0);
            }
            else if (level == Level.INFO)
                return false;
        }
        
        return true;
    }

}
