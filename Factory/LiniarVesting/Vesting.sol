//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../IUtilityContract.sol";

contract Vesting is IUtilityContract, Ownable {
    constructor() Ownable(msg.sender) { }

    IERC20 public token;
    bool private initialized;

    address public benefiaciry;
    uint256 public totalAmount;
    uint256 public claimed;

    uint256 public startTime;
    uint256 public cliff;
    uint256 public duration;

    error AlreadyInitialized();
    error UserIsNotBeneficiary();
    error CliffNotReached();
    error NothingToClaim();
    error TransferIsFailed();

    event Claim(address benefiaciry, uint256 amount, uint256 timestamp);

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    function claim() public {
        require(msg.sender == benefiaciry, UserIsNotBeneficiary());
        require(block.timestamp > startTime + cliff, CliffNotReached());

        uint256 claimable = claimableAmount();
        require(claimable > 0, NothingToClaim());

        require(token.transfer(benefiaciry, claimable), TransferIsFailed());
        claimed += claimable;
        emit Claim(benefiaciry, claimable, block.timestamp);

    }

    function vestedAmount() internal view returns(uint256) {
        if (block.timestamp < startTime + cliff) return 0;
        uint256 passedTime = block.timestamp - (startTime + cliff);
        return (passedTime * totalAmount) / duration;
    }

    function claimableAmount() public view returns(uint256) {
        if (block.timestamp < startTime + cliff) return 0;
        return vestedAmount() - claimed;
    }


    function initialize(bytes memory _initData) notInitialized external returns(bool) {
        (address _token, address _owner) = abi.decode(_initData, (address, address));
        token = IERC20(_token);
        
        Ownable.transferOwnership(_owner);

        initialized = true;
        return true;
    }

    function getInitData(address _token, address _treasury, uint256 _amount, address _owner) external pure returns(bytes memory) {
        return abi.encode(_token, _treasury, _amount, _owner);
    }

}