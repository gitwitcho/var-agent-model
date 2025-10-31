/**
 * 
 */
package info.financialecology.finance.abm.model.agent;

import info.financialecology.finance.abm.model.ShareMarket;
import info.financialecology.finance.abm.model.strategy.TradingStrategy;
import info.financialecology.finance.abm.model.strategy.TradingStrategy.Order;
import info.financialecology.finance.abm.model.util.TradingPortfolio;
import info.financialecology.finance.utilities.Assertion;
import info.financialecology.finance.utilities.Assertion.Level;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.statistics.StatsTimeSeries;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import repast.simphony.engine.schedule.ScheduledMethod;



/**
 * @author Gilbert Peffer
 *
 */
public class Trader extends Agent {

    private static final Logger logger = (Logger)LoggerFactory.getLogger(Trader.class.getSimpleName());

    private String label;       // the label (or name) of the trader
    
    private ShareMarket market;             // the market in which the trader operates
    private ShareMarketMaker marketMaker;   // the market maker from which the trader takes her prices
	private TradingPortfolio portfolio;     // the trading portfolio with the positions and orders
	private HashMap<String, TradingStrategy> strategies;   // the trading strategies that the trader is actively engaging in
	private UseVar useVar;                  // specifies if the agent uses a VaR system
	private double varLimit;                // VaR threshold (in dollar value)
	private UseStressedVar useStressedVar;             // specifies if the agent uses stressed VaR
	private UseStressedEs useStressedEs;               // specifies if the agent uses stressed ES
	private VariabilityVarLimit variabilityVarLimit;   // specifies if the VaR limit is constant or variable
	private UseEs useEs;                   // specifies if the agent uses an ES system
	private double esLimit;                // ES threshold (in dollar value)
	
	private State state;                    // specifies if the agent has failed (wealth < 0) 
	private int failureTick;				// time step where the agent has failed (-1 if the agent does not fail)
	
	private int volWindow;                          // volatility window used to calculate VaR and ES

	private DoubleTimeSeries tsVar_preTrade;        // time series of VaR (before any trade is done) - used for plots
	private DoubleTimeSeries tsVar_postTrade;       // time series of VaR (after the trade is done) - used for plots
	private DoubleTimeSeries tsStressedVar_postTrade;    // time series of stressed VaR (after the trade is done) - used for plots
	private TradingPortfolio portfolioVarReductions;     // the trading portfolio with the reductions in positions made to keep VaR below limit
	private HashMap<String, DoubleTimeSeries> tsVarSelloff;         // time series of sell-off orders due to VaR - used for plots

	private DoubleTimeSeries tsEs_preTrade;        // time series of ES (before any trade is done) - used for plots
	private DoubleTimeSeries tsEs_postTrade;       // time series of ES (after the trade is done) - used for plots
	private DoubleTimeSeries tsStressedEs_postTrade;     // time series of stressed ES (after the trade is done) - used for plots
	private TradingPortfolio portfolioEsReductions;      // the trading portfolio with the reductions in positions made to keep ES below limit
	private HashMap<String, DoubleTimeSeries> tsEsSelloff;         // time series of sell-off orders due to ES - used for plots

    private HashMap<String, Double> maMeanReturns_previous_tick;        // given: mean of log-returns at t-1 (used in the incremental calculation of variance)
    private HashMap<String, HashMap<String, Double>> maCovarianceReturns_previous_tick;    // given: covariances of log-returns at t-1 (used in the incremental calculation of covariances)
    private HashMap<String, Double> maMeanReturns_current_tick;         // compute: mean of log-returns at t (used in the incremental calculation of variance)
    private HashMap<String, HashMap<String, Double>> maCovarianceReturns_current_tick;    // compute: covariances of log-returns at t (used in the incremental calculation of covariances)
    private HashMap<String, Boolean> firstMACalculation;                // the first calculation needs to use the full MA and variance methods, after that incremental
    
    private HashMap<String, HashMap<String, Double>> maxCovariances;    // covariances of log-returns at the time step when the average covariance was the highest 
    																	// since the start of the simulation (used in the calculation of stressed VaR and ES)
    
	private DoubleTimeSeries tsVolatilityIndex;       // average of volatility over all assets (used to update the VaR limit)
	private double volatilityIndex_MA_t = 0;          // historical mean of volatility index over a window
	private double volatilityIndex_MA_t_1 = 0;
	private DoubleTimeSeries tsVarLimit;       // time series of variable VaR limit
	
