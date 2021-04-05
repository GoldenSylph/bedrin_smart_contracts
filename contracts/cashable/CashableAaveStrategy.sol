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

import "./lib/CashLib.sol";
import "./CashMachine.sol";

contract CashableAaveStrategy is Ownable, Initializable, ICashableStrategy {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    modifier onlyCashMachineClone(address _cashMachineClone) {
        require(_msgSender() == _cashMachineClone, "!senderCashMachine");
        require(_cashMachineClone.isContract(), "!contract");
        require(IERC165(_cashMachineClone).supportsInterface(CashLib.MACHINE_ERC165), "!cashMachine");
        require(CashMachine(_cashMachineClone).strategy() == address(this), "!strategy");
        _;
    }

    // cash machine => token
    mapping(address => address) public tokens;

    // cash machine => token
    mapping(address => uint256) public volumes;

    uint256 public totalValue;
    IERC20 public mainAToken;

    function convertToMainAToken(address _toConvert, uint256 _amount) public onlyOwner {

    }

    function convertToMainAToken(uint256 _amount) external onlyOwner {

    }

    function setMainToken() external onlyOwner {

    }

    function cashStrategyName() external pure returns(string memory) {
        return "Cash Aave One AToken Strategy V1"
    }

    function register(address _cashMachine, address _token, uint256 _amount)
        external
        onlyCashMachineClone(_cashMachine)
    {
        tokens[_cashMachine] = _token;
        volumes[_cashMachine] = _amount;
        totalValue = totalValue.add(_amount);
        convertToMainAToken(_token, _amount);

    }

    function withdraw(address _cashMachine, address _token, uint256 _amount)
        external
        onlyCashMachineClone(_cashMachine)
    {
        (,totalValue) = totalValue.trySub(_amount);
    }

    function cashStrategyName() external pure returns(string memory) {
        return "Aave Cash Machine Strategy";
    }

    // function getRevenue() public view returns(uint256 revenue) {
    //     if (token != CashLib.ETH) {
    //         revenue = IERC20(token).balanceOf(address(this)).trySub(sumOfNominals);
    //     } else {
    //         revenue = address(this).balance.trySub(sumOfNominals);
    //     }
    // }
    //
    // function harvest() external onlyTeam {
    //     uint256 revenue = getRevenue();
    //     if (revenue > 0) {
    //       if (token != CashLib.ETH) {
    //           IERC20(token).safeTransfer(team, revenue);
    //       } else {
    //           team.sendValue(revenue);
    //       }
    //     }
    //     emit Operation(token, revenue, false);
    // }

    // using EnumerableSet for EnumerableSet.AddressSet;
    //

    // EnumerableSet.AddressSet public cashClones;
    //
    // function balanceOf(address _cashClone) external view onlyCashClone(_cashClone) returns(uint256) {
    //
    // }
    //
    // function withdraw(address _cashClone) external onlyCashClone(_cashClone) {
    //
    // }
    //
    // function earn(address _cashClone) external onlyCashClone(_cashClone) {
    //
    // }
    //
    // function getNominalOf(uint256 _idx) public view returns(uint256) {
    //     return Cash(cashClones.at(_idx)).nominal;
    // }
    //
    // function getTokenOf(uint256 _idx) public view returns(address) {
    //     return Cash(cashClones.at(_idx)).token;
    // }
    //
    // function getVolume(address _token) public view returns(uint256) {
    //     uint256 sum = 0;
    //     for (uint256 i = 0; i < cashClones.length(); i++) {
    //         Cash cash = Cash(cashClones.at(i));
    //         if (cash.token == _token) {
    //             sum += cash.nominal;
    //         }
    //     }
    //     return sum;
    // }

}
