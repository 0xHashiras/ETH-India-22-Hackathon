// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Potion is ERC20, Ownable {
    constructor() ERC20("POTION", "PT") {}

    // TODO : access control
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    // TODO : access control
    function burn(address account, uint256 amount) public virtual {
        // _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}
