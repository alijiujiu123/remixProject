// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/IUniswapV3Pool.sol";
// import "https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol";
// import "https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol";
// UniswapV3闪电贷回调接口
interface IUniswapV3FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IUniswapV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#flash call
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}
// swapCallback接口定义
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// UniswapV3闪电贷合约: Sepolia测试网
contract UniswapV3Flashloan is IUniswapV3FlashCallback, IUniswapV3SwapCallback {
    // UniswapV3Factory
    // address public constant UNISWAP_V3_FACTORY = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
    // IUniswapV3Factory private constant factory = IUniswapV3Factory(UNISWAP_V3_FACTORY);
    // UNI
    address public constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    IERC20 private constant uni = IERC20(UNI);
    // WETH
    address public constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    WETH9 private constant weth9 = WETH9(WETH);
    
    // USDC
    // address public constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    // IERC20 private constant usdc = IERC20(USDC);
    address public constant UNI_WETH1 = 0x224Cc4e5b50036108C1d862442365054600c260C;
    IUniswapV3Pool public immutable pool1;
    address public constant UNI_WETH2 = 0x287B0e934ed0439E2a7b1d5F0FC25eA2c24b64f7;
    IUniswapV3Pool public immutable pool2;
    address public constant UNI_WETH3 = 0x51aDC79e7760aC5317a0d05e7a64c4f9cB2d4369;
    IUniswapV3Pool public immutable pool3;
    // 闪电贷callback事件
    event FlashCallback(uint256 fee0,uint256 fee1, uint256 wethEarn);
    // swapCallback事件
    event SwapCallback(address poolAddress, string transferToken0Desc, string receiveTokenDesc, int256 amount0Delta,int256 amount1Delta);
    constructor() {
        pool1 = IUniswapV3Pool(UNI_WETH1);
        pool2 = IUniswapV3Pool(UNI_WETH2);
        pool3 = IUniswapV3Pool(UNI_WETH3);
    }
    // 触发借款
    function flashloan(uint amount) external returns (uint256) {
        bytes memory data = abi.encode(UNI_WETH1, amount);
        // 1. 从pool1 借出1 UNI
        pool1.flash(address(this), amount, 0, data);
    }
    // 闪电贷函数回调
    function uniswapV3FlashCallback(
        // token0 fee
        uint256 fee0,
        // token1 fee
        uint256 fee1,
        // data
        bytes calldata data
    ) external {
        // checks
        require(msg.sender == address(pool1), "uniswapV3FlashCallback: not authorized");
        // 解码
        (address poolAddress, uint256 amount) = abi.decode(data, (address, uint256));
        require(poolAddress == UNI_WETH1, "uniswapV3FlashCallback: pool borrow != UNI_WETH1");
        // effects
        // 2. UNI_WETH3: 1 UNI => 28.9 WETH
        /*
        function swap(
            // 接收者
            address recipient,
            // 交易方向：true: token0 -> token1; false: token1 -> token0
            bool zeroForOne,
            // 指定交易类型和大小: 
                // 正数： 固定输入量，最大化输出（支付100 token0，交换尽可能多的token1）
                // 负数： 固定输出量，最小化输入（希望获取5000 token1，支付最少得token0）
            int256 amountSpecified,
            // 价格边界：
                // 非0：
                    // zeroForOne=true(卖出tokne0)，价格下限，交易价格不能低于sqrtPriceLimitX96
                    // zeroForOne=false(卖出tokne1)，价格上限，交易价格不能高于sqrtPriceLimitX96
                // 0: 无价格限制
            uint160 sqrtPriceLimitX96,
            // 传递给uniswapV3SwapCallback的数据
            bytes calldata data
        ) external override noDelegateCall returns (int256 amount0, int256 amount1)
        */
        bytes memory pool3SwapData = abi.encode("UNI", "WETH", amount);
        pool3.swap(address(this), true, int256(amount), 0, pool3SwapData);
        // **************pool3回调swapCallback(转账给pool3 amount UNI)*******************

        // 3. UNI_WETH2: 22.9 WETH => 1 UNI （剩余28.9 - 22.9 = 6 WETH）
        bytes memory pool2SwapData = abi.encode("WETH", "UNI", amount);
        // flashloan解出来待还的UNI
        uint256 needRebackUNIAmount = fee0 + amount;
        // zeroForOne=false: WETH -> UNI
        // amountSpecified: 希望获取needRebackUNIAmount UNI，支付最少得WETH
        pool2.swap(address(this), false, 0-int256(needRebackUNIAmount), 0, pool2SwapData);
        // **************pool2回调swapCallback(转账给pool2 needRebackUNIAmount WETH)*******************

        // 4. UNI_WETH1: 还款1 UNI+fee
        uni.transfer(msg.sender, needRebackUNIAmount);
        // 5. 将WETH 转账给用户
        uint wethBalance = weth9.balanceOf(address(this));
        if (wethBalance > 0) {
            address recipient = 0x4320c101a2A26447F14f3Da29969A0FAF0eD59B0;
            weth9.transfer(recipient, wethBalance);
        }
        emit FlashCallback(fee0, fee1, wethBalance);
        // 6. 将ETH 转账给 用户 
        // if (address(this).balance > 0) {
        //     address recipient = 0x4320c101a2A26447F14f3Da29969A0FAF0eD59B0;
        //    (bool success, ) = recipient.call{value: amount}("");
        // }
    }
    // swap回调: 需要在这里把向池子支付的token转账完成
    function uniswapV3SwapCallback(
        // 池子中token0，在本次swap中的净收支: 100 表示用户需要向池子支付100 token0
        int256 amount0Delta,
        // 池子中token1，在本次swap中的净收支: -5000 表示池子已向用户转出5000 token1
        int256 amount1Delta,
        // 传递交易上下文数据
        bytes calldata data
    ) external {
        // bytes memory pool3SwapData = abi.encode("UNI", "WETH", amount);
        require(msg.sender == address(pool3) || msg.sender == address(pool2), "uniswapV3SwapCallback: not authorized");
        (string memory transferToken0Desc, string memory receiveTokenDesc, uint256 amount) = abi.decode(data, (string, string, uint256));
        if (amount0Delta > 0) {
            // 向pool转账UNI
            uni.transfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            // 向合约转账WETH
            weth9.transfer(msg.sender, uint256(amount1Delta));
        }
        emit SwapCallback(msg.sender, transferToken0Desc, receiveTokenDesc, amount0Delta, amount1Delta);
    }
    // 合约资金转账
    function transferTo(address recipient, uint256 amount) external returns (bool) {
        require(address(this).balance >= amount, "transferTo: insuffisient balance");
        (bool success, ) = recipient.call{value: amount}("");
        return success;
    }
    function transferWETHTo(address recipient) external returns (bool) {
        uint wethBalance = weth9.balanceOf(address(this));
        require(wethBalance > 0, "transferTo: insuffisient balance");
        return weth9.transfer(recipient, wethBalance);
    }

}

