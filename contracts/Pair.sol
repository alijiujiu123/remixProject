// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
contract Pair {
    address public factory;
    address public token0;
    address public token1;
    constructor() payable {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }
}

contract PairTwo {
    address public factory;
    address public token0;
    address public token1;
    uint256 public num;
    constructor(uint256 _num) payable {
        factory = msg.sender;
        num = _num;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }
}