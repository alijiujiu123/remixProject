// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "contracts/LogLibrary.sol";
contract MyERC1967 is TransparentUpgradeableProxy {
    using LogLibrary for *;
    // 初始化代理合约
    constructor(address _logic,address owner, bytes memory _data) payable TransparentUpgradeableProxy(_logic, owner, _data){
        // "MyERC1967 constructor()".printLog();
    }
    function getAdmin() external view returns (address) {
        return super._proxyAdmin();
    }
    receive() external payable {}
    // fallback() external payable override  { 
    //     super._fallback();
    // }
}
contract MyERC1967Target {
    using LogLibrary for *;
    uint256 public num;
    function init(uint256 _num) external {
        num = _num;
//        "MyERC1967Target init()".printUint256Log(_num);
    }
    function getNum() external view returns (uint256) {
        return num;
    }
    function setNum(uint256 _num) external {
        num = _num;
    }
}
// 0xbADc3f83445681bddD289CDF0936577b43e8130F
//function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
contract MyERC1967TargetTwo {
    using LogLibrary for *;
    uint256 public num;
    function initTwo(uint256 _num) external {
        num = _num*2;
        "MyERC1967TargetTwo init()".printUint256Log(_num);
    }
    function getNum() external view returns (uint256) {
        return num-1;
    }
    function setNum(uint256 _num) external {
        num = _num+1;
    }
}
contract CallDataGenerate {
    MyERC1967 myERC1967;
    // constructor(MyERC1967 _myERC1967) {
    //     myERC1967 = _myERC1967;
    // }
    function generateInit(uint256 _num) external pure returns (bytes memory) {
        bytes memory result = abi.encodeWithSignature("init(uint256)", _num);
        return result;
    }
    function generateGetNum() external pure returns (bytes memory) {
        bytes memory result = abi.encodeWithSignature("getNum()");
        return result;
    }
    function generateSetNum(uint256 _num) external pure returns (bytes memory) {
        bytes memory result = abi.encodeWithSignature("setNum(uint256)", _num);
        return result;
    }
    // function getNum() external view returns (uint256) {
    //     return myERC1967.getNum();
    // }
    // function setNum(uint256 _num) external {
    //     myERC1967.setNum(_num);
    // }
    // function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
    function generateUpgradeToAndCall(address newImplementation,bytes calldata data) external pure returns (bytes memory) {
        bytes memory result = abi.encodeWithSignature("upgradeToAndCall(address,bytes)", newImplementation, data);
        return result;
    }
    function generateInitTwo(uint256 _num) external pure returns (bytes memory) {
        bytes memory result = abi.encodeWithSignature("initTwo(uint256)", _num);
        return result;
    }
}