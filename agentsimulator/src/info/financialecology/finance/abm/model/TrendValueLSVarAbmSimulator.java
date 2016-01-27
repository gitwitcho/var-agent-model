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
package info.financialecology.finance.abm.model;

import java.util.HashMap;

import info.financialecology.finance.abm.model.agent.ShareMarketMaker;
import info.financialecology.finance.abm.model.agent.Trader;
import info.financialecology.finance.abm.model.agent.Trader.UseVar;
import info.financialecology.finance.abm.model.strategy.TradingStrategy;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.MultiplierTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.OrderOrPositionStrategyTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.PositionUpdateTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.VariabilityCapFactorTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.ShortSellingTrend;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.PositionUpdateValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.OrderOrPositionStrategyValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.VariabilityCapFactorValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.ShortSellingValue;
import info.financialecology.finance.abm.model.strategy.LSMABCStrategy;
import info.financialecology.finance.abm.model.strategy.LSMABCStrategy.PositionUpdateLS;
import info.financialecology.finance.abm.model.strategy.LSMABCStrategy.MultiplierLS;
import info.financialecology.finance.abm.model.util.TradingPortfolio;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.WorldClock;
import info.financialecology.finance.utilities.abm.AbstractSimulator;
import info.financialecology.finance.utilities.datagen.DataGenerator;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.statistics.StatsTimeSeries;

import org.slf4j.LoggerFactory;
import ch.qos.logback.classic.Logger;

import repast.simphony.engine.schedule.DefaultScheduleFactory;
import repast.simphony.engine.schedule.ISchedule;


/**
 * TODO I am assuming below that we are having different warmup periods for different trading strategies, which may not be optimal 
 * <p>
 * SET-UP: Before the first tick {@code t = 0}</br>
 * -------------------------------------</br>
 * The SET-UP needs to be done in the simulation code, e.g. {@code TrendValueSingleAssetAbmSimulation}.
 * {@code t} is equal to the currentTick as returned by the WorldClock.
 * <pre>
 * 1. Read model parameters from an XML file
 * 2. Set up the simulator
 *    2.1 Reset the WorldClock to t=0
 *    2.2 Create a market maker
 *    2.3 Create a market
 *    2.4 Market maker enters the market
 *    2.5 Schedule the market maker's clearMarket() method with FIRST_PRIORITY, starting at t=0
 * 3. Set the shares that can be traded in the market and assign to market maker
 * 4. Set the t=0 price for the shares
 * 5. Set the t=0 fundamental value of the shares
 * 6. Set the liquidity of the shares
 * 7. Create the trend followers
 *    7.1 Trend followers enter the market
 *    7.2 Schedule the trend followers' actions() {=placeOrders()} method, to execute them in the order they are added to the scheduler, starting at t=0
 * 8. Create the value investors
 *    8.1 Value investors enter the market
 *    8.2 Schedule the value investors' actions() {=placeOrders()} method, to execute them in the order they are added to the scheduler, starting at t=0
 * 9. Setting up the data generators
 * 10. Set the exogenous price and market-wide fundamental value processes
 * 11. Set up the trend strategies and assign them to the traders
 * 12. Set number of ticks of the simulation
 * </pre>
 * RUN: {@code 0 <= t <= warmup_period}</br>
 * ---------------------------------------</br>
 * This shows the flow of execution in the {@code TrendValueAbmSimulator} for {@code t <= warmup_period} 
 * [TBD: the maximum warmup_period]. {@code t} is equal to the currentTick as returned by the WorldClock.
 * <pre>
 * 13. Market maker clears the market for all shares registered with her [via clearMarket(), scheduled as FIRST_PRIORITY]
 *    13.1 At t = 0, the share prices are equal to the t=0 prices fixed during the SET-UP. No orders have been placed, so the calculation is skipped
 *    13.2 At 0 < t <= warmup_period, value investors will have placed their orders but trend followers won't
 *       13.2.1 Determine total orders placed in t-1 by all traders for all shares
 *       13.2.2 Compute a new price at time t for each share, based on total orders place at t-1 and the exogenous price   
 * 14. Trend followers place their orders, in the sequence in which they registered with the scheduler [via scheduled actions() -> placeOrders()]
 *    14.1 Execute trading strategies registered with each trend follower [trade()]
 *       14.1.1 Positions and orders are set to '0' at each tick that lies within the warm-up period. No further calculations are done
 *    14.2 Trend traders place no orders with the market maker
 * 15. Value investors place their orders, in the sequence in which they registered with the scheduler [via scheduled actions() -> placeOrders()]
 *    15.1 Execute trading strategies registered with each value investor [trade()]
 *       15.1.1 At t = 0, positions and orders are set to '0'. No further calculations are done [TBD: use the maximum warmup_period?]
 *       15.1.2 At t > 0, apply a state machine type logic to decide whether to compute the new positions for time t
 *       15.1.3 At t > 0, compute the order for time t and add it to the value investor's order book
 *    15.2 Value investors place the resulting orders (for all secIds) with the market maker [placeOrder()]
 * </pre>
 * RUN: t > warmup_period</br>
 * ---------------------------</br>
 * This shows the flow of execution in the {@code TrendValueAbmSimulator} for t > warmup_period [TBD: the maximum warmup_period]
 * <pre>
 * 16. Market maker clears the market for all shares registered with her [via clearMarket(), scheduled as FIRST_PRIORITY]
 *    13.1 At t > warmup_period, both value investors and trend followers will have placed their orders
 *    13.2 Determine total orders placed in t-1 by all traders for all shares
 *    13.3 Compute a new price at time t for each share, based on total orders place at t-1 and the exogenous price   
 * 14. Trend followers place their orders, in the sequence in which they registered with the scheduler [via scheduled actions() -> placeOrders()]
 *    14.1 Execute trading strategies registered with each trend follower [trade()]
 *       14.1.1 #####
 *    14.2 Trend traders place resulting order (for secId) with market maker [placeOrder()]
 * 15. Value investors place their orders, in the sequence in which they registered with the scheduler [via scheduled actions() -> placeOrders()]
 *    15.1 Execute trading strategies registered with each value investor [trade()]
 *       15.1.2 Apply a state machine type logic to decide whether to compute the new positions for time t
 *       15.1.3 Compute the order for time t and add it to the value investor's order book
 *    15.2 Value investors place the resulting orders (for all secIds) with the market maker [placeOrder()]
 *    
 *    Summary of computations on the timeline
 * 
 * ============ t=0 ------------ t=1 ------------ t=2 ------------
 * 
 * <p>
 * 
 *  
 * ------------ t-1 ============ t ------------ t+1 ------------
 * 
 * @author Gilbert Peffer, Barbara Llacay
 *
 */
public class TrendValueLSVarAbmSimulator extends AbstractSimulator {
    
    private ISchedule scheduler;                    // main scheduler to run actions (=methods) at particular points in time
    private ShareMarket market;                     // stock market where trend followers trade with value investors 
    
    private int nextTrendIndex = 0;                 // the next numeric index for the trend follower labels
    private int nextValueIndex = 0;                 // the next numeric index for the value investor labels
    private int nextLSIndex = 0;                    // the next numeric index for the LS investor labels
    private String prefixTrendFollower = "Trend";   // label prefix for formatting output
    private String prefixValueInvestor = "Value";   // label prefix for formatting output
    private String prefixLSInvestor = "LS";         // label prefix for formatting output
    
    private static final Logger logger = (Logger)LoggerFactory.getLogger(TrendValueLSVarAbmSimulator.class.getSimpleName());
    
    
    /**
     * Constructor. Creates the scheduler ({@link ISchedule}) and the {@link ShareMarket}.
     */
    public TrendValueLSVarAbmSimulator() {
        
        logger.trace("Calling: TrendValueLSAbmSimulator()");
        
        resetWorldClock();
        
        ShareMarketMaker marketMaker = new ShareMarketMaker();
        market = new ShareMarket("Share market", marketMaker);
        
        DefaultScheduleFactory factory = new DefaultScheduleFactory();  // TODO move this to to a new class AbstractABMSimulator
        scheduler = factory.createSchedule();
        
        scheduler.schedule(marketMaker);
    }
    
    
    /**
     * Constructor. Creates the scheduler ({@link ISchedule}) and the {@link ShareMarket}.
     * 
     * @param pTrend the prefix for trend follower labels; used for formatting output
     * @param pValue the prefix for value investor labels; used for formatting output
     * @param pLS the prefix for LS investor labels; used for formatting output
     */
    public TrendValueLSVarAbmSimulator(String pTrend, String pValue, String pLS) {
        
        this();

        logger.trace("Calling: TrendValueAbmSimulator(String, String, String)");

        prefixTrendFollower = pTrend;
        prefixValueInvestor = pValue;
        prefixLSInvestor = pLS;
    }
    
    
    /**
     * Get the time series of prices for security {@code secId} from the {@link ShareMarket}
     * 
     * @param secId the unique security identifier
     * @return the time series of prices
     */
    public DoubleTimeSeries getPrices(String secId) {
        return market.getPrices(secId);
    }
    
    /**
     * Get the time series of log-returns for security {@code secId} from the {@link ShareMarket}
     * 
     * @param secId the unique security identifier
     * @return the time series of log-returns
     */
    public DoubleTimeSeries getLogReturns(String secId) {
        return market.getLogReturns(secId);
    }
    
    
    /**
     * Get the time series of market-wide fundamental values for security {@code secId} from the 
     * {@link ShareMarket}. Market-wide fundamental values differ from agents' fundamental values
     * in that the latter have an added agent-specific factor to reflect idiosyncratic beliefs about
     * share value.   
     * 
     * @param secId the unique security identifier
     * @return the time series of prices
     */
    public DoubleTimeSeries getFundValues(String secId) {
        return market.getFundValues(secId);
    }
            
    
    /**
     * Add shares (by security identifier) to the {@link ShareMarket}. Also adds them to the list 
     * of shares the market maker quotes prices for. 
     * 
     * @param secIds set of security identifiers
     */
    public void addShares(String... secIds){
        
        market.addShares(secIds);
        market.getMarketMaker().makeMarketInAllSecurities();    // update the shares that the market maker quotes prices for
    }
    
    
    /**
     * Add spreads (by securities' identifier) to the {@link ShareMarket}. Also adds them to the list 
     * of spreads the market maker quotes prices for. 
     * 
     * @param spreadIds set of security identifiers
     */
    public void addSpreads(String... spreadIds){
        
        market.addSpreads(spreadIds); 
    }
        
    
    /**
     * Create trend followers
     *  
     * @param numTrend the number of trend followers to create
     */
    public void createTrendFollowers(int numTrend) {
        Trader trader;
        
        for (int i = 0; i < numTrend; i++) {
            trader = new Trader(prefixTrendFollower + "_" + nextTrendIndex++);
            market.addTrader(trader);
            trader.setInitCovariances(0.0);
            scheduler.schedule(trader); // schedules the actions() method of the trader
        }
    }
    
    /**
     * Create value investors
     *  
     * @param numValue the number of value investors to create
     */
    public void createValueInvestors(int numValue) {
        Trader trader;
        
        for (int i = 0; i < numValue; i++) {
            trader = new Trader(prefixValueInvestor + "_" + nextValueIndex++);
            market.addTrader(trader);
            trader.setInitCovariances(0.0);
            scheduler.schedule(trader); // schedules the actions() method of the trader
        }
    }
    
