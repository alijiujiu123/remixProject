// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// v1合约：只支持自增1
contract LogicV1 {
    uint256 private counter;
    bool private isInitialized;
    error InitailizerCallRepeat();
    function increa() external {
        counter++;
    }
    function getCounter() external view returns (uint256) {
        return counter;
    }
    // 初始化方法
    function initialize(uint256 value) external {
        if (isInitialized) {
            revert InitailizerCallRepeat();
        }
        counter = value;
        isInitialized = true;
    }
}