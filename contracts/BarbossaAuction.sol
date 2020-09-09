// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

/// @title Contract for sealed bid pirate auction as part of the assignment
/// @dev All function calls are currently implemented without side effects

import "./Auction.sol";

contract BarbossaAuction {

    address deployer = msg.sender;
    address payable public addressVyperAucContract;
    

    struct BidderInfo {
         bool sentBid;
         bool revealedBid;
         uint256 balance;
         uint256 bidValue;
         bytes32 sealedBidValue;
    }
    struct WinnerInfo {
        //Address of highest bidder so far
        address payable bidder;
        //Value of highest bid so far
        uint256 bidValue;
        uint256 nonce;
    }
    mapping(address => bool) ringMembers;
    mapping(address => BidderInfo) bidders;
    mapping(uint8 => WinnerInfo) winner;

    /// @dev number of members in bidding ring 9
    uint256 numRingMembers = 0;

    /// @dev  number of members that sent sealed bid
    uint8 numCurrentSentSealed = 0;

    /// @dev  number of members that revealed bid
    uint8 numCurrentRevealed = 0;

    uint256 public nameofDeployer;
   
    event SealedBid(
        address indexed _from,
        bytes32 _hashedvalue
    );
    event RevealBid(
        address indexed _from,
        uint256 _value,
        uint256 _secret
    );
    
    event callVyperReveal(
        address indexed _from,
        uint256  _value,
        uint256  _nonce

    );
    event ValidDeployer(
        address indexed _from,
        uint256 _name
    );
    event WithDrewMoney(
        address indexed _from,
        uint256 value

    );

    
    /// @notice Constructor initialize default values
    constructor (uint256 name, address[] memory _members) public  {
        uint256 validName = 0x426172626f737361;

        // if (validName == name){
        //     emit ValidDeployer(msg.sender, name);
        // }
        require(validName == name, "Not a valid deployer");
                        
        nameofDeployer = name;
        for (uint8 i = 0; i < _members.length; i++) {
           ringMembers[_members[i]] = true;
        }
        
        ringMembers[deployer] = true;
        numRingMembers += _members.length +1;

    }

    function setAddressAuction(address payable _addressVyperAuc) external {
              addressVyperAucContract = _addressVyperAuc;
    }


    /// @notice Function that receives the sealed bids
    /// @param hashed the hashed bid that the function receives
    function sealedBid(bytes32 hashed) public  {
        require(ringMembers[msg.sender] == true, "Only Members can bid");
        BidderInfo storage bidder = bidders[msg.sender];

        emit SealedBid(msg.sender, hashed);

        //Each person can only bid once
        require(bidder.sentBid != true, "Can send bid only once");
        bidder.sealedBidValue = hashed;

        //Mark the account/address as checked, to prevent multiple bids
        bidder.sentBid = true;
        numCurrentSentSealed += 1;
       
    }
    /// @dev Function that hashes value and secret
    /// @param value the value of the bid to be hashed
    /// @param secret the key with which the value is hashed 
    function getHash(uint256 value, uint256 secret) pure internal returns(bytes32) {

       return keccak256(abi.encodePacked(value,secret));

    }
    
    /// @notice Function to reveal bid value and secret used to create the hashed bid value sent during function sealedBid()
    /// @param value the value of the bid that was hashed
    /// @param secret the key with which the value was hashed 
        function revealBid(uint256 value, uint256 secret) public payable {

        //The bidding condition shouldnt fail
        require(numCurrentSentSealed >= numRingMembers, " Barbossa Bidding phase is not complete");
        BidderInfo storage bidder = bidders[msg.sender];

        require(bidder.revealedBid != true, "Can reveal bid only once");

        require(numCurrentRevealed <= numRingMembers, "Reveal phase is completed");
        require(msg.value >= value, "Auction not enough ether");

        emit RevealBid(msg.sender, value, secret);
        bytes32 hashValue = getHash(value, secret);
        bytes32 storedValue = bidder.sealedBidValue;

        require(hashValue == storedValue, "Barbossa value does not match sealed bid value");

        //The balance available in the account of the bidder should be greater than or equal to the amount bid

        require(msg.sender.balance >= value, "Barbossa Not enough balance");

        //Store the amount bid for later withdrawals incase of failure to win BarbossaAuction
        bidder.bidValue += value;

        //Storing the balance of each bidder
        bidder.balance += msg.sender.balance;

        emit RevealBid(msg.sender, bidder.balance, numCurrentRevealed);


        //If the bid is higher than the previously processed bids, update accordingly
        if (value > winner[0].bidValue) {
            //The bidder is now the highest bidder
            winner[0].bidder = msg.sender;
            winner[0].bidValue = value;

            if (numCurrentRevealed >= numRingMembers){
                winner[0].nonce = secret;

            }
        } 
        bidder.revealedBid = true;
        numCurrentRevealed +=1; 
    }

    /// @notice Deployer has to call this function with Address of vyper Auction contract to send winning bid
    /// @param _vyperAuctionContract the address of the sealed second bid auction contract
    function sendWinningBidToVyperAuction(address payable _vyperAuctionContract) public {

        require(msg.sender == deployer, "Deployer can only send the winning bid to Vyper Auction");
        require(numCurrentRevealed >= numRingMembers, " Barbossa Reveal phase is not complete");
        this.setAddressAuction(_vyperAuctionContract);
        Auction vyperAuct = Auction(_vyperAuctionContract);
        vyperAuct.hashBid(winner[0].bidder, getHash(winner[0].bidValue, winner[0].nonce));
        
    }

    /// @notice Deployer has to call this function after sendWinningBidToVyperAuction to reveal bid values  
    function revealWinningBidToVyperAuction() public {

        require(addressVyperAucContract != address(0), "sendWinningBidToVyperAuction is not called");
        require(msg.sender == deployer, "Deployer can only reveal the winning bid to Vyper Auction");
        Auction vyperAuct = Auction(addressVyperAucContract);
        emit callVyperReveal(winner[0].bidder, winner[0].bidValue,winner[0].nonce);
        // vyperAuct.Bid.value(winner[0].bidValue)(winner[0].bidder, winner[0].bidValue,winner[0].nonce);
        vyperAuct.Bid{value:winner[0].bidValue}(winner[0].bidder, winner[0].bidValue,winner[0].nonce);

        
    }
    
    /// @notice Deployer has to call this function after revealWinningBidToVyperAuction() to get money back in case of losing or the difference from ring winner bid value plus vyper second highest bid.
    function getmoneyFromVyperAuction() public returns (bool){

        require(addressVyperAucContract != address(0), "sendWinningBidToVyperAuction is not called");
        require(msg.sender == deployer, "Deployer can only interact with Vyper Auction");
        Auction vyperAuct = Auction(addressVyperAucContract);
        vyperAuct.endAuction(winner[0].bidder);

    }

    /// @notice Bid losers call this function to get their money back
    function withDrawMoney() public{
        require(numCurrentRevealed >= numRingMembers, " Barbossa Reveal phase is not complete");
        require(winner[0].bidder != msg.sender, "Can't withdraw yet, Deployer will get your money back");
        BidderInfo storage bidder = bidders[msg.sender];
        uint256 returnamount = bidder.bidValue;
        //The amount owned is reset to 0
        bidder.bidValue = 0;
        //Require withdrawal not be allowed if no money is owed
        require(returnamount != 0, "No Amount is due");
        msg.sender.transfer(returnamount);
        emit WithDrewMoney(msg.sender, returnamount);

    }

    /// @notice  Fallback function to receive any transfers
    receive() external payable { 

    }
    
}