/**
 * 
 */
package info.financialecology.finance.abm.model.agent;

import info.financialecology.finance.abm.model.FJMarket;
import info.financialecology.finance.abm.model.util.Order;
import info.financialecology.finance.abm.model.util.SimplePortfolio;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


import cern.jet.random.*;
import repast.simphony.engine.schedule.ScheduleParameters;
import repast.simphony.engine.schedule.ScheduledMethod;

/**
 * @author Gilbert Peffer
 *
 */
public class FJFundamentalTrader extends Agent {

    private static int numInst = -1;	
	private static int currentTick = -1;   // force update for the first call of updateBaseValue()
    // TODO move to simulator, although it seems specific to fundamental traders?
	private static double valueRef_t;      // reference value at the current time step - has to be set once at start of tick
	private static Normal distRefValue;     // reference process for stock value
//	private static Uniform distOffsetValue;    // fixed offset added to the value reference process - different for each trader 
//	private static Normal distDeltaValue;   // change in value between t and t+1

    private int nID;
    private FJMarket market;       // market in which the fundamental trader operates
    private FJMarketMaker marketMaker;
	private double value_t;
	private double offsetValue;
	private double capitalFactor;
	private SimplePortfolio portfolio;
	private Order currentOrder;
		
    private static final Logger logger = (Logger)LoggerFactory.getLogger(FJFundamentalTrader.class.getSimpleName());

	public FJFundamentalTrader() {
		super();
		setID();

//		valueOffset = distOffsetValue.nextDouble();	// trader-specific random offset - set once
//		value_t = valueRef_t + valueOffset;		    // Initial value of stock (different for each trader)
		
//		capitalFactor = 0.3;						// Homogeneous capital factor
		portfolio = new SimplePortfolio();        	// Initialise portfolio with cash and stock

        logger.trace("CREATED: {}", this.toString());
        logger.trace("Value_0 = {}", value_t);
}
	
    /**
     * Set/reset static variables
     */
    public static void setAllStatics() {
        
        FJFundamentalTrader.numInst = 0;
        FJFundamentalTrader.currentTick = -1;
//        FJFundamentalTrader.distRefValue = RandomHelper.createNormal(0, 0.35);
//        FJFundamentalTrader.distOffsetValue = RandomHelper.createUniform(-2, 2);
//        FJFundamentalTrader.distDeltaValue = RandomHelper.createNormal(0,0.35);
    }
    
    // TODO Add a state validation check, since the instance depends on too many values being set externally. Eventually replace with builder pattern
    
    /**
     * @param market the market in which the fundamental trader operates
     */
    public void setMarket(FJMarket market) {
        this.market = market;
        marketMaker = market.getMarketMaker();
    }

    /**
     * @param capitalFactor the capitalFactor to set
     */
    public void setCapitalFactor(double capitalFactor) {
        this.capitalFactor = capitalFactor;
    }

    /**
     * @param offsetValue the offsetValue to set
     */
    public void setOffsetValue(double offsetValue) {
        this.offsetValue = offsetValue;
    }

    /**
     * @param initCash the initial cash endowment for all fundamental traders  
     */
    public void setInitCash(double initCash) {
        portfolio.setCash(initCash);
    }

    /**
     * @param initStock the initial stock endowment for all fundamental traders  
     */
    public void setInitStock(double initStock) {
        portfolio.setStock(initStock);
    }
    
    /**
     * @param distRefValue the normal distribution function to generate reference values for log value of stock
     */
    public static void setDistributionRefValue(Normal distRefValue) {
        FJFundamentalTrader.distRefValue = distRefValue;
    }

//    /**
//     * @param distOffsetValue the distribution function to generate trader-specific offset to reference process for stock value
//     */
//    public static void setDistributionOffsetValue(Uniform distOffsetValue) {
//        FJFundamentalTrader.distOffsetValue = distOffsetValue;
//    }

//    /**
//     * @param distDeltaValue the distribution function to generate initial values for stock
//     */
//    public static void setDistributionDeltaValue(Normal distDeltaValue) {
//        FJFundamentalTrader.distDeltaValue = distDeltaValue;
//    }

    @ScheduledMethod(start = 0, interval = 1, shuffle = false)
	public void placeOrder() {
		
		double price = marketMaker.getCurrentPrice();
		
		logger.trace("t = {} | {}", market.getCurrentTick(), this.toString());
		
		if (price < value_t){
			Order order = new Order(Order.AssetType.STOCK,Order.BuySell.BUY, Math.round(capitalFactor * (value_t - price)));
			marketMaker.placeOrder(this, order);
			currentOrder = order;
		}
		else {
			Order order = new Order(Order.AssetType.STOCK,Order.BuySell.SELL, Math.round(capitalFactor * (price - value_t)));
			marketMaker.placeOrder(this, order);
			currentOrder = order;
		}
		
		logger.trace("t = {} | Order = {}", market.getCurrentTick(), currentOrder.getAmount());
		logger.trace("t = {} | Value = {}", market.getCurrentTick(), value_t);
	}
	
	public void orderFilled(){
		if (currentOrder.getBuySell() == Order.BuySell.BUY)
			portfolio.add(currentOrder.getAmount());
		else
			portfolio.remove(currentOrder.getAmount());
	}
	
	// Update base value (the same for all fund traders) at the start of the tick
	@ScheduledMethod(start = 1, interval = 1, priority = ScheduleParameters.FIRST_PRIORITY)
	public void updateBaseValue(){
		if (currentTick != market.getCurrentTick())     // TODO maybe move this one level up to the simulator?
			valueRef_t += distRefValue.nextDouble();    // reference log-value is that same for all traders, so update only once
		
//		CLog.fine("t=" + schedule.getTickCount() + " | PREVIOUS value = " + value_t);
//		double deltaValue = rndDeltaValue.nextDouble();
//		value_t += 10 * deltaValue;
		value_t = valueRef_t + offsetValue;  // compute current value from reference value and trader-specific offset
		
//		logger.trace("t = {} | Base value {}", market.getCurrentTick(), value_base);
		logger.trace("t = {} | Updated stock value to {} for {}", new Object[] {market.getCurrentTick(), value_t, this.toString()});
		
		currentTick = (int) market.getCurrentTick();
	}
	
	// Add idiosyncratic 
	
//	private void initialiseLogging() {
//		// Initialise the logging for debug messages
//		if (logInit) return;
//		DebugFormatter formatter = new DebugFormatter();
//		ConsoleHandler debugHandler = new ConsoleHandler();
//		debugHandler.setFormatter(formatter);
//		CLog.addHandler(debugHandler);
//		
//		Handler [] handlers = CLog.getHandlers();
//	    for ( int index = 0; index < handlers.length; index++ ) {
//	        handlers[index].setLevel( Level.FINE );
//	      }
//
//		CLog.setLevel(Level.FINE);
//		logInit = true;
//	}
	
    // Generate numeric ID from number of instances created
	private void setID() {
        if (numInst == -1)
            throw new IllegalStateException("make sure you call setAllStatics() before creating an instance of this class");

        numInst++;
		nID = numInst;		
	}
	
//	public static void resetNumInst() {
//		FJFundamentalTrader.numInst = 0;
//	}
//	
//	public static void resetValueBase(){
//		FJFundamentalTrader.value_base = 0;
//	}
	
    public String toString() {
        return "FundamentalTrader_" + nID;
    }
}
