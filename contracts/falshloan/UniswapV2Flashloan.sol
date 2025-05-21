// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// UniswapV2闪电贷回调接口
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
// UniswapV2闪电贷合约
// 1. 没有找到Sepolia环境的DAI合约地址
// 2. 没有发现有WET并且有储存量的UniswapV2Pairs
contract UniswapV2FlashLoan is IUniswapV2Callee {
    address public constant UNISWAP_V2_FACTORY = 0xF62c03E08ada871A0bEb309762E260a7a6a880E6;
    address public constant UNISWAP_V2_ROUTER02 = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3;
    // 没有找到Sepolia环境的DAI合约地址
    address public constant DAI = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3;
    address public constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    WETH9 private constant weth9 = WETH9(WETH);
    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
    IUniswapV2Pair private immutable pair;
    // 初始化 WETH-DAI UniswapV2Pair合约地址
    constructor() {
        pair = IUniswapV2Pair(factory.getPair(WETH, DAI));
    }
    // 闪电贷函数
    function flashloan(uint256 wethAmount) external {
        // 构建data: data.length > 0触发闪电贷回调
        // UniswapV2Pair.sol: 
        //  if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        bytes memory data = abi.encode(WETH, wethAmount);
        // 参数分别是：借出的token0数量，借出的token1数量，代币接收者，data数据
        pair.swap(0, wethAmount, address(this), data);

    }
    // 闪电贷回调接口
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        // checks
        // 确认发起者是本合约
        require(sender == address(this), "uniswapV2Call: sender error");
        // 确认调用者是DAI-WETH pair合约
        address pairAddress = msg.sender;
        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();
        require(factory.getPair(token0, token1) == pairAddress, "uniswapV2Call: msgSender error");
        // 校验data
        // 解码data
        (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));
        require(tokenBorrow == WETH, "uniswapV2Call: borrow token type error");

        // weth资金使用逻辑....

        // 计算flashloan费用：0.3%
        /* swap()源码中关于手续费计算逻辑: 
        // token0当前余额 * 1000 - token0返还金额*3 : balance0*1000 - amount0In*3 == (balance0-amount0In*0.003)*1000
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        // token1当前余额 * 1000 - token0返还金额*3: (balance1-amount0In*0.003)*1000
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        // 由于balance0Adjusted=(balance0-amount0In*0.003)*1000，balance1Adjusted=balance1.mul(1000).sub(amount1In.mul(3));
        // 所以需要： balance0Adjusted*balance1Adjusted >= _reserve0*_reserve1*1000*1000
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        */
        // 由于手续费计算是按照返还金额计算的，不是按借出金额，所以设借出金额为x，fee为y:  
        /*
        y/(x+y) = 3/1000,求y的计算公式？
            1000y/(x+y) = 3
            1000y = 3x + 3y
            997y = 3x
            y = 3x/997
            向上取整：y = 3x/997 +1
        即 fee = (amount*3)/997 + 1
        */
        uint256 fee = (amount1 * 3) / 997 + 1;
        uint256 amountToRepay = amount1+fee;
        // 归还闪电贷
        weth9.transfer(address(pair), amountToRepay);

        
    }
}

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}
// 查找WETHPairs: 找不到有weth的pairs
contract Test {
    address public fatoryAddress = 0xF62c03E08ada871A0bEb309762E260a7a6a880E6;
    address public wethAddress = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    function searchWETPairs() external view returns (
        // weth总储备量
        uint256[] memory, 
        // pair另一种代币地址
        address[] memory
    ) {
        uint256 length = IUniswapV2Factory(fatoryAddress).allPairsLength();
        uint256[] memory wethAmounts = new uint256[](length);
        address[] memory tokens = new address[](length);
        uint256 cursor;
        for (uint256 i=0; i< length; i++) {
            address pairAddress = IUniswapV2Factory(fatoryAddress).allPairs(i);
            address token0 = IUniswapV2Pair(pairAddress).token0();
            address token1 = IUniswapV2Pair(pairAddress).token1();
            if (token0 == wethAddress || token1 == wethAddress) {
                    // function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
                (uint112 reserve0, uint112 reserve1,  ) = IUniswapV2Pair(pairAddress).getReserves();
                if (reserve0 != 0 && reserve1!=0) {
                    if (token0 == wethAddress) {
                        // token0是weth
                        wethAmounts[cursor] = reserve0;
                        tokens[cursor] = token1;
                    }else {
                        // token1是weth
                        wethAmounts[cursor] = reserve1;
                        tokens[cursor] = token0;
                    }
                    cursor++;
                }
            }
        }
    }
}

// uniswapV2 Pair
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    /* swap源码
    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        // 借款金额校验
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        // 资金总储存量
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        // 校验借款金额 < 储存量
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        // 借款方校验：不可以是代币对任何一方合约
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        
        // 借款金额转账给to
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens

        // 借款方回调（可以作为flashloan替代方案）
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);

        // flashloan完成后的token0代币余额
        // 闪电贷回调返还后的token0余额
        balance0 = IERC20(_token0).balanceOf(address(this));
        // 闪电贷返还后的token1余额
        balance1 = IERC20(_token1).balanceOf(address(this));
        }

        // _reserve0 - amount0Out: 借款转账前的token0储备金额 - 借款金额 = 借款后的token0储备剩余金额
        // balance0 - (_reserve0 - amount0Out): 闪电贷完成后的token0余额 - 借款后token0储备剩余 = token0闪电贷返回金额
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        // token1闪电贷返还金额
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

        // 返还金额校验: 返还金额不能为0
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        // token0当前余额 * 1000 - token0返还金额*3 : balance0*1000 - amount0In*3 == (balance0-amount0In*0.003)*1000
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        // token1当前余额 * 1000 - token0返还金额*3: (balance1-amount0In*0.003)*1000
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        // 由于balance0Adjusted=(balance0-amount0In*0.003)*1000，balance1Adjusted=balance1.mul(1000).sub(amount1In.mul(3));
        // 所以需要： balance0Adjusted*balance1Adjusted >= _reserve0*_reserve1*1000*1000
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }
        // 更新代币储备量
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
    */
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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