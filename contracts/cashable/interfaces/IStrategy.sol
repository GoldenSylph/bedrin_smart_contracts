// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.3;


interface IStrategy {
  function register(address _cashMachine, address _token, uint256 _amount) external;
  function withdraw(address _cashMachine, address _token, uint256 _amount) external;

}
