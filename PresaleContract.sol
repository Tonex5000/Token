//Contract Address: "0xe76a47353Aa017DF4bF3C69573a4DAa1312c6877"

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20Token.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Presale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // State variables
    address public admin;
    BEP20Token public token;
    uint256 public totalRaised;
    uint256 public currentStage;
    uint256 public currentStagePrice;
    uint256 public currentStageTokensLeft;
    uint256 public currentStageHardcap;
    uint256 public totalSold;
    uint256 public refundPool;
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public refunds; 
    mapping(address => mapping(uint256 => uint256)) public userContributions;
    
    mapping(uint256 => uint256) public claimTimes;

    // Events
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 value);
    event RefundClaimed(address indexed user, uint256 amount);
    event TokensClaimed(address indexed user, uint256 amount);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Presale: caller is not the admin");
        _;
    }

    modifier nonZeroAmount() {
        require(msg.value > 0, "Presale: Ether value must be greater than 0");
        _;
    }

    // Constructor
    constructor(address _tokenAddress) {
        admin = msg.sender;
        token = BEP20Token(_tokenAddress);
        currentStage = 0;
        setCurrentStageParams();
    }

    // Set current stage parameters
    function setCurrentStageParams() private {
        if (currentStage == 1) {
            currentStageTokensLeft = 20000000;
            currentStagePrice = 33215604260000;
            currentStageHardcap = currentStageTokensLeft * currentStagePrice; // Use SafeMath mul
        } else if (currentStage >= 2 && currentStage <= 6) {
            currentStagePrice = [49823406400000, 83039010670000, 107913428700000, 141045420800000, 166195053300000][currentStage - 2];
            currentStageTokensLeft = 40000000;
            currentStageHardcap = currentStageTokensLeft * currentStagePrice; // Use SafeMath mul
        } else if (currentStage == 7) {
            currentStagePrice = 0;
            currentStageTokensLeft = 0;
            currentStageHardcap = 0;
        }
    }

    // View function to get contract token balance
    function contractTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Claim refund function
    function claimRefund() external nonReentrant {
        require(currentStage > 6, "Presale: Presale is not over yet");
        uint256 userRefund = refunds[msg.sender];
        require(userRefund > 0, "Presale: No refund available for user");

        refunds[msg.sender] = 0;
        payable(msg.sender).transfer(userRefund);
         
        emit RefundClaimed(msg.sender, userRefund);
    }

    // Withdraw funds function
    function withdrawFunds() external onlyAdmin {
        require(currentStage > 6, "Presale: Presale is not over yet");
        payable(admin).transfer(address(this).balance);
    }

    // Withdraw unsold tokens function
    function withdrawUnsoldTokens() external onlyAdmin {
        require(currentStage > 6, "Presale: Presale is not over yet");
        uint256 unsoldTokens = token.balanceOf(address(this));
        token.transfer(admin, unsoldTokens);
    }

// Function to buy tokens
    function buyTokens(uint256 numberOfTokens) external payable nonReentrant {
        require(currentStage > 0 && currentStage <= 6, "Presale: Presale has not started or has ended");

        // Calculate the total value of tokens being purchased
        uint256 tokensValue = numberOfTokens * currentStagePrice; // Assume currentStagePrice is defined elsewhere

        // Check if the number of tokens to buy is greater than zero
        require(numberOfTokens > 0, "Presale: Number of tokens to buy must be greater than zero");

        // Check if the total value of funds raised does not exceed the hard cap
        require((totalRaised + tokensValue) <= currentStageHardcap, "Presale: Hardcap reached for current stage");

        // Check if the user sent enough ETH
        require(msg.value >= tokensValue, "Presale: Insufficient ETH sent for approval");

        // Update contract state variables
        totalRaised += tokensValue;
        currentStageTokensLeft -= numberOfTokens;

        // Update user contributions for the current stage
        userContributions[msg.sender][currentStage] += numberOfTokens;

        // Handle excess ETH
        if (msg.value > tokensValue) {
            payable(msg.sender).transfer(msg.value - tokensValue);
        }

        // Emit an event to log the purchase
        emit TokensPurchased(msg.sender, numberOfTokens, tokensValue);
    }


  
  // Function to withdraw claim for the current stage
    function withdrawClaimForCurrentStage() external nonReentrant {
        require(currentStage > 1, "Presale: Withdrawal not available for current stage");

        uint256 userClaim = userContributions[msg.sender][currentStage - 1]; // Get user's contribution for the previous stage

        require(userClaim > 0, "Presale: No claim available for user at this stage");

        // Clear user's contribution for the previous stage
        userContributions[msg.sender][currentStage - 1] = 0;

        // Transfer tokens to the user
        token.transfer(msg.sender, userClaim);

        emit TokensClaimed(msg.sender, userClaim);
    }


    // Function to increase the stage externally
    function increaseStage() external {
        require(currentStage < 7, "Presale: Presale has ended.");
        currentStage++;
        setCurrentStageParams(); // Update stage parameters
    }
}

