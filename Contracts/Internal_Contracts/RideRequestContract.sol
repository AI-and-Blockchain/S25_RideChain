// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RideRequestContract {
    struct RideRequest {
        address rider;
        string start;
        string end;
        string preferences;
        bool accepted;
        address selectedDriver;
        uint256 paymentAmount;
    }

    struct RideProposal {
        address driver;
        uint256 price;
    }

    address public mobileOracle;
    address public aiRatingOracle;

    uint256 public rideCounter;

    mapping(uint256 => RideRequest) public rideRequests;
    mapping(uint256 => RideProposal[]) public rideProposals;

    event RideRequested(uint256 rideId, address rider);
    event DriverNotified(uint256 rideId, address driver);
    event ProposalSubmitted(uint256 rideId, address driver, uint256 price);
    event RideAccepted(uint256 rideId, address driver);
    event RideConfirmed(uint256 rideId);
    event PaymentTransferred(uint256 rideId, address driver);

    modifier onlyMobileOracle() {
        require(msg.sender == mobileOracle, "Not Mobile Oracle");
        _;
    }

    constructor(address _mobileOracle, address _aiRatingOracle) {
        mobileOracle = _mobileOracle;
        aiRatingOracle = _aiRatingOracle;
    }

    function initiateRideRequest(
        string calldata start,
        string calldata end,
        string calldata preferences
    ) external returns (uint256 rideId) {
        rideId = rideCounter++;
        rideRequests[rideId] = RideRequest({
            rider: msg.sender,
            start: start,
            end: end,
            preferences: preferences,
            accepted: false,
            selectedDriver: address(0),
            paymentAmount: 0
        });
        emit RideRequested(rideId, msg.sender);
    }

    function submitRideProposal(uint256 rideId, uint256 price) external {
        require(rideId < rideCounter, "Invalid ride ID");
        rideProposals[rideId].push(RideProposal({driver: msg.sender, price: price}));
        emit ProposalSubmitted(rideId, msg.sender, price);
    }

    function finalizeRideSelection(uint256 rideId, address driver, uint256 paymentAmount) external payable {
        RideRequest storage request = rideRequests[rideId];
        require(msg.sender == request.rider, "Only rider can select");
        require(msg.value == paymentAmount, "Incorrect payment amount");

        request.accepted = true;
        request.selectedDriver = driver;
        request.paymentAmount = paymentAmount;

        emit RideAccepted(rideId, driver);
    }

    function confirmDeparture(uint256 rideId) external {
        RideRequest storage request = rideRequests[rideId];
        require(msg.sender == request.rider, "Only rider can confirm departure");
        // Interact with Mobile Oracle here 
        emit RideConfirmed(rideId);
    }

    function confirmArrival(uint256 rideId) external onlyMobileOracle {
        RideRequest storage request = rideRequests[rideId];
        require(request.accepted, "Ride not accepted");
        payable(request.selectedDriver).transfer(request.paymentAmount);
        emit PaymentTransferred(rideId, request.selectedDriver);
    }

    function sendReview(uint256 rideId, string calldata feedback) external {
        RideRequest storage request = rideRequests[rideId];
        require(msg.sender == request.rider, "Only rider can review");
        // Interact with AI Rating Oracle
        // AIRC -> AI -> AIRC -> then update score for driver
    }

}
