// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract TransferToUser {
    function transferToUser(address toAddress) external payable returns (bool) {
        require(msg.value > 0, "msgValue zero error");
        return payable(toAddress).send(msg.value);
    }
}