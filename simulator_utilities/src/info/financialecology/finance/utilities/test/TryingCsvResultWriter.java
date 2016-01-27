/*
 * Copyright (c) 2011-2014 Gilbert Peffer, Barbara Llacay
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
package info.financialecology.finance.utilities.test;

import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeries;

import cern.colt.list.DoubleArrayList;

/**
 * @author Gilbert Peffer
 *
 */
public class TryingCsvResultWriter {

    /**
     * @param args
     */
    public static void main(String[] args) {
        
        DoubleTimeSeries dts = new DoubleTimeSeries(new DoubleArrayList(new double [] {10, 11, 12, 13, 14, 15}));
        
        
        VersatileTimeSeries vts = new VersatileTimeSeries("TS", dts);
        System.out.println(vts);
    }
}
