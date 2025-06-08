//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../IUtilityContract.sol";

contract ERC721Airdropper is IUtilityContract, Ownable {
    constructor() Ownable(msg.sender) { }
    IERC721 public token;
    address public treasury;

    bool private initialized;

    error AlreadyInitialized();
    error MisMatch();
    error NeedToApproveTokens();
    error TransferFail();

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    function initialize(bytes memory _initData) notInitialized external returns(bool) {
        (address _token, address _treasury, address _owner) = abi.decode(_initData, (address, address, address));

        token = IERC721(_token);
        treasury = _treasury;

        Ownable.transferOwnership(_owner);

        initialized = true;
        return true;
    }

    function getInitData(address _token, address _treasury, uint256 _amount, address _owner) external pure returns(bytes memory) {
        return abi.encode(_token, _treasury, _amount, _owner);
    }

    function airdrop(address[] calldata receivers, uint256[] calldata tokenId) external onlyOwner {
        require(receivers.length == tokenId.length, MisMatch());
        require(token.isApprovedForAll(treasury, address(this)), NeedToApproveTokens());

        for (uint256 i = 0; i < receivers.length; i++) {
            token.safeTransferFrom(treasury, receivers[i], tokenId[i], "");
        }
    }

}

