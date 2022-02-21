//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GordionStrongboxBase.sol";
import "./IJoeRouter.sol";
import "./IGordionParticipantVoter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GordionShareToken.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract GordionTVInvestment is Ownable {

    GordionStrongbox strongbox;
    
    struct Film {
        string title;
        address creator;
        bytes32 creatorName;
        uint256 votingSeason;
        uint256 participantID;
        uint256 requiredInvestment;
        bytes32 movieURL;
        bytes32 contactEMail;
    }

    struct Investment {
        uint256 id;
        Film winner;
        mapping(address => uint256) investmentValue;
        uint256 totalInvestment;
        uint256 deadline;
        bool executed;
    }

    IGordionianParticipantVoter participantVoter;
    

    address GordionDAO;

    address joeAddress = address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    IJoeRouter02 joeRouter = IJoeRouter02(joeAddress);

    //Although all stable tokens listed here accepted payments will be with DAI

    address usdteAddress = address(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address usdtAddress = address(0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7);
    address usdceAddress = address(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
    address usdcAddress = address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
    address daiAddress = address(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70);

    IERC20 usdte = IERC20(usdteAddress);
    IERC20 usdt = IERC20(usdtAddress);
    IERC20 usdce = IERC20(usdceAddress);
    IERC20 usdc = IERC20(usdcAddress);
    IERC20 dai = IERC20(daiAddress);

    mapping(uint256 => Film) winnerOf;
    mapping(uint256 => bool) roundFinished;
    mapping(uint256 => Investment) investmentRound;
    mapping(uint256 => GordionShareToken) shareTokens;
    mapping(uint => bool) shareTokenCreated;
    uint256 private lastFinishedRound;

    constructor(address _participantVoter) {
        address[] memory admin = new address[](1);
        admin[0] = address(this);
        strongbox = new GordionStrongbox(admin, 1);
        participantVoter = IGordionianParticipantVoter(_participantVoter);
    }

    function getWinner(uint256 roundID) external onlyOwner {
        Film memory winner;
        (
            winner.title,
            winner.creator,
            winner.creatorName,
            winner.votingSeason,
            winner.participantID,
            winner.requiredInvestment,
            winner.movieURL,
            winner.contactEMail
        ) = participantVoter.getWinner(roundID);
        winnerOf[roundID] = winner;
        roundFinished[roundID] = true;
    }

    function investWinner(
        uint256 roundID,
        uint8 tokenID,
        uint256 value
    ) external {
        Investment storage currentInvestment = investmentRound[roundID];
        require(
            currentInvestment.deadline >= block.timestamp,
            "Investment period has finished"
        );
        require(tokenID <= 4, "Invalid token ID");
        IERC20 investmentToken;
        address investmentTokenAddress;
        if (tokenID == 0) {
            investmentToken = usdt;
            investmentTokenAddress = usdtAddress;
        } else if (tokenID == 1) {
            investmentToken = usdte;
            investmentTokenAddress = usdteAddress;
        } else if (tokenID == 2) {
            investmentToken = usdc;
            investmentTokenAddress = usdcAddress;
        } else if (tokenID == 3) {
            investmentToken = usdce;
            investmentTokenAddress = usdceAddress;
        } else if (tokenID == 4) {
            investmentToken = dai;
            investmentTokenAddress = daiAddress;
        }
        require(
            investmentToken.allowance(msg.sender, address(this)) >= value,
            "not enough allowance"
        );

        investmentToken.transferFrom(msg.sender, address(this), value);
        if (investmentTokenAddress != daiAddress) {
            address[] memory path = new address[](2);
            path[0] = investmentTokenAddress;
            path[1] = daiAddress;
            investmentToken.approve(joeAddress, value);
            uint256[] memory remAmounts = joeRouter.getAmountsOut(value, path);
            uint256 amountOutMin = (remAmounts[remAmounts.length - 1] *
                (100 - 5)) / 100;
            joeRouter.swapExactTokensForTokens(
                value,
                amountOutMin,
                path,
                address(this),
                (block.timestamp + 120)
            );
        }
        dai.approve(address(strongbox), dai.balanceOf(address(this)));
        strongbox.depositToken(daiAddress, dai.balanceOf(address(this)));

        currentInvestment.investmentValue[msg.sender] += value;
        currentInvestment.totalInvestment += value;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint8 slippage,
        address[] calldata path
    ) external returns (uint256[] memory amounts) {
        uint256[] memory remAmounts = joeRouter.getAmountsOut(amountIn, path);
        uint256 amountOutMin = (remAmounts[remAmounts.length - 1] *
            (100 - slippage)) / 100;
        return
            joeRouter.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                (block.timestamp + 120)
            );
    }

    function getTotalInvestment() external view returns (uint256) {
        return dai.balanceOf(address(this));
    }

    function getInvestmentOfProject(uint256 roundID)
        external
        view
        returns (uint256)
    {
        Investment storage currentInvestment = investmentRound[roundID];
        return currentInvestment.totalInvestment;
    }

    function executeInvestment(uint256 roundID) external onlyOwner {
        Investment storage currentInvestment = investmentRound[roundID];
        require(currentInvestment.deadline <= block.timestamp);
        require(
            currentInvestment.totalInvestment >=
                (currentInvestment.winner.requiredInvestment * 90 /100)
        );
        require(!currentInvestment.executed, "Investment is already executed");
        currentInvestment.executed = true;
        dai.transfer(currentInvestment.winner.creator, currentInvestment.totalInvestment);
        GordionShareToken newShareToken = new GordionShareToken(currentInvestment.winner.title, Strings.toString(roundID), GordionDAO);
        shareTokens[roundID] = newShareToken;
        shareTokens[roundID].mint(GordionDAO, currentInvestment.totalInvestment * 10 / 100);
        shareTokens[roundID].mint(currentInvestment.winner.creator, currentInvestment.totalInvestment  * 45 / 100);
    }

    function getShareToken(uint roundID) external {
        Investment storage currentInvestment = investmentRound[roundID];
        require(currentInvestment.executed, "Investment is not executed yet");
        require(currentInvestment.investmentValue[msg.sender] >= 0, "You have no investment");
        shareTokens[roundID].mint(msg.sender, currentInvestment.investmentValue[msg.sender] * 45 / 100);
    }
}
