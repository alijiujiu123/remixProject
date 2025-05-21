// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "contracts/structs/BitMaps.sol";
import "contracts/structs/MultiBitsMaps.sol";
contract BitMapsTest {
    using BitMaps for *;
    BitMaps.AddressBitMap private checkAccess;
    function check() external returns (string memory result) {
        if (!checkAccess.get(msg.sender)) {
            result = "welcome, nice to meet you";
            checkAccess.set(msg.sender);
        }else {
            result = "hi, my brother";
        }
    }

    function calcelFriend() external {
        checkAccess.unset(msg.sender);
    }

    using MultiBitsMaps for *;
    MultiBitsMaps.AddressTwoBitsMap private addressTwoBitsMap;
    function addAddressTwoBitsMap(uint8 value) external {
        addressTwoBitsMap.set(msg.sender, value);
    }
    function getAddressTwoBitsMap() external view returns (uint8) {
        return addressTwoBitsMap.get(msg.sender);
    }
    MultiBitsMaps.Uint256TwoBitsMap private uint256TwoBitsMap;
    function addUint256TwoBitsMap(uint256 data,uint8 value) external {
        uint256TwoBitsMap.set(data, value);
    }
    function getUint256TwoBitsMap(uint256 data) external view returns (uint8) {
        return uint256TwoBitsMap.get(data);
    }
    
    MultiBitsMaps.Uint256FourBitsMap private uint256FourBitsMap;
    function addUint256FourBitsMap(uint256 data,uint8 value) external {
        uint256FourBitsMap.set(data, value);
    }
    function getUint256FourBitsMap(uint256 data) external view returns (uint8) {
        return uint256FourBitsMap.get(data);
    }

    MultiBitsMaps.Uint256ByteMap private uint256ByteMap;
    function addUint256ByteMap(uint256 data,uint8 value) external {
        uint256ByteMap.set(data, value);
    }
    function getUint256ByteMap(uint256 data) external view returns (uint8) {
        return uint256ByteMap.get(data);
    }
}