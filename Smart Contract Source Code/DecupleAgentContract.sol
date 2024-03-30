// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

//import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";


contract Agent { 

    /**
    * @dev Price of minting one NFT.
    */
    uint256 public price1 = 100000000000000000; // 0.1 


    /**
    * @dev Price of minting three NFTs at the same time.
    */
    uint256 public price3 = 200000000000000000; // 0.2 

    
    /**
    * @dev Price of minting five NFTs at the same time.
    */
    uint256 public price5 = 300000000000000000; // 0.3


        
    /**
    * @dev Address of the ERC20 token used for minting payments. 
    * This contract assumes the token deployed at this address is USDT.
    */
    address public usdtAddress = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd; // USDT
    ERC20 _token;

    /**
    * @dev Address of the deployed ERC-721 NFT contract used for minting NFTs.
    */
    address public _nftContractAddress = 0x7f9D666653c4Beda0E402B5B35D33FfF7b41B186; // Decuple NFT
    NFT _nft;


    /**
    * @dev Address of the deployed Bonus contract used for paying referral bonuses.
    */
    address public _bonusContract = 0xdBcA65490D0572657Ad8dF803ED95aF01afbD775; // Decuple Bonus Manager
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
    bool private _referralProgram; 

    /**
    * @dev Address of the contract owner.
    * The owner has special privileges to manage the contract.
    */
    address private immutable _owner;


    /**
    * @dev List of reserve addresses where the minting fees are distributed.
    * The order of addresses in this list corresponds to the order of percentages 
    * defined in `portions1`, `portions3`, and `portions5`.
    */
    address[] private reserves = [0xf1ccEA469D75BC034034C1464542bB5CDC5515c2,0x9E62609A54b91Db49dd04277bbAcB25432fb8325];

    /**
    * @dev Distribution percentages for reserve addresses when minting 1, 3, or 5 NFTs respectively.
    * Each element in the array corresponds to a reserve address in the `reserves` list.
    * The sum of all percentages in an array should be equal to 100 (100%).
    */
    uint256[] private portions1 = [70000000000000000,30000000000000000];     // 70% - 30%
    uint256[] private portions3 = [140000000000000000,60000000000000000];    // 70% - 30%
    uint256[] private portions5 = [210000000000000000,90000000000000000];    // 70% - 30%


    // set reservs and portions

    
        /**
        * @dev Updates the list of reserve addresses where the minting fees are transferred. Only the owner can call this function.
        *
        */
        function setReserves(address[] memory newReserves) public onlyOwner returns(bool){
            reserves = newReserves;
            return true;
        }


        /**
        * @dev Updates the distribution portions for the reserve addresses when minting 1 NFT. Only the owner can call this function.
        *
        */
        function setPortions1(uint256[] memory newportions) public onlyOwner returns(bool){
            portions1 = newportions;
            return true;
        }



        /**
        * @dev Updates the distribution portions for the reserve addresses when minting 3 NFTs. Only the owner can call this function.
        *
        */
        function setPortions3(uint256[] memory newportions) public onlyOwner returns(bool){
            portions3 = newportions;
            return true;
        }



        /**
        * @dev Updates the distribution portions for the reserve addresses when minting 5 NFTs. Only the owner can call this function.
        *
        */
        function setPortions5(uint256[] memory newportions) public onlyOwner returns(bool){
            portions5 = newportions;
            return true;
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
        * @dev Returns the address of the currently deployed NFT contract.
        *
        */
        function getNFTContractAddress() public view returns (address){
            return _nftContractAddress;
        }
    //

    //Set Bonus Contract

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
        * @dev Returns the address of the currently deployed Bonus contract.
        *
        */
        function getBonusContractAddress() public view returns (address){
            return _bonusContract;
        }
    //

    constructor(){
        _owner = msg.sender;
        _paused = false;
        _referralProgram = true;
        _nft = NFT(_nftContractAddress);
        _token = ERC20(usdtAddress);
        
    }




    // Mint Functions Normal

        /**
        * @dev Mints one NFT to the caller after transferring the required amount of USDT from the caller's wallet to the reserve addresses.
        *
        */
        function mint1() public whenNotPaused returns(bool){
            bool p0 = _token.transferFrom(msg.sender,reserves[0],portions1[0]);
            bool p1 = _token.transferFrom(msg.sender,reserves[1],portions1[1]);
            require(p0 && p1);
            uint256 id = _nft.safeMint(msg.sender);
            emit  mint(msg.sender, id);
            return true;
        }
        
        
        /**
        * @dev Mints three NFTs to the caller after transferring the required amount of USDT from the caller's wallet to the reserve addresses.
        *
        */
        function mint3() public whenNotPaused returns(bool){
            bool p0 = _token.transferFrom(msg.sender,reserves[0],portions3[0]);
            bool p1 = _token.transferFrom(msg.sender,reserves[1],portions3[1]);
            require(p0 && p1);
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
            bool p0 = _token.transferFrom(msg.sender,reserves[0],portions5[0]);
            bool p1 = _token.transferFrom(msg.sender,reserves[1],portions5[1]);
            require(p0 && p1);
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

            bool p0 = _token.transferFrom(msg.sender,reserves[0],portions1[0]);
            bool p1 = _token.transferFrom(msg.sender,reserves[1],portions1[1]);
            require(p0 && p1);
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

            bool p0 = _token.transferFrom(msg.sender,reserves[0],portions3[0]);
            bool p1 = _token.transferFrom(msg.sender,reserves[1],portions3[1]);
            require(p0 && p1);
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

            bool p0 = _token.transferFrom(msg.sender,reserves[0],portions5[0]);
            bool p1 = _token.transferFrom(msg.sender,reserves[1],portions5[1]);
            require(p0 && p1);
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


    // General Functions
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
        * @dev Updates the prices for minting 1, 3, or 5 NFTs. Only the owner can call this function
        *
        */
        function setMintPrices(uint256[] memory prices) public onlyOwner returns (bool){
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
 