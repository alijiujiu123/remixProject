// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// v2合约：支持自增1，自减1，支持自增任意数字
contract LogicV2 {
    uint256 private counter;
    bool private isInitialized;
    error InitailizerCallRepeat();
    function increa() external {
        counter++;
    }
    function increaBy(uint256 num) external {
        counter += num;
    }
    function decrea() external {
        counter--;
    }
    function getCounter() external view returns (uint256) {
        return counter;
    }
    // 初始化方法
    function initialize(uint256 value) external {
        if (isInitialized) {
            revert InitailizerCallRepeat();
        }
        counter = value+6;
        isInitialized = true;
    }
}