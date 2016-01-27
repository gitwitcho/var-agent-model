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

package info.financialecology.finance.utilities.datastruct;

import info.financialecology.finance.utilities.Assertion;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.StringUtils;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartFrame;
import org.jfree.chart.ChartTheme;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.StandardChartTheme;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.data.Range;
import org.jfree.data.statistics.SimpleHistogramBin;
import org.jfree.data.statistics.SimpleHistogramDataset;
import org.jfree.data.time.TimeSeriesCollection;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;

/**
 * @author Gilbert Peffer
 *
 */
public class VersatileChart {
    
    private InternalParams params;
    
    public class InternalParams {
        public String title;
        public String xLabel;
        public String yLabel;
        public Boolean legend;
        public Boolean toolTips;
        public Boolean autoRange;
        public double autoRangePadding;
        public int numBins;
        public ChartTheme theme;
        public int rows, cols;
        public Boolean ticks;
        
        public InternalParams () {
            title = "";
            xLabel = "X";
            yLabel = "Y";
            legend = true;
            toolTips = true;
            theme = new StandardChartTheme("no_name");
            rows = 1;
            cols = 1;
            ticks = true;
            autoRange = true;
            autoRangePadding = 0.1;
            numBins = 10;
        }
    }
    
    public VersatileChart() {
        this(new StandardChartTheme("standard_theme"), 1, 1, true);
    }
    
    public VersatileChart(Boolean ticks) {
        this(new StandardChartTheme("standard_theme"), 1, 1, ticks);
    }
    
    public VersatileChart(int rows, int cols, Boolean ticks) {
        this(new StandardChartTheme("standard_theme"), rows, cols, ticks);
    }
    
    public VersatileChart(ChartTheme theme, int rows, int cols, Boolean ticks) {
        this.params = new InternalParams();
    }
    
    public InternalParams getInternalParms() {
        return params;
    }
    
//    public ChartTheme getTheme() {
//        return params.theme;
//    }
//    
//    public VersatileChart setTheme (ChartTheme theme) {
//        params.theme = theme;
//        return this;
//    }
//    
//    public VersatileChart setGridLayout(int rows, int cols) {
//        params.rows = rows;
//        params.cols = cols;
//        return this;
//    }
//    
//    public VersatileChart setTicksOrActual(Boolean ticks) {
//        params.ticks = ticks;
//        return this;
//    }
//    
    public void draw(Object... objects) {
        ArrayList<JFreeChart> charts = new ArrayList<JFreeChart>();

        if ((objects == null) || (objects[0] == null)) return;
        
        Class clazz = objects[0].getClass();
        
        if (clazz == VersatileTimeSeries.class) {
            ArrayList<VersatileTimeSeries> atsArray = new ArrayList<VersatileTimeSeries>();
            
            for (Object o : objects) {
                VersatileTimeSeries ats = (VersatileTimeSeries) o;
                atsArray.add(ats);
            }
            
            charts.add(drawTimeSeries(atsArray));
        }
        else if (clazz == VersatileTimeSeriesCollection.class) {
            ArrayList<VersatileTimeSeriesCollection> atscArray = new ArrayList<VersatileTimeSeriesCollection>();
            
            for (Object o : objects) {
                VersatileTimeSeriesCollection atsc = (VersatileTimeSeriesCollection) o;
                atscArray.add(atsc);
            }
            
            charts.add(drawTimeSeriesCollections(atscArray));
        }
        else if (clazz == VersatileDataTable.class) {
//            ArrayList<VersatileDataTable> acdsArray = new ArrayList<VersatileDataTable>();
//            
//            for (Object o : objects) {
//                VersatileDataTable acds = (VersatileDataTable) o;
//                acdsArray.add(acds);
//            }
//            
//            charts.addAll((drawCategoryDatasets(atscArray));            
        }
        else
            Assertion.assertStrict(false, Assertion.Level.ERR, "Class '" + clazz.toString() + "' currently not supported by VersatileChart");
        
        for (JFreeChart chart : charts) {
            ChartFrame frame = new ChartFrame("UNKNOWN", chart);
            frame.pack();
            frame.setVisible(true);
        }
        
//      frame.getContentPane().setLayout(new GridLayout(numRows, numCols));
//      frame.getContentPane().add(barChart);
//      frame.getContentPane().add(pieChart);
    }
    
