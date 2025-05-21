// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "contracts/LogLibrary.sol";
    // Logic V1
contract LogicV1 {
    using LogLibrary for *;
    uint256 public value;

    function initialize(uint256 _value) external {
        value = _value;
    }

    function setValue(uint256 _value) external {
        value = _value;
    }
    function getValue() external returns (uint256) {
        "LogicV1 getValue(),msg.sender:".printAddressLog(msg.sender);
        return value;
    }
}

// Logic V2
contract LogicV2 {
    using LogLibrary for *;
    uint256 public value;

    function initialize(uint256 _value) external {
        value = _value+1;
    }

    function setValue(uint256 _value) external {
        value = _value * 2;
    }
    function getValue() external returns (uint256) {
        "LogicV2 getValue(),msg.sender:".printAddressLog(msg.sender);
        return value+1;
    }
}

// Proxy Contract
contract MyProxy is TransparentUpgradeableProxy {
    using LogLibrary for *;
    bytes public constant MY_CONSTANT = hex"fe4b84df000000000000000000000000000000000000000000000000000000000000002a";
    constructor(address _logic,address owner)
        TransparentUpgradeableProxy(_logic, owner, MY_CONSTANT)
    {}
    function getProxyAdmin() external view returns (address) {
        return super._proxyAdmin();
    }
    // 目的是使用TransparentUpgradeableProxy的_fallback转发
    fallback() external payable override  {
        "MyProxy fallback(),msg.sender:".printAddressLog(msg.sender);
        TransparentUpgradeableProxy._fallback();
    }
    receive() external payable {}
}

contract MethodSign {
    using LogLibrary for *;
    function getInitializeMethodSign(uint256 _value) public pure returns (bytes memory) {
        bytes memory initData = abi.encodeWithSignature("initialize(uint256)", _value);
        return initData;
    }
    function getInitializeMethodSign() public pure returns (bytes memory) {
        bytes memory initData = abi.encodeWithSignature("initialize(uint256)", 8);
        return initData;
    }
    function getGetValueMethodSign() external pure returns (bytes memory) {
        bytes memory initData = abi.encodeWithSignature("getValue()");
        return initData;
    }
    function getSetValueMethodSign() external pure returns (bytes memory) {
        bytes memory initData = abi.encodeWithSignature("setValue(uint256)", 8);
        return initData;
    }
    // function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
    // function getUpgradeToAndCallMethodSign() external pure returns (bytes memory) {
    //     // 先获取initialize
    //     bytes memory initializeMethodSign = getInitializeMethodSign();
    //     bytes memory initData = abi.encodeWithSignature("upgradeToAndCall(address,bytes)", 0x03292440D9BAF284Cc75De6342A3673888DCCA55, initializeMethodSign);
    //     return initData;
    // }
    function trgerUpgradeToAndCall(address proxyAddress, address upgradeAddress) external returns (bytes memory) {
        "MethodSign trgerUpgradeToAndCall(),msg.sender:".printAddressLog(msg.sender);
        bytes4 upgradeSelector = ITransparentUpgradeableProxy.upgradeToAndCall.selector;
        "trgerUpgradeToAndCall upgradeSelector:".printBytesLog(abi.encodePacked(upgradeSelector));
        // 构建data
        bytes memory initData = abi.encodeWithSignature("initialize(uint256)", uint256(15));
        bytes memory upgradeData = abi.encodeWithSignature("upgradeToAndCall(address,bytes calldata)", upgradeAddress, initData);
        (bool success, bytes memory resultData) = proxyAddress.call(upgradeData);
        "trgerUpgradeToAndCall success:".printBoolLog(success);
        "trgerUpgradeToAndCall resultData:".printBytesLog(resultData);
        return upgradeData;
    }
    function callProxy(address contractAddress) external {
        bytes memory initData = abi.encodeWithSignature("getValue()");
        (bool success, bytes memory resultData) = contractAddress.call(initData);
        "callProxy success:".printBoolLog(success);
        "callProxy resultData:".printUint256Log(abi.decode(resultData, (uint256)));
    }
    function delegateCallProxy(address contractAddress) external {
        bytes memory initData = abi.encodeWithSignature("getValue()");
        (bool success, bytes memory resultData) = contractAddress.delegatecall(initData);
        "callProxy success:".printBoolLog(success);
        "callProxy resultData:".printUint256Log(abi.decode(resultData, (uint256)));
    }
    function contractProxy(address contractAddress) external {
        uint256 result = LogicV1(contractAddress).getValue();
        "callProxy resultData:".printUint256Log(result);
    }

}
// 升级合约
contract UpgradeContract {
    using LogLibrary for *;
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public proxy;
    constructor(uint256 num) {
        // 部署ProxyAdmin
        proxyAdmin = new ProxyAdmin(address(this));
        // 部署初始逻辑合约（目标合约）
        LogicV1 logicV1 = new LogicV1();
        // 部署代理合约
        proxy = new TransparentUpgradeableProxy(
            address(logicV1),
            address(proxyAdmin),
            abi.encodeWithSignature("initialize(uint256)", num)
        );
        "address(this):".printAddressLog(address(this));
        "address(proxyAdmin): ".printAddressLog(address(proxyAdmin));
    }
    // 升级并执行初始化方法
    function upgradeToV2(address v2, uint256 newValue) external {
        bytes memory data = abi.encodeWithSignature("initialize(uint256)", newValue);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), v2, data);
    }
    // 调用代理合约
    function callProxyGetValue() external returns (uint256) {
        bytes memory data = abi.encodeWithSignature("getValue()");
        (bool success, bytes memory result) = address(proxy).call(data);
        "callProxy success:".printBoolLog(success);
        "callProxy resultData:".printBytesLog(result);
        return abi.decode(result, (uint256));
    }
    function callProxySetValue(uint256 num) external returns (bool) {
        bytes memory data = abi.encodeWithSignature("setValue(uint256)", num);
        (bool success, bytes memory result) = address(proxy).call(data);
        "callProxy resultData:".printBytesLog(result);
        return success;
    }
    // function getProxyAdmin() external view returns (address) {
    //     return proxy._proxyAdmin();
    // }
}