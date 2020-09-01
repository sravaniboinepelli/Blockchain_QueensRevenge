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

    //Mapping of the balances of all the bidders
    mapping(address => uint256) public amountBid;
    
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

    //Function that recieves hashed bid
    function hashBid(byte32 hash) public {
        hashBid[msg.sender] = hash;

    }
    //Function that accounts use to make bids
    function Bid(uint256 nonce) public payable {

        //The amount that is bid is sent as msg.value
        uint256 amount = msg.value;
        
        require(keccak256(amount,nonce) == hashBid[msg.sender]);

        //The bidding condition should not fail
        require(endOfBidding != 0);

        //Each person can only bid once
        require(bidCheck[msg.sender] != true);

        //Store the amount bid for later withdrawals incase of failure to win auction
        amountBid[msg.sender] = amount;

        //Storing the balance of each bidder
        balanceBidders[msg.sender] += msg.sender.balance;

        //The balance available in the account of the bidder should be greater than or equal to the amount bid
        require(balanceBidders[msg.sender] >= amount);

        //If the bid is higher than the previously processed bids, update accordingly
        if (amount > highBid) {
            //The bidder is now the highest bidder, the previous highest bid is the second highest bid
            highBidder = msg.sender;
            secondBid = highBid;
            highBid = amount;
        }
        //Mark the account/address as checked, to prevent multiple bids
        bidCheck[msg.sender] = true;

        //Change bidding condition variable
        endOfBidding -= 1;
    }

    //Fucntion used to check balance of the smart contract
    function balanceof() external view returns(uint){
        
        return address(this).balance;
    }

    //End auction function that accounts can use to withdraw funds used in the bidding if they failed to win the auction
    function endAuction() public payable{

        //Require that withdrawal not be allowed if no money is owed
        require(amountBid[msg.sender] != 0);
        
        //Allow highest bidder to withdraw excess money
        if(msg.sender == highBidder){
            uint256 returnamount = highBid - secondBid;
            msg.sender.transfer(returnamount);
        }
        //Allow losing bidders to withdraw their entire funds
        else {
            msg.sender.transfer(amountBid[msg.sender]);
        }
        //The amount owed is reset to 0
        amountBid[msg.sender] = 0;
    }
}