    /**
     * Create LS investors
     *  
     * @param numLS the number of LS investors to create
     */
    public void createLSInvestors(int numLS) {
        Trader trader;
        
        for (int i = 0; i < numLS; i++) {
            trader = new Trader(prefixLSInvestor + "_" + nextLSIndex++);
            market.addTrader(trader);
            trader.setInitCovariances(0.0);
            scheduler.schedule(trader); // schedules the actions() method of the trader
        }
    }
    
    
    /**
     * Set up all trend followers with the same trend strategy. Call this method as many times as there 
     * are trend strategies per trend follower.
     *
     * @param secId the security identifier
     * @param maShortTicks the range over which the short (=fast) moving average is computed (for entry indicator)
     * @param maLongTicks the range over which the long (=slow) moving average is computed (for entry indicator)
     * @param bcTicks the size of the window over which maximum and minimum values are computed (for exit indicator)
     * @param capFactor the capital multiplier for the trading strategy
     * @param volWindow the size of the window over which the volatility is computed
     * @param multiplier a multiplier for entry positions, depending on the approach chosen (see {@link TrendMABCStrategy.Multiplier})
     */
    public void addTrendStrategyForAllTrendFollowers(String secId,
                                                     int maShortTicks, 
                                                     int maLongTicks, 
                                                     int bcTicks, 
                                                     double capFactor, 
                                                     int volWindow,
                                                     MultiplierTrend multiplier,
                                                     PositionUpdateTrend positionUpdate,
                                                     OrderOrPositionStrategyTrend orderOrPositionStrategy,
                                                     VariabilityCapFactorTrend variabilityCapFactor,
                                                     ShortSellingTrend shortSellingTrend) {
        logger.trace("Calling: addTrendStrategyForAllTraders(...)");

        // Get all trend followers
        HashMap<String, Trader> trendFollowers = getTrendFollowers();
        
        Assertion.assertStrict(market.isShareTraded(secId), Level.ERR, "There is no share with ID '"
                + secId + "' traded in the market '" + market.getId() + "'");
        Assertion.assertStrict((!trendFollowers.isEmpty()), Level.ERR, "Cannot assign trend strategy" +
        		" because there are no trend followers in the market");
        
        for (Trader trader : trendFollowers.values()) { // create a trend strategy for each trend follower 
            
            HashMap<String, TradingStrategy> strategies = trader.getStrategies();
            boolean hasStrategy = false;
            
            for (TradingStrategy strategy : strategies.values()) {   // has a strategy with secId already been assigned to the trader?
                if (strategy.getUniqueId().compareTo(secId) == 0) {
                    hasStrategy = true;
                    // TODO Message that a strategy with that identifier already exists and that the intent to add a new one is ignored. IS THAT THE CORRECT BEHAVIOUR?
                }
            }
            
            if (!hasStrategy) { // if the trader does not have a strategy for share secId, then assign it
            	TrendMABCStrategy strategy = new TrendMABCStrategy(secId, maShortTicks, maLongTicks, bcTicks, capFactor, market.getPrices(secId), 
            			volWindow, multiplier, positionUpdate, orderOrPositionStrategy, variabilityCapFactor, shortSellingTrend);
                trader.addStrategy(strategy);                
            }
        }
    }
    
    /**
     * Set up the trend follower '{@code traderId}' with a trend strategy. Call this method as 
     * many times as there are trend strategies for this trend follower.
     *
     * @param secId the the security identifier
     * @param traderId the identifier for the trend follower
     * @param maShortTicks the range over which the short (=fast) moving average is computed (for entry indicator)
     * @param maLongTicks the range over which the long (=slow) moving average is computed (for entry indicator)
     * @param bcTicks the size of the window over which maximum and minimum values are computed (for exit indicator)
     * @param capFactor the capital multiplier for the trading strategy
     * @param volWindow the size of the window over which the volatility is computed
     * @param multiplier a multiplier for entry positions, depending on the approach chosen (see {@link TrendMABCStrategy.MultiplierTrend})
     */
    public void addTrendStrategyForOneTrendFollower(String secId,
    										        String traderId,
    										        int maShortTicks, 
    										        int maLongTicks, 
    										        int bcTicks, 
    										        double capFactor, 
    										        int volWindow,
    										        MultiplierTrend multiplier,
    										        PositionUpdateTrend positionUpdate,
    										        OrderOrPositionStrategyTrend orderOrPositionStrategy,
    										        VariabilityCapFactorTrend variabilityCapFactor,
    										        ShortSellingTrend shortSellingTrend) {
        logger.trace("Calling: addTrendStrategyForOneTrendFollower(...) - For trader with ID = " + traderId);
        
        Trader trader = market.getTrader(traderId);

        Assertion.assertStrict(market.isShareTraded(secId), Level.ERR, "There is no share with ID '"
                + secId + "' traded in the market '" + market.getId() + "'");
        
        // TODO The validation code that we have in 'addValueStrategyForAllValueInvestors' is missing here 
                
        TrendMABCStrategy newStrategy = new TrendMABCStrategy(secId, maShortTicks, maLongTicks, bcTicks, capFactor, market.getPrices(secId), 
        		volWindow, multiplier, positionUpdate, orderOrPositionStrategy, variabilityCapFactor, shortSellingTrend);
        
        trader.addStrategy(newStrategy);
    }
    
    
    /**
     * Set up all value investors with the same value strategy. Call this method as many times as there 
     * are trend strategies per trend follower.
     *
     * @param secId the security identifier
     * @param entryThreshold 
     * @param exitThreshold 
     * @param valueOffset captures the difference between the value perceived by the value investor 
     * and the market-wide fundamental value (not price!) of the share. This is not too meaningful in
     * the case where the trading strategies of all value investors are identical (as per this method) 
     * @param bcTicks the size of the window over which maximum and minimum values are computed (for exit indicator)
     * @param capFactor the capital multiplier for the trading strategy
     */
    public void addValueStrategyForAllValueInvestors(String secId,
                                                     double entryThreshold, 
                                                     double exitThreshold, 
                                                     double valueOffset, 
                                                     int bcTicks,
                                                     double capFactor,
                                                     PositionUpdateValue positionUpdate,
                                                     OrderOrPositionStrategyValue orderOrPositionStrategy,
                                                     VariabilityCapFactorValue variabilityCapFactor,
                                                     ShortSellingValue shortSellingValue) {
        logger.trace("Calling: addValueStrategyForAllValueInvestors(...)");

//        HashMap<String, Trader> trendFollowers = getTrendFollowers();
        // Get all value investors
        HashMap<String, Trader> valueInvestors = getValueInvestors();
        
        Assertion.assertStrict(market.isShareTraded(secId), Level.ERR, "There is no share with ID '" + 
                secId + "' traded in the market");
        Assertion.assertStrict((!valueInvestors.isEmpty()), Level.ERR, "Cannot assign value strategy " +
        		"because there are no value investors in the market '" + market.getId() + "'");
        
        for (Trader trader : valueInvestors.values()) { // create a value strategy for each value investor
            
            HashMap<String, TradingStrategy> strategies = trader.getStrategies();
            boolean hasStrategy = false;
            
            for (TradingStrategy strategy : strategies.values()) {   // has a strategy with secId already been assigned to the trader?
                if (strategy.getUniqueId().compareTo(secId) == 0) {
                    hasStrategy = true;
                    // TODO Message that a strategy with that identifier already exists and that the intent to add a new one is ignored. IS THAT THE CORRECT BEHAVIOUR?
                }
            }
            
            if (!hasStrategy) { // if the trader does not have a strategy for share secId, then assign it
                ValueMABCStrategy strategy = new ValueMABCStrategy(secId, entryThreshold, exitThreshold, valueOffset, bcTicks, capFactor, 
                		market.getPrices(secId), market.getFundValues(secId), 
                		positionUpdate, orderOrPositionStrategy, variabilityCapFactor, shortSellingValue);
                trader.addStrategy(strategy);                
            }
        }
    }
    
    
    /**
     * Set up the value investor '{@code traderId}' with a value strategy. Call this method as 
     * many times as there are trend strategies for this trend follower.
     *
     * @param secId the security identifier
     * @param entryThreshold 
     * @param exitThreshold 
     * @param valueOffset captures the difference between the value perceived by the value investor 
     * and the market-wide fundamental value (not price!) of the share. This is not too meaningful in
     * the case where the trading strategies of all value investors are identical (as per this method) 
     * @param bcTicks the size of the window over which maximum and minimum values are computed (for exit indicator)
     * @param capFactor the capital multiplier for the trading strategy
     */
    public void addValueStrategyForOneValueInvestor(String secId,
                                                    String traderId,
                                                    double entryThreshold, 
                                                    double exitThreshold, 
                                                    double valueOffset, 
                                                    int bcTicks,
                                                    double capFactor,
                                                    PositionUpdateValue positionUpdate,
                                                    OrderOrPositionStrategyValue orderOrPositionStrategy,
                                                    VariabilityCapFactorValue variabilityCapFactor,
                                                    ShortSellingValue shortSellingValue) {
        logger.trace("Calling: addValueStrategyForOneValueInvestor(...) - For trader with ID=" + traderId);
        
        Trader trader = market.getTrader(traderId);

        Assertion.assertStrict(market.isShareTraded(secId), Level.ERR, "There is no share with ID '" + secId + "' traded in the market");
        
        // TODO The validation code that we have in 'addValueStrategyForAllValueInvestors' is missing here 

        ValueMABCStrategy newStrategy = new ValueMABCStrategy(secId, entryThreshold, exitThreshold, valueOffset, bcTicks, capFactor, 
        		market.getPrices(secId), market.getFundValues(secId),  
        		positionUpdate, orderOrPositionStrategy, variabilityCapFactor, shortSellingValue);        
        trader.addStrategy(newStrategy);
    }
    
    
    
    /**
     * Set up the LS investor '{@code traderId}' with an LS strategy. Call this method as 
     * many times as there are LS strategies for this LS trader.
     *
     * @param secId_1 the identifier of the first security that constitutes the spread
     * @param secId_2 the identifier of the second security that constitutes the spread
     * @param traderId the identifier of the agent
     * @param histWindow window used to calculate the historical mean and standard deviation of the spread
     * @param volWindow the size of the window over which the volatility is computed
     * @param entryDivergenceSigmas number of sigmas of spread divergence used in the LS entry threshold 
     * @param exitConvergenceSigmas number of sigmas of spread convergence used in the LS exit threshold
     * @param exitStopLossSigmas number of sigmas of spread divergence used in the LS stop loss threshold
     * @param capFactor the capital multiplier for the trading strategy
     * @param multiplier a multiplier for entry positions, depending on the approach chosen (see {@link LSMABCStrategy.MultiplierLS})
     */
    public void addLSStrategyForOneLSInvestor(String secId_1,
    											String secId_2,
    											String traderId,
    											int maSpreadShortTicks,
    											int maSpreadLongTicks,
    											int volWindow,
    											double entryDivergenceSigmas,
    											double exitConvergenceSigmas,
    											double exitStopLossSigmas,
    											double capFactor,
    											MultiplierLS multiplier,
    											PositionUpdateLS positionUpdate) {
    	
        logger.trace("Calling: addLSStrategyForOneLSInvestor(...) - For trader with ID=" + traderId);
        
        Trader trader = market.getTrader(traderId);

        Assertion.assertStrict(market.isShareTraded(secId_1), Level.ERR, "There is no share with ID '" + secId_1 + "' traded in the market");
        Assertion.assertStrict(market.isShareTraded(secId_2), Level.ERR, "There is no share with ID '" + secId_2 + "' traded in the market");
        
        // TODO The validation code that we have in 'addValueStrategyForAllValueInvestors' is missing here 
        
        LSMABCStrategy newStrategy = new LSMABCStrategy(secId_1, market.getPrices(secId_1), secId_2, market.getPrices(secId_2),
        		market.getSpreads(secId_1, secId_2), maSpreadShortTicks, maSpreadLongTicks, volWindow, entryDivergenceSigmas, exitConvergenceSigmas, 
        		exitStopLossSigmas, capFactor, multiplier, positionUpdate);        
        trader.addStrategy(newStrategy);                
    }
    
    
    
