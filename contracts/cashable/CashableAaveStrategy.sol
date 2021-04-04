// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.3;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./lib/CashLib.sol";
import "./Cash.sol";

contract CashableAaveStrategy is Ownable, ICashableStrategy {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    function cashStrategyName() external pure returns(string memory) {
        return "Cash Aave Strategy V1"
    }

    function getRevenue() public view returns(uint256 revenue) {
        if (token != CashLib.ETH) {
            revenue = IERC20(token).balanceOf(address(this)).trySub(sumOfNominals);
        } else {
            revenue = address(this).balance.trySub(sumOfNominals);
        }
    }

    function harvest() external onlyTeam {
        uint256 revenue = getRevenue();
        if (revenue > 0) {
          if (token != CashLib.ETH) {
              IERC20(token).safeTransfer(team, revenue);
          } else {
              team.sendValue(revenue);
          }
        }
        emit Operation(token, revenue, false);
    }

    // using EnumerableSet for EnumerableSet.AddressSet;
    //
    // modifier onlyCashClone(address _cashClone) {
    //   require(_cashClone.isContract(), "!contract");
    //   require(msg.sender == _cashClone, "!cashClone");
    //   _;
    // }

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
