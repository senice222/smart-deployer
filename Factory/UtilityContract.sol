// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;
import "./IUtilityContract.sol";

contract UtilityContract is IUtilityContract {
    uint256 public number;
    address public bigBoss;
    bool private initialized;

    error AlreadyInitialized();

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    function initialize(bytes memory _initData) notInitialized external returns(bool) {
        (uint256 _number, address _bigBoss) = abi.decode(_initData, (uint256, address));
        number = _number;
        bigBoss = _bigBoss;
        initialized = true;
        return true;
    }

    function getInitData(uint256 _number, address _bigBoss) external pure returns(bytes memory) {
        return abi.encode(_number, _bigBoss);
    }
}