package info.financialecology.finance.abm.model.agent;

import info.financialecology.finance.abm.model.FJMarket;
import info.financialecology.finance.abm.model.util.Order;
import info.financialecology.finance.utilities.datastruct.Datastore;
import info.financialecology.finance.utilities.datastruct.DoubleTimeSeries;
import info.financialecology.finance.utilities.datastruct.ResultEnum;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.Iterator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


import repast.simphony.engine.schedule.ScheduleParameters;
import repast.simphony.engine.schedule.ScheduledMethod;

/**
 * 
 */

/**
 * @author Gilbert Peffer
 *
 */
public class FJMarketMaker extends Agent {

    private static int numInst = -1;
	private int nID;			// standard ID, incremental numbering of instances
	
	private double initPrice;      // Initial price
	private FJMarket market;       // market in which the market maker operates

    private DoubleTimeSeries priceSeries;
//    private DoubleTimeSeries tsPrices;              // times series of prices
	private ArrayList<OrderBookEntry> orderBook;
	
    private static final Logger logger = (Logger)LoggerFactory.getLogger(FJMarketMaker.class.getSimpleName());
    
    public enum Results implements ResultEnum {
        PRICES (DoubleTimeSeries.class);

        private final Type mType;

        Results(Type type) {
            this.mType = type;
        }

        public Type type() { return mType; }
    }

	public FJMarketMaker() {
		setID();
        Datastore.logAllResults(Results.class);     // Initialize the data store to hold the results defined by enum Results
        
        // TODO Unclear whether we want to store the prices in the Datastore or use the local object priceSeries 
//        tsPrices = Datastore.getResult(DoubleTimeSeries.class, Results.PRICES);
        
		priceSeries = new DoubleTimeSeries();
		orderBook = new ArrayList<OrderBookEntry>();
		
		logger.trace("CREATED: {}", this.toString());
	}
	
    /**
     * Set/reset static variables
     */
    public static void setAllStatics() {   
        FJMarketMaker.numInst = 0;
    }
    
    /**
     * @param market the market in which the market maker operates
     */
    public void setMarket(FJMarket market) {
        this.market = market;
    }

    /**
     * @param initPrice the initPrice to set
     */
    public void setInitPrice(double initPrice) {
        this.initPrice = initPrice;
    }

    // Clear the market based on the orders from the traders
	@ScheduledMethod(start=0,interval=1, priority = ScheduleParameters.FIRST_PRIORITY)
	public void clearMarket() {
		double totalOrders = 0;
		int currentTick = (int) market.getCurrentTick();
		
		logger.trace("t = {} | {}", currentTick, this.toString());

		Iterator<OrderBookEntry> itrEntries = orderBook.iterator();
		
		// Determine total stock orders from order book
		while (itrEntries.hasNext()){
			Order order = itrEntries.next().order;
			
			if (order.getBuySell() == Order.BuySell.BUY)
				totalOrders += order.getAmount();
			else
				totalOrders -= order.getAmount();
		}
		
		// Notify traders that all orders have been fulfilled at the current price 
		itrEntries = orderBook.iterator();
		
		while (itrEntries.hasNext()){
			Agent agent = itrEntries.next().getTrader();
		}
		
		// Calculate new price
		if (currentTick == 0) {
			priceSeries.add(currentTick, initPrice + totalOrders / market.getLiquidity());
//			tsPrices.add(currentTick, initPrice + totalOrders / market.getLiquidity());
		}
		else {
			priceSeries.add(currentTick, priceSeries.getValue(currentTick - 1) + totalOrders / market.getLiquidity());
//			tsPrices.add(currentTick, priceSeries.getValue(currentTick - 1) + totalOrders / market.getLiquidity());
		}
		
		logger.trace("t = {} | Price = {}", market.getCurrentTick(), priceSeries.getValue(currentTick));
//		logger.trace("t = {} | TS Price = {}", market.getCurrentTick(), tsPrices.getValue(currentTick));
		
		// Clear order book entries
		orderBook.clear();
	}
	
	// Provide the current market price
	public double getCurrentPrice() {
		return priceSeries.getValue((int) market.getCurrentTick());
	}
	
	// Get price timeseries from market
	public DoubleTimeSeries getPriceSeries(){
		return priceSeries;
	}
	
	private class OrderBookEntry {
		private Agent agent;
		private Order order;
				
		/**
		 * @param agent
		 * @param order
		 */
		public OrderBookEntry(Agent agent, Order order) {
			super();
			this.agent = agent;
			this.order = order;
		}
		
		/**
		 * @return the fundTrader
		 */
		public Agent getTrader() {
			return agent;
		}
		/**
		 * @return the order
		 */
		public Order getOrder() {
			return order;
		}
	}
	
	// Service for traders to post their orders
	public void placeOrder(Agent agent, Order order){
		OrderBookEntry entry = new OrderBookEntry(agent, order);
		orderBook.add(entry);
	}
	
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
		FJMarketMaker.numInst = 0;
	}
	
    public String toString() {
        return "MarketMaker_" + nID;
    }
}
