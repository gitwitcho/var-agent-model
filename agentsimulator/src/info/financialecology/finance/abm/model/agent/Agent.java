/**
 * 
 */
package info.financialecology.finance.abm.model.agent;


/**
 * @author Gilbert
 *
 */
public class Agent {

    private int nId;    // TODO not sure this is needed at this level of abstraction; should be overwritten by inheriting classes
    
	public Agent() { nId = 0; };
	
	public void orderFilled() {
		// TODO Auto-generated method stub
	}
    
    /**
     * @param nId the nId to set
     */
    public void setnId(int nId) {
        this.nId = nId;
    }

    /**
     * @return the nId
     */
    public int getnId() {
        return nId;
    }

    @Override
    public String toString() {
        return "Ag" + nId;
    }


}
