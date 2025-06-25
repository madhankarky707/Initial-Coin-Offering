//SPDX-License-Identifier:NOLICENSE
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

pragma solidity =0.8.28;

contract MKToken is ERC20, ERC20Burnable {
    uint256 initialSupply = 12_000_000; // 12 Million

    constructor() ERC20("MK Token","MKT") {
        _mint(msg.sender, initialSupply * 10 ** decimals()); // Creating 12 million tokens for the deployer.
    }
}