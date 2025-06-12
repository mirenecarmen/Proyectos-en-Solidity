// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Bad Bunny Auction Contract
/// @author
/// @notice This contract allows bidding on a VIP concert ticket with time extension logic.
/// @dev Handles commission, refunding, and bid history tracking.

contract SubastaBadBunny {
    address payable public seller;
    address payable public commissionReceiver;
    string public itemName;
    uint public minimumBid;
    uint public auctionStart;
    uint public auctionEnd;
    uint public extensionTime = 10 minutes;
    uint public duration = 60 minutes;
    uint public commissionPercent = 2;

    struct Bid {
        address payable bidder;
        uint amount;
    }

    Bid[] public bidHistory;
    mapping(address => uint) public refunds;

    address public highestBidder;
    uint public highestBid;
    bool public ended;

    event NewBid(address bidder, uint amount);
    event AuctionEnded(address winner , uint amount);

    modifier onlyWhileActive() {
        require(block.timestamp >= auctionStart, "Too early");
        require(block.timestamp <= auctionEnd, "Too late");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp > auctionEnd, "Still active");
        _;
    }

    constructor(uint _minimumBid) {
        require(_minimumBid > 0, "Min > 0");
        itemName = "VIP pass BB concert BA, River Plate, 2026";
        seller = payable(msg.sender);
        commissionReceiver = payable(msg.sender);
        minimumBid = _minimumBid;
        auctionStart = block.timestamp;
        auctionEnd = auctionStart + duration;
    }

    /// @notice Allows users to place a new bid
    /// @dev Extends auction time if bid placed near end
    function placeBid() external payable onlyWhileActive {
        require(msg.value >= minimumBid, "Below min");
        require(
            msg.value >= highestBid + (highestBid * 5) / 100,
            "Min +5% required"
        );

        if (highestBidder != address(0)) {
            refunds[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        bidHistory.push(Bid(payable(msg.sender), msg.value));

        if (auctionEnd - block.timestamp <= extensionTime) {
            auctionEnd = block.timestamp + extensionTime;
        }

        emit NewBid(msg.sender, msg.value);
    }

    /// @notice Refund all losing bids
    /// @dev Should be called after auction ends to clean up refunds
    function refundAllLosers() external onlyAfterEnd {
        uint len = bidHistory.length;
        address currentHighest = highestBidder;

        for (uint i = 0; i < len; i++) {
            address payable bidder = bidHistory[i].bidder;

            if (bidder != currentHighest && refunds[bidder] > 0) {
                uint refund = refunds[bidder];
                refunds[bidder] = 0;
                bidder.transfer(refund);
            }
        }
    }

    /// @notice Allows partial withdrawal of refunds
    /// @param _amount The amount to withdraw
    function withdrawPartial(uint _amount) external {
        require(refunds[msg.sender] > 0, "No refund");
        require(_amount > 0 && _amount <= refunds[msg.sender], "Invalid amount");

        refunds[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    /// @notice Withdraw full available refund
    function withdrawRefund() external {
        uint amount = refunds[msg.sender];
        require(amount > 0, "No refund");

        refunds[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /// @notice Finalize auction, transfer funds
    function finalizeAuction() external onlyAfterEnd {
        require(!ended, "Already done");
        require(highestBid > 0, "No bids");

        ended = true;

        uint commissionAmount = (highestBid * commissionPercent) / 100;
        uint payout = highestBid - commissionAmount;

        seller.transfer(payout);

        if (commissionReceiver != address(0)) {
            commissionReceiver.transfer(commissionAmount);
        }

        emit AuctionEnded(highestBidder, highestBid);
    }

    /// @notice Returns winner and bid
    /// @return winner address and bid amount
    function getWinner() external view returns (address, uint) {
        return (highestBidder, highestBid);
    }

    /// @notice Returns bid history
    /// @return All bids made in order
    function getBidHistory() external view returns (Bid[] memory) {
        return bidHistory;
    }

    /// @notice Emergency function to recover stuck ETH
    /// @dev Only callable after auction end by seller
    function emergencyWithdraw() external onlyAfterEnd {
        require(msg.sender == seller, "Only seller");
        uint balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        seller.transfer(balance);
    }
}