// IUniswapV3Factory
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

contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function receive() public payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        // Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        // Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        // Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        // Transfer(src, dst, wad);

        return true;
    }
}
contract Test {
    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}
contract TestV3 {
    address public admin;
    address public constant UNISWAP_V3_FACTORY = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
    IUniswapV3Factory private constant factory = IUniswapV3Factory(UNISWAP_V3_FACTORY);
    // EURC
    // 0x08210F9170F89Ab7658F0B5E3fF39b0E03C594D4
    // USDC
    address public constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    IERC20 private constant usdc = IERC20(USDC);
    // WETH
    address public constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    WETH9 private constant weth9 = WETH9(WETH);
    // WETH-USDC pool
    IUniswapV3Pool public immutable pool;
    // 源码：feeAmountTickSpacing[3000] = 60; 计算fee的参数
    uint24 private constant poolFee = 3000;

    address[] public tokenArray;
    mapping(address tokenAddress => string) public tokensDesc;
    uint24[] public feeArray;
    constructor() {
        admin = msg.sender;
        (address poolAddress, , , , ) = getPool(USDC, WETH, poolFee);
        pool = IUniswapV3Pool(poolAddress);
        initTokenArray();
    }
    function getBlockNum() external view returns (uint256) {
        return block.number;
    }
    // 初始化token地址数据
    function initTokenArray() private {
        address WETHAddress = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
        tokenArray.push(WETHAddress);
        tokensDesc[WETHAddress] = "WETH";
        address USDCAddress = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
        tokenArray.push(USDCAddress);
        tokensDesc[USDCAddress] = "USDC";
        address USDT = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;
        tokenArray.push(USDT);
        tokensDesc[USDT] = "USDT";
        address DAI = 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;
        tokenArray.push(DAI);
        tokensDesc[DAI] = "DAI";
        address EURC = 0x08210F9170F89Ab7658F0B5E3fF39b0E03C594D4;
        tokenArray.push(EURC);
        tokensDesc[EURC] = "EURC";
        address LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        tokenArray.push(LINK);
        tokensDesc[LINK] = "LINK";
        address AAVE = 0x88541670E55cC00bEEFD87eB59EDd1b7C511AC9a;
        tokenArray.push(AAVE);
        tokensDesc[AAVE] = "AAVE";
        address UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        tokenArray.push(UNI);
        tokensDesc[UNI] = "UNI";
        address WBTC = 0x29f2D40B0605204364af54EC677bD022dA425d03;
        tokenArray.push(WBTC);
        tokensDesc[WBTC] = "WBTC";
        address MATIC = 0x3fd0A53F4Bf853985a95F4Eb3F9C9FDE1F8e2b53;
        tokenArray.push(MATIC);
        tokensDesc[MATIC] = "MATIC";
        // address SHIB = 0x9f885f12cb3179817324839a035288b0d74d24fa;
        // tokenArray.push(SHIB);
        // tokensDesc[SHIB] = "SHIB";
        address KNC = 0xD701e3e1A327d13564ba072e6C0806129Fea4671;
        tokenArray.push(KNC);
        tokensDesc[KNC] = "KNC";
        feeArray.push(500);
        feeArray.push(3000);
        feeArray.push(10000);
    }
    modifier onlyAdmin() {
        require(msg.sender == admin, "access control");
        _;
    }
    // 根据_token0, _token1, fee查询UniswapV3Pool信息
    function getPool(address _token0, address _token1, uint24 fee) public view returns (
        // UniswapV3Pool地址
        address poolAddress,
        // token0地址 
        address token0,
        // token0总储存量 
        uint256 token0Balance, 
        // token1地址
        address token1,
        // token1总储存量 
        uint256 token1Balance
    ) {
        poolAddress = factory.getPool(_token0, _token1, fee);
        token0 = IUniswapV3PoolImmutables(poolAddress).token0();
        token0Balance = IERC20(token0).balanceOf(poolAddress);
        token1 = IUniswapV3PoolImmutables(poolAddress).token1();
        token1Balance = IERC20(token1).balanceOf(poolAddress);
    }

    struct PoolInfo {
        // pool描述: ETH-USDC-fee
        string desc;
        uint24 fee;
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
        bytes errorMsg;
    }
    // event ErrorEvent(string reason);
    // event PanicEvent(uint errorCode);
    // event OtherExceptionEvent(bytes data);
    function batchGetPoolInfo() public view returns (PoolInfo[] memory) {
        uint256 tokenLen = tokenArray.length;
        uint256 feeLen = feeArray.length;
        PoolInfo[] memory poolInfoArray = new PoolInfo[]((tokenLen*(tokenLen-1)/2)*feeLen);
        uint256 poolCount;
        for (uint i=0; i<tokenLen-1; i++) {
            address tokenA = tokenArray[i];
            for (uint j=i+1; j<tokenLen; j++) {
                address tokenB = tokenArray[j];
                for (uint n=0; n<feeLen; n++) {
                    uint24 fee = feeArray[n];
                    try this.getPool(tokenA, tokenB, fee) returns (// UniswapV3Pool地址
                        address poolAddress,
                        // token0地址 
                        address token0,
                        // token0总储存量 
                        uint256 token0Balance, 
                        // token1地址
                        address token1,
                        // token1总储存量 
                        uint256 token1Balance
                    ) {
                        // 写入poolInfoArray
                        poolInfoArray[poolCount].desc = string(
                            abi.encodePacked(
                                tokensDesc[token0],
                                "-",
                                tokensDesc[token1]
                            )
                        );
                        poolInfoArray[poolCount].fee = fee;
                        poolInfoArray[poolCount].poolAddress = poolAddress;
                        poolInfoArray[poolCount].token0 = token0;
                        poolInfoArray[poolCount].token0Balance = token0Balance;
                        poolInfoArray[poolCount].token1 = token1;
                        poolInfoArray[poolCount].token1Balance = token1Balance;
                    }catch Error(string memory reason) {
                        // emit ErrorEvent(reason);
                        poolInfoArray[poolCount].errorMsg = abi.encode(reason);
                    }catch Panic(uint errorCode) {
                        // emit PanicEvent(errorCode);
                        poolInfoArray[poolCount].errorMsg = abi.encode(errorCode);
                    }catch (bytes memory lowLevelData) {
                        // emit OtherExceptionEvent(lowLevelData);
                        poolInfoArray[poolCount].errorMsg = lowLevelData;
                    }
                    poolCount++;
                }
            }
        }
        return poolInfoArray;
    }

    // 查询代币金额
    function batchBalanceOf(address[] memory tokens, address[] memory owners) public view returns (uint256[] memory) {
        uint256 length = tokens.length;
        require(length > 0, "batchBalanceOf: empty error");
        require(length == owners.length, "batchBalanceOf: length different");
        uint256[] memory amounts = new uint256[](length);
        for (uint i=0; i< length; i++) {
            amounts[i] = IERC20(tokens[i]).balanceOf(owners[i]);
        }
        return amounts;
    }

    // 交换：USDC交换WETH
    function swapUSDC2WETH(int256 amount, address receiver) public onlyAdmin returns (int256 amount0, int256 amount1) {
        // zeroForOne如果是 true，表示用 token0 换 token1
        bool zeroForOne = true;
        (amount0, amount1) = pool.swap(receiver, zeroForOne, amount, uint160(0), new bytes(0));
    }
    // 将WETH转给指定地址: 万一把WETH搞到合约来，就没办法提现了
    function transferWETH(uint256 amount, address receiver) public onlyAdmin {
        weth9.transfer(receiver, amount);
    }
    function transferUSDC(uint256 amount, address receiver) public onlyAdmin {
        usdc.transfer(receiver, amount);
    }

    function searchWETPairs() external view returns (address poolAddress, uint256 balance0, uint256 balance1) {

    }
}

// USDC源码
contract AdminUpgradeabilityProxy {
    function admin() external view returns (address) {
        // return _admin();
    }

    /**
     * @return The address of the implementation.
     */
    function implementation() external view returns (address) {
        // return _implementation();
    }
}