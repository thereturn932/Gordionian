const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("GordionianGenreVoter");
    const greeter = await Greeter.deploy();
    await greeter.deployed();

    console.log("Contract Deployed to", greeter.address);
    
  });
});
