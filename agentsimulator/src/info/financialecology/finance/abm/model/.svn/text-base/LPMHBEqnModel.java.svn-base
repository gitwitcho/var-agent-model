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

import info.financialecology.finance.abm.simulation.LPMHBEqnParams;
import info.financialecology.finance.abm.simulation.LPMHBEqnParams.Sequence;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.abm.AbstractSimulator;
import info.financialecology.finance.utilities.datastruct.Datastore;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.datastruct.ResultEnum;

import java.lang.reflect.Type;
import java.util.ArrayList;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import repast.simphony.random.RandomHelper;

import cern.colt.list.DoubleArrayList;
import cern.colt.list.IntArrayList;
import cern.jet.random.Normal;
import cern.jet.random.Uniform;

//import com.cimne.finance.abm.simulation.LPLSEqnParams;
//import com.cimne.finance.abm.simulation.LPLSEqnParams.Sequence;

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
public class LPMHBEqnModel {
    private static final Logger logger = (Logger)LoggerFactory.getLogger(LPMHBEqnModel.class.getSimpleName());

    private AbstractSimulator simulator;
    private LPMHBEqnParams params;
    
    
    /**
     * Declaring the results we wish to log
     */
    public enum Results implements ResultEnum {
        LOG_PRICES (DoubleTimeSeriesList.class),
        LOG_REFVALUES (DoubleTimeSeriesList.class),
        ORDER_FUNDAMENTAL (DoubleTimeSeriesList.class),
        ORDER_TREND (DoubleTimeSeriesList.class),
        ORDER_LONGSHORT (DoubleTimeSeriesList.class),
        NET_POS_MF (DoubleTimeSeriesList.class),
        NET_POS_HF (DoubleTimeSeriesList.class),
        NET_POS_B (DoubleTimeSeriesList.class),
        NET_POS_FUND (DoubleTimeSeriesList.class),
        NET_POS_TREND (DoubleTimeSeriesList.class),
        NET_POS_LS (DoubleTimeSeriesList.class),
        VOLUME (DoubleTimeSeriesList.class),
        TOTAL_TRADES (DoubleTimeSeriesList.class),
        CASH (DoubleTimeSeriesList.class),
        //PROFIT_AND_LOSS (DoubleTimeSeriesList.class),
        PAPER_PROFIT_AND_LOSS (DoubleTimeSeriesList.class),
        REALISED_PROFIT_AND_LOSS (DoubleTimeSeriesList.class),
        //PROFIT_AND_LOSS_STRATEGY (DoubleTimeSeriesList.class),
        PAPER_PROFIT_AND_LOSS_STRATEGY (DoubleTimeSeriesList.class),
        REALISED_PROFIT_AND_LOSS_STRATEGY (DoubleTimeSeriesList.class),
        MUTUAL_FUNDS (ArrayList.class);

        private final Type mType;

        Results(Type type) {
            this.mType = type;
        }

        public Type type() { return mType; }
    }
    
    private DoubleTimeSeriesList tsLogPrices;
    private DoubleTimeSeriesList tsLogRefValues;
    private DoubleTimeSeriesList tsOrderFundamental;
    private DoubleTimeSeriesList tsOrderTrend;
    private DoubleTimeSeriesList tsOrderLongShort;
    private DoubleTimeSeriesList storedNetPosMF;    // net position of MF - list of TS [asset x pos(t)]
    private DoubleTimeSeriesList storedNetPosHF;    // net position of HF - list of TS [asset x pos(t)]
    private DoubleTimeSeriesList storedNetPosB;     // net position of B  - list of TS [asset x pos(t)]
    private DoubleTimeSeriesList storedNetPosFUND;  // net position of FUND  - list of TS [asset x pos(t)]
    private DoubleTimeSeriesList storedNetPosTREND; // net position of TREND - list of TS [asset x pos(t)]
    private DoubleTimeSeriesList storedNetPosLS;    // net position of LS    - list of TS [asset x pos(t)]
    private DoubleTimeSeriesList tsVolume;
    private DoubleTimeSeriesList tsTotalTrades;
    private DoubleTimeSeriesList storedTotalCash;
    //private DoubleTimeSeriesList storedProfitAndLoss;           // P&L for {MF, HF, B} - list of TS [agent type x P&L(t)]
    private DoubleTimeSeriesList storedPaperProfitAndLoss;           // P&L due to price change for {MF, HF, B} - list of TS [agent type x P&L(t)]
    private DoubleTimeSeriesList storedRealisedProfitAndLoss;           // P&L due to position change for {MF, HF, B} - list of TS [agent type x P&L(t)]
    //private DoubleTimeSeriesList storedProfitAndLossStrategy;    // P&L for {FUND, TREND, LS} - list of TS [strategy x P&L(t)]
    private DoubleTimeSeriesList storedPaperProfitAndLossStrategy;    // P&L due to price change for {FUND, TREND, LS} - list of TS [strategy x P&L(t)]
    private DoubleTimeSeriesList storedRealisedProfitAndLossStrategy;    // P&L due to position change for {FUND, TREND, LS} - list of TS [strategy x P&L(t)]
    private ArrayList<MutualFund> lsMutualFunds;
    
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
    
    // Mutual fund - FUNDAMENTAL 
    ArrayList<Uniform> distOffsetValueFUND_MF
                       = new ArrayList<Uniform>();   // distribution of agent-specific value offset, for each asset
    Uniform distEntryThreshFUND_MF;                  // distribution of agent-specific entry threshold
    Uniform distExitThreshFUND_MF;                   // distribution of agent-specific exit threshold
    
    // Mutual fund - TREND
    Uniform distDelayTREND_MF;          // distribution of trader-specific time horizon for technical strategy
    Uniform distEntryThreshTREND_MF;    // distribution of trader-specific entry threshold
    Uniform distExitThreshTREND_MF;     // distribution of trader-specific exit threshold
    
