// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library MerkleProof {
    // 验证通过proof+leaf，是否可以还原出root
    function verify (
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal  pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    // 计算proof+leaf的值
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computeHash = leaf;
        for(uint256 i=0; i<proof.length; i++) {
            computeHash = _computePair(computeHash, proof[i]);
        }
        return computeHash;
    }

    // 计算hash对，的hash值
    function _computePair(bytes32 a, bytes32 b) private  pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encode(b, a));
    }
}

contract TestProof {
    event ProofFail(bytes32 errRoot);
    bytes32 public constant root = 0x6d649da728564a114b7a35d7ab9712bb35c0973d88d918f0b77e98f554098228;
    bytes32[] public proof;

    function verifyLeaf() external returns (bool) {
        proof.push(0xe511f2bcabebcb974e530ac6ddc211a9fa14bea01bef14199ed902f88b9d0518);
        proof.push(0x5527280678aaa80d7c2296c355c7c600a333fd98ee7dd3df3610d2bca0603672);
        proof.push(0x6dc277eda17b262674e6184a52d6ebf2eac80050c5ee4b876b2bc851ba9622fe);
        proof.push(0x946f07a4b999bc9b4acbd2e6fd8770c041478dc715dcf8fadb969c42a1df661b);
        proof.push(0x672ea51beb9a9e4187ed9968a047a5a3160db3c26bfcd9801bf9fa835b12e5f3);

        bytes32 leaf = 0x7b2e1e5d78c71d8d385435a44af6973d31aed552438f3fab5a17ea1140c4aae0;
        bool result =  MerkleProof.verify(proof, root, leaf);
        if(!result) {
            bytes32 errRoot = MerkleProof.processProof(proof, leaf);
            emit ProofFail(errRoot);
        }

        return result;
    }
}