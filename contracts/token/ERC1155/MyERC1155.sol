// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
contract MyERC1155 is ERC1155 {
    string public name;
    string public symbol;
    address public admin;
    // 构造函数
    constructor(string memory _name, string memory _symbol, string memory uri) ERC1155(uri) {
        name = _name;
        symbol = _symbol;
        admin = msg.sender;
    }
    modifier onlyAdmin() {
        require(msg.sender==admin, "only admin can access");
        _;
    }
    // 代币铸造
    function min(address to, uint256  id, uint256 value) external onlyAdmin {
        super._mint(to, id, value, "");
    }
    // 批量铸造
    function mintBatch(address to, uint256[] memory ids, uint256[] memory values) external onlyAdmin {
        super._mintBatch(to, ids, values, "");
    }
    // 代币销毁(ERC1155Burnable已实现)
}
