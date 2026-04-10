// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Bank2 {
    address public owner;
    uint256 public totalMoney;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function withdrawAll() external onlyOwner {
        totalMoney = 0;
    }

    function deposit() external payable {
        totalMoney += msg.value;
    }
}