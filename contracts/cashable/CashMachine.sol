// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.3;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol"
import "@openzeppelin/contracts/introspection/ERC165.sol"

import "./lib/CashLib.sol";
import "./utils/FundsEvacuator.sol";
import "./interfaces/ICashMachine.sol";

contract CashMachine is Initializable, FundsEvacuator, ERC165, ICashMachine  {

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  using CashLib.CashSet for CashLib.Cash;

  address public token;
  CashLib.CashSet public cashPile;
  address public team;
  address public strategy;
  address public cashMachineFactory;

  event Operation(address indexed _token, uint256 indexed _amount, bool earnOrHarvest);

  modifier onlyCashMachineFactory {
      require(msg.sender.isContract(), "!contract");
      require(IERC165(msg.sender).supportsInterface(CashLib.FACTORY_ERC165), "!cashMachineFactory");
      _;
  }

  modifier onlyTeam {
      require(msg.sender == team, "!team");
      _;
  }

  function cashMachineName() external pure returns(string memory) {
      return "Cash Machine V1";
  }

  function configure(
      address _token,
      address _team,
      address _strategy,
      address _cashMachineFactory,
      uint256[] memory _nominals,
      address[] memory _holders
  ) external initializer onlyCashMachineFactory {
      require(_nominals.length == _holders.length, "!lengths");
      token = _token;
      team = _team;
      strategy = _strategy;
      cashMachineFactory = _cashMachineFactory;
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

  function burn(address payable _to, uint256 _id) external {
      require(cashPile.atHolder(_id) == _msgSender(), "onlyHolder");
      uint256 nominal = cashPile.atNominal(_id);
      IStrategy(strategy).withdraw(address(this), nominal);

      IERC20 tokenErc20 = IERC20(token);
      if (token != CashLib.ETH) {
          tokenErc20.safeTransfer(to, nominal);
      } else {
          to.sendValue(nominal);
      }
      require(cashPile.removeAt(_id), '!removed');

      // impossible case, but if some fund are stuck in there - they are sent to team address, to further return or reinvest
      if (cashPile.length() == 0) {
          if (token != CashLib.ETH) {
              tokenErc20.safeTransfer(team, tokenErc20.balanceOf(address(this)));
          }
          selfdestruct(team);
      }
  }

  function supportsInterface(bytes4 interfaceId) public view override returns(bool) {
      return interfaceId == 0x01ffc9a7
        || interfaceId == CashLib.MACHINE_ERC165;
  }

  fallback() external {
      revert("NoFallback");
  }

  receive() external {}

}
