//Contract Address: "0x9BF8b88Da1e26aEC797d8B201abDb5893CC1074A"

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20Token.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title BlabStakingContract
 * @dev A contract for staking Blab tokens and earning rewards
 */
contract BlabStakingContract is ReentrancyGuard {
    // Token contract
    // Token contract
    BEP20Token public immutable stakingToken;

    // Reward rate per staked token per second
    uint256 public constant REWARD_RATE = 1e16; // 1 reward token per staked token per year

    // Minimum staking amount
    uint256 public constant MIN_STAKE_AMOUNT = 1e18; // 1 token

    // Maximum staking amount
    uint256 public constant MAX_STAKE_AMOUNT = 1e24; // 1 million tokens

    // Staking duration
    uint256 public constant STAKING_DURATION = 365 days; // 1 year

    // Struct to store staker information
    struct Staker {
        uint256 amount; // Amount of tokens staked
        uint256 rewardDebt; // Reward debt (used to calculate rewards)
        uint256 lastRewardTime; // Time of last reward calculation
    }

    // Mapping of stakers' addresses to staker information
    mapping(address => Staker) public stakers;

    // Total staked amount
    uint256 public totalStaked;

    // Contract deployment timestamp
    uint256 public immutable deploymentTime;

    // Events
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event RewardPaid(address indexed staker, uint256 reward);

    /**
     * @dev Constructor
     * @param _stakingToken Address of the token to be staked
     */
    constructor(address _stakingToken) {
        stakingToken = BEP20Token(_stakingToken);
        deploymentTime = block.timestamp;
    }

    /**
     * @dev Stake tokens
     * @param _amount Amount of tokens to stake
     */
    function stake(uint256 _amount) external nonReentrant {
        require(
            _amount >= MIN_STAKE_AMOUNT && _amount <= MAX_STAKE_AMOUNT,
            "Invalid staking amount"
        );
        require(
            stakingToken.balanceOf(msg.sender) >= _amount,
            "Insufficient balance"
        );

        updateReward(msg.sender);

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakers[msg.sender].amount += _amount;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Unstake tokens
     * @param _amount Amount of tokens to unstake
     */
    function unstake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            stakers[msg.sender].amount >= _amount,
            "Insufficient staked amount"
        );

        updateReward(msg.sender);

        stakingToken.transfer(msg.sender, _amount);
        stakers[msg.sender].amount -= _amount;
        totalStaked -= _amount;

        emit Unstaked(msg.sender, _amount);
    }

    /**
     * @dev Claim rewards
     */
    function claimReward() external nonReentrant {
        updateReward(msg.sender);

        uint256 reward = calculateReward(msg.sender);
        if (reward > 0) {
            stakingToken.transfer(msg.sender, reward);
            stakers[msg.sender].rewardDebt += reward;

            emit RewardPaid(msg.sender, reward);
        }
    }

    /**
     * @dev Update the reward for a staker
     * @param _staker Address of the staker
     */
    function updateReward(address _staker) internal {
        Staker storage staker = stakers[_staker];
        if (staker.amount > 0) {
            uint256 rewardDuration = block.timestamp - staker.lastRewardTime;
            if (rewardDuration > 0) {
                uint256 reward = (staker.amount * rewardDuration * REWARD_RATE) / 1e18;
                // Ensure no overflow or underflow
                require(reward <= type(uint256).max - staker.rewardDebt, "Reward overflow");
                staker.rewardDebt += reward;
            }
            staker.lastRewardTime = block.timestamp;
        }
    }   

    /**
     * @dev Calculate the reward for a staker
     * @param _staker Address of the staker
     * @return Reward amount
     */
    function calculateReward(address _staker) public view returns (uint256) {
        Staker memory staker = stakers[_staker];
        
        // Check if the staker has staked any amount
        if (staker.amount == 0) {
            return 0;
        }
        
        // Calculate reward duration and ensure it's non-negative
        uint256 rewardDuration = block.timestamp > staker.lastRewardTime ? block.timestamp - staker.lastRewardTime : 0;

        // Calculate reward and ensure all values are non-negative
        uint256 reward = (staker.amount * rewardDuration * REWARD_RATE) / 1e18;

        // Ensure the calculated reward is non-negative
        return reward >= staker.rewardDebt ? reward - staker.rewardDebt : 0;
    }   

    /**
     * @dev Recover any accidentally sent tokens
     * @param _token Address of the token to recover
     */
    function recoverToken(BEP20Token _token) external {
        require(
            _token != stakingToken,
            "Cannot recover staking or reward tokens"
        );
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "No tokens to recover");
        _token.transfer(msg.sender, balance);
    }
}
