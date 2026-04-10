// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract DelegateCallExample {
    uint256 public storedValue;
    address public owner;
    address public libraryAddress;

    event DelegateCallExecuted(string functionName, bool success);

    constructor(address _libraryAddress) {
        libraryAddress = _libraryAddress;
        owner = msg.sender;
    }

    function setValue(uint256 _value) external returns (bool) {
        (bool success, ) = libraryAddress.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
        emit DelegateCallExecuted("setValue", success);
        return success;
    }
    
    function increment() external returns (bool) {
        (bool success, ) = libraryAddress.delegatecall(
            abi.encodeWithSignature("increment()")
        );
        emit DelegateCallExecuted("increment", success);
        return success;
    }

    function setOwner(address _owner) external returns (bool) {
        (bool success, ) = libraryAddress.delegatecall(
            abi.encodeWithSignature("setOwner(address)", _owner)
        );
        emit DelegateCallExecuted("setOwner", success);
        return success;
    } 

    // 获取值
    function getValue() external view returns (uint256) {
        return storedValue;
    }
}