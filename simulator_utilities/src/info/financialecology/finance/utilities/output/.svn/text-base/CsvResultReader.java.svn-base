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

import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.datastruct.VersatileDataTable;

import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import cern.colt.list.DoubleArrayList;
import cern.colt.list.IntArrayList;
import cern.colt.matrix.*;
import cern.colt.matrix.impl.DenseDoubleMatrix2D;
import au.com.bytecode.opencsv.CSVReader;

/**
 * Read the values from a CSV (comma-separated values) file and store them in objects of different types 
 * Data can be written to objects of the following types:
 * <ul>
 * <li> {@link DoubleArrayList}
 * <li> {@link DoubleTimeSeries}
 * <li> {@link DoubleTimeSeriesList}
 * <li> {@link VersatileDataTable}
 * </ul>  
 * 
 * @author Gilbert Peffer
 *
 */
public class CsvResultReader {
    private static final String     TICK_HEADER = "tick";
    private static final char       SEPARATOR   = ',';
    private CSVReader w;
    
    public enum Format {ROW, COL}

    
    /**
     * Constructor. Uses the default separator {@link #SEPARATOR} for the CSV values.
     * 
     * @param fileName name of the CSV file
     */
    public CsvResultReader(String fileName) {
        try {
            w = new CSVReader(new FileReader(fileName), SEPARATOR);
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    
    /**
     * Constructor. The separator is provided as an argument.
     * 
     * @param fileName name of the input CSV file
     * @param separator the separator of the CSV file 
     */
    public CsvResultReader(String fileName, char separator) {
        try {
            w = new CSVReader(new FileReader(fileName), separator);
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }
    

    /**
     * Read the CSV file and store the values in a {@code ArrayList<IntArrayList>} object. Row and column
     * names in the CSV are ignored, but it needs to be indicated whether they are present using the 
     * {@code isRowNames} and {@code isColNames}. The columns are stored in the {@code IntArrayLists}.
     * 
     * @param isRowNames true if the CSV file contains row names (it is not safe to detect this 
     * automatically)
     * @param isColNames true if the CSV file contains column names (it is not safe to detect this 
     */
    public ArrayList<IntArrayList> readIntMatrix2D(Boolean isRowNames, Boolean isColNames) {
        
        ArrayList<ArrayList<String>> csvTable = readCSVTable(isRowNames, isColNames);     // read the CSV values from the file into the table csvTable (list(0) = row names, list(1) = col names, list (2..n) = values
        
        int numValueRows = csvTable.get(2).size();  // the third array list in the csvTable is the 
        int numValueCols = csvTable.size() - 2;
        
        ArrayList<IntArrayList> matrix = new ArrayList<IntArrayList>();
        
        for (int c = 0; c < numValueCols; c++) {
            
            ArrayList<String> col = csvTable.get(c + 2);
            IntArrayList intCol = new IntArrayList();
            
            for (int r = 0; r < numValueRows; r++)
                intCol.add(Integer.valueOf(col.get(r)));
            
            matrix.add(intCol);
        }
        
        return matrix;
    }

    
    /**
     * Read the CSV file and store the values in a {@code DoubleMatrix2D} object. Row and column
     * names in the CSV are ignored, but it needs to be indicated whether they are present using
     * the {@code isRowNames} and {@code isColNames}.
     * 
     * @param isRowNames true if the CSV file contains row names (it is not safe to detect this 
     * automatically)
     * @param isColNames true if the CSV file contains column names (it is not safe to detect this 
     */
    public DoubleMatrix2D readDoubleMatrix2D(Boolean isRowNames, Boolean isColNames) {
        
        ArrayList<ArrayList<String>> csvTable = readCSVTable(isRowNames, isColNames);     // read the CSV values from the file into the table csvTable (list(0) = row names, list(1) = col names, list (2..n) = values
        
        int numValueRows = csvTable.get(2).size();  // the third array list in the csvTable is the 
        int numValueCols = csvTable.size() - 2;
        
        DoubleMatrix2D matrix = new DenseDoubleMatrix2D(numValueRows, numValueCols);
        
        for (int c = 0; c < numValueCols; c++) {
            
            ArrayList<String> col = csvTable.get(c + 2);
            
            for (int r = 0; r < numValueRows; r++)
                matrix.set(r, c, Double.valueOf(col.get(r)));
        }
        
        return matrix;
    }

    
    /**
     * Read the CSV file and store the values in a {@code DoubleTimeSeries} object.
     * 
     * We expect the first column of the CSV values to contain the tick and the second column the
     * values. Row names are ignored. If a column name is provided, the name of the second column
     * is assigned to the identifier of the time series.  
     *  
     * @param isRowNames true if the CSV file contains row names (it is not safe to detect this 
     * automatically)
     * @param isColNames true if the CSV file contains column names (it is not safe to detect this 
     * automatically)
     */
    public DoubleTimeSeries readDoubleTimeSeries(Boolean isRowNames, Boolean isColNames) {

        ArrayList<ArrayList<String>> csvTable = readCSVTable(isRowNames, isColNames);     // read the CSV values from the file into the table csvTable (list(0) = row names, list(1) = col names, list (2..n) = values
        
        int numValueRows = csvTable.get(2).size();
        
        DoubleTimeSeries dts = new DoubleTimeSeries();
                    
        ArrayList<String> ticks = csvTable.get(2);
        ArrayList<String> values = csvTable.get(3);
            
        for (int r = 0; r < numValueRows; r++)
            dts.add(Integer.valueOf(ticks.get(r)), Double.valueOf(values.get(r)));
        
        if (isColNames) dts.setId(csvTable.get(1).get(0));
        
        return dts;
    }
    
        
    /**
     * Read the CSV file and store the values in a {@link DoubleTimeSeriesList} object. Every
     * column of CSV values is stored in a {@link DoubleTimeSeries}.
     * 
     * We expect the first column of the CSV values (excluding row names) to contain the tick and 
     * the second column the values. Row names are ignored. If a column names are provided, they are
     * assigned to the identifiers of the time series.  
     *  
     * @param isRowNames true if the CSV file contains row names (it is not safe to detect this 
     * automatically)
     * @param isColNames true if the CSV file contains column names (it is not safe to detect this 
     * automatically)
     */
    public DoubleTimeSeriesList readDoubleTimeSeriesList(Boolean isRowNames, Boolean isColNames) {

        ArrayList<ArrayList<String>> csvTable = readCSVTable(isRowNames, isColNames);     // read the CSV values from the file into the table csvTable (list(0) = row names, list(1) = col names, list (2..n) = values
        
        int numValueRows = csvTable.get(2).size();
        int numValueCols = csvTable.size() - 3;
        
        DoubleTimeSeriesList dtsl = new DoubleTimeSeriesList();

        ArrayList<String> ticks = csvTable.get(2);  // the ticks are in array list '2'

        for (int c = 0; c < numValueCols; c++) {
            
            ArrayList<String> values = csvTable.get(c + 3);    // the first variable is in array list '3'
            DoubleTimeSeries dts = new DoubleTimeSeries();
            
            for (int r = 0; r < numValueRows; r++) {
                
                dts.add(Integer.valueOf(ticks.get(r)), Double.valueOf(values.get(r)));

                if (isColNames) dts.setId(csvTable.get(1).get(c));
            }
            
            dtsl.add(dts);
        }
        
        return dtsl;
    }
    
        
    /**
     * Read the CSV file and store the values in a {@link VersatileDataTable} object. Row and column 
     * names are both stored in the object.
     * 
     * @param isRowNames true if the CSV file contains row names (it is not safe to detect this 
     * automatically)
     * @param isColNames true if the CSV file contains column names (it is not safe to detect this 
     * automatically)
     */
    public VersatileDataTable readVersatileDataTable(Boolean isRowNames, Boolean isColNames) {
        
        ArrayList<ArrayList<String>> csvTable = readCSVTable(isRowNames, isColNames);     // read the CSV values from the file into the table csvTable (list(0) = row names, list(1) = col names, list (2..n) = values
        
        int numValueRows = csvTable.get(2).size();
        int numValueCols = csvTable.size() - 2;
        
        VersatileDataTable table = new VersatileDataTable("unlabeled");
        
        for (int c = 0; c < numValueCols; c++)            
            for (int r = 0; r < numValueRows; r++)                
                table.addValue(Double.valueOf(csvTable.get(c + 2).get(r)), csvTable.get(0).get(r), csvTable.get(1).get(c));
        
        return table;
    }


    /**
     * Reads the values of a CSV file, including row and column names, if provided. It stores the
     * strings in am array list of array lists. The first array list contains the row names, the 
     * second the column names, and the remaining array lists contain the columns of the CSV table.
     * 
     *  @author Gilbert Peffer
     */
    private ArrayList<ArrayList<String>> readCSVTable(Boolean isRowNames, Boolean isColNames) {
        
        ArrayList<ArrayList<String>> rowsAndColsAndValues = new ArrayList<ArrayList<String>>();  // array storing the row and column names and the values 
        rowsAndColsAndValues.add(new ArrayList<String>());  // array for the row names
        rowsAndColsAndValues.add(new ArrayList<String>());  // array for the column names

        List<String []> csvLines = null;    // the object holding all the CSV values
        
        try {
            csvLines = w.readAll();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        
        int numRows = csvLines.size();          // number of rows in the CSV file
        int numCols = csvLines.get(0).length;   // number of columns in the CSV file

        int startIndexRows = 0;              // if the col names are provided the CSV values start in row '1' 
        int startIndexCols = 0;              // if the row names are provided the CSV values start in column '1' 
        
        if (isRowNames)  startIndexCols = 1;
        if (isColNames)  startIndexRows = 1;
        
        if (isRowNames) {   // write the row names if they are given
            
            for (int i = startIndexRows; i < numRows; i++)
                rowsAndColsAndValues.get(0).add(csvLines.get(i)[0]);    // row names are stored in array '0'
        }
        
        if (isColNames) {   // write the column names if they are given
            
            for (int i = startIndexCols; i < numCols; i++)
                rowsAndColsAndValues.get(1).add(csvLines.get(0)[i]);    // column names are stored in array '1'
        }
        
        // Generate empty arrays to hold the variables (columns)
        for (int i = 0; i < numCols; i++)
            rowsAndColsAndValues.add(new ArrayList<String>());
        
        // Generate the value arrays, column by column
        for (int i = startIndexCols; i < numCols; i++)    // loop over the column of the CSV 'table'
            for (int j = startIndexRows; j < numRows; j++)
                rowsAndColsAndValues.get(i - startIndexCols + 2).add(csvLines.get(j)[i]);    // add CSV values to column arrays, starting at array '2'
        
        return rowsAndColsAndValues;
    }
}
