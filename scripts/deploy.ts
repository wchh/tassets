import { ethers } from "hardhat";

async function main() {
  const coreAddress = "0x123..."; // Replace with the actual address of core
  const priceProviderAddress = "0x456..."; // Replace with the actual address of price provider
  const vat = await ethers.deployContract("Vat", [coreAddress, priceProviderAddress]);
  await vat.waitForDeployment();
  console.log("Vat contract deployed to:", vat.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
