// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CryptoSpiral
 * @dev Simple ETH staking pool with time-based spiral multiplier on rewards
 * @notice Users stake ETH and earn rewards that grow the longer they stay staked
 */
contract CryptoSpiral {
    address public owner;

    uint256 public baseAPR;          // base APR in basis points (e.g. 500 = 5% per year)
    uint256 public maxMultiplierBP;  // extra multiplier in basis points at max duration (e.g. 10000 = +100%)
    uint256 public maxSpiralDays;    // days required to reach max multiplier

    uint256 public totalStaked;
    uint256 public totalRewardsDistributed;

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastClaimTime;
        bool    isActive;
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 timestamp);
    event RewardClaimed(address indexed user, uint256 reward, uint256 timestamp);
    event ParamsUpdated(uint256 baseAPR, uint256 maxMultiplierBP, uint256 maxSpiralDays);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier hasStake() {
        require(stakes[msg.sender].isActive && stakes[msg.sender].amount > 0, "No active stake");
        _;
    }

    constructor(
        uint256 _baseAPR,
        uint256 _maxMultiplierBP,
        uint256 _maxSpiralDays
    ) payable {
        owner = msg.sender;
        require(_maxSpiralDays > 0, "maxSpiralDays = 0");
        baseAPR = _baseAPR;
        maxMultiplierBP = _maxMultiplierBP;
        maxSpiralDays = _maxSpiralDays;
    }

    /**
     * @dev Stake ETH into the spiral pool
     */
    function stake() external payable {
        require(msg.value > 0, "Stake > 0");

        StakeInfo storage s = stakes[msg.sender];

        // If already staking, first claim pending rewards
        if (s.isActive && s.amount > 0) {
            _claimReward(msg.sender);
        } else {
            s.startTime = block.timestamp;
            s.lastClaimTime = block.timestamp;
            s.isActive = true;
        }

        s.amount += msg.value;
        totalStaked += msg.value;

        emit Staked(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Unstake a specific amount of ETH and claim rewards
     * @param amount Amount to unstake
     */
    function unstake(uint256 amount) external hasStake {
        StakeInfo storage s = stakes[msg.sender];
        require(amount > 0 && amount <= s.amount, "Invalid amount");

        // claim rewards before reducing position
        _claimReward(msg.sender);

        s.amount -= amount;
        totalStaked -= amount;

        if (s.amount == 0) {
            s.isActive = false;
        }

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Transfer failed");

        emit Unstaked(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Claim accumulated rewards without unstaking
     */
    function claimReward() external hasStake {
        uint256 reward = _claimReward(msg.sender);
        require(reward > 0, "No reward");
    }

    /**
     * @dev Internal reward calculation and transfer
     */
    function _claimReward(address user) internal returns (uint256 reward) {
        StakeInfo storage s = stakes[user];
        reward = calculateReward(user);

        if (reward > 0) {
            s.lastClaimTime = block.timestamp;
            totalRewardsDistributed += reward;

            (bool ok, ) = payable(user).call{value: reward}("");
            require(ok, "Reward transfer failed");

            emit RewardClaimed(user, reward, block.timestamp);
        }
    }

    /**
     * @dev Calculate pending reward for a user using spiral multiplier
     * Formula:
     *  timeFactor = (block.timestamp - lastClaimTime)
     *  aprEffective = baseAPR * (1 + spiralMultiplier)
     *  spiralMultiplier = min( (daysStaked / maxSpiralDays) * maxMultiplierBP / 10000, maxMultiplierBP / 10000 )
     */
    function calculateReward(address user) public view returns (uint256) {
        StakeInfo memory s = stakes[user];
        if (!s.isActive || s.amount == 0) return 0;

        uint256 timeElapsed = block.timestamp - s.lastClaimTime;
        if (timeElapsed == 0 || baseAPR == 0) return 0;

        // days staked since original start
        uint256 daysStaked = (block.timestamp - s.startTime) / 1 days;
        if (daysStaked > maxSpiralDays) {
            daysStaked = maxSpiralDays;
        }

        // spiral multiplier in basis points (0 to maxMultiplierBP)
        uint256 spiralBP = (daysStaked * maxMultiplierBP) / maxSpiralDays;

        // effective APR in basis points: baseAPR * (1 + spiralBP/10000)
        uint256 effectiveAprBP = baseAPR + (baseAPR * spiralBP) / 10000;

        // reward = amount * effectiveAprBP * timeElapsed / (10000 * 365 days)
        uint256 reward = (s.amount * effectiveAprBP * timeElapsed) / (10000 * 365 days);

        // cap reward to contract balance for safety
        uint256 balance = address(this).balance;
        if (reward > balance) {
            reward = balance;
        }

        return reward;
    }

    /**
     * @dev Owner can update spiral parameters
     */
    function updateParams(
        uint256 _baseAPR,
        uint256 _maxMultiplierBP,
        uint256 _maxSpiralDays
    ) external onlyOwner {
        require(_maxSpiralDays > 0, "maxSpiralDays = 0");
        baseAPR = _baseAPR;
        maxMultiplierBP = _maxMultiplierBP;
        maxSpiralDays = _maxSpiralDays;

        emit ParamsUpdated(_baseAPR, _maxMultiplierBP, _maxSpiralDays);
    }

    /**
     * @dev Get contract ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Transfer ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}
