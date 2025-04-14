// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {RegistrationContract} from "../src/RegistrationContract.sol";
import {AIRatingOracleContract} from "../src/AIRatingOracleContract.sol";
import {RideRequestContract} from "../src/RideRequestContract.sol";
import {DriverContract} from "../src/Driver.sol";
import {RiderContract} from "../src/Rider.sol";

// forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

contract DeployAndDemo is Script {
    function run() external {
        // Load test keys (these are default from Anvil)
        uint256 deployer = vm.envUint("DEPLOYER_PRIVATE_KEY");
        console.log("Deployer address:", deployer);
        uint256 driverKey = vm.envUint("DRIVER_PRIVATE_KEY"); // or use vm.envUintOr("DRIVER_PRIVATE_KEY", 1);
        uint256 riderKey = vm.envUint("RIDER_PRIVATE_KEY");

        vm.startBroadcast(deployer); // All from deployer now

        // Step 1: Deploy Registration
        RegistrationContract registration = new RegistrationContract();

        // Step 2: Deploy AI Rating (depends on registration)
        AIRatingOracleContract aiRating = new AIRatingOracleContract(address(registration));

        // Step 3: Deploy RideRequest (depends on aiRating, aiRating, registration)
        RideRequestContract rideRequest = new RideRequestContract(
            address(aiRating),
            address(aiRating),
            address(registration)
        );

        // Step 4: Deploy Driver + Rider Contracts (need registration + request)
        DriverContract driverContract = new DriverContract(address(registration), address(rideRequest));
        RiderContract riderContract = new RiderContract(address(registration), address(rideRequest));

        vm.stopBroadcast();

        // Register Driver with 1000 wei
        vm.startBroadcast(driverKey);
        driverContract.registerAsDriver{value: 1000 wei}();
        vm.stopBroadcast();

        // Register Rider (no ETH needed)
        vm.startBroadcast(riderKey);
        riderContract.registerAsRider();
        vm.stopBroadcast();

        address driverAddress;
        uint256 collateral;
        uint256 rating;
        uint256 rideCount;
        bool registered;

        vm.startBroadcast(driverKey);  // Using driver's private key to call the function
        (driverAddress, collateral, rating, rideCount, registered) = driverContract.viewMyDriverData();
        vm.stopBroadcast();

        // Log the driver data
        console.log("Driver Address:", driverAddress);
        console.log("Driver Collateral:", collateral);
        console.log("Driver Rating:", rating);
        console.log("Driver Ride Count:", rideCount);
        console.log("Driver Registered:", registered);

        vm.startBroadcast(riderKey);
        uint256 rideID = riderContract.requestRide("Troy", "Albany", "2025-07-13 11:00:00", "Need room for bags and luggage");
        console.log("Ride Requested:", rideID);
        vm.stopBroadcast();

        vm.startBroadcast(driverKey);
        driverContract.proposeRidePrice(rideID, 100);
        vm.stopBroadcast();

        vm.startBroadcast(riderKey);
        riderContract.selectBestOffer{value: 100 wei}(rideID);
        riderContract.confirmDeparture(rideID);
        riderContract.confirmArrival(rideID);
        riderContract.sendReview(rideID, "GOOD JOB BOSS!!");
        vm.stopBroadcast();

        vm.startBroadcast(driverKey);  // Using driver's private key to call the function
        (driverAddress, collateral, rating, rideCount, registered) = driverContract.viewMyDriverData();
        vm.stopBroadcast();

        // Log the driver data
        console.log("Driver Address:", driverAddress);
        console.log("Driver Collateral:", collateral);
        console.log("Driver Rating:", rating);
        console.log("Driver Ride Count:", rideCount);
        console.log("Driver Registered:", registered);

        vm.startBroadcast(driverKey);  // Using driver's private key to call the function
        driverContract.withdrawRequest();
        vm.stopBroadcast();

        console.log("Driver Balance (wei):", vm.addr(driverKey).balance);
    }
}
