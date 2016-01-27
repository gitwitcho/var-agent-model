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

import static org.junit.Assert.*;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeries.Period;

import org.junit.Before;
import org.junit.Test;

import cern.colt.list.DoubleArrayList;

/**
 * @author Gilbert Peffer
 *
 */
public class VersatileTimeSeriesCollectionTest {

    DoubleTimeSeries dts_1;
    DoubleTimeSeries dts_2;
    DoubleTimeSeries dts_3;
    DoubleTimeSeries dts_4;
    DoubleTimeSeries dts_5;
    DoubleTimeSeries dts_6;

    
    /**
     * @throws java.lang.Exception
     */
    @Before
    public void setUp() throws Exception {
        dts_1 = new DoubleTimeSeries(new DoubleArrayList( new double[] {1, 2, 3, 4, 5, 6, 7, 8, 9}));
        dts_2 = new DoubleTimeSeries(new DoubleArrayList( new double[] {10, 20, 30, 40, 50, 60, 70, 80, 90}));
        dts_3 = new DoubleTimeSeries(new DoubleArrayList( new double[] {100, 200, 300, 400, 500, 600, 700, 800, 900}));
        dts_4 = new DoubleTimeSeries(new DoubleArrayList( new double[] {21, 22, 23, 24, 25, 26, 27, 28, 29}));
        dts_5 = new DoubleTimeSeries(new DoubleArrayList( new double[] {210, 220, 230, 240, 250, 260, 270, 280, 290}));
        dts_6 = new DoubleTimeSeries(new DoubleArrayList( new double[] {2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900}));
    }

    
    /**
     * Test method for {@link VersatileTimeSeriesCollection#checkConsistency()}.
     */
    @Test
    public void add_doubleTimeSeries_success() {
        
        DoubleTimeSeries dts = new DoubleTimeSeries(new DoubleArrayList( new double[] {10, 20, 30, 40, 50, 60, 70, 80, 90}));
        VersatileTimeSeriesCollection vtsc = new VersatileTimeSeriesCollection("collection");
        
        vtsc.add(dts);
                
        VersatileTimeSeries vts = vtsc.getSeries(0);
        
        assertTrue("The time series added to the collection should have the same values than the one "
                + "retrieved from the collection", vts.equals(new VersatileTimeSeries("time series", dts)));  
    }
    
    
    /**
     * Test method for {@link VersatileTimeSeriesCollection#checkConsistency()}.
     */
    @Test
    public void checkConsistency_succeed() {
        
        System.out.println();
        System.out.println("UNIT TEST: checkConsistency_succeed");
        System.out.println();

        VersatileTimeSeriesCollection vtsc = new VersatileTimeSeriesCollection("succeed");
        
        vtsc.populateSeries(0, "dts1", dts_1, 0);
        vtsc.populateSeries(0, "dts2", dts_2, 0);
        vtsc.populateSeries(0, "dts3", dts_3, 0);

        System.out.println(vtsc.printDecoratedSeries("v", 10, true));
        
        assertTrue("The three time series are consistent, so test should succeed", vtsc.checkConsistency());        
    }

    
    /**
     * Test method for {@link VersatileTimeSeriesCollection#checkConsistency()}.
     */
    @Test
    public void populateSeries_exp_run_name_dts_indices_succeed() {
        
        VersatileTimeSeriesCollection vtsc = new VersatileTimeSeriesCollection("collection");

        vtsc.populateSeries(1, 1, "dts1", dts_1);
        vtsc.populateSeries(1, 2, "dts2", dts_2);
        vtsc.populateSeries(1, 3, "dts3", dts_3);
        
        assertEquals("There should be 6 time series in the collection", vtsc.getSeriesCount(), 3);
        assertTrue("The first time series added to the collection is different from the one returned", vtsc.getSeries(0).equals(new VersatileTimeSeries(dts_1.getId(), dts_1)));
        assertTrue("The second time series added to the collection is different from the one returned", vtsc.getSeries(1).equals(new VersatileTimeSeries(dts_2.getId(), dts_2)));
        assertTrue("The third time series added to the collection is different from the one returned", vtsc.getSeries(2).equals(new VersatileTimeSeries(dts_3.getId(), dts_3)));
    }

    
    /**
     * Test method for {@link VersatileTimeSeriesCollection#checkConsistency()}.
     */
    @Test
    public void filterByExperiment_succeed() {
        
        System.out.println();
        System.out.println("UNIT TEST: filterByExperiment_succeed");
        System.out.println();

        VersatileTimeSeriesCollection vtsc = new VersatileTimeSeriesCollection("collection");

        vtsc.populateSeries(1, 1, "dts1", dts_1);
        vtsc.populateSeries(1, 2, "dts2", dts_2);
        vtsc.populateSeries(1, 3, "dts3", dts_3);
        vtsc.populateSeries(1, 1, "dts4", dts_2);
        vtsc.populateSeries(2, 2, "dts5", dts_3);
        vtsc.populateSeries(2, 3, "dts6", dts_1);
        
        System.out.println(vtsc.filterByExperiment(1).printDecoratedSeries("v", 10, true));

        assertEquals("There should be 4 time series in the first experiment", vtsc.filterByExperiment(1).getSeriesCount(), 4);
        assertEquals("There should be 2 time series in the second experiment", vtsc.filterByExperiment(2).getSeriesCount(), 2);
        assertEquals("There should be 6 time series in the first and second experiment", vtsc.filterByExperiment(1,2).getSeriesCount(), 6);
        assertEquals("There should be no time series when filtering by both experiments", vtsc.filterByExperiment(1).filterByExperiment(2).getSeriesCount(), 0);
        
        VersatileTimeSeriesCollection vtscExp_2 = vtsc.filterByExperiment(2);
        
        String id_1 = (String) vtscExp_2.getSeries(0).getKey();
        String id_2 = (String) vtscExp_2.getSeries(1).getKey();

        assertTrue("The time series id has to contain the string 'e2'", id_1.indexOf("e2") > -1);
        assertTrue("The time series id has to contain the string 'e2'", id_2.indexOf("e2") > -1);
    }
    

    /**
     * Test method for {@link VersatileTimeSeriesCollection#checkConsistency()}.
     */
    @Test
    public void checkConsistency_fail() {
        
    }
}
