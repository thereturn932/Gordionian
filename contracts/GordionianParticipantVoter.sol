//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GordionianParticipantVoter is Ownable{
    struct Movie {
        string title;
        address creator;
        uint votingSeason;
        uint participantID;
        string movieURL;
    }
    uint currentSeason;
    uint participationNumber;
    mapping(uint => uint) public votes; /// @dev participant ID to vote number
    mapping(address => string) creatorName;
    mapping(address => bool) isVoted;
    mapping(uint => Movie) movieMap;
    uint[] currentParticipants;
    uint votingDeadline;
    IERC20 GRD;

    event NewParticipant(string _title, string _creatorName, string _movieURL, uint participantID);

    constructor(address _GRDAddress) {
        GRD = IERC20(_GRDAddress);
    }

    function DefineGRD(address _GRDAddress) external onlyOwner{
        GRD = IERC20(_GRDAddress);
    }

    function NewParticipation(string memory _title, string memory _creatorName, string memory _movieURL) external {
        Movie memory newParticipant;
        newParticipant.title = _title;
        newParticipant.movieURL = _movieURL;
        newParticipant.votingSeason = currentSeason;
        participationNumber++;
        newParticipant.participantID = participationNumber;
        newParticipant.creator = msg.sender;
        creatorName[msg.sender] = _creatorName;
        movieMap[participationNumber] = newParticipant;
        currentParticipants.push(participationNumber);

        emit NewParticipant(_title, _creatorName, _movieURL, participationNumber);
    }

    function VoteForParticipant(uint _ID, uint amount) external {
        require(isVoted[msg.sender] == false && 
        GRD.allowance(msg.sender, address(this))>= amount &&
         block.timestamp <= votingDeadline && 
         movieMap[_ID].votingSeason == currentSeason);

        votes[_ID]++;
    }

    function StartNewSeason( uint duration) external onlyOwner{
        require(votingDeadline <= block.timestamp);
        delete currentParticipants;
        currentSeason++;
        votingDeadline += duration;
    }

    function FindWinner() external view returns (string memory, uint){
        require(votingDeadline <= block.timestamp);
        uint256 winner = 0; 
        uint256 i;

        for(i = 0; i < currentParticipants.length; i++){
            if(votes[currentParticipants[i]] > winner) {
                winner = currentParticipants[i]; 
            } 
        }

        return (movieMap[winner].title, movieMap[winner].participantID);
    }

}