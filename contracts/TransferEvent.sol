// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract TransferEvent {
    // 用户余额
    mapping(address => uint256) private address2Balance;
    // 构造方法
    constructor() {
        address2Balance[msg.sender] = 1e18 ether;
    }
    // 修饰器
    modifier havaBalance() {
        require(address2Balance[msg.sender]>0, "must have halance");
        _;
    }
    // 事件
    event Transfer(address indexed from, address indexed to, uint256 amount);
    // 转账
    function transfer(address to, uint256 amount) external havaBalance returns (uint256) {
        // checks
        require(to!=address(0), "target address must not empty");
        require(amount>0, "amount must be positive");
        // effects
        uint256 oldBalance = address2Balance[msg.sender];
        require(oldBalance>=amount, "balance less than amount");
        address2Balance[msg.sender] -= amount;
        address2Balance[to] += amount;
        // interactions
        // event
        emit Transfer(msg.sender, to, amount);
        return address2Balance[msg.sender];
    }
    // 查询余额
    function getBalance() external view returns (uint256) {
        return address2Balance[msg.sender];
    }
}