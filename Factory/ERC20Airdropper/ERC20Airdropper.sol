//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Airdropper {

    IERC20 public token;
    uint256 public amount; //100 000

    bool private initialized;

    error AlreadyInitialized();

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    function initialize(bytes memory _initData) notInitialized external returns(bool) {
        (address _token, uint256 _amount) = abi.decode(_initData, (address, uint256));
        token = IERC20(_token);
        amount = _amount;
        initialized = true;
        return true;
    }

    function getInitData(address _token, uint256 _amount) external pure returns(bytes memory) {
        return abi.encode(_token, _amount);
    }

    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external {
        require(receivers.length == amounts.length, "arrays length mismatch");
        require(token.allowance(msg.sender, address(this)) >= amount, "not enought approved tokens");

        for (uint256 i = 0; i < receivers.length; i++) {
            require(token.transferFrom(msg.sender, receivers[i], amounts[i]), "transfer failed");
        }

    }

}

