async function main() {
  const AlphaCarpFactory = await ethers.getContractFactory("AlphaCarp");
  console.log("Deploying AlphaCarp...");

  const AlphaCarp = await AlphaCarpFactory.deploy();

  console.log("Alpha Carp has been deployed to :: ", AlphaCarp.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode(1);
});