    /**
     * Get all trend followers operating in the market
     * 
     * @return a {@code HashMap} with all trend followers
     */
    public HashMap<String, Trader> getTrendFollowers() {
        HashMap<String, Trader> traders = market.getTraders();
        HashMap<String, Trader> trendFollowers = new HashMap<String, Trader>();
        
        for (String key : traders.keySet()) {
            if (key.startsWith(prefixTrendFollower))
                trendFollowers.put(key, traders.get(key));
        }
        
        return trendFollowers;
    }
    
    
    /**
     * Get all value investors operating in the market
     * 
     * @return a {@code HashMap} with all value investors
     */
    public HashMap<String, Trader> getValueInvestors() {
        HashMap<String, Trader> traders = market.getTraders();
        HashMap<String, Trader> valueInvestors = new HashMap<String, Trader>();
        
        for (String key : traders.keySet()) {
            if (key.startsWith(prefixValueInvestor))
                valueInvestors.put(key, traders.get(key));
        }
        
        return valueInvestors;
    }
    
    
    /**
     * Get all LS investors operating in the market
     * 
     * @return a {@code HashMap} with all LS investors
     */
    public HashMap<String, Trader> getLSInvestors() {
        HashMap<String, Trader> traders = market.getTraders();
        HashMap<String, Trader> LSInvestors = new HashMap<String, Trader>();
        
        for (String key : traders.keySet()) {
            if (key.startsWith(prefixLSInvestor))
                LSInvestors.put(key, traders.get(key));
        }
        
        return LSInvestors;
    }
    
    
    /**
     * Get the market maker
     * 
     * @return the market maker
     */
    public ShareMarketMaker getMarketMaker() {
        return market.getMarketMaker();
    }
    
    
    /**
     * Get the market
     * 
     * @return the market
     */
    public ShareMarket getMarket() {
        return market;
    }
    
    
    /**
     * Set the exogenous price process for a given asset
     * 
     * @param assetId the identifier of the asset, e.g. "IBM"
     * @param exoPriceGen a {@link DataGenerator} for the exogenous price process. The full price 
     * process consists of two parts
     * <ul>
     * <li>an endogenous part that calculates prices based on orders
     * or positions
     * <li> an exogenous part that is provided by the user in form of a {@link DataGenerator} process
     * </ul>   
     */
    public void setExogeneousPriceProcess(String assetId, DataGenerator exoPriceGen) {
        market.getMarketMaker().setExogenousPriceGenerator(assetId, exoPriceGen);
    }
    
    
    /**
     * Set the market-wide fundamental value process for a given asset. The value process consists of two parts:
     * <ul>
     * <li> the market-wide fundamental value, which reflects the value perceived by the average
     * market participant
     * <li> an idiosyncractic offset - added to the market-wide fundamental value - that reflects 
     * the belief of a given trader about the fundamental value of the share.
     * </ul>
     */
    public void setFundamentalValueProcess(String assetId, DataGenerator fundValueGen) {
        market.setFundValueGenerator(assetId, fundValueGen);
    }
    
    
    /**
     * Get the scheduler for this simulator
     * 
     * @return scheduler of this simulator
     */
    protected ISchedule getScheduler() {
        return scheduler;
    }
    
    
    /**
     * Get the current tick according to the {@link WorldClock}
     * 
     * @return current tick
     */
    public long currentTick() {
        long currentTick = super.currentTick();
        long scheduleTickCount = (long) scheduler.getTickCount();
        
        // TODO This test is a bit more difficult. The schedule tick count is -1 the first time the current tick is called below. 
        // TODO It seems the tick count is set to 0 before the first scheduled event executes. So any schedule-executed code should test for this, but other code shouldn't 
        Assertion.assertStrict(currentTick == scheduleTickCount, Level.ERR, "Scheduler has gaps because tick count is out of sync");
        
        return currentTick;
    }
    
    
    /**
     * Run the simulation. Internally, this executes the methods registered with the scheduler.
     */
    public void run() {
        logger.trace("Calling: run()");
        
        Assertion.assertStrict((!getTrendFollowers().isEmpty() || !getValueInvestors().isEmpty() || !getLSInvestors().isEmpty()), 
        		Level.ERR, "There are no trend followers, value investors and LS investors in the market '" + market.getId() + "'");
        
        // TODO test for first tick and if true, use super.currentTick() to avoid testing (see comments in currentTick()). Otherwise use the currentTick() method of this class.
               
        while (super.currentTick() < nTicks) {  // call currentTick of super to skip test that ensures the current tick and the scheduler tick count are in sync
            scheduler.execute();
            incrementTick();
        }
    }

    
    /**
     *  Calculate the total volume time series (sum of absolute orders) of trades made by fundamental 
     *  investors
     *  
     *  @param secId the unique security identifier
     *  @return the time series of total volume
     */
	public DoubleTimeSeries getFundVolume(String secId) {     // TODO replace this and the next method with a single getVolume() method, since trader and strategy objects used inside are generic 
		
		HashMap<String, Trader> valueTraders = getValueInvestors();
		DoubleTimeSeriesList dtlAbsOrders = new DoubleTimeSeriesList();		
		DoubleTimeSeries tsFundVolume = new DoubleTimeSeries();
		
		// No value investors? Set entries in tsFundVolume to zero and return
		if (valueTraders.size() == 0) {
		    tsFundVolume.fillWithConstants((int) nTicks, 0.0);
		    return tsFundVolume;
		}
		
		// Create a time series list of absolute orders placed by all fundamental investors
        for (String key : valueTraders.keySet()) {
        	DoubleTimeSeries absOrders = new DoubleTimeSeries();
        	Trader fund = valueTraders.get(key);
        	DoubleTimeSeries fundPos = fund.getPortfolio().getTsPosition(secId);
        	
        	absOrders.add(0,  Math.abs(fundPos.get(0)));  // Order at t=0
        	
        	for (int i = 1; i < nTicks; i++) {
        		absOrders.add(i,  Math.abs(fundPos.get(i) - fundPos.get(i-1)));
        	}
        	
        	dtlAbsOrders.add(absOrders);
        }
         
        // Calculate the volume at each tick by summing the absolute orders over all fundamental traders
        for (int i = 0; i < nTicks; i++) { 
        	double volume = 0.0;
        	
        	for (int j = 0; j < dtlAbsOrders.size(); j++) {
        		volume += dtlAbsOrders.get(j).getValue(i);
        	}
        	
        	tsFundVolume.add(i, volume);
        }
       
        return tsFundVolume;
    }
     
	
    /**
     *  Calculate the total volume time series (sum of absolute orders) of trades made by trend 
     *  followers
     *  
     *  @param secId the unique security identifier
     *  @return the time series of total volume
     */
	public DoubleTimeSeries getTrendVolume(String secId) {
		
		HashMap<String, Trader> trendTraders = getTrendFollowers();
		DoubleTimeSeriesList dtlAbsOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsTrendVolume = new DoubleTimeSeries();
		
		// No trend followers? Set entries in tsTrendVolume to zero and return
		if (trendTraders.size() == 0) {
			tsTrendVolume.fillWithConstants((int) nTicks, 0.0);
			return tsTrendVolume;
		}
		
		// Create a time series list of absolute orders placed by all trend followers
        for (String key : trendTraders.keySet()) {
        	DoubleTimeSeries absOrders = new DoubleTimeSeries();   
        	Trader trend = trendTraders.get(key);
        	DoubleTimeSeries trendPos = trend.getPortfolio().getTsPosition(secId);
        	
        	absOrders.add(0,  Math.abs(trendPos.get(0)));  // Order at t=0
        	
        	for (int i = 1; i < nTicks; i++) {
        		absOrders.add(i,  Math.abs(trendPos.get(i) - trendPos.get(i-1)));
        	}
        	
        	dtlAbsOrders.add(absOrders);
        }
        
        // Calculate the volume at each tick by summing the absolute orders over all trend followers
        for (int i = 0; i < nTicks; i++) {
        	double volume = 0.0;
        	
        	for (int j = 0; j < dtlAbsOrders.size(); j++) {
        		volume += dtlAbsOrders.get(j).getValue(i);
        	}
        	
        	tsTrendVolume.add(i, volume);
        }
       
        return tsTrendVolume;
    }	

	
    /**
     *  Calculate the total volume time series (sum of absolute orders) of trades made by  
     *  LS investors
     *  
     *  @param secId the unique security identifier
     *  @return the time series of total volume
     */
	public DoubleTimeSeries getLSVolume(String secId) {
		
		HashMap<String, Trader> LSTraders = getLSInvestors();
		DoubleTimeSeriesList dtlAbsOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsLSVolume = new DoubleTimeSeries();
		
		// No LS investors? Set entries in tsLSVolume to zero and return
		if (LSTraders.size() == 0) {
			tsLSVolume.fillWithConstants((int) nTicks, 0.0);
			return tsLSVolume;
		}
		
		// Create a time series list of absolute orders placed by all LS investors
		for (String key : LSTraders.keySet()) {
			
        	DoubleTimeSeries absOrders = new DoubleTimeSeries();   
        	Trader ls = LSTraders.get(key);
        	DoubleTimeSeries lsPos = ls.getPortfolio().getTsPosition(secId);
        	
        	absOrders.add(0,  Math.abs(lsPos.get(0)));  // Order at t=0
        	
        	for (int i = 1; i < nTicks; i++) {
        		absOrders.add(i,  Math.abs(lsPos.get(i) - lsPos.get(i-1)));
        	}
        	
        	dtlAbsOrders.add(absOrders);
        }

        // Calculate the volume at each tick by summing the absolute orders over all LS traders
        for (int i = 0; i < nTicks; i++) {
        	
        	double volume = 0.0;
        	
        	for (int j = 0; j < dtlAbsOrders.size(); j++) {
        		volume += dtlAbsOrders.get(j).getValue(i);
        	}
        	
        	tsLSVolume.add(i, volume);
        }
       
        return tsLSVolume;
    }	

	
    /**
     *  Calculate the total volume time series (sum of absolute orders) of trades made by  
     *  fundamental investors, trend followers and LS investors
     *  
     *  @param secId the unique security identifier
     *  @return the time series of total volume
     */
	public DoubleTimeSeries getTotalVolume(String secId) {
		
		DoubleTimeSeries tsFundVolume = getFundVolume(secId);
		DoubleTimeSeries tsTrendVolume = getTrendVolume(secId);
		DoubleTimeSeries tsLSVolume = getLSVolume(secId);
		DoubleTimeSeries tsTotalVolume = new DoubleTimeSeries();
     
        int nTicks = tsFundVolume.size();
        
        for (int i = 0; i < nTicks; i++) {
        	double volume = tsFundVolume.get(i) + tsTrendVolume.get(i) + tsLSVolume.get(i);        	
        	tsTotalVolume.add(i, volume);
        }
       
        return tsTotalVolume;
    }
	
    /**
     *  Calculate the aggregated order time series (sum of orders with their sign) of 
     *  trades made by fundamental investors
     *  
     *  @param secId the unique security identifier
     *  @return the time series of aggregated orders
     */
	public DoubleTimeSeries getFundTotalOrders(String secId) {     // TODO replace this and the next method with a single getTotalOrders() method, since trader and strategy objects used inside are generic 
		
		HashMap<String, Trader> valueTraders = getValueInvestors();
		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsFundTotalOrders = new DoubleTimeSeries();
		
		// No value investors? Set entries in tsFundTotalOrders to zero and return
		if (valueTraders.size() == 0) {
		    tsFundTotalOrders.fillWithConstants((int) nTicks, 0.0);
		    return tsFundTotalOrders;
		}
		
		// Create a time series list of orders placed by all fundamental investors
        for (String key : valueTraders.keySet()) {
        	DoubleTimeSeries orders = new DoubleTimeSeries();
        	Trader fund = valueTraders.get(key);
        	DoubleTimeSeries fundPos = fund.getPortfolio().getTsPosition(secId);
        	
        	orders.add(0, fundPos.get(0));  // Order at t=0
        	
        	for (int i = 1; i < nTicks; i++) {
        		orders.add(i,  fundPos.get(i) - fundPos.get(i-1));
        	}
        	
        	dtlOrders.add(orders);
        }
        
        // Calculate the aggregate order at each tick by summing the orders sent by all fundamental traders
        for (int i = 0; i < nTicks; i++) { 
        	double totalOrder = 0.0;
        	
        	for (int j = 0; j < dtlOrders.size(); j++) {
        		totalOrder += dtlOrders.get(j).getValue(i);
        	}
        	
        	tsFundTotalOrders.add(i, totalOrder);
        }
       
        return tsFundTotalOrders;
	}
	
