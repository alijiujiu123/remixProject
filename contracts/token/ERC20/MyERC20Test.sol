// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "contracts/token/ERC20/MyERC20.sol";
contract MyERC20Test {
    MyERC20 public myERC20;
    constructor(){
        myERC20 = new MyERC20();
    }
    // 转账
    function transfer(address to, uint256 value) external {
        myERC20.transfer(to, value);
    }
    // 授权转账
    // function approveAndTransferFrom()
}