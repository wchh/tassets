// SPDX-License-Identifier: MIT
// Copyright (C) 2023
// vex.sol : veXXX : veTDT, veTTL, veTTS, veTTP
//

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ERC20Like is IERC20 {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}

contract Vex is ReentrancyGuard, ERC721 {
  // ---- Auth ----
  mapping(address => uint) wards;
  uint256 public live;

  modifier auth() {
    require(wards[msg.sender] == 1, "Val/not-authorized");
    _;
  }

  function rely(address usr) external auth {
    require(live == 1, "Vat/not-live");
    wards[usr] = 1;

    emit Rely(usr);
  }

  function deny(address usr) external auth {
    require(live == 1, "Vat/not-live");
    wards[usr] = 0;

    emit Deny(usr);
  }

  event Rely(address indexed usr);
  event Deny(address indexed usr);

  ERC20Like public token;
  uint256 public tokenId; // current

  struct Pow {
    uint256 balance;
    uint256 start;
    Long long;
  }

  enum Long {
    ONEMON,
    SIXMON,
    ONEYEAR,
    TWOYEAR,
    FOURYEAR
  }

  uint256 public constant POW_DIVISOR = 1000000;

  mapping(uint256 => Pow) public pows; // key is tokenId
  mapping(Long => uint256) public mults;
  mapping(Long => uint256) public longs;

  constructor(
    string memory name_,
    string memory symbol_,
    address token_
  ) ERC721(name_, symbol_) {
    token = ERC20Like(token_);
    live = 1;
    wards[msg.sender] = 1;

    longs[Long.ONEMON] = 30 days;
    longs[Long.SIXMON] = 180 days;
    longs[Long.ONEYEAR] = 365 days;
    longs[Long.TWOYEAR] = longs[Long.ONEYEAR] * 2;
    longs[Long.FOURYEAR] = longs[Long.TWOYEAR] * 2;

    // base rate = 1.02
    // ONEMON = 1.05, SIXMON = 1.05 ** 4, ONEYEAR = 1.05 ** 9, 16, 25 ...
    mults[Long.ONEMON] = 1050000;
    mults[Long.SIXMON] = 1215506;
    mults[Long.ONEYEAR] = 1551328;
    mults[Long.TWOYEAR] = 2208241;
    mults[Long.FOURYEAR] = 3386354;
  }

  function setMults(uint256[] memory mults_) public auth {
    require(
      mults_.length == uint256(Long.FOURYEAR) + 1,
      "Vex/mults length is invilid"
    );
    for (uint i = 0; i < mults_.length; i++) {
      mults[Long(i)] = mults_[i];
    }
  }

  function setLongs(uint256[] memory longs_) public auth {
    require(
      longs_.length == uint256(Long.FOURYEAR) + 1,
      "Vex/longs length is invilid"
    );
    for (uint i = 0; i < longs_.length; i++) {
      longs[Long(i)] = longs_[i];
    }
  }

  function power(uint256 tokenId_) public view returns (uint256) {
    Long l = pows[tokenId_].long;
    return (mults[l] * pows[tokenId_].balance) / POW_DIVISOR;
  }

  function deposit(uint256 amt, Long long) external returns (uint256) {
    token.transferFrom(msg.sender, address(this), amt);
    tokenId++;
    pows[tokenId] = Pow(amt, block.timestamp, long);
    _mint(msg.sender, tokenId);
    return tokenId;
  }

  function withdraw(uint256 tokenId_) external nonReentrant {
    require(ownerOf(tokenId_) == msg.sender, "Vex/tokenId not belong you");
    uint256 start = pows[tokenId_].start;
    Long long = pows[tokenId_].long;
    require(block.timestamp >= start + longs[long], "Vex/time is't up");
    _burn(tokenId_);
    uint256 amt = pows[tokenId_].balance;
    token.transfer(msg.sender, amt);
    uint256 reward = power(tokenId_) - amt;
    token.mint(msg.sender, reward);
    delete pows[tokenId_];
  }
}
