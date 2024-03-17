// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20Token.sol";
import "./Ownable.sol"; // Import the Ownable contract

contract Presale is Ownable { // Inherit from Ownable
    address public admin;
    BEP20Token public token;
    uint256 public totalRaised;
    uint256 public currentStage;
    uint256 public currentStageTokensLeft;
    uint256 public currentStageHardcap;
    uint256 public totalSold;
    uint256 public refundPool;
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public refunds;
    uint256 public claimDeadline;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 value);
    event RefundClaimed(address indexed user, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Presale: caller is not the admin");
        _;
    }

    constructor(address _tokenAddress) {
        admin = msg.sender;
        token = BEP20Token(_tokenAddress);
        currentStage = 0;
        setCurrentStageParams();
        // Set a default claim deadline (e.g., 30 days from contract deployment)
        claimDeadline = block.timestamp + 30 days;
    }

    function setCurrentStageParams() private {
        if (currentStage == 1) {
            currentStageTokensLeft = 20_000_000 * (10 ** uint256(token.decimals()));
            currentStageHardcap = 400_000; // 400,000 BLAB
        } else if (currentStage == 2) {
            currentStageTokensLeft = 20_000_000 * (10 ** uint256(token.decimals()));
            currentStageHardcap = 600_000; // 600,000 BLAB
        } else if (currentStage == 3) {
            currentStageTokensLeft = 40_000_000 * (10 ** uint256(token.decimals()));
            currentStageHardcap = 1_600_000; // 1,600,000 BLAB
        } else if (currentStage == 4) {
            currentStageTokensLeft = 40_000_000 * (10 ** uint256(token.decimals()));
            currentStageHardcap = 2_000_000; // 2,000,000 BLAB
        } else if (currentStage == 5) {
            currentStageTokensLeft = 40_000_000 * (10 ** uint256(token.decimals()));
            currentStageHardcap = 2_400_000; // 2,400,000 BLAB
        } else if (currentStage == 6) {
            currentStageTokensLeft = 40_000_000 * (10 ** uint256(token.decimals()));
            currentStageHardcap = 2_800_000; // 2,800,000 BLAB
        }
    }

    function buyTokens() external payable {
        require(currentStage > 0 && currentStage <= 6, "Presale: Presale has ended");
        require(totalRaised + msg.value <= currentStageHardcap, "Presale: Hardcap reached for current stage");

        uint256 tokensToBuy = (msg.value * 10**uint256(token.decimals())) / currentStagePrice;
        if (tokensToBuy > currentStageTokensLeft) {
            tokensToBuy = currentStageTokensLeft;
            refundPool += (msg.value - (tokensToBuy * currentStagePrice)) / (10**uint256(token.decimals()));
        }

        require(tokensToBuy > 0, "Presale: No tokens to buy");

        token.transfer(msg.sender, tokensToBuy);
        totalRaised += msg.value;
        currentStageTokensLeft -= tokensToBuy;
        totalSold += tokensToBuy;
        contributions[msg.sender] += msg.value;

        emit TokensPurchased(msg.sender, tokensToBuy, msg.value);

        if (currentStageTokensLeft == 0) {
            increaseStage(); // Increase the stage when tokens are sold out
            setCurrentStageParams();
        }
    }

    function claimRefund() external {
        require(currentStage > 6, "Presale: Presale is not over yet");
        require(block.timestamp <= claimDeadline, "Presale: Claim deadline has passed");
        uint256 userRefund = refunds[msg.sender];
        require(userRefund > 0, "Presale: No refund available for user");

        refunds[msg.sender] = 0;
        payable(msg.sender).transfer(userRefund);

        emit RefundClaimed(msg.sender, userRefund);
    }

    function withdrawFunds() external onlyAdmin {
        require(block.timestamp > claimDeadline, "Presale: Claim deadline has not passed yet");
        payable(admin).transfer(address(this).balance);
    }

    function withdrawUnsoldTokens() external onlyAdmin {
        require(currentStage > 6, "Presale: Presale is not over yet");
        uint256 unsoldTokens = token.balanceOf(address(this));
        token.transfer(admin, unsoldTokens);
    }

    function withdrawClaimForCurrentStage() external {
        require(currentStage > 1 && currentStage <= 6, "Presale: Withdrawal not available for current stage");

        uint256 userClaim = contributions[msg.sender];
        require(userClaim > 0, "Presale: No claim available for user");

        require(currentStage >= 2 && userClaim > 0, "Presale: No claim available for user");

        contributions[msg.sender] = 0;
        refunds[msg.sender] += userClaim;

        emit RefundClaimed(msg.sender, userClaim);
    }

    // Function to increase the stage externally
    function increaseStage() external onlyOwner {
        require(currentStage < 6, "Presale: Already at the final stage");
        currentStage++;
    }
}
