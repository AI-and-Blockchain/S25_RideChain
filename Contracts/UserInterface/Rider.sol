// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RiderContract {
    address public owner;

    struct Rider {
        address riderAddress;
        bool registered;
        uint256 rideCount;
    }

    struct RideOffer {
        address driver;
        uint256 price;
        bool accepted;
    }

    mapping(address => Rider) public riders;
    mapping(address => RideOffer[]) public rideOffers; // Stores ride offers for each rider

    event RiderRegistered(address indexed rider);
    event RideRequested(address indexed rider, string startLocation, string endLocation, string preferences);
    event RideOfferReceived(address indexed rider, address indexed driver, uint256 price);
    event RideOfferAccepted(address indexed rider, address indexed driver, uint256 price);
    event PaymentSubmitted(address indexed rider, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyRegisteredRider() {
        require(riders[msg.sender].registered, "Rider not registered");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerAsRider() external {
        require(!riders[msg.sender].registered, "Already registered");

        riders[msg.sender] = Rider({
            riderAddress: msg.sender,
            registered: true,
            rideCount: 0
        });

        emit RiderRegistered(msg.sender);
    }

    function requestRide(string calldata startLocation, string calldata endLocation, string calldata preferences) 
        external onlyRegisteredRider 
    {
        emit RideRequested(msg.sender, startLocation, endLocation, preferences);
    }

    function receiveRideOffer(address driver, uint256 price) external {
        rideOffers[msg.sender].push(RideOffer({
            driver: driver,
            price: price,
            accepted: false
        }));

        emit RideOfferReceived(msg.sender, driver, price);
    }

    function selectBestOffer() external onlyRegisteredRider {
        require(rideOffers[msg.sender].length > 0, "No ride offers available");

        uint256 bestIndex = 0;
        uint256 bestPrice = rideOffers[msg.sender][0].price;

        for (uint256 i = 1; i < rideOffers[msg.sender].length; i++) {
            if (rideOffers[msg.sender][i].price < bestPrice) {
                bestPrice = rideOffers[msg.sender][i].price;
                bestIndex = i;
            }
        }

        rideOffers[msg.sender][bestIndex].accepted = true;
        emit RideOfferAccepted(msg.sender, rideOffers[msg.sender][bestIndex].driver, bestPrice);
    }

    function submitPayment(uint256 amount) external payable onlyRegisteredRider {
        require(msg.value == amount, "Incorrect payment amount");

        emit PaymentSubmitted(msg.sender, amount);
    }

    function incrementRideCount(address riderAddress) external onlyOwner {
        require(riders[riderAddress].registered, "Rider not registered");
        riders[riderAddress].rideCount++;
    }
}
