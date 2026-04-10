// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Log {
    struct Record {
        string message;
        address author;
        uint256 timestamp;
    }

    Record[] public records;
    address public owner;

    event RecordCreated(uint256 indexed id, address indexed author, string message, uint256 timestamp);
    event RecordDeleted(uint256 indexed id, address indexed deletedBy);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addRecord(string calldata message) external {
        require(bytes(message).length > 0, "Message cannot be empty");
        records.push(Record({
            message: message,
            author: msg.sender,
            timestamp: block.timestamp
        }));

        emit RecordCreated(records.length - 1, msg.sender, message, block.timestamp);
    }

    function getRecord(uint256 id) external view returns (Record memory) {
        require(id < records.length, "Record does not exist");
        return records[id];
    }

    function totalRecords() external view returns (uint256) {
        return records.length;
    }

    function deleteRecord(uint256 id) external onlyOwner {
        require(id < records.length, "Record does not exist");

        records[id] = records[records.length - 1];
        records.pop();

        emit RecordDeleted(id, msg.sender);
    }
}