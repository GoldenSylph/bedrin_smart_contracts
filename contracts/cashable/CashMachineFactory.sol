// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.3;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol"

import "./CashMachine.sol";
import "./utils/FundsEvacuator.sol";

contract CashMachineFactory is Ownable, ReentrancyGuard, FundsEvacuator, ERC165 {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event CashMachineCreated(address _cashMachineClone, address _cashMachineMain);

    address public cashMachineImpl;
    address public defaultStrategy;

    constructor(address _cashMachineImpl, address _defaultStrategy) external {
        cashMachineImpl = _cashMachineImpl;
        _setEvacuator(owner(), true);
        defaultStrategy = _defaultStrategy;
        _registerInterface(...);
    }

    function setCashMachineImpl(address _cashMachineImpl) external onlyOwner {
        cashMachineImpl = _cashMachineImpl;
    }

    function setDefaultStrategy(address _defaultStrategy) external onlyOwner {
        defaultStrategy = _defaultStrategy;
    }

    function predictCashAddress(bytes32 _salt)
        external
        view
        returns(address)
    {
        return Clones.predictDeterministicAddress(cashMachineImpl, _salt);
    }

    function mintCash(
        bytes32 _salt,
        address _token,
        address[] memory _holders,
        uint256[] memory _nominals
    ) external nonReentrant {
        require(_nominals.length == _holders.length, "!lengths");

        address sender = _msgSender();
        uint256 nominalsSum = 0;

        for (uint256 i; i < _holders.length; i++) {
            require(sender != _holders[i], "holder==sender");
            require(!_holders[i].isContract(), "holderIsContract");
            nominalsSum += _nominals[i];
        }

        address result = Clones.cloneDeterministic(cashMachineImpl, _salt);

        CashMachine cashMachine = CashMachine(result);
        cashMachine.configure(
            _token,
            owner(),
            defaultStrategy,
            address(this);
            _nominals,
            _holders
        );

        if (_token != CashLib.ETH) {
            IERC20(_token).safeTransferFrom(sender, result, nominalsSum);
        } else {
            require(msg.value >= nominalsSum, "!nominalEth");
            result.sendValue(nominalsSum);
        }

        cashMachine.earn();
        emit CashMachineCreated(result, cashMachineImpl);
    }

}
