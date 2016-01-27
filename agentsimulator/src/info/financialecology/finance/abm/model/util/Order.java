/**
 * 
 */
package info.financialecology.finance.abm.model.util;

/**
 * @author Gilbert Peffer
 *
 */
public class Order {
	private AssetType assetType;
	private BuySell buySell;
	private double amount;
	
	public enum BuySell {BUY, SELL};
	public enum AssetType {CASH, STOCK}
	
	/**
	 * @param assetType
	 * @param buySell
	 * @param amount
	 */
	public Order(AssetType asset_type, BuySell buy_sell, double amount) {
		super();
		this.assetType = asset_type;
		this.buySell = buy_sell;
		this.amount = amount;
	}
	
	/**
	 * @return the asset_type
	 */
	public AssetType getAssetType() {
		return assetType;
	}
	
	/**
	 * @param asset_type the asset_type to set
	 */
	public void setAsset_type(AssetType asset_type) {
		this.assetType = asset_type;
	}
	
	/**
	 * @return the buy_sell
	 */
	public BuySell getBuySell() {
		return buySell;
	}
	
	/**
	 * @param buy_sell the buy_sell to set
	 */
	public void setBuySell(BuySell buy_sell) {
		this.buySell = buy_sell;
	}

	/**
	 * @return the amount
	 */
	public double getAmount() {
		return amount;
	}

	/**
	 * @param amount the amount to set
	 */
	public void setAmount(double amount) {
		this.amount = amount;
	};
	
}
