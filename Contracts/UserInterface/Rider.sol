// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interface to RiderRegistrationContract
interface IRiderRegistration {
    function handleRiderRegistration(address rider) external;
    function isRiderRegistered(address rider) external view returns (bool);
    function getRiderData(address rider) external view returns (
        address riderAddress,
        bool registered,
        uint256 rideCount
    );
    function incrementRiderCount(address rider) external;
}

interface IRideRequestContract {
    struct RideProposal {
        address driver;
        uint256 price;
    }
    function initiateRideRequest(
        string calldata start,
        string calldata end,
        string calldata startDate,
        string calldata preferences
    ) external returns (uint256 rideId);
    function finalizeRideSelection(uint256 rideId, address driver) external payable;
    function confirmDeparture(uint256 rideId) external;
    function confirmArrival(uint256 rideId) external;
    function sendReview(uint256 rideId, string calldata feedback) external;
    function getRideProposals(uint256 rideId) external view returns (RideProposal[] memory);
}

contract RiderContract {
    address public owner;
    IRiderRegistration public registration;
    IRideRequestContract public request;

    event RiderRegistered(address indexed rider);
    event RideRequested(address indexed rider, string startLocation, string endLocation, string startTime, string preferences);
    event RideOfferReceived(address indexed rider, address indexed driver, uint256 price);
    event RideOfferAccepted(address indexed rider, address indexed driver, uint256 price);
    event PaymentSubmitted(address indexed rider, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyRegisteredRider() {
        require(registration.isRiderRegistered(msg.sender), "Rider not registered");
        _;
    }

    //RegistractionAddress contract needed to interface with it
    constructor(address registrationAddress, address requestAddress) {
        owner = msg.sender;
        registration = IRiderRegistration(registrationAddress);
        request = IRideRequestContract(requestAddress);
    }

    function registerAsRider() external {
        require(!registration.isRiderRegistered(msg.sender), "Already registered");

        registration.handleRiderRegistration(msg.sender);
        emit RiderRegistered(msg.sender);
    }

    //Quickly view riders data stored
    function viewMyRiderData() external view returns (
        address riderAddress,
        bool registered,
        uint256 rideCount
    ) {
        return registration.getRiderData(msg.sender);
    }

    //UPDATE
    function requestRide(string calldata startLocation, string calldata endLocation, string calldata startTime, string calldata preferences) 
        external onlyRegisteredRider 
    {
        emit RideRequested(msg.sender, startLocation, endLocation, startTime, preferences);
        request.initiateRideRequest(startLocation, endLocation, startTime, preferences);
    }

    //UPDATE
    function receiveRideOffer(address rider, address driver, uint256 price) external {
        emit RideOfferReceived(rider, driver, price);
    }

    function selectBestOffer(uint256 rideId) external onlyRegisteredRider {
        IRideRequestContract.RideProposal[] memory proposals = request.getRideProposals(rideId);
        require(proposals.length > 0, "No ride proposals available");
    
        uint256 bestIndex = 0;
        uint256 bestPrice = proposals[0].price;
    
        for (uint256 i = 1; i < proposals.length; i++) {
            if (proposals[i].price < bestPrice) {
                bestPrice = proposals[i].price;
                bestIndex = i;
            }
        }
    
        address selectedDriver = proposals[bestIndex].driver;
    
        // Call finalizeRideSelection on RideRequestContract
        request.finalizeRideSelection(rideId, selectedDriver);
    
        emit RideOfferAccepted(msg.sender, selectedDriver, bestPrice);
    }

    //UPDATE: to submitPayment to the riderequest contract
    function submitPayment(uint256 amount) external payable onlyRegisteredRider {
        require(msg.value == amount, "Incorrect payment amount");

        emit PaymentSubmitted(msg.sender, amount);
    }

    //UPDATE: Interface elsewhere
    function incrementRideCount(address riderAddress) external onlyOwner {
        require(registration.isRiderRegistered(riderAddress), "Rider not registered");
        registration.incrementRiderCount(riderAddress);
    }
    

    //Change contract address
    function updateRegistrationAddress(address newAddress) external onlyOwner {
        registration = IRiderRegistration(newAddress);
    }

    function confirmDeparture(uint256 rideId) external {
        request.confirmDeparture(rideId);
    }

    function confirmArrival(uint256 rideId) external {
        request.confirmArrival(rideId);
    }

    function sendReview(uint256 rideId, string calldata feedback) external onlyRegisteredRider {
        request.sendReview(rideId, feedback);
    }

}
