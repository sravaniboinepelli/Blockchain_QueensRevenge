const Auction = artifacts.require("Auction");
const argv = require('minimist')(process.argv.slice(2));
module.exports = (deployer,network,accounts) => {
  console.log("----migration custom argument: ",argv);
  deployer.deploy(Auction, argv['minPrice'], argv['noOfBids']);
};
