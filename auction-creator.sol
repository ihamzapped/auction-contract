// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {Auction} from "./auction.sol";

contract AuctionCreator {
    Auction[] public auctions;

    function deploy() public returns (Auction) {
        Auction addr = new Auction(msg.sender);
        auctions.push(addr);
        return addr;
    }
}
