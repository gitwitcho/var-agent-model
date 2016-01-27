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
package info.financialecology.finance.abm.model;

import info.financialecology.finance.abm.simulation.LPLSEqnParams;
import info.financialecology.finance.abm.simulation.LPLSEqnParams.Sequence;
import info.financialecology.finance.utilities.abm.AbstractSimulator;
import info.financialecology.finance.utilities.datastruct.Datastore;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.datastruct.ResultEnum;

import java.lang.reflect.Type;
import java.util.ArrayList;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import cern.colt.list.DoubleArrayList;
import cern.jet.random.Normal;
import cern.jet.random.Uniform;


/**
 * 
 *  LPLSEquationModel is the model class that implements the long-short strategy for a multi-asset
 *  stock market model. It extends FJEquationModel with a long-short trading strategy, three agent
 *  types (banks, mutual funds, and hedge funds), 
 *  
 *  Based on FJEquationModel
 *      Strategies and agents
 *      - three strategies: fundamental, trend following, arbitrage
 *      - three agent types: mutual funds, hedge funds, banks
 *      - constraints on using strategies:
 *          - mutual fund: fundamental, trend following
 *          - hedge fund: arbitrage
 *          - bank: fundamental, trend following, arbitrage
 *      - parameters: proportion of agent type i using strategy j; provide proportion, eg 1:3:4...
 *      - short-selling and positive cash restrictions for mutual funds, but not for hedge funds and banks
 *      
 *      Assets and cash
 *      - number of assets > 1
 *      - initial price for the n assets
 *      - initial cash (different intervals for the three types)
 *      - initial asset positions are all zero, for the time being and to simplify matters
 *      - reference value processes have to be spawned for the three assets 
 *
 *      Miscellanea
 *      - added class Portfolio to organise position, cash and order for the assets
 * 
 * 
 * @author Gilbert Peffer
 *
 */
public class LPLSEqnModel {
    private static final Logger logger = (Logger)LoggerFactory.getLogger(LPLSEqnModel.class.getSimpleName());

    private AbstractSimulator simulator;
    private LPLSEqnParams params;
    
    
    /**
     * Declaring the results we wish to log
     */
    public enum Results implements ResultEnum {
        LOG_PRICES (DoubleTimeSeriesList.class),
        LOG_REFVALUES (DoubleTimeSeriesList.class),
        ORDER_VALUE (DoubleTimeSeriesList.class),
        ORDER_TREND (DoubleTimeSeriesList.class),
        ORDER_LONGSHORT (DoubleTimeSeriesList.class),
        NET_POS_VALUE (DoubleTimeSeriesList.class),
        NET_POS_TREND (DoubleTimeSeriesList.class),
        NET_POS_LS (DoubleTimeSeriesList.class),
        VOLUME (DoubleTimeSeriesList.class),
        TOTAL_TRADES (DoubleTimeSeriesList.class),
        CASH (DoubleTimeSeriesList.class),
        PAPER_PROFIT_AND_LOSS (DoubleTimeSeriesList.class),
        REALISED_PROFIT_AND_LOSS (DoubleTimeSeriesList.class);

        private final Type mType;

        Results(Type type) {
            this.mType = type;
        }

        public Type type() { return mType; }
    }
    
    private DoubleTimeSeriesList tsLogPrices;
    private DoubleTimeSeriesList tsLogRefValues;
    private DoubleTimeSeriesList tsOrderValue;
    private DoubleTimeSeriesList tsOrderTrend;
    private DoubleTimeSeriesList tsOrderLongShort;
    private DoubleTimeSeriesList storedNetPosVALUE;  // net position of FUND  - list of TS [asset x pos(t)]
    private DoubleTimeSeriesList storedNetPosTREND; // net position of TREND - list of TS [asset x pos(t)]
    private DoubleTimeSeriesList storedNetPosLS;    // net position of LS    - list of TS [asset x pos(t)]
    private DoubleTimeSeriesList tsVolume;
    private DoubleTimeSeriesList tsTotalTrades;
    private DoubleTimeSeriesList storedTotalCash;
    private DoubleTimeSeriesList storedPaperProfitAndLoss;           // P&L due to price change for {MF, HF, B} - list of TS [agent type x P&L(t)]
    private DoubleTimeSeriesList storedRealisedProfitAndLoss;           // P&L due to position change for {MF, HF, B} - list of TS [agent type x P&L(t)]
    
//    public class Cash {
//        public double cashMF = 0;
//        public double cashHF = 0;
//        public double cashB = 0;
//    }
//    
    /**
     * Declaring the random generators
     */
    
