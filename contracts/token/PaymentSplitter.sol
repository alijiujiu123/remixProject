// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// 分账合约：收益按照固定份额分配
contract PaymentSplitter {
    // 增加受益人事件
    event PayeeAdded(address payee, uint256 shares);
    // 收款事件
    event PaymentReceived(address sender, uint256 amount);
    // 收益提取事件
    event PaymentReleased(address payee, uint256 amount);

    // 总份额
    uint256 public totalShares;
    // 账户 -> 分账份额 映射
    mapping(address account => uint256) public shares;
    // 总提取
    uint256 public totalReleased;
    // 账户 -> 受益人提取金额 映射
    mapping(address account => uint256) public released;
    // 受益人数组
    address[] public payees;

    // 构造函数初始化受益人数据
    constructor(address[] memory _payees,uint256[] memory _shares) payable {
        require(_shares.length == _payees.length, "_payees length not equals _shares length");
        require(_payees.length > 0, "no payees");
        for (uint i = 0; i < _shares.length; ++i) {
            _addPayee(_payees[i], _shares[i]);
        }
    }
    // 添加受益人及收益份额
    function _addPayee(address _account, uint256 _shares) private {
        // checks
        require(_account != address(0), "invalid account");
        require(_shares > 0, "Shares can not zero");
        require(shares[_account] == 0, "account already has shares");
        // effects
        shares[_account] += _shares;
        totalShares += _shares;
        payees.push(_account);
    }
    // 接收ETH
    receive() external payable {
        // eth接收事件
        emit PaymentReceived(msg.sender, msg.value);
    }
    // 查询总收益
    function totalReceived() public view returns (uint256) {
        return address(this).balance+totalReleased;
    }
    // 分账提取amount金额eth
    function release(uint256 amount) public {
        // checks
        address payee = msg.sender;
        require(shares[payee] > 0, "not payee");
        // 计算可提取金额
        uint256 payment = releasable(payee);
        require(payment >= amount, "payment not enough");
        // effects
        released[payee] += amount;
        totalReleased += amount;
        // interactions
        // call转账
        (bool success,) = payee.call{value: amount}("");
        if (success) {
            emit PaymentReleased(payee, amount);
        }
    }

    // 计算account,总可提取金额
    function releasable(address account) public view returns (uint256) {
        // account所占份额/总分成份额 * 总收益 - account已提取金额
        return shares[account]*totalReceived() / totalShares - released[account];
    }
}