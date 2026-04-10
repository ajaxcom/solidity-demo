// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract SimpleCounter {
    uint256 public count;
    address public owner;

    error NotOwner();
    error CountTooHigh(uint256 currentCount);

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();  // 使用自定义错误
        }
        _;
    }

    constructor() {
        owner = msg.sender;
        count = 0;
    }

    function increment() external {
        count++;
    }

    function reset() external onlyOwner {
        count = 0;
    }

    function setCount(uint256 newCount) external onlyOwner {
        if (newCount > 100) {
            revert CountTooHigh(newCount);
        }
        count = newCount;
    }
}