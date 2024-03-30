// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @title Decuple Token Contract (DCO)
 * @author [Your Name/Team] (if applicable)
 * @notice This contract is an ERC20 token implementation for the Decuple project.
 * @dev It inherits from the OpenZeppelin `ERC20` contract to provide standard token functionalities
 *  like transfer, allowance, and total supply tracking.
 *  In the constructor, it mints a total supply of 100 billion DCO tokens (1000000000 * 10^18)
 *  and assigns them to the contract deployer (msg.sender).
 */
contract Decuple is ERC20 {
    constructor() ERC20("Decuple", "DCO") {
        _mint(msg.sender, 1000000000*(10**18));
    }
}