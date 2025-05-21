// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "contracts/LogLibrary.sol";
import "@openzeppelin/contracts/utils/SlotDerivation.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
contract ReceiveETH {
    using LogLibrary for *;
    using SlotDerivation for *;
    using StorageSlot for *;

    event ReceiveCalled(address indexed sender, uint256 amount);
    event FallbackCalled(address indexed sender, uint256 amount, bytes msgData);
    event DelegateCallSuccess(address indexed sender, uint256 amount, bytes msgData, bytes returnData);
    error DelegateCallFailed();
    /**
     * This is the keccak-256 hash of "eip1967.proxy.ownerBalance" subtracted by 1.
     */
    bytes32 internal constant OWNER_BALANCE_MAPPING_SLOT = 0x1f110348bc21beebf4be96c5a8a1d0e3fb17d4705fa82359e4adaf1ea21a7f51;

    // address -> amount
//    mapping(address => uint256) public ownerBalance;
    address public immutable targetAddress;
    // 构造方法，初始化被代理合约地址
    constructor(address _targetAddress) {
        targetAddress = _targetAddress;
    }
    // 获取合约余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    function getOwnerBalance() external view returns (uint256) {
//        return ownerBalance[msg.sender];
        return getBalance(msg.sender);
    }
    function getBalanceByAddress(address _address) external view returns (uint256) {
        return getBalance(_address);
    }
    // 接收ETH
    function recharge() external payable returns (bool) {
        "recharge: ".printAddressValueLog(msg.sender, msg.value);
//        ownerBalance[msg.sender] += msg.value;
        addOwnerBalance(msg.sender, msg.value);
        return true;
    }
    // receive: 接收直接转账(msg.data无数据)，send，transfer会限制gas
    receive() external payable {
        // 触发事件
        emit ReceiveCalled(msg.sender, msg.value);
//         ownerBalance[msg.sender] += msg.value;
        addOwnerBalance(msg.sender, msg.value);
    }
    // fallback: 不存在的函数调用, 如果msg.data不为空，执行delegatecall调用
    fallback() external payable {
        bytes memory msgData = msg.data;
        emit FallbackCalled(msg.sender, msg.value, msgData);
        if (msgData.length>0) {
            // delegatecall
            (bool success, bytes memory returnData) = targetAddress.delegatecall(msgData);
            if (!success) {
                revert DelegateCallFailed();
            }else {
                // 打印返回值
                emit DelegateCallSuccess(msg.sender, msg.value, msgData, returnData);
            }
        }
    }
    // 获取owner对应balance
    function getBalance(address owner) private view returns (uint256) {
        // 计算mapping[owner]存储位置
        bytes32 ownerSlot = OWNER_BALANCE_MAPPING_SLOT.deriveMapping(owner);
        return ownerSlot.getUint256Slot().value;
    }
    // owner增加余额
    function addOwnerBalance(address owner, uint256 amount) private returns (uint256) {
        bytes32 ownerSlot = OWNER_BALANCE_MAPPING_SLOT.deriveMapping(owner);
        StorageSlot.Uint256Slot storage slot = ownerSlot.getUint256Slot();
        slot.value += amount;
        return slot.value;
    }
}
// TargetContract
contract TargetContract {
    using SlotDerivation for *;
    using StorageSlot for *;
    event TransferTo(address indexed to, uint256 amount);
    uint256 private counter;
    /**
     * This is the keccak-256 hash of "eip1967.proxy.ownerBalance" subtracted by 1.
     */
    bytes32 internal constant OWNER_BALANCE_MAPPING_SLOT = 0x1f110348bc21beebf4be96c5a8a1d0e3fb17d4705fa82359e4adaf1ea21a7f51;
    
//    mapping(address => uint256) public ownerBalance;
    // 验证ETH没有转给目标合约
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    function giveYourMoney() external payable returns (bool, uint256) {
        // ownerBalance[msg.sender] += msg.value;
        // return (true, ownerBalance[msg.sender]);
        return (true, addOwnerBalance(msg.sender, msg.value));
    }
    // 金额转出
    function transTo(address to, uint256 amount) external returns (uint256) {
//        uint256 myBalance = ownerBalance[msg.sender];
        address owner = msg.sender;
        uint256 myBalance = getBalance(owner);
        // checks
        require(myBalance>=amount, "balance not enough");
        // effects
        //ownerBalance[msg.sender] -= amount;
        uint256 result = minusOwnerBalance(owner, amount);
        // interaction
        payable(to).transfer(amount);
        emit TransferTo(to, amount);
        return result;
    }

    // 获取owner对应balance
    function getBalance(address owner) private view returns (uint256) {
        // 计算mapping[owner]存储位置
        bytes32 ownerSlot = OWNER_BALANCE_MAPPING_SLOT.deriveMapping(owner);
        return ownerSlot.getUint256Slot().value;
    }
    // owner增加余额
    function addOwnerBalance(address owner, uint256 amount) private returns (uint256) {
        // 获取指定key的存储槽地址
        bytes32 ownerSlot = OWNER_BALANCE_MAPPING_SLOT.deriveMapping(owner);
        StorageSlot.Uint256Slot storage slot = ownerSlot.getUint256Slot();
        slot.value += amount;
        return slot.value;
    }
    // owner减少余额
    function minusOwnerBalance(address owner, uint256 amount) private returns (uint256) {
        bytes32 ownerSlot = OWNER_BALANCE_MAPPING_SLOT.deriveMapping(owner);
        StorageSlot.Uint256Slot storage slot = ownerSlot.getUint256Slot();
        slot.value -= amount;
        return slot.value;
    }
}