	private double deltaWealth_t;              // increment in wealth at current time step (used to decide if the agent is dead)
	private double deltaWealth_t_1;
	

	public enum UseVar {      // Specifies if the agent uses a value-at-risk system
        TRUE,                 // The agent uses VaR
        FALSE;                // The agent does not use VaR   
    }

	public enum UseEs {      // Specifies if the agent uses an expected shortfall system
        TRUE,                 // The agent uses ES
        FALSE;                // The agent does not use ES   
    }

    public enum UseStressedVar {      // Specifies if the agent uses stressed VaR
        TRUE,                         // The agent uses stressed VaR
        FALSE;                        // The agent does not use stressed VaR
    }

    public enum UseStressedEs {       // Specifies if the agent uses stressed ES
        TRUE,                         // The agent uses stressed ES
        FALSE;                        // The agent does not use stressed ES
    }

    public enum VariabilityVarLimit {      // Specifies if the varLimit is constant or varies
        CONSTANT,                          // the varLimit is constant
        PROCYCLICAL,                       // the capFactor is variable and decreases with market instability
        COUNTERCYCLICAL;                   // the capFactor is variable and increases with market instability
    }

	public enum State {      // Specifies if the agent has failed
        DEAD,                // The agent has failed (wealth < 0)
        ALIVE;               // The agent has not failed   
    }
	
    public Trader() {
        this("trader");
    }

	public Trader(String label) {
		super();
//		setID();
		
		this.state = State.ALIVE;
		this.failureTick = -1;
		this.deltaWealth_t = 0;

		this.market = null;
		this.marketMaker = null;
		this.portfolio = new TradingPortfolio();
		this.strategies = new HashMap<String, TradingStrategy>();
		
		this.label = label;
		
		this.tsVar_preTrade = new DoubleTimeSeries();
		this.tsVar_postTrade = new DoubleTimeSeries();
		this.tsStressedVar_postTrade = new DoubleTimeSeries();
		this.portfolioVarReductions = new TradingPortfolio();
		this.tsVarSelloff =  new HashMap<String, DoubleTimeSeries>();

		this.tsEs_preTrade = new DoubleTimeSeries();
		this.tsEs_postTrade = new DoubleTimeSeries();
		this.tsStressedEs_postTrade = new DoubleTimeSeries();
		this.portfolioEsReductions = new TradingPortfolio();
		this.tsEsSelloff =  new HashMap<String, DoubleTimeSeries>();

		this.maMeanReturns_previous_tick = new HashMap<String, Double>();
		this.maCovarianceReturns_previous_tick = new HashMap<String, HashMap<String, Double>>();
		this.maMeanReturns_current_tick = new HashMap<String, Double>();
		this.maCovarianceReturns_current_tick = new HashMap<String, HashMap<String, Double>>();
		this.firstMACalculation = new HashMap<String, Boolean>();
		
		this.maxCovariances = new HashMap<String, HashMap<String, Double>>();
		
		this.tsVolatilityIndex = new DoubleTimeSeries();
		this.tsVarLimit = new DoubleTimeSeries();
		
		this.portfolio.setTraderId(label);
		
        logger.trace("CREATED: {}", this.toString());
	}
    
    /**
     * @param market the market in which the trader operates
     */
    public void enterMarket(ShareMarket market) {
        this.market = market;
        marketMaker = market.getMarketMaker();
    }
    
    /**
     * Add a new trading strategy
     */
    public void addStrategy(TradingStrategy strategy) {    	

//### TODO The assertion below doesn't work for the multi-asset case - use strategy.getUniqueId instead      
//###        Assertion.assertStrict(!strategies.containsKey(strategy.getSecId()), Level.INFO, "Strategy for security '" 
//###        + strategy.getSecId() + "' already exists for trader '" + getLabel() + "'");  // BL: Level changed to INFO to allow that a strategy can be redefined
        
        strategies.put(strategy.getUniqueId(), strategy);
        
        Set<String> secIds = strategy.getSecIds();
        
        for (String secId_1 : secIds) {
            portfolio.newSecurity(secId_1);
            
        	portfolioVarReductions.newSecurity(secId_1);
        	tsVarSelloff.put(secId_1, new DoubleTimeSeries());
        	portfolioEsReductions.newSecurity(secId_1);
        	tsEsSelloff.put(secId_1, new DoubleTimeSeries());
        	
        	maMeanReturns_previous_tick.put(secId_1, 0.0);
        	maMeanReturns_current_tick.put(secId_1, 0.0);        	
        	firstMACalculation.put(secId_1, true);
        }
    }

