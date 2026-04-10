// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IsimpleStorage {
    function setValue(uint256 _value) external;

    function getValue() external view returns (uint256);
    
    function increment(uint256 _amount) external returns (uint256);
}

// 调用者
contract StorageCaller {
    address public storageAddress;

    // 使用接口类型声明变量
    IsimpleStorage public storageContract;

    event ExternalCallSucceeded(string functionName, uint256 result);
    event ExternalCallFailed(string functionName, string reason);

    constructor(address _storageAddress) {
        storageAddress = _storageAddress;
        storageContract = IsimpleStorage(_storageAddress);
    }

    // 方式 1 ：通过接口调用外部合约
    function callSetValue(uint256 _value) external {
        storageContract.setValue(_value);
        
        emit ExternalCallSucceeded("setValue", _value);
    }

    // 方式2：调有返回值的函数
    function callIncrement(uint256 _amount) external returns (uint256) {
        // 调用外部合约的函数并接收返回值
        uint256 newValue = storageContract.increment(_amount);

        emit ExternalCallSucceeded("increment", newValue);
        return newValue;  // 修复：移除多余的 "new"
    }
}
