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
import "./Cash.sol";

contract CashController is Ownable {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    modifier onlyCashClone(address _cashClone) {
      require(_cashClone.isContract(), "!contract");
      require(msg.sender == _cashClone, "!cashClone");
      _;
    }

    // cashClone => strategy
    mapping(address => address) public strategies;

    function balanceOf(address _cashClone) external view onlyCashClone(_cashClone) returns(uint256) {
        return IStrategy(strategies[_cashClone]).balanceOf(Cash(_cashClone).token);
    }

    function _withdrawAndSend(address _cashClone, address _to) internal {
      Cash cashContract = Cash(_cashClone);
      uint256 withdrawn = IStrategy(strategies[_cashClone]).withdraw(_cashClone);
      if (cashContract.token == CashLib.ETH) {
        _to.sendValue(withdrawn);
      } else {
        IERC20(cashContract.token).safeTransfer(_to, withdrawn);
      }
    }

    function withdraw(address _cashClone) external onlyCashClone(_cashClone) {
        _withdrawAndSend(_cashClone, _cashClone);
    }

    function earn(address _cashClone) external onlyCashClone(_cashClone) {
      Cash cashContract = Cash(_cashClone);
      address strategy = strategies[_cashClone];
      if (cashContract.token == CashLib.ETH) {
          strategy.sendValue(cashContract.nominal);
      } else {
          IERC20(cashContract.token).safeTransfer(strategy, cashContract.nominal);
      }
      IStrategy(strategy).earn(_cashClone);
    }

    function setStrategy(address _cashClone, address _strategy) external onlyOwner {
        _withdrawAndSend(_cashClone, _strategy);
        strategies[_cashClone] = _strategy;
        IStrategy(_strategy).earn(_cashClone);
    }

}
