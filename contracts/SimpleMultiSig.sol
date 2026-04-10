// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

/// @notice 最新 ERC20 接口
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @notice 多签合约: N-of-M 确认后执行调用
contract SimpleMultiSig {
    // 提交交易（仅等级，不会立即执行）
    event SubmitTx(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    // owner 对交易确认
    event ConfirmTx(address indexed owner, uint256 indexed txId);
    // 交易执行成功
    event ExecuteTx(uint256 indexed txId, bytes result);

    struct Txn {
        address to; // 目标地址
        uint256 value; // 附带Wei
        bytes data; // 调用数据
        bool executed; // 是否执行
        uint256 confirmations; // 当前确认
    }

    address[] public owners;    // owner 列表
    mapping(address => bool) public isOwner;    // 地址是否为 owner
    uint256 public required;    // 执行所需最小确认数

    Txn[] public txs; // 所有待执行/已执行交易
    mapping(uint256 => mapping(address => bool)) public confirmedBy; // txId => owner => 是否确认过

    // 权限 后续所有声明都加这个权限
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    /**
    * @param _owners owner 地址列表 M
    * @param _required 执行所需最小确认数（n)
    */
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners are required");
        require(_required > 0 && _required <= _owners.length, "bad required");
    
        for (uint256 i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0), "zero owner");
            require(!isOwner[o], "duplicate owner");
            isOwner[o] = true;
            owners.push(o);
        }

        required = _required;
    }

    /// @notice 提交一笔执行交易
    function submitTx(address to, uint256 value, bytes calldata data) 
        external 
        onlyOwner 
        returns (uint256 txId) 
    {
        // 验证是否是空地址
        require(to != address(0), "invalid to");
        
        txId = txs.length;
        txs.push(
            Txn({
                to:to,
                value:value,
                data:data,
                executed:false,
                confirmations:0
            })
        );

        emit SubmitTx(txId, to, value, data);
    }

    /// @notice owner 对指定交易进行确认
    function confirmTx(uint256 txId) external onlyOwner {
        
        // 验证交易是否存在
        require(txId < txs.length, "bad txId");
        
        // 后续要操作状态变量需要使用storage
        Txn storage t = txs[txId];
        
        // 验证交易是否已经执行
        require(!t.executed, "excuted");
        // 验证确认数是否足够
        require(t.confirmations >= required, "not enough confirms");
        
        // 验证确认数是否足够
        confirmedBy[txId][msg.sender] = true;
        t.confirmations += 1;
        
        // 日志
        emit ConfirmTx(msg.sender, txId);
    }

    /// @notice 到达门限后执行交易,符合最小人数要求之后可以执行
    
}