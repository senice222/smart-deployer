//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Airdropper is Ownable {
    constructor() Ownable(msg.sender) { }
    IERC20 public token;
    uint256 public amount; // с учетом decimals
    address public treasury;

    bool private initialized;

    error AlreadyInitialized();
    error MisMatch();
    error NotEnoughApprove();
    error TransferFail();

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    function initialize(bytes memory _initData) notInitialized external returns(bool) {
        (address _token, address _treasury, uint256 _amount, address _owner) = abi.decode(_initData, (address, address, uint256, address));

        token = IERC20(_token);
        amount = _amount;
        treasury = _treasury;

        Ownable.transferOwnership(_owner);

        initialized = true;
        return true;
    }

    function getInitData(address _token, address _treasury, uint256 _amount, address _owner) external pure returns(bytes memory) {
        return abi.encode(_token, _treasury, _amount, _owner);
    }

    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external onlyOwner {
        require(receivers.length == amounts.length, MisMatch());
        require(token.allowance(treasury, address(this)) >= amount, NotEnoughApprove());

        for (uint256 i = 0; i < receivers.length; i++) {
            require(token.transferFrom(treasury, receivers[i], amounts[i]), TransferFail());
        }
    }

}

