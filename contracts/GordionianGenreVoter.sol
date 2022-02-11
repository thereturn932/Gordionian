//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GordionianGenreVoter is Ownable {
    uint256 votingID;

    bytes32[] private genres = [
        bytes32("Action"),
        bytes32("Adventure"),
        bytes32("Animation"),
        bytes32("Biographical"),
        bytes32("Comedy"),
        bytes32("Crime"),
        bytes32("Disaster"),
        bytes32("Documentary"),
        bytes32("Drama"),
        bytes32("Fantasy"),
        bytes32("Horror"),
        bytes32("Musical"),
        bytes32("Mystery"),
        bytes32("Noir"),
        bytes32("Romance"),
        bytes32("Satire"),
        bytes32("Science-Fiction"),
        bytes32("Spy"),
        bytes32("Teen"),
        bytes32("Thriller"),
        bytes32("War"),
        bytes32("Western")
    ];

    mapping(bytes32 => bool) private doesExist;

    struct VotingRound {
        uint256 id;
        bytes32[] genres;
        uint256[] votes;
        uint256 deadline;
        mapping(address => bool) isVoted;
        bytes32[3] winners;
    }

    VotingRound[] private rounds;

    constructor() {
        //Push first empty round to match id with array index
        rounds.push();
    }

    function addNewGenre(bytes32 genreName) external onlyOwner {
        require(!doesExist[genreName], "Genre name already exists");
        genres.push(genreName);
        doesExist[genreName] = true;
    }

    function removeGenre(uint256 index, bytes32 genreName) external onlyOwner {
        require(doesExist[genreName], "Genre name does not exist");
        require(genres[index] == genreName, "Index and genre do not match");
        if (index >= genres.length) return;

        for (uint256 i = index; i < genres.length - 1; i++) {
            genres[i] = genres[i + 1];
        }
        delete genres[genres.length - 1];
        doesExist[genreName] = false;
    }

    function startRound(uint256 _deadline) external onlyOwner {
        votingID++;
        VotingRound storage newRound = rounds.push();
        newRound.id = votingID;
        newRound.deadline = _deadline;
        newRound.genres = genres;
        newRound.votes = new uint256[](genres.length);
    }

    function endRound(uint256 id) external onlyOwner {
        VotingRound storage round = rounds[id];
        round.deadline = block.timestamp;
    }

    function voteGenre(
        uint256 id,
        uint256 genreIndex,
        bytes32 genreName
    ) external {
        VotingRound storage round = rounds[id];
        require(
            round.genres[genreIndex] == genreName,
            "Index and genre do not match"
        );
        require(!round.isVoted[msg.sender], "Already voted");
        round.isVoted[msg.sender] = true;
        round.votes[genreIndex]++;
    }

    function revokeVote(
        uint256 id,
        uint256 genreIndex,
        bytes32 genreName
    ) external {
        VotingRound storage round = rounds[id];
        require(
            round.genres[genreIndex] == genreName,
            "Index and genre do not match"
        );
        require(round.isVoted[msg.sender], "Already not voted");
        round.isVoted[msg.sender] = false;
        round.votes[genreIndex]--;
    }

    function checkRemainingTime(uint256 id) external view returns (uint256) {
        VotingRound storage round = rounds[id];
        return (round.deadline - block.timestamp);
    }

    function winningGenres(uint256 id) external onlyOwner{
        VotingRound storage round = rounds[id];
        require(
            block.timestamp >= round.deadline,
            "Round has not finished yet"
        );

        uint256 pos_1;
        uint256 pos_2;
        uint256 pos_3;

        bytes32 firstPlace;
        bytes32 secondPlace;
        bytes32 thirdPlace;

        for (uint256 i; i < round.votes.length; i++) {
            if (round.votes[i] >= pos_1) {
                pos_3 = pos_2;
                thirdPlace = secondPlace;
                pos_2 = pos_1;
                secondPlace = firstPlace;
                pos_1 = round.votes[i];
                firstPlace = round.genres[i];
            } else if (round.votes[i] >= pos_2) {
                pos_3 = pos_2;
                thirdPlace = secondPlace;
                pos_2 = round.votes[i];
                secondPlace = round.genres[i];
            } else if (round.votes[i] >= pos_3) {
                pos_3 = round.votes[i];
                thirdPlace = round.genres[i];
            }
        }

        round.winners = [firstPlace, secondPlace, thirdPlace];
    }

    function getRoundInfo(uint256 id)
        external
        view
        returns (
            uint256,
            bytes32[] memory,
            uint256[] memory,
            uint256,
            bytes32[3] memory
        )
    {
        VotingRound storage round = rounds[id];
        return (
            round.id,
            round.genres,
            round.votes,
            round.deadline,
            round.winners
        );
    }

    function getGenres() external view returns (bytes32[] memory) {
        return genres;
    }
}
