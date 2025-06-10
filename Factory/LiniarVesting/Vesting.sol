//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../IUtilityContract.sol";

contract Vesting is IUtilityContract, Ownable {
    constructor() Ownable(msg.sender) { }

    IERC20 public token;
    bool private initialized;
    address public ownerContract;
    uint256 public allocatedTokens;

    struct VestingInfo {
        uint256 totalAmount;
        uint256 claimed;
        uint256 startTime;
        uint256 cliff;
        uint256 duration;
        uint256 lastClaimTime;
        uint256 claimCooldawn;
        uint256 minClaimAmount;
    }

    mapping(address => VestingInfo) public vestings;

    error AlreadyInitialized();
    error VestingNotFound();
    error CliffNotReached();
    error NothingToClaim();
    error TransferIsFailed();
    error InfsufficentBalance();
    error VestingAlreadyExists();
    error AmountCantBeZero();
    error StartTimeShouldBeFuture();
    error DurationCantBeZero();
    error CliffCantBeLongerThanDuration();
    error CooldawnCantBeLongerThanDuration();
    error InvalidBeneficiary();
    error BelowMinClaimAmount();
    error CooldownNotPassed();
    error CantClaimMoreThatTotalAmount();
    error WithdrawTransferFailed();
    error NothingToWithdraw();

    event Claim(address beneficiary, uint256 amount, uint256 timestamp);
    event VestingCreated(address beneficiary, uint256 amount, uint256 creationTime);
    event TokensWithdrawn(address to, uint256 amount);

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    function claim() public {
        VestingInfo storage vesting = vestings[msg.sender];
        require(vesting.totalAmount > 0, VestingNotFound());
        require(block.timestamp > vesting.startTime + vesting.cliff, CliffNotReached());
        require(block.timestamp > vesting.lastClaimTime + vesting.claimCooldawn, CooldownNotPassed());

        uint256 claimable = claimableAmount(msg.sender);
        require(claimable > 0, NothingToClaim());
        require(claimable >= vesting.minClaimAmount, BelowMinClaimAmount());
        require(claimable + vesting.totalAmount > vesting.totalAmount, CantClaimMoreThatTotalAmount());

        require(token.transfer(msg.sender, claimable), TransferIsFailed());

        vesting.claimed += claimable;
        vesting.lastClaimTime = block.timestamp;
        allocatedTokens -= claimable;
        emit Claim(msg.sender, claimable, block.timestamp);
    }

    function vestedAmount(address _claimer) internal view returns(uint256) {
        VestingInfo storage vesting = vestings[_claimer];

        if (block.timestamp < vesting.startTime + vesting.cliff) return 0;
        uint256 passedTime = block.timestamp - (vesting.startTime + vesting.cliff);
        if (passedTime > vesting.duration) {
            passedTime = vesting.duration; 
        }
        return (passedTime * vesting.totalAmount) / vesting.duration;
    }

    function claimableAmount(address _claimer) public view returns(uint256) {
        VestingInfo storage vesting = vestings[_claimer];
        if (block.timestamp < vesting.startTime + vesting.cliff) return 0;
        return vestedAmount(_claimer) - vesting.claimed;
    }

    function startVesting(
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _cliff,
        uint256 _duration,
        uint256 _claimCooldawn,
        uint256 _minClaimAmount,
        uint256 _startTime
    ) external onlyOwner {
        require(token.balanceOf(address(this)) - allocatedTokens >= _totalAmount, InfsufficentBalance());
        require(
            vestings[_beneficiary].totalAmount == 0 
            || 
            vestings[_beneficiary].totalAmount == vestings[_beneficiary].claimed
            , 
            VestingAlreadyExists()
        );
        require(_totalAmount > 0, AmountCantBeZero());
        require(_startTime > block.timestamp, StartTimeShouldBeFuture());
        require(_duration > 0, DurationCantBeZero());
        require(_cliff < _duration, CliffCantBeLongerThanDuration());
        require(_claimCooldawn < _duration, CooldawnCantBeLongerThanDuration());
        require(_beneficiary != address(0), InvalidBeneficiary());

        vestings[_beneficiary] = VestingInfo({
            totalAmount: _totalAmount,
            startTime: _startTime,
            cliff: _cliff,
            claimCooldawn: _claimCooldawn,
            minClaimAmount: _minClaimAmount,
            duration: _duration,
            claimed: 0,
            lastClaimTime: 0
            
        });
        allocatedTokens += _totalAmount;
        emit VestingCreated(_beneficiary, _totalAmount, block.timestamp);
    }

    function withdraw(address _to) external onlyOwner {
        uint256 available = token.balanceOf(address(this)) - allocatedTokens;
        require(available > 0, NothingToWithdraw());
        require(token.transfer(_to, available), WithdrawTransferFailed());
        emit TokensWithdrawn(_to, available);
    }   

    function initialize(bytes memory _initData) notInitialized external returns(bool) {
        (address _token, address _owner) = abi.decode(_initData, (address, address));
        token = IERC20(_token);
        ownerContract = _owner;
        Ownable.transferOwnership(_owner);

        initialized = true;
        return true;
    }

    function getInitData(address _token, address _owner) external pure returns(bytes memory) {
        return abi.encode(_token, _owner);
    }

}