// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AIRatingOracleContract {
    address public owner;
    mapping(address => uint256) public driverScores;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    //In the future this function will interface with the AI component to calculate "newScore"
    function updateDriverScore(address driver, uint256 newScore) external onlyOwner {
        driverScores[driver] = newScore;
    }

    //This function will be called by other processes to get the drivers score when needed
    function getDriverScore(address driver) external view returns (uint256) {
        return driverScores[driver];
    }
}
