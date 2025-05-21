// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
contract DestructContract {
    uint public value = 10;

    constructor() payable {}

    receive() external payable {}

    function destruct() external {
        selfdestruct(payable(msg.sender));
    }

    // 获取余额
    function getBalance() external view returns (uint balance) {
        balance = address(this).balance;
    }

}

// deploy and destruct in a same transaction, the contract will delete
contract DeployDestructContract {
    struct DestructContractInfo {
        address addr;
        uint balance;
        uint value;
    }

    constructor() payable {}

    // 获取余额
    function getBalance() external view returns (uint balance) {
        balance = address(this).balance;
    }

    // 销毁合约（只转出ETH，扔可调用）
    function destruct() external {
        selfdestruct(payable(msg.sender));
    }

    // deploy and destruct the Destruct
    function deployDestructContract() external payable returns (DestructContractInfo memory) {
        // deploy DestructContract
        DestructContract des = new DestructContract{value: msg.value}();
        // save DestructContractInfo
        DestructContractInfo memory res = DestructContractInfo({
            addr: address(des),
            balance: des.getBalance(),
            value: des.value()
        });
        // destruct 
        des.destruct();
        return res;
    }

}