    /**
     * Set the volatility window
     */
    public void setVolWindow(int volWindow) {    	

        this.volWindow = volWindow;
    }
    
    /**
     * Set the VaR limit
     */
    public void setVarLimit(double varLimit) {    	

        this.varLimit = varLimit;
        this.tsVarLimit.add(0, varLimit);
    }
    
    /**
     * Set the ES limit
     */
    public void setEsLimit(double esLimit) {    	

        this.esLimit = esLimit;
        //this.tsEsLimit.add(0, esLimit);
    }

    /**
     * Specify if the trader uses VaR
     */
    public void setUseVar(UseVar useVar) {    	

        this.useVar = useVar;
    }

    /**
     * Specify if the trader uses ES
     */
    public void setUseEs(UseEs useEs) {    	

        this.useEs = useEs;
    }

    /**
     * Specify if the trader uses stressed VaR
     */
    public void setUseStressedVar(UseStressedVar useStressedVar) {    	

        this.useStressedVar = useStressedVar;
    }
    
    /**
     * Specify if the trader uses stressed ES
     */
    public void setUseStressedEs(UseStressedEs useStressedEs) {    	

        this.useStressedEs = useStressedEs;
    }
    
    /**
     * Specify if the VaR limit is variable
     */
    public void setVariabilityVarLimit(VariabilityVarLimit variabilityVarLimit) {    	

        this.variabilityVarLimit = variabilityVarLimit;
    }
    
    /**
     * Get the VaR limit
     */
    public double getVarLimit() { 
    	return varLimit;
    }

    /**
     * Get the ES limit
     */
    public double getEsLimit() { 
    	return esLimit;
    }

    /**
     * Get the time series of variable VaR limit
     */
    public DoubleTimeSeries getTsVarLimit() { 
    	return tsVarLimit;
    }
    
    
    /**
     * Get the time series of VaR (calculated before any trade is done)
     */
    public DoubleTimeSeries getTsVarPreTrade() { 
    	return tsVar_preTrade;
    }

    /**
     * Get the time series of ES (calculated before any trade is done)
     */
    public DoubleTimeSeries getTsEsPreTrade() { 
    	return tsEs_preTrade;
    }

    /**
     * Get the time series of VaR (calculated after the trade is done)
     */
    public DoubleTimeSeries getTsVarPostTrade() { 
    	return tsVar_postTrade;
    }
    
    /**
     * Get the time series of ES (calculated after the trade is done)
     */
    public DoubleTimeSeries getTsEsPostTrade() { 
    	return tsEs_postTrade;
    }

    /**
     * Get the time series of stressed VaR (calculated after the trade is done)
     */
    public DoubleTimeSeries getTsStressedVarPostTrade() { 
    	return tsStressedVar_postTrade;
    }
    
    /**
     * Get the time series of stressed ES (calculated after the trade is done)
     */
    public DoubleTimeSeries getTsStressedEsPostTrade() { 
    	return tsStressedEs_postTrade;
    }
    
    /**
     * Get the time series of sell-off orders due to VaR
     */
    public HashMap<String, DoubleTimeSeries> getTsVarSelloff() { 
    	return tsVarSelloff;
    }
        
    /**
     * Get the time series of sell-off orders due to ES
     */
    public HashMap<String, DoubleTimeSeries> getTsEsSelloff() { 
    	return tsEsSelloff;
    }
    
    /**
     * Get all trading strategies for this trader
     */
    public HashMap<String, TradingStrategy> getStrategies() {
        return strategies;
    }

    @ScheduledMethod(start = 0, interval = 1, shuffle = false)
    public void actions() {
        placeOrders();
    }
    
