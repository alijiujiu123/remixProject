// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
contract MyERC1155Receiver is IERC1155Receiver, ERC165 {
    event ERC1155ReceivedEvent(address indexed operator, address indexed from, uint256 indexed id, uint256 value, bytes data);
    event ERC1155BatchReceivedEvent(address indexed operator, address indexed from, uint256[] ids, uint256[] values, bytes data);

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
    // ERC1155代币转账接受
    function onERC1155Received(
        address operator, 
        address from, 
        uint256 id, 
        uint256 value, 
        bytes calldata data
    ) external override returns (bytes4) {
        emit ERC1155ReceivedEvent(operator, from, id, value, data);
        return this.onERC1155Received.selector;
    }
    // ERC1155批量代币转账接受
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public override returns (bytes4) {
        emit ERC1155BatchReceivedEvent(operator, from, ids, values, data);
        return this.onERC1155BatchReceived.selector;
    }
}