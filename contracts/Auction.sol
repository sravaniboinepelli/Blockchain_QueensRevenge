// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.0;
/// @title Contract for sealed bid second bid auction
/// @dev All function calls are currently implemented without side effects

contract Auction {
    

    /// @notice Address of the person selling
    address payable public seller;

    /// @dev The minimum reserve price given by the seller
    uint256 reservePrice;

    /// @dev Variable for triggering the end of the bidding, can be replaced with time based system
    uint256 endOfBidding;

    /// @dev Address of highest bidder so far
    address payable highBidder;

    /// @dev Value of highest bid so far
    uint256 highBid;

    /// @dev Value of second highest bid so far
    uint256 secondBid;

    /// @dev Mapping used to check if the bid of a certain address has been processed
    mapping(address => bool) bidCheck;

    /// @dev Mapping balances of all bidders
    mapping(address => uint256) balanceBidders;

    /// @dev Mapping amount bid of all bidders
    mapping(address => uint256) amountBid;
    
    /// @dev Mapping hashed bids of the bidders
    mapping(address => bytes32) hashedBids;

    /// @notice Event for receiving hashed bids
    event HashBid(
        address indexed _from,
        bytes32 _value
    );

    /// @notice Event for receiving revealed bids
    event BidRecvd(
        address indexed _from,
        uint256 _value,
        uint256 _secret,
        uint256 _mvalue

    );

    /// @notice Event for withdrawal of funds at auction end
     event EndAuction(
        address indexed _from,
        address indexed _winner,
        uint256 _amount
    );

    /// @notice Constructor to initialise minPrice of auction, and number of bids in the auction
    constructor (uint256 minPrice, uint256 numberOfBids) public  {
        
        /// @devSet reserve price
        reservePrice = minPrice;

        /// @devIn this case, set endOfBidding limited by number of bids
        endOfBidding = numberOfBids;
        seller = msg.sender;
        
        /// @devSet default highest, second highest bids to the reserve price, and highest bidder to the seller
        highBidder = seller;
        highBid = reservePrice;
        secondBid = reservePrice;
        bidCheck[seller] = true;
    }

    /// @notice Function that recieves hashed bid
    /// @param hashed the hash sent to the contract
    function hashBid(bytes32 hashed) external  {
        require(endOfBidding >= 0, "Auction end of Bidding");

        /// @dev Each person can only bid once
        require(bidCheck[msg.sender] == false, "Can send bid only once");

        hashedBids[msg.sender] = hashed;
        emit HashBid(msg.sender, hashed);

        /// @notice Mark the account/address as checked, to prevent multiple bids
        bidCheck[msg.sender] = true;

        /// @notice Change bidding condition variable
        endOfBidding -= 1;
    }

    /// @dev Function that hashes value and secret
    /// @param value the value of the bid to be hashed
    /// @param secret the key with which the value is hashed 
    function getHashValue(uint256 value, uint256 secret) pure internal returns(bytes32) {

         return keccak256(abi.encodePacked(value,secret));

    }
    
    /// @notice Function that receives the bid after the end of the auction 
    /// @param value the value of the bid as claimed by the sender
    /// @param secret the secret with which the value was hashed to give the hashed value 
    function Bid(uint256 value, uint256 secret) external payable {
        /// @devThe bidding condition should not fail
        require(endOfBidding <= 0, "Auction Bidding phase not completed");

        /// @devThe amount that is bid is sent as msg.value
        uint256 amount = value;
        require(msg.value >= value, "Auction not enough ether");

        emit BidRecvd(msg.sender, msg.value, msg.sender.balance, amount);

        bytes32 hashV = getHashValue(value, secret);

        require(hashV == hashedBids[msg.sender], "Auction values does not match");

        /// @devStore the amount bid for later withdrawals incase of failure to win auction
        amountBid[msg.sender] += amount;

        /// @devStoring the balance of each bidder
        balanceBidders[msg.sender] += msg.sender.balance;

        emit BidRecvd(msg.sender, balanceBidders[msg.sender], value, msg.value);

        /// @devIf the bid is higher than the previously processed bids, update accordingly
        if (value >= highBid) {
            /// @devThe bidder is now the highest bidder, the previous highest bid is the second highest bid
            highBidder = msg.sender;
            secondBid = highBid;
            highBid = value;
        }
        
    }

    /// @notice Function that returns the balance of the sender
    function balanceof() external view returns(uint){
        
        return address(this).balance;
    }
    
   
    /// @notice End auction function that accounts can use to withdraw funds used in the bidding if they failed to win the auction
    function endAuction() external returns(uint256) {

        require(highBidder != address(0), "Auction reveal phase is not completed");
        
        uint256 returnamount = amountBid[msg.sender];

        /// @devThe amount owed is reset to 0
        amountBid[msg.sender] = 0;

        /// @devRequire withdrawal not be allowed if no money is owed
        require(returnamount != 0, "Auction: No Amount is due");

        /// @devAllow highest bidder to withdraw excess money
        if(msg.sender == highBidder){
            returnamount = highBid - secondBid;
            emit EndAuction(msg.sender, highBidder, returnamount);
            if (returnamount != 0) {
                msg.sender.transfer(returnamount);
                return returnamount;
            }
        }
        /// @devAllow losing bidders to withdraw their entire funds
        else {
            emit EndAuction(msg.sender, highBidder, returnamount);
            if (returnamount != 0) {
                 msg.sender.transfer(returnamount);
                 return returnamount;
            }
           
        }

    }
   
}
