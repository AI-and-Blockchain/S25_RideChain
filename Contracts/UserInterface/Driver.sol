// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DriverContract {
    address public owner;

    struct Driver {
        address driverAddress;
        uint256 collateral;
        uint256 rating;
        uint256 rideCount;
        bool registered;
    }

    mapping(address => Driver) public drivers;

    event DriverRegistered(address indexed driver, uint256 collateral);
    event RideProposalSubmitted(address indexed driver, uint256 price, uint256 ride_id);
    event FundsWithdrawn(address indexed driver, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyRegisteredDriver() {
        require(drivers[msg.sender].registered, "Driver not registered");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerAsDriver(uint256 collateral) external payable {
        require(!drivers[msg.sender].registered, "Already registered");
        require(msg.value >= collateral, "Insufficient collateral");

        drivers[msg.sender] = Driver({
            driverAddress: msg.sender,
            collateral: msg.value,
            rating: 0, // Default rating for now
            rideCount: 0,
            registered: true
        });

        emit DriverRegistered(msg.sender, msg.value);
    }

    function proposeRidePrice(uint256 ride_id, uint256 price) external onlyRegisteredDriver {
        emit RideProposalSubmitted(msg.sender, price, ride_id);
    }

    function withdrawRequest() external onlyRegisteredDriver {
        Driver storage driver = drivers[msg.sender];

        require(driver.rating > 3, "Rating too low");
        require(driver.rideCount >= 10, "Not enough rides completed");

        uint256 amount = driver.collateral;
        driver.collateral = 0;
        payable(msg.sender).transfer(amount);

        emit FundsWithdrawn(msg.sender, amount);
    }

    function updateDriverScore(address driverAddress, uint256 newRating) external onlyOwner {
        require(drivers[driverAddress].registered, "Driver not registered");
        oldScore = drivers[driverAddress].rating;
        count = drivers[driverAddress].rideCount;
        newScore = (oldScore*count + newRating) / (count+1);
        drivers[driverAddress].rating = newScore;
    }

    function incrementRideCount(address driverAddress) external onlyOwner {
        require(drivers[driverAddress].registered, "Driver not registered");
        drivers[driverAddress].rideCount++;
    }
}
