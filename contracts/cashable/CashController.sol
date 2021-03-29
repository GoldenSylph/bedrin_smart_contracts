pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./lib/CashLib.sol";

contract CashController is Ownable {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;


    function balanceOf(address _cashClone, address _token) external {

    }

    function withdraw(address _cashClone, address _token) external {

    }

    function earn(address _cashClone, address _token) external {

    }

}
