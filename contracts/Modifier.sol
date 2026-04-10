// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract ModifierExample {
    address public owner;
    uint256 public balance;
    bool public paused;
    mapping(address => bool) public whitelisted;

    constructor() {
        owner = msg.sender; // 部署合约的人称为 owner
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
}