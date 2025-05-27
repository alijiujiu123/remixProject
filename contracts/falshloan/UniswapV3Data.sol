// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
interface IQuoterV2 {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        view
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountIn The desired input amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        view
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        view
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountOut The desired output amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutputSingle(QuoteExactOutputSingleParams memory params)
        external
        view
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}
interface IUniswapV3Data {
    // 获取pool数据参数
    struct PoolParam {
        address _token0Address;
        address _token1Address;
        uint24 fee;
    }
    // 获取pool数据返回
    struct PoolInfo {
        // UniswapV3Pool地址
        address poolAddress;
        // token0地址 
        address token0;
        // token0总储存量 
        uint256 token0Balance; 
        // token1地址
        address token1;
        // token1总储存量 
        uint256 token1Balance;
        int24 tickSpacing;
        // the current price
        uint160 sqrtPriceX96;
         // the current tick
        int24 tick;
        uint128 liquidity;
        PoolTick[] ticks;
    }
    struct PoolTick {
        // tick值
        int24 tick;
        uint128 liquidityGross;
        int128 liquidityNet;
    }
    // 获取uniswapV3Pool数据
    function getPoolInfo(address factoryAddress, PoolParam[] calldata poolParams) external view returns (PoolInfo[] memory poolInfoArray, uint256 latestBlockNumber, bytes32 blockHash);
    // 获取uniswapV3Pool数据: 不获取并返回ticks数据
    function getPoolInfoWithoutTickData(address factoryAddress, PoolParam[] calldata poolParams) external view returns (PoolInfo[] memory poolInfoArray, uint256 latestBlockNumber, bytes32 blockHash);
    // 查询pool状态数据
    function getPoolStateData(address poolAddress) external view returns (uint160 sqrtPriceX96,int24 tick, uint128 liquidity);
    // 查询pool的tick数据
    function getPoolTicks(address poolAddress, int24 tickSpacing) external view returns (PoolTick[] memory);
    // 根据tickBitMaps获取所有有效ticks
    function extractInitializedTicks(
        uint256[] memory tickBitMaps,
        int16 minWordPos,
        int24 tickSpacing
    ) external pure returns (int24[] memory);
    // 根据tick和tickspacing，计算出bitMap索引位置
    function tickToWord(int24 tick, int24 tickSpacing) external pure returns (int16);
}
contract UniswapV3Data is IUniswapV3Data {
    
    // 获取uniswapV3Pool数据
    function getPoolInfo(address factoryAddress, PoolParam[] calldata poolParams) public view returns (PoolInfo[] memory poolInfoArray, uint256 latestBlockNumber, bytes32 blockHash) {
        uint len = poolParams.length;
        (poolInfoArray, latestBlockNumber, blockHash) = getPoolInfoWithoutTickData(factoryAddress, poolParams);
        for(uint i=0; i<len; i++) {
            address poolAddress = poolInfoArray[i].poolAddress;
            // 查询
            if (poolAddress != address(0)) {
                // 构建tick数据
                poolInfoArray[i].ticks = getPoolTicks(poolAddress, poolInfoArray[i].tickSpacing);
            }
        }
    }
    function getPoolInfoWithoutTickData(address factoryAddress, PoolParam[] calldata poolParams) public view returns (PoolInfo[] memory poolInfoArray, uint256 latestBlockNumber, bytes32 blockHash) {
        IUniswapV3Factory factory = IUniswapV3Factory(factoryAddress);
        uint len = poolParams.length;
        poolInfoArray = new PoolInfo[](len);
        // latest区块号
        latestBlockNumber = block.number-1;
        blockHash = blockhash(latestBlockNumber);
        for(uint i=0; i<len; i++) {
            // 查询
            address poolAddress = factory.getPool(poolParams[i]._token0Address, poolParams[i]._token1Address, poolParams[i].fee);
            
            if (poolAddress != address(0)) {
                poolInfoArray[i].poolAddress = poolAddress;
                poolInfoArray[i].token0 = IUniswapV3PoolImmutables(poolAddress).token0();
                poolInfoArray[i].token0Balance = IERC20(poolInfoArray[i].token0).balanceOf(poolAddress);
                poolInfoArray[i].token1 = IUniswapV3PoolImmutables(poolAddress).token1();
                poolInfoArray[i].token1Balance = IERC20(poolInfoArray[i].token1).balanceOf(poolAddress);
                poolInfoArray[i].tickSpacing = IUniswapV3PoolImmutables(poolAddress).tickSpacing();
                (uint160 sqrtPriceX96, int24 tick, uint128 liquidity) = getPoolStateData(poolAddress);
                poolInfoArray[i].sqrtPriceX96 = sqrtPriceX96;
                poolInfoArray[i].tick = tick;
                poolInfoArray[i].liquidity = liquidity;
            }
        }
    }
    // 查询pool状态数据
    function getPoolStateData(address poolAddress) public view returns (uint160 sqrtPriceX96,int24 tick, uint128 liquidity) {
        IUniswapV3PoolState poolState = IUniswapV3PoolState(poolAddress);
        (sqrtPriceX96, tick, , , , , ) = poolState.slot0();
        liquidity = poolState.liquidity();
    }
    // 查询pool的tick数据
    function getPoolTicks(address poolAddress, int24 tickSpacing) public view returns (PoolTick[] memory) {
        IUniswapV3PoolState poolState = IUniswapV3PoolState(poolAddress);
        // 1. 根据tickSpacing计算所有的bitMap位置
        //      bitMap: 也称为字(word), uint256类型, 每个bitMap表示256个tick的状态
        //      bitMap的每个bit位表示是否初始化: 已初始化为1, 未初始化为0
        //      所有tick都位于-887272和887272之间，有效tick只能在被tickSpacing整除的所引出初始化
        int16 minWordPosition = tickToWord(-887272, tickSpacing);
        int16 maxWordPosition = tickToWord(887272, tickSpacing);
        // 2. 根据位置拿到所有的bitMap
        uint256 length = uint256(uint16(maxWordPosition - minWordPosition + 1));
        uint256[] memory tickBitMaps= new uint256[](length);
        for(int16 i=minWordPosition; i<=maxWordPosition; i++) {
            uint256 index = uint256(uint16(i-minWordPosition));
            tickBitMaps[index] = poolState.tickBitmap(i);
        }
        // 3. 从位图中计算出所有的tick值
        int24[] memory tickValueArray = extractInitializedTicks(tickBitMaps, minWordPosition, tickSpacing);
        // 4. 根据tick值获取tick数据
        PoolTick[] memory poolTicks = new PoolTick[](tickValueArray.length);
        for(uint i=0; i<tickValueArray.length; i++) {
            (
                uint128 liquidityGross,
                int128 liquidityNet,
                ,
                ,
                ,
                ,
                ,
                
            ) = poolState.ticks(tickValueArray[i]);
            poolTicks[i].tick = tickValueArray[i];
            poolTicks[i].liquidityGross = liquidityGross;
            poolTicks[i].liquidityNet = liquidityNet;
        }
        return poolTicks;
    }
    // 根据tickBitMaps获取所有有效ticks
    function extractInitializedTicks(
        uint256[] memory tickBitMaps,
        int16 minWordPos,
        int24 tickSpacing
    ) public pure returns (int24[] memory) {
        uint256 totalCount;

        // First pass: count total number of initialized ticks
        for (uint256 w = 0; w < tickBitMaps.length; w++) {
            uint256 bitmap = tickBitMaps[w];
            for (uint256 i = 0; i < 256; i++) {
                if ((bitmap & (1 << i)) != 0) {
                    totalCount++;
                }
            }
        }

        int24[] memory initializedTicks = new int24[](totalCount);
        uint256 index;

        // Second pass: extract tick values
        for (uint256 w = 0; w < tickBitMaps.length; w++) {
            uint256 bitmap = tickBitMaps[w];
            int24 wordPos = int24(int16(minWordPos) + int16(uint16(w))); // wordPos = min + offset

            for (uint256 i = 0; i < 256; i++) {
                if ((bitmap & (1 << i)) != 0) {
                    int24 tickIndex = (wordPos * 256 + int24(int256(i))) * tickSpacing;
                    initializedTicks[index++] = tickIndex;
                }
            }
        }

        return initializedTicks;
    }
    // 根据tick和tickspacing，计算出bitMap索引位置
    function tickToWord(int24 tick, int24 tickSpacing) public pure returns (int16) {
        // 压缩 tick（即 tick / tickSpacing）
        int24 compressed = tick / tickSpacing;

        // 对负数做额外处理（向下取整）
        if (tick < 0 && tick % tickSpacing != 0) {
            compressed -= 1;
        }

        // 每 256 个 compressed tick 对应一个 bitmap word
        int16 wordIndex = int16(compressed >> 8);
        return wordIndex;
    }
}
interface ITokenData {
    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        uint8 decimals;
    }
    function fetchTokenData(address[] calldata tokenAddresses) external view returns (TokenInfo[] memory);
}
contract TokenData is ITokenData {
    
    function fetchTokenData(address[] calldata tokenAddresses) public view returns (TokenInfo[] memory) {
        uint len = tokenAddresses.length;
        TokenInfo[] memory tokenInfos = new TokenInfo[](len);
        for(uint i=0; i<len; i++) {
            tokenInfos[i].tokenAddress = tokenAddresses[i];
            tokenInfos[i].name = IERC20Metadata(tokenAddresses[i]).name();
            tokenInfos[i].symbol = IERC20Metadata(tokenAddresses[i]).symbol();
            tokenInfos[i].decimals = IERC20Metadata(tokenAddresses[i]).decimals();
        }
        return tokenInfos;
    }
}
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// quoteV2多路调用
interface IQuoteV2MultiCall {
    // 1. quoteExactInput多路调用
    struct QuoteExactInputMulParam {
        bytes path;
        uint256 amountIn;
    }
    struct QuoteExactInputMulRes {
        uint256 amountOut;
        uint160[] sqrtPriceX96AfterList;
        uint32[] initializedTicksCrossedList;
        uint256 gasEstimate;
    }
    function quoteExactInputMul(address quoteV2Address,QuoteExactInputMulParam[] calldata params) external view returns (QuoteExactInputMulRes[] memory);

