// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/Pair.sol";
contract PairFactory {
    // 通过代币地址查询Pair地址
    mapping(address => mapping(address => address)) public getPair;
    // 所有pair地址
    address[] public allPairs;

    // CREATE contract
    function createPair(address tokenA, address tokenB) external returns (address pairAddress) {
        // 创建币对合约Pair
        Pair pair = new Pair();
        // 调用pair合约的initialize()
        pair.initialize(tokenA, tokenB);
        // 保存getPair
        pairAddress = address(pair);
        getPair[tokenA][tokenB] = pairAddress;
        getPair[tokenB][tokenA] = pairAddress;
        // 保存allPairs
        allPairs.push(pairAddress);
    }

    // CREATE2 contract
    function create2Pair(address tokenA, address tokenB) external returns (address pairAddress) {
        PairTwo pair = new PairTwo{salt: _getSalt(tokenA, tokenB)}(66);
        // 初始化
        pair.initialize(tokenA, tokenB);
        // 保存getPair
        pairAddress = address(pair);
        getPair[tokenA][tokenB] = pairAddress;
        getPair[tokenB][tokenA] = pairAddress;
        // 保存allPairs
        allPairs.push(pairAddress);
    }

    // get salt by tokenA and tokenB
    function _getSalt(address tokenA, address tokenB) private pure returns (bytes32 salt) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        salt = keccak256(abi.encodePacked(token0, token1));
    }
    // calculate CREATE2 address
    function calculateCreate2Address(address tokenA, address tokenB) public view returns(address pairAddress) {
        require(tokenA != tokenB, "Illegal token: must different");
        // 用tokenA和tokenB计算salt
        bytes32 salt = _getSalt(tokenA, tokenB);
        // 无构造参数
        // bytes32 initCode = keccak256(
        //     type(Pair).creationCode
        // );
        // 有构造参数
        bytes32 initCode = keccak256(
            abi.encodePacked(
                type(PairTwo).creationCode,
                abi.encode(66)
            )
        );
        pairAddress = _calcCreate2Address(address(this), salt, initCode);
    }
    function _calcCreate2Address(address creator, bytes32 salt, bytes32 initCode) private pure returns (address create2Address) {
        create2Address = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xFF),
                            creator,
                            salt,
                            initCode
                        )
                    )
                )
            )
        );
    }
}