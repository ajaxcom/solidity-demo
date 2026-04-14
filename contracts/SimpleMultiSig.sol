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
        function executeTx(uint256 txId) external onlyOwner returns (bytes memory result) {
        require(txId < txs.length, "bad txId");
        Txn storage t = txs[txId];
        require(!t.executed, "executed");
        require(t.confirmations >= required, "not enough confirms");
        t.executed = true;
        (bool ok, bytes memory ret) = t.to.call{value: t.value}(t.data);
        require(ok, "call failed");
        emit ExecuteTx(txId, ret);
        return ret;
    }

    receive() external payable {}
}

/**
 * @title SimpleTimelock
 * @notice 最小时间锁：管理员先 queue，等待最小延迟后 execute
 * @dev 建议 admin 设置为多签合约地址，这样就是“多签 + 时间锁”组合
 */
contract SimpleTimeLock {
    event Queue(bytes32 indexed opId, address indexed target, uint256 value, bytes data, uint256 eta);
    event Execute(bytes32 indexed opId, address indexed target, uint256 value, bytes data);
    event Cancel(bytes32 indexed opId);

    address public admin;          // 管理员（建议是多签）
    uint256 public immutable minDelay; // 最小延迟（秒）

    // opId 是否已排队（queued）
    mapping(bytes32 => bool) public queued;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    // 传递进来参数 地址和最小时间
    constructor(address _admin, uint256 _minDelay) {
        require(_admin != address(0), "zero admin");
        require(_minDelay > 0, "delay=0");        
        admin = _admin;
        minDelay = _minDelay;
    }

    /// @notice 通过参数确定唯一操作ID 
    // calldata 表示只读，只能读不能改
    // memory data 会拷贝到内存可修改
    // pure 表示只计算，这个函数不上状态
    // keccak256 是一个哈希函数，它将输出的数据是固定的256位长度
    // 实现原理是内部有一个 固定 1600位 200个字节 的状态数组，将给出的字符补充为 1088位，数据库，异或进入水箱进行异或运算，超过的会形成多个数据块
    // abi.encode 以太坊 abi 标准，将参数转换为 evm可执行的16进制数据
    function getOpId(address target, uint256 value, bytes calldata data, uint256 eta)
        public
        pure   
        returns (bytes32)
    {
        return keccak256(abi.encode(target, value, data, eta));
    }

    /*
    * @notice 排队一个将来可执行的操作
    * @param target 目标地址
    * @param value 附带Wei
    * @param data 调用数据
    * @param eta 最早执行时间 >= block.timestamp +minDelay
    * onlyAdmin 代表只有管理员才能调用这个函数，否则交易会回滚
    *
     */
    function queue(address target, uint256 value, bytes calldata data, uint256 eta) 
        external 
        onlyAdmin 
        returns (bytes32 opId)
    {
        // 验证target是否是地址
        require(target != address(0), "zero target");

        // 验证eta是否大于最小延迟，不允许eat比出口
        require(eta >= block.timestamp + minDelay, "eta too soon");

        // 获取唯一的操作ID，openId已经在函数签名声明bytes32 所以这里必须要再次声明
        opId = getOpId(target, value, data, eta);
        
        // 查看是否已经排队
        require(!queued[opId], "already queued");

        // 未排队设置未已排队状态
        queued[opId] = true;

        // 加入日志
        emit Queue(opId, target, value, data, eta);
    }

    /// @notice 执行一个已经排队的操作
    function execute(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        payable
        onlyAdmin
        returns (bytes memory result)
    {
        bytes32 opId = getOpId(target, value, data, eta);

        // 验证这个操作是否已经排队
        require(queued[opId], "not queued");
        // 验证最小时间是否已经到达
        require(block.timestamp >= eta, "too early");

        // 先标记状态
        queued[opId] = false;
        (bool ok, bytes memory ret) = target.call{value: value}(data);
        
        // 验证调用是否成功
        require(ok, "call failed");
    
        emit Execute(opId, target, value, data);
        return ret;
    }

    // 管理员取消排队操作
    function cancel(bytes32 opId) external onlyAdmin {
        require(queued[opId], "not queued");
        queued[opId] = false;

        emit Cancel(opId);
    }
}

/**
* @title LinearVestingVault
* @notice 线性锁仓金库：从 start 开始到 start+duration 线性释放 totalAmount
* @dev 管理操作（如改受益人）只能由 timelock 调用
*/
contract LinearVestingVault {

    // 日志
    event Released(uint256 amount, uint256 totalReleased);
    event BeneficiaryChanged(address indexed oldB, address indexed newB);

    // immutable 表示在合约部署时初始化，之后不能修改，仅有一次赋值的机会
    IERC20 public immutable token;          // 被锁定的代币

    address public beneficiary;       // 受益人（接收释放代币）
    address public immutable timelock; // 时间锁地址（管理权限）

    uint64 public immutable start;          // 开始时间戳
    uint64 public immutable duration;       // 释放总市场（秒）
    uint256 public immutable totalAmount;   // 锁仓总额
    uint256 public released;                // 已释放总量

    modifier onlyTimelock() {
        require(msg.sender == timelock, "not timelock");
    }

    
}