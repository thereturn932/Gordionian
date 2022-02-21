//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IGordionianParticipantVoter {
    function startRound(uint256 _deadline) external;

    function endRound(uint256 id) external;

    function voteFilm(uint256 id, uint256 _participantID, bytes32 filmTitle) external;

    function revokeVote(uint256 id, uint256 _participantID, bytes32 filmTitle) external;

    function checkRemainingTime(uint256 id) external view returns (uint256);

    function winningFilms(uint256 id) external;

    function getRoundInfo(uint256 id) external view returns (uint256, uint256, uint256[] memory, uint256, bytes32[3] memory);

    function NewParticipation(bytes32 _title, bytes32 _creatorName, bytes32 _movieURL, bytes32 _contactEMail, uint256 roundID) external;

    function cancelParticipation(uint256 roundID, uint256 _participantID, bytes32 _title) external;

    function getWinner(uint256 roundID)external view returns (string memory, address, bytes32, uint256, uint256, uint256, bytes32, bytes32);
}