	public void placeOrders() {
		
		int currentTick = (int) market.currentTick();
		ArrayList<String> secIds = market.getMarketMaker().getSecIds();
		
		if (useVar == UseVar.TRUE) {
			this.updateCovariances();     // Update the covariances with current prices to calculate the VaR
			this.updateMaxCovariances();  // Update the maximum covariances to calculate the stressed VaR
			tsVar_preTrade.add(currentTick, portfolio.preTradeValueAtRisk(market, market.getConfLevelVar()));  // Value at risk with current price, before any trade is done (-> using positions at t-1, prices at t)
		}
		
		if (useEs == UseEs.TRUE) {
			this.updateCovariances();     // Update the covariances with current prices to calculate the ES
			this.updateMaxCovariances();  // Update the maximum covariances to calculate the stressed ES
			tsEs_preTrade.add(currentTick, portfolio.preTradeShortfallParametricNormal(market, market.getConfLevelEs()));  // ES with current price, before any trade is done (-> using positions at t-1, prices at t)
		}

		ArrayList<Order> completeOrders = new ArrayList<Order>();  // Store the orders in all the assets

		// Calculate the desired positions (using the trading strategy)		
		for (TradingStrategy strategy : strategies.values()) {
			strategy.trade(this.getPortfolio());
			ArrayList<Order> orders = strategy.getOrders();					

			for (Order order : orders) {  // Add the orders in one asset or pair to the complete array of orders
				completeOrders.add(order);
			}
		}

		for (String secId : secIds) {   // Set a default (zero) value for the portfolio reductions, to avoid exceptions if no VaR-reduction is done 
    		portfolioVarReductions.getTsPosition(secId).add(currentTick, 0.0);
    		tsVarSelloff.get(secId).add(currentTick, 0.0);
    		tsVar_postTrade.add(currentTick, 0.0);
    		tsStressedVar_postTrade.add(currentTick, 0.0);

    		portfolioEsReductions.getTsPosition(secId).add(currentTick, 0.0);
    		tsEsSelloff.get(secId).add(currentTick, 0.0);
    		tsEs_postTrade.add(currentTick, 0.0);
    		tsStressedEs_postTrade.add(currentTick, 0.0);
		}

		
		if (useVar == UseVar.TRUE) {
			// Update the VaR limit

			int windowVolatilityIndexMA = 200;
			this.updateVarLimit(windowVolatilityIndexMA);

			// Calculate the total VaR (= normal VaR + stressed VaR)

			double postTradeVar = portfolio.valueAtRisk(market, market.getConfLevelVar());  // Value at risk of current portfolio (-> using positions at t, prices at t)
			
			double stressedVar = 0;			
			if (useStressedVar == UseStressedVar.TRUE)
				stressedVar = portfolio.stressedValueAtRisk(market, market.getConfLevelVar());  // Stressed VaR of current portfolio
			
			double totalVar = postTradeVar + stressedVar;
			tsVar_postTrade.add(currentTick, postTradeVar);
			tsStressedVar_postTrade.add(currentTick, stressedVar);
			
			// Check if VaR level [using the just-calculated positions] is below the limit
		
			if (totalVar > tsVarLimit.get(currentTick)) {
				ArrayList<Order> varReductionOrders = varRebalance(totalVar, tsVarLimit.get(currentTick));
				for (Order order : varReductionOrders) {
				
					// Calculate if the agent is forced to sell off due to VaR (used for plots)
					String shareId = order.getSecId();
					double var_reduction_order = order.getOrder();
					double desired_order;
				
					if (currentTick > 0)   // 'recover' the order desired according to the trading strategy 				
						desired_order = this.getPortfolio().getTsPosition(shareId).get(currentTick) - this.getPortfolio().getTsPosition(shareId).get(currentTick - 1);
					else
						desired_order = this.getPortfolio().getTsPosition(shareId).get(currentTick);

					if (Math.abs(var_reduction_order) > Math.abs(desired_order)) {  // The agent would like to buy (sell) and is forced to sell (buy) due to VaR
					    tsVarSelloff.get(shareId).add(currentTick, var_reduction_order + desired_order);
			    	}
				
					// Add the reduction orders to the complete array of orders
					completeOrders.add(order);					
					portfolio.addToPositions(order);   // Update positions in the trader's portfolio				
					portfolioVarReductions.addToPositions(order);
				}
			}
		}
		
		if (useEs == UseEs.TRUE) {

			// Calculate the total ES (= normal ES + stressed ES)

			double postTradeEs = portfolio.expectedShortfallParametricNormal(market, market.getConfLevelEs());
			
//			if (currentTick == 3000) {
//				System.out.println("agent " + this.label + "ES = " + portfolio.expectedShortfallParametricNormal(market, market.getConfLevelEs()) + " / stressed ES = " + portfolio.stressedExpectedShortfall(market, market.getConfLevelEs()) + "\n");
//			}
						
			double stressedEs = 0;
			if (useStressedEs == UseStressedEs.TRUE)
				stressedEs = portfolio.stressedExpectedShortfall(market, market.getConfLevelEs());  // Stressed ES of current portfolio
			
			//double totalEs = postTradeEs + stressedEs;  // This implementation copies Basel II.5 with stressed VaR
			double totalEs = stressedEs;
			if (postTradeEs != 0)
				totalEs = postTradeEs * Math.max(1, stressedEs/postTradeEs);  // This implementation follows the FRTB
			
			tsEs_postTrade.add(currentTick, postTradeEs);
			tsStressedEs_postTrade.add(currentTick, stressedEs);
			
			// Check if ES level [using the just-calculated positions] is below the limit
		
			if (totalEs > esLimit) {
				ArrayList<Order> esReductionOrders = esRebalance(totalEs, esLimit);
				for (Order order : esReductionOrders) {
				
					// Calculate if the agent is forced to sell off due to ES (used for plots)
					String shareId = order.getSecId();
					double es_reduction_order = order.getOrder();
					double desired_order;
				
					if (currentTick > 0)   // 'recover' the order desired according to the trading strategy 				
						desired_order = this.getPortfolio().getTsPosition(shareId).get(currentTick) - this.getPortfolio().getTsPosition(shareId).get(currentTick - 1);
					else
						desired_order = this.getPortfolio().getTsPosition(shareId).get(currentTick);

					if (Math.abs(es_reduction_order) > Math.abs(desired_order)) {  // The agent would like to buy (sell) and is forced to sell (buy) due to ES
					    tsEsSelloff.get(shareId).add(currentTick, es_reduction_order + desired_order);
			    	}
				
					// Add the reduction orders to the complete array of orders
					completeOrders.add(order);					
					portfolio.addToPositions(order);   // Update positions in the trader's portfolio				
					portfolioEsReductions.addToPositions(order);
				}
			}
		}
		
		
		// Send all orders to the market maker
		for (Order order : completeOrders) {
			if (Math.abs(order.getOrder()) > Double.MIN_VALUE) {    // only add an order if it is different from zero, to avoid clogging the market maker's order book with empty orders
				marketMaker.placeOrder(this, order.getSecId(), order.getOrder());
			} 
		}
		
		// Calculate the accumulated P&L
		if (currentTick >= 1) {
			deltaWealth_t = deltaWealth_t_1;
			
			for (String secId : secIds) {
	    		deltaWealth_t = deltaWealth_t + this.portfolio.getTsPosition(secId).get(currentTick - 1) * (market.getPrices(secId).get(currentTick) - market.getPrices(secId).get(currentTick - 1));
	    	}
			deltaWealth_t_1 = deltaWealth_t;
		}
		
		// Check if the agent has failed in the current tick
		// TODO: I leave a prudential warming period of 400 ticks, but this should be extracted
		// from the different windows used by the agents
		
    	double portfolioValue = 0;    	
    	for (String secId : secIds) {
    		portfolioValue = portfolioValue + Math.abs(this.portfolio.getTsPosition(secId).get(currentTick)) * market.getPrices(secId).get(currentTick);
    	}
		
//		if (deltaWealth_t < 0 && this.failureTick < 0  && currentTick >= 400) {
    	if (deltaWealth_t + portfolioValue < 0  &&  this.failureTick < 0  &&  currentTick >= 400) {
			this.state = State.DEAD;
			this.failureTick = currentTick;
		}
	    		
		logger.trace("t = {} | {}", market.currentTick(), this.toString());   // TODO information not meaningful
		
		//-------------
		
//		if (currentTick == 3999 && this.portfolio.getTsPosition("IBM").get(currentTick) >0) {
//			double aux = this.portfolio.getTsPosition("IBM").get(currentTick);
//			//double tradeES = portfolio.expectedShortfall(market);
//			//double tradeES = portfolio.expectedShortfall(market, 0.99, 200);
//			double tradeES = portfolio.expectedShortfallParametricTStudent(market, 0.99);
//			double tradeES_N = portfolio.expectedShortfallParametricNormal(market, 0.99);
//			//double tradeES = portfolio.expectedShortfallParametric(market, 0.99);
//			System.out.println("position: " + this.portfolio.getTsPosition("IBM").get(currentTick) + "  ES_t: " + tradeES + "  ES_N: " + tradeES_N + "\n");
//		}
	}

	
	/*
	 * Update the current covariances of the log-returns of all assets. 
	 */
	
