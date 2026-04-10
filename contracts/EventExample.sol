// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract EventExample {
    mapping(address => uint256) public balances;
    address public owner;

    // 没有 indexed 无法过滤
    event SimpleTransfer(
        address from, 
        address to, 
        uint256 amount
    );

    // 有 indexed (可以过滤)
    event IndexedTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    // 部分参数 indexed
    event Deposit(
        address indexed account,   // 存款账户
        uint256 amount,             // 存款金额
        uint256 timestamp           // 时间戳
    );

    // 最多三个 indexed
    event ComplexEvent(
        address indexed User,
        uint256 indexed taskId,
        string indexed category,
        string description,
        uint256 value
    );

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(to != address(0), "Invalid address");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        // 触发两个事件进行对比
        emit SimpleTransfer(msg.sender, to, amount);
        emit IndexedTransfer(msg.sender, to, amount);
    }

    function createTask(uint256 taskId, string memory category, string memory description, uint256 value) external {
        emit ComplexEvent(msg.sender, taskId, category, description, value);
    }
}