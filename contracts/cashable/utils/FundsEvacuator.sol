// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.3;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FundsEvacuator {
    using SafeERC20 for IERC20;

    address public evacuator;
    bool public anyToken;
    address public tokenToStay;

    modifier onlyEvacuator {
        require(msg.sender == evacuator, "!evacuator");
        _;
    }

    function _setEvacuator(address _evacuator, bool _anyToken) internal {
        evacuator = _evacuator;
        anyToken = _anyToken;
    }

    function _setTokenToStay(address _tokenToStay) internal {
        tokenToStay = _tokenToStay;
    }

    function renounceEvacuator(address _to) external onlyEvacuator {
        evacuator = _to;
    }

    function evacuate(address _otherToken, address _to) external onlyEvacuator {
        if (!anyToken) {
          require(_otherToken != tokenToStay, "=tokenToStay");
        }
        IERC20(_otherToken).safeTransfer(_to);
    }
}
