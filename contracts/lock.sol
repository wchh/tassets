// SPDX-License-Identifier: MIT
// Copyright (C) 2023
// lock.sol : lock token

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ERC20Like is IERC20 {
  function mint(address account, uint amt) external;

  function burn(address account, uint amt) external;
}

contract Lock is ReentrancyGuard {
  // ---- Auth ----
  mapping(address => uint) wards;
  uint public live;

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

  mapping(bytes32 => uint) public remains;
  mapping(bytes32 => address) public addrs;
  mapping(bytes32 => uint) public cycle;
  mapping(bytes32 => uint) public cycleMinted;

  uint public constant ONE = 1e18;
  uint public start;
  uint public initTeamLockLong = 300 days;
  uint public lpNext = 0;

  modifier onlyDao() {
    require(msg.sender == addrs["dao"], "Val/not-authorized");
    _;
  }
  modifier onlytsaDao() {
    require(msg.sender == addrs["tsaDao"], "Val/not-authorized");
    _;
  }
  modifier onlyteam() {
    require(msg.sender == addrs["team"], "Val/not-authorized");
    _;
  }
  modifier onlylpFund() {
    require(msg.sender == addrs["lpFund"], "Val/not-authorized");
    _;
  }

  event DaoMint(address indexed usr, uint amt);
  event TsaDaoMint(address indexed usr, uint amt);
  event TeamMint(address indexed usr, uint amt);
  event LpFundMint(address indexed usr, uint amt);

  constructor(
    address token_,
    address dao_,
    address tsaDao_,
    address team_,
    address lpFund_
  ) {
    live = 1;
    wards[msg.sender] = 1;
    token = ERC20Like(token_);
    addrs["dao"] = dao_;
    addrs["tsaDao"] = tsaDao_;
    addrs["team"] = team_;
    addrs["lpFund"] = lpFund_;

    cycle["dao"] = 30 days;
    cycle["tsaDao"] = 30 days;
    cycle["team"] = 30 days;
    cycle["lpFund"] = 7 days;

    token.mint(dao_, 2e7 * ONE);
    remains["tsaDao"] = 1e8 * ONE;
    remains["team"] = 1e8 * ONE;
    remains["dao"] = 8e7 * ONE;
    remains["lpFund"] = 7e8 * ONE;
    start = block.timestamp;

    cycleMinted["dao"] = remains["dao"] / 80;
    cycleMinted["tsaDao"] = remains["tsaDao"] / 50;
    cycleMinted["team"] = remains["team"] / 80;
    lpNext = remains["lpFund"] / 52 / 5;
  }

  function daoMint() external onlyDao nonReentrant {
    require(remains["dao"] > 0, "Val/no-remain");
    uint nth = (block.timestamp - start) / cycle["dao"];
    uint amt = remains["dao"] - cycleMinted["dao"] * nth;
    require(amt > 0, "Val/no-remain");

    remains["dao"] -= amt;
    token.mint(addrs["dao"], amt);
    emit DaoMint(addrs["dao"], amt);
  }

  function tsaDaoMint() external onlytsaDao nonReentrant {
    require(remains["tsaDao"] > 0, "Val/no-remain");
    uint nth = (block.timestamp - start) / cycle["tsaDao"];
    uint amt = remains["tsaDao"] - cycleMinted["tsaDao"] * nth;
    require(amt > 0, "Val/no-remain");

    remains["tsaDao"] -= amt;
    token.mint(addrs["tsaDao"], amt);
    emit TsaDaoMint(addrs["tsaDao"], amt);
  }

  function teamMint() external onlyteam nonReentrant returns (uint) {
    if (block.timestamp - start < initTeamLockLong) {
      return 0;
    }
    uint teamStart = start + initTeamLockLong;
    require(remains["team"] > 0, "Val/no-remain");
    uint nth = (block.timestamp - teamStart) / cycle["team"];
    uint amt = remains["team"] - cycleMinted["team"] * nth;
    require(amt > 0, "Val/no-remain");

    remains["team"] -= amt;
    token.mint(addrs["team"], amt);
    emit TeamMint(addrs["team"], amt);
    return amt;
  }

  function lpFundMint() external onlylpFund nonReentrant {
    require(remains["lpFund"] > 0, "Val/no-remain");
    uint amt = lpNext;
    if (amt > remains["lpFund"]) {
      amt = remains["lpFund"];
    }
    require(amt > 0, "Val/no-remain");

    remains["lpFund"] -= amt;
    token.mint(addrs["lpFund"], amt);
    emit LpFundMint(addrs["lpFund"], amt);
  }

  function setLpNext(uint amt) external auth {
    lpNext = amt;
  }
}
