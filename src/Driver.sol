// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//Minimal interface to the RegistrationContract
interface IRegistrationContract {
    function handleDriverRegistration(address driver) external payable;
    function incrementDriverCount(address driver) external;
    function isDriverRegistered(address driver) external view returns (bool);
    function getDriverData(address driver) external view returns (
        address driverAddress,
        uint256 collateral,
        uint256 rating,
        uint256 rideCount,
        bool registered
    );
    function updateDriverScore(address driver, uint256 newRating) external;
    function withdrawCollateral(address driver) external;
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
    function finalizeRideSelection(uint256 rideId, address driver, uint256 paymentAmount) external payable;
    function confirmDeparture(uint256 rideId) external;
    function confirmArrival(uint256 rideId) external;
    function sendReview(uint256 rideId, string calldata feedback) external;
    function submitRideProposal(address driver, uint256 rideId, uint256 price) external;
    function getRideProposals(uint256 rideId) external view returns (RideProposal[] memory);
}

contract DriverContract {
    address public owner;
    IRegistrationContract public registration;
    IRideRequestContract public request;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyRegisteredDriver() {
        require(registration.isDriverRegistered(msg.sender), "Not a registered driver");
        _;
    }

    //Events:
    event DriverRegistered(address indexed driver, uint256 collateral);
    event RideProposalSubmitted(address indexed driver, uint256 price, uint256 ride_id);
    event FundsWithdrawn(address indexed driver);

    constructor(address registrationAddress, address requestAddress) {
        owner = msg.sender;
        registration = IRegistrationContract(registrationAddress);
        request = IRideRequestContract(requestAddress);
    }

    receive() external payable {
        revert("Don't send ETH directly");
    }

    function registerAsDriver() external payable {
        require(!registration.isDriverRegistered(msg.sender), "Already registered");
        registration.handleDriverRegistration{value: msg.value}(msg.sender);
        emit DriverRegistered(msg.sender, msg.value);
    }

    function viewMyDriverData() external view returns (
        address driverAddress,
        uint256 collateral,
        uint256 rating,
        uint256 rideCount,
        bool registered
    ) {
        return registration.getDriverData(msg.sender);
    }

    function proposeRidePrice(uint256 ride_id, uint256 price) external {
        require(registration.isDriverRegistered(msg.sender), "Driver not registered");
        emit RideProposalSubmitted(msg.sender, price, ride_id);
        request.submitRideProposal(msg.sender, ride_id, price);
    }

    function withdrawRequest() external onlyRegisteredDriver {
        require(registration.isDriverRegistered(msg.sender), "Driver not registered");
        registration.withdrawCollateral(msg.sender);
        emit FundsWithdrawn(msg.sender);
    }

    function incrementRideCount(address driverAddress) external onlyOwner {
        require(registration.isDriverRegistered(driverAddress), "Driver not registered");
        registration.incrementDriverCount(driverAddress);
    }

    function updateRegistrationAddress(address newAddress) external onlyOwner {
        registration = IRegistrationContract(newAddress);
    }

    function confirmDeparture(uint256 rideId) external {
        request.confirmDeparture(rideId);
    }

    function confirmArrival(uint256 rideId) external {
        request.confirmArrival(rideId);
    }
}
