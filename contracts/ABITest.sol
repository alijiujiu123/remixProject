// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
contract ABITest {
    uint256[2] public arr = [6,8];
    function encodeTest(uint a, address b, string memory c) external view returns (bytes memory result) {
//        ;
        result = abi.encode("encodeTest(uint,ddress,string memory)",a, b, c, arr);
    } 
    function encodePackedTest(uint a, address b, string memory c) external view returns (bytes memory result) {
        result = abi.encodePacked("encodeTest(uint,ddress,string memory)",a, b, c, arr);
    }
    function encodeWithSignatureTest(uint a, address b, string memory c) external view returns (bytes memory result) {
        result = abi.encodeWithSignature("encodeTest(uint,ddress,string memory)", a, b, c, arr);
    }

    function encodeWithSelectorTest(uint a, address b, string memory c) external view returns (bytes memory result) {
        result = abi.encodeWithSelector(ABITest.encodeTest.selector, a, b, c, arr);
    }

    function decodeTest(bytes memory data) external pure 
        returns (string memory selector,uint a, address b, string memory c, uint256[2] memory _arr) {
            (selector, a, b, c, _arr) = abi.decode(data, (string, uint,address,string,uint256[2]));
    }

    function getSelector(string memory methodSign) external pure returns (bytes4 selector) {
        selector = bytes4(keccak256(bytes(methodSign)));
    }
}