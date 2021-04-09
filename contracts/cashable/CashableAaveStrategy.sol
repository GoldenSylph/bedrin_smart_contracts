// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";

import "./lib/CashLib.sol";
import "./CashMachine.sol";
import "./interfaces/third_party/aave/ILendingPool.sol";

contract CashableAaveStrategy is Ownable, Initializable, AccessControlEnumerable, ICashableStrategy {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint16 public constant AAVE_REFERRAL_CODE = 96;
    bytes32 public constant CASH_MACHINE_CLONE_ROLE = keccak256("CASH_MACHINE_CLONE_ROLE");

    // cash machine => token
    mapping(address => address) public tokens;

    // cash machine => volume
    mapping(address => uint256) public volumes;

    uint256 public totalAmountOfMainTokens;

    IERC20 public mainToken;
    IERC20 public mainAToken;
    UniswapV2Router02 public uniswapRouter;
    ILendingPool public aaveLendingPool;
    address public cashMachineFactory;

    modifier onlyCashMachineClone {
        require(hasRole(CASH_MACHINE_CLONE_ROLE, _msgSender()), "!senderCashMachine");
        _;
    }

    modifier onlyCashMachineFactory {
        require(_msgSender() == cashMachineFactory, "!senderCashMachineFactory");
        _;
    }

    modifier onlyOwnerOrSelf {
        address sender = _msgSender();
        require(sender == owner() || sender == address(this), "!owner|self");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
    }

    function configure(
      address _mainToken,
      address _mainAToken,
      address _uniswapRouter,
      address _aaveLendingPool,
      address _cashMachineFactory
    ) external initializer {
        mainToken = IERC20(_mainToken);
        mainAToken = IERC20(_mainAToken);
        uniswapRouter = UniswapV2Router02(_uniswapRouter);
        aaveLendingPool = ILendingPool(_aaveLendingPool);
        cashMachineFactory = _cashMachineFactory;
    }

    function _getAmountOut(address _from, address _to, uint256 _amount) internal returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        uint256[] _amountsOut = UniswapV2Router02.getAmountsOut(_amount, path);
        return _amountsOut[1];
    }

    function _convertUniswap(address _tokenIn, address _tokenOut, uint256 _amount) internal returns(uint256 amountOut) {
        if (_tokenIn != _tokenOut) {
            require(IERC20(_token).approve(address(uniswapRouter), _amount), '!uniswapApprove');
            amountOut = _getAmountOut(_tokenIn, _tokenOut, _amount);
            if (_tokenIn != CashLib.ETH && _tokenOut == CashLib.ETH) {
                UniswapV2Router02.swapExactTokensForETH(_amount, amountOut, path, msg.sender, block.timestamp);
            } else if (_tokenIn == CashLib.ETH && _tokenOut != CashLib.ETH) {
                UniswapV2Router02.swapExactETHForTokens{value: _amount}(_amount, amountOut, path, msg.sender, block.timestamp);
            } else {
                UniswapV2Router02.swapExactTokensForTokens(_amount, amountOut, path, msg.sender, block.timestamp);
            }
        } else {
            amountOut = _amount;
        }
    }

    function register(address _cashMachine, address _token, uint256 _amount)
        external
        onlyCashMachineFactory
    {
        grantRole(CASH_MACHINE_CLONE_ROLE, _cashMachine);
        tokens[_cashMachine] = _token;
        volumes[_cashMachine] = _amount;
        address mainTokenAddress = address(mainToken);
        uint256 amountInMainTokens = _convertUniswap(_token, mainTokenAddress, _amount);
        mainToken.approve(address(aaveLendingPool), amountInMainTokens);
        aaveLendingPool.deposit(mainTokenAddress, amountInMainTokens, address(this), AAVE_REFERRAL_CODE);
        totalAmountOfMainTokens = totalAmountOfMainTokens.add(amountInMainTokens);
    }

    function harvest() public onlyOwnerOrSelf {
        uint256 aMainTokenBalance = mainAToken.balanceOf(address(this));
        if (aMainTokenBalance > totalValue) {
            mainAToken.safeTransfer(owner(), aMainTokenBalance.sub(totalAmountOfMainTokens));
        }
    }

    function withdraw(uint256 _amount)
        external
        onlyCashMachineClone
    {
        address sender = _msgSender();
        uint256 volume = volumes[sender];
        address token = tokens[sender];
        address mainTokenAddress = address(mainToken);

        uint256 amountInMainTokens = _getAmountOut(token, mainTokenAddress, _amount);

        mainAToken.approve(address(aaveLendingPool), amountInMainTokens);
        aaveLendingPool.withdraw(mainTokenAddress, amountInMainTokens, address(this));

        uint256 amountInTokens = _convertUniswap(mainTokenAddress, token, amountInMainTokens);

        if (token != CashLib.ETH) {
            IERC20(token).safeTransfer(sender, amountInTokens);
        } else {
            sender.sendValue(amountInTokens);
        }

        (,totalAmountOfMainTokens) = totalAmountOfMainTokens.trySub(amountInMainTokens);

        (,volumes[sender]) = volume.trySub(amountInTokens);
        if (volumes[sender] == 0) {
            revokeRole(CASH_MACHINE_CLONE_ROLE, sender);
        }
        harvest();
    }

}
