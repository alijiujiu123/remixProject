// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// 代币锁
contract TokenLocker {
    // 增加线性释放受益人信息
    event AddBeneficiaryInfoEvent(address indexed erc20, address indexed beneficiary, uint256 amount, uint256 lockTime);
    // 释放代币事件
    event ReleaseBeneficiaryAmountEvent(address indexed erc20, address indexed beneficiary, uint256 amount);
    // 受益人数据不存在
    error BeneficiaryInfoNotExists(address erc20, address beneficiaryAddress);
    // 受益人信息
    struct BeneficiaryInfo {
        // 锁定结束时间
        uint256 lockTime;
        // 锁定金额
        uint256 amount;
        // 是否已释放
        bool released;
    }
    // erc20 -> beneficiaryArress -> beneficiaryInfo 映射
    mapping(address erc20Address => mapping(address beneficiaryAddress => BeneficiaryInfo)) public tokenBeneficiaryInfo;
    // 添加受益人
    function addBeneficiaryInfo(address erc20, address beneficiary, uint256 amount, uint256 lockTime) external {
        // checks
        require(_checkERC20(erc20), "erc20 address invalid");
        require(beneficiary != address(0), "beneficiary invalid");
        require(amount > 0,"amount zero");
        require(lockTime > 0, "duration zero");
        require(tokenBeneficiaryInfo[erc20][beneficiary].lockTime == 0, "beneficiary exists");
        // effects
        tokenBeneficiaryInfo[erc20][beneficiary].lockTime = block.timestamp+lockTime;
        tokenBeneficiaryInfo[erc20][beneficiary].amount = amount;
        // interactions
        _transfer(erc20, amount);
        emit AddBeneficiaryInfoEvent(erc20, beneficiary, amount, lockTime);
    }
    function _checkERC20(address erc20) private view returns (bool) {
        if (erc20 == address(0) || erc20.code.length==0) {
            return false;
        }
        return true;
    }
    function _transfer(address erc20, uint256 amount) private {
        IERC20(erc20).transferFrom(msg.sender, address(this), amount);
    }
    // 代币释放
    function releaseBeneficiary(address erc20) external returns (uint256) {
        // checks
        require(_checkERC20(erc20), "erc20 address invalid");
        address beneficiaryAddress = msg.sender;
        if (tokenBeneficiaryInfo[erc20][beneficiaryAddress].lockTime == 0) {
            revert BeneficiaryInfoNotExists(erc20, beneficiaryAddress);
        }
        require(!tokenBeneficiaryInfo[erc20][beneficiaryAddress].released, "amount is released");
        if (block.timestamp < tokenBeneficiaryInfo[erc20][beneficiaryAddress].lockTime) {
            revert ("not util lockTime");
        }
        // effects
        tokenBeneficiaryInfo[erc20][beneficiaryAddress].released = true;
        // interactions
        // 转账
        uint256 releaseAmount = tokenBeneficiaryInfo[erc20][beneficiaryAddress].amount;
        IERC20(erc20).transfer(beneficiaryAddress, releaseAmount);
        emit ReleaseBeneficiaryAmountEvent(erc20, beneficiaryAddress, releaseAmount);
        return releaseAmount;
    }
}