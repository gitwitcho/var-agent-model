/**
 * 
 */
package info.financialecology.finance.abm.model.util;

/**
 * @author Gilbert Peffer
 *
 */
public class SimplePortfolio {
	private double stock;
	private double cash;
	
	public SimplePortfolio() {
	    super();
	}
	
	/**
	 * @param stock
	 * @param cash
	 */
	public SimplePortfolio(double stock, double cash) {
		super();
		this.stock = stock;
		this.cash = cash;
	}
	/**
	 * @return the stock
	 */
	public double getStock() {
		return stock;
	}
	/**
	 * @param stock the stock to set
	 */
	public void setStock(double stock) {
		this.stock = stock;
	}
	/**
	 * @return the cash
	 */
	public double getCash() {
		return cash;
	}
	/**
	 * @param cash the cash to set
	 */
	public void setCash(double cash) {
		this.cash = cash;
	}
	
	// Add stock to the portfolio
	public void add(double amount){
		stock += amount;
	}
	
	// Remove stock from the portfolio
	public void remove(double amount){
		stock -= amount;
	}
	
}