    // Hedge fund - LONGSHORT
    Uniform distEntryThreshLS_HF;                  // distribution of agent-specific entry threshold
    Uniform distExitThreshLS_HF;                   // distribution of agent-specific exit threshold
    Uniform distMaWindowLS_HF;                     // distribution of trader-specific time horizon for technical strategy
    Uniform distReturnPeriodLS_HF;                 // distribution of trader-specific return period for LS strategy
    
    // Bank - FUNDAMENTAL
    ArrayList<Uniform> distOffsetValueFUND_B
                       = new ArrayList<Uniform>();   // distribution of agent-specific value offset, for each asset
    Uniform distEntryThreshFUND_B;                   // distribution of agent-specific entry threshold
    Uniform distExitThreshFUND_B;                    // distribution of agent-specific exit threshold
    
    // Bank - TREND
    Uniform distDelayTREND_B;          // distribution of trader-specific time horizon for technical strategy
    Uniform distEntryThreshTREND_B;    // distribution of trader-specific entry threshold
    Uniform distExitThreshTREND_B;     // distribution of trader-specific exit threshold
    
    // Bank - LONGSHORT
    Uniform distEntryThreshLS_B;                  // distribution of agent-specific entry threshold
    Uniform distExitThreshLS_B;                   // distribution of agent-specific exit threshold
    Uniform distMaWindowLS_B;          // distribution of trader-specific time horizon for technical strategy


    /**
     *  Declaring the three agent types: mutual funds, hedge funds, banks
     *  
     *  Parameters to determine mix of agents and strategies
     *      - N_mutual : N_banks : N_hedge (proportions) and N_total (total number of agents)
     *      - Any mutual fund -> all FUNDAMENTAL or all TREND
     *      - All mutual funds -> N_FUNDAMENTAL : N_TREND (proportion)
     *      - Any hedge fund -> all LONGSHORT
     *      - Any bank -> mix of (FUNDAMENTAL, TREND), LONGSHORT
     *          - the capital factor defines the proportion of fundamental to trend to longshort investment;
     *            a more meaningful apportioning of investments to strategies can only be achieved by limiting 
     *            the capital that the bank can use
     *          - in this model, the capital factor is treated differently for different strategies, though more flexibility could be useful
     *      - All banks -> (N_FUNDAMENTAL, N_TREND) : (N_FUNDAMENTAL, N_TREND, N_LONGSHORT) - proportion of those who use LONGSHORT
     *      
     */
    public enum Strategy {
        FUNDAMENTAL,
        TREND,
        LONGSHORT;
    }
    
    class Portfolio {
        public DoubleArrayList position = new DoubleArrayList();
        public double cash;
        public double order;        
    }
    
    // TODO Since tBank has separate capital factors for FUNDAMENTAL and TREND, MutualFund should have so as well
    
    public class MutualFund {
        Strategy type;
        public Portfolio            portfolio
                                    = new Portfolio();
        public DoubleArrayList      valueOffset          // offset for the log-value processes; different for each asset (FUNDAMENTAL only)
                                    = new DoubleArrayList();
        public double               entryThresh;         // threshold for entering a position; the same for all assets (FUNDAMENTAL and TREND)
        public double               exitThresh;          // threshold for exiting a position; the same for all assets (FUNDAMENTAL and TREND)
        public int                  delay;               // interval size, to calculate log-price trend (TREND only)
        public double               capFac;              // multiplier, to determine orders (can be constant or variable)  (FUNDAMENTAL and TREND)
    }
    
    // TODO create classes for the different strategies to avoid having to index field names with strategy labels
    
    class Bank {
        ArrayList<Strategy>         type              // a bank can use either of the three strategies 
                                    = new ArrayList<Strategy>();
//        public double               percentLS;      // the percentage of fundamental relative to trend strategies used in the bank (works through capital factor calculation)

        public Portfolio            portfolio 
                                    = new Portfolio();
        public DoubleArrayList      valueOffset          // offset for the log-value processes; different for each asset (FUNDAMENTAL only)
                                    = new DoubleArrayList();
        public int                  delay;            // size of interval to determine log-price trend
        public double               entryThreshFUND;  // threshold for entering a position; the same for all assets
        public double               exitThreshFUND;   // threshold for exiting a position; the same for all assets
        public double               entryThreshTREND; // threshold for entering a position; the same for all assets
        public double               exitThreshTREND;  // threshold for exiting a position; the same for all assets
        public double               entryThreshLS;    // threshold for entering a position; the same for all assets
        public double               exitThreshLS;     // threshold for exiting a position; the same for all assets
        public double               capFacFUND;       // multiplier, to determine orders (is either constant or variable)
        public double               capFacTREND;      // multiplier, to determine orders (is either constant or variable)
        public double               capFacLS;         // multiplier, to determine orders (is either constant or variable)
        public int                  maWindow;         // size of moving average window for return
        public DoubleArrayList      maReturn            // the current moving average of returns
                                    = new DoubleArrayList();
    }
    
    public class HedgeFund {
        Strategy type;
        public Portfolio        portfolio 
                                = new Portfolio();
        public double           entryThreshLS;   // threshold for entering a position; the same for all assets
        public double           exitThreshLS;    // threshold for exiting a position; the same for all assets
        public int              returnPeriod;    // period over which to calculate returns for the LS strategy 
        public int              maWindow;        // size of moving average window for return
        public DoubleArrayList  maReturn         // the current moving average of returns
                                = new DoubleArrayList();
        public double           capFac;          // multiplier, to determine orders (can be constant or variable)
    }
    
    ArrayList<MutualFund>   mutualFunds = new ArrayList<MutualFund>();    // array of mutual funds 
    ArrayList<Bank>         banks       = new ArrayList<Bank>();          // array of banks
    ArrayList<HedgeFund>    hedgeFunds  = new ArrayList<HedgeFund>();     // array of hedge funds
    