    /**
     *  Calculate the aggregated order time series (sum of orders with their sign) of 
     *  trades made by trend followers
     *  
     *  @param secId the unique security identifier
     *  @return the time series of aggregated orders
     */
	public DoubleTimeSeries getTrendTotalOrders(String secId) { 
		
		HashMap<String, Trader> trendTraders = getTrendFollowers();
		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsTrendTotalOrders = new DoubleTimeSeries();
		
		// No trend followers? Set entries in tsTrendTotalOrders to zero and return
		if (trendTraders.size() == 0) {
		    tsTrendTotalOrders.fillWithConstants((int) nTicks, 0.0);
		    return tsTrendTotalOrders;
		}
        
		// Create a time series list of orders placed by all trend followers
        for (String key : trendTraders.keySet()) {
        	DoubleTimeSeries orders = new DoubleTimeSeries();
        	Trader trend = trendTraders.get(key);
        	DoubleTimeSeries trendPos = trend.getPortfolio().getTsPosition(secId);
        	
        	orders.add(0, trendPos.get(0));  // Order at t=0
        	
        	for (int i = 1; i < nTicks; i++) {
        		orders.add(i,  trendPos.get(i) - trendPos.get(i-1));
        	}
        	
        	dtlOrders.add(orders);
        }
        
        // Calculate the aggregate order at each tick by summing over all trend followers
        for (int i = 0; i < nTicks; i++) { 
        	double totalOrder = 0.0;
        	
        	for (int j = 0; j < dtlOrders.size(); j++) {
        		totalOrder += dtlOrders.get(j).getValue(i);
        	}
        	
        	tsTrendTotalOrders.add(i, totalOrder);
        }
       
        return tsTrendTotalOrders;
    }

	
    /**
     *  Calculate the aggregated order time series (sum of orders with their sign) of 
     *  trades made by LS investors
     *  
     *  @param secId the unique security identifier
     *  @return the time series of aggregated orders
     */
	public DoubleTimeSeries getLSTotalOrders(String secId) {     // TODO replace this and the next method with a single getTotalOrders() method, since trader and strategy objects used inside are generic 
		
		HashMap<String, Trader> LSTraders = getLSInvestors();
		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsLSTotalOrders = new DoubleTimeSeries();
		
		// No LS investors? Set entries in tsLSTotalOrders to zero and return
		if (LSTraders.size() == 0) {
		    tsLSTotalOrders.fillWithConstants((int) nTicks, 0.0);
		    return tsLSTotalOrders;
		}
        
		// Create a time series list of orders placed by all LS investors
        for (String key : LSTraders.keySet()) {
        	DoubleTimeSeries orders = new DoubleTimeSeries();
        	Trader ls = LSTraders.get(key);
        	DoubleTimeSeries lsPos = ls.getPortfolio().getTsPosition(secId);
        	
        	orders.add(0, lsPos.get(0));  // Order at t=0
        	
        	for (int i = 1; i < nTicks; i++) {
        		orders.add(i,  lsPos.get(i) - lsPos.get(i-1));
        	}
        	
        	dtlOrders.add(orders);
        }
        
        // Calculate the aggregate order at each tick by summing over all LS investors
        for (int i = 0; i < nTicks; i++) { 
        	double totalOrder = 0.0;
        	
        	for (int j = 0; j < dtlOrders.size(); j++) {
        		totalOrder += dtlOrders.get(j).getValue(i);
        	}
        	
        	tsLSTotalOrders.add(i, totalOrder);
        }
       
        return tsLSTotalOrders;
	}

	
    /**
     *  Calculate the aggregated time series of orders sent to reduce the VaR of
     *  fundamental investors' portfolios (sum of reduction orders with their sign)
     *  
     *  @param secId the unique security identifier
     *  @return the time series of aggregated reduction orders
     */
	public DoubleTimeSeries getFundTotalReducedOrders(String secId) { 
		
		HashMap<String, Trader> valueTraders = getValueInvestors();
		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsFundReducedOrders = new DoubleTimeSeries();
		
		// No value investors? Set entries in tsFundReducedOrders to zero and return
		if (valueTraders.size() == 0) {
		    tsFundReducedOrders.fillWithConstants((int) nTicks, 0.0);
		    return tsFundReducedOrders;
		}
		
		// Create a time series list of reduction orders placed by all fundamental investors
        for (String key : valueTraders.keySet()) {
        	DoubleTimeSeries orders = new DoubleTimeSeries();
        	Trader fund = valueTraders.get(key);
        	DoubleTimeSeries fundReducedPos = fund.getPortfolioReductions().getTsPosition(secId);
        	
        	for (int i = 0; i < nTicks; i++) {
        		orders.add(i,  fundReducedPos.get(i));
        	}
        	
        	dtlOrders.add(orders);
        }
        
        // Calculate the aggregate reduced orders at each tick by summing the reduction orders sent by all fundamental traders
        for (int i = 0; i < nTicks; i++) { 
        	double totalOrder = 0.0;
        	
        	for (int j = 0; j < dtlOrders.size(); j++) {
        		totalOrder += dtlOrders.get(j).getValue(i);
        	}
        	
        	tsFundReducedOrders.add(i, totalOrder);
        }
       
        return tsFundReducedOrders;
	}


    /**
     *  Calculate the aggregated time series of orders sent to reduce the VaR of
     *  trend followers' portfolios (sum of reduction orders with their sign)
     *  
     *  @param secId the unique security identifier
     *  @return the time series of aggregated reduction orders
     */
	public DoubleTimeSeries getTrendTotalReducedOrders(String secId) { 
		
		HashMap<String, Trader> trendTraders = getTrendFollowers();
		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsTrendReducedOrders = new DoubleTimeSeries();
		
		// No trend followers? Set entries in tsTrendReducedOrders to zero and return
		if (trendTraders.size() == 0) {
		    tsTrendReducedOrders.fillWithConstants((int) nTicks, 0.0);
		    return tsTrendReducedOrders;
		}
		
		// Create a time series list of reduction orders placed by all trend followers
        for (String key : trendTraders.keySet()) {
        	DoubleTimeSeries orders = new DoubleTimeSeries();
        	Trader trend = trendTraders.get(key);
        	DoubleTimeSeries trendReducedPos = trend.getPortfolioReductions().getTsPosition(secId);
        	       	
        	for (int i = 0; i < nTicks; i++) {
        		orders.add(i,  trendReducedPos.get(i));
        	}
        	
        	dtlOrders.add(orders);
        }
        
        // Calculate the aggregate reduced orders at each tick by summing the reduction orders sent by all trend followers
        for (int i = 0; i < nTicks; i++) { 
        	double totalOrder = 0.0;
        	
        	for (int j = 0; j < dtlOrders.size(); j++) {
        		totalOrder += dtlOrders.get(j).getValue(i);
        	}
        	
        	tsTrendReducedOrders.add(i, totalOrder);
        }
       
        return tsTrendReducedOrders;
	}


    /**
     *  Calculate the aggregated time series of orders sent to reduce the VaR of
     *  LS investors' portfolios (sum of reduction orders with their sign)
     *  
     *  @param secId the unique security identifier
     *  @return the time series of aggregated reduction orders
     */
	public DoubleTimeSeries getLSTotalReducedOrders(String secId) { 
		
		HashMap<String, Trader> LSTraders = getLSInvestors();
		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsLSReducedOrders = new DoubleTimeSeries();
		
		// No LS investors? Set entries in tsLSReducedOrders to zero and return
		if (LSTraders.size() == 0) {
		    tsLSReducedOrders.fillWithConstants((int) nTicks, 0.0);
		    return tsLSReducedOrders;
		}
		
		// Create a time series list of reduction orders placed by all LS investors
        for (String key : LSTraders.keySet()) {
        	DoubleTimeSeries orders = new DoubleTimeSeries();
        	Trader ls = LSTraders.get(key);
        	DoubleTimeSeries lsReducedPos = ls.getPortfolioReductions().getTsPosition(secId);
        	
        	for (int i = 0; i < nTicks; i++) {
        		orders.add(i,  lsReducedPos.get(i));
        	}
        	
        	dtlOrders.add(orders);
        }
        
        // Calculate the aggregate reduced orders at each tick by summing the reduction orders sent by all LS traders
        for (int i = 0; i < nTicks; i++) {
        	double totalOrder = 0.0;
        	
        	for (int j = 0; j < dtlOrders.size(); j++) {
        		totalOrder += dtlOrders.get(j).getValue(i);
        	}
        	
        	tsLSReducedOrders.add(i, totalOrder);
        }
       
        return tsLSReducedOrders;
	}

	
    /**
     *  Calculate the total volume time series (sum of absolute orders) of trades made by
     *  fundamental investors to reduce the VaR of their portfolio  
     *  
     *  @param secId the unique security identifier
     *  @return the time series of reduction volume
     */
	public DoubleTimeSeries getFundReducedVolume(String secId) { 
		
		HashMap<String, Trader> valueTraders = getValueInvestors();
		DoubleTimeSeriesList dtlAbsOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsFundReducedVolume = new DoubleTimeSeries();
		
		// No value investors? Set entries in tsFundReducedVolume to zero and return
		if (valueTraders.size() == 0) {
		    tsFundReducedVolume.fillWithConstants((int) nTicks, 0.0);
		    return tsFundReducedVolume;
		}
		
		// Create a time series list of absolute reduction orders placed by all fundamental investors
        for (String key : valueTraders.keySet()) {
        	DoubleTimeSeries absOrders = new DoubleTimeSeries();
        	Trader fund = valueTraders.get(key);
        	DoubleTimeSeries fundReducedPos = fund.getPortfolioReductions().getTsPosition(secId);
        	
        	for (int i = 0; i < nTicks; i++) {
        		absOrders.add(i,  Math.abs(fundReducedPos.get(i)));
        	}
        	
        	dtlAbsOrders.add(absOrders);
        }
        
        // Calculate the aggregate reduced volume at each tick by summing the absolute reduction orders sent by all fundamental traders
        for (int i = 0; i < nTicks; i++) { 
        	double volume = 0.0;
        	
        	for (int j = 0; j < dtlAbsOrders.size(); j++) {
        		volume += dtlAbsOrders.get(j).getValue(i);
        	}
        	
        	tsFundReducedVolume.add(i, volume);
        }
       
        return tsFundReducedVolume;
	}


