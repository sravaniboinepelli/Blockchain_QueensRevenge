const Auction = artifacts.require("Auction");
const argv = require('minimist')(process.argv.slice(2));

//If not running blockchain on either ganache or some other program, comment this out
var minPrice = argv['minPrice'];
var noOfBids = argv['noOfBids'];

//Use either the declaration below, or change the values inside the contract itself if not using ganache or some other program
//var minPrice = argv['minPrice'];
//var noOfBids = argv['noOfBids'];

module.exports = (deployer,network,accounts) => {
  deployer.deploy(Auction, minPrice, noOfBids);
};
