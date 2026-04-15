// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;

    // 总供应量
    uint256 public totalSupply;

    // 地址 =>余额
    mapping(address => uint256) public balanceOf;
}