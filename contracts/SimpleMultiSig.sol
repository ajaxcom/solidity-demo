// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice 最小 ERC20 接口（本示例仅使用 transfer / balanceOf）
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @notice 最小多签：M 个 owner 至少 N 个确认后执行交易
contract SimpleMultiSig {
    // 仅登记交易，不会立即执行
    event SubmitTx(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    // owner 完成一次确认
    event ConfirmTx(address indexed owner, uint256 indexed txId);
    // 达到门限后执行成功
    event ExecuteTx(uint256 indexed txId, bytes result);

    struct Txn {
        address to;             // 目标地址（合约或 EOA）
        uint256 value;          // 附带 ETH（wei）
        bytes data;             // 调用数据（函数选择器+参数）
        bool executed;          // 是否已执行
        uint256 confirmations;  // 已确认数量
    }

    address[] public owners; // owner 列表（M）
    mapping(address => bool) public isOwner; // 快速判断地址是否 owner
    uint256 public required; // 执行所需最小确认数（N）

    Txn[] public txs; // 所有待执行/已执行交易
    mapping(uint256 => mapping(address => bool)) public confirmedBy; // txId => owner => 是否确认过

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "owners empty");
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

    /// @notice 提交一笔待执行交易
    function submitTx(address to, uint256 value, bytes calldata data) external onlyOwner returns (uint256 txId) {
        require(to != address(0), "zero to");

        txId = txs.length;
        txs.push(
            Txn({
                to: to,
                value: value,
                data: data,
                executed: false,
                confirmations: 0
            })
        );

        emit SubmitTx(txId, to, value, data);
    }

    /// @notice owner 对指定交易进行确认
    function confirmTx(uint256 txId) external onlyOwner {
        require(txId < txs.length, "bad txId");
        Txn storage t = txs[txId];

        require(!t.executed, "executed");
        require(!confirmedBy[txId][msg.sender], "already confirmed");

        confirmedBy[txId][msg.sender] = true;
        t.confirmations += 1;

        emit ConfirmTx(msg.sender, txId);
    }

    /// @notice 达到门限后执行交易
    function executeTx(uint256 txId) external onlyOwner returns (bytes memory result) {
        require(txId < txs.length, "bad txId");
        Txn storage t = txs[txId];

        require(!t.executed, "executed");
        require(t.confirmations >= required, "not enough confirms");

        t.executed = true; // 先标记，防止重入执行
        (bool ok, bytes memory ret) = t.to.call{value: t.value}(t.data);
        require(ok, "call failed");

        emit ExecuteTx(txId, ret);
        return ret;
    }

    receive() external payable {}
}

/**
 * @title SimpleTimeLock
 * @notice 最小时间锁：管理员先 queue，等待最小延迟后 execute
 * @dev 建议 admin 设置为多签地址，即可组合成“多签+时间锁”
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

    constructor(address _admin, uint256 _minDelay) {
        require(_admin != address(0), "zero admin");
        require(_minDelay > 0, "delay=0");
        admin = _admin;
        minDelay = _minDelay;
    }

    /// @notice 通过参数计算唯一操作 ID
    function getOpId(address target, uint256 value, bytes calldata data, uint256 eta)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(target, value, data, eta));
    }

    /// @notice 排队一个未来操作，eta 需满足最小延迟
    function queue(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        onlyAdmin
        returns (bytes32 opId)
    {
        require(target != address(0), "zero target");
        require(eta >= block.timestamp + minDelay, "eta too soon");

        opId = getOpId(target, value, data, eta);
        require(!queued[opId], "already queued");

        queued[opId] = true;
        emit Queue(opId, target, value, data, eta);
    }

    /// @notice 执行排队操作；为了可用性，任何地址都可触发执行
    function execute(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        payable
        returns (bytes memory result)
    {
        bytes32 opId = getOpId(target, value, data, eta);

        require(queued[opId], "not queued");
        require(block.timestamp >= eta, "too early");

        queued[opId] = false;
        (bool ok, bytes memory ret) = target.call{value: value}(data);
        require(ok, "call failed");

        emit Execute(opId, target, value, data);
        return ret;
    }

    /// @notice 管理员可取消排队操作
    function cancel(bytes32 opId) external onlyAdmin {
        require(queued[opId], "not queued");
        queued[opId] = false;
        emit Cancel(opId);
    }
}

/**
 * @title LinearVestingVault
 * @notice 线性锁仓：start 到 start+duration 期间按线性比例释放 totalAmount
 * @dev 管理操作（如改 beneficiary）仅能通过 timelock
 */
contract LinearVestingVault {
    event Released(uint256 amount, uint256 totalReleased);
    event BeneficiaryChanged(address indexed oldB, address indexed newB);

    IERC20 public immutable token; // 锁仓代币
    address public beneficiary; // 收款受益人
    address public immutable timelock; // 管理权限来源

    uint64 public immutable start; // 开始时间戳
    uint64 public immutable duration; // 线性释放时长（秒）
    uint256 public immutable totalAmount; // 总锁仓额度
    uint256 public released; // 已释放额度

    modifier onlyTimelock() {
        require(msg.sender == timelock, "not timelock");
        _;
    }

    constructor(
        address _token,
        address _beneficiary,
        uint64 _start,
        uint64 _duration,
        uint256 _totalAmount,
        address _timelock
    ) {
        require(_token != address(0), "zero token");
        require(_beneficiary != address(0), "zero beneficiary");
        require(_duration > 0, "duration=0");
        require(_totalAmount > 0, "amount=0");
        require(_timelock != address(0), "zero timelock");

        token = IERC20(_token);
        beneficiary = _beneficiary;
        start = _start;
        duration = _duration;
        totalAmount = _totalAmount;
        timelock = _timelock;
    }

    /// @notice 某时间点已归属总量（线性）
    function vestedAmount(uint256 timestamp) public view returns (uint256) {
        if (timestamp <= start) return 0;
        if (timestamp >= start + duration) return totalAmount;

        uint256 elapsed = timestamp - start;
        return (totalAmount * elapsed) / duration;
    }

    /// @notice 当前可领取额度 = 已归属 - 已领取
    function releasable() public view returns (uint256) {
        uint256 vested = vestedAmount(block.timestamp);
        if (vested <= released) return 0;
        return vested - released;
    }

    /// @notice 任何人都可触发释放，资金只会转给 beneficiary
    function release() external {
        uint256 amount = releasable();
        require(amount > 0, "nothing releasable");

        released += amount;
        require(token.transfer(beneficiary, amount), "token transfer failed");

        emit Released(amount, released);
    }

    /// @notice 示例管理操作：更换受益人（必须由 timelock 调用）
    function setBeneficiary(address newBeneficiary) external onlyTimelock {
        require(newBeneficiary != address(0), "zero beneficiary");
        address old = beneficiary;
        beneficiary = newBeneficiary;
        emit BeneficiaryChanged(old, newBeneficiary);
    }
}