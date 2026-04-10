// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Storage {
    uint256 private value;

    function set(uint _value) public {
        value = _value;
    }

    function get() public view returns (uint256) {
        return value;
    }
}