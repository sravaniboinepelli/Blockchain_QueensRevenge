const BarbossaAuction = artifacts.require("BarbossaAuction");
const argv = require('minimist')(process.argv.slice(3));

//If you arent running blockchain on ganache, comment this out
var nameS = argv['deployerName'];
var member = argv['members'];
console.log(argv);
console.log(nameS);
// console.log(member)
var _members = member.split(",");
// console.log(_members);
var name = web3.utils.asciiToHex(new String(nameS));
// var name = web3.utils.hexToBytes(nameH);
console.log(name);
// _members = ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db"];


module.exports = (deployer,network,accounts) => {
  deployer.deploy(BarbossaAuction, name, _members);
};
