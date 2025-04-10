// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAIRatingOracleContract {
    function updateDriverScore(address driver, uint256 newScore) external;
}

contract RideRequestContract {
    struct RideRequest {
        address rider;
        string start;
        string end;
        string startDate; 
        string preferences;
        bool accepted;
        address selectedDriver;
        uint256 paymentAmount;
        string status; //Requested, Accepted, Departed, Arrived, Completed
    }

    struct RideProposal {
        address driver;
        uint256 price;
    }

    mapping(address => bool) public allowedCallers;
    modifier onlyAllowedCaller() {
        require(allowedCallers[msg.sender], "Not authorized");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }


    address public mobileOracle;
    IAIRatingOracleContract public aiRatingOracle;
    address public owner;

    uint256 public rideCounter;

    mapping(uint256 => RideRequest) public rideRequests;
    mapping(uint256 => RideProposal[]) public rideProposals;
    mapping(uint256 => mapping(address => bool)) public hasProposed;

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
        owner = msg.sender;
        mobileOracle = _mobileOracle;
        aiRatingOracle = IAIRatingOracleContract(_aiRatingOracle);
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

    function initiateRideRequest(
        string calldata start,
        string calldata end,
        string calldata startDate,
        string calldata preferences
    ) external onlyAllowedCaller returns (uint256 rideId) {
        rideId = rideCounter++;
        rideRequests[rideId] = RideRequest({
            rider: msg.sender,
            start: start,
            end: end,
            startDate: startDate,
            preferences: preferences,
            accepted: false,
            selectedDriver: address(0),
            paymentAmount: 0,
            status: "requested"
        });
        emit RideRequested(rideId, msg.sender);
    }

    function submitRideProposal(uint256 rideId, uint256 price) external onlyAllowedCaller{
        require(rideId < rideCounter, "Invalid ride ID");
        require(!hasProposed[rideId][msg.sender], "Proposal already submitted for this ride");

        rideProposals[rideId].push(RideProposal({driver: msg.sender, price: price}));
        hasProposed[rideId][msg.sender] = true;

        emit ProposalSubmitted(rideId, msg.sender, price);
    }

    function getRideProposals(uint256 rideId) external view onlyAllowedCaller returns (RideProposal[] memory) {
        require(rideId < rideCounter, "Invalid ride ID");
        return rideProposals[rideId];
    }

    function finalizeRideSelection(uint256 rideId, address driver) external payable onlyAllowedCaller {
        RideRequest storage request = rideRequests[rideId];
        require(msg.sender == request.rider, "Only rider can select");
        require(!request.accepted, "Ride already accepted");

        // Check if the driver has submitted a proposal and retrieve the price
        RideProposal[] memory proposals = rideProposals[rideId];
        uint256 proposedPrice = 0;
        bool found = false;

        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].driver == driver) {
                proposedPrice = proposals[i].price;
                found = true;
                break;
            }
        }

        require(found, "Driver has not submitted a proposal");
        require(msg.value == proposedPrice, "Incorrect payment amount");

        // Finalize ride
        request.accepted = true;
        request.status = "accepted";
        request.selectedDriver = driver;
        request.paymentAmount = proposedPrice;

        emit RideAccepted(rideId, driver);
    }

    function confirmDeparture(uint256 rideId) external onlyAllowedCaller {
        RideRequest storage request = rideRequests[rideId];
        require(msg.sender == request.rider, "Only rider can confirm departure");
        require(keccak256(abi.encodePacked(request.status)) == keccak256(abi.encodePacked("accepted")), "Ride must be accepted to confirm departure");
        //Right now calling this method makes the request departed
        request.status = "departed";
        // Interact with Mobile Oracle here 
        emit RideConfirmed(rideId);
    }

    function confirmArrival(uint256 rideId) external onlyAllowedCaller {
        RideRequest storage request = rideRequests[rideId];
        require(request.accepted, "Ride not accepted");
        require(keccak256(abi.encodePacked(request.status)) == keccak256(abi.encodePacked("departed")), "Ride must be departed to confirm departure");
        
        request.status = "arrived";

        payable(request.selectedDriver).transfer(request.paymentAmount);
        emit PaymentTransferred(rideId, request.selectedDriver);
    }

    function sendReview(uint256 rideId, string calldata feedback) external onlyAllowedCaller {
        RideRequest storage request = rideRequests[rideId];
        
        require(msg.sender == request.rider, "Only rider can review");
        require(keccak256(abi.encodePacked(request.status)) == keccak256(abi.encodePacked("arrived")), "Ride must be departed to confirm departure");
        
        request.status = "completed";
        // Interact with AI Rating Oracle
        // AIRC -> AI -> AIRC -> then update score for driver

        //Simulate AI Oracle
        aiRatingOracle.updateDriverScore(request.selectedDriver, 5);

    }

}
