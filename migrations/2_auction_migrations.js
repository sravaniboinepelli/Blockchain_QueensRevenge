const Auction = artifacts.require("Auction");
const argv = require('minimist')(process.argv.slice(3));

//If you arent running blockchain on ganache, comment this out
var minPrice = argv['minPrice'];
var noOfBids = argv['noOfBids'];

//Use either the declaration below, or change the values inside the contract itself if not using ganache
//var minPrice = argv['minPrice'];
//var noOfBids = argv['noOfBids'];
console.log(argv);
console.log(minPrice);
module.exports = (deployer,network,accounts) => {
  deployer.deploy(Auction, minPrice, noOfBids);
};


