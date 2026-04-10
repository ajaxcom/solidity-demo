// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Wallet {

    // 用户地址 =》 余额
    mapping(address => uint256) public balances;

    // 合约当前持有的总 ETH
    uint256 public totalDeposited;

    // 存款
    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 newBalance
    );

    // 取款
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 newBalance
    );

    // 存款
    function deposit() external payable {
        require(msg.value > 0, "Wallet: amount must be > 0");

        // 增加余额
        balances[msg.sender] += msg.value;
        totalDeposited += msg.value;

        // 触发事件
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }

    // 取款
    function withdraw(uint256 amount) external {
        require(amount > 0, "Wallet: amount must be > 0");
        require(balances[msg.sender] >= amount, "Wallet: insufficient balance");

        balances[msg.sender] -= amount;
        totalDeposited -= amount;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Wallet: transfer failed");

        emit Withdraw(msg.sender, amount, balances[msg.sender]);
    }

    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }
}