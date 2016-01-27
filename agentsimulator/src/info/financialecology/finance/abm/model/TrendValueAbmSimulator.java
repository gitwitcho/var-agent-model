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
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.ShortSellingTrend;
import info.financialecology.finance.abm.model.strategy.TrendMABCStrategy.VariabilityCapFactorTrend;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.PositionUpdateValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.OrderOrPositionStrategyValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.VariabilityCapFactorValue;
import info.financialecology.finance.abm.model.strategy.ValueMABCStrategy.ShortSellingValue;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.WorldClock;
import info.financialecology.finance.utilities.abm.AbstractSimulator;
import info.financialecology.finance.utilities.datagen.DataGenerator;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeriesList;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.statistics.StatsTimeSeries;
import info.financialecology.finance.abm.model.util.TradingPortfolio;

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
public class TrendValueAbmSimulator extends AbstractSimulator {
    
    private ISchedule scheduler;                    // main scheduler to run actions (=methods) at particular points in time
    private ShareMarket market;                     // stock market where trend followers trade with value investors 
    
    private int nextTrendIndex = 0;                 // the next numeric index for the trend follower labels
    private int nextValueIndex = 0;                 // the next numeric index for the value investor labels    
    private String prefixTrendFollower = "Trend";   // label prefix for formatting output
    private String prefixValueInvestor = "Value";   // label prefix for formatting output    
    
    private static final Logger logger = (Logger)LoggerFactory.getLogger(TrendValueAbmSimulator.class.getSimpleName());
    
    
    /**
     * Constructor. Creates the scheduler ({@link ISchedule}) and the {@link ShareMarket}.
     */
    public TrendValueAbmSimulator() {
        
        logger.trace("Calling: TrendValueAbmSimulator()");
        
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
     */
    public TrendValueAbmSimulator(String pTrend, String pValue) {
        
        this();

        logger.trace("Calling: TrendValueAbmSimulator(String, String)");

        prefixTrendFollower = pTrend;
        prefixValueInvestor = pValue;
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
//        HashMap<String, Trader> valueInvestors = getValueInvestors();
        
        Assertion.assertStrict(market.isShareTraded(secId), Level.ERR, "There is no share with ID '"
                + secId + "' traded in the market '" + market.getId() + "'");
        Assertion.assertStrict((!trendFollowers.isEmpty()), Level.ERR, "Cannot assign trend strategy" +
        		" because there are no trend followers in the market");
//        Assertion.assertStrict((!trendFollowers.isEmpty() || !valueInvestors.isEmpty()), Level.ERR, 
//                "There are neither trend followers nor value investors in the market");
        
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
     * @param multiplier a multiplier for entry positions, depending on the approach chosen (see {@link TrendMABCStrategy.Multiplier})
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
//        Assertion.assertStrict((!trendFollowers.isEmpty() || !valueTraders.isEmpty()), Level.ERR, "There are neither trend followers nor fund traders in the market");
        
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
    
    
//    /**
//     * Set the exogenous price process
//     * 
//     * @param exoPriceGen a {@link DataGenerator} for the exogenous price process. The full price 
//     * process consists of two parts
//     * <ul>
//     * <li>an endogenous part that calculates prices based on orders
//     * or positions
//     * <li> an exogenous part that is provided by the user in form of a {@link DataGenerator} process
//     * </ul>   
//     */
//    public void setExogeneousPriceProcess(DataGenerator exoPriceGen) {
//        market.getMarketMaker().setExogenousPriceGenerator(exoPriceGen);
//    }
    
    
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
        
        Assertion.assertStrict((!getTrendFollowers().isEmpty() || !getValueInvestors().isEmpty()), Level.ERR, 
                "There are no trend followers and value investors in the market '" + market.getId() + "'");
        
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
     *  Calculate the total volume time series (sum of absolute orders) of trades made by both 
     *  fundamental investors and trend followers
     *  
     *  @param secId the unique security identifier
     *  @return the time series of total volume
     */
	public DoubleTimeSeries getTotalVolume(String secId) {
		
		DoubleTimeSeries tsFundVolume = getFundVolume(secId);
		DoubleTimeSeries tsTrendVolume = getTrendVolume(secId);
		DoubleTimeSeries tsTotalVolume = new DoubleTimeSeries();
     
        int nTicks = tsFundVolume.size();
        
        for (int i = 0; i < nTicks; i++) {
        	double volume = tsFundVolume.get(i) + tsTrendVolume.get(i);
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
    
}
