// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract StakingRewards {
    // Staking token (e.g., LISK)
    address public immutable stakingToken;
    
    // Reward rate per second
    uint256 public rewardRate = 1;  // 1 token per second
    
    // Timestamp of when the rewards finish
    uint256 public periodFinish = 0;
    
    // Last time the reward was calculated
    uint256 public lastUpdateTime;
    
    // Stored reward per token
    uint256 public rewardPerTokenStored;
    
    // User's last known reward per token paid
    mapping(address => uint256) public userRewardPerTokenPaid;
    
    // User rewards to be claimed
    mapping(address => uint256) public rewards;
    
    // Total staked amount
    uint256 private _totalSupply;
    
    // User staking balances
    mapping(address => uint256) private _balances;
    
    // Minimum staking period (7 days)
    uint256 public constant MINIMUM_STAKING_PERIOD = 7 days;
    
    // Staking periods and their multipliers (in days => multiplier)
    mapping(uint256 => uint256) public stakingMultipliers;
    
    // User staking end times
    mapping(address => uint256) public userStakingEndTime;

    // Events
    event Staked(address indexed user, uint256 amount, uint256 stakingPeriod);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
    event EmergencyWithdrawn(address indexed user, uint256 amount);

    constructor(address _stakingToken) {
        stakingToken = _stakingToken;
        
        // Initialize staking multipliers
        // 7 days = 1x multiplier
        stakingMultipliers[7] = 100;
        // 30 days = 1.5x multiplier
        stakingMultipliers[30] = 150;
        // 90 days = 2x multiplier
        stakingMultipliers[90] = 200;
        // 180 days = 3x multiplier
        stakingMultipliers[180] = 300;
    }

    // Modifier to update reward for a user
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // Returns the last time the reward was applicable
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // Calculates the reward per token
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    // Calculates earned rewards for an account
    function earned(address account) public view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    // Stakes tokens for a specific period
    function stake(uint256 amount, uint256 stakingPeriodInDays) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        require(stakingMultipliers[stakingPeriodInDays] > 0, "Invalid staking period");
        
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        userStakingEndTime[msg.sender] = block.timestamp + (stakingPeriodInDays * 1 days);
        
        // Transfer tokens to contract
        (bool success,) = stakingToken.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", 
            msg.sender, 
            address(this), 
            amount)
        );
        require(success, "Transfer failed");
        
        emit Staked(msg.sender, amount, stakingPeriodInDays);
    }

    // Withdraws staked tokens
    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(block.timestamp >= userStakingEndTime[msg.sender], "Staking period not finished");
        
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        
        // Transfer tokens back to user
        (bool success,) = stakingToken.call(
            abi.encodeWithSignature("transfer(address,uint256)", 
            msg.sender, 
            amount)
        );
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }

    // Claims rewards
    function getReward() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            
            // Calculate bonus based on staking period
            uint256 stakingPeriod = (userStakingEndTime[msg.sender] - block.timestamp) / 1 days;
            uint256 multiplier = stakingMultipliers[stakingPeriod];
            uint256 bonusReward = (reward * multiplier) / 100;
            
            // Transfer reward tokens to user
            (bool success,) = stakingToken.call(
                abi.encodeWithSignature("transfer(address,uint256)", 
                msg.sender, 
                bonusReward)
            );
            require(success, "Transfer failed");
            
            emit RewardPaid(msg.sender, bonusReward);
        }
    }

    // Emergency withdraw function
    function emergencyWithdraw() external {
        uint256 amount = _balances[msg.sender];
        require(amount > 0, "No tokens staked");
        
        // Apply penalty for early withdrawal (20%)
        uint256 penalty = (amount * 20) / 100;
        uint256 withdrawAmount = amount - penalty;
        
        _totalSupply -= amount;
        _balances[msg.sender] = 0;
        rewards[msg.sender] = 0;
        
        // Transfer remaining tokens back to user
        (bool success,) = stakingToken.call(
            abi.encodeWithSignature("transfer(address,uint256)", 
            msg.sender, 
            withdrawAmount)
        );
        require(success, "Transfer failed");
        
        emit EmergencyWithdrawn(msg.sender, withdrawAmount);
    }

    // View functions
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function getStakingMultiplier(uint256 stakingPeriodInDays) external view returns (uint256) {
        return stakingMultipliers[stakingPeriodInDays];
    }

    function getRemainingStakingTime(address account) external view returns (uint256) {
        if (block.timestamp >= userStakingEndTime[account]) return 0;
        return userStakingEndTime[account] - block.timestamp;
    }
}
