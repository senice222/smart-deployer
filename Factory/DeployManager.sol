// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IUtilityContract.sol";

contract DeployManager is Ownable {

    constructor() Ownable(msg.sender) {}

    event NewDeployment(
        address addressDeployer,
        address contractAddress,
        uint256 fee,
        uint256 timestamp
    );
    event NewContractAdded(
        address contractAddress,
        uint256 fee,
        bool isActive,
        uint256 timestamp
    );
    event ContractFeeUpdated(
        address contractAddress,
        uint256 oldFee,
        uint256 newFee,
        uint256 timestamp
    );
    event ContractStatusUpdated(
        address contractAddress,
        bool status,
        uint256 timestamp
    );    

    error NotActive();
    error NotEnoughFunds();
    error DoesNotRegistred();
    error DeploymentFailed();

    struct ContractInfo{
        bool isActive;
        uint256 fee;
        uint256 registredAt;
    }

    mapping(address => address[]) public deployedContracts;
    mapping(address => ContractInfo) public contractsData;

    function deploy(address _utilityContract, bytes calldata _initData) external payable returns(address) {
        ContractInfo memory info = contractsData[_utilityContract];
        require(info.isActive, NotActive());
        require(msg.value >= info.fee, NotEnoughFunds());
        require(info.registredAt > 0, DoesNotRegistred());

        address clone = Clones.clone(_utilityContract);
        require(IUtilityContract(clone).initialize(_initData), DeploymentFailed());

        payable(owner()).transfer(msg.value);

        deployedContracts[msg.sender].push(clone);
        emit NewDeployment(msg.sender, clone, info.fee, block.timestamp);
        return clone;
    }

    function addNewContract(address _contractAddress, bool _active, uint256 _fee) external onlyOwner {
        contractsData[_contractAddress] = ContractInfo({
            isActive: _active,
            fee: _fee,
            registredAt: block.timestamp
        });
    
        emit NewContractAdded(_contractAddress, _fee, _active, block.timestamp);
    }

    function updateFee(address _contract, uint256 _fee) external onlyOwner {
        require (contractsData[_contract].registredAt > 0, DoesNotRegistred());

        uint256 oldFee = contractsData[_contract].fee;
        contractsData[_contract].fee = _fee;
        emit ContractFeeUpdated(_contract, oldFee, _fee, block.timestamp);
    }

    function activate(address _contract) external onlyOwner {
        require (contractsData[_contract].registredAt > 0, DoesNotRegistred());

        contractsData[_contract].isActive = true;
        emit ContractStatusUpdated(_contract, true, block.timestamp);
    }
    function deactivate(address _contract) external onlyOwner {
        require (contractsData[_contract].registredAt > 0, DoesNotRegistred());
        contractsData[_contract].isActive = false;
        emit ContractStatusUpdated(_contract, false, block.timestamp);
    }

}