    /**
     *  Calculate the total volume time series (sum of absolute orders) of trades made by
     *  trend followers to reduce the VaR of their portfolio  
     *  
     *  @param secId the unique security identifier
     *  @return the time series of reduction volume
     */
	public DoubleTimeSeries getTrendReducedVolume(String secId) { 
		
		HashMap<String, Trader> trendTraders = getTrendFollowers();
		DoubleTimeSeriesList dtlAbsOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsTrendReducedVolume = new DoubleTimeSeries();
		
		// No trend followers? Set entries in tsTrendReducedVolume to zero and return
		if (trendTraders.size() == 0) {
		    tsTrendReducedVolume.fillWithConstants((int) nTicks, 0.0);
		    return tsTrendReducedVolume;
		}
		
		// Create a time series list of absolute reduction orders placed by all trend followers
        for (String key : trendTraders.keySet()) {
        	DoubleTimeSeries absOrders = new DoubleTimeSeries();
        	Trader trend = trendTraders.get(key);
        	DoubleTimeSeries trendReducedPos = trend.getPortfolioReductions().getTsPosition(secId);
        	
        	for (int i = 0; i < nTicks; i++) {
        		absOrders.add(i,  Math.abs(trendReducedPos.get(i)));
        	}
        	
        	dtlAbsOrders.add(absOrders);
        }
        
        // Calculate the aggregate reduced volume at each tick by summing the absolute reduction orders sent by all trend followers
        for (int i = 0; i < nTicks; i++) { 
        	double volume = 0.0;
        	
        	for (int j = 0; j < dtlAbsOrders.size(); j++) {
        		volume += dtlAbsOrders.get(j).getValue(i);
        	}
        	
        	tsTrendReducedVolume.add(i, volume);
        }
       
        return tsTrendReducedVolume;
	}

	
    /**
     *  Calculate the total volume time series (sum of absolute orders) of trades made by
     *  LS investors to reduce the VaR of their portfolio  
     *  
     *  @param secId the unique security identifier
     *  @return the time series of reduction volume
     */
	public DoubleTimeSeries getLSReducedVolume(String secId) { 
		
		HashMap<String, Trader> LSTraders = getLSInvestors();
		DoubleTimeSeriesList dtlAbsOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsLSReducedVolume = new DoubleTimeSeries();
		
		// No LS investors? Set entries in tsLSReducedVolume to zero and return
		if (LSTraders.size() == 0) {
		    tsLSReducedVolume.fillWithConstants((int) nTicks, 0.0);
		    return tsLSReducedVolume;
		}
		
		// Create a time series list of absolute reduction orders placed by all LS investors
        for (String key : LSTraders.keySet()) {
        	DoubleTimeSeries absOrders = new DoubleTimeSeries();
        	Trader ls = LSTraders.get(key);
        	DoubleTimeSeries lsReducedPos = ls.getPortfolioReductions().getTsPosition(secId);
        	
        	for (int i = 0; i < nTicks; i++) {
        		absOrders.add(i,  Math.abs(lsReducedPos.get(i)));
        	}
        	
        	dtlAbsOrders.add(absOrders);
        }
        
        // Calculate the aggregate reduced volume at each tick by summing the absolute reduction orders sent by all LS traders
        for (int i = 0; i < nTicks; i++) {
        	double volume = 0.0;
        	
        	for (int j = 0; j < dtlAbsOrders.size(); j++) {
        		volume += dtlAbsOrders.get(j).getValue(i);
        	}
        	
        	tsLSReducedVolume.add(i, volume);
        }
       
        return tsLSReducedVolume;
	}

	
    /**
     *  Calculate the aggregated time series of sell-off orders due to VaR of
     *  fundamental investors' portfolios (sum of sell-off orders with their sign)
     *  
     *  @param secId the unique security identifier
     *  @return the time series of aggregated sell-off orders
     */
	public DoubleTimeSeries getFundTotalSelloffOrders(String secId) { 
		
		HashMap<String, Trader> valueTraders = getValueInvestors();
		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsFundSelloffOrders = new DoubleTimeSeries();
		
		// No value investors? Set entries in tsFundSelloffOrders to zero and return
		if (valueTraders.size() == 0) {
		    tsFundSelloffOrders.fillWithConstants((int) nTicks, 0.0);
		    return tsFundSelloffOrders;
		}
		
		// Create a time series list of sell-off orders placed by all fundamental investors
        for (String key : valueTraders.keySet()) {
        	DoubleTimeSeries orders = new DoubleTimeSeries();
        	Trader fund = valueTraders.get(key);
        	DoubleTimeSeries fundSelloffPos = fund.getTsSelloff().get(secId);
        	
        	for (int i = 0; i < nTicks; i++) {
        		orders.add(i,  fundSelloffPos.get(i));
        	}
        	
        	dtlOrders.add(orders);
        }
        
        // Calculate the aggregate sell-off orders at each tick by summing the sell-off orders sent by all fundamental traders
        for (int i = 0; i < nTicks; i++) { 
        	double totalOrder = 0.0;
        	
        	for (int j = 0; j < dtlOrders.size(); j++) {
        		totalOrder += dtlOrders.get(j).getValue(i);
        	}
        	
        	tsFundSelloffOrders.add(i, totalOrder);
        }
       
        return tsFundSelloffOrders;
	}

	
    /**
     *  Calculate the aggregated time series of sell-off orders due to VaR of
     *  trend followers' portfolios (sum of sell-off orders with their sign)
     *  
     *  @param secId the unique security identifier
     *  @return the time series of aggregated sell-off orders
     */
	public DoubleTimeSeries getTrendTotalSelloffOrders(String secId) { 
		
		HashMap<String, Trader> trendTraders = getTrendFollowers();
		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsTrendSelloffOrders = new DoubleTimeSeries();
		
		// No trend followers? Set entries in tsTrendSelloffOrders to zero and return
		if (trendTraders.size() == 0) {
		    tsTrendSelloffOrders.fillWithConstants((int) nTicks, 0.0);
		    return tsTrendSelloffOrders;
		}
		
		// Create a time series list of sell-off orders placed by all trend followers
        for (String key : trendTraders.keySet()) {
        	DoubleTimeSeries orders = new DoubleTimeSeries();
        	Trader trend = trendTraders.get(key);
        	DoubleTimeSeries trendSelloffPos = trend.getTsSelloff().get(secId);
        	       	
        	for (int i = 0; i < nTicks; i++) {
        		orders.add(i,  trendSelloffPos.get(i));
        	}
        	
        	dtlOrders.add(orders);
        }
        
        // Calculate the aggregate sell-off orders at each tick by summing the sell-off orders sent by all trend followers
        for (int i = 0; i < nTicks; i++) { 
        	double totalOrder = 0.0;
        	
        	for (int j = 0; j < dtlOrders.size(); j++) {
        		totalOrder += dtlOrders.get(j).getValue(i);
        	}
        	
        	tsTrendSelloffOrders.add(i, totalOrder);
        }
       
        return tsTrendSelloffOrders;
	}

	
    /**
     *  Calculate the aggregated time series of sell-off orders due to VaR of
     *  LS investors' portfolios (sum of sell-off orders with their sign)
     *  
     *  @param secId the unique security identifier
     *  @return the time series of aggregated sell-off orders
     */
	public DoubleTimeSeries getLSTotalSelloffOrders(String secId) { 
		
		HashMap<String, Trader> LSTraders = getLSInvestors();
		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsLSSelloffOrders = new DoubleTimeSeries();
		
		// No LS investors? Set entries in tsLSSelloffOrders to zero and return
		if (LSTraders.size() == 0) {
		    tsLSSelloffOrders.fillWithConstants((int) nTicks, 0.0);
		    return tsLSSelloffOrders;
		}
		
		// Create a time series list of sell-off orders placed by all LS investors
        for (String key : LSTraders.keySet()) {
        	DoubleTimeSeries orders = new DoubleTimeSeries();
        	Trader ls = LSTraders.get(key);
        	DoubleTimeSeries lsSelloffPos = ls.getTsSelloff().get(secId);
        	
        	for (int i = 0; i < nTicks; i++) {
        		orders.add(i,  lsSelloffPos.get(i));
        	}
        	
        	dtlOrders.add(orders);
        }
        
        // Calculate the aggregate sell-off orders at each tick by summing the sell-off orders sent by all LS traders
        for (int i = 0; i < nTicks; i++) {
        	double totalOrder = 0.0;
        	
        	for (int j = 0; j < dtlOrders.size(); j++) {
        		totalOrder += dtlOrders.get(j).getValue(i);
        	}
        	
        	tsLSSelloffOrders.add(i, totalOrder);
        }
       
        return tsLSSelloffOrders;
	}

	
    /**
     *  Calculate the total sell-off volume time series (sum of sell-off 
     *  orders in absolute value) of fundamental investors  
     *  
     *  @param secId the unique security identifier
     *  @return the time series of sell-off volume
     */
	public DoubleTimeSeries getFundSelloffVolume(String secId) { 
		
		HashMap<String, Trader> valueTraders = getValueInvestors();
		DoubleTimeSeriesList dtlAbsOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsFundSelloffVolume = new DoubleTimeSeries();
		
		// No value investors? Set entries in tsFundSelloffVolume to zero and return
		if (valueTraders.size() == 0) {
		    tsFundSelloffVolume.fillWithConstants((int) nTicks, 0.0);
		    return tsFundSelloffVolume;
		}
		
		// Create a time series list of absolute sell-off orders placed by all fundamental investors
        for (String key : valueTraders.keySet()) {
        	DoubleTimeSeries absOrders = new DoubleTimeSeries();
        	Trader fund = valueTraders.get(key);
        	DoubleTimeSeries fundSelloffPos = fund.getTsSelloff().get(secId);
        	
        	for (int i = 0; i < nTicks; i++) {
        		absOrders.add(i,  Math.abs(fundSelloffPos.get(i)));
        	}
        	
        	dtlAbsOrders.add(absOrders);
        }
        
        // Calculate the aggregate sell-off volume at each tick by summing the absolute sell-off orders sent by all fundamental traders
        for (int i = 0; i < nTicks; i++) { 
        	double volume = 0.0;
        	
        	for (int j = 0; j < dtlAbsOrders.size(); j++) {
        		volume += dtlAbsOrders.get(j).getValue(i);
        	}
        	
        	tsFundSelloffVolume.add(i, volume);
        }
       
        return tsFundSelloffVolume;
	}

	
    /**
     *  Calculate the total sell-off volume time series (sum of sell-off 
     *  orders in absolute value) of trend followers  
     *  
     *  @param secId the unique security identifier
     *  @return the time series of sell-off volume
     */
	public DoubleTimeSeries getTrendSelloffVolume(String secId) { 
		
		HashMap<String, Trader> trendTraders = getTrendFollowers();
		DoubleTimeSeriesList dtlAbsOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsTrendSelloffVolume = new DoubleTimeSeries();
		
		// No trend followers? Set entries in tsTrendSelloffVolume to zero and return
		if (trendTraders.size() == 0) {
		    tsTrendSelloffVolume.fillWithConstants((int) nTicks, 0.0);
		    return tsTrendSelloffVolume;
		}
		
		// Create a time series list of absolute sell-off orders placed by all trend followers
        for (String key : trendTraders.keySet()) {
        	DoubleTimeSeries absOrders = new DoubleTimeSeries();
        	Trader trend = trendTraders.get(key);
        	DoubleTimeSeries trendSelloffPos = trend.getTsSelloff().get(secId);
        	
        	for (int i = 0; i < nTicks; i++) {
        		absOrders.add(i,  Math.abs(trendSelloffPos.get(i)));
        	}
        	
        	dtlAbsOrders.add(absOrders);
        }
        
        // Calculate the aggregate sell-off volume at each tick by summing the absolute sell-off orders sent by all trend followers
        for (int i = 0; i < nTicks; i++) { 
        	double volume = 0.0;
        	
        	for (int j = 0; j < dtlAbsOrders.size(); j++) {
        		volume += dtlAbsOrders.get(j).getValue(i);
        	}
        	
        	tsTrendSelloffVolume.add(i, volume);
        }
       
        return tsTrendSelloffVolume;
	}