    // Market
    ArrayList<Normal> distLogPriceNoise
                      = new ArrayList<Normal>();  // noise distribution for log price process, for each asset
    ArrayList<Normal> distRefValue
                      = new ArrayList<Normal>();  // noise distribution for reference process of log value, for each asset
    
    // All agents
    Uniform distCash;                   // [min, max] uniform distribution of initial cash; the same for all agents
    
    // Value investors 
    ArrayList<Uniform> distOffsetValueVALUE
                       = new ArrayList<Uniform>();   // distribution of agent-specific value offset, for each asset
    Uniform distEntryThreshVALUE;                  // distribution of agent-specific entry threshold
    Uniform distExitThreshVALUE;                   // distribution of agent-specific exit threshold
    
    // Long-short investors
    Uniform distEntryThreshLS;                  // distribution of agent-specific entry threshold
    Uniform distExitThreshLS;                   // distribution of agent-specific exit threshold
    Uniform distMaWindowLS;                     // distribution of trader-specific time horizon for technical strategy
    Uniform distReturnPeriodLS;                 // distribution of trader-specific return period for LS strategy
    
    // Trend followers
    Uniform distDelayTREND;          // distribution of trader-specific time horizon for technical strategy
    Uniform distEntryThreshTREND;    // distribution of trader-specific entry threshold
    Uniform distExitThreshTREND;     // distribution of trader-specific exit threshold
    

    /**
     *  [...]
     *      
     */
    public enum Strategy {
        VALUE,
        TREND,
        LONGSHORT;
    }
    
    class Portfolio {
        public DoubleArrayList position = new DoubleArrayList();
        public double cash;
        public double order;        
    }
        
    public class ValueInvestor {
        Strategy type;
        public Portfolio            portfolio
                                    = new Portfolio();
        public DoubleArrayList      valueOffset          // offset for the log-value processes; different for each asset (FUNDAMENTAL only)
                                    = new DoubleArrayList();
        public double               entryThresh;         // threshold for entering a position; the same for all assets (FUNDAMENTAL and TREND)
        public double               exitThresh;          // threshold for exiting a position; the same for all assets (FUNDAMENTAL and TREND)
        public double               capFac;              // multiplier, to determine orders (can be constant or variable)  (FUNDAMENTAL and TREND)
    }
    
    // TODO create classes for the different strategies to avoid having to index field names with strategy labels
    
    class TrendFollower {
        Strategy type;

        public Portfolio            portfolio 
                                    = new Portfolio();
        public DoubleArrayList      valueOffset          // offset for the log-value processes; different for each asset (FUNDAMENTAL only)
                                    = new DoubleArrayList();
        public int                  delay;            // size of interval to determine log-price trend
        public double               entryThresh; // threshold for entering a position; the same for all assets
        public double               exitThresh;  // threshold for exiting a position; the same for all assets
        public double               capFac;      // multiplier, to determine orders (is either constant or variable)
    }
    
    public class LongShortInvestor {
        Strategy type;
        public Portfolio        portfolio 
                                = new Portfolio();
        public double           entryThresh;   // threshold for entering a position; the same for all assets
        public double           exitThresh;    // threshold for exiting a position; the same for all assets
        public int              returnPeriod;    // period over which to calculate returns for the LS strategy 
        public int              maWindow;        // size of moving average window for return
        public DoubleArrayList  maReturn         // the current moving average of returns
                                = new DoubleArrayList();
        public double           capFac;          // multiplier, to determine orders (can be constant or variable)
    }
    
    ArrayList<ValueInvestor>        valueInvestors      = new ArrayList<ValueInvestor>();    // array of mutual funds 
    ArrayList<TrendFollower>        trendFollowers      = new ArrayList<TrendFollower>();          // array of banks
    ArrayList<LongShortInvestor>    longShortInvestors  = new ArrayList<LongShortInvestor>();     // array of hedge funds
    
