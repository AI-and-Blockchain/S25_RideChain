// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {RegistrationContract} from "../src/RegistrationContract.sol";
import {AIRatingOracleContract} from "../src/AIRatingOracleContract.sol";
import {RideRequestContract} from "../src/RideRequestContract.sol";
import {DriverContract} from "../src/Driver.sol";
import {RiderContract} from "../src/Rider.sol";

contract CheckPostRideState is Script {
    function run() external {
        uint256 driverKey = vm.envUint("DRIVER_PRIVATE_KEY");

        RegistrationContract registration = RegistrationContract(payable(0x5FbDB2315678afecb367f032d93F642f64180aa3));
        AIRatingOracleContract aiRating = AIRatingOracleContract(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
        RideRequestContract rideRequest = RideRequestContract(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);
        DriverContract driverContract = DriverContract(payable(0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9));
        RiderContract riderContract = RiderContract(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9);

        // Fetch driver info
        vm.startBroadcast(driverKey);
        (address driverAddress, uint256 collateral, uint256 rating, uint256 rideCount, bool registered) =
            driverContract.viewMyDriverData();
        vm.stopBroadcast();

        console.log("Driver Address:", driverAddress);
        console.log("Driver Collateral:", collateral);
        console.log("Driver Rating:", rating);
        console.log("Driver Ride Count:", rideCount);
        console.log("Driver Registered:", registered);

        // Withdraw funds
        vm.startBroadcast(driverKey);
        try driverContract.withdrawRequest() {
            console.log("Withdrawal succeeded!");
        } catch Error(string memory reason) {
            console.log("Withdrawal reverted with reason:", reason);
        } catch {
            console.log("Withdrawal reverted with unknown error.");
        }
        vm.stopBroadcast();

        console.log("Driver Balance (wei):", vm.addr(driverKey).balance);
    }
}
