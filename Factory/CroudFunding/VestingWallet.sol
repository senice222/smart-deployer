//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract Vesting is VestingWallet {
    constructor(address beneficiary, uint64 _duration) payable VestingWallet(beneficiary, uint64(block.timestamp), _duration) { }
}