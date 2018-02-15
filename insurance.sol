pragma solidity ^0.4.19;

contract InsurancePolicy {

/* Contract to:
Allow a customer to purchase an insurance policy from an insurance company.  
Contract will hold the insurance policy details like limit, premium.

Allow a customer to authorize access to a specific field of information on their policy (i.e. if a person has home 
insurance, they want to be able to let their bank see the limit they hold as  requirement for getting a mortgage 
or they want to be able to let their accountant see the amount of premium they paid for the policy for the purposes 
of preparing their tax return)

Allow a third party to access only field of information they are allowed to access (i.e. the bank would be able to 
get the limit but not the premium

For this demo, we make a simplifying assumption that each third party can only access up to 1 field on the policy

	How to run in Remix
		
			1) Purchase a policy
			
			Create the contract
			Run the purchasePolicy function with 123, 1000 as arguments (i.e. policy number = 123, limit = 1000) and pass in some WEI to be stored as the premium
			
			2) Grant access to a third party
			
			Run the grantAccessToLimit and pass in the policy number (i.e. 123) account address of the third party (in double quotes) - for testing purposes we can just use the current account's address
			
			3) Access the information
			
			Run the accessPolicyPremium and pass in the policy number (i.e. 123)
			
			Note for this demo we are assuming 1 address will be granted access to exactly 1 of the policy attributes (i.e. either policy limit OR policy premium)
			
	*/
	enum PolicyAttribute {POLICYLIMIT, POLICYPREMIUM}			// Holds the attribute in the insurance policy that can be granted access	
	uint public totalPolicies;									// Counter to keep track of total policies in the contract
	
	struct Policy {
		bool hasPolicy;											// Boolean to store the fact a policy exists
		address policyHolder;									// The purchaser of the insurance - saving the msg.sender
        uint policyLimit;										// The coverage limit of the insurance policy
		uint policyPremium;										// The premium paid (in WEI) for the insurance policy
		mapping(address => PolicyAttribute) policyAccess;		// For each address (third party), hold the field of data in the Policy they can access - for this demo we assume for 1 address, they can only have access to 1 of the policy attributes
	}
	
	mapping(uint => Policy) public policies;					// For each policy number, hold the struct that contains the details on their insurance policy
	
	event NoAccessToPolicyPremium (address caller);				// Event raised when the caller has no access to policy premium
	event NoAccessToPolicyLimit (address caller);				// Event raised when the caller has no access to policy limit

   
	/*	@dev Allows a person to purchase an insurance policy
		@param _policyLimit - The limit of insurance of the policy
		@param _policyPremium - The cost of the insurance policy
		@return returns true if successful
	*/
	function purchasePolicy(uint policyNumber, uint _policyLimit) payable public returns (bool) {
		require(_policyLimit > 0 && msg.value > 0);
		
		// Create the representation of the policy for the purchaser (sender) and store the limit/premium
		policies[policyNumber].hasPolicy = true;
		policies[policyNumber].policyHolder = msg.sender;
		policies[policyNumber].policyLimit = _policyLimit;
		policies[policyNumber].policyPremium = msg.value;
		
		// Increment totalPolicies
		totalPolicies += 1;
		return true;
	}

	/*	@dev Allows the purchaser to authorize an address to view the limit of the policy
		@param thirdPartyAddress - The address of the third party that are granting access to
		@return returns true if successful
	*/
	function grantAccessToLimit(uint policyNumber,address thirdPartyAddress) payable public returns (bool) {
		require(thirdPartyAddress != address(0x0));

		// Check the policy holder has a policy
		require(policies[policyNumber].hasPolicy == true);
		
		policies[policyNumber].policyAccess[thirdPartyAddress] = PolicyAttribute.POLICYLIMIT;
		
		return true;
	}	

	/*	@dev Allows the purchaser to authorize an address to view the premium of the policy
		@param thirdPartyAddress - The address of the third party that are granting access to
		@return returns true if successful
	*/
	function grantAccessToPremium(uint policyNumber, address thirdPartyAddress) payable public returns (bool) {
		require(thirdPartyAddress != address(0x0));

		// Check the policy holder has a policy
		require(policies[policyNumber].hasPolicy == true);
		
		policies[policyNumber].policyAccess[thirdPartyAddress] = PolicyAttribute.POLICYPREMIUM;
		
		return true;
	}	

	/*	@dev Allows the third party to view the limit of the policy
		@param policyHolder - The address of the policyHolder who's limit is being accessed
		@return accessedLimit - The limit
	*/
	function accessPolicyLimit(uint policyNumber) payable public returns (uint accessedLimit) {
		
		// Check the policy holder has a policy
		require(policies[policyNumber].hasPolicy == true);
		
		// Check the person requesting the information is allowed to access the limit
		if(policies[policyNumber].policyAccess[msg.sender] == PolicyAttribute.POLICYLIMIT) {
			return (policies[policyNumber].policyLimit);

		} else {
			// Raise event for the error condition
			NoAccessToPolicyLimit(msg.sender);

			//consume gas 
			throw;
		}
	}	

	/*	@dev Allows the third party to view the premiuim of the policy
		@param policyHolder - The address of the policyHolder who's premium is being accessed
		@return accessedPremium - The premium in WEI
	*/
	function accessPolicyPremium(uint policyNumber) payable public returns (uint accessedPremium) {
		// Check the policy holder has a policy
		require(policies[policyNumber].hasPolicy == true);
		
		// Check the person requesting the information is allowed to access the limit
		if(policies[policyNumber].policyAccess[msg.sender] == PolicyAttribute.POLICYPREMIUM) {
			return (policies[policyNumber].policyPremium);

		} else {
			// Raise event for the error condition
			NoAccessToPolicyPremium(msg.sender);

			//consume gas 
			throw;
		}
	}		

	/*	@dev Returns the number of policies purchased
		@return totalPolicies - The number of policies
	*/    
    function getPolicyCount () public constant returns (uint){
        return totalPolicies;
    }
}