    /**
     *  Constructor
     * 
     * @param simulator
     * @param params
     */
    public LPLSEqnModel(AbstractSimulator simulator, LPLSEqnParams params) {
        logger.trace("CONSTUCTOR");
        
        this.params = params;
        this.simulator = simulator;
        
        /**
         *  Create storage space for time series of results
         */
        
        Datastore.logAllResults(Results.class);
        tsLogPrices = Datastore.getResult(DoubleTimeSeriesList.class, Results.LOG_PRICES);
        tsLogRefValues = Datastore.getResult(DoubleTimeSeriesList.class, Results.LOG_REFVALUES);
        tsOrderValue = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_VALUE);
        tsOrderTrend = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_TREND);
        tsOrderLongShort = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_LONGSHORT);
        tsVolume = Datastore.getResult(DoubleTimeSeriesList.class, Results.VOLUME);
        tsTotalTrades = Datastore.getResult(DoubleTimeSeriesList.class, Results.TOTAL_TRADES);
        storedNetPosVALUE= Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_VALUE);
        storedNetPosTREND = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_TREND);
        storedNetPosLS = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_LS);
        storedTotalCash = Datastore.getResult(DoubleTimeSeriesList.class, Results.CASH);
        storedPaperProfitAndLoss= Datastore.getResult(DoubleTimeSeriesList.class, Results.PAPER_PROFIT_AND_LOSS);
        storedRealisedProfitAndLoss= Datastore.getResult(DoubleTimeSeriesList.class, Results.REALISED_PROFIT_AND_LOSS);
        
        for (int i = 0; i < params.nAssets; i++) {
            tsLogPrices.add(i, new DoubleTimeSeries());
            tsLogRefValues.add(i, new DoubleTimeSeries());
            tsOrderValue.add(i, new DoubleTimeSeries());
            tsOrderTrend.add(i, new DoubleTimeSeries());
            tsOrderLongShort.add(i, new DoubleTimeSeries());
            storedNetPosVALUE.add(i, new DoubleTimeSeries());
            storedNetPosTREND.add(i, new DoubleTimeSeries());
            storedNetPosLS.add(i, new DoubleTimeSeries());
            tsVolume.add(i, new DoubleTimeSeries());
            tsTotalTrades.add(i, new DoubleTimeSeries());
        }

        for (int i = 0; i < 3; i++) {   // for each of the three agent types
            storedTotalCash.add(new DoubleTimeSeries());
            storedTotalCash.get(i).add(0.0);
            storedPaperProfitAndLoss.add(new DoubleTimeSeries());
            storedRealisedProfitAndLoss.add(new DoubleTimeSeries());
        }
        
        /**
         *  Defining the random number generators
         */
                
        // All agents
