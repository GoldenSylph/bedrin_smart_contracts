// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";

import "./lib/CashLib.sol";
import "./CashMachine.sol";
import "./interfaces/third_party/ILendingPool.sol";

contract CashableAaveStrategy is Ownable, Initializable, ICashableStrategy {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint16 public constant AAVE_REFERRAL_CODE = ...;

    // cash machine => token
    mapping(address => address) public tokens;

    // cash machine => token
    mapping(address => uint256) public volumes;

    uint256 public totalValue;
    IERC20 public mainAToken;
    UniswapV2Router02 public uniswapRouter;
    ILendingPool public aaveLendingPool;

    EnumerableSet.AddressSet public cashMachines;

    modifier onlyCashMachineClone(address _cashMachineClone) {
        require(_msgSender() == _cashMachineClone, "!senderCashMachine");
        require(_cashMachineClone.isContract(), "!contract");
        require(IERC165(_cashMachineClone).supportsInterface(CashLib.MACHINE_ERC165), "!cashMachine");
        require(CashMachine(_cashMachineClone).strategy() == address(this), "!strategy");
        _;
    }

    function cashStrategyName() external pure returns(string memory) {
        return "Cash Aave One AToken Strategy V1"
    }

    function cashMachineAt(uint256 index) external view returns(address) {
        return cashMachines.at(index);
    }

    function cashMachinesLength() external view returns(uint256) {
        return cashMachines.length();
    }

    function convertUniswap(address _tokenIn, address _tokenOut, uint256 _amount) internal returns(uint256 amountOut) {
        require(IERC20(_token).approve(address(uniswapRouter), _amount), '!uniswapApprove');
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint256[] _amountsOut = UniswapV2Router02.getAmountsOut(_amount, path);
        amountOut = _amountsOut[1];
        if (_tokenIn != CashLib.ETH && _tokenOut == CashLib.ETH) {
            UniswapV2Router02.swapExactTokensForETH(_amount, amountOut, path, msg.sender, block.timestamp);
        } else if (_tokenIn == CashLib.ETH && _tokenOut != CashLib.ETH) {
            UniswapV2Router02.swapExactETHForTokens(_amount, amountOut, path, msg.sender, block.timestamp);
        } else if (_tokenIn != CashLib.ETH && _tokenOut != CashLib.ETH && _tokenIn != _tokenOut) {
            UniswapV2Router02.swapExactTokensForTokens(_amount, amountOut, path, msg.sender, block.timestamp);
        } else {
            revert("sameTokens");
        }
    }

    function register(address _cashMachine, address _token, uint256 _amount)
        external
        onlyCashMachineClone(_cashMachine)
    {
        cashMachines.add(_cashMachine);
        tokens[_cashMachine] = _token;
        volumes[_cashMachine] = _amount;

        uint256 convertedAmount = ...;
        totalValue = totalValue.add(convertedAmount);
    }

    function withdraw(address _cashMachine, uint256 _amount)
        external
        onlyCashMachineClone(_cashMachine)
    {
        uint256 volume = volumes[_cashMachine];
        address token = tokens[_cashMachine];

        if (token != CashLib.ETH) {
            IERC20(token).safeTransfer(_cashMachine, _amount);
        } else {
            _cashMachine.sendValue(volume);
        }
        (,volumes[_cashMachine]) = volume.trySub(_amount);
        if (volumes[_cashMachine] == 0) {
            cashMachines.remove(_cashMachine);
        }
        (,totalValue) = totalValue.trySub(_amount);
    }

    function cashStrategyName() external pure returns(string memory) {
        return "Aave Cash Machine Strategy";
    }

}
