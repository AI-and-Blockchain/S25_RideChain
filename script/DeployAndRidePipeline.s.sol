// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {RegistrationContract} from "../src/RegistrationContract.sol";
import {AIRatingOracleContract} from "../src/AIRatingOracleContract.sol";
import {RideRequestContract} from "../src/RideRequestContract.sol";
import {DriverContract} from "../src/Driver.sol";
import {RiderContract} from "../src/Rider.sol";

contract DeployAndRidePipeline is Script {
    function run() external {
        uint256 deployer = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 driverKey = vm.envUint("DRIVER_PRIVATE_KEY");
        uint256 riderKey = vm.envUint("RIDER_PRIVATE_KEY");

        vm.startBroadcast(deployer);
        RegistrationContract registration = new RegistrationContract();
        AIRatingOracleContract aiRating = new AIRatingOracleContract(address(registration));
        RideRequestContract rideRequest = new RideRequestContract(
            address(aiRating), address(aiRating), address(registration)
        );
        DriverContract driverContract = new DriverContract(address(registration), address(rideRequest));
        RiderContract riderContract = new RiderContract(address(registration), address(rideRequest));
        vm.stopBroadcast();

        console.log("Registration Contract Address:", address(registration));
        console.log("AI Rating Oracle Contract Address:", address(aiRating));
        console.log("Ride Request Contract Address:", address(rideRequest));
        console.log("Driver Contract Address:", address(driverContract));
        console.log("Rider Contract Address:", address(riderContract));

        // Register driver and rider
        vm.startBroadcast(driverKey);
        driverContract.registerAsDriver{value: 1000 wei}();
        vm.stopBroadcast();

        vm.startBroadcast(riderKey);
        riderContract.registerAsRider();
        vm.stopBroadcast();

        // Request ride
        vm.startBroadcast(riderKey);
        uint256 rideID = riderContract.requestRide("Troy", "Albany", "2025-07-13 11:00:00", "Need room for bags and luggage");
        vm.stopBroadcast();

        // Propose price
        vm.startBroadcast(driverKey);
        driverContract.proposeRidePrice(rideID, 100);
        vm.stopBroadcast();

        // Accept offer and complete ride
        vm.startBroadcast(riderKey);
        riderContract.selectBestOffer{value: 100 wei}(rideID);
        riderContract.confirmDeparture(rideID);
        riderContract.confirmArrival(rideID);
        riderContract.sendReview(rideID, "HORRIBLE JOB, WORST DRIVER EVER!!");
        vm.stopBroadcast();

   }
}
