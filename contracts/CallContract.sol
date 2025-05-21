// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "contracts/LogLibrary.sol";
contract SomeContract {
    error SetNumWithoutETH();
    event CallReceive(address indexed from, uint256 amount);
    event CallFallback(address indexed from, uint256 amount, bytes data);
    uint256 private num;
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    function getNum() external view returns (uint256) {
        return num;
    }
    function setNum(uint256 _num) external payable {
        if (msg.value == 0) {
            revert SetNumWithoutETH();
        }
        num = _num;
    }
    receive() external payable {
        emit CallReceive(msg.sender, msg.value);
    }
    fallback() external payable {
        emit CallFallback(msg.sender, msg.value, msg.data);
    }
}
contract CallContract {
    using LogLibrary for *;
    event CallReturnLog(bool success, bytes data);
    SomeContract private immutable someContract;
    address immutable someContractAddress;
    constructor(address _address) payable {
        someContract = SomeContract(payable(_address));
        someContractAddress = _address;
    }
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    // 通过传入地址调用合约函数
    function callSomeContractGetBalance(address _address) external view returns (uint256) {
        return SomeContract(payable(_address)).getBalance();
    }
    // 通过传入合约调用目标函数
    function callSomeContractGetNum() external view returns (uint256) {
        return someContract.getNum();
    }
    // 通过传入合约，调用函数并发送ETH
    function callSomContractSetNum(uint256 _num) external payable {
        someContract.setNum{value: msg.value-1}(_num);
    }
    // call方法调用函数（官方推荐用来转账、触发fallback、触发receive），不推荐调用普通方法；普通方法推荐使用：声明合约变量后调用函数方法
    // 触发receive
    function callReceive() external payable {
        (bool success, bytes memory resultData) = someContractAddress.call{value:msg.value}("");
        emit CallReturnLog(success, resultData);
    }
    // 触发fallback
    function callFallback() external payable {
        (bool success, bytes memory resultData) = someContractAddress.call{value:msg.value}(
            abi.encodeWithSignature("notExists()")
        );
        emit CallReturnLog(success, resultData);
    }
    // 触发getNum(不推荐)
    function callGetNum() external {
        (bool success, bytes memory resultData) = someContractAddress.call(
            abi.encodeWithSignature("getNum()")
        );
        emit CallReturnLog(success, resultData);
        uint256 num = abi.decode(resultData, (uint256));
        "callGetNum.result: ".printUint256Log(num);
    }
    // 触发setNum(不推荐)
    function callSetNum(uint256 num) external payable {
        (bool success, bytes memory resultData) = someContractAddress.call{value:msg.value-1}(
            abi.encodeWithSignature("setNum(uint256)", num)
        );
        emit CallReturnLog(success, resultData);
    }
}