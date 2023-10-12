// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract FractionalNFT is ERC20 {
    constructor() ERC20("FRACTIONAL_NFT", "FRN", 18) {
        // _mint(msg.sender, 1000000 * 10 ** 18); // Mint 1,000,000 fractionNFT tokens to the contract deployer
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}