// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/utils/GrantPrivileges.sol";
contract MyERC20 is ERC20,GrantPrivileges {
    // string public constant TOKEN_NAME="NEZHA";
    // string public constant TOKEN_SYMBOL="NZ";
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){
        _mint(msg.sender, 10000000000*10**18);
    }
    function mint(address account, uint256 value) external onlyAdmin {
        _mint(account, value);
    }

}