    // 2. quoteExactInputSingle多路调用
    struct QuoteExactInputSingleMulRes {
        uint256 amountOut;
        uint160 sqrtPriceX96After;
        uint32 initializedTicksCrossed;
        uint256 gasEstimate;
    }
    function quoteExactInputSingleMul(address quoteV2Address,IQuoterV2.QuoteExactInputSingleParams[] calldata params) external view returns (QuoteExactInputSingleMulRes[] memory);

    // 3. quoteExactOutput多路调用
    struct QuoteExactOutputMulParam {
        bytes path;
        uint256 amountOut;
    }
    struct QuoteExactOutputMulRes {
        uint256 amountIn;
        uint160[] sqrtPriceX96AfterList;
        uint32[] initializedTicksCrossedList;
        uint256 gasEstimate;
    }
    function quoteExactOutputMul(address quoteV2Address,QuoteExactOutputMulParam[] calldata params) external view returns (QuoteExactOutputMulRes[] memory);

    struct QuoteExactOutputSingleMulRes {
        uint256 amountIn;
        uint160 sqrtPriceX96After;
        uint32 initializedTicksCrossed;
        uint256 gasEstimate;
    }
    function quoteExactOutputSingleMul(address quoteV2Address,IQuoterV2.QuoteExactOutputSingleParams[] calldata params) external view returns (QuoteExactOutputSingleMulRes[] memory);
} 
contract QuoteV2MultiCall is IQuoteV2MultiCall {
    // 1. quoteExactInput 多路调用
    function quoteExactInputMul(address quoteV2Address, QuoteExactInputMulParam[] calldata params) external view returns (QuoteExactInputMulRes[] memory) {
        uint len = params.length;
        QuoteExactInputMulRes[] memory resultList = new QuoteExactInputMulRes[](len);

        for (uint i = 0; i < len; i++) {
            bytes memory callData = abi.encodeWithSelector(
                IQuoterV2.quoteExactInput.selector,
                params[i].path,
                params[i].amountIn
            );

            (bool success, bytes memory result) = quoteV2Address.staticcall(callData);
            if (success) {
                (
                    uint256 amountOut,
                    uint160[] memory sqrtPriceX96AfterList,
                    uint32[] memory initializedTicksCrossedList,
                    uint256 gasEstimate
                ) = abi.decode(result, (uint256, uint160[], uint32[], uint256));
                resultList[i] = QuoteExactInputMulRes(amountOut, sqrtPriceX96AfterList, initializedTicksCrossedList, gasEstimate);
            } else {
                revert(string(abi.encodePacked("staticcall failed at index ", Strings.toString(i))));
            }
        }

        return resultList;
    }

    // 2. quoteExactInputSingle 多路调用
    function quoteExactInputSingleMul(address quoteV2Address, IQuoterV2.QuoteExactInputSingleParams[] calldata params) external view returns (QuoteExactInputSingleMulRes[] memory) {
        uint len = params.length;
        QuoteExactInputSingleMulRes[] memory resultList = new QuoteExactInputSingleMulRes[](len);

        for (uint i = 0; i < len; i++) {
            bytes memory callData = abi.encodeWithSelector(
                IQuoterV2.quoteExactInputSingle.selector,
                params[i]
            );

            (bool success, bytes memory result) = quoteV2Address.staticcall(callData);
            if (success) {
                (
                    uint256 amountOut,
                    uint160 sqrtPriceX96After,
                    uint32 initializedTicksCrossed,
                    uint256 gasEstimate
                ) = abi.decode(result, (uint256, uint160, uint32, uint256));
                resultList[i] = QuoteExactInputSingleMulRes(amountOut, sqrtPriceX96After, initializedTicksCrossed, gasEstimate);
            } else {
                revert(string(abi.encodePacked("staticcall failed at index ", Strings.toString(i))));
            }
        }

        return resultList;
    }

    // 3. quoteExactOutput 多路调用
    function quoteExactOutputMul(address quoteV2Address, QuoteExactOutputMulParam[] calldata params) external view returns (QuoteExactOutputMulRes[] memory) {
        uint len = params.length;
        QuoteExactOutputMulRes[] memory resultList = new QuoteExactOutputMulRes[](len);

        for (uint i = 0; i < len; i++) {
            bytes memory callData = abi.encodeWithSelector(
                IQuoterV2.quoteExactOutput.selector,
                params[i].path,
                params[i].amountOut
            );

            (bool success, bytes memory result) = quoteV2Address.staticcall(callData);
            if (success) {
                (
                    uint256 amountIn,
                    uint160[] memory sqrtPriceX96AfterList,
                    uint32[] memory initializedTicksCrossedList,
                    uint256 gasEstimate
                ) = abi.decode(result, (uint256, uint160[], uint32[], uint256));
                resultList[i] = QuoteExactOutputMulRes(amountIn, sqrtPriceX96AfterList, initializedTicksCrossedList, gasEstimate);
            } else {
                revert(string(abi.encodePacked("staticcall failed at index ", Strings.toString(i))));
            }
        }

        return resultList;
    }

    // 4. quoteExactOutputSingle 多路调用
    function quoteExactOutputSingleMul(address quoteV2Address, IQuoterV2.QuoteExactOutputSingleParams[] calldata params) external view returns (QuoteExactOutputSingleMulRes[] memory) {
        uint len = params.length;
        QuoteExactOutputSingleMulRes[] memory resultList = new QuoteExactOutputSingleMulRes[](len);

        for (uint i = 0; i < len; i++) {
            bytes memory callData = abi.encodeWithSelector(
                IQuoterV2.quoteExactOutputSingle.selector,
                params[i]
            );

            (bool success, bytes memory result) = quoteV2Address.staticcall(callData);
            if (success) {
                (
                    uint256 amountIn,
                    uint160 sqrtPriceX96After,
                    uint32 initializedTicksCrossed,
                    uint256 gasEstimate
                ) = abi.decode(result, (uint256, uint160, uint32, uint256));
                resultList[i] = QuoteExactOutputSingleMulRes(amountIn, sqrtPriceX96After, initializedTicksCrossed, gasEstimate);
            } else {
                revert(string(abi.encodePacked("staticcall failed at index ", Strings.toString(i))));
            }
        }

        return resultList;
    }
}
contract PriceTest {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    function getSqrtRatioAtTick(int24 tick) public pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) public pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

interface INonfungiblePositionManager {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}