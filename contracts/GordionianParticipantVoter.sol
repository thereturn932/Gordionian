//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GordionianParticipantVoter is Ownable {
    uint256 votingID;

    struct Film {
        string title;
        address creator;
        bytes32 creatorName;
        uint256 votingSeason;
        uint256 participantID;
        uint requiredInvestment;
        bytes32 movieURL;
        bytes32 contactEMail;
    }

    struct VotingRound {
        uint256 id;
        Film[] films;
        uint256[] votes;
        uint256 deadline;
        mapping(address => bool) isVoted;
        string[3] winners;
    }

    VotingRound[] private rounds;
    mapping(uint => Film) private winners;


    event NewParticipant(
        string _title,
        bytes32 _creatorName,
        bytes32 _movieURL,
        uint256 participantID
    );

    constructor() {
        rounds.push();
    }

    function startRound(uint256 _deadline) external onlyOwner {
        votingID++;
        VotingRound storage newRound = rounds.push();
        newRound.id = votingID;
        newRound.deadline = _deadline;
        newRound.films.push();
    }

    function endRound(uint256 id) external onlyOwner {
        VotingRound storage round = rounds[id];
        round.deadline = block.timestamp;
    }

    function voteFilm(
        uint256 id,
        uint256 _participantID,
        bytes32 filmTitle
    ) external {
        VotingRound storage round = rounds[id];
        require(
            (keccak256(abi.encodePacked((round.films[_participantID].title))) == keccak256(abi.encodePacked((filmTitle)))),
            "Index and title do not match"
        );
        require(!round.isVoted[msg.sender], "Already voted");
        round.isVoted[msg.sender] = true;
        round.votes[_participantID]++;
    }

    function revokeVote(
        uint256 id,
        uint256 _participantID,
        bytes32 filmTitle
    ) external {
        VotingRound storage round = rounds[id];
        require(
            (keccak256(abi.encodePacked((round.films[_participantID].title))) == keccak256(abi.encodePacked((filmTitle)))),
            "Index and title do not match"
        );
        require(round.isVoted[msg.sender], "Already not voted");
        round.isVoted[msg.sender] = false;
        round.votes[_participantID]--;
    }

    function checkRemainingTime(uint256 id) external view returns (uint256) {
        VotingRound storage round = rounds[id];
        return (round.deadline - block.timestamp);
    }

    function winningFilms(uint256 id) external onlyOwner {
        VotingRound storage round = rounds[id];
        require(
            block.timestamp >= round.deadline,
            "Round has not finished yet"
        );

        uint256 pos_1;
        uint256 pos_2;
        uint256 pos_3;

        string memory firstPlace;
        string memory secondPlace;
        string memory thirdPlace;

        Film memory winner;

        for (uint256 i; i < round.votes.length; i++) {
            if (round.votes[i] >= pos_1) {
                pos_3 = pos_2;
                thirdPlace = secondPlace;
                pos_2 = pos_1;
                secondPlace = firstPlace;
                pos_1 = round.votes[i];
                firstPlace = round.films[i].title;
                winner = round.films[i];
            } else if (round.votes[i] >= pos_2) {
                pos_3 = pos_2;
                thirdPlace = secondPlace;
                pos_2 = round.votes[i];
                secondPlace = round.films[i].title;
            } else if (round.votes[i] >= pos_3) {
                pos_3 = round.votes[i];
                thirdPlace = round.films[i].title;
            }
        }

        winners[id] = winner;
        round.winners = [firstPlace, secondPlace, thirdPlace];
    }

    function getRoundInfo(uint256 id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256[] memory,
            uint256,
            string[3] memory
        )
    {
        VotingRound storage round = rounds[id];
        return (
            round.id,
            round.films.length,
            round.votes,
            round.deadline,
            round.winners
        );
    }

    function NewParticipation(
        string calldata _title,
        bytes32 _creatorName,
        bytes32 _movieURL,
        uint _requiredInvestment,
        bytes32 _contactEMail,
        uint256 roundID
    ) external {
        VotingRound storage round = rounds[roundID];

        Film memory newParticipant;
        newParticipant.title = _title;
        newParticipant.movieURL = _movieURL;
        newParticipant.votingSeason = votingID;
        newParticipant.participantID = round.films.length;
        newParticipant.requiredInvestment = _requiredInvestment;
        newParticipant.creator = msg.sender;
        newParticipant.creatorName = _creatorName;
        newParticipant.contactEMail = _contactEMail;

        round.films.push(newParticipant);
        round.votes.push();
    }

    function cancelParticipation(uint roundID, uint _participantID, bytes32 _title) external {
        VotingRound storage round = rounds[roundID];
        require((keccak256(abi.encodePacked((round.films[_participantID].title))) == keccak256(abi.encodePacked((_title)))), "titles does not match");
        require(round.films[_participantID].creator == msg.sender, "creator does not match");
        
        delete round.films[_participantID];
        delete round.votes[_participantID];
    }

    function getWinner(uint roundID) external view returns (string memory, address, bytes32, uint,uint,uint,bytes32,bytes32) {
        Film storage winner = winners[roundID];
        return (winner.title,winner.creator,winner.creatorName,winner.votingSeason,winner.participantID,winner.requiredInvestment,winner.movieURL,winner.contactEMail);
    } 
}
