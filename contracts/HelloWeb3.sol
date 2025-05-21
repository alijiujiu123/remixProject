// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract HelloWeb3 {
    string public myStr = "Hello Web3";
    // bool
    bool public myBool = true;
    bool public flag = !myBool;

    // int
    int public counter = -1;
    // uint
    uint public uCounter = 2**2;
    // uint256
    uint256 public u2Counter = 2**4;
    uint256 public u2Counter1 = u2Counter+1;
    bool public compareU2 = u2Counter1 >= u2Counter;

    // address
    address public myAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    // payable address
    address payable public myPayableAddress = payable(myAddress);
    // address.balance
    uint256 public myBalance = myAddress.balance;
    uint256 public myPayableBalance = myPayableAddress.balance;
    bool public balanceEquals = myBalance == myPayableBalance;

    // bytes32
    bytes32 public myByte32 = "MiniSolidity";
    // bytes1
    bytes1 public myByte1 = myByte32[0];

    // enum
    enum ActionSet {Buy, Hold, Sell}
    ActionSet myAction = ActionSet.Hold;
    // toUint
    uint public action2Uint = uint(myAction);
    // toAction
    ActionSet public uint2Action = ActionSet(action2Uint);
}