	public void updateCovariances() {
		ArrayList<String> secIds = market.getMarketMaker().getSecIds();
		int currentTick = (int) market.currentTick(); 
		
		if (currentTick >= this.volWindow) {
			for (String secId_1 : secIds) {
				
				if (this.firstMACalculation.get(secId_1)) {
					this.maMeanReturns_current_tick.put(secId_1, StatsTimeSeries.fullMA(market.getLogReturns(secId_1), this.volWindow));
					
					for (String secId_2 : secIds) {
						this.maCovarianceReturns_current_tick.get(secId_1).put(secId_2, StatsTimeSeries.covariance(market.getLogReturns(secId_1), 
								market.getLogReturns(secId_2), this.volWindow));
					}
					this.firstMACalculation.put(secId_1, false);
				}
				else {
					this.maMeanReturns_current_tick.put(secId_1, StatsTimeSeries.incrementalMA(market.getLogReturns(secId_1), this.volWindow, 
							this.maMeanReturns_previous_tick.get(secId_1)));
					
					for (String secId_2 : secIds) {
						this.maCovarianceReturns_current_tick.get(secId_1).put(secId_2, StatsTimeSeries.incrementalCovariance(market.getLogReturns(secId_1), 
								market.getLogReturns(secId_2), this.volWindow, this.maCovarianceReturns_previous_tick.get(secId_1).get(secId_2), 
								this.maMeanReturns_previous_tick.get(secId_1), this.maMeanReturns_previous_tick.get(secId_2)));
					}
				}
			}
		}
		
		// Shift ma_t to ma_t_minus_1

		for (String secId_1 : secIds) {
			maMeanReturns_previous_tick.put(secId_1, maMeanReturns_current_tick.get(secId_1));

			for (String secId_2 : secIds) {
				maCovarianceReturns_previous_tick.get(secId_1).put(secId_2, maCovarianceReturns_current_tick.get(secId_1).get(secId_2));
			}
		}
	}
	

