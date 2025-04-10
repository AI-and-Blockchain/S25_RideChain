// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interface to DriverRegistration
interface IDriverRegistration {
    function updateDriverScore(address driver, uint256 newRating) external;
    function getDriverData(address driver) external view returns (
        address driverAddress,
        uint256 collateral,
        uint256 rating,
        uint256 rideCount,
        bool registered
    );
}

contract AIRatingOracleContract {
    address public owner;
    IDriverRegistration public registration;

    mapping(address => bool) public allowedCallers;
    modifier onlyAllowedCaller() {
        require(allowedCallers[msg.sender], "Not authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address registrationAddress) {
        owner = msg.sender;
        registration = IDriverRegistration(registrationAddress);
    }

    //Only the ownder and add or remove callers to this internal smart contract
    function addAllowedCaller(address caller) external onlyOwner {
        allowedCallers[caller] = true;
    }

    function removeAllowedCaller(address caller) external onlyOwner {
        allowedCallers[caller] = false;
    }

    //Transfer owner can only be done by the owner!
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    //Updates the driver score in the registration contract
    function updateDriverScore(address driver, uint256 newScore) external onlyAllowedCaller {
        registration.updateDriverScore(driver, newScore);
    }

    //This function gets the driver's score from the registration contract
    function getDriverScore(address driver) external view onlyAllowedCaller returns (uint256) {
        (, , uint256 rating, , ) = registration.getDriverData(driver);  //Fetch driver data
        return rating;  //Return the rating score
    }

    //Update registration contract address if needed
    function updateRegistrationAddress(address newAddress) external onlyOwner {
        registration = IDriverRegistration(newAddress);
    }
}

