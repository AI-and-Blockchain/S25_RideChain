// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RegistrationContract {
    address public owner;

    mapping(address => bool) public registeredRiders;
    mapping(address => uint256) public driverCollaterals;
    //Drivier initial collatoral upon registraction
    uint256 public initial_collateral = 1000 wei;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function handleRiderRegistration(address rider) external onlyOwner {
        require(!registeredRiders[rider], "Rider already registered");
        registeredRiders[rider] = true;
    }

    function handleDriverRegistration(address driver) external payable onlyOwner {
        require(driverCollaterals[driver] == 0, "Driver already registered");
        require(msg.value >= initial_collateral, "Insufficient collateral");
        driverCollaterals[driver] = msg.value;
    }

    //Update to interact with driver and rider contracts later
    function confirmRegistration(address user) external view returns (bool) {
        return registeredRiders[user] || driverCollaterals[user] > 0;
    }
}
