// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// WETH合约
contract WETH is ERC20 {
    // 存款事件
    event Deposit(address indexed sender, uint256 amount);
    // 取款事件
    event Withdraw(address indexed sender, uint256 amount);
    constructor() ERC20("MYWETH", "MYWETH") {}
    // 存款方法
    function deposit() public payable {
        uint256 amount = msg.value;
        // effects
        _mint(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }
    // 取款方法
    function withdraw(uint256 _amount) external {
        // effects
        _burn(msg.sender, _amount);
        // interactions
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }
    fallback() external payable { 
        deposit();
    }
    receive() external payable { 
        deposit();
    }

}