// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.3;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./lib/CashLib.sol";
import "./utils/FundsEvacuator.sol";

contract CashMachine is Initializable, FundsEvacuator {

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  using CashLib.CashSet for CashLib.Cash;

  address public token;
  CashLib.CashSet public cashPile;
  address public team;

  event ReceivedToken(address indexed token);

  modifier onlyCashMachineFactory {
      require(msg.sender == address(0), "!cashMachineFactory");
      _;
  }

  modifier onlyTeam {
      require(msg.sender == team, "!team");
      _;
  }

  function configure(
    address _token,
    address _team,
    uint256[] memory _nominals,
    address[] memory _holders,
  ) external initializer onlyCashMachineFactory {
      require(_nominals.length == _holders.length, "!lengths");
      token = _token;
      team = _team;
      _setEvacuator(team, false);
      _setTokenToStay(_token);
      for (uint256 i = 0; i < _nominals.length; i++) {
          cashPile.add(
            CashLib.Cash({
                id: i,
                holder: _holders[i],
                nominal: _nominals[i]
            })
          );
      }
  }

  function earn() external onlyCashMachineFactory {
      if (token != CashLib.ETH) {
          IERC20 tokenErc20 = IERC20(token);
          tokenErc20.safeTransfer(strategy, tokenErc20.balanceOf(address(this)));
      } else {
          strategy.sendValue(address(this).balance);
      }
      emit ReceivedToken(token);
  }

  function burn(address payable _to, uint256 _id) external {
      require(cashPile.atHolder(_id) == _msgSender());
      if (token != CashLib.ETH) {
          IERC20 tokenErc20 = IERC20(token);
          uint256 tokenBalance = tokenErc20.balanceOf(address(this));
          if (tokenBalance > nominal) {
              tokenErc20.safeTransfer(team, tokenBalance.sub(nominal));
          }
          tokenErc20.safeTransfer(to, nominal);
      } else {
        if (address(this).balance > nominal) {
            team.sendValue(address(this).balance.sub(nominal));
        }
      }
      selfdestruct(to);
  }

  fallback() external {
      revert("NoFallback");
  }

  receive() external onlyCashMachineFactory {}

}
