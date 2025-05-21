// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Exception {
    // 定义日志事件
    event Log(string msg);
    // 定义error
    error SenderAddressNotAdmin(address sender);
    // 不可变常量
    address public immutable adminAddress;
    constructor() {
        adminAddress = msg.sender;
    }
    // require
    // transaction cost: 23332
    function requireTest() external {
        emit Log("requireTest called");
        require(msg.sender==adminAddress, "sender address not admin");
    }
    // error
    // transaction cost: 23241
    function errorTest() external {
        emit Log("errorTest called");
        if (msg.sender != adminAddress) {
            revert SenderAddressNotAdmin(msg.sender);
        }
    }
    // assert: 一般用作debug或测试，因为没有报错信息，没用
    // transaction cost: 23065
    function assertTest() external {
        emit Log("assertTest called");
        assert(msg.sender == adminAddress);
    }
}