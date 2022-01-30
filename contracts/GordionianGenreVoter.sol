//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GordionianGenreVoter is Ownable{
  uint votingID;
    bytes32[] public genres = [bytes32("Action"),
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

    mapping(bytes32 => uint) public votes;
    mapping (bytes32 => bool) public doesExist;
    uint deadline;
    bytes32[] private voters;
    mapping (bytes32 => bool) public voted;

    
    constructor() {
    }
    
    function AddNewGenre(bytes32 _genreName) external onlyOwner{
        genres.push(_genreName);
        votes[_genreName] = 0;
        doesExist[_genreName] = true;
    }
    
    function VoteAGenre(bytes32 _genreName) external payable {
        assert(doesExist[_genreName] && (block.timestamp < deadline) && !voted[keccak256(abi.encodePacked(msg.sender,votingID))]);
        voters.push(keccak256(abi.encodePacked(msg.sender,votingID)));
        voted[keccak256(abi.encodePacked(msg.sender,votingID))] = true;
        votes[_genreName]++;
    }
    
    function StartVoting(uint _time) external onlyOwner{
        //time in seconds
        votingID++;
        deadline = block.timestamp + _time;
    }

    function EndVoting() external onlyOwner{
        deadline = block.timestamp;
    }
    
    function CheckRemainingTime() external view returns (uint){
        return deadline - block.timestamp;
    }
    
    function IsVoting() external view returns (bool){
        return block.timestamp < deadline;
    }
    
    function WinningGenres() external view returns (bytes32[] memory){
        uint[] memory voteCount = new uint[](genres.length);
        for(uint i = 0; i<genres.length; i++) {
            voteCount[i] = votes[genres[i]];
        }
        bytes32[] memory sortedGenres = new bytes32[](genres.length);
        (voteCount, sortedGenres) = sort(voteCount, genres);
        bytes32[] memory winningGenres = new bytes32[](3);
        winningGenres[2] = sortedGenres[sortedGenres.length-1];
        winningGenres[1] = sortedGenres[sortedGenres.length-2];
        winningGenres[0] = sortedGenres[sortedGenres.length-3];
        return winningGenres;
    }
    
    function sort(uint[] memory intArr, bytes32[] memory strArr) public pure returns (uint[] memory, bytes32[] memory){
        if (intArr.length > 0)
            quickSort(intArr, 0, intArr.length - 1, strArr);
        return (intArr, strArr);
    }

    function quickSort(uint[] memory arr, uint left, uint right, bytes32[] memory strArr) public pure {
        if (left >= right)
            return;
        uint p = arr[(left + right) / 2];   // p = the pivot element
        uint i = left;
        uint j = right;
        while (i < j) {
            while (arr[i] < p) ++i;
            while (arr[j] > p) --j;         // arr[j] > p means p still to the left, so j > 0
            if (arr[i] > arr[j]) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
                (strArr[i], strArr[j]) = (strArr[j], strArr[i]);
            }
            else
                ++i;
        }
    
        // Note --j was only done when a[j] > p.  So we know: a[j] == p, a[<j] <= p, a[>j] > p
        if (j > left)
            quickSort(arr, left, j - 1, strArr);    // j > left, so j > 0
        quickSort(arr, j + 1, right,strArr);
    }
}