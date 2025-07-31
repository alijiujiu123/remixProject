// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GeneralAirdrop {
    event MultiAirdropETHRebackFail(address indexed sender);
    event MultiAirdropETHFail(address indexed sender, address indexed receiver, uint amount);
    // 想多个地址转账ERC20代币，使用前需要先授权
    function multiTransferToken(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external {
        // 校验数组长度相等
        require(_addresses.length == _amounts.length, " lengths of Addresses and Amounts not equal");
        // 检查授权额度
        IERC20 token = IERC20(_token);
        uint _amountSum = getSum(_amounts);
        require(token.allowance(msg.sender, address(this))>=_amountSum, "Need approval ERC20 token");
        // 发送空投
        for(uint i=0; i<_addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }

    }
    function multiTransferETH(address payable[] calldata _addresses, uint256[] calldata _amounts) external payable {
        // 校验数组长度相等
        require(_addresses.length == _amounts.length, " lengths of Addresses and Amounts not equal");
        // 校验金额
        uint _amountSum = getSum(_amounts);
        require(msg.value>=_amountSum, "msgValue not enough");
        uint sendSum = 0;
        for(uint i=0; i<_addresses.length; i++) {
            // _addresses[i].transfer(_amounts[i])有Dos攻击风险
            (bool success, ) = _addresses[i].call{value: _amounts[i]}("");
            if (!success) {
                emit MultiAirdropETHFail(msg.sender, _addresses[i], _amounts[i]);
            }
            sendSum += _amounts[i];
        }
        // 返还多余eth
        (bool rebackResult, ) = payable(msg.sender).call{value: msg.value-sendSum}("");
        if (!rebackResult) {
            emit MultiAirdropETHRebackFail(msg.sender);
        }
    }
    function getSum(uint256[] calldata _amounts) private pure returns(uint256) {
        uint sum = 0;
        for(uint i=0; i<_amounts.length; i++) {
            sum += _amounts[i];
        }
        return sum;
    }
}