    /**
     *  Constructor
     * 
     * @param simulator
     * @param params
     */
    public LPMHBEqnModel(AbstractSimulator simulator, LPMHBEqnParams params) {
        logger.trace("CONSTUCTOR");
        
        this.params = params;
        this.simulator = simulator;
        
        /**
         *  Create storage space for time series of results
         */
        
        Datastore.logAllResults(Results.class);
        tsLogPrices = Datastore.getResult(DoubleTimeSeriesList.class, Results.LOG_PRICES);
        tsLogRefValues = Datastore.getResult(DoubleTimeSeriesList.class, Results.LOG_REFVALUES);
        tsOrderFundamental = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_FUNDAMENTAL);
        tsOrderTrend = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_TREND);
        tsOrderLongShort = Datastore.getResult(DoubleTimeSeriesList.class, Results.ORDER_LONGSHORT);
        tsVolume = Datastore.getResult(DoubleTimeSeriesList.class, Results.VOLUME);
        tsTotalTrades = Datastore.getResult(DoubleTimeSeriesList.class, Results.TOTAL_TRADES);
        storedNetPosMF= Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_MF);
        storedNetPosHF = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_HF);
        storedNetPosB = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_B);
        storedNetPosFUND= Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_FUND);
        storedNetPosTREND = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_TREND);
        storedNetPosLS = Datastore.getResult(DoubleTimeSeriesList.class, Results.NET_POS_LS);
        storedTotalCash = Datastore.getResult(DoubleTimeSeriesList.class, Results.CASH);
        //storedProfitAndLoss= Datastore.getResult(DoubleTimeSeriesList.class, Results.PROFIT_AND_LOSS);
        storedPaperProfitAndLoss= Datastore.getResult(DoubleTimeSeriesList.class, Results.PAPER_PROFIT_AND_LOSS);
        storedRealisedProfitAndLoss= Datastore.getResult(DoubleTimeSeriesList.class, Results.REALISED_PROFIT_AND_LOSS);
        //storedProfitAndLossStrategy = Datastore.getResult(DoubleTimeSeriesList.class, Results.PROFIT_AND_LOSS_STRATEGY);
        storedPaperProfitAndLossStrategy = Datastore.getResult(DoubleTimeSeriesList.class, Results.PAPER_PROFIT_AND_LOSS_STRATEGY);
        storedRealisedProfitAndLossStrategy = Datastore.getResult(DoubleTimeSeriesList.class, Results.REALISED_PROFIT_AND_LOSS_STRATEGY);
        lsMutualFunds = Datastore.getResult(ArrayList.class, Results.MUTUAL_FUNDS);
        
        for (int i = 0; i < params.nAssets; i++) {
            tsLogPrices.add(i, new DoubleTimeSeries());
            tsLogRefValues.add(i, new DoubleTimeSeries());
            tsOrderFundamental.add(i, new DoubleTimeSeries());
            tsOrderTrend.add(i, new DoubleTimeSeries());
            tsOrderLongShort.add(i, new DoubleTimeSeries());
            storedNetPosMF.add(i, new DoubleTimeSeries());
            storedNetPosHF.add(i, new DoubleTimeSeries());
            storedNetPosB.add(i, new DoubleTimeSeries());
            storedNetPosFUND.add(i, new DoubleTimeSeries());
            storedNetPosTREND.add(i, new DoubleTimeSeries());
            storedNetPosLS.add(i, new DoubleTimeSeries());
            tsVolume.add(i, new DoubleTimeSeries());
            tsTotalTrades.add(i, new DoubleTimeSeries());
        }

        for (int i = 0; i < 3; i++) {   // for each agent type {MF, HF, B}
            storedTotalCash.add(new DoubleTimeSeries());
            storedTotalCash.get(i).add(0.0);
            //storedProfitAndLoss.add(new DoubleTimeSeries());
            storedPaperProfitAndLoss.add(new DoubleTimeSeries());
            storedRealisedProfitAndLoss.add(new DoubleTimeSeries());
        }
        
        for (int i = 0; i < 3; i++) {   // for each strategy {TREND, FUND, LS}
            //storedProfitAndLossStrategy.add(new DoubleTimeSeries());
            storedPaperProfitAndLossStrategy.add(new DoubleTimeSeries());
            storedRealisedProfitAndLossStrategy.add(new DoubleTimeSeries());
        }
        
        /**
         *  Defining the random number generators
         */
        
//        // All agents
//        distCash = assignUniform(params, Sequence.CASH);
//
//        // Mutual fund - FUNDAMENTAL
//        distEntryThreshFUND_MF = assignUniform(params, Sequence.T_FUND_MF);
//        distExitThreshFUND_MF  = assignUniform(params, Sequence.TAU_FUND_MF);
//        
//        // Mutual fund - TREND
//        distEntryThreshTREND_MF = assignUniform(params, Sequence.T_TREND_MF);
//        distExitThreshTREND_MF = assignUniform(params, Sequence.TAU_TREND_MF);
//        distDelayTREND_MF = assignUniform(params, Sequence.DELAY_TREND_MF);
//        
//        // Hedge fund - LONGSHORT
//        distEntryThreshLS_HF = assignUniform(params, Sequence.T_LS_HF);
//        distExitThreshLS_HF = assignUniform(params, Sequence.TAU_LS_HF);
//        distMaWindowLS_HF = assignUniform(params, Sequence.MA_WIN_LS_HF);
//        distReturnPeriodLS_HF = assignUniform(params, Sequence.R_PERIOD_LS_HF);
//        
//        // Bank - FUNDAMENTAL
//        distEntryThreshFUND_B = assignUniform(params, Sequence.T_FUND_B);
//        distExitThreshFUND_B = assignUniform(params, Sequence.TAU_FUND_B);
//        
//        // Bank - TREND
//        distDelayTREND_B = assignUniform(params, Sequence.DELAY_TREND_B);
//        distEntryThreshTREND_B = assignUniform(params, Sequence.T_TREND_B);
//        distExitThreshTREND_B = assignUniform(params, Sequence.TAU_TREND_B);
//        
//        // Bank - LONGSHORT
//        distEntryThreshLS_B = assignUniform(params, Sequence.T_LS_B);
//        distExitThreshLS_B = assignUniform(params, Sequence.TAU_LS_B);
//        distMaWindowLS_B = assignUniform(params, Sequence.MA_WIN_LS_B);
//
//        // Market; Mutual funds, banks (FUNDAMENTAL) - per-asset distributions
//        for (int i = 0; i < params.nAssets; i++) {
//            distLogPriceNoise.add(i, assignNormal(params, Sequence.PRICE_NOISE));
//            distRefValue.add(i, assignNormal(params, Sequence.REF_VALUE));
//            distOffsetValueFUND_MF.add(i, assignUniform(params, Sequence.OFFSET_VALUE));
//            distOffsetValueFUND_B.add(i, assignUniform(params, Sequence.OFFSET_VALUE));
//        }
        
        // #############################################
        //
        // TODO RANDOM NUMBER GENERATION NEEDS TO BE ADAPTED TO THE NEW RANDOMGENERATORPOOL
        //
        // #############################################
        
        // All agents
