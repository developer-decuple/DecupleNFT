// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

/**
 * @title Bonus Contract
 * @author Lenzolab Development team - matthewshelb@gmail.com
 * @notice This contract manages referral bonuses for the Decuple NFT project.
 * @dev It interacts with the Decuple NFT contract and an ERC20 token (DCO) for bonus payments.
 */
contract Bonus { 

    /**
    * @dev Flag indicating whether the contract is paused.
    * When paused, referral bonus payments cannot be processed.
    */
    bool private _paused;


    /**
    * @dev Address of the contract owner.
    * The owner has special privileges to manage the contract, 
    * including setting the agent, DCO token address, pausing/unpausing the contract,
    * and sending DCO tokens directly to an address.
    */
    address private immutable _owner;


    /**
    * @dev Address of the agent authorized to call the `payBonus` function.
    * This role is typically assigned to the agent contract to trigger referral bonuses
    * upon successful NFT mints.
    */
    address public _agent;


    /**
    * @dev Address of the ERC20 token (DCO) used for referral bonus payments.
    */
    address public _dco;
    ERC20 DCO;


    /**
    * @dev Internal counter tracking the total number of referral entries recorded.
    * This is used as a unique identifier for each minted NFT with a referral bonus.
    */
    uint256 private refIndex = 0; 


    /**
    * @dev Mapping to store detailed information for each minted NFT with a referral bonus.
    * The key is the unique `refIndex` generated for each entry.
    * The value is a `minted` struct containing details like NFT ID, price, minter address,
    * referrer address, and timestamp.
    */
    mapping (uint256 => minted ) public referrals;


    /**
    * @dev Mapping to track the number of referrals for each user address.
    */
    mapping (address => uint256 ) public referralCount;


    /**
    * @dev Mapping to store an array of `refIndex` values for each user address.
    * This allows efficient retrieval of all minted NFTs with a referral bonus
    * associated with a specific user (referrer).
    */
    mapping (address => uint256[] ) public referralIndexes;


    /**
    * @dev Mapping to track whether a user has already claimed the speed bonus.
    * The key is the user address, and the value is a timestamp indicating when the claim was made
    * (initialized to 0 if not claimed).
    */
    mapping (address => uint256 ) public claimed;


    /**
    * @dev Array containing the base referral bonus amounts for the referrer in DCO Wei.
    * The index corresponds to the number of NFTs minted in a single transaction (1, 3, or 5).
    */
    uint256[] referrerBonus = [100000000000000000000,400000000000000000000,700000000000000000000];


    /**
    * @dev Array containing the base referral bonus amounts for the minter in DCO Wei.
    * The index corresponds to the number of NFTs minted in a single transaction (1, 3, or 5).
    */
    uint256[] refereeBonus = [50000000000000000000,200000000000000000000,350000000000000000000];


    /**
    * @dev Array containing additional referral bonus amounts for the referrer in Wei.
    * These bonuses are awarded under specific conditions:
    *  - `referrerExtraBonus[0]`: Speed bonus - Awarded to the referrer once they reach 10 total referrals.
    *  - `referrerExtraBonus[1]`: Additional bonus awarded every 5 referrals after the speed bonus is triggered.
    */
    uint256[] referrerExtraBonus =  [1000000000000000000000, 500000000000000000000]; //0: Speed bonus - 1: for every 5 referrals after the speed



    constructor(){
        _owner = msg.sender;
        _paused = false;
        _agent = 0x8Fc319929e4A1EBE7A58b5f86ADDd958026A493a; 
        setDCO(0xA7A1CEe5aa198838A111C7b0930617FA617C78d9);
    }
 

    /**
    * @dev Struct to represent data passed during bonus payment processing.
    * @param ids: Array of NFT IDs minted in a single transaction.
    * @param price: Total price paid for the minted NFTs.
    * @param minter: Address of the user who minted the NFTs.
    * @param referrer: Address of the user who referred the minter.
    * @param timestamp: Timestamp of the transaction.
    */
    struct refData {
        uint256[] ids;
        uint256 price;
        address minter;
        address referrer;
        uint256 timestamp;
    }


    /**
    * @dev Struct to store information about a minted NFT with a referral bonus.
    * @param id: ID of the minted NFT.
    * @param index: Unique `refIndex` for this entry.
    * @param price: Price paid for the minted NFT.
    * @param minter: Address of the user who minted the NFT.
    * @param referrer: Address of the user who referred the minter (if applicable).
    * @param timestamp: Timestamp of the transaction.
    */
    struct minted {
        uint256 id;
        uint256 index;
        uint256 price;
        address minter;
        address referrer;
        uint256 timestamp;
    }


    /**
    * @dev Internal function to record referral data for minted NFTs with a bonus.
    * This function is called by `payBonus` after successful payment processing.
    * It iterates through the provided `ids` array and creates a `minted` struct entry
    * for each NFT, storing details like ID, price, minter, referrer, and timestamp.
    * The entries are stored in the `referrals` mapping using the unique `refIndex` as the key.
    * It also updates the `referralCount` and `referralIndexes` mappings for the referrer.
    * @param data: Reference to the `refData` struct containing referral information.
    */
    function recordData(refData memory data) private {
        for (uint256 j=0; j < data.ids.length; j++) 
        {
            minted memory newMint = minted(data.ids[j], refIndex, data.price, data.minter, data.referrer, data.timestamp);
            referrals[refIndex] = newMint;
            referralCount[data.referrer]++;
            referralIndexes[data.referrer].push(refIndex);
            refIndex++;
            if(referralCount[data.referrer] > 14){
                if(referralCount[data.referrer] % 5 ==0){
                    DCO.transfer(data.referrer, referrerExtraBonus[1]);
                }
            }
        }
    }
     

    /**
    * @dev Public function to process referral bonus payments for minted NFTs.
    * This function can only be called by the authorized agent (typically the Decuple NFT contract).
    * It takes a `refData` struct as input containing details about the minted NFTs.
    * Based on the number of NFTs minted in a single transaction (obtained from the `ids` array length),
    * it distributes the corresponding referral bonuses to the referrer and minter using the `DCO.transfer` function.
    * It also calls the `recordData` function to store referral information for each minted NFT.
    * Finally, it emits a `referralBonus` event with details about the transaction.
    * @param data: Reference to the `refData` struct containing referral information.
    * @return true if the bonus payment was successful.
    */
    function payBonus(refData memory data) public onlyAgent returns (bool) {
        
        if(data.ids.length == 1){
            DCO.transfer(data.referrer, referrerBonus[0]);
            DCO.transfer(data.minter, refereeBonus[0]);
        }
        if(data.ids.length == 3){
            DCO.transfer(data.referrer, referrerBonus[1]);
            DCO.transfer(data.minter, refereeBonus[1]);
        }        
        if(data.ids.length == 5){
            DCO.transfer(data.referrer, referrerBonus[2]);
            DCO.transfer(data.minter, refereeBonus[2]);
        }
        recordData(data);
        emit referralBonus(data.minter ,data.referrer, data.ids.length, data.ids );
        return true;
    }


    /**
    * @dev Public function for a user to claim the speed bonus (if applicable).
    * A user can only claim the speed bonus once (`claimed[msg.sender] == 0`).
    * They must also have at least 10 referrals (`referralCount[msg.sender] >= 10`) to be eligible.
    * This function transfers the speed bonus amount (`referrerExtraBonus[0]`) from the DCO token to the user using `DCO.transfer`.
    * It also updates the `claimed` mapping for the user with the current block timestamp.
    * @return true if the claim was successful.
    */
    function claim() public returns(bool){
        require(claimed[msg.sender] == 0, "You have already claimed.");
        require(referralCount[msg.sender] >= 10, "Not enough referrals.");
        DCO.transfer(msg.sender, referrerExtraBonus[0]);
        claimed[msg.sender] = block.timestamp;
        return true;
    }


    /**
    * @dev View function to retrieve a report of all recorded referral entries.
    * It iterates through the `refIndex` counter and creates an array of `minted` structs,
    * copying data from the `referrals` mapping.
    * The resulting array is returned, providing a comprehensive report of all referral activities.
    * @return minted[]: An array of `minted` structs containing information about all recorded referral entries.
    */
    function getReferralReport() public view returns ( minted[] memory){
        minted[] memory result = new minted[](refIndex);
        for (uint256 i=0; i<refIndex; i++) 
        {
            result[i] = referrals[i];
        }
        return result;
    }


    /**
    * @dev View function to retrieve referral entries for a specific user address.
    * This function takes an address as input and iterates through the `referrals` mapping.
    * It checks if the referrer address for each entry matches the provided address.
    * If a match is found, the corresponding `minted` struct information is added to a new array.
    * This array is then returned, providing details about all NFTs minted with a referral bonus
    * where the specified address acted as the referrer.
    * @param adr: Address of the user for whom to retrieve referral entries.
    * @return minted[]: An array of `minted` structs containing information about the user's referral entries.
    */
    function getReferralsFor(address adr) public view returns( minted[] memory){
        minted[] memory result = new minted[](referralCount[adr]);
        uint256 num = 0;
        for (uint256 i=0; i<refIndex; i++) 
        {
            if(referrals[i].referrer == adr){
                result[num] = (referrals[i]);
                num++;
            }
        }
        return result;
    }


    /**
    * @dev View function to retrieve the array of `refIndex` values associated with a user address.
    * This function takes an address as input and returns the corresponding array stored in the `referralIndexes` mapping.
    * This array provides a list of unique identifiers (`refIndex`) for all NFTs minted with a referral bonus
    * where the specified address acted as the referrer.
    * @param adr: Address of the user for whom to retrieve `refIndex` values.
    * @return uint256[]: An array of `refIndex` values for the user's referral entries.
    */
    function getReferralIndexesFor(address adr) public view returns( uint256[] memory){
        return referralIndexes[adr];
    }


    /**
    * @dev Function to set the address of the ERC20 token (DCO) used for bonus payments.
    * This function can only be called by the contract owner.
    * It updates the `DCO` instance variable with the provided address.
    * It also updates the `_dco` state variable to store the address permanently.
    * @param adr: Address of the ERC20 token (DCO) contract.
    * @return true if the DCO address was successfully set.
    */
    function setDCO(address adr) public onlyOwner returns(bool){
        DCO = ERC20(adr);
        _dco = adr;
        return true;
    }


    /**
    * @dev Function to send DCO tokens directly to an address.
    * This function can only be called by the contract owner.
    * It uses the `DCO.transfer` function to transfer the specified amount of DCO tokens to the provided address.
    * This function is primarily for manual distribution or emergency purposes.
    * @param to: Address to which the DCO tokens should be sent.
    * @param amount: Amount of DCO tokens to transfer (in Wei).
    * @return true if the DCO transfer was successful.
    */
    function sendDCO(address to, uint256 amount) public onlyOwner returns(bool){
        return DCO.transfer(to, amount);
    }


    /**
    * @dev Function to set the authorized agent address.
    * This function can only be called by the contract owner (`onlyOwner` modifier).
    * It updates the internal `_agent` state variable with the provided `newAgent` address.
    * The authorized agent is typically another contract 
    * that has permission to trigger referral bonus payments using the `payBonus` function.
    * @param newAgent: The address of the new authorized agent.
    */
    function setAgent(address newAgent) public onlyOwner{
        _agent = newAgent;
    }

    
    /**
    * @dev Pauses the contract, preventing any minting actions. Only the owner can call this function.
    *
    */
    function pause() public onlyOwner{
        _paused = true;
    }


    /**
    * @dev Unpauses the contract, preventing any minting actions. Only the owner can call this function.
    *
    */
    function unpause()  public onlyOwner{
        _paused = false;
    }


    /**
    * @dev Event emitted whenever a referral bonus payment is processed.
    * This event logs details about the transaction, including:
    *  - minter: Address of the user who minted the NFTs.
    *  - referrer: Address of the user who referred the minter (if applicable).
    *  - count: Number of NFTs minted in the transaction (1, 3, or 5).
    *  - id: Array of NFT IDs minted in the transaction.
    */
    event referralBonus(address indexed minter, address indexed referrer, uint256 count, uint256[] id);

    
    //Custom Modifier
    /**
    * @dev Custom modifier to restrict function calls to the authorized agent contract.
    * This modifier checks if the message sender (`msg.sender`) matches the `_agent` address stored in the contract.
    * If the condition is not met, the function execution reverts.
    * Functions requiring agent access (e.g., `payBonus`) should be decorated with this modifier.
    */
    modifier onlyAgent() {
        require(msg.sender == _agent , "Sender is not the _agent.");
        _;
    }


    /**
    * @dev Custom modifier to restrict function calls to the contract owner.
    * This modifier checks if the message sender (`msg.sender`) matches the `_owner` address stored in the contract.
    * If the condition is not met, the function execution reverts.
    * Functions requiring owner privileges (e.g., `setDCO`, `pause/unpause`, `sendDCO`) should be decorated with this modifier.
    */
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

}

// Interface for interacting with the ERC-20 DCO contract.
interface ERC20 {
    function approve(address spender, uint256 value) external returns (bool);
    function transfer( address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}