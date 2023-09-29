// SPDX-License-Identifier: MIT
// Copyright (C) 2023
// val.sol : core vault
//

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface InvLike {
  function deposit(
    address[] memory asss_,
    uint256[] memory amts_,
    address reward
  ) external;

  function withdraw(address[] memory asss_, uint256[] memory amts_) external;

  function claim() external;

  function depositedAmount(
    address usr,
    address ass
  ) external view returns (uint256);

  function rewards(address usr, address ass) external view returns (uint256);

  function rewardTokens(address usr) external view returns (address[] memory);
}

interface PriceProviderLike {
  function price(address ass1, address ass2) external view returns (uint256); // ass1/ass2

  function price(address ass) external view returns (uint256); // in usd
}

interface ERC20Like is IERC20 {
  function mint(address account, uint256 amt) external;

  function burn(address account, uint256 amt) external;
}

contract Val is ReentrancyGuard {
  // ---- Auth ----
  mapping(address => uint) wards;

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

  struct Ass {
    uint256 min; // min persent
    uint256 max; // max persent
    uint256 pos;
  }

  struct Inv {
    uint256 max;
    uint256 amt;
  }

  mapping(address => Ass) public asss;
  mapping(address => mapping(address => Inv)) public invs;
  address[] invetors;
  address[] tokens;

  uint256 public live; // active flag
  PriceProviderLike public priceProvider;
  ERC20Like public core; // TDT, TCAv1, TCAV2

  uint256 constant ONE = 1.00E18;
  uint256 constant PENSENT_DIVISOR = 10000;

  event Rely(address indexed usr);
  event Deny(address indexed usr);

  constructor(address core_, address pp) {
    core = ERC20Like(core_);
    priceProvider = PriceProviderLike(pp);
    wards[msg.sender] = 1;
    live = 1;
    tokens.push(address(0)); // index 0 is 0
  }

  function stop() external auth {
    live = 0;
  }

  function setAsset(address ass, uint256 min, uint256 max) external auth {
    require(live == 1, "Vat/not-live");
    require(max > 0, "Vat/max persent error");

    Ass storage a = asss[ass];
    a.min = min;
    a.max = max;
    tokens.push(ass);
    a.pos = tokens.length - 1;
  }

  function removeAsset(address ass) external auth {
    uint256 pos = asss[ass].pos;
    require(pos > 0, "Val/asset not in whitelist");
    address a = tokens[tokens.length - 1];
    tokens[pos] = a;
    tokens.pop();
    asss[a].pos = pos;
    delete asss[ass];
  }

  // price provider
  function setPriceProvider(address pp) external auth {
    require(live == 1, "Vat/not-live");
    require(pp != address(0), "Vat/price provider not valid");
    priceProvider = PriceProviderLike(pp);
  }

  function setInv(address ass, address inv, uint256 max) external auth {
    require(live == 1, "Vat/not-live");
    require(asss[ass].pos > 0, "Val/asset not in whitelist");

    bool e = false;
    for (uint i = 0; i < invetors.length; i++) {
      if (invetors[i] == inv) {
        e = true;
        break;
      }
    }
    if (!e) {
      invetors.push(inv);
    }

    invs[ass][inv].max = max;
  }

  function invetMax(address ass, address inv) public view returns (uint256) {
    uint256 balance = assetAmount(ass);
    uint256 maxPersent = invs[ass][inv].max;
    uint256 max = (balance * maxPersent) / PENSENT_DIVISOR;
    InvLike invetor = InvLike(inv);
    uint256 damt = invetor.depositedAmount(address(this), ass);
    if (max > damt) {
      return max - damt;
    }
    return 0;
  }

  function assetAmount(address ass) public view returns (uint256) {
    IERC20 token = IERC20(ass);
    uint256 balance = token.balanceOf(address(this));
    for (uint i = 0; i < invetors.length; i++) {
      InvLike invetor = InvLike(invetors[i]);
      uint256 damt = invetor.depositedAmount(address(this), ass);
      uint256 rewards = invetor.rewards(address(this), ass);
      balance = balance + rewards + damt;
    }
    return balance;
  }

  function assetValue(address ass) public view returns (uint256) {
    uint256 balance = assetAmount(ass);
    uint256 value = (priceProvider.price(ass) * balance) / ONE;
    return value;
  }

  function totalValue() public view returns (uint256) {
    uint256 total = 0;
    for (uint i = 1; i < tokens.length; i++) {
      total += assetValue(tokens[i]);
    }
    return total;
  }

  function _assetPersent(
    address ass,
    int256 amt
  ) internal view returns (uint256) {
    int256 total = int256(totalValue());
    int256 assVal = int256(assetValue(ass));
    int256 dval = (int256(priceProvider.price(ass)) * amt) / int256(ONE);
    total += dval;
    assVal += dval;
    require(assVal > 0, "Val/asset is 0");
    return (PENSENT_DIVISOR * uint256(assVal)) / uint256(total);
  }

  function assetPersent(address ass) public view returns (uint256) {
    return _assetPersent(ass, 0);
  }

  function deposit(
    address[] memory asss_,
    uint256[] memory amts_,
    address inv_
  ) external auth {
    for (uint i = 0; i < asss_.length; i++) {
      uint256 amt = amts_[i];
      uint256 max = invetMax(asss_[i], inv_);
      require(amt <= max, "Val/amt error");
      IERC20 ass = IERC20(asss_[i]);
      ass.approve(inv_, amt);
    }
    InvLike(inv_).deposit(asss_, amts_, address(this));
  }

  function withdraw(
    address[] memory asss_,
    uint256[] memory amts_,
    address inv_
  ) external auth {
    InvLike(inv_).withdraw(asss_, amts_);
  }

  function buyFee(address ass, uint256 amt) public view returns (uint256) {
    uint256 p = _assetPersent(ass, int256(amt));
    if (p <= asss[ass].max) {
      return 0;
    }
    uint256 exc = p - asss[ass].max;
    return (exc * amt) / PENSENT_DIVISOR / 10;
  }

  function sellFee(address ass, uint256 amt) public view returns (uint256) {
    uint256 p = _assetPersent(ass, -int256(amt));
    if (p >= asss[ass].min) {
      return 0;
    }
    uint256 exc = asss[ass].min - p;
    return (exc * amt) / PENSENT_DIVISOR / 10;
  }

  // no buy fee
  function initAssets(
    address[] memory asss_,
    uint256[] memory amts_
  ) external auth {
    for (uint i = 0; i < asss_.length; i++) {
      _buy(asss_[i], msg.sender, amts_[i], false);
    }
  }

  function buy(
    address ass,
    address to,
    uint256 amt
  ) external returns (uint256) {
    return _buy(ass, to, amt, true);
  }

  // buy tdt, sell amt of ass buy tdt
  function _buy(
    address ass,
    address to,
    uint256 amt,
    bool useFee
  ) internal nonReentrant returns (uint256) {
    require(live == 1, "Vat/not-live");
    require(asss[ass].pos > 0, "Vat/asset not in whitelist");

    IERC20 token = IERC20(ass);
    token.transferFrom(msg.sender, address(this), amt);

    uint256 fee = 0;
    if (useFee) {
      fee = buyFee(ass, amt);
    }
    uint256 price = priceProvider.price(address(core), ass); // tdt/ass
    uint256 max = price * (amt - fee);

    core.mint(to, max);
    return max;
  }

  // sell core for ass, amt is tdt amount for sell
  function sell(
    address ass,
    address to,
    uint256 amt
  ) external nonReentrant returns (uint256) {
    require(live == 1, "Vat/not-live");
    require(asss[ass].pos > 0, "Vat/asset not in whitelist");

    core.burn(msg.sender, amt);

    uint256 price = priceProvider.price(ass, address(core)); // ass/tdt
    uint256 max = price * amt;
    uint256 fee = sellFee(ass, max);
    max = max - fee;

    IERC20 token = IERC20(ass);
    token.transfer(to, max);
    return max;
  }
}
