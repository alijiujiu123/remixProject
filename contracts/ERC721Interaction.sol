// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "contracts/MyERC721.sol";
// NFT基础数据抽象合约
abstract contract NFTTransactionBase {
    IERC721 public nft;
    // 构造参数是，nft合约地址
    constructor(address nftAddress) {
        nft = IERC721(nftAddress);
    }
}
// 合约触发"NFT合约"转账
contract ERC721Interaction is NFTTransactionBase,ERC721Transfer {
    // 构造函数
    constructor(address nftAddress) NFTTransactionBase(nftAddress) {}
    // nft转移
    function transfer(address to, uint256 tokenId) external {
        emit MESTransfer(msg.sender, to, tokenId);
        // 授权代币：这一步必须在此合约方法调用之前，代币持有者调用nft.approve()对特定nft进行授权，
        // 或代币持有者调用nft.approvalForAll()对所有持有的所有nft进行全局授权
        // 否则会失败：Address that may be allowed to operate on tokens without being their owner
        // 代币转移
        nft.safeTransferFrom(msg.sender, to, tokenId);
    }
}
// nft接收合约账户: 由于使用safeTransferFrom,会导致nft交易失败
// 报错信息：Address to which tokens are being transferred.
contract NFTReciver {}

// 实现了IERC721Receiver的合约，可以接收nft
contract ERC721Receiver is NFTTransactionBase,IERC721Receiver,ERC721Transfer {
    // 接收到的ntf
    mapping(uint256 => bool) public receivedTokens;
    // 构造函数
    constructor(address nftAddress) NFTTransactionBase(nftAddress) {}
    // nft接收事件
    event NFTReceved(address indexed operator, address indexed from, uint256 indexed tokenId,bytes data);
    // 合约发出nft事件
    event NFTTransfer(address indexed to, uint256 indexed tokenId);
    // nft接收
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        emit NFTReceved(operator, from, tokenId, data);
        receivedTokens[tokenId] = true;
        return this.onERC721Received.selector;
    }
    // nft从当前合约转移到目标地址
    function transfer(address to,uint256 tokenId) external {
        emit MESTransfer(msg.sender, to, tokenId);
        // checks
        require(receivedTokens[tokenId], "not have this tokenId");
        // effects
        delete receivedTokens[tokenId];
        // interactions
        nft.safeTransferFrom(address(this), to, tokenId);
    }
}