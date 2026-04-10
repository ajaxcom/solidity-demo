// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract MyToken {
    string public name; // 代币名称
    string public symbol; // 代币符号
    uint8 public decimals; // 代币精度

    uint256 public totalSupply; // 总供应量
    mapping(address => uint256) public balanceOf; // 地址 => 余额
    mapping(address => mapping(address => uint256)) public allowance; // 所有者 => (被授权人 => 可花费数量)

    // 标准事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // 构造函数
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply // 初始供应量
    ) {
        name = _name;
        symbol = _symbol;
        decimals = 18;

        // 把初始供应量给部署者
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;

        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    // 转账
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    // 授权他人代花费额度
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // 代扣转账：由被授权人把 from 的代币转给 to
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");

        if (currentAllowance != type(uint256).max) {
            unchecked {
                allowance[from][msg.sender] = currentAllowance - amount;
            }
        }

        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");

        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= amount, "ERC20: insufficient balance");

        unchecked {
            balanceOf[from] = fromBalance - amount;
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
}
