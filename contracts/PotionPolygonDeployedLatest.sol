// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Potion is ERC20, Ownable {
    address public operator;

    constructor() ERC20("POTION", "PT") {}

    function updateOperator(address _operator) external onlyOwner{
        operator = _operator ;
    }

    modifier onlyOperator() {
        require(operator == _msgSender(), "caller is not the operator");
        _;
    }

    function mint(address to, uint256 amount) public onlyOperator {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public onlyOperator virtual {
        // _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}
