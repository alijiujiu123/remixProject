// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract ERC712Storage {
    using ECDSA for bytes32;

    // storage
    // ERC712的类型hash
    bytes32 private constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    // Storage的类型hash
    bytes32 private constant STORAGE_TYPEHASH = keccak256("Storage(address spender,uint256 number)");
    // 每个Dapp的唯一值，由EIP712DOMAIN_TYPEHASH和STORAGE_TYPEHASH组成，构造函数中初始化
    bytes32 private DOMAIN_SEPARATOR;
    uint256 public number;
    address public  owner;

    // 构造函数
    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes("EIP712Storage")), // name
            keccak256(bytes("1")), // version
            block.chainid, // chain id
            address(this) // contract address
        ));
        owner = msg.sender;
    }

    // EIP712签名修改number值
    function permitStore(uint256 _num, bytes memory _signature) public {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // 使用内联汇编从签名中获取r,s,v
        assembly {
            // bytes _signature的存储布局: [length(32 bytes), r(32 bytes), s(32 bytes), v(1 bytes)]
            // 读取长度数据后的32bytes，[32, 64]
            r := mload(add(_signature, 0x20))
            // 读取r之后的32 bytes: [64, 96]
            s := mload(add(_signature, 0x40))
            // 读取s之后的1 bytes [96, 97]
            v := byte(0, mload(add(_signature, 0x60)))
        }
        // 获取签名消息hash
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(STORAGE_TYPEHASH, msg.sender, _num))
        ));
        // 恢复签名者
        address signer = digest.recover(v, r, s);
        // address signer = ECDSA.recover(digest, v, r, s);
        require(signer == owner, "ERC712Storage: Invalid signature");
        // 修改状态变量
        number = _num;
    }

}