	/*
	 * Update the maximum covariances of all assets (covariances at the time step when the average 
	 * covariance was the highest since the start of the simulation) 
	 */
	
	public void updateMaxCovariances() {
		ArrayList<String> secIds = market.getMarketMaker().getSecIds();
		
		double avgMaxCovariance = 0; 
		double avgCurrentCovariance = 0;
		
		for (String secId : secIds) {  // Average of variances over all assets in the market
			avgMaxCovariance += maxCovariances.get(secId).get(secId);
			avgCurrentCovariance += maCovarianceReturns_current_tick.get(secId).get(secId);
		}
		
		if (avgCurrentCovariance > avgMaxCovariance) {  // current time step has the highest volatilities --> update maxCovariances
			for (String secId_1 : secIds) {				
				for (String secId_2 : secIds) {
	        		maxCovariances.get(secId_1).put(secId_2, maCovarianceReturns_current_tick.get(secId_1).get(secId_2));
				}
			}
		}
		
	}

	
	/*
	 * Update the VaR limit, based on the difference between current market volatility
	 * and its historical mean.
	 */

	public void updateVarLimit(int windowVolatilityIndexMA) {

		double volatilityIndex_t = 0;
		ArrayList<String> secIds = market.getMarketMaker().getSecIds();
		int currentTick = (int) market.currentTick();
				
		// Update the volatility index and its historical mean as an indicator of market instability
		for (String secId : secIds) {
			volatilityIndex_t += Math.sqrt(maCovarianceReturns_current_tick.get(secId).get(secId));
		}
		volatilityIndex_t = volatilityIndex_t / secIds.size();
		tsVolatilityIndex.add(currentTick, volatilityIndex_t);

		if (currentTick == windowVolatilityIndexMA) {
			volatilityIndex_MA_t = StatsTimeSeries.fullMA(tsVolatilityIndex, windowVolatilityIndexMA);
			volatilityIndex_MA_t_1 = volatilityIndex_MA_t;
		}
		else if (currentTick > windowVolatilityIndexMA) {
			volatilityIndex_MA_t = StatsTimeSeries.incrementalMA(tsVolatilityIndex, windowVolatilityIndexMA, volatilityIndex_MA_t_1);
			volatilityIndex_MA_t_1 = volatilityIndex_MA_t;
		}

		// Update the VaR limit
		if (variabilityVarLimit != VariabilityVarLimit.CONSTANT && currentTick > windowVolatilityIndexMA) {

			if (variabilityVarLimit == VariabilityVarLimit.PROCYCLICAL)
				tsVarLimit.add(currentTick, varLimit * volatilityIndex_MA_t/volatilityIndex_t);
			
			if (variabilityVarLimit == VariabilityVarLimit.COUNTERCYCLICAL)
				tsVarLimit.add(currentTick, varLimit * volatilityIndex_t/volatilityIndex_MA_t);
		}
		else  // VaR limit is constant, or currentTick <= window
			tsVarLimit.add(currentTick, varLimit); 
	}

	
	/*
	 * Returns the orders to be added to the portfolio to adjust the positions so
	 * that the VaR of the portfolio is equal to the limit. 
	 */
	public ArrayList<Order> varRebalance(double currentVar, double varLimit) {
		
		double reductionRatio = varLimit / currentVar;
		int currentTick = (int) market.currentTick();
		Set<String> secIds = market.getTradedShares().keySet();
		ArrayList<Order> orders = new ArrayList<Order>();
		
		for (String secId : secIds) {
			double pos_t = portfolio.getTsPosition(secId).get(currentTick);
			double pos_t_adjusted = reductionRatio * pos_t;
			
			Order order = new Order();
			order.setOrder(pos_t_adjusted - pos_t);
			order.setSecId(secId);
						
	        orders.add(order);
		}
		
		return orders;
	}
	