    /**
     *  Calculate the total sell-off volume time series (sum of sell-off 
     *  orders in absolute value) of LS investors  
     *  
     *  @param secId the unique security identifier
     *  @return the time series of sell-off volume
     */
	public DoubleTimeSeries getLSSelloffVolume(String secId) { 
		
		HashMap<String, Trader> LSTraders = getLSInvestors();
		DoubleTimeSeriesList dtlAbsOrders = new DoubleTimeSeriesList();
		DoubleTimeSeries tsLSSelloffVolume = new DoubleTimeSeries();
		
		// No LS investors? Set entries in tsLSSelloffVolume to zero and return
		if (LSTraders.size() == 0) {
		    tsLSSelloffVolume.fillWithConstants((int) nTicks, 0.0);
		    return tsLSSelloffVolume;
		}
		
		// Create a time series list of absolute sell-off orders placed by all LS investors
        for (String key : LSTraders.keySet()) {
        	DoubleTimeSeries absOrders = new DoubleTimeSeries();
        	Trader ls = LSTraders.get(key);
        	DoubleTimeSeries lsSelloffPos = ls.getTsSelloff().get(secId);
        	
        	for (int i = 0; i < nTicks; i++) {
        		absOrders.add(i,  Math.abs(lsSelloffPos.get(i)));
        	}
        	
        	dtlAbsOrders.add(absOrders);
        }
        
        // Calculate the aggregate sell-off volume at each tick by summing the absolute sell-off orders sent by all LS traders
        for (int i = 0; i < nTicks; i++) {
        	double volume = 0.0;
        	
        	for (int j = 0; j < dtlAbsOrders.size(); j++) {
        		volume += dtlAbsOrders.get(j).getValue(i);
        	}
        	
        	tsLSSelloffVolume.add(i, volume);
        }
       
        return tsLSSelloffVolume;
	}


//	/**
//	 *  Calculate the aggregated time series of sales due to the trading strategy of
//	 *  fundamental investors (sum of short orders with their sign)
//	 *  
//	 *  @param secId the unique security identifier
//	 *  @return the time series of aggregated strategy-induced sale orders
//	 */
//	public DoubleTimeSeries getFundTotalStrategySales(String secId) { 
//
//		HashMap<String, Trader> valueTraders = getValueInvestors();
//		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
//		DoubleTimeSeries tsFundStrategySales = new DoubleTimeSeries();
//
//		// No value investors? Set entries in tsFundStrategySales to zero and return
//		if (valueTraders.size() == 0) {
//			tsFundStrategySales.fillWithConstants((int) nTicks, 0.0);
//			return tsFundStrategySales;
//		}
//
//		// Create a time series list of strategy-induced sales placed by all fundamental investors
//		for (String key : valueTraders.keySet()) {
//			DoubleTimeSeries orders = new DoubleTimeSeries();
//			Trader fund = valueTraders.get(key);
//			DoubleTimeSeries fundSales = fund.getTsStrategySales().get(secId);
//
//			for (int i = 0; i < nTicks; i++) {
//				orders.add(i,  fundSales.get(i));
//			}
//
//			dtlOrders.add(orders);
//		}
//
//		// Calculate the aggregate strategy-induced sales at each tick by summing the strategy sales sent by all fundamental traders
//		for (int i = 0; i < nTicks; i++) { 
//			double totalOrder = 0.0;
//
//			for (int j = 0; j < dtlOrders.size(); j++) {
//				totalOrder += dtlOrders.get(j).getValue(i);
//			}
//
//			tsFundStrategySales.add(i, totalOrder);
//		}
//
//		return tsFundStrategySales;
//	}
//
//
//	/**
//	 *  Calculate the aggregated time series of sales due to the trading strategy of
//	 *  trend followers (sum of short orders with their sign)
//	 *  
//	 *  @param secId the unique security identifier
//	 *  @return the time series of aggregated strategy-induced sale orders
//	 */
//	public DoubleTimeSeries getTrendTotalStrategySales(String secId) { 
//
//		HashMap<String, Trader> trendTraders = getTrendFollowers();
//		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
//		DoubleTimeSeries tsTrendStrategySales = new DoubleTimeSeries();
//
//		// No trend followers? Set entries in tsTrendStrategySales to zero and return
//		if (trendTraders.size() == 0) {
//			tsTrendStrategySales.fillWithConstants((int) nTicks, 0.0);
//			return tsTrendStrategySales;
//		}
//
//		// Create a time series list of strategy-induced sales placed by all trend followers
//		for (String key : trendTraders.keySet()) {
//			DoubleTimeSeries orders = new DoubleTimeSeries();
//			Trader trend = trendTraders.get(key);
//			DoubleTimeSeries trendSales = trend.getTsStrategySales().get(secId);
//
//			for (int i = 0; i < nTicks; i++) {
//				orders.add(i,  trendSales.get(i));
//			}
//
//			dtlOrders.add(orders);
//		}
//
//		// Calculate the aggregate strategy-induced sales at each tick by summing the strategy sales sent by all trend followers
//		for (int i = 0; i < nTicks; i++) { 
//			double totalOrder = 0.0;
//
//			for (int j = 0; j < dtlOrders.size(); j++) {
//				totalOrder += dtlOrders.get(j).getValue(i);
//			}
//
//			tsTrendStrategySales.add(i, totalOrder);
//		}
//
//		return tsTrendStrategySales;
//	}
//
//
//	/**
//	 *  Calculate the aggregated time series of sales due to the trading strategy of
//	 *  LS investors (sum of short orders with their sign)
//	 *  
//	 *  @param secId the unique security identifier
//	 *  @return the time series of aggregated strategy-induced sale orders
//	 */
//	public DoubleTimeSeries getLSTotalStrategySales(String secId) { 
//
//		HashMap<String, Trader> LSTraders = getLSInvestors();
//		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
//		DoubleTimeSeries tsLSStrategySales = new DoubleTimeSeries();
//
//		// No LS investors? Set entries in tsLSStrategySales to zero and return
//		if (LSTraders.size() == 0) {
//			tsLSStrategySales.fillWithConstants((int) nTicks, 0.0);
//			return tsLSStrategySales;
//		}
//
//		// Create a time series list of strategy-induced sales placed by all LS investors
//		for (String key : LSTraders.keySet()) {
//			DoubleTimeSeries orders = new DoubleTimeSeries();
//			Trader ls = LSTraders.get(key);
//			DoubleTimeSeries lsSales = ls.getTsStrategySales().get(secId);
//
//			for (int i = 0; i < nTicks; i++) {
//				orders.add(i,  lsSales.get(i));
//			}
//
//			dtlOrders.add(orders);
//		}
//
//		// Calculate the aggregate strategy-induced sales at each tick by summing the strategy sales sent by all LS investors
//		for (int i = 0; i < nTicks; i++) { 
//			double totalOrder = 0.0;
//
//			for (int j = 0; j < dtlOrders.size(); j++) {
//				totalOrder += dtlOrders.get(j).getValue(i);
//			}
//
//			tsLSStrategySales.add(i, totalOrder);
//		}
//
//		return tsLSStrategySales;
//	}
//
//
//	/**
//	 *  Calculate the aggregated time series of sales due to VaR of
//	 *  fundamental investors (sum of short orders with their sign)
//	 *  
//	 *  @param secId the unique security identifier
//	 *  @return the time series of aggregated VaR-induced sale orders
//	 */
//	public DoubleTimeSeries getFundTotalVarSales(String secId) { 
//
//		HashMap<String, Trader> valueTraders = getValueInvestors();
//		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
//		DoubleTimeSeries tsFundVarSales = new DoubleTimeSeries();
//
//		// No value investors? Set entries in tsFundVarSales to zero and return
//		if (valueTraders.size() == 0) {
//			tsFundVarSales.fillWithConstants((int) nTicks, 0.0);
//			return tsFundVarSales;
//		}
//
//		// Create a time series list of VaR-induced sales placed by all fundamental investors
//		for (String key : valueTraders.keySet()) {
//			DoubleTimeSeries orders = new DoubleTimeSeries();
//			Trader fund = valueTraders.get(key);
//			DoubleTimeSeries fundSales = fund.getTsVarSales().get(secId);
//
//			for (int i = 0; i < nTicks; i++) {
//				orders.add(i,  fundSales.get(i));
//			}
//
//			dtlOrders.add(orders);
//		}
//
//		// Calculate the aggregate VaR-induced sales at each tick by summing the VaR sales sent by all fundamental traders
//		for (int i = 0; i < nTicks; i++) { 
//			double totalOrder = 0.0;
//
//			for (int j = 0; j < dtlOrders.size(); j++) {
//				totalOrder += dtlOrders.get(j).getValue(i);
//			}
//
//			tsFundVarSales.add(i, totalOrder);
//		}
//
//		return tsFundVarSales;
//	}
//
//
//	/**
//	 *  Calculate the aggregated time series of sales due to VaR of
//	 *  trend followers (sum of short orders with their sign)
//	 *  
//	 *  @param secId the unique security identifier
//	 *  @return the time series of aggregated VaR-induced sale orders
//	 */
//	public DoubleTimeSeries getTrendTotalVarSales(String secId) { 
//
//		HashMap<String, Trader> trendTraders = getTrendFollowers();
//		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
//		DoubleTimeSeries tsTrendVarSales = new DoubleTimeSeries();
//
//		// No trend followers? Set entries in tsTrendVarSales to zero and return
//		if (trendTraders.size() == 0) {
//			tsTrendVarSales.fillWithConstants((int) nTicks, 0.0);
//			return tsTrendVarSales;
//		}
//
//		// Create a time series list of VaR-induced sales placed by all trend followers
//		for (String key : trendTraders.keySet()) {
//			DoubleTimeSeries orders = new DoubleTimeSeries();
//			Trader trend = trendTraders.get(key);
//			DoubleTimeSeries trendSales = trend.getTsVarSales().get(secId);
//
//			for (int i = 0; i < nTicks; i++) {
//				orders.add(i,  trendSales.get(i));
//			}
//
//			dtlOrders.add(orders);
//		}
//
//		// Calculate the aggregate VaR-induced sales at each tick by summing the VaR sales sent by all trend followers
//		for (int i = 0; i < nTicks; i++) { 
//			double totalOrder = 0.0;
//
//			for (int j = 0; j < dtlOrders.size(); j++) {
//				totalOrder += dtlOrders.get(j).getValue(i);
//			}
//
//			tsTrendVarSales.add(i, totalOrder);
//		}
//
//		return tsTrendVarSales;
//	}
//
//
//	/**
//	 *  Calculate the aggregated time series of sales due to VaR of
//	 *  LS investors (sum of short orders with their sign)
//	 *  
//	 *  @param secId the unique security identifier
//	 *  @return the time series of aggregated VaR-induced sale orders
//	 */
//	public DoubleTimeSeries getLSTotalVarSales(String secId) { 
//
//		HashMap<String, Trader> LSTraders = getLSInvestors();
//		DoubleTimeSeriesList dtlOrders = new DoubleTimeSeriesList();
//		DoubleTimeSeries tsLSVarSales = new DoubleTimeSeries();
//
//		// No LS investors? Set entries in tsLSVarSales to zero and return
//		if (LSTraders.size() == 0) {
//			tsLSVarSales.fillWithConstants((int) nTicks, 0.0);
//			return tsLSVarSales;
//		}
//
//		// Create a time series list of VaR-induced sales placed by all LS investors
//		for (String key : LSTraders.keySet()) {
//			DoubleTimeSeries orders = new DoubleTimeSeries();
//			Trader ls = LSTraders.get(key);
//			DoubleTimeSeries lsSales = ls.getTsVarSales().get(secId);
//
//			for (int i = 0; i < nTicks; i++) {
//				orders.add(i,  lsSales.get(i));
//			}
//
//			dtlOrders.add(orders);
//		}
//
//		// Calculate the aggregate VaR-induced sales at each tick by summing the VaR sales sent by all LS investors
//		for (int i = 0; i < nTicks; i++) { 
//			double totalOrder = 0.0;
//
//			for (int j = 0; j < dtlOrders.size(); j++) {
//				totalOrder += dtlOrders.get(j).getValue(i);
//			}
//
//			tsLSVarSales.add(i, totalOrder);
//		}
//
//		return tsLSVarSales;
//	}

	
    /**
     *  Calculate the VaR time series averaged over fundamental investors  
     *    
     *  @return the time series of VaR level
     */
	public DoubleTimeSeries getFundAvgVaR() { 
		
		HashMap<String, Trader> valueTraders = getValueInvestors();
		DoubleTimeSeriesList dtlVar = new DoubleTimeSeriesList();
		DoubleTimeSeries tsFundAvgVar = new DoubleTimeSeries();
		
		// No value investors? Set entries in tsFundAvgVar to zero and return
		if (valueTraders.size() == 0) {
		    tsFundAvgVar.fillWithConstants((int) nTicks, 0.0);
		    return tsFundAvgVar;
		}
		
		// Create a time series list of VaR level of all value investors
        for (String key : valueTraders.keySet()) {
        	dtlVar.add(valueTraders.get(key).getTsVarPostTrade());
        }
        
        int nTicks = dtlVar.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the aggregated VaR at each tick by summing over all value investors
        	double totalVar = 0.0;
        	
        	for (int j = 0; j < dtlVar.size(); j++) {
        		totalVar += dtlVar.get(j).getValue(i);
        	}
        	
        	totalVar = totalVar / valueTraders.size();  // Divide by the number of value investors
        	
        	tsFundAvgVar.add(i, totalVar);
        }
       
