pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./CashController.sol";
import "./lib/CashLib.sol";


contract Cash is Ownable, Initializable {

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address payable public holder;
  address public token;
  address public nominal;
  address public team;
  address public controller;

  event ReceivedToken(address indexed token);

  modifier onlyCashFactory {
      require(msg.sender == address(0), "!cashFactory");
      _;
  }

  modifier onlyHolder {
      require(msg.sender == holder, "!holder");
      _;
  }

  modifier onlyTeam {
    require(msg.sender == team, "!team");
    _;
  }

  function configure(
    address _holder,
    address _token,
    address _nominal,
    address _team,
    address _controller
  ) external initializer onlyCashFactory {
      holder = _holder;
      token = _token;
      nominal = _nominal;
      team = _team;
      controller = _controller;
  }

  function evacuate(address _otherToken, address _to) external onlyTeam {
      require(token != _otherToken, "=token");
      IERC20(_otherToken).transfer(_to);
  }

  function earn() external onlyCashFactory {
      if (token != CashLib.ETH) {
          IERC20 tokenErc20 = IERC20(token);
          tokenErc20.transfer(controller, tokenErc20.balanceOf(address(this)));
      } else {
          controller.sendValue(address(this).balance);
      }
      CashController(controller).earn(address(this), token);
      emit ReceivedToken(token);
  }

  function burn(address payable to) external onlyHolder {
      CashController(controller).withdraw(address(this), token);
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

  receive() external onlyCashFactory {}

}