	/*
	 * Returns the orders to be added to the portfolio to adjust the positions so
	 * that the ES of the portfolio is equal to the limit. 
	 */
	public ArrayList<Order> esRebalance(double currentEs, double esLimit) {
		
		double reductionRatio = esLimit / currentEs;
		int currentTick = (int) market.currentTick();
		Set<String> secIds = market.getTradedShares().keySet();
		ArrayList<Order> orders = new ArrayList<Order>();
		
		for (String secId : secIds) {
			double pos_t = portfolio.getTsPosition(secId).get(currentTick);
			double pos_t_adjusted = reductionRatio * pos_t;
			
			Order order = new Order();
			order.setOrder(pos_t_adjusted - pos_t);
			order.setSecId(secId);
						
	        orders.add(order);	        
		}
		
		return orders;
	}

	public String getLabel() {
	    return label;
	}
	
	public UseVar getUseVar() {
	    return useVar;
	}
	
	public UseEs getUseEs() {
	    return useEs;
	}
	
	public TradingPortfolio getPortfolio() {
	    return portfolio;
	}
		
	public TradingPortfolio getPortfolioVarReductions() {
	    return portfolioVarReductions;
	}
	
	public TradingPortfolio getPortfolioEsReductions() {
	    return portfolioEsReductions;
	}
	
	public void setInitCovariances(double initValue) {
		Set<String> secIds = market.getTradedShares().keySet();
		
		for (String secId_1 : secIds) {
			maCovarianceReturns_current_tick.put(secId_1, new HashMap<String, Double>());
			maCovarianceReturns_previous_tick.put(secId_1, new HashMap<String, Double>());
			maxCovariances.put(secId_1, new HashMap<String, Double>());
			
			for (String secId_2 : secIds) {
        		maCovarianceReturns_current_tick.get(secId_1).put(secId_2, initValue);
        		maCovarianceReturns_previous_tick.get(secId_1).put(secId_2, initValue);
        		maxCovariances.get(secId_1).put(secId_2, initValue);
			}
		}
	}
	
	public double getCurrentCovariance(String secId_1, String secId_2) {
	    return maCovarianceReturns_current_tick.get(secId_1).get(secId_2);
	}
	
	public double getMaxCovariance(String secId_1, String secId_2) {
	    return maxCovariances.get(secId_1).get(secId_2);
	}
	
	public int getFailureTick() {
	    return failureTick;
	}

    public String toString() {
        return label;
    }
}
