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

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address registrationAddress) {
        owner = msg.sender;
        registration = IDriverRegistration(registrationAddress);
    }

    //Updates the driver score in the registration contract
    function updateDriverScore(address driver, uint256 newScore) external onlyOwner {
        registration.updateDriverScore(driver, newScore);
    }

    //This function gets the driver's score from the registration contract
    function getDriverScore(address driver) external view returns (uint256) {
        (, , uint256 rating, , ) = registration.getDriverData(driver);  //Fetch driver data
        return rating;  //Return the rating score
    }

    //Update registration contract address if needed
    function updateRegistrationAddress(address newAddress) external onlyOwner {
        registration = IDriverRegistration(newAddress);
    }
}

