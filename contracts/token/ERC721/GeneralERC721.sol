// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract GeneralERC721 is ERC721 {
    string private constant _name = "General ERC721 Token";
    string private constant _symbol = "GET";
    uint256 public tokenCounter;
    constructor () ERC721(_name, _symbol) {}
    function mint() external {
        _mint(msg.sender, tokenCounter++);
    }
}