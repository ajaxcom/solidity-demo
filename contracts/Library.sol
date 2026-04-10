// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Library {
    uint256 public storedValue;
    address public owner;

    // 设置值
    function setValue(uint256 _value) external {
        storedValue = _value;
    }

    // 增加值
    function increment() external {
        storedValue += 1;
    }

    // 设置所有者
    function setOwner(address _owner) external {
        owner = _owner;
    }

    // 获取值
    function getValue() public view returns (uint256) {
        return storedValue;
    }
}