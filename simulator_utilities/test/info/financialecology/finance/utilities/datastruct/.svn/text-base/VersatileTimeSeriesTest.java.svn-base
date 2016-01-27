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
import info.financialecology.finance.utilities.output.CsvResultReader;

import org.jfree.data.time.Day;
import org.jfree.data.time.Month;
import org.junit.Before;
import org.junit.Test;

import cern.colt.list.DoubleArrayList;

/**
 * @author Gilbert Peffer
 *
 */
public class VersatileTimeSeriesTest {

    /**
     * @throws java.lang.Exception
     */
    @Before
    public void setUp() throws Exception {
    }

    /**
     * Test method for {@link info.financialecology.finance.utilities.datastruct.VersatileTimeSeries#equals(info.financialecology.finance.utilities.datastruct.VersatileTimeSeries)}.
     */
    @Test
    public void equalsVersatileTimeSeries() {
        
        DoubleTimeSeries dts_1 = new DoubleTimeSeries(new DoubleArrayList( new double[] {1, 2, 3, 4, 5, 6, 7, 8, 9}));
        DoubleTimeSeries dts_2 = new DoubleTimeSeries(new DoubleArrayList( new double[] {10, 20, 30, 40, 50, 60, 70, 80, 90}));

        VersatileTimeSeries vts_1 = new VersatileTimeSeries("dts 1", dts_1, new Day(1, 1, 2014));
        VersatileTimeSeries vts_2 = new VersatileTimeSeries("dts 4", dts_1, new Day(1, 1, 2014));
        VersatileTimeSeries vts_3 = new VersatileTimeSeries("dts 3", dts_1, new Day(2, 1, 2014));
        VersatileTimeSeries vts_4 = new VersatileTimeSeries("dts 2", dts_2, new Day(1, 1, 2014));
        VersatileTimeSeries vts_5 = new VersatileTimeSeries("dts 5", dts_1, new Month(1, 2014));
        
        assertTrue("Time series dts_1 and dts_2 should be equal", vts_1.equals(vts_2));
        assertFalse("Time series dts_1 and dts_2 should be different because values are different", vts_1.equals(vts_4));
        assertFalse("Time series dts_1 and dts_3 should be different because the DAY dates are different", vts_1.equals(vts_3));
        assertFalse("Time series dts_1 and dts_5 should be different because the period is MONTH and not DAY", vts_1.equals(vts_5));        
    }
    
    /**
     * Test method for {@link VersatileTimeSeries#operatorAutoCorrelation(int)}.
     * <p>
     * Computes auto-correlations for S&P 500 values from 2010-2014. The index values are stored in a file. 
     */
    @Test
    public void autoCorrelation_SP500() {
        
        System.out.println();
        System.out.println("###: autoCorrelation_SP500");
        System.out.println();

        String fileName = "in/tmp/sp500_2010-2014.csv";
        
        CsvResultReader r = new CsvResultReader(fileName);
        
        DoubleTimeSeriesList dtsl = r.readDoubleTimeSeriesList(false, true);

        DoubleTimeSeries dts = dtsl.get(3);
        VersatileTimeSeries vts = new VersatileTimeSeries("close", dts);
        
        System.out.println(VersatileTimeSeries.printValues(vts.operatorAutoCorrelation(30)));
    }    

}
