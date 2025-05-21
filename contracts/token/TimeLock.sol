// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// 时间锁：可以将交易锁定一段时间后执行
contract TimeLock {
    // 创建交易事件
    event TransactionQueued(address indexed target, uint256 value, string signature, bytes data, uint256 executeTime, bytes32 indexed txHash);
    // 锁定期满后的交易执行事件
    event TransactionCancelled(address indexed target, uint256 value, string signature, bytes data, uint256 executeTime, bytes32 indexed txHash, bytes returnData);
    // 交易取消事件
    event CancelTransaction(bytes32 indexed txHash);
    // 修改管理员地址事件
    event AdminChanged(address newAdmin, address oldAdmin);

    address public admin;
    // 交易锁定时间
    uint256 public delay;
    // 锁定交易队列
    mapping(bytes32 txHash => bool) public queuedTransactions;

    constructor(uint256 _delay) {
        delay = _delay;
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Forbidden: Caller not admin");
        _;
    }
    modifier onlyTimeLocker() {
        require(msg.sender == address(this), "Forbidden: Caller not timeLocker");
        _;
    }
    // admin更改(只允许本合约调用)
    function changeAdmin(address newAdmin) public onlyTimeLocker {
        require(admin != newAdmin, "Forbidden: Admin not change");
        address old = admin;
        admin = newAdmin;
        emit AdminChanged(newAdmin, old);
    }
    
    // 加入交易队列
    function queueTransaction(
        // 目标地址
        address target, 
        // eth金额
        uint256 value,
        // 调用函数签名 
        string memory signature, 
        // 交易calldata
        bytes memory data, 
        // 交易执行时间
        uint256 executeTime
    ) external onlyAdmin payable {
        // checks
        require(executeTime > block.timestamp+delay, "queueTransaction: executeTime must satisfy delay");
        // effects
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        queuedTransactions[txHash] = true;
        emit TransactionQueued(target, value, signature, data, executeTime, txHash);
    }
    // 获取txHash
    function getTxHash(
        // 目标地址
        address target,
        // eth金额
        uint256 value,
        // 调用函数签名 
        string memory signature, 
        // 交易calldata
        bytes memory data, 
        // 交易执行时间
        uint256 executeTime
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(target, value,signature, data, executeTime));
    }

    // 执行特定交易: 1、交易在队列中；2、达到交易执行时间
    function executeTransaction(
        // 目标地址
        address target,
        // eth金额
        uint256 value,
        // 调用函数签名 
        string memory signature, 
        // 交易calldata
        bytes memory data, 
        // 交易执行时间
        uint256 executeTime
    ) external onlyAdmin returns (bytes memory) {
        // checks
        require(executeTime > block.timestamp+delay, "executeTransaction: executeTime must satisfy delay");
        bytes32 txHash = getTxHash(msg.sender, value, signature, data, executeTime);
        require(queuedTransactions[txHash], "executeTransaction: Transaction not queued");
        // effects
        // 移除队列
        queuedTransactions[txHash] = false;
        // interactions
        // 构建参数
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        }else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // 执行交易
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "executeTransaction: call fail");
        emit TransactionCancelled(target, value, signature, data, executeTime, txHash, returnData);
        return returnData;
    }
    // 取消交易
    function cancelTransaction(bytes32 _txHash) external onlyAdmin {
        require(queuedTransactions[_txHash], "cancelTransaction: Transaction not queued");
        queuedTransactions[_txHash] = false;
        emit CancelTransaction(_txHash);
    }
}
contract Test {
    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}