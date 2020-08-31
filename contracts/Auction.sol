pragma solidity >=0.4.22 <0.8.0;
contract Auction {
    //Address of the person selling
    address public seller;

    //The minimum reserve price given by the seller
    uint256 public reservePrice;

    //Variable for triggering the end of the bidding, can be replaced with time based system
    uint256 public endOfBidding;

    //Address of highest bidder so far
    address public highBidder;

    //Value of highest bid so far
    uint256 public highBid;

    //Value of second highest bid so far
    uint256 public secondBid;

    //Mapping that is used to check if the bid of a certain address has been processed
    mapping(address => bool) public bidCheck;

    //Mapping of the balances of all the bidders
    mapping(address => uint256) public balanceBidders;

    //Constructor
    constructor (uint256 minPrice, uint256 numberOfBids) public {
        //Set reserve price
        reservePrice = minPrice;

        //In this case, set endOfBidding limited by number of bids
        endOfBidding = numberOfBids;

        seller = msg.sender;
        
        //Set default highest,second highest bids to the reserve price, and highest bidder to the seller
        highBidder = seller;
        highBid = reservePrice;
        secondBid = reservePrice;
        bidCheck[seller] = true;
    }

    function Bid() public payable {
        uint256 amount = msg.value;
        require(endOfBidding != 0);
        //require(bidCheck[msg.sender] != true);
        balanceBidders[msg.sender] += msg.sender.balance;
        require(balanceBidders[msg.sender] >= reservePrice);
        require(balanceBidders[msg.sender] >= amount);
        if (amount > highBid) {
            
            highBidder = msg.sender;
            secondBid = highBid;
            highBid = amount;
        }
        bidCheck[msg.sender] = true;
        //endOfBidding -= 1;
    }
    function receive() external payable {
        
    }
    function balanceof() external view returns(uint){
        return address(this).balance;
    }
    function endAuction() public payable{
        endOfBidding = 0;
    }
}