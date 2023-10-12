// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract FractionalNFT is ERC20 {
    constructor() ERC20("FRACTIONAL_NFT", "FRN", 18) {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}