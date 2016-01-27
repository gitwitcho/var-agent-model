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
package info.financialecology.finance.abm.model.strategy;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import info.financialecology.finance.abm.model.util.TradingPortfolio;

/**
 * @author Gilbert Peffer
 *
 */
public interface TradingStrategy {
    
    public class Order {
        private String secId;
        private double order;
        
        public Order() {
            this.secId = null;
            this.order = 0;
        }

        /**
         * @return the secId
         */
        public String getSecId() {
            return secId;
        }

        /**
         * @param secId the secId to set
         */
        public void setSecId(String secId) {
            this.secId = secId;
        }

        /**
         * @return the order
         */
        public double getOrder() {
            return order;
        }

        /**
         * @param order the order to set
         */
        public void setOrder(double order) {
            this.order = order;
        }
    }
    
    public void trade(TradingPortfolio portfolio);
    public ArrayList<Order> getOrders();
    public String getUniqueId();
    public HashSet<String> getSecIds();
    
//    public double getOrder(String secId);
//    public String getSecId();
}
