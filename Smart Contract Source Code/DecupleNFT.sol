// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;


import "@openzeppelin/contracts@5.0.2/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";


/**
 * @title Decuple NFT ERC-721
 * @author Lenzolab Development team - matthewshelb@gmail.com
 * @notice This contract manages tokens for Decuple NFT project.
 * @dev It interacts with the Decuple Agent contract.
 */
contract Decuple is ERC721, ERC721Pausable, Ownable { 
    uint256 private _nextTokenId;

    constructor(address initialOwner)
        ERC721("DecupleNFT", "DCP")
        Ownable(initialOwner)
    {  
        agent = msg.sender; 
    }  
 
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmQZEpoNiDxhpxLZ5zQqrSJHEimFnxxSAXMy3V1fNYeWW1/";
        // return "https://ipfs.io/ipfs/QmZADDRyuwz8QNFAA6cEpbkbxvZ8qEgb2k1pcetL2zitk2/";
    }

    function pause() public onlyOwner {
        _pause();
    } 

    function unpause() public onlyOwner {
        _unpause();
    }

    // onlyAgent is a custom modifier
    function safeMint(address to) public onlyAgent whenNotPaused returns(uint256){
        //Custom condition
        require(_nextTokenId < maxSupply, "Collection has reachd to the maximum.");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }


    //Custom Variables:
    uint256 public constant maxSupply = 100;
    address public agent;

    //Custom Functions
    function getOwnedBy(address wallet) public view returns(uint256[] memory){
        uint256 balance = balanceOf(wallet);
        require(balance > 0 , "Address does not own any NFTs");
        uint256[] memory assets = new uint256[](balance);
        uint256 index = 0;
        for (uint256 i = 0; i < maxSupply; i++) 
        {
            if(_owners[i] == wallet){
                assets[index] = i;
                index++;
            }
        }
        return assets;
    }

    function totalSupply() public view returns(uint256){
        if(_nextTokenId <= maxSupply){
            return _nextTokenId;
        }
        return maxSupply; // This is only for the time that all NFTs are  minted.
    }


    //Custom Modifier
    modifier onlyAgent() {
        require(msg.sender == agent , "Sender is not the agent.");
        _;
    }

    function setAgent(address newAgent) public onlyOwner{
        agent = newAgent;
    }
    
 

}


// In ERC721 the visibility of the -owners has been changed from private to internal.
// In ERC721 Int the tokenURI function, the line _requireOwned(tokenId); has been commented.
// In ERC721 Int the tokenURI function, the part (, ".json") has been added to the return value;
// Custom variable maxSupply has been added.
// In safeMint Custome condition id < maxSupply has been Added.
// Custom function getOwnedBy has been Added.
// Custom function totalSupply has been Added.
// Custom modifier onlyAgent has been Added.
// Custom function setAgent has been Added.