        return tsFundAvgVar;
	}

	
    /**
     *  Calculate the VaR time series averaged over trend followers  
     *    
     *  @return the time series of VaR level
     */
	public DoubleTimeSeries getTrendAvgVaR() { 
		
		HashMap<String, Trader> trendTraders = getTrendFollowers();
		DoubleTimeSeriesList dtlVar = new DoubleTimeSeriesList();
		DoubleTimeSeries tsTrendAvgVar = new DoubleTimeSeries();
		
		// No trend followers? Set entries in tsTrendAvgVar to zero and return
		if (trendTraders.size() == 0) {
		    tsTrendAvgVar.fillWithConstants((int) nTicks, 0.0);
		    return tsTrendAvgVar;
		}
		
		// Create a time series list of VaR level of all trend followers
        for (String key : trendTraders.keySet()) {
        	dtlVar.add(trendTraders.get(key).getTsVarPostTrade());
        }
        
        int nTicks = dtlVar.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the aggregated VaR at each tick by summing over all trend followers
        	double totalVar = 0.0;
        	
        	for (int j = 0; j < dtlVar.size(); j++) {
        		totalVar += dtlVar.get(j).getValue(i);
        	}
        	
        	totalVar = totalVar / trendTraders.size();  // Divide by the number of trend followers
        	
        	tsTrendAvgVar.add(i, totalVar);
        }
       
        return tsTrendAvgVar;
	}

	
    /**
     *  Calculate the VaR time series averaged over LS investors  
     *    
     *  @return the time series of VaR level
     */
	public DoubleTimeSeries getLSAvgVaR() { 
		
		HashMap<String, Trader> LSTraders = getLSInvestors();
		DoubleTimeSeriesList dtlVar = new DoubleTimeSeriesList();
		DoubleTimeSeries tsLSAvgVar = new DoubleTimeSeries();
		
		// No LS investors? Set entries in tsLSAvgVar to zero and return
		if (LSTraders.size() == 0) {
		    tsLSAvgVar.fillWithConstants((int) nTicks, 0.0);
		    return tsLSAvgVar;
		}
		
		// Create a time series list of VaR level of all LS investors
        for (String key : LSTraders.keySet()) {
        	dtlVar.add(LSTraders.get(key).getTsVarPostTrade());
        }
        
        int nTicks = dtlVar.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the aggregated VaR at each tick by summing over all LS investors
        	double totalVar = 0.0;
        	
        	for (int j = 0; j < dtlVar.size(); j++) {
        		totalVar += dtlVar.get(j).getValue(i);
        	}
        	
        	totalVar = totalVar / LSTraders.size();  // Divide by the number of LS investors
        	
        	tsLSAvgVar.add(i, totalVar);
        }
       
        return tsLSAvgVar;
	}

    /**
     *  Calculate the stressed VaR time series averaged over fundamental investors  
     *    
     *  @return the time series of stressed VaR level
     */
	public DoubleTimeSeries getFundAvgStressedVaR() { 
		
		HashMap<String, Trader> valueTraders = getValueInvestors();
		DoubleTimeSeriesList dtlStressedVar = new DoubleTimeSeriesList();
		DoubleTimeSeries tsFundAvgStressedVar = new DoubleTimeSeries();
		
		// No value investors? Set entries in tsFundAvgStressedVar to zero and return
		if (valueTraders.size() == 0) {
		    tsFundAvgStressedVar.fillWithConstants((int) nTicks, 0.0);
		    return tsFundAvgStressedVar;
		}
		
		// Create a time series list of stressed VaR level of all value investors
        for (String key : valueTraders.keySet()) {
        	dtlStressedVar.add(valueTraders.get(key).getTsStressedVarPostTrade());
        }
        
        int nTicks = dtlStressedVar.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the aggregated stressed VaR at each tick by summing over all value investors
        	double totalStressedVar = 0.0;
        	
        	for (int j = 0; j < dtlStressedVar.size(); j++) {
        		totalStressedVar += dtlStressedVar.get(j).getValue(i);
        	}
        	
        	totalStressedVar = totalStressedVar / valueTraders.size();  // Divide by the number of value investors
        	
        	tsFundAvgStressedVar.add(i, totalStressedVar);
        }
       
        return tsFundAvgStressedVar;
	}

    /**
     *  Calculate the stressed VaR time series averaged over trend followers  
     *    
     *  @return the time series of stressed VaR level
     */
	public DoubleTimeSeries getTrendAvgStressedVaR() { 
		
		HashMap<String, Trader> trendTraders = getTrendFollowers();
		DoubleTimeSeriesList dtlStressedVar = new DoubleTimeSeriesList();
		DoubleTimeSeries tsTrendAvgStressedVar = new DoubleTimeSeries();
		
		// No trend followers? Set entries in tsTrendAvgStressedVar to zero and return
		if (trendTraders.size() == 0) {
		    tsTrendAvgStressedVar.fillWithConstants((int) nTicks, 0.0);
		    return tsTrendAvgStressedVar;
		}
		
		// Create a time series list of stressed VaR level of all trend followers
        for (String key : trendTraders.keySet()) {
        	dtlStressedVar.add(trendTraders.get(key).getTsStressedVarPostTrade());
        }
        
        int nTicks = dtlStressedVar.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the aggregated stressed VaR at each tick by summing over all trend followers
        	double totalStressedVar = 0.0;
        	
        	for (int j = 0; j < dtlStressedVar.size(); j++) {
        		totalStressedVar += dtlStressedVar.get(j).getValue(i);
        	}
        	
        	totalStressedVar = totalStressedVar / trendTraders.size();  // Divide by the number of trend followers
        	
        	tsTrendAvgStressedVar.add(i, totalStressedVar);
        }
       
        return tsTrendAvgStressedVar;
	}

	
    /**
     *  Calculate the stressed VaR time series averaged over LS investors  
     *    
     *  @return the time series of stressed VaR level
     */
	public DoubleTimeSeries getLSAvgStressedVaR() { 
		
		HashMap<String, Trader> LSTraders = getLSInvestors();
		DoubleTimeSeriesList dtlStressedVar = new DoubleTimeSeriesList();
		DoubleTimeSeries tsLSAvgStressedVar = new DoubleTimeSeries();
		
		// No LS investors? Set entries in tsLSAvgStressedVar to zero and return
		if (LSTraders.size() == 0) {
		    tsLSAvgStressedVar.fillWithConstants((int) nTicks, 0.0);
		    return tsLSAvgStressedVar;
		}
		
		// Create a time series list of stressed VaR level of all LS investors
        for (String key : LSTraders.keySet()) {
        	dtlStressedVar.add(LSTraders.get(key).getTsStressedVarPostTrade());
        }
        
        int nTicks = dtlStressedVar.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the aggregated stressed VaR at each tick by summing over all LS investors
        	double totalStressedVar = 0.0;
        	
        	for (int j = 0; j < dtlStressedVar.size(); j++) {
        		totalStressedVar += dtlStressedVar.get(j).getValue(i);
        	}
        	
        	totalStressedVar = totalStressedVar / LSTraders.size();  // Divide by the number of LS investors
        	
        	tsLSAvgStressedVar.add(i, totalStressedVar);
        }
       
        return tsLSAvgStressedVar;
	}
	

	
    /**
     *  Calculate the VaR limit time series averaged over fundamental investors  
     *    
     *  @return the time series of VaR limit level
     */
	public DoubleTimeSeries getFundAvgVarLimit() { 
		
		HashMap<String, Trader> valueTraders = getValueInvestors();
		DoubleTimeSeriesList dtlVarLimit = new DoubleTimeSeriesList();
		DoubleTimeSeries tsFundAvgVarLimit = new DoubleTimeSeries();
		
		// No value investors? Set entries in tsFundAvgVarLimit to zero and return
		if (valueTraders.size() == 0) {
		    tsFundAvgVarLimit.fillWithConstants((int) nTicks, 0.0);
		    return tsFundAvgVarLimit;
		}
		
		// Create a time series list of VaR limit of all value investors
        for (String key : valueTraders.keySet()) {
        	dtlVarLimit.add(valueTraders.get(key).getTsVarLimit());
        }
        
        int nTicks = dtlVarLimit.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the aggregated VaR limit at each tick by summing over all value investors
        	double totalVarLimit = 0.0;
        	
        	for (int j = 0; j < dtlVarLimit.size(); j++) {
        		totalVarLimit += dtlVarLimit.get(j).getValue(i);
        	}
        	
        	totalVarLimit = totalVarLimit / valueTraders.size();  // Divide by the number of value investors
        	
        	tsFundAvgVarLimit.add(i, totalVarLimit);
        }
       
        return tsFundAvgVarLimit;
	}


    /**
     *  Calculate the VaR limit time series averaged over trend followers  
     *    
     *  @return the time series of VaR limit level
     */
	public DoubleTimeSeries getTrendAvgVarLimit() { 
		
		HashMap<String, Trader> trendTraders = getTrendFollowers();
		DoubleTimeSeriesList dtlVarLimit = new DoubleTimeSeriesList();
		DoubleTimeSeries tsTrendAvgVarLimit = new DoubleTimeSeries();
		
		// No trend followers? Set entries in tsTrendAvgVarLimit to zero and return
		if (trendTraders.size() == 0) {
		    tsTrendAvgVarLimit.fillWithConstants((int) nTicks, 0.0);
		    return tsTrendAvgVarLimit;
		}
		
		// Create a time series list of VaR limit level of all trend followers
        for (String key : trendTraders.keySet()) {
        	dtlVarLimit.add(trendTraders.get(key).getTsVarLimit());
        }
        
        int nTicks = dtlVarLimit.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the aggregated VaR limit at each tick by summing over all trend followers
        	double totalVarLimit = 0.0;
        	
        	for (int j = 0; j < dtlVarLimit.size(); j++) {
        		totalVarLimit += dtlVarLimit.get(j).getValue(i);
        	}
        	
        	totalVarLimit = totalVarLimit / trendTraders.size();  // Divide by the number of trend followers
        	
        	tsTrendAvgVarLimit.add(i, totalVarLimit);
        }
       
        return tsTrendAvgVarLimit;
	}

	
    /**
     *  Calculate the VaR limit time series averaged over LS investors  
     *    
     *  @return the time series of VaR limit level
     */
	public DoubleTimeSeries getLSAvgVarLimit() { 
		
		HashMap<String, Trader> LSTraders = getLSInvestors();
		DoubleTimeSeriesList dtlVarLimit = new DoubleTimeSeriesList();
		DoubleTimeSeries tsLSAvgVarLimit = new DoubleTimeSeries();
		
		// No LS investors? Set entries in tsLSAvgVarLimit to zero and return
		if (LSTraders.size() == 0) {
		    tsLSAvgVarLimit.fillWithConstants((int) nTicks, 0.0);
		    return tsLSAvgVarLimit;
		}
		
		// Create a time series list of VaR Limit level of all LS investors
        for (String key : LSTraders.keySet()) {
        	dtlVarLimit.add(LSTraders.get(key).getTsVarLimit());
        }
        
        int nTicks = dtlVarLimit.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the aggregated VaR limit at each tick by summing over all LS investors
        	double totalVarLimit = 0.0;
        	
        	for (int j = 0; j < dtlVarLimit.size(); j++) {
        		totalVarLimit += dtlVarLimit.get(j).getValue(i);
        	}
        	
        	totalVarLimit = totalVarLimit / LSTraders.size();  // Divide by the number of LS investors
        	
        	tsLSAvgVarLimit.add(i, totalVarLimit);
        }
       
        return tsLSAvgVarLimit;
	}
	

	
    /**
     *  Calculate the average increment in wealth of fundamental investors.
     *  
     *  @param secId the unique security identifier
     *  @return the time series of wealth increment
     */
	public DoubleTimeSeries getFundAvgWealthIncrement(String secId) { 
		
		HashMap<String, Trader> valueTraders = getValueInvestors();
		DoubleTimeSeriesList dtlWealthIncrements = new DoubleTimeSeriesList();
		DoubleTimeSeries tsFundAvgWealthIncrement = new DoubleTimeSeries();
		
		// No value investors? Set entries in  tsFundAvgWealthIncrement to zero and return
		if (valueTraders.size() == 0) {
			tsFundAvgWealthIncrement.fillWithConstants((int) nTicks, 0.0);
		    return tsFundAvgWealthIncrement;
		}
		
		// Create a time series list of wealth increment of all fundamental investors
        for (String key : valueTraders.keySet()) {
        	DoubleTimeSeries prices = market.getPrices(secId);
        	DoubleTimeSeries positions = valueTraders.get(key).getPortfolio().getTsPosition(secId);
        	DoubleTimeSeries wealthIncrement = StatsTimeSeries.deltaWealth(prices, positions);
        	dtlWealthIncrements.add(wealthIncrement);
        }
        
        int nTicks = dtlWealthIncrements.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the total wealth increment at each tick by summing over all value investors 
        	double totalWealthIncrement = 0.0;
        	
        	for (int j = 0; j < dtlWealthIncrements.size(); j++) {
        		totalWealthIncrement += dtlWealthIncrements.get(j).getValue(i);
        	}
        	
        	totalWealthIncrement = totalWealthIncrement / valueTraders.size();  // Divide by the number of value investors
        	
        	tsFundAvgWealthIncrement.add(i, totalWealthIncrement);
        }
       
        return tsFundAvgWealthIncrement;
	}
	
    /**
     *  Calculate the average increment in wealth of trend followers.
     *  
     *  @param secId the unique security identifier
     *  @return the time series of wealth increment
     */
	public DoubleTimeSeries getTrendAvgWealthIncrement(String secId) { 
		
		HashMap<String, Trader> trendTraders = getTrendFollowers();
		DoubleTimeSeriesList dtlWealthIncrements = new DoubleTimeSeriesList();
		DoubleTimeSeries tsTrendAvgWealthIncrement = new DoubleTimeSeries();
		
		// No trend followers? Set entries in tsTrendAvgWealthIncrement to zero and return
		if (trendTraders.size() == 0) {
			tsTrendAvgWealthIncrement.fillWithConstants((int) nTicks, 0.0);
		    return tsTrendAvgWealthIncrement;
		}
		
		// Create a time series list of wealth increment of all trend followers
        for (String key : trendTraders.keySet()) {
        	DoubleTimeSeries prices = market.getPrices(secId);
        	DoubleTimeSeries positions = trendTraders.get(key).getPortfolio().getTsPosition(secId);
        	DoubleTimeSeries wealthIncrement = StatsTimeSeries.deltaWealth(prices, positions);
        	dtlWealthIncrements.add(wealthIncrement);
        }
        
        int nTicks = dtlWealthIncrements.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the total wealth increment at each tick by summing over all trend followers 
        	double totalWealthIncrement = 0.0;
        	
        	for (int j = 0; j < dtlWealthIncrements.size(); j++) {
        		totalWealthIncrement += dtlWealthIncrements.get(j).getValue(i);
        	}
        	
        	totalWealthIncrement = totalWealthIncrement / trendTraders.size();  // Divide by the number of trend followers
        	
        	tsTrendAvgWealthIncrement.add(i, totalWealthIncrement);
        }
       
        return tsTrendAvgWealthIncrement;
	}


    /**
     *  Calculate the average increment in wealth of LS investors.
     *  
     *  @param secId the unique security identifier
     *  @return the time series of wealth increment
     */
	public DoubleTimeSeries getLSAvgWealthIncrement(String secId) { 
		
		HashMap<String, Trader> LSTraders = getLSInvestors();
		DoubleTimeSeriesList dtlWealthIncrements = new DoubleTimeSeriesList();
		DoubleTimeSeries tsLSAvgWealthIncrement = new DoubleTimeSeries();
		
		// No LS investors? Set entries in tsLSAvgWealthIncrement to zero and return
		if (LSTraders.size() == 0) {
			tsLSAvgWealthIncrement.fillWithConstants((int) nTicks, 0.0);
		    return tsLSAvgWealthIncrement;
		}
		
		// Create a time series list of wealth increment of all LS investors
        for (String key : LSTraders.keySet()) {
        	DoubleTimeSeries prices = market.getPrices(secId);
        	DoubleTimeSeries positions = LSTraders.get(key).getPortfolio().getTsPosition(secId);
        	DoubleTimeSeries wealthIncrement = StatsTimeSeries.deltaWealth(prices, positions);
        	dtlWealthIncrements.add(wealthIncrement);
        }
        
        int nTicks = dtlWealthIncrements.get(0).size();
        
        for (int i = 0; i < nTicks; i++) {  // calculate the total wealth increment at each tick by summing over all LS investors
        	double totalWealthIncrement = 0.0;
        	
        	for (int j = 0; j < dtlWealthIncrements.size(); j++) {
        		totalWealthIncrement += dtlWealthIncrements.get(j).getValue(i);
        	}
        	
        	totalWealthIncrement = totalWealthIncrement / LSTraders.size();  // Divide by the number of LS investors
        	
        	tsLSAvgWealthIncrement.add(i, totalWealthIncrement);
        }
       
        return tsLSAvgWealthIncrement;
	}
	
	
       
    /**
     * Calculates the average of the entry multiplier (e.g. delta slope) used by trend followers, over 
     * {@code normPeriod} time steps. Since {@link TrendMABCStrategy} can use a variety of entry 
     * indicators we need to normalise them so they do not lead to positions that differ by orders of
     * magnitude from those of value investors. This method helps us get a feel for what that order of
     * magnitude is for any given entry multiplier.
     * <p>
     * The normalisation window {@code normPeriod} cannot overlap with the warm-up period of the simulation 
     * {@code max(maLongTicks,  volWindow).
     *    
     * @param secId security identifier of the share
     * @param normPeriod range of input data for normalising the orders of value investors and trend 
     * followers (in ticks)
     * @param maShortTicks range for short (fast) moving average of prices (in ticks)
     * @param maLongTicks range for long (slow) moving average of prices (in ticks)
     * @param volWindow the size of the window used for volatility calculations
     * @param multiplier method to calculate the size of the position
     * 
     * @return average value of the entry multiplier for the trend follower, over {@code normPeriod} time
     * steps
     * 
     */
    public double magnitudeTrendIndicator(String secId, int normPeriod, int maShortTicks, int maLongTicks, int volWindow, MultiplierTrend multiplier) {
    	
    	DoubleTimeSeries tsPrice = market.getPrices(secId);
    	int lastTick = tsPrice.getLastTick();    // the last tick for which a price is available 
    	        
        double magnitudeTrendIndicator = 0;
        
        Assertion.assertOrKill(normPeriod + Math.max(maLongTicks,  volWindow) <= lastTick + 1, 
                "At tick " + lastTick + "normPeriod (=" + normPeriod + ") overlaps with " +
                		"the warm-up period (=" + Math.max(maLongTicks,  volWindow) + ").");
        
        for (int k = 0; k < normPeriod; k++) {
        	
        	/*
        	 * Collect the prices in the long-term, short-term and volatility windows for subsequent calculations
        	 */
        	DoubleTimeSeries tsPriceShort_current_tick = new DoubleTimeSeries();
        	DoubleTimeSeries tsPriceLong_current_tick = new DoubleTimeSeries();
        	DoubleTimeSeries tsPriceShort_previous_tick = new DoubleTimeSeries();
        	DoubleTimeSeries tsPriceLong_previous_tick = new DoubleTimeSeries();
        	DoubleTimeSeries tsPriceVolWindow = new DoubleTimeSeries();
        	
        	for (int t = 0; t < maShortTicks; t++) {
        		tsPriceShort_current_tick.add(tsPrice.get(lastTick - t - k));
        		tsPriceShort_previous_tick.add(tsPrice.get(lastTick - t-1 - k));
        	}
        	
        	for (int t = 0; t < maLongTicks; t++) {
        		tsPriceLong_current_tick.add(tsPrice.get(lastTick - t - k));
        		tsPriceLong_previous_tick.add(tsPrice.get(lastTick - t-1 - k));
        	}
        	
        	for (int t = 0; t < volWindow; t++) {
        		tsPriceVolWindow.add(tsPrice.get(lastTick - t - k));
        	}
        	
        	/*
        	 * Calculate the mean of the TREND entry indicator over the window 'normPeriod'
        	 */
        	double maShort_current_tick = tsPriceShort_current_tick.mean();
        	double maShort_previous_tick = tsPriceShort_previous_tick.mean();
        	double maLong_current_tick = tsPriceLong_current_tick.mean();
        	double maLong_previous_tick = tsPriceLong_previous_tick.mean();
        	
        	double slopeShort = Math.atan(maShort_current_tick - maShort_previous_tick);
        	double slopeLong = Math.atan(maLong_current_tick - maLong_previous_tick);
        	double deltaSlope = slopeShort - slopeLong;
        	
        	double stdDev = tsPriceVolWindow.stdev();
        	
        	if (multiplier == MultiplierTrend.CONSTANT) {
        		magnitudeTrendIndicator = magnitudeTrendIndicator + 1;
            }
            else if (multiplier == MultiplierTrend.FAST_MA_SLOPE) {  // Computing slope short MA
            	magnitudeTrendIndicator = magnitudeTrendIndicator + Math.abs(slopeShort);
            }
            else if (multiplier == MultiplierTrend.MA_SLOPE_DIFFERENCE) {    // Computing slope difference for fast vs slow MA
            	magnitudeTrendIndicator = magnitudeTrendIndicator + Math.abs(deltaSlope);
            }
            else if (multiplier == MultiplierTrend.MA_SLOPE_DIFFERENCE_STDDEV) {     // Computing slope difference for fast vs slow MA
            	magnitudeTrendIndicator = magnitudeTrendIndicator + Math.abs(deltaSlope) / stdDev;
            }
            else if (multiplier == MultiplierTrend.STDDEV) {     // Computing the standard deviation of prices
            	magnitudeTrendIndicator = magnitudeTrendIndicator + 1 / stdDev;
            }
            else {
                Assertion.assertStrict(false, Level.ERR, "The method for multiplier " + 
                        multiplier + " is not implemented");
            }
        	
        }
                
        return magnitudeTrendIndicator / normPeriod;
    }
    
    
    /**
     * Calculates the average of the entry multiplier ({@code value - price}) used by value investors,
     * over a specified number of time steps. Similar to {@code magnitudeTrendIndicator(...)}, we need
     * to normalise the multiplier so it does not lead to positions that differ by orders of magnitude 
     * from those of trend followers. This method helps us get a feel for what that order of magnitude 
     * is for any given entry multiplier.
     * 
     * @param secId Identifier of the share
     * @param normPeriod range of input data for normalising the orders of value investors and trend 
     * followers (in ticks)
     * 
     * @return average value of the entry multiplier for the trend follower, over {@code normPeriod} time
     * steps
     * 
     */
    public double magnitudeValueIndicator(String secId, int normPeriod, double valueOffset) {
    	
    	DoubleTimeSeries tsPrice = market.getPrices(secId);
    	DoubleTimeSeries tsValue = market.getFundValues(secId);

        int lastTick = tsPrice.getLastTick();

    	Assertion.assertOrKill(normPeriod <= lastTick + 1, "normPeriod (=" + normPeriod + ") has to be smaller " +
    			"or equal to the number of ticks in the simulation");
    	Assertion.assertOrKill(tsPrice.quickCompare(tsValue), "DoubleTimeSeries.quickCompare(...) for " +
    			"the time series tsPrice and tsValue failed");
    	
        double magnitudeValueIndicator = 0;
                
        for (int k = 0; k < normPeriod; k++) {
        	magnitudeValueIndicator = magnitudeValueIndicator + Math.abs(tsValue.get(lastTick-k) + valueOffset - tsPrice.get(lastTick-k));
        }
                
        return magnitudeValueIndicator / normPeriod;
    }
    
    
    /**
     * Calculates the average of the entry multiplier ({@code value - price}) used by LS investors,
     * over a specified number of time steps. Similar to {@code magnitudeTrendIndicator(...)}, we need
     * to normalise the multiplier so it does not lead to positions that differ by orders of magnitude 
     * from those of value investors. This method helps us get a feel for what that order of magnitude 
     * is for any given entry multiplier.
     * 
     * @param secId Identifier of the share
     * @param normPeriod range of input data for normalising the orders of value investors and LS 
     * investors (in ticks)
     * 
     * @return average value of the entry multiplier for the LS investors, over {@code normPeriod} time
     * steps
     * 
     */
    public double magnitudeLSIndicator(String secId, int normPeriod, int histWindow, int volWindow, MultiplierLS multiplier) {
    	
    	DoubleTimeSeries tsPrice_1 = market.getPrices("IBM");
    	DoubleTimeSeries tsPrice_2 = market.getPrices(secId);
    	DoubleTimeSeries tsSpread = StatsTimeSeries.substraction(tsPrice_1, tsPrice_2);

        int lastTick = tsPrice_1.getLastTick();

    	Assertion.assertOrKill(normPeriod <= lastTick + 1, "normPeriod (=" + normPeriod + ") has to be smaller " +
     			"or equal to the number of ticks in the simulation");
    	    	
        double magnitudeLSIndicator = 0;
        
        DoubleTimeSeries tsSpreadHistWindow = new DoubleTimeSeries();
        DoubleTimeSeries tsSpreadVolWindow = new DoubleTimeSeries();
                
        for (int k = 0; k < normPeriod; k++) {
        	
        	for (int t = 0; t < histWindow; t++) {
        		tsSpreadHistWindow.add(tsSpread.get(lastTick - t - k));
        	}

        	for (int t = 0; t < volWindow; t++) {
        		tsSpreadVolWindow.add(tsSpread.get(lastTick - t - k));
        	}

        	/*
        	 * Calculate the mean of the LS entry indicator over the window 'normPeriod'
        	 */
        	
        	double histMean = tsSpreadHistWindow.mean();
        	double stdDev = tsSpreadVolWindow.stdev();
        	
        	if (multiplier == MultiplierLS.DIVERGENCE) {
        		magnitudeLSIndicator = magnitudeLSIndicator + Math.abs(tsSpread.get(lastTick-k) - histMean);
            }
            else if (multiplier == MultiplierLS.DIVERGENCE_STDDEV) {
            	magnitudeLSIndicator = magnitudeLSIndicator + Math.abs(tsSpread.get(lastTick-k) - histMean) / stdDev;
            }
        }
                
        return magnitudeLSIndicator / normPeriod;
    }
    

    /**
     * Calculates how many fundamental investors fail at each time step.
     * 
     * @return time series of FUND failures
     */
	public DoubleTimeSeries getFundFailures() { 
		
		HashMap<String, Trader> valueTraders = getValueInvestors();
		DoubleTimeSeries tsFundFailures = new DoubleTimeSeries();
		tsFundFailures.fillWithConstants((int) nTicks, 0.0);
		
		// No value investors? Set entries in  tsFundFailures to zero and return
		if (valueTraders.size() == 0)
			return tsFundFailures;
				
		// Create a time series list of fundamental investor failures
        for (int i = 0; i < nTicks; i++) { 
        	int failures = 0;
        	for (String key : valueTraders.keySet()) {
        		if (valueTraders.get(key).getFailureTick() == i)
        			failures += 1;
        	}
        	tsFundFailures.add(i, failures);
        }	
       
        return tsFundFailures;
	}
	
    /**
     * Calculates how many trend followers fail at each time step.
     * 
     * @return time series of TREND failures
     */
	public DoubleTimeSeries getTrendFailures() { 
		
		HashMap<String, Trader> trendTraders = getTrendFollowers();
		DoubleTimeSeries tsTrendFailures = new DoubleTimeSeries();
		tsTrendFailures.fillWithConstants((int) nTicks, 0.0);
		
		// No trend followers? Set entries in  tsTrendFailures to zero and return
		if (trendTraders.size() == 0)
			return tsTrendFailures;
				
		// Create a time series list of trend follower failures
        for (int i = 0; i < nTicks; i++) { 
        	int failures = 0;
        	for (String key : trendTraders.keySet()) {
        		if (trendTraders.get(key).getFailureTick() == i)
        			failures += 1;
        	}
        	tsTrendFailures.add(i, failures);
        }	
       
        return tsTrendFailures;
	}

    /**
     * Calculates how many LS investors fail at each time step.
     * 
     * @return time series of LS failures
     */
	public DoubleTimeSeries getLSFailures() { 
		
		HashMap<String, Trader> LSTraders = getLSInvestors();
		DoubleTimeSeries tsLSFailures = new DoubleTimeSeries();
		tsLSFailures.fillWithConstants((int) nTicks, 0.0);
		
		// No LS investors? Set entries in  tsLSFailures to zero and return
		if (LSTraders.size() == 0)
			return tsLSFailures;
				
		// Create a time series list of LS investor failures
        for (int i = 0; i < nTicks; i++) { 
        	int failures = 0;
        	for (String key : LSTraders.keySet()) {
        		if (LSTraders.get(key).getFailureTick() == i)
        			failures += 1;
        	}
        	tsLSFailures.add(i, failures);
        }	
       
        return tsLSFailures;
	}

	
}