//        distCash = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.CASH);
//
//        // Mutual fund - FUNDAMENTAL
//        distEntryThreshFUND_MF = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.ENTRY_VALUE);
//        distExitThreshFUND_MF  = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.EXIT_VALUE);
//        
//        // Mutual fund - TREND
////        distEntryThreshTREND_MF = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions..T_TREND_MF);
////        distExitThreshTREND_MF = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.TAU_TREND_MF);
////        distDelayTREND_MF = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.DELAY_TREND_MF);
//        
//        // Hedge fund - LONGSHORT
//        distEntryThreshLS_HF = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.ENTRY_LS);
//        distExitThreshLS_HF = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.EXIT_LS);
//        distMaWindowLS_HF = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.MA_WIN_LS);
//        distReturnPeriodLS_HF = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.R_PERIOD_LS);
//        
//        // Bank - FUNDAMENTAL
////        distEntryThreshFUND_B = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.T_FUND_B);
////        distExitThreshFUND_B = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.TAU_FUND_B);
//        
//        // Bank - TREND
//        distEntryThreshTREND_B = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.ENTRY_TREND);
//        distExitThreshTREND_B = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.EXIT_TREND);
//        distDelayTREND_B = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.DELAY_TREND);
//        
//        // Bank - LONGSHORT
////        distEntryThreshLS_B = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.T_LS_B);
////        distExitThreshLS_B = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.TAU_LS_B);
////        distMaWindowLS_B = (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.MA_WIN_LS_B);
//
//        // Market; Mutual funds, banks (FUNDAMENTAL) - per-asset distributions
//        for (int i = 0; i < params.nAssets; i++) {
//            distLogPriceNoise.add(i, (Normal) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.LOG_PRICE_NOISE, i));
//            distRefValue.add(i, (Normal) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.LOG_REF_VALUE, i));
//            distOffsetValueFUND_MF.add(i, (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.OFFSET_VALUE, i));
////            distOffsetValueFUND_B.add(i, (Uniform) LPLSRandomGeneratorPool.getDistribution(LPLSRandomGeneratorPool.Distributions.OFFSET_VALUE_B, i));
//        }
        
        
        
        createAgentPopulation();
    }
    
    /**
     *  Create the population of agents
     */
    private void createAgentPopulation () {
        
        logger.trace("METHOD: createAgentPopulation()");
        
        // TODO verification: generate agent populations and check numbers and distributional values against parameter file 
        
        // Number of agents when 'nAgents' is provided
        if (params.nAgents > 0) {
            int total = params.nMutualFunds + params.nHedgeFunds + params.nBanks;
            
            if (total != 0) {
                params.nMutualFunds = Math.round(params.nAgents * params.nMutualFunds / total);
                params.nHedgeFunds = Math.round(params.nAgents * params.nHedgeFunds / total);
                params.nBanks = Math.round(params.nAgents * params.nBanks / total);
            }
        }
        
        /**
         *  Generate mutual fund population
         */

        int nFUND_MF = (int) Math.round(params.nMutualFunds * params.proportionFUND_MF);
        
        for (int i = 0; i < params.nMutualFunds; i++) {
            MutualFund mf = new MutualFund();
            
            mf.portfolio = new Portfolio();
            mf.portfolio.order = 0.0;
            mf.portfolio.cash = distCash.nextDouble();

            storedTotalCash.get(0).addToValue(0, mf.portfolio.cash);

            if (i < nFUND_MF)   // TODO this has to be randomised when more such assignments are made, otherwise it introduces spurious dependencies 
                mf.type = Strategy.FUNDAMENTAL;
            else
                mf.type = Strategy.TREND;
            
            for (int j = 0; j < params.nAssets; j++) {
                mf.portfolio.position.add(0.0);         // initial position is 0, for all MFs
               
                if (mf.type == Strategy.FUNDAMENTAL)
                    mf.valueOffset.add(distOffsetValueFUND_MF.get(j).nextDouble());  // value offset for asset j and MF i
            }
            
            if (mf.type == Strategy.FUNDAMENTAL) {
                mf.entryThresh = distEntryThreshFUND_MF.nextDouble();
                mf.exitThresh = distExitThreshFUND_MF.nextDouble();
                mf.delay = -1;

                if (params.constCapFac)
                    mf.capFac = params.aFUND_MF;
                else
                    mf.capFac = params.aFUND_MF * (mf.entryThresh - mf.exitThresh);
            }
            else if (mf.type == Strategy.TREND) {
                mf.valueOffset = null;
                mf.entryThresh = distEntryThreshTREND_MF.nextDouble();
                mf.exitThresh = distExitThreshTREND_MF.nextDouble();
                mf.delay = distDelayTREND_MF.nextInt();

                if (params.constCapFac)
                    mf.capFac = params.aTREND_MF;
                else
                    mf.capFac = params.aTREND_MF * (mf.entryThresh - mf.exitThresh);
            }
                        
            mutualFunds.add(mf);
            lsMutualFunds.add(mf);
        }

        /**
         *  Generate hedge fund population
         */
        
        for (int i = 0; i < params.nHedgeFunds; i++) {
            HedgeFund hf = new HedgeFund();
            
            hf.type = Strategy.LONGSHORT;
            
            hf.portfolio = new Portfolio();
            hf.portfolio.order = 0.0;
            hf.portfolio.cash = distCash.nextDouble();

            storedTotalCash.get(1).addToValue(0, hf.portfolio.cash);

            for (int j = 0; j < params.nAssets; j++) {
                hf.portfolio.position.add(0.0);         // initial position is 0, for all MFs
                hf.maReturn.add(0.0);                   // initial asset returns are 0
            }
            
            hf.returnPeriod = distReturnPeriodLS_HF.nextInt();
            hf.maWindow = distMaWindowLS_HF.nextInt();
            
            if (params.constCapFac)
                hf.capFac = params.aLS_HF;
            else
                hf.capFac = params.aLS_HF * (hf.entryThreshLS - hf.exitThreshLS);
            
            hedgeFunds.add(hf);
        }
        
        /**
         *  Generate bank population
         *  
         *  BA_STRATEGIES: proportion of BAs using LS strategies (0.2 = 20% of BAs use LS strategy in addition to FUND + TREND)
         *      - format: [a,b]
         *      - a,b: bounds of the uniform distribution U[a,b]; 'a' = minimum and 'b' = maximum of proportion
         *      
         */
        
        // TODO add maReturn and capFacLS and initialise
        // TODO add toString() functions to agent classes
        
        // Number of banks using the LS strategy
        int nLS_B = (int) Math.round(params.nBanks * params.proportionLS_B);
        
        for (int i = 0; i < params.nBanks; i++) {
            Bank ba = new Bank();
            
            ba.type.add(0, Strategy.FUNDAMENTAL);
            ba.type.add(1, Strategy.TREND);
            
            if (i < nLS_B)    // TODO should be randomised
                ba.type.add(2, Strategy.LONGSHORT);
            
//            ba.percentFund = distPercentB_LS.nextDouble();
               
            ba.portfolio = new Portfolio();
            ba.portfolio.order = 0.0;
            ba.portfolio.cash = distCash.nextDouble();
            
            storedTotalCash.get(2).addToValue(0, ba.portfolio.cash);

            for (int j = 0; j < params.nAssets; j++) {
                ba.portfolio.position.add(0.0);         // initial position is 0, for all MFs
                ba.valueOffset.add(distOffsetValueFUND_B.get(j).nextDouble());  // value offset for asset j and MF i
            }
            
            ba.entryThreshFUND = distEntryThreshFUND_B.nextDouble();
            ba.exitThreshFUND = distExitThreshFUND_B.nextDouble();
            ba.entryThreshTREND = distEntryThreshTREND_B.nextDouble();
            ba.exitThreshTREND = distExitThreshTREND_B.nextDouble();
            ba.delay = distDelayTREND_B.nextInt();
            ba.maWindow = distMaWindowLS_B.nextInt();
            
            if (params.constCapFac) {
                ba.capFacFUND = params.aFUND_B;
                ba.capFacTREND = params.aTREND_B;
                ba.capFacLS = params.aLS_B;
            }
            else {
                ba.capFacFUND = params.aFUND_B * (ba.entryThreshFUND - ba.exitThreshFUND);
                ba.capFacTREND = params.aTREND_B * (ba.entryThreshTREND - ba.exitThreshTREND);
                ba.capFacLS = params.aLS_B * (ba.entryThreshLS - ba.exitThreshLS);
            }
            
            banks.add(ba);
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
            tsOrderFundamental.get(i).add(0.0);
            tsOrderTrend.get(i).add(0.0);
            tsOrderLongShort.get(i).add(0.0);
            storedNetPosMF.get(i).add(storedNetPosMF.get(i).getValue(t - 1));
            storedNetPosHF.get(i).add(storedNetPosHF.get(i).getValue(t - 1));
            storedNetPosB.get(i).add(storedNetPosB.get(i).getValue(t - 1));
            storedNetPosFUND.get(i).add(storedNetPosFUND.get(i).getValue(t - 1));
            storedNetPosTREND.get(i).add(storedNetPosTREND.get(i).getValue(t - 1));
            storedNetPosLS.get(i).add(storedNetPosLS.get(i).getValue(t - 1));
            tsVolume.get(i).add(0.0);
            tsTotalTrades.get(i).add(0.0);
        }
        
        // TODO group all the code for data storage centrally in a class and provide access methods with a standard calling signature
        // TODO that way data storage and access can be made much more efficient; incl. remove initialisations from warmup() in simulator
        for (int i = 0; i < 3; i++) {
            storedTotalCash.get(i).add(0.0);
            //storedProfitAndLoss.get(i).add(0.0);
            storedPaperProfitAndLoss.get(i).add(0.0);
            storedRealisedProfitAndLoss.get(i).add(0.0);
        }
        
        for (int i = 0; i < 3; i++) {
            //storedProfitAndLossStrategy.get(i).add(0.0);
            storedPaperProfitAndLossStrategy.get(i).add(0.0);
            storedRealisedProfitAndLossStrategy.get(i).add(0.0);
        }
        
        // BL check: all add(...) functions for orders and volume are now replaced by set(t, ...) in the remainder of this method

        for (int i = 0; i < params.nAssets; i++) {
            DoubleTimeSeries ts = tsLogRefValues.get(i);
            double logRefValue = ts.getValue(t - 1);          // reference log-value at last tick
            logRefValue += distRefValue.get(i).nextDouble();  // update reference value of asset i for this time step 
            ts.add(t, logRefValue);
        }
                
        // Orders from mutual funds
        for (int i = 0; i < params.nMutualFunds; i++) {
            MutualFund mf = (MutualFund) mutualFunds.get(i);
            DoubleTimeSeriesList tsl = null;
            
            if (mf.type == Strategy.FUNDAMENTAL) {
                pos = calcFundamentalPosition(mf.portfolio.position, mf.valueOffset, mf.entryThresh, mf.exitThresh, mf.capFac, t);
                tsl = tsOrderFundamental;
            }
            else if (mf.type == Strategy.TREND) {
                pos = calcTrendPosition(mf.portfolio.position, mf.delay, mf.entryThresh, mf.exitThresh, mf.capFac, t);
                tsl = tsOrderTrend;
            }
            
            double order;
            double cumulativeVolume;
            double cumulativeOrder;
            double cumulativeTrades;
            double totalCashNeeded = 0.0;
            double totalCashAvailable = mf.portfolio.cash;
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
                if ((params.shortSellingAllowed_MF == false) && (pos.get(j) < 0))     // selling order would create a negative position (though positive cash, hence no interaction with borrowing constraint)
                    pos.set(j, 0.0);
               
//                if (params.borrowing_MF == false) {
                
                if (pos.get(j) < mf.portfolio.position.get(j))      // cash inflows due to sales orders for the various assets
                    totalCashAvailable += -(pos.get(j) - mf.portfolio.position.get(j)) * Math.exp(tsLogPrices.get(j).get(t - 1));
                else                                                // cash outgoings due to purchase orders for the various assets
                    totalCashNeeded += (pos.get(j) - mf.portfolio.position.get(j)) * Math.exp(tsLogPrices.get(j).get(t - 1));
//                }
            }
            
            // CHECK reversed conditional
            if ((params.borrowingAllowed_MF == false) && (totalCashNeeded > totalCashAvailable)) {    // second, calculate a weight in case orders need to be reduced because of the borrowing constraint 
                weight = totalCashAvailable / totalCashNeeded;
//                mf.portfolio.cash = 0.0;             
            }
            else {
                weight = 1.0;
//                mf.portfolio.cash = totalCashAvailable - totalCashNeeded;                
            }
            
            for (int j = 0; j < params.nAssets; j++) {  // third, reduce the positions that generate buying orders so that the cash constraint is satisfied (doesn't touch positions that generate selling orders)
                if ((pos.get(j) > mf.portfolio.position.get(j)) && (weight < 1.0))
                    pos.set(j, weight * (pos.get(j) - mf.portfolio.position.get(j)) + mf.portfolio.position.get(j));    // reducing the order (if 'buy') for each asset so that the borrowing constraint is met

                // TODO After we have scaled the order we should round them down 
                order = pos.get(j) - mf.portfolio.position.get(j);
                
                if (order > 0)  // round down (rather than up) to ensure possible borrowing constraint
                    order = Math.floor(order);
                else    // round up (rather than down) to ensure possible short sales constraint
                    order = Math.ceil(order);
                
                // Adjust position and cash to account for rounded order
                pos.set(j, mf.portfolio.position.get(j) + order);
                mf.portfolio.cash -= order * Math.exp(tsLogPrices.get(j).getValue(t - 1));
                
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
                
                mf.portfolio.position.set(j, pos.get(j));   // set new portfolio positions
                storedNetPosMF.get(j).set(t, storedNetPosMF.get(j).getValue(t) + order);    // update net position in asset j for MF type

                if (mf.type == Strategy.FUNDAMENTAL)
                    storedNetPosFUND.get(j).set(t, storedNetPosFUND.get(j).getValue(t) + order);    // update net position in asset j for FUND strategy
                else if (mf.type == Strategy.TREND)
                    storedNetPosTREND.get(j).set(t, storedNetPosTREND.get(j).getValue(t) + order);    // update net position in asset j for TREND strategy
            }

            storedTotalCash.get(0).addToValue(t, mf.portfolio.cash);
        }
        
        // Orders from hedge funds
        for (int i = 0; i < params.nHedgeFunds; i++) {
            HedgeFund hf = (HedgeFund) hedgeFunds.get(i);
            
            pos = calcLongShortPosition(hf.portfolio.position, hf.maReturn, hf.returnPeriod, hf.maWindow, hf.capFac, t);
            
            double order;
            double cumulativeVolume;
            double cumulativeTrades;
            double cumulativeOrder;

            for (int j = 0; j < params.nAssets; j++) {
                order = Math.round(pos.get(j) - hf.portfolio.position.get(j));

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

                hf.portfolio.position.set(j, pos.get(j));   // set new portfolio positions
                storedNetPosHF.get(j).set(t, storedNetPosHF.get(j).getValue(t) + order);    // update net position in asset j for HF type

                storedNetPosLS.get(j).set(t, storedNetPosLS.get(j).getValue(t) + order);    // update net position in asset j for LS strategy
           }            

            storedTotalCash.get(1).addToValue(t, hf.portfolio.cash);
        }
        
        // TODO implement percentage fundamental vs. trend strategies, in the capital factor calculation
        // TODO the 'set' method in DoubleArrayList throws an exception if the index is out of bound.; create a wrapper class where 'set' allows e.g. to be out of bound by 1 element (sliding expansion, but not allowing out of bound > 1, which seems reasonable) 
        
        // Orders from banks
        for (int i = 0; i < params.nBanks; i++) {
            Bank ba = (Bank) banks.get(i);
            DoubleArrayList posFUND = null, posTREND = null, posLS = null;
            
            if (ba.type.contains(Strategy.FUNDAMENTAL))
                posFUND = calcFundamentalPosition(ba.portfolio.position, ba.valueOffset, ba.entryThreshFUND, ba.exitThreshFUND, ba.capFacFUND, t);
            
            if (ba.type.contains(Strategy.TREND))
                posTREND = calcTrendPosition(ba.portfolio.position, ba.delay, ba.entryThreshTREND, ba.exitThreshTREND, ba.capFacTREND, t);
            
            if (ba.type.contains(Strategy.LONGSHORT))
                posLS = calcLongShortPosition(ba.portfolio.position, ba.maReturn, 1, ba.maWindow, ba.capFacLS, t);  // TODO add return period for banks to parameters
            
            double order;
            double orderFUND = 0, orderTREND = 0, orderLS = 0;
            double cumulativeVolume, cumulativeOrder, cumulativeTrades;

            for (int j = 0; j < params.nAssets; j++) {
                double tmpPos = 0.0;

                if (posFUND != null)
                    tmpPos += posFUND.get(j);
                if (posTREND != null)
                    tmpPos += posTREND.get(j);
                if (posLS != null)
                    tmpPos += posLS.get(j);
                
                order = tmpPos - ba.portfolio.position.get(j);
                
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

                if (posFUND != null) {
                    orderFUND = Math.round(posFUND.get(j) - ba.portfolio.position.get(j));
                    
                    if (t == 0)
                        cumulativeOrder = 0;
                    else
                        cumulativeOrder = tsOrderFundamental.get(j).getValue(t);     // current order
                    
                    // BL check: Do not accumulate orders in t with orders in previous steps
                    tsOrderFundamental.get(j).set(t, orderFUND + cumulativeOrder);
                }
                
                if (posTREND != null) {
                    orderTREND = Math.round(posTREND.get(j) - ba.portfolio.position.get(j));

                    if (t == 0)
                        cumulativeOrder = 0;
                    else
                        cumulativeOrder = tsOrderTrend.get(j).getValue(t);           // current order

                    tsOrderTrend.get(j).set(t, orderTREND + cumulativeOrder);                    
                }
                
                if (posLS != null) {
                    orderLS = Math.round(posLS.get(j) - ba.portfolio.position.get(j));

                    if (t == 0)
                        cumulativeOrder = 0;
                    else
                        cumulativeOrder = tsOrderLongShort.get(j).getValue(t);       // current order
                    
                    // BL check: Do not accumulate orders in t with orders in previous steps
                    tsOrderLongShort.get(j).set(t, orderLS + cumulativeOrder);                    
                }
                
                if (orderFUND != 0.0)
                    tsTotalTrades.get(j).set(t, cumulativeTrades + 1);
                
                if (orderTREND != 0.0)
                    tsTotalTrades.get(j).set(t, cumulativeTrades + 1);
                
                if (orderLS != 0.0)     // each order for the long-short strategy involves two trades
                    tsTotalTrades.get(j).set(t, cumulativeTrades + 2);  
                
                ba.portfolio.position.set(j, tmpPos);   // set new portfolio positions
                storedNetPosB.get(j).set(t, storedNetPosB.get(j).getValue(t) + order);    // update net position in asset j for B type

                storedNetPosFUND.get(j).set(t, storedNetPosFUND.get(j).getValue(t) + orderFUND);    // update net position in asset j for FUND strategy
                storedNetPosTREND.get(j).set(t, storedNetPosTREND.get(j).getValue(t) + orderTREND);    // update net position in asset j for FUND strategy
                storedNetPosLS.get(j).set(t, storedNetPosLS.get(j).getValue(t) + orderLS);    // update net position in asset j for FUND strategy
            }

            storedTotalCash.get(3).addToValue(t, ba.portfolio.cash);
        }
        
        // Price dynamics
        for (int i = 0; i < params.nAssets; i++) {
            double noise = distLogPriceNoise.get(i).nextDouble();
            double liquidity = params.getDoubleNumberSequence(Sequence.LIQUIDITY).get(i).get(0);
            double totalOrder = tsOrderFundamental.get(i).getValue(t) + tsOrderTrend.get(i).getValue(t) + tsOrderLongShort.get(i).getValue(t);
            
            double logPrice_t = tsLogPrices.get(i).getValue(t - 1) + (1 / liquidity) * totalOrder + noise;
            
    //            logger.trace("Total orders: {}", totalOrderFund + totalOrderTech);
    //            logger.trace("Log price: {}", logPrice_t);
    //            logger.trace("Price: {}", Math.exp(logPrice_t));
    
            tsLogPrices.get(i).add(t, logPrice_t);
            
            // Calculate global P&L of the MFs, HFs, and Bs
            double diffPrice = 0.0;
            double diffPosFUND, diffPosTREND, diffPosLS, diffPosMF, diffPosHF, diffPosB;
            
            if (t >= 2)
                diffPrice = Math.exp(tsLogPrices.get(i).getValue(t - 1)) - Math.exp(tsLogPrices.get(i).getValue(t - 2));
            
            diffPosMF = storedNetPosMF.get(i).getValue(t - 1) - storedNetPosMF.get(i).getValue(t); 
            diffPosHF = storedNetPosHF.get(i).getValue(t - 1) - storedNetPosHF.get(i).getValue(t); 
            diffPosB = storedNetPosB.get(i).getValue(t - 1) - storedNetPosB.get(i).getValue(t); 
            
            diffPosFUND = storedNetPosFUND.get(i).getValue(t - 1) - storedNetPosFUND.get(i).getValue(t); 
            diffPosTREND = storedNetPosTREND.get(i).getValue(t - 1) - storedNetPosTREND.get(i).getValue(t); 
            diffPosLS = storedNetPosLS.get(i).getValue(t - 1) - storedNetPosLS.get(i).getValue(t); 
            
            // P&L - profit and loss for {MF, HF, B} type
            
            //BUG: P&L formula is not correct, because it adds twice the profit from a change in prices.
            //Implemented now the paper P&L (P&L from the change in prices) and the realised P&L (P&L from the change in positions)
            
//            double currentValue = storedProfitAndLoss.get(0).get(t);
//            storedProfitAndLoss.get(0).set(t, currentValue + diffPrice * storedNetPosMF.get(i).getValue(t - 1) + diffPosMF * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
//            currentValue = storedProfitAndLoss.get(1).get(t);
//            storedProfitAndLoss.get(1).set(t, currentValue + diffPrice * storedNetPosHF.get(i).getValue(t - 1) + diffPosHF * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
//            currentValue = storedProfitAndLoss.get(2).get(t);
//            storedProfitAndLoss.get(2).set(t, currentValue + diffPrice * storedNetPosB.get(i).getValue(t - 1) + diffPosB * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
            
            // P&L due to price change - paper profit and loss for {MF, HF, B} type
            double currentValue = storedPaperProfitAndLoss.get(0).get(t);
            storedPaperProfitAndLoss.get(0).set(t, currentValue + diffPrice * storedNetPosMF.get(i).getValue(t - 1));
            currentValue = storedPaperProfitAndLoss.get(1).get(t);
            storedPaperProfitAndLoss.get(1).set(t, currentValue + diffPrice * storedNetPosHF.get(i).getValue(t - 1));
            currentValue = storedPaperProfitAndLoss.get(2).get(t);
            storedPaperProfitAndLoss.get(2).set(t, currentValue + diffPrice * storedNetPosB.get(i).getValue(t - 1));
            
            // P&L due to position change - realised profit and loss for {MF, HF, B} type
            currentValue = storedRealisedProfitAndLoss.get(0).get(t);
            storedRealisedProfitAndLoss.get(0).set(t, currentValue + diffPosMF * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
            currentValue = storedRealisedProfitAndLoss.get(1).get(t);
            storedRealisedProfitAndLoss.get(1).set(t, currentValue + diffPosHF * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
            currentValue = storedRealisedProfitAndLoss.get(2).get(t);
            storedRealisedProfitAndLoss.get(2).set(t, currentValue + diffPosB * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
            
            // P&L - profit and loss for {FUND, TREND, LS} strategy
            
            //BUG: P&L formula is not correct, because it adds twice the profit from a change in prices.
            //Implemented now the paper P&L (P&L from the change in prices) and the realised P&L (P&L from the change in positions)
            
//            currentValue = storedProfitAndLossStrategy.get(0).get(t);
//            storedProfitAndLossStrategy.get(0).set(t, currentValue + diffPrice * storedNetPosFUND.get(i).getValue(t - 1) + diffPosFUND * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
//            currentValue = storedProfitAndLossStrategy.get(1).get(t);
//            storedProfitAndLossStrategy.get(1).set(t, currentValue + diffPrice * storedNetPosTREND.get(i).getValue(t - 1) + diffPosTREND * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
//            currentValue = storedProfitAndLossStrategy.get(2).get(t);
//            storedProfitAndLossStrategy.get(2).set(t, currentValue + diffPrice * storedNetPosLS.get(i).getValue(t - 1) + diffPosLS * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
            
            // P&L due to price change - profit and loss for {FUND, TREND, LS} strategy
            currentValue = storedPaperProfitAndLossStrategy.get(0).get(t);
            storedPaperProfitAndLossStrategy.get(0).set(t, currentValue + diffPrice * storedNetPosFUND.get(i).getValue(t - 1));
            currentValue = storedPaperProfitAndLossStrategy.get(1).get(t);
            storedPaperProfitAndLossStrategy.get(1).set(t, currentValue + diffPrice * storedNetPosTREND.get(i).getValue(t - 1));
            currentValue = storedPaperProfitAndLossStrategy.get(2).get(t);
            storedPaperProfitAndLossStrategy.get(2).set(t, currentValue + diffPrice * storedNetPosLS.get(i).getValue(t - 1));
            
            // P&L due to position change - profit and loss for {FUND, TREND, LS} strategy
            currentValue = storedRealisedProfitAndLossStrategy.get(0).get(t);
            storedRealisedProfitAndLossStrategy.get(0).set(t, currentValue + diffPosFUND * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
            currentValue = storedRealisedProfitAndLossStrategy.get(1).get(t);
            storedRealisedProfitAndLossStrategy.get(1).set(t, currentValue + diffPosTREND * Math.exp(tsLogPrices.get(i).getValue(t - 1)));
            currentValue = storedRealisedProfitAndLossStrategy.get(2).get(t);
            storedRealisedProfitAndLossStrategy.get(2).set(t, currentValue + diffPosLS * Math.exp(tsLogPrices.get(i).getValue(t - 1)));

        }
    }
    
    /**
     * Calculate the position for the fundamental strategy
     *  
     */
    private DoubleArrayList calcFundamentalPosition(DoubleArrayList currentPos, DoubleArrayList valueOffset, double entryThresh, double exitThresh, double capFac, int t) {
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
        
    /**
     * Create a uniform distribution extracting the parameters 
     *  
     */
    private Uniform assignUniform(LPMHBEqnParams params, Sequence sequence) {
        return assignUniform(params, sequence, 0);
    }
    
    private Normal assignNormal(LPMHBEqnParams params, Sequence sequence) {
        return assignNormal(params, sequence, 0);
    }
    
    private Uniform assignUniform(LPMHBEqnParams params, Sequence sequence, int index) {
        Uniform dist = null;
        
        if (sequence.type() == Integer.class) {
            ArrayList<IntArrayList> ial = params.getIntegerIntervalSequence(sequence);
            Assertion.assertStrict(index < ial.size(), Assertion.Level.ERR, "Sequence '" + sequence.label() + 
                    "': last index is '" + (sequence.length(params) - 1) + "', but trying to access element '" + index + "'");            
            dist = RandomHelper.createUniform(ial.get(index).get(0), ial.get(index).get(1));
        } else {
            ArrayList<DoubleArrayList> dal = params.getDoubleIntervalSequence(sequence);
            Assertion.assertStrict(index < dal.size(), Assertion.Level.ERR, "Sequence '" + sequence.label() + 
                    "': last index is '" + (sequence.length(params) - 1) + "', but trying to access element '" + index + "'");            
            dist = RandomHelper.createUniform(dal.get(index).get(0), dal.get(index).get(1));
        }
        
        return dist;
    }
    
    private Normal assignNormal(LPMHBEqnParams params, Sequence sequence, int index) {
        ArrayList<DoubleArrayList> dal = params.getDoubleIntervalSequence(sequence);

        Assertion.assertStrict(index < dal.size(), Assertion.Level.ERR, "Sequence '" + sequence.label() + 
                "': length is '" + sequence.length(params) + "', but trying to access element '" + index + "'");
        
        Normal dist = RandomHelper.createNormal(dal.get(index).get(0), dal.get(index).get(1));
        return dist;
    }
}
