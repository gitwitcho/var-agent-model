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
package info.financialecology.finance.utilities.datastruct;

import info.financialecology.finance.utilities.Assertion;

import java.util.ArrayList;

import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;

import cern.colt.list.DoubleArrayList;

/**
 * @author Gilbert Peffer
 *
 */
public class DoubleTimeSeriesList extends ArrayList<DoubleTimeSeries> {
    
    private static final long serialVersionUID = 756574007357240175L;
    private DescriptiveStatistics   stats = new DescriptiveStatistics();

    public DoubleTimeSeriesList() {
        super();
    }
    
    @Override
    public boolean add(DoubleTimeSeries element) {
        return super.add(element);
    }
    
    @Override
    public DoubleTimeSeries set(int index, DoubleTimeSeries element) {
        return super.set(index, element);
    }
    
    @Override
    public DoubleTimeSeries get(int i) {
        return super.get(i);
    }
    
    
    /**
     * Get the values at time t of all time series in the list.
     * 
     * @param t the time for which we want the values
     * @return the time slice as a {@code DoubleArrayList}
     */
    public DoubleArrayList slice(int t) {
        
        Assertion.assertOrKill(t < this.get(0).size(), "Out of bounds - The slice for time t=" + t + " does not exist");
        
        DoubleArrayList slice = new DoubleArrayList();
        
        for (int i = 0; i < this.size(); i++)
            slice.add(this.get(i).get(t));
        
        return slice;
    }
    
    public double mean() {
        for (int i = 0; i < super.size(); i++) {
            DoubleTimeSeries dts = super.get(i);
            for(int j = 0; j < dts.size(); j++)
                stats.addValue(dts.getValue(j));
        }
        return stats.getMean();
    }

}
