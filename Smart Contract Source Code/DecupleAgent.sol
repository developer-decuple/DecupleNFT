// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

//import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";


/**
 * @title Agent Contract
 * @author Lenzolab Development team - matthewshelb@gmail.com
 * @notice This contract manages price payment and mint the Decuple NFT project.
 * @dev It interacts with the Decuple NFT contract, USDT ERC-20 and an Decuple Bonus contract.
 */
contract Agent { 
        
    /**
    * @dev Address of the ERC20 token used for minting payments. 
    * This contract assumes the token deployed at this address is USDT.
    */
    address public usdtAddress = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd; // USDT
    ERC20 _token;


    /**
    * @dev Address of the deployed ERC-721 NFT contract used for minting NFTs.
    */
    address public _nftContractAddress = 0x87F89CE4b499FB7330958406e3dF8D2FAB8D654F; // Decuple NFT
    NFT _nft;


    /**
    * @dev Address of the deployed Bonus contract used for paying referral bonuses.
    */
    address public _bonusContract = 0xEFeB1Ee21eE114eC51229A92DC4aa23318cc2999; // Decuple Bonus Manager
    Bonus _bonus;


    /**
    * @dev Flag indicating whether the contract is paused.
    * When paused, minting actions are prevented.
    */
    bool private _paused;


    /**
    * @dev Flag indicating whether the referral program is active.
    * When enabled, users can mint NFTs with a referral bonus.
    */
    bool public _referralProgram; 


    /**
    * @dev Address of the contract owner.
    * The owner has special privileges to manage the contract.
    */
    address private _owner;


    /**
    * @dev Price of minting one NFT.
    */
    uint256 public price1 = 100000000000000000; // 0.1 USDT


    /**
    * @dev Price of minting three NFTs at the same time.
    */
    uint256 public price3 = 200000000000000000; // 0.2 USDT

    
    /**
    * @dev Price of minting five NFTs at the same time.
    */
    uint256 public price5 = 300000000000000000; // 0.3 USDT


    /**
    * @dev Distribution percentages for reserve addresses when minting 1, 3, or 5 NFTs respectively.
    * Each element in the array corresponds to a reserve address in the `reserves` list.
    * The sum of all percentages in an array should be equal to 100 (100%).
    */
    mapping(uint8 => uint256[])  private portions;


    /**
    * @dev List of reserve addresses where the minting fees are distributed.
    * The order of addresses in this list corresponds to the order of percentages 
    * defined in `portions[0]` to `portions[9]`.
    */
    address[] private reserves = [
        0xf1ccEA469D75BC034034C1464542bB5CDC5515c2,
        0x9E62609A54b91Db49dd04277bbAcB25432fb8325,
        0xf1ccEA469D75BC034034C1464542bB5CDC5515c2,
        0xf1ccEA469D75BC034034C1464542bB5CDC5515c2,
        0xf1ccEA469D75BC034034C1464542bB5CDC5515c2,
        0xf1ccEA469D75BC034034C1464542bB5CDC5515c2,
        0xf1ccEA469D75BC034034C1464542bB5CDC5515c2,
        0xf1ccEA469D75BC034034C1464542bB5CDC5515c2,
        0xf1ccEA469D75BC034034C1464542bB5CDC5515c2,
        0xf1ccEA469D75BC034034C1464542bB5CDC5515c2];


    
    
    // Managerial Seetings
    

        /**
        * @dev Chenges the contract owner.
        * The owner has special privileges to manage the contract.
        */
        function changeOwner(address newOwner) public onlyOwner {
            _owner = newOwner;
        }

    
        /**
        * @dev Updates the list of reserve addresses where the minting fees are transferred. Only the owner can call this function.
        *
        */
        function setReserves(address[] memory newReserves) public onlyOwner returns(bool){
            require(newReserves.length == 10, "Array length is not valid.");
            reserves = newReserves;
            return true;
        }
 

        /**
        * @dev Updates the distribution portions for the reserve addresses. 
        *
        */
        function setPortions(uint8 count, uint256[] memory newPortions) public onlyOwner returns (bool){
            require(newPortions.length == 10, "Array length is not valid.");
            uint256 total = 0;
            for (uint256 i = 0; i < newPortions.length; i++) 
            {
                total += newPortions[i];
            }
            if(count == 1 && total == price1){
                portions[count] = newPortions;
                return true;
            }
            if(count == 3 && total == price3){
                portions[count] = newPortions;
                return true;
            }
            if(count == 5 && total == price5){
                portions[count] = newPortions;
                return true;
            }
            revert("Not a valid price array or count.");
        }

        /**
        * @dev Disables the referral program. Only the owner can call this function.
        *
        */
        function stopReferral() public onlyOwner returns(bool){
            _referralProgram = false;
            return true;
        }

        /**
        * @dev Enables the referral program. Only the owner can call this function.
        *
        */
        function startReferral() public onlyOwner returns(bool){
            _referralProgram = true;
            return true;
        }

        
        /**
        * @dev Updates the address of the deployed NFT contract. Only the owner can call this function.
        *
        */
        function setNFTContract(address adr) public onlyOwner{
            _nftContractAddress = adr;
            _nft = NFT(adr);
        }


        /**
        * @dev Updates the address of the deployed Bonus contract. Only the owner can call this function.
        *
        */
        function setBonusContract(address newAddress) public onlyOwner returns(bool){
            _bonusContract = newAddress;
            _bonus = Bonus(newAddress);
            return true;
        }


        
        /**
        * @dev Updates the prices for minting 1, 3, or 5 NFTs. Only the owner can call this function
        *
        */
        function setMintPrices(uint256[] memory prices) public onlyOwner returns (bool){
            require(prices.length == 3, "Array length is not valid.");
            price1    = prices[0];
            price3    = prices[1];
            price5    = prices[2];
            return true;
        }


        /**
        * @dev Pauses the contract, preventing any minting actions. Only the owner can call this function.
        *
        */
        function pause() public onlyOwner{
            _paused = true;
        }
        

        /**
        * @dev Unpauses the contract, allowing minting actions to resume. Only the owner can call this function.
        *
        */
        function unpause()  public onlyOwner{
            _paused = false;
        }

    //

    constructor(){
        _owner = msg.sender;
        _paused = false;
        _referralProgram = true;
        _nft = NFT(_nftContractAddress);
        _token = ERC20(usdtAddress);
        _bonus = Bonus(_bonusContract);       

        portions[1] = [10000000000000000, 10000000000000000, 10000000000000000, 10000000000000000, 10000000000000000, 10000000000000000, 10000000000000000, 10000000000000000, 10000000000000000, 10000000000000000];    // 10% each
        portions[3] = [20000000000000000, 20000000000000000, 20000000000000000, 20000000000000000, 20000000000000000, 20000000000000000, 20000000000000000, 20000000000000000, 20000000000000000, 20000000000000000];    // 10% each
        portions[5] = [30000000000000000, 30000000000000000, 30000000000000000, 30000000000000000, 30000000000000000, 30000000000000000, 30000000000000000, 30000000000000000, 30000000000000000, 30000000000000000];    // 10% each
   
    }




    // Mint Functions Normal

        /**
        * @dev Mints one NFT to the caller after transferring the required amount of USDT from the caller's wallet to the reserve addresses.
        *
        */
        function mint1() public whenNotPaused returns(bool){
            require(payPrice(msg.sender, 1), "Unable to pay the price.");
            uint256 id = _nft.safeMint(msg.sender);
            emit  mint(msg.sender, id);
            return true;
        }

        
        /**
        * @dev Mints three NFTs to the caller after transferring the required amount of USDT from the caller's wallet to the reserve addresses.
        *
        */
        function mint3() public whenNotPaused returns(bool){
            require(payPrice(msg.sender, 3), "Unable to pay the price.");
            uint256 id1 = _nft.safeMint(msg.sender);
            emit  mint(msg.sender, id1);
            uint256 id2 = _nft.safeMint(msg.sender);
            emit  mint(msg.sender, id2);
            uint256 id3 = _nft.safeMint(msg.sender);
            emit  mint(msg.sender, id3);
            return true;
        }

        /**
        * @dev Mints five NFTs to the caller after transferring the required amount of USDT from the caller's wallet to the reserve addresses.
        *
        */  
        function mint5() public whenNotPaused returns(bool){
            require(payPrice(msg.sender, 5), "Unable to pay the price.");
            uint256 id1 = _nft.safeMint(msg.sender);
            emit  mint(msg.sender, id1);
            uint256 id2 = _nft.safeMint(msg.sender);
            emit  mint(msg.sender, id2);
            uint256 id3 = _nft.safeMint(msg.sender);
            emit  mint(msg.sender, id3);
            uint256 id4 = _nft.safeMint(msg.sender);
            emit  mint(msg.sender, id4);
            uint256 id5 = _nft.safeMint(msg.sender);
            emit  mint(msg.sender, id5);
            return true;
        }

    //



    // Mint With Referral
                                                      
        /**
        * @dev Mints one NFT to the caller with a referral bonus if a valid referral address is provided. Requires transferring the required amount of USDT from the caller's wallet to the reserve addresses.
        *
        */  
        function mint1R(address referrer) public whenNotPaused returns(bool){
            require(msg.sender != referrer, "Referrer and Sender cant be the same.");

            require(payPrice(msg.sender, 1), "Unable to pay the price.");
            uint256[] memory news = new uint256[](1);

        
            uint256 id1 = _nft.safeMint(msg.sender);
            news[0]=id1;
            emit  mintWithReferral(msg.sender,referrer, id1);

            if(_referralProgram){
                Bonus.refData memory mintDataR = Bonus.refData(news, price1, msg.sender, referrer, block.timestamp );
                _bonus.payBonus(mintDataR);
            }

            return true;
        }


                                                      
        /**
        * @dev Mints three NFTs to the caller with a referral bonus if a valid referral address is provided. Requires transferring the required amount of USDT from the caller's wallet to the reserve addresses.
        *
        */  
        function mint3R(address referrer) public whenNotPaused returns(bool){
            require(msg.sender != referrer, "Referrer and Sender cant be the same.");

            require(payPrice(msg.sender, 3), "Unable to pay the price.");
            uint256[] memory news = new uint256[](3);


        
            uint256 id1 = _nft.safeMint(msg.sender);
            news[0]=id1;
            emit  mintWithReferral(msg.sender,referrer, id1);
        
            uint256 id2 = _nft.safeMint(msg.sender);
            news[1]=id2;
            emit  mintWithReferral(msg.sender,referrer, id2);
        
            uint256 id3 = _nft.safeMint(msg.sender);
            news[2]=id3;
            emit  mintWithReferral(msg.sender,referrer, id3);
    
            if(_referralProgram){
                Bonus.refData memory mintDataR = Bonus.refData(news, price3, msg.sender, referrer, block.timestamp );
                _bonus.payBonus(mintDataR);
            }
            return true;
        }
        
                                                              
        /**
        * @dev Mints five NFTs to the caller with a referral bonus if a valid referral address is provided. Requires transferring the required amount of USDT from the caller's wallet to the reserve addresses.
        *
        */  
        function mint5R(address referrer) public whenNotPaused returns(bool){
            require(msg.sender != referrer, "Referrer and Sender cant be the same.");

            require(payPrice(msg.sender, 5), "Unable to pay the price.");
            uint256[] memory news = new uint256[](5);


            uint256 id1 = _nft.safeMint(msg.sender);
            news[0]=id1;
            emit  mintWithReferral(msg.sender,referrer, id1);

            uint256 id2 = _nft.safeMint(msg.sender);
            news[1]=id1;
            emit  mintWithReferral(msg.sender,referrer, id2);

            uint256 id3 = _nft.safeMint(msg.sender);
            news[2]=id1;
            emit  mintWithReferral(msg.sender,referrer, id3);
            
            uint256 id4 = _nft.safeMint(msg.sender);
            news[3]=id1;
            emit  mintWithReferral(msg.sender,referrer, id4);
            
            uint256 id5 = _nft.safeMint(msg.sender);
            news[4]=id1;
            emit  mintWithReferral(msg.sender,referrer, id5);

            if(_referralProgram){
                Bonus.refData memory mintDataR = Bonus.refData(news, price5, msg.sender, referrer, block.timestamp );
                _bonus.payBonus(mintDataR);
            }
            return true;
        }

    //



    /**
    * @dev Transfers the price of mint.
    *
    */
    function payPrice(address sender, uint8 count) private returns (bool){
        uint256[] memory pors = portions[count];
        bool p0 = _token.transferFrom(sender, reserves[0], pors[0]);
        bool p1 = _token.transferFrom(sender, reserves[1], pors[1]);
        bool p2 = _token.transferFrom(sender, reserves[2], pors[2]);
        bool p3 = _token.transferFrom(sender, reserves[3], pors[3]);
        bool p4 = _token.transferFrom(sender, reserves[4], pors[4]);
        bool p5 = _token.transferFrom(sender, reserves[5], pors[5]);
        bool p6 = _token.transferFrom(sender, reserves[6], pors[6]);
        bool p7 = _token.transferFrom(sender, reserves[7], pors[7]);
        bool p8 = _token.transferFrom(sender, reserves[8], pors[8]);
        bool p9 = _token.transferFrom(sender, reserves[9], pors[9]);
        if(p0 && p1 && p2 && p3 && p4 && p5 && p6 && p7 && p8 && p9 ){
            return true;
        }else{
            return false;
        }
    }


    /**
    * @dev Returns an array containing the current prices for minting 1, 3, or 5 NFTs.
    *
    */
    function getMintPrices() public view returns (uint256[] memory){
        uint256[] memory prices = new uint256[](3);
        prices[0] = price1;
        prices[1] = price3;
        prices[2] = price5;
        return prices;
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


    /**
    * @dev Modifier to restrict function execution when the contract is paused.
    * This modifier checks if the internal `_paused` state variable is `false`,
    * indicating the contract is active. If the contract is paused (`_paused` is `true`),
    * the function execution will revert with a "Paused" message using the `require` statement.
    * Functions requiring active status should be decorated with this modifier
    * to ensure they are only callable when the contract is operational.
    */
        modifier whenNotPaused() {
            require(_paused == false);
            _;
        }
    //



    /**
    * @dev Emitted when an NFT is minted successfully.
    *
    */
    event mint(address indexed minter,  uint256 id);

    /**
    * @dev Emitted when an NFT is minted with a referral bonus.
    *
    */
    event mintWithReferral(address indexed minter, address indexed referrer, uint256 id);


}


// Interface for interacting with the Bonus contract
interface Bonus {

    // Function to pay referral bonus based on provided data
    function payBonus(refData memory data) external returns (bool) ;

    // Structure representing data for referral bonus payment
    struct refData {
        uint256[] ids;
        uint256 price;
        address minter;
        address referrer;
        uint256 timestamp;
    }
}


// Interface for interacting with the NFT contract
interface NFT {
    // Function to mint a new NFT to a specified address
    function safeMint(address to) external returns (uint256) ;
}


// Interface for interacting with an ERC20 compliant token
interface ERC20 {

    // Function to approve spending of tokens by the contract
    function approve(address spender, uint256 value) external returns (bool);

    // Function to transfer tokens from one address to another
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
 