    public void drawSimpleHistogram(VersatileTimeSeries ats) {
        ArrayList<VersatileTimeSeries> atsArray = new ArrayList<VersatileTimeSeries>();
        atsArray.add(ats);
        
        JFreeChart chart = drawSimpleHistogram((String) ats.getKey(), atsArray);
        
        ChartFrame frame = new ChartFrame("UNKNOWN", chart);
        frame.pack();
        frame.setVisible(true);        
    }

    public void drawSimpleHistogramExploded(VersatileTimeSeries... atsList) {
        ArrayList<JFreeChart> charts = new ArrayList<JFreeChart>();

        for (VersatileTimeSeries ats : atsList) {
            ArrayList<VersatileTimeSeries> atsArray = new ArrayList<VersatileTimeSeries>();
            atsArray.add(ats);
            JFreeChart chart = drawSimpleHistogram((String) ats.getKey(), atsArray);
            charts.add(chart);
        }
        
        ChartFrame frame;
        
        for (JFreeChart chart : charts) {
            frame = new ChartFrame("UNKNOWN", chart);
            frame.pack();
            frame.setVisible(true);        
        }
    }
    
    public void drawScatterPlot(VersatileDataTable acds, String... xyPairs) {
        ArrayList<JFreeChart> charts = new ArrayList<JFreeChart>();
        
        XYSeriesCollection dataSet = new XYSeriesCollection();
        XYSeries xySeries= new XYSeries("no_name");
        dataSet.addSeries(xySeries);
        
        for (int i = 0; i < xyPairs.length; i += 2) {
            List<String> rowKeys = acds.getRowKeys();
            
            for (String rowKey : rowKeys) {
                if (!StringUtils.startsWith(rowKey, "#")) {
                    double xValue = acds.getValue(rowKey, xyPairs[i]).doubleValue();
                    double yValue = acds.getValue(rowKey, xyPairs[i + 1]).doubleValue();
                    xySeries.add(xValue, yValue);                    
                }        
            }
            
            JFreeChart chart = ChartFactory.createScatterPlot(
                    params.title,
                    params.xLabel,
                    params.yLabel,
                    dataSet,
                    PlotOrientation.VERTICAL,
                    params.legend,
                    params.toolTips,
                    false);
            
            charts.add(chart);
        }
        
        ChartFrame frame;
        
        for (JFreeChart chart : charts) {
            frame = new ChartFrame("UNKNOWN", chart);
            frame.pack();
            frame.setVisible(true);        
        }        
    }
    
    public JFreeChart drawSimpleHistogram(String name, ArrayList<VersatileTimeSeries> atsArray) {
        JFreeChart chart;
        int count = 0;
        double min = 0, max = 0, tmpMin, tmpMax;
        
        for (VersatileTimeSeries ats : atsArray) {
            if (count == 0) {
                min = ats.getMinY();
                max = ats.getMaxY();
            }
            else {
                tmpMin = ats.getMinY();
                tmpMax = ats.getMaxY();
                min = tmpMin < min ? tmpMin : min;
                max = tmpMax > max ? tmpMax : max;
            }
        }
        
        max = max > 0 ? max * 1.05 : max / 1.05; 
        min = min > 0 ? min / 1.05 : min * 1.05; 
        
        SimpleHistogramDataset dataSet = new SimpleHistogramDataset(name);
        
        for (int i = 0; i < params.numBins; i++) {
            double start = min + i * ((max - min) / params.numBins);
            double end = start + ((max - min) / params.numBins) * 0.999999999999;
            
            SimpleHistogramBin histBin = new SimpleHistogramBin(start, end, true, true);
            dataSet.addBin(histBin);
        }
                
        for (VersatileTimeSeries ats : atsArray) {            
            for (int i = 0; i < ats.getItemCount(); i++) {
                double value = ats.getValue(i).doubleValue();
                
                try {
                    dataSet.addObservation(ats.getValue(i).doubleValue());
                }
                catch (Throwable t) {
                    // sometimes this throws an exception when the value falls within the narrow gaps of the bins
                }
            }
        }
        chart = ChartFactory.createHistogram(
                params.title,
                params.xLabel,
                params.yLabel,
                dataSet,
                PlotOrientation.VERTICAL,
                params.legend,
                params.toolTips,
                false);

        return chart;
    }
    
