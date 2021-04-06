// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;


interface ICashableStrategy {
  function register(address _cashMachine, address _token, uint256 _amount) external;
  function withdraw(address _cashMachine, address _token, uint256 _amount) external;
  function cashStrategyName() external pure returns(string memory);
}
