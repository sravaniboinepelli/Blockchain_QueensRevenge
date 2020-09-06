// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.0;
contract Auction {
    
    //Address of the person selling
    address payable public seller;

    //The minimum reserve price given by the seller
    uint256 reservePrice;

    //Variable for triggering the end of the bidding, can be replaced with time based system
    uint256 endOfBidding;

    //Address of highest bidder so far
    address payable highBidder;

    //Value of highest bid so far
    uint256 highBid;

    //Value of second highest bid so far
    uint256 secondBid;

    //Mapping used to check if the bid of a certain address has been processed
    mapping(address => bool) bidCheck;

    //Mapping balances of all bidders
    mapping(address => uint256) balanceBidders;

    //Mapping balances of all bidders
    mapping(address => uint256) amountBid;
    
    //Mapping hashed bids of the bidders
    mapping(address => bytes32) hashedBids;
    event HashBid(
        address indexed _from,
        bytes32 _value
    );
    event BidRecvd(
        address indexed _from,
        uint256 _value,
        uint256 _secret,
        uint256 _mvalue

    );
     event EndAuction(
        address indexed _from,
        address indexed _winner,
        uint256 _amount
    );
    //Constructor
    constructor (uint256 minPrice, uint256 numberOfBids) public payable {
        
        //Set reserve price
        reservePrice = minPrice;

        //In this case, set endOfBidding limited by number of bids
        endOfBidding = numberOfBids;
        seller = msg.sender;
        
        //Set default highest, second highest bids to the reserve price, and highest bidder to the seller
        highBidder = seller;
        highBid = reservePrice;
        secondBid = reservePrice;
        bidCheck[seller] = true;
    }

    //Function that recieves hashed bid
    function hashBid(address payable from, bytes32 hashed) external payable {
        if (from == address(0)) {
            from = msg.sender;
        }
        require(endOfBidding >= 0, "Auction end of Bidding");

        // Each person can only bid once
        require(bidCheck[from] == false, "Can send bid only once");

        hashedBids[from] = hashed;
        emit HashBid(from, hashed);

        //Mark the account/address as checked, to prevent multiple bids
        bidCheck[from] = true;

        //Change bidding condition variable
        endOfBidding -= 1;
    }

    
    function getHashValue(uint256 value, uint256 secret) pure internal returns(bytes32) {

         return keccak256(abi.encodePacked(value,secret));

    }
    //Function that accounts use to make bids
    function Bid(address payable from, uint256 value, uint256 secret) external payable {
        if (from == address(0)){
            from = msg.sender;
        }
        //The bidding condition should not fail
        require(endOfBidding <= 0, "Auction Bidding phase not completed");

        //The amount that is bid is sent as msg.value
        uint256 amount = value;

        emit BidRecvd(from, msg.value, from.balance, amount);

        bytes32 hashV = getHashValue(value, secret);

        require(hashV == hashedBids[from], "Auction values does not match");

        //Store the amount bid for later withdrawals incase of failure to win auction
        amountBid[from] += amount;

        //Storing the balance of each bidder
        balanceBidders[from] += from.balance;

        emit BidRecvd(from, balanceBidders[from], amount, msg.value);

        //The balance available in the account of the bidder should be greater than or equal to the amount bid
        require(balanceBidders[from] >= amount, "Auction not enough balance");

        //If the bid is higher than the previously processed bids, update accordingly
        if (value > highBid) {
            //The bidder is now the highest bidder, the previous highest bid is the second highest bid
            highBidder = from;
            secondBid = highBid;
            highBid = value;
        }

        
    }

    //Fucntion used to check balance of the smart contract
    function balanceof() external view returns(uint){
        
        return address(this).balance;
    }
    
    //End auction function that accounts can use to withdraw funds used in the bidding if they failed to win the auction
    function endAuction(address payable from) external payable{

        if (from == address(0)) {
            from = msg.sender;
        }
        
        require(highBidder != address(0), "Auction reveal phase is not completed");
        
        uint256 returnamount = amountBid[from];

        //The amount owed is reset to 0
        amountBid[from] = 0;

        //Require withdrawal not be allowed if no money is owed
        require(returnamount != 0, "Auction: No Amount is due");

        //Allow highest bidder to withdraw excess money
        if(from == highBidder){
            returnamount = highBid - secondBid;
            emit EndAuction(from, highBidder, returnamount);
            if (returnamount != 0) {
                from.transfer(returnamount);
            }
        }
        //Allow losing bidders to withdraw their entire funds
        else {
            emit EndAuction(from, highBidder, returnamount);
            if (returnamount != 0) {
                 from.transfer(returnamount);
            }
           
        }

    }
   
}