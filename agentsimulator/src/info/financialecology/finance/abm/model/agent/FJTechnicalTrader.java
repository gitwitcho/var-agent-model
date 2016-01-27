/**
 * 
 */
package info.financialecology.finance.abm.model.agent;

import info.financialecology.finance.abm.model.FJMarket;
import info.financialecology.finance.abm.model.util.Order;
import info.financialecology.finance.abm.model.util.SimplePortfolio;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import repast.simphony.engine.schedule.ScheduledMethod;


/**
 * @author Gilbert Peffer
 *
 */
public class FJTechnicalTrader extends Agent {

    private static int numInst = -1;
	private int nID;

	private double             capitalFactor;
	private double             initCash;
	private double             initStock;
	private SimplePortfolio    portfolio;
	private Order              currentOrder;
	private FJMarket           market;
	private FJMarketMaker      marketMaker;
	
    private static final Logger logger = (Logger)LoggerFactory.getLogger(FJTechnicalTrader.class.getSimpleName());
		
	public FJTechnicalTrader() {
		super();
		setID();

		portfolio = new SimplePortfolio();    // Initialize portfolio with cash and stock
        logger.trace("CREATED: {}", this.toString());
	}
	
    /**
     * Set/reset static variables
     */
    public static void setAllStatics() {   
        FJTechnicalTrader.numInst = 0;
    }
	
    /**
     * @param market the market in which the technical trader operates
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
     * @param initCash the initial cash endowment for all technical traders  
     */
    public void setInitCash(double initCash) {
        portfolio.setCash(initCash);
    }

    /**
     * @param initStock the initial stock endowment for all technical traders  
     */
    public void setInitStock(double initStock) {
        portfolio.setStock(initStock);
    }

    @ScheduledMethod(start = 1, interval = 1, shuffle = false)
	public void placeOrder() {

		int currentTick = (int) market.getCurrentTick();
		double priceChange = marketMaker.getPriceSeries().getValue(currentTick) - marketMaker.getPriceSeries().getValue(currentTick - 1);
		
		logger.trace("t = {} | {}", currentTick, this.toString());
//		System.out.println("Agent_" + nID + ".placeOrder() called at TICK = " + schedule.getTickCount());
		
		if (priceChange > 0){
			Order order = new Order(Order.AssetType.STOCK,Order.BuySell.BUY, Math.round(capitalFactor * (priceChange)));
			marketMaker.placeOrder(this, order);
			currentOrder = order;
		}
		else {
			Order order = new Order(Order.AssetType.STOCK,Order.BuySell.SELL, Math.round(capitalFactor * (priceChange)));
			marketMaker.placeOrder(this, order);
			currentOrder = order;
		}
		
		logger.trace("t = {} | Order = {}", currentTick, currentOrder.getAmount());
		logger.trace("t = {} | Price change = {}", currentTick, priceChange);
	}
	
	public void orderFilled(){
		if (currentOrder.getBuySell() == Order.BuySell.BUY)
			portfolio.add(currentOrder.getAmount());
		else
			portfolio.remove(currentOrder.getAmount());
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
	
	/**
	 * @param numInst the numInst to set
	 */
	public static void resetNumInst() {
		FJTechnicalTrader.numInst = 0;
	}
	
//	public static void resetSchedule() {
//		FJTechnicalTrader.schedule = RunEnvironment.getInstance().getCurrentSchedule();
//	}
	
    public String toString() {
        return "TechnicalTrader_" + nID;
    }

}
