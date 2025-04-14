// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RegistrationContract {
    
    //Keep track of admin of contract
    address public owner;

    //Initial_collateral value for default drivers
    uint256 public initial_collateral = 1000 wei;

    //Driver struct
    struct Driver {
        address driverAddress;
        uint256 collateral;
        uint256 rating;
        uint256 rideCount;
        bool registered;
    }

    //Rider struct
    struct Rider {
        address riderAddress;
        bool registered;
        uint256 rideCount;
    }

    //We map the address that interacts with this contract to the data stored in the contract.
    mapping(address => Driver) public drivers;
    mapping(address => Rider) public riders;

    //Planning to only allow certain callers to use this contract.
    //it should only be able to be interfaced via smart contracts in the ridechain system.
    mapping(address => bool) public allowedCallers;

    //Events:
    event DriverRegistered(address indexed driver, uint256 collateral);
    event RiderRegistered(address indexed rider);
    event CollateralWithdrawn(address indexed driver, uint256 amount);

    //Useful modifiers
    modifier onlyAllowedCaller() {
        //require(allowedCallers[msg.sender], "Not authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
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

    //Live update of collaeral
    function setInitialCollateral(uint256 newCollateral) external onlyOwner {
        initial_collateral = newCollateral;
    }

    receive() external payable {
        revert("Use register function to send ETH");
    }

    fallback() external payable {
        revert("Invalid function call");
    }

    constructor() {
        owner = msg.sender;
    }

    function handleDriverRegistration(address driver) external payable onlyAllowedCaller {
        require(!drivers[driver].registered, "Driver already registered");
        require(msg.value >= initial_collateral, "Insufficient collateral");

        drivers[driver] = Driver({
            driverAddress: driver,
            collateral: msg.value,
            rating: 5,
            rideCount: 10,
            registered: true
        });
        emit DriverRegistered(driver, msg.value);
    }

    function handleRiderRegistration(address rider) external onlyAllowedCaller {
        require(!riders[rider].registered, "Rider already registered");

        riders[rider] = Rider({
            riderAddress: rider,
            registered: true,
            rideCount: 0
        });
        emit RiderRegistered(rider);
    }

    //Used to get a drivers data if they are registered
    function getDriverData(address driver) external view returns (Driver memory) {
        require(drivers[driver].registered, "Driver not registered");
        return drivers[driver];
    }

    //Receives payment and increments collatoral
    function receiveRidePayment(address rider, address driver, uint256 payment) external payable {
        require(drivers[driver].registered, "Driver not registered");
        require(riders[rider].registered, "Driver not registered");
        require(payment == msg.value, "Incorrect funds sent");
        drivers[driver].collateral += msg.value;
        drivers[driver].rideCount += 1;
        riders[rider].rideCount += 1;
    }

    //Used to get a riders data if they are registered
    function getRiderData(address rider) external view returns (Rider memory) {
        require(riders[rider].registered, "Rider not registered");
        return riders[rider];
    }

    //Quick driver registration check
    function isDriverRegistered(address driver) external view returns (bool) {
        return drivers[driver].registered;
    }

    //Quick rider registration check
    function isRiderRegistered(address rider) external view returns (bool) {
        return riders[rider].registered;
    }

    //Update a drivers rating to a new rating
    function updateDriverScore(address driver, uint256 newRating) external onlyAllowedCaller {
        Driver storage d = drivers[driver];
        require(d.registered, "Driver not registered");
        d.rating = (d.rating * d.rideCount + newRating) / (d.rideCount + 1);
    }

    function withdrawCollateral(address driver) external onlyAllowedCaller {
        Driver storage d = drivers[driver];
        require(d.rating > 3, "Rating too low");
        require(d.rideCount >= 10, "Not enough rides");

        uint256 amount = d.collateral;
        d.collateral = 0;
        payable(driver).transfer(amount);
        emit CollateralWithdrawn(driver, amount);
    }

    function incrementRiderCount(address rider) external onlyAllowedCaller {
        require(riders[rider].registered, "Rider not registered");
        riders[rider].rideCount += 1;
    }

    function incrementDriverCount(address driver) external onlyAllowedCaller {
        require(drivers[driver].registered, "Driver not registered");
        drivers[driver].rideCount++;
    }
}
