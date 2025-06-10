//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./VestingWallet.sol";

contract CroundFunding is Ownable {
    uint256 public goal;
    uint256 public pool;
    uint64 public duration;
    bool public goalReached;
    mapping(address => uint256) public userFunds;

    address public fundraiser;
    
    error GoalReached();
    error NothingToWithdraw();
    error TransferFailed();

    event VestingCreated(address vestingContract, address beneficiary, uint64 duration);

    constructor(
        uint256 _goal,
        address _fundraiser,
        uint64 _duration
    ) Ownable(msg.sender) {
        goal = _goal;
        fundraiser = _fundraiser;
        duration = _duration;
    }

    function deposit() public payable {
        require(!goalReached, GoalReached());
        
        if (!goalReached && goal > pool + msg.value) {
            userFunds[msg.sender] += msg.value;
            pool += msg.value;
        } else {
            goalReached = true;
            Vesting vesting = new Vesting{value: address(this).balance}(fundraiser, duration);
            emit VestingCreated(address(vesting), fundraiser, duration);
        }
    }

    function refund() public payable {
        require(!goalReached, GoalReached());
        uint256 amount = userFunds[msg.sender];
        require(amount > 0, NothingToWithdraw());

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, TransferFailed());
        userFunds[msg.sender] -= amount;
        pool -= amount;
    }   

}