// TestSenderContract
contract TestSenderContract {
    using LogLibrary for *;
    event CallSuccess(address indexed to, uint256 amount, bool success, bytes returnData);
    event CallTransferToSuccess(address indexed to, address toAddress, bool success, bytes returnData);
    address public immutable receiveETHAddress;
    constructor(address _receiveETHAddress) {
        receiveETHAddress = _receiveETHAddress;
    }
    // 获取合约余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    receive() external payable {
        // 触发事件
        "TestSenderContract.receive: ".printAddressValueLog(msg.sender, msg.value);
    }
    // todo 调用ReceiveETH（代理合约）的giveYourMoney(), 并完成转账
    // ReceiveETH.giveYourMoney()
    function giveReceiveETHMoney(uint256 amount) external returns (uint256) {
        // checks
        require(address(this).balance>amount);
        // effects
        // interactions
        // 生成函数签名合并参数
        bytes memory data = abi.encodeWithSignature("giveYourMoney()");
        // 执行调用
        (bool success, bytes memory resultData) = receiveETHAddress.call{value:amount}(data);
        emit CallSuccess(receiveETHAddress, amount, success, resultData);
        return address(this).balance;
    }
    // ReceiveETH.transTo(): 将以太币转给其他address
    function transReceiveETHTo(address to, uint256 amount) external returns (bool) {
        // checks
        // effects
        // interactions
        // 1.生成签名
        bytes memory data = abi.encodeWithSignature("transTo(address,uint256)", to, amount);
        // 2.执行调用
        (bool success, bytes memory resultData) = receiveETHAddress.call(data);
        // 3.返回值解析
        emit CallTransferToSuccess(receiveETHAddress, to, success, resultData);
        return true;
    }

}

// 获取call低级调用data合约
contract CallUtil {
    function getCallData(string calldata methodSelector, address to, uint256 amount) external pure returns (bytes memory) {
        bytes memory data = abi.encodeWithSignature(methodSelector, to, amount);
        return data;
    }
    function generateKeccak256(string memory str) external pure returns (bytes32) {
        bytes32 hash = keccak256(bytes(str));
        return bytes32(uint256(hash)-1);
    }
}

// 部署时发送以太币
contract DeployETH {
    // 中奖余额
    mapping(address => uint256) public rewardAmount;
    // 可以在部署时添加ETH(作为初始奖金)
    constructor() payable {}
    // 可以通过向合约发送以太币来获取奖金
    function buyTicket() external payable returns (uint256) {
        // 白拿，给1块，送2块
        require(msg.value>0, "you can not give nothing");
        uint256 reward = msg.value+1 gwei;
        payable(msg.sender).transfer(reward);
        return reward;
    }
}
