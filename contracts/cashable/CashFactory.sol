pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Cash.sol";

contract CashFactory is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event CashMinted(address _cashClone, address _cashMain);

    address public cashImpl;
    address public controller;

    constructor(address _cashImpl, address _controller) external {
        cashImpl = _cashImpl;
        controller = _controller;
    }

    function setCashImpl(address _cashImpl) external onlyOwner {
        cashImpl = _cashImpl;
    }

    function setController(address _controller) external onlyOwner {
        controller = _controller;
    }

    function predictCashAddress(bytes32 _salt)
        external
        view
        returns(address)
    {
        return Clones.predictDeterministicAddress(cashImpl, _salt);
    }

    function mintCash(
        bytes32 _salt,
        address _token,
        address _holder,
        uint256 _nominal
    ) external nonReentrant {

        address sender = _msgSender();
        require(sender != _holder, "holder==sender");
        require(!_holder.isContract(), "holderIsContract");

        address _result = Clones.cloneDeterministic(cashImpl, _salt);

        Cash cashContract = Cash(_result);
        cashContract.configure(_holder, _token, _nominal, owner(), controller);

        if (_token != CashLib.ETH) {
          require(IERC20(_token).allowance(sender, _result) >= _nominal, "!nominalToken");
          IERC20(_token).safeTransferFrom(sender, _result, _nominal);
        } else {
          require(msg.value >= _nominal, "!nominalEth");
          _result.sendValue(_nominal);
          if (msg.value > _nominal) {
            sender.sendValue(msg.value.sub(_nominal));
          }
        }

        cashContract.transferOwnership(_holder);
        cashContract.earn();
        emit CashMinted(_result, cashImpl);
    }

}
