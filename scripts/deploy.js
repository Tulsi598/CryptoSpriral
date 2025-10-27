const hre = require("hardhat");

async function main() {
  const BlockWeaveNet = await hre.ethers.getContractFactory("BlockWeaveNet");
  const blockWeaveNet = await BlockWeaveNet.deploy();
  await blockWeaveNet.waitForDeployment();

  console.log("✅ BlockWeaveNet deployed to:", await blockWeaveNet.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
