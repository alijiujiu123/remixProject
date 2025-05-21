// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 线性释放
contract TokenVesting {
    // 增加线性释放受益人信息
    event AddBeneficiaryInfoEvent(address indexed erc20, address indexed beneficiary, uint256 amount, uint256 start, uint256 duration);
    // 释放代币事件
    event ReleaseBeneficiaryAmountEvent(address indexed erc20, address indexed beneficiary, uint256 amount);
    error BeneficiaryInfoNotExists(address erc20, address beneficiaryAddress);
    // 受益人信息
    struct BeneficiaryInfo {
        // 起始时间戳
        uint256 start;
        // 归属期
        uint256 duration;
        // 已释放金额
        uint256 released;
    }
    // erc20 -> beneficiaryArress -> beneficiaryInfo 映射
    mapping(address erc20Address => mapping(address beneficiaryAddress => BeneficiaryInfo)) public tokenBeneficiaryInfo;
    // 添加受益人
    function addBeneficiaryInfo(address erc20, address beneficiary, uint256 amount, uint256 duration) external {
        // checks
        require(_checkERC20(erc20), "erc20 address invalid");
        require(beneficiary != address(0), "beneficiary invalid");
        require(amount > 0,"amount zero");
        require(duration > 0, "duration zero");
        require(tokenBeneficiaryInfo[erc20][beneficiary].start == 0, "beneficiary exists");
        // effects
        uint256 start = block.timestamp;
        tokenBeneficiaryInfo[erc20][beneficiary].start = start;
        tokenBeneficiaryInfo[erc20][beneficiary].duration = duration;
        // interactions
        _transfer(erc20, amount);
        emit AddBeneficiaryInfoEvent(erc20, beneficiary, amount, start, duration);
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
    // 线性释放
    function releaseBeneficiary(address erc20) external returns (uint256) {
        // checks
        require(_checkERC20(erc20), "erc20 address invalid");
        address beneficiaryAddress = msg.sender;
        // 计算可释放金额
        uint256 releaseAmount = calcReleaseAmount(erc20, beneficiaryAddress);
        require(releaseAmount > 0, "releaseAmount zero");
        // effects
        tokenBeneficiaryInfo[erc20][beneficiaryAddress].released += releaseAmount;
        // interactions
        // 转账
        IERC20(erc20).transfer(beneficiaryAddress, releaseAmount);
        emit ReleaseBeneficiaryAmountEvent(erc20, beneficiaryAddress, releaseAmount);
        return releaseAmount;
    }
    // 计算当前可释放金额
    function calcReleaseAmount(address erc20, address beneficiaryAddress) public view returns (uint256) {
        if (tokenBeneficiaryInfo[erc20][beneficiaryAddress].start == 0) {
            revert BeneficiaryInfoNotExists(erc20, beneficiaryAddress);
        }
        // 总金额
        uint256 allAmount = tokenBeneficiaryInfo[erc20][beneficiaryAddress].released + IERC20(erc20).balanceOf(address(this));
        // 当前可解锁: (now-start)*allAmount/duration;
        uint256 diff = block.timestamp - tokenBeneficiaryInfo[erc20][beneficiaryAddress].start;
        if (diff > tokenBeneficiaryInfo[erc20][beneficiaryAddress].duration) {
            return allAmount - tokenBeneficiaryInfo[erc20][beneficiaryAddress].released;
        }else {
            uint256 allRelease = (block.timestamp - tokenBeneficiaryInfo[erc20][beneficiaryAddress].start)*allAmount/tokenBeneficiaryInfo[erc20][beneficiaryAddress].duration;
            // 当前可释放: 总可释放 - 已释放
            return allRelease - tokenBeneficiaryInfo[erc20][beneficiaryAddress].released;
        }
    }
}