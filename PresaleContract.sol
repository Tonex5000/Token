// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20Token.sol";
import "./Ownable.sol"; // Import the Ownable contract
import "@api3/contracts/v0.8/interfaces/IProxy.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Presale is Ownable { // Inherit from Ownable
    address public admin;
    BEP20Token public token;
    uint256 public totalRaised;
    uint256 public currentStage;
    int224 public currentStagePrice; // Price per BLAB token in BUSD (in decimal)
    int256 public currentStageTokensLeft;
    int256 public currentStageHardcap;
    uint256 public totalSold;
    uint256 public refundPool;
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public refunds;
    uint256 public claimDeadline;
    address public proxyAddress;
    int224 public bnbPrice;
    mapping(address => uint256) public stage1Contributions;
    mapping(address => uint256) public stage2Contributions;
    mapping(address => uint256) public stage3Contributions;
    mapping(address => uint256) public stage4Contributions;
    mapping(address => uint256) public stage5Contributions;
    mapping(address => uint256) public stage6Contributions;
    // Define mappings for other stages as needed


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
        //claimDeadline = block.timestamp + 30;
    }

    function setProxyAddress(address _proxyAddress) public onlyOwner {
        proxyAddress = _proxyAddress;
    }

    function readDataFeed() external {
        (bnbPrice,) = IProxy(proxyAddress).read();
    }

    function setCurrentStageParams() private {
        bnbPrice = bnbPrice/10 ** 18;
        if (currentStage == 1) {
            currentStageTokensLeft = 20000000;
            currentStagePrice = int224(0.02 * 10**20) / bnbPrice; // BNB price in wei 0.02 * 10**2
            currentStageHardcap = currentStageTokensLeft * currentStagePrice; //int224(400000) / bnbPrice;  400,000 BUS
        } else if (currentStage == 2) {
            currentStagePrice = int224(0.03 * 10**20)/bnbPrice; // $0.03 in BUSD (in decimal)
            currentStageTokensLeft = 20000000;
            currentStageHardcap = currentStageTokensLeft * currentStagePrice; // 600,000 BUSD
        } else if (currentStage == 3) {
            currentStagePrice = int224(0.05 * 10**20)/bnbPrice; // $0.05 in BUSD (in decimal)
            currentStageTokensLeft = 40000000;
            currentStageHardcap = currentStageTokensLeft * currentStagePrice; // 2,000,000 BUSD
        } else if (currentStage == 4) {
            currentStagePrice = int224(0.065 * 10**21)/bnbPrice; // $0.065 in BUSD (in decimal)
            currentStageTokensLeft = 40000000;
            currentStageHardcap = currentStageTokensLeft * currentStagePrice; // 2,600,000 BUSD
        } else if (currentStage == 5) {
            currentStagePrice = int224(0.065 * 10**21)/bnbPrice; // $0.085 in BUSD (in decimal)
            currentStageTokensLeft = 40000000;
            currentStageHardcap = currentStageTokensLeft * currentStagePrice; // 3,400,000 BUSD
        } else if (currentStage == 6) {
            currentStagePrice = int224(0.1 * 10**19)/bnbPrice; // $0.10 in BUSD (in decimal)
            currentStageTokensLeft = 40000000;
            currentStageHardcap = currentStageTokensLeft * currentStagePrice; // 4,000,000 BUSD
        } else if (currentStage == 7) {
            currentStagePrice = 0; // $0.10 in BUSD (in decimal)
            currentStageTokensLeft = 0; //40_000_000 * (10 ** uint256(token.decimals()));
            currentStageHardcap = 0; //4_000_000 * (10 ** uint256(token.decimals())); // 4,000,000 BUSD
        }
    }



    function buyTokens(int256 numberOfTokens) external payable {
        require(currentStage > 0, "Presale: Presale has not started");
        require(currentStage <= 6, "Presale: Presale has ended");
        require(bnbPrice != 0, "Presale: BNB price is not initialized or is zero");

        // Calculate the total value of tokens being purchased
        uint256 tokensValue = SafeMath.mul(uint256(int256(numberOfTokens)), uint256(int256(currentStagePrice)));


        // Check if the total value of funds raised does not exceed the hard cap
        require((totalRaised + (tokensValue)) <= uint256(currentStageHardcap), "Presale: Hardcap reached for current stage");

        // Check if the number of tokens to buy is greater than zero and within the available tokens
        require(uint256(int256(numberOfTokens)) > 0, "Presale: Number of tokens to buy must be greater than zero");
        require(uint256(int256(numberOfTokens)) <= uint256(currentStageTokensLeft), "Presale: Insufficient tokens available for purchase");

        // Transfer tokens to the buyer
        token.transfer(msg.sender, uint256(numberOfTokens));

        // Update contract state variables
        totalRaised = totalRaised + (tokensValue);
        currentStageTokensLeft -= (numberOfTokens);
        totalSold = totalSold + (uint256(numberOfTokens));
        contributions[msg.sender] = contributions[msg.sender] + uint256(int256(tokensValue));

        // Emit an event to log the purchase
        emit TokensPurchased(msg.sender, uint256(numberOfTokens), tokensValue);
    }

    function contractTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function claimRefund() external {
        require(currentStage > 6, "Presale: Presale is not over yet");
        //require(block.timestamp <= claimDeadline, "Presale: Claim deadline has passed");
        uint256 userRefund = refunds[msg.sender];
        require(userRefund > 0, "Presale: No refund available for user");

        refunds[msg.sender] = 0;
        payable(msg.sender).transfer(userRefund);
         
        emit RefundClaimed(msg.sender, userRefund);
    }

    function withdrawFunds() external onlyAdmin {
        require(currentStage > 6, "Presale: Presale is not over yet");
        //require(block.timestamp > claimDeadline, "Presale: Claim deadline has not passed yet");
        payable(admin).transfer(address(this).balance);
    }

    function withdrawUnsoldTokens() external onlyAdmin {
        require(currentStage > 6, "Presale: Presale is not over yet");
        uint256 unsoldTokens = token.balanceOf(address(this));
        token.transfer(admin, unsoldTokens);
    }

    function withdrawClaimForCurrentStage() external {
        require(currentStage > 1, "Presale: Withdrawal not available for current stage");

        uint256 userClaim = 0;
        
        if (currentStage == 2) {
            require(currentStage == 2, "Presale: Withdrawal not available for current stage");
            userClaim = contributions[msg.sender];
        } else if (currentStage == 3) {
            require(currentStage == 3, "Presale: Withdrawal not available for current stage");
            userClaim = stage2Contributions[msg.sender];
        } else if (currentStage == 4) {
            require(currentStage == 4, "Presale: Withdrawal not available for current stage");
            userClaim = stage3Contributions[msg.sender];
        } else if (currentStage == 5) {
            require(currentStage == 5, "Presale: Withdrawal not available for current stage");
            userClaim = stage4Contributions[msg.sender];
        } else if (currentStage == 6) {
            require(currentStage == 6, "Presale: Withdrawal not available for current stage");
            userClaim = stage5Contributions[msg.sender];
        } else {
            require(currentStage > 6, "Presale: Withdrawal not available for current stage");
            userClaim = stage6Contributions[msg.sender];
        }

        require(userClaim > 0, "Presale: No claim available for user at this stage");

        contributions[msg.sender] = 0;
        refunds[msg.sender] += userClaim;

        emit RefundClaimed(msg.sender, userClaim);
    }



    // Function to increase the stage externally
    function increaseStage() external {
        require(currentStage < 7, "Presale: Presale has ended.");
        currentStage++;
        setCurrentStageParams(); // Update stage parameters
    }
}
