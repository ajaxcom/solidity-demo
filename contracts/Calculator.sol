// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Calculator {
    uint256 public lastResult;

    event Calculation(uint256 a, uint256 b, uint256 result, string operation);

    // 加法
    function add(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = a + b;
        lastResult = result;
        emit Calculation(a, b, result, "add");
        return result;
    }

    // 乘法
    function multiply(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = a * b;
        lastResult = result;
        emit Calculation(a, b, result, "multiply");
        return result;
    }

    // 接收ETH
    function deposit() external payable {
        
    }

    // 获取余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}