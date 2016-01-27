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
package info.financialecology.finance.utilities.output;

import static org.junit.Assert.*;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.VersatileTimeSeriesCollection;

import org.junit.Before;
import org.junit.Test;

import au.com.bytecode.opencsv.CSVWriter;
import cern.colt.list.DoubleArrayList;

/**
 * @author Gilbert Peffer
 *
 */
public class CsvResultWriterTest {
    
    private DoubleArrayList dal;
    private String fileName;

    /**
     * @throws java.lang.Exception
     */
    @Before
    public void setUp() throws Exception {        
    }

    
    /**
     * Test method for {@link CsvResultWriter#write(Object, Object[])}.
     */
    @Test
    public void write() {
        
//        fileName = "../resources/test/tmp/out_write.csv";
//
//        dal = new DoubleArrayList(new double [] {0, 1, 2, 3, 4});
//
//        CsvResultWriter writer = new CsvResultWriter(fileName);
//        writer.write(dal);
    }

    
    /**
     * Test method for {@link CsvResultWriter#write(Object, Object[])}.
     */
    @Test
    public void write_versatileTimeSeriesCollection_success() {
        
        fileName = "resources/test/tmp/out_write_vtsc.csv";

        DoubleTimeSeries dts_1 = new DoubleTimeSeries(new DoubleArrayList( new double[] {1, 2, 3, 4, 5, 6, 7, 8, 9}));
        DoubleTimeSeries dts_2 = new DoubleTimeSeries(new DoubleArrayList( new double[] {10, 20, 30, 40, 50, 60, 70, 80, 90}));
        DoubleTimeSeries dts_3 = new DoubleTimeSeries(new DoubleArrayList( new double[] {100, 200, 300, 400, 500, 600, 700, 800, 900}));
        
        dts_1.setId("dts 1");
        dts_2.setId("dts 2");
        dts_3.setId("dts 3");
        
        VersatileTimeSeriesCollection vtsc = new VersatileTimeSeriesCollection("collection");
        
        vtsc.add(dts_1);
        vtsc.add(dts_2);
        vtsc.add(dts_3);

        CsvResultWriter writer = new CsvResultWriter(fileName);
        writer.write(vtsc);
    }
}