    public JFreeChart drawTimeSeries(ArrayList<VersatileTimeSeries> atsArray) {
        JFreeChart chart;
        ArrayList<String> visibleKeys = new ArrayList<String>();
        
        if (params.ticks) {
            XYSeriesCollection dataSet = new XYSeriesCollection();
            
            for (VersatileTimeSeries ats : atsArray) {
                XYSeries xySeries= new XYSeries(ats.getKey());
                dataSet.addSeries(xySeries);
                
                for (int i = 0; i < ats.getItemCount(); i++)
                    xySeries.add(i, ats.getValue(i));
            }
            
            chart = ChartFactory.createXYLineChart(
                    params.title,
                    params.xLabel,
                    params.yLabel,
                    dataSet,
                    PlotOrientation.VERTICAL,
                    params.legend,
                    params.toolTips,
                    false);
            
            if (params.autoRange) {
                Range currentRange = dataSet.getRangeBounds(true);
                Range newRange = new Range((1 - params.autoRangePadding) * currentRange.getLowerBound(), (1 + params.autoRangePadding) * currentRange.getUpperBound());
                chart.getXYPlot().getRangeAxis().setRange(newRange);
            }
        }            
        else {
            TimeSeriesCollection dataSet = new TimeSeriesCollection();
            
            for (VersatileTimeSeries ats : atsArray) {
                dataSet.addSeries(ats);
                visibleKeys.add((String) ats.getKey());
            }
            
            chart = ChartFactory.createTimeSeriesChart(
                    params.title,
                    params.xLabel,
                    params.yLabel,
                    dataSet,
                    params.legend,
                    params.toolTips,
                    false);
                        
            if (params.autoRange) {
                Range currentRange = dataSet.getRangeBounds(visibleKeys, dataSet.getDomainBounds(true), true);
                Range newRange = new Range((1 - params.autoRangePadding) * currentRange.getLowerBound(), (1 + params.autoRangePadding) * currentRange.getUpperBound());
                chart.getXYPlot().getRangeAxis().setRange(newRange);
            }
        }
        
        return chart;
    }
    
    public JFreeChart drawTimeSeries(VersatileTimeSeries ats) {
        ArrayList<VersatileTimeSeries> atsl = new ArrayList<VersatileTimeSeries>();
        atsl.add(ats);
        
        JFreeChart chart = drawTimeSeries(atsl);
        
        return chart;
    }
    
    public JFreeChart drawTimeSeriesCollections(ArrayList<VersatileTimeSeriesCollection> atscArray) {
        JFreeChart chart;
        ArrayList<String> visibleKeys = new ArrayList<String>();
        
        if (params.ticks) {
            XYSeriesCollection dataSet = new XYSeriesCollection();
            
            for (VersatileTimeSeriesCollection atsc : atscArray) {
                List<VersatileTimeSeries> atsList = atsc.getSeries();
                
                for (VersatileTimeSeries ats : atsList) {
                    XYSeries xySeries= new XYSeries(ats.getKey());
                    dataSet.addSeries(xySeries);
                    
                    for (int i = 0; i < ats.getItemCount(); i++)
                        xySeries.add(i, ats.getValue(i));
                }
            }
            
            chart = ChartFactory.createXYLineChart(
                    params.title,
                    params.xLabel,
                    params.yLabel,
                    dataSet,
                    PlotOrientation.VERTICAL,
                    params.legend,
                    params.toolTips,
                    false);
            
            if (params.autoRange) {
                Range currentRange = dataSet.getRangeBounds(true);
                Range newRange = new Range((1 - params.autoRangePadding) * currentRange.getLowerBound(), (1 + params.autoRangePadding) * currentRange.getUpperBound());
                chart.getXYPlot().getRangeAxis().setRange(newRange);
            }
        }            
        else {
            TimeSeriesCollection dataSet = new TimeSeriesCollection();
            
            for (VersatileTimeSeriesCollection atsc : atscArray) {
                List<VersatileTimeSeries> atsList = atsc.getSeries();
                
                for (VersatileTimeSeries ats : atsList) {
                    dataSet.addSeries(ats);
                    visibleKeys.add((String) ats.getKey());
                }
            }
            
            chart = ChartFactory.createTimeSeriesChart(
                    params.title,
                    params.xLabel,
                    params.yLabel,
                    dataSet,
                    params.legend,
                    params.toolTips,
                    false);
                        
            if (params.autoRange) {
                Range currentRange = dataSet.getRangeBounds(visibleKeys, dataSet.getDomainBounds(true), true);
                Range newRange = new Range((1 - params.autoRangePadding) * currentRange.getLowerBound(), (1 + params.autoRangePadding) * currentRange.getUpperBound());
                chart.getXYPlot().getRangeAxis().setRange(newRange);
            }
        }
        
        return chart;
    }

}