//        distCash = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.CASH);
//
//        // Value investors
//        distEntryThreshVALUE = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.ENTRY_VALUE);
//        distExitThreshVALUE  = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.EXIT_VALUE);
//        
//        // Long-short investors
//        distEntryThreshLS = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.ENTRY_LS);
//        distExitThreshLS = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.EXIT_LS);
//        distMaWindowLS = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.MA_WIN_LS);
//        distReturnPeriodLS = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.R_PERIOD_LS);
//        
//        // Trend followers
//        distEntryThreshTREND = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.ENTRY_TREND);
//        distExitThreshTREND = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.EXIT_TREND);
//        distDelayTREND = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.DELAY_TREND);
//        
//        // Value investors - per-asset distributions
//        for (int i = 0; i < params.nAssets; i++) {
//            distLogPriceNoise.add(i, (Normal) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.LOG_PRICE_NOISE, i));
//            distRefValue.add(i, (Normal) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.LOG_REF_VALUE, i));
//            distOffsetValueVALUE.add(i, (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.OFFSET_VALUE, i));
//        }
        
        createAgentPopulation();
    }
    
    /**
     *  Create the population of agents
     */
    private void createAgentPopulation () {
        
        logger.trace("METHOD: createAgentPopulation()");
        
        // TODO verification: generate agent populations and check numbers and distributional values against parameter file 
        
        // When 'nAgents' is provided, adjust the numbers of the three agent types so that the sum is equal to nAgents 
        if (params.nAgents > 0) {
            int total = params.nValueInvestors + params.nLongShortInvestors + params.nTrendFollowers;
            
            if (total != 0) {
                params.nValueInvestors = Math.round(params.nAgents * params.nValueInvestors / total);
                params.nLongShortInvestors = Math.round(params.nAgents * params.nLongShortInvestors / total);
                params.nTrendFollowers = Math.round(params.nAgents * params.nTrendFollowers / total);
            }
        }
        
        /**
         *  Generate value investor population
         */

        for (int i = 0; i < params.nValueInvestors; i++) {
            ValueInvestor vi = new ValueInvestor();
            
            vi.portfolio = new Portfolio();
            vi.portfolio.order = 0.0;
            vi.portfolio.cash = distCash.nextDouble();

            storedTotalCash.get(0).addToValue(0, vi.portfolio.cash);

            vi.type = Strategy.VALUE;
            
            for (int j = 0; j < params.nAssets; j++) {
                vi.portfolio.position.add(0.0);         // initial position is 0, for all value investors
                vi.valueOffset.add(distOffsetValueVALUE.get(j).nextDouble());  // value offset for asset j and VI i
            }
            
            vi.entryThresh = distEntryThreshVALUE.nextDouble();
            vi.exitThresh = distExitThreshVALUE.nextDouble();

            if (params.constCapFac)
                vi.capFac = params.aVALUE;
            else
                vi.capFac = params.aVALUE * (vi.entryThresh - vi.exitThresh);
                        
            valueInvestors.add(vi);
        }

        /**
         *  Generate long-short population
         */
        
        for (int i = 0; i < params.nLongShortInvestors; i++) {
            LongShortInvestor ls = new LongShortInvestor();
            
            ls.type = Strategy.LONGSHORT;
            
            ls.portfolio = new Portfolio();
            ls.portfolio.order = 0.0;
            ls.portfolio.cash = distCash.nextDouble();

            storedTotalCash.get(1).addToValue(0, ls.portfolio.cash);

            for (int j = 0; j < params.nAssets; j++) {
                ls.portfolio.position.add(0.0);         // initial position is 0, for all MFs
                ls.maReturn.add(0.0);                   // initial asset returns are 0
            }
            
            ls.returnPeriod = distReturnPeriodLS.nextInt();
            ls.maWindow = distMaWindowLS.nextInt();
            
            if (params.constCapFac)
                ls.capFac = params.aLS;
            else
                ls.capFac = params.aLS * (ls.entryThresh - ls.exitThresh);
            
            longShortInvestors.add(ls);
        }
        
        /**
         *  Generate trend follower population
         */
        
        // TODO add toString() functions to agent classes
                
        for (int i = 0; i < params.nTrendFollowers; i++) {
            TrendFollower tf = new TrendFollower();
            
            tf.type = Strategy.TREND;
                           
            tf.portfolio = new Portfolio();
            tf.portfolio.order = 0.0;
            tf.portfolio.cash = distCash.nextDouble();
            
            storedTotalCash.get(2).addToValue(0, tf.portfolio.cash);

            for (int j = 0; j < params.nAssets; j++) {
                tf.portfolio.position.add(0.0);         // initial position is 0, for all TFs
            }
            
            tf.entryThresh = distEntryThreshTREND.nextDouble();
            tf.exitThresh = distExitThreshTREND.nextDouble();
            tf.delay = distDelayTREND.nextInt();
            
            if (params.constCapFac)
                tf.capFac = params.aTREND;
            else
                tf.capFac = params.aTREND * (tf.entryThresh - tf.exitThresh);
            
            trendFollowers.add(tf);
        }
    }
    

    /** 
     * Execute one simulation step
     **/
    public void step() {
        
        int t = (int) simulator.currentTick();
        DoubleArrayList pos = new DoubleArrayList();
        
        // Initialise order time series at t, since the code may not behave well when there are zero agents of some types
        for (int i = 0; i < params.nAssets; i++) {
            tsOrderValue.get(i).add(0.0);
            tsOrderTrend.get(i).add(0.0);
            tsOrderLongShort.get(i).add(0.0);
            storedNetPosVALUE.get(i).add(storedNetPosVALUE.get(i).getValue(t - 1));
            storedNetPosTREND.get(i).add(storedNetPosTREND.get(i).getValue(t - 1));
            storedNetPosLS.get(i).add(storedNetPosLS.get(i).getValue(t - 1));
            tsVolume.get(i).add(0.0);
            tsTotalTrades.get(i).add(0.0);
        }
        
        // TODO group all the code for data storage centrally in a class and provide access methods with a standard calling signature
        // TODO that way data storage and access can be made much more efficient; incl. remove initialisations from warmup() in simulator
        for (int i = 0; i < 3; i++) {       // for each agent type
            storedTotalCash.get(i).add(0.0);
            storedPaperProfitAndLoss.get(i).add(0.0);
            storedRealisedProfitAndLoss.get(i).add(0.0);
        }
                
        // BL check: all add(...) functions for orders and volume are now replaced by set(t, ...) in the remainder of this method

        for (int i = 0; i < params.nAssets; i++) {
            DoubleTimeSeries ts = tsLogRefValues.get(i);
            double logRefValue = ts.getValue(t - 1);          // reference log-value at last tick
            logRefValue += distRefValue.get(i).nextDouble();  // update reference value of asset i for this time step 
            ts.add(t, logRefValue);
        }
                
        // Orders from value investors
        for (int i = 0; i < params.nValueInvestors; i++) {
            ValueInvestor vi = (ValueInvestor) valueInvestors.get(i);
            DoubleTimeSeriesList tsl = null;
            
            pos = calcValuePosition(vi.portfolio.position, vi.valueOffset, vi.entryThresh, vi.exitThresh, vi.capFac, t);
            tsl = tsOrderValue;
            
            double order;
            double cumulativeVolume;
            double cumulativeOrder;
            double cumulativeTrades;
            double totalCashNeeded = 0.0;
            double totalCashAvailable = vi.portfolio.cash;
            double weight = 1.0;    // order weights, to implement borrowing constraint
            
            /**
             * Short sales and borrowing constraints enforced (shortSelling = false, borrowing = false)
             * 
             *      - no short sales: none of the asset positions can be less than zero; since  there is no 
             *                        other constraint, e.g. on asset mix, short sales constraint can be 
             *                        implemented independently for each asset
             *      - no borrowing:   cash position has to be larger or equal to zero; if not, orders are
             *                        reduced on a pro ratio basis so that cash equals zero 
             */
            for (int j = 0; j < params.nAssets; j++) {  // first, the positions according to the short selling constraint
                if ((params.shortSellingAllowed_VALUE == false) && (pos.get(j) < 0))     // selling order would create a negative position (though positive cash, hence no interaction with borrowing constraint)
                    pos.set(j, 0.0);
               
//                if (params.borrowing_MF == false) {
                
                if (pos.get(j) < vi.portfolio.position.get(j))      // cash inflows due to sales orders for the various assets
                    totalCashAvailable += -(pos.get(j) - vi.portfolio.position.get(j)) * Math.exp(tsLogPrices.get(j).get(t - 1));
                else                                                // cash outgoings due to purchase orders for the various assets
                    totalCashNeeded += (pos.get(j) - vi.portfolio.position.get(j)) * Math.exp(tsLogPrices.get(j).get(t - 1));
//                }
            }
            
            // CHECK reversed conditional
            if ((params.borrowingAllowed_VALUE == false) && (totalCashNeeded > totalCashAvailable)) {    // second, calculate a weight in case orders need to be reduced because of the borrowing constraint 
                weight = totalCashAvailable / totalCashNeeded;
//                mf.portfolio.cash = 0.0;             
            }
            else {
                weight = 1.0;
//                mf.portfolio.cash = totalCashAvailable - totalCashNeeded;                
            }
            
            for (int j = 0; j < params.nAssets; j++) {  // third, reduce the positions that generate buying orders so that the cash constraint is satisfied (doesn't touch positions that generate selling orders)
                if ((pos.get(j) > vi.portfolio.position.get(j)) && (weight < 1.0))
                    pos.set(j, weight * (pos.get(j) - vi.portfolio.position.get(j)) + vi.portfolio.position.get(j));    // reducing the order (if 'buy') for each asset so that the borrowing constraint is met

                // TODO After we have scaled the order we should round them down 
                order = pos.get(j) - vi.portfolio.position.get(j);
                
                if (order > 0)  // round down (rather than up) to ensure possible borrowing constraint
                    order = Math.floor(order);
                else    // round up (rather than down) to ensure possible short sales constraint
                    order = Math.ceil(order);
                
                // Adjust position and cash to account for rounded order
                pos.set(j, vi.portfolio.position.get(j) + order);
                vi.portfolio.cash -= order * Math.exp(tsLogPrices.get(j).getValue(t - 1));
                
                if (t == 0) {
                    cumulativeVolume = 0;
                    cumulativeOrder = 0;
                    cumulativeTrades = 0;
                }
                else {
                    cumulativeVolume = tsVolume.get(j).getValue(t);      // current volume
                    cumulativeOrder = tsl.get(j).getValue(t);            // current order
                    cumulativeTrades = tsTotalTrades.get(j).getValue(t); //current number of trades
                }
                
                // BL check: Do not accumulate volume in t with volume in previous steps
                tsVolume.get(j).set(t, Math.abs(order) + cumulativeVolume);
                // BL check: Do not accumulate orders in t with orders in previous steps
                tsl.get(j).set(t, order + cumulativeOrder);
                
                if (order != 0.0)
                    tsTotalTrades.get(j).set(t, cumulativeTrades + 1);
                
                vi.portfolio.position.set(j, pos.get(j));   // set new portfolio positions

                if (vi.type == Strategy.VALUE)
                    storedNetPosVALUE.get(j).set(t, storedNetPosVALUE.get(j).getValue(t) + order);    // update net position in asset j for FUND strategy
                else if (vi.type == Strategy.TREND)
                    storedNetPosTREND.get(j).set(t, storedNetPosTREND.get(j).getValue(t) + order);    // update net position in asset j for TREND strategy
            }

            storedTotalCash.get(0).addToValue(t, vi.portfolio.cash);
        }
        
        // Orders from long-short investors
        for (int i = 0; i < params.nLongShortInvestors; i++) {
            LongShortInvestor ls = (LongShortInvestor) longShortInvestors.get(i);
            
            pos = calcLongShortPosition(ls.portfolio.position, ls.maReturn, ls.returnPeriod, ls.maWindow, ls.capFac, t);
            
            double order;
            double cumulativeVolume;
            double cumulativeTrades;
            double cumulativeOrder;

            for (int j = 0; j < params.nAssets; j++) {
                order = Math.round(pos.get(j) - ls.portfolio.position.get(j));

                if (t == 0) {
                    cumulativeVolume = 0;
                    cumulativeOrder = 0;
                    cumulativeTrades = 0;
                }
                else {
                    cumulativeVolume = tsVolume.get(j).getValue(t);          // current volume
                    cumulativeOrder = tsOrderLongShort.get(j).getValue(t);   // current order
                    cumulativeTrades = tsTotalTrades.get(j).getValue(t);     //current number of trades
                }

                // BL check: Do not accumulate volume in t with volume in previous steps
                tsVolume.get(j).set(t, Math.abs(order) + cumulativeVolume);
                // BL check: Do not accumulate orders in t with orders in previous steps
                tsOrderLongShort.get(j).set(t, order + cumulativeOrder);
                
                if (order != 0.0)
                    tsTotalTrades.get(j).set(t, cumulativeTrades + 1);

                ls.portfolio.position.set(j, pos.get(j));   // set new portfolio positions

                storedNetPosLS.get(j).set(t, storedNetPosLS.get(j).getValue(t) + order);    // update net position in asset j for LS strategy
           }            

            storedTotalCash.get(1).addToValue(t, ls.portfolio.cash);
        }
        
        // TODO the 'set' method in DoubleArrayList throws an exception if the index is out of bound.; create a wrapper class where 'set' allows e.g. to be out of bound by 1 element (sliding expansion, but not allowing out of bound > 1, which seems reasonable) 
        
        // Orders from trend followers
        for (int i = 0; i < params.nTrendFollowers; i++) {
            TrendFollower tf = (TrendFollower) trendFollowers.get(i);
            DoubleArrayList posTREND = null;
            
            posTREND = calcTrendPosition(tf.portfolio.position, tf.delay, tf.entryThresh, tf.exitThresh, tf.capFac, t);
                        
            double order;
            double orderTREND = 0;
            double cumulativeVolume, cumulativeOrder, cumulativeTrades;

            for (int j = 0; j < params.nAssets; j++) {
                double tmpPos = 0.0;

                tmpPos += posTREND.get(j);
                
                order = tmpPos - tf.portfolio.position.get(j);
                
                if (t == 0) {
                    cumulativeVolume = 0;
                    cumulativeTrades = 0;
                }
                else {
                    cumulativeVolume = tsVolume.get(j).getValue(t);  // current volume
                    cumulativeTrades = tsTotalTrades.get(j).getValue(t);     //current number of trades
                }
                
                // BUG Do not accumulate volume in t with volume in previous steps
                tsVolume.get(j).set(t, Math.abs(order) + cumulativeVolume);

                orderTREND = Math.round(posTREND.get(j) - tf.portfolio.position.get(j));

                if (t == 0)
                    cumulativeOrder = 0;
                else
                    cumulativeOrder = tsOrderTrend.get(j).getValue(t);           // current order

                tsOrderTrend.get(j).set(t, orderTREND + cumulativeOrder);                    
            
                tsTotalTrades.get(j).set(t, cumulativeTrades + 1);
                
                tf.portfolio.position.set(j, tmpPos);   // set new portfolio positions

                storedNetPosTREND.get(j).set(t, storedNetPosTREND.get(j).getValue(t) + orderTREND);    // update net position in asset j for FUND strategy
            }

            storedTotalCash.get(3).addToValue(t, tf.portfolio.cash);
        }
        
        // Price dynamics
        for (int i = 0; i < params.nAssets; i++) {
            double noise = distLogPriceNoise.get(i).nextDouble();
            double liquidity = params.getDoubleNumberSequence(Sequence.LIQUIDITY).get(i).get(0);
            double totalOrder = tsOrderValue.get(i).getValue(t) + tsOrderTrend.get(i).getValue(t) + tsOrderLongShort.get(i).getValue(t);
            
            double logPrice_t = tsLogPrices.get(i).getValue(t - 1) + (1 / liquidity) * totalOrder + noise;
            
            tsLogPrices.get(i).add(t, logPrice_t);
            
            // Calculate global P&L of the MFs, HFs, and Bs
            double diffPrice = 0.0;
            double diffPosVALUE, diffPosTREND, diffPosLS;
            
            if (t >= 2)
                diffPrice = Math.exp(tsLogPrices.get(i).getValue(t - 1)) - Math.exp(tsLogPrices.get(i).getValue(t - 2));
            
            diffPosVALUE = storedNetPosVALUE.get(i).getValue(t - 1) - storedNetPosVALUE.get(i).getValue(t); 
            diffPosTREND = storedNetPosTREND.get(i).getValue(t - 1) - storedNetPosTREND.get(i).getValue(t); 
            diffPosLS = storedNetPosLS.get(i).getValue(t - 1) - storedNetPosLS.get(i).getValue(t); 
                        
            // P&L due to price change - paper profit and loss for the three agent types
            double currentValue = storedPaperProfitAndLoss.get(0).get(t);
            storedPaperProfitAndLoss.get(0).set(t, currentValue + diffPrice * storedNetPosVALUE.get(i).getValue(t - 1));
            currentValue = storedPaperProfitAndLoss.get(1).get(t);
            storedPaperProfitAndLoss.get(1).set(t, currentValue + diffPrice * storedNetPosLS.get(i).getValue(t - 1));
            currentValue = storedPaperProfitAndLoss.get(2).get(t);
            storedPaperProfitAndLoss.get(2).set(t, currentValue + diffPrice * storedNetPosTREND.get(i).getValue(t - 1));
            
            // P&L due to position change - realised profit and loss for the three agent types
            currentValue = storedRealisedProfitAndLoss.get(0).get(t);
            storedRealisedProfitAndLoss.get(0).set(t, currentValue + diffPosVALUE * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
            currentValue = storedRealisedProfitAndLoss.get(1).get(t);
            storedRealisedProfitAndLoss.get(1).set(t, currentValue + diffPosLS * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
            currentValue = storedRealisedProfitAndLoss.get(2).get(t);
            storedRealisedProfitAndLoss.get(2).set(t, currentValue + diffPosTREND * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
            
        }
    }
    
    /**
     * Calculate the position for the fundamental strategy
     *  
     */
    private DoubleArrayList calcValuePosition(DoubleArrayList currentPos, DoubleArrayList valueOffset, double entryThresh, double exitThresh, double capFac, int t) {
        DoubleArrayList pos = new DoubleArrayList();
        double logRefValue;
        double logValueFund;
        double diff;
        
//        if (t == 4240) {
//            System.out.println("DEBUG BREAK +++ DEBUG BREAK +++ DEBUG BREAK +++ DEBUG BREAK");  // unconditional breakpoint on this line
//        }
        
        for (int i = 0; i < params.nAssets; i++) {
            logRefValue = tsLogRefValues.get(i).getValue(t);
            logValueFund = logRefValue + valueOffset.get(i);  // value of asset at time t for Agent i
            diff = logValueFund - tsLogPrices.get(i).getValue(t - 1);
            
            // Careful about the overlapping entry and exit channels
            if (Math.abs(diff) > entryThresh) {
                pos.add(Math.round(capFac * diff));
            } 
            else if ((currentPos.get(i) > 0) && (diff > -entryThresh) && (diff <= exitThresh)) {  // we are entering the [T.tau] channel from above (V - p > 0)
                pos.add(0.0);
            }
            else if ((currentPos.get(i) < 0) && (diff > -exitThresh) && (diff <= entryThresh)) {  // we are entering the [T.tau] channel from below (V - p < 0)
                pos.add(0.0);
            }
//            else if (Math.abs(diff) < exitThresh) {
//                pos.add(0.0);
//            } 
            else
                pos.add(currentPos.get(i));
        }
        
        return pos;
    }
    
    /**
     * Calculate the position for the trend following strategy
     * 
     */
    private DoubleArrayList calcTrendPosition(DoubleArrayList currentPos, int delay, double entryThresh, double exitThresh, double capFac, int t) {
        DoubleArrayList pos = new DoubleArrayList();
        double priceTrend, newPos, effectiveDelay;

        
        for (int i = 0; i < params.nAssets; i++) {
            
            /**
             * Adjust the delay in the warm-up phase, where t < delay. The delay determines the prices included in the trend
             * calculation: trend = p_t - p_(t-delay). For delay = 1 for instance, trend = p_t - p_(t-1).
             */ 
            if (t < 2) {  // at this point, with t = 1 for instance, the price at t = 1 is unknown and hence no trend can be computed
                priceTrend = 0;
                effectiveDelay = 1.0;
            }
            else if (t < delay + 2) {
                priceTrend = tsLogPrices.get(i).getValue(t - 1) - tsLogPrices.get(i).getValue(0);   // increasing the trend calculation interval until it reaches 'delay'
                effectiveDelay = t - 1;
            }
            else {
                priceTrend = tsLogPrices.get(i).getValue(t - 1) - tsLogPrices.get(i).getValue(t - delay - 1);
                effectiveDelay = delay;
            }
            
            // Careful about the overlapping entry and exit channels
            if (Math.abs(priceTrend) > entryThresh) {
                newPos = Math.round(capFac * priceTrend);
            } 
            else if ((currentPos.get(i) > 0) && (priceTrend > -entryThresh) && (priceTrend <= exitThresh)) {  // we are entering the [T.tau] channel from above (V - p > 0)
                newPos = 0.0;
            }
            else if ((currentPos.get(i) < 0) && (priceTrend > -exitThresh) && (priceTrend <= entryThresh)) {  // we are entering the [T.tau] channel from below (V - p < 0)
                newPos = 0.0;
            }
//            else if (Math.abs(priceTrend) < exitThresh) {
//                pos.add(0.0);
//            } 
            else
                newPos = currentPos.get(i);
            
            pos.add(newPos / Math.sqrt(effectiveDelay));
        }
        
        return pos;
    }
    
    /**
     * Calculate the position for the long-short strategy
     * 
     */
    private DoubleArrayList calcLongShortPosition(DoubleArrayList currentPos, DoubleArrayList maReturn, int returnPeriod, int maWindow, double capFac, int t) {
        DoubleArrayList pos = new DoubleArrayList();
        double weight;
        double currentReturn = 0;
        double updateMaReturn = 0;
        double averageReturn = 0;    // average of all asset returns 
        double dropReturn;  // return which is dropped; e.g. at t = 4, the log return is calculated as p_3 - p_2
                            // for maWindow = 2 and current t = 6, we need returns at t = 6 and t = 5 and drop return at t = 4
        int returnPeriodStart = returnPeriod < t ? t - returnPeriod - 1 : 0;    // Example: for returnPeriod = 1, at t = 5, the return is calculated with prices at t = {3,4} and returnPeriodStart is 3 
        
        for (int i = 0; i < params.nAssets; i++) {

            // Update the moving average of returns for all assets
            if (t < 2)
                updateMaReturn = 0;
            else if (t < maWindow + 2) {     // Warm-up phase
//                currentReturn = (tsLogPrices.get(i).get(t - 1) - tsLogPrices.get(i).get(t - 2));     // CHECK return calculated over the interval returnPeriod
                currentReturn = (tsLogPrices.get(i).getValue(t - 1) - tsLogPrices.get(i).getValue(returnPeriodStart));     // CHECK return calculated over the interval returnPeriod
                updateMaReturn = (maReturn.get(i) * (t - 2) + currentReturn) / (t - 1);     // update moving average
            }
            else {
                dropReturn = tsLogPrices.get(i).getValue(t - maWindow - 1) - tsLogPrices.get(i).getValue(t - maWindow - 2);
//                currentReturn = (tsLogPrices.get(i).get(t - 1) - tsLogPrices.get(i).get(t - 2));     // CHECK return calculated over the interval returnPeriod
                currentReturn = (tsLogPrices.get(i).getValue(t - 1) - tsLogPrices.get(i).getValue(returnPeriodStart));     // CHECK return calculated over the interval returnPeriod
                updateMaReturn = (maReturn.get(i) * maWindow - dropReturn + currentReturn) / maWindow;
            }

            maReturn.set(i, updateMaReturn);
            averageReturn = (averageReturn * i + updateMaReturn) / (i + 1);     // incremental averaging
            
            // TODO Returns R_k in Khandani's paper can be interpreted as p(t)-p(t-k). Implement this strategy.
        }
        
        // TODO check whether the way of calculating orders makes sense for this strategy (e.g. division by price when prices are very small, though that's the behviour we originally wanted)
        DoubleArrayList weights = new DoubleArrayList();
        double totalAbsWeight = 0.0;
        
        for (int i = 0; i < params.nAssets; i++) {  // buy lower than average return assets and seel higher than average return assets
            weight = -(maReturn.get(i) - averageReturn) / params.nAssets;   // the asset weights sum to zero and represent cash income/outlay from asset sale/purchase, so that total outlay is zero
            weights.add(weight);
            totalAbsWeight += Math.abs(weight);
        }
         
        for (int i = 0; i < params.nAssets; i++) {
//            double normalisedWeight = weights.get(i) / totalAbsWeight;      // absolute values of weights sum to one
            double normalisedWeight = weights.get(i);      // NOTE normalisation seems to create problems for the price dynamics, so we remove it here for testing
//            order = capFac * normalisedWeight / Math.exp(tsLogPrices.get(i).get(t - 1));  // weights represent 'sum(order x price)'
            double newPos = capFac * normalisedWeight / Math.exp(tsLogPrices.get(i).getValue(t - 1));  // asset weights represent proportion in portfolio 'sum(position x price)'
            newPos = newPos / Math.sqrt(returnPeriod);      // CHECK increasing the return period increases the variance of the log return over that period by the length of the period; hence we normalise the stdev here  
            pos.add(Math.round(newPos));
        }

        return pos;
    }        
}
