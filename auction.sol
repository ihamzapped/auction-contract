// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/*
    Second-price Sealed-bid Auction Contract except the final price is calculated as:
        min(second highest bid + bidIncrement, highest bid);

*/

contract Auction {
    bool ownerHasClaimed;
    address payable public owner;

    string public ipfsHash;

    uint256 public start = block.timestamp;
    uint256 public end = start + 604800;

    uint256 public highestBindingBid; // Selling price
    address payable public highestBidder;
    uint256 public bidIncrement = 100;

    enum State {
        Started,
        Running,
        Ended,
        Canceled
    }
    State public auctionState;

    mapping(address => uint256) public bids;

    constructor() {
        owner = payable(msg.sender);
        auctionState = State.Running;
    }

    function bid() public payable notOwner isRunning {
        require(msg.value >= 100 wei, "min 100 wei");

        uint256 currentBid = bids[msg.sender] + msg.value;

        require(currentBid > highestBindingBid, "Cannot Outbid");

        bids[msg.sender] = currentBid;

        if (currentBid > bids[highestBidder]) {
            highestBindingBid = min(
                bids[highestBidder] + bidIncrement,
                currentBid
            );
            highestBidder = payable(msg.sender);
        } else
            highestBindingBid = min(
                bids[highestBidder],
                currentBid + bidIncrement
            );
    }

    function withdraw() public {
        require(auctionState == State.Canceled || block.timestamp > end);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint256 value;

        if (auctionState == State.Canceled || msg.sender != highestBidder) {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }

        if (auctionState != State.Canceled && msg.sender == owner) {
            require(!ownerHasClaimed, "Already Withdrawn");
            recipient = owner;
            value = highestBindingBid;
            ownerHasClaimed = true;
        }

        if (msg.sender == highestBidder) {
            recipient = highestBidder;
            value = bids[highestBidder] - highestBindingBid;
        }

        recipient.transfer(value);
        bids[recipient] = 0;
    }

    function cancelAuction() public isOwner {
        auctionState = State.Canceled;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) return a;
        return b;
    }

    modifier isRunning() {
        require(auctionState == State.Running, "Auction Ended");
        require(
            start <= block.timestamp && end >= block.timestamp,
            "Auction Ended"
        );
        _;
    }
    modifier isOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }
    modifier notOwner() {
        require(msg.sender != owner, "owner not allowed");
        _;
    }
}
