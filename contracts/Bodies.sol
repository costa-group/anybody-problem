// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Ticks.sol";
import "./Problems.sol";

contract Bodies is ERC721, Ownable {
    address public problems;
    address public ticks;
    mapping(uint256 => bytes32) public seeds;
    uint256 public counter;
    uint256 public constant decimals = 10 ** 18;
    uint256[10] public tickPrice = [
        0, // 1st body
        0, // 2nd body
        0, // 3rd body
        1_000, // 4th body
        10_000, // 5th body
        100_000, // 6th body
        1_000_000, // 7th body
        10_000_000, // 8th body
        100_000_000, //9th body
        1_000_000_000 // 10th body
    ];
    mapping(uint256 => uint256) public problemPriceLevels;

    modifier onlyProblems() {
        require(msg.sender == problems, "Only Problems can call");
        _;
    }

    constructor(address problems_) ERC721("Bodies", "BOD") {
        updateProblems(problems_);
    }

    function updateProblems(address problems_) public onlyOwner {
        problems = problems_;
    }

    function updateTicks(address ticks_) public onlyOwner {
        ticks = ticks_;
    }

    function generateSeed(uint256 tokenId) public view returns (bytes32) {
        return
            keccak256(abi.encodePacked(tokenId, blockhash(block.number - 1)));
    }

    function processPayment(address from, uint256 problemId) internal {
        uint256 problemPriceLevel = problemPriceLevels[problemId];
        uint256 problemPrice = tickPrice[problemPriceLevel] * decimals;
        problemPriceLevels[problemId]++;
        Ticks(ticks).burn(from, problemPrice);
    }

    function mint(uint256 problemId) public {
        require(
            Problems(problems).ownerOf(problemId) == msg.sender,
            "Not owner"
        );
        processPayment(msg.sender, problemId);
        counter++;
        seeds[counter] = generateSeed(counter);
        _mint(msg.sender, counter);
    }

    function mintAndBurn(
        address owner,
        uint256 problemId
    ) public onlyProblems returns (uint256) {
        processPayment(owner, problemId);
        counter++;
        seeds[counter] = generateSeed(counter);
        emit Transfer(address(0), owner, counter);
        emit Transfer(owner, address(0), counter);
        return counter;
    }

    function burn(uint256 bodyID) public onlyProblems {
        _burn(bodyID);
    }

    function problemMint(address owner, uint256 bodyId) public onlyProblems {
        _mint(msg.sender, bodyId);
    }
}
