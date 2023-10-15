# GMX 协议分析

**注意: 以下内容来源于[知乎](https://zhuanlan.zhihu.com/p/621120121), 我这里对照代码验证了一遍**

## 1 GMX的产品设计目标

GMX的产品设计目标是打造一个去中心化的永续合约和现货交易平台。不需要任何注册、KYC和地域限制等限制，用户即可方便地用它进行链上资产交易和合约交易。

## 2 GMX的核心卖点

1. **去中心化**。GMX是一个去中心化的永续合约交易平台，所有资产由智能合约保管，智能合约开源，所有运营数据也是公开透明的。
2. **全额保证金**。GMX上面的所有杠杆订单都是有全额保证金的，保障用户的收益能够钢性对付，很多中心化交易所都无法做到全额保证金。
3. **无需许可Permissionless**。所有人都可以公平得参与平台做市，并且根据GMX和GLP持有量平等地分到平台的盈利。
4. **市场报价去中心化**。系统报价主要由ChainLink和报价机器人组成，报价公开透明，有效避免了恶意插针等扰乱市场的行为。

## 3 GMX的系统整体设计

### 3.1 GMX系统架构图

![](https://pic3.zhimg.com/80/v2-c84412676efccb2aa5b9048958dd48de_1440w.webp)

其中，Vault合约是整个GMX的核心，负责管理GMX平台的全部资产。

### 3.2 系统核心数据模型

```json
{
    "id": keccak256(_account, _collateralToken, _indexToken, _isLong), // 仓位ID
    "size": uint256, // Position大小
    "collateral": uint256, // 抵押品价格 USD
    "averagePrice": uint256, // 平均持仓价格 USD
    "entryFundingRate": uint256, // 入场资金费率
    "reserveAmount": uint256, // 抵押品token储备数量
    "realisedPnl": int256, // 已兑付盈亏
    "lastIncreasedTime": uint256, // 最后加仓时间
}
```

盈亏USD价值计算：

```js
delta = position.size * (currentPrice - position.averagePrice)  / position.averagePrice
```

## 4 GMX核心业务逻辑解读

了解了GMX系统设计框架，那么解析来就逐个解析它的核心业务流程。

### 4.1 GMX加减仓业务逻辑

### 4.1.1 GMX加减仓业务流程

![](https://pic4.zhimg.com/80/v2-55df4cd14444f9b79ee369e0b172462b_1440w.webp)

**创建订单流程**

1. 用户在Web页面发起市价或者限价单，并发送Transaction到链上。
2. Transaction会根据用户的提交参数，选择调用市价单或者限价单合约来创建订单。
3. 结束，等待交易机器人执行交易。

**执行订单流程**

1. 执行交易机器人根据市场价选择执行市价单或者限价单，并发送交易到链上。
2. Transaction会根据会根据机器人的提交参数，选择调用市价单或者限价单合约和执行订单。
3. 市价单或者限价单合约会调用Vault合约来执行加减仓操作。

### 4.1.2 GMX加减仓流程解读

从加减仓业务流程中可以看出，订单的创建和执行是2个独立的步骤。首先，用户创建市价单和限价单，并由市价单合约和限价单合约来保存订单数据。然后，订单执行机器人会异步调用市价单合约和限价单合约来执行订单。订单执行机器人可以根据当前的市价选择哪些订单可以被执行。

**手续费 = 交易手续费 + 资金费用**

1. 交易手续费：价减仓USD金额 * 0.1%。
2. 资金费用：仓位总USD价值 * 时间间隔 * 单位USD单位时间间隔的费率。

**爆仓条件**

另外还需要判断是否爆仓，满足一下条件之一就有可能爆仓。

1. 条件一：抵押品总USD价值 + 仓位盈亏USD价值 < 资金USD费用 + 清算USD费用。
2. 条件二：(抵押品总USD价值 + 仓位盈亏USD价值) * 最大杠杆倍数 < 仓位总USD价值。

其中，清算USD费用由管理员设置。

**相关合约地址**

| 合约名称    | 合约地址                                                                                                                                                                              |
| ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 市价单合约   | [https://arbiscan.io/address/0xb87a436b93ffe9d75c5cfa7bacfff96430b09868](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xb87a436b93ffe9d75c5cfa7bacfff96430b09868) |
| 限价单合约   | [https://arbiscan.io/address/0x09f77e8a13de9a35a7231028187e9fd5db8a2acb](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x09f77e8a13de9a35a7231028187e9fd5db8a2acb) |
| Vault合约 | [https://arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a) |

**相关交易操作交易Hash**

| 操作名称        | 交易Hash                                                                                                                                                                                                                  |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 用户发起市价单加仓交易 | [https://arbiscan.io/tx/0x3230e702a44c6029790d279d0a11e87f89474a9fec251aa0b7f5070aab38104b](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x3230e702a44c6029790d279d0a11e87f89474a9fec251aa0b7f5070aab38104b) |
| 用户发起市价单减仓交易 | [https://arbiscan.io/tx/0x7d359cb6a1744f87c6b4cc1ff93a8b8ee9fc6bbfa73227e8c7d8b59214a8a368](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x7d359cb6a1744f87c6b4cc1ff93a8b8ee9fc6bbfa73227e8c7d8b59214a8a368) |
| 执行机器人执行市价单  | [https://arbiscan.io/tx/0x5f5a3a90ed30b099ad456f14e7ea580cea3f25cd4bdf2d491ae5e18eadd87ff2](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x5f5a3a90ed30b099ad456f14e7ea580cea3f25cd4bdf2d491ae5e18eadd87ff2) |
| 执行机器人执行限价单  | [https://arbiscan.io/tx/0x3cc5b3bd1fc5efeba0cbf1cfc5752773d9476c15b2fb8cc3bb5dc02b8480b5af](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x3cc5b3bd1fc5efeba0cbf1cfc5752773d9476c15b2fb8cc3bb5dc02b8480b5af) |

### 4.2 GMX清算业务逻辑

### 4.2.1 GMX清算业务流程

![](https://pic4.zhimg.com/80/v2-ac906494e071123d0c71539842d2cddb_1440w.webp)

**清算流程**

1. 清算机器人发送清算交易，并广播到链上
2. 仓位管理合约调用Vault合约执行清算逻辑

### 4.2.2 GMX清算流程解读

清算流程主要清算机器人来发起，清算机器人会监控合约中的Position，并调用合约方法来对爆仓的Position进行清算。完成清算任务后，清算机器人收到一笔清算手续费。

**仓位清算条件**

满足一下条件之一就可以被清算

1. 条件一：抵押品总USD价值 + 仓位盈亏USD价值 < 资金USD费用 + 清算USD费用
2. 条件二：(抵押品总USD价值 + 仓位盈亏USD价值) * 最大杠杆倍数 < 仓位总USD价值

其中，清算USD费用大小由管理员设置。

**相关合约地址**

| 合约名称    | 合约地址                                                                                                                                                                              |
| ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 仓位管理合约  | [https://arbiscan.io/address/0x75e42e6f01baf1d6022bea862a28774a9f8a4a0c](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x75e42e6f01baf1d6022bea862a28774a9f8a4a0c) |
| Vault合约 | [https://arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a) |

**相关交易操作交易Hash**

| 操作名称        | 交易Hash                                                                                                                                                                                                                  |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 清算机器人发起清算流程 | [https://arbiscan.io/tx/0xccca7adf093d4e20ed25d2d479419a1efaac964c337beea958f214b4db195c34](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0xccca7adf093d4e20ed25d2d479419a1efaac964c337beea958f214b4db195c34) |

### 4.3 GMX现货交易业务逻辑

### 4.3.1 GMX现货交易业务流程

![](https://pic3.zhimg.com/80/v2-f39423c1bd88a0814eb436434b2a19ee_1440w.webp)

**现货交易流程**

1. 用户发起现货交易，并广播到链上。
2. Router合约调用Vault合约执行现货交易。
3. Vault合约从Token价格合约获取价格，并执行交易。

### 4.3.2 GMX现货交易流程解读

GMX的现货交易不是主流的AMM，而是通过Chainlink获取TokenIn价格，然后计算出TokenOut的数量。具体计算过程如下

1. 先从Token价格合约获取tokenInUSDPrice和tokenOutUSDPrice。
2. 计算tokenOutAmount：`tokenOutAmount = tokenInAmount * tokenInUSDPrice / tokenOutUSDPrice`。

**相关合约地址**

| 合约名称      | 合约地址                                                                                                                                                                              |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Router合约  | [https://arbiscan.io/address/0xabbc5f99639c9b6bcb58544ddf04efa6802f4064](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xabbc5f99639c9b6bcb58544ddf04efa6802f4064) |
| Vault合约   | [https://arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a) |
| Token价格合约 | [https://arbiscan.io/address/0x2d68011bca022ed0e474264145f46cc4de96a002](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x2d68011bca022ed0e474264145f46cc4de96a002) |

**相关交易操作交易Hash**

| 操作名称     | 交易Hash                                                                                                                                                                                                                  |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 用户发起现货交易 | [https://arbiscan.io/tx/0x0da7809c5f6372b5cc7342493fa405d0215d56ac47167b2682797df3ac4fca64](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x0da7809c5f6372b5cc7342493fa405d0215d56ac47167b2682797df3ac4fca64) |

### 4.4 GMX质押和解除业务逻辑

### 4.4.1 GMX质押业务流程

![](https://pic3.zhimg.com/80/v2-aea777ad07bf75f8b61e1f3a0fe7085a_1440w.webp)

**GMX质押流程**

1. 用户向RewardRouter合约发起GMX质押。
2. RewardRouter合约调用sGMX RewardTracker合约，质押GMX并得到sGMX。
3. RewardRouter合约调用sbGMX RewardTracker合约，质押sGMX并得到sbGMX。
4. RewardRouter合约调用sbfGMX RewardTracker合约，质押sbGMX并得到sbfGMX。
5. 用户最终得到sbfGMX。

### 4.4.2 GMX质押流程解读

质押业务由用户发起，质押核心业务逻辑在RewardRouter核心实现。质押具体逻辑主要由sGMX RewardTracker合约、sbGMX RewardTracker合约和sbfGMX RewardTracker合约来实现，它们的作用分别为

- sGMX RewardTracker合约是sGMX的ERC20合约，同时负责质押GMX并Mint sGMX。质押GMX的用户可以获取esGMX Token奖励。
- sbGMX RewardTracker合约是sbGMX的ERC20合约，同时负责质押sGMX并Mint sbGMX。质押sGMX的用户可以获取bnGMX Token奖励。
- sbfGMX RewardTracker合约是sbfGMX的ERC20合约，同时负责质押sbGMX并Mint sbfGMX。质押sbGMX的用户可以获取平台手续费，以WETH结算。

这样做的好处是RewardTracker合约即作为ERC20合约，又负责了质押业务，节省了合约gas成本。

**esGMX是什么**

esGMX等同与GMX，但是esGMX无法转账交易。用户可以把esGMX质押到gmxVestor合约，一年时间内esGMX就会在一年时间内线性地转换为GMX。

**bnGMX是什么**

bnGMX会在restake进行二次质押，并且提升用户的APR。但是在unstake的时候，就会burn掉。

**相关合约地址**

| 合约名称                   | 合约地址                                                                                                                                                                              |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RewardRouter合约         | [https://arbiscan.io/address/0xa906f338cb21815cbc4bc87ace9e68c87ef8d8f1](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xa906f338cb21815cbc4bc87ace9e68c87ef8d8f1) |
| sGMX RewardTracker合约   | [https://arbiscan.io/address/0x908c4d94d34924765f1edc22a1dd098397c59dd4](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x908c4d94d34924765f1edc22a1dd098397c59dd4) |
| sbGMX RewardTracker合约  | [https://arbiscan.io/address/0x4d268a7d4c16ceb5a606c173bd974984343fea13](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x4d268a7d4c16ceb5a606c173bd974984343fea13) |
| sbfGMX RewardTracker合约 | [https://arbiscan.io/address/0xd2d1162512f927a7e282ef43a362659e4f2a728f](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xd2d1162512f927a7e282ef43a362659e4f2a728f) |

**相关交易操作交易Hash**

| 操作名称  | 交易Hash                                                                                                                                                                                                                  |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GMX质押 | [https://arbiscan.io/tx/0xf885f7691effca2b0ba23423fa38941d3c2341598c6de208f025375e91d3c4e1](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0xf885f7691effca2b0ba23423fa38941d3c2341598c6de208f025375e91d3c4e1) |

### 4.4.3 GMX解除质押业务流程

![](https://pic3.zhimg.com/80/v2-281852b9cb7ac05d25b36bfccdd1efd6_1440w.webp)

**GMX解除质押流程**

1. 用户向RewardRouter合约发起GMX解除质押。
2. RewardRouter合约调用sbfGMX RewardTracker合约，解除质押sbfGMX并得到sbGMX。
3. RewardRouter合约调用sbGMX RewardTracker合约，解除质押sbGMX并得到sGMX。
4. RewardRouter合约调用sGMX RewardTracker合约，解除质押sGMX并得到GMX。
5. 用户最终得到GMX。

### 4.4.4 GMX解除质押流程解读

GMX解除质押业务流程就是质押流程的逆向操作，输入是sbfGMX，最终得到GMX。

**相关合约地址**

| 合约名称                   | 合约地址                                                                                                                                                                              |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RewardRouter合约         | [https://arbiscan.io/address/0xa906f338cb21815cbc4bc87ace9e68c87ef8d8f1](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xa906f338cb21815cbc4bc87ace9e68c87ef8d8f1) |
| sGMX RewardTracker合约   | [https://arbiscan.io/address/0x908c4d94d34924765f1edc22a1dd098397c59dd4](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x908c4d94d34924765f1edc22a1dd098397c59dd4) |
| sbGMX RewardTracker合约  | [https://arbiscan.io/address/0x4d268a7d4c16ceb5a606c173bd974984343fea13](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x4d268a7d4c16ceb5a606c173bd974984343fea13) |
| sbfGMX RewardTracker合约 | [https://arbiscan.io/address/0xd2d1162512f927a7e282ef43a362659e4f2a728f](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xd2d1162512f927a7e282ef43a362659e4f2a728f) |

**相关交易操作交易Hash**

| 操作名称    | 交易Hash                                                                                                                                                                                                                  |
| ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GMX解除质押 | [https://arbiscan.io/tx/0x1dc5efbc0ddfe09c3596407d1974647b787f77794a415e81df11ff21e8d683c3](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x1dc5efbc0ddfe09c3596407d1974647b787f77794a415e81df11ff21e8d683c3) |

### 4.5 GLP质押和解除业务逻辑

### 4.5.1 GLP质押业务流程

![](https://pic4.zhimg.com/80/v2-7f4062777accb763baf7db20062e41bf_1440w.webp)

**GLP质押流程**

1. 用户调用RewardRouter合约，发起GLP Mint和质押流程。
2. RewardRouter合约调用GlpManager合约，发起GLP Mint。
3. GlpManager合约调用Vault合约，消耗eth并mint 相应数量的USDg。
4. GlpManager合约调用GLP合约，消耗USDg并Mint GLP。
5. RewardRouter合约调用fGLP RewardTracker合约，质押GLP并得到fGLP。
6. RewardRouter合约调用fsGLP RewardTracker合约，质押fGLP并得到fsGLP。
7. 最终用户得到fsGLP。

### 4.5.2 GLP质押流程解读

GLP的Mint和质押流程需要先通过GlpManager合约，把输入的eth兑换成USDg，1 USDg = 1 USD。再用USDg来兑换GLP。完成GLP兑换后再通过fGLP RewardTracker合约和fsGLP RewardTracker合约的循环质押，最终得到fsGLP。

- fGLP RewardTracker合约是fGLP的ERC20合约，同时负责质押GLP并Mint fGLP。质押GLP可以获得平台手续费，以WETH结算。
- fsGLP RewardTracker合约是fsGLP的ERC20合约，同时负责质押fGLP并Mint fsGLP。质押fGLP可以获得esGMX Token奖励。

**相关合约地址**

| 合约名称                  | 合约地址                                                                                                                                                                              |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RewardRouter合约        | [https://arbiscan.io/address/0xa906f338cb21815cbc4bc87ace9e68c87ef8d8f1](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xa906f338cb21815cbc4bc87ace9e68c87ef8d8f1) |
| GlpManager合约          | [https://arbiscan.io/address/0x3963ffc9dff443c2a94f21b129d429891e32ec18](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x3963ffc9dff443c2a94f21b129d429891e32ec18) |
| Vault合约               | [https://arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a) |
| GLP合约                 | [https://arbiscan.io/address/0x4277f8f2c384827b5273592ff7cebd9f2c1ac258](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x4277f8f2c384827b5273592ff7cebd9f2c1ac258) |
| fGLP RewardTracker合约  | [https://arbiscan.io/address/0x4e971a87900b931ff39d1aad67697f49835400b6](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x4e971a87900b931ff39d1aad67697f49835400b6) |
| fsGLP RewardTracker合约 | [https://arbiscan.io/address/0x1addd80e6039594ee970e5872d247bf0414c8903](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x1addd80e6039594ee970e5872d247bf0414c8903) |

**相关交易操作交易Hash**

| 操作名称  | 交易Hash                                                                                                                                                                                                                  |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GLP质押 | [https://arbiscan.io/tx/0x348cffb309afeafe3fa252c355e6f27251ab40bb9dfa48b0b0ee8c40cf95d9e1](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x348cffb309afeafe3fa252c355e6f27251ab40bb9dfa48b0b0ee8c40cf95d9e1) |

### 4.5.3 GLP解除质押业务流程

![](https://pic4.zhimg.com/80/v2-186f656c276c0aaef89738d4b5c38047_1440w.webp)

**GLP解除质押流程**

1. 用户调用RewardRouter合约，发起GLP解除质押和burn流程。
2. RewardRouter合约调用fsGLP RewardTracker合约，burn fsGLP并得到fGLP。
3. RewardRouter合约调用fGLP RewardTracker合约，burn fGLP并得到GLP。
4. RewardRouter合约调用GlpManager合约，发起GLP burn。
5. GlpManager合约调用GLP合约，burn GLP并得到USDg。
6. GlpManager合约调用Vault合约，burn USDG并得到eth。
7. 最终用户得到ETH。

### 4.5.4 GLP解除质押流程解读

GLP解除质押就是质押流程的逆向操作，输入是fsGLP，最终得到ETH。

**相关合约地址**

| 合约名称                  | 合约地址                                                                                                                                                                              |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RewardRouter合约        | [https://arbiscan.io/address/0xa906f338cb21815cbc4bc87ace9e68c87ef8d8f1](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xa906f338cb21815cbc4bc87ace9e68c87ef8d8f1) |
| GlpManager合约          | [https://arbiscan.io/address/0x3963ffc9dff443c2a94f21b129d429891e32ec18](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x3963ffc9dff443c2a94f21b129d429891e32ec18) |
| Vault合约               | [https://arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a) |
| GLP合约                 | [https://arbiscan.io/address/0x4277f8f2c384827b5273592ff7cebd9f2c1ac258](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x4277f8f2c384827b5273592ff7cebd9f2c1ac258) |
| fGLP RewardTracker合约  | [https://arbiscan.io/address/0x4e971a87900b931ff39d1aad67697f49835400b6](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x4e971a87900b931ff39d1aad67697f49835400b6) |
| fsGLP RewardTracker合约 | [https://arbiscan.io/address/0x1addd80e6039594ee970e5872d247bf0414c8903](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x1addd80e6039594ee970e5872d247bf0414c8903) |

**相关交易操作交易Hash**

| 操作名称    | 交易Hash                                                                                                                                                                                                                  |
| ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GLP解除质押 | [https://arbiscan.io/tx/0x79b20a42a9ed410772fea136b0f45bf1f35ea77a2726aef170c1ba9612109888](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x79b20a42a9ed410772fea136b0f45bf1f35ea77a2726aef170c1ba9612109888) |

### 4.6 GMX领取质押收益业务逻辑

### 4.6.1 GMX领取质押收益业务流程

![](https://pic2.zhimg.com/80/v2-082c6a632097af8e133c065bd7a86c79_1440w.webp)

**GMX领取收益流程**

1. 用户调用RewardRouter合约发起领取收益流程。
2. RewardRouter合约调用gmxVester合约领取GMX收益。
3. RewardRouter合约调用glpVester合约领取GMX收益。
4. RewardRouter合约调用sGMX RewardTracker合约领取esGMX收益。
5. RewardRouter合约调用fsGLP RewardTracker合约领取esGMX收益。
6. RewardRouter合约调用sbGMX RewardTracker合约领取bnGMX收益。
7. RewardRouter合约调用sbfGMX RewardTracker合约领取平台手续费，以WETH结算。
8. RewardRouter合约调用fGLP RewardTracker合约领取平台手续费，以WETH结算。
9. RewardRouter合约收到的GMX、esGMX和WETH发送给用户。

### 4.6.2 GMX领取质押收益流程解读

领取质押收益主要由用户发起，RewardRouter合约来调用其它收益合约来领取收益。

**RewardTracker合约的收益计算公式**

可领取收益 = 用户质押数量 * 质押时长 * 单位质押单位时间的收益率

其中，单位质押单位时间的收益率由管理员来设置。

**gmxVester合约和glpVester合约是什么**

gmxVester合约和glpVester合约是用来转换esGMX到GMX的合约。收益计算公式为

可领取收益 = esGMX质押数量 * 质押时长 / vestingDuration

其中，vestingDuration由管理员设置，目前设置为1年时间。

**相关合约地址**

| 合约名称                   | 合约地址                                                                                                                                                                              |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RewardRouter合约         | [https://arbiscan.io/address/0xa906f338cb21815cbc4bc87ace9e68c87ef8d8f1](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xa906f338cb21815cbc4bc87ace9e68c87ef8d8f1) |
| gmxVester合约            | [https://arbiscan.io/address/0x199070ddfd1cfb69173aa2f7e20906f26b363004](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x199070ddfd1cfb69173aa2f7e20906f26b363004) |
| glpVester合约            | [https://arbiscan.io/address/0xa75287d2f8b217273e7fcd7e86ef07d33972042e](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xa75287d2f8b217273e7fcd7e86ef07d33972042e) |
| fGLP RewardTracker合约   | [https://arbiscan.io/address/0x4e971a87900b931ff39d1aad67697f49835400b6](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x4e971a87900b931ff39d1aad67697f49835400b6) |
| fsGLP RewardTracker合约  | [https://arbiscan.io/address/0x1addd80e6039594ee970e5872d247bf0414c8903](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x1addd80e6039594ee970e5872d247bf0414c8903) |
| sGMX RewardTracker合约   | [https://arbiscan.io/address/0x908c4d94d34924765f1edc22a1dd098397c59dd4](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x908c4d94d34924765f1edc22a1dd098397c59dd4) |
| sbGMX RewardTracker合约  | [https://arbiscan.io/address/0x4d268a7d4c16ceb5a606c173bd974984343fea13](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x4d268a7d4c16ceb5a606c173bd974984343fea13) |
| sbfGMX RewardTracker合约 | [https://arbiscan.io/address/0xd2d1162512f927a7e282ef43a362659e4f2a728f](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xd2d1162512f927a7e282ef43a362659e4f2a728f) |

**相关交易操作交易Hash**

| 操作名称   | 交易Hash                                                                                                                                                                                                                  |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 领取质押收益 | [https://arbiscan.io/tx/0x2731c50c5b63e80779aaa97b14a1d25cdf1f4ecc414204d583238fb38c076096](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x2731c50c5b63e80779aaa97b14a1d25cdf1f4ecc414204d583238fb38c076096) |

### 4.7 GMX平台手续费归集并分配收入业务逻辑

### 4.7.1 GMX平台手续费归集并分配收入业务流程

![](https://pic4.zhimg.com/80/v2-2ecfeb6d4e4327d70e371e9e1d1ba3c7_1440w.webp)

**业务流程**

1. 由平台管理员统一从Vault合约中领取平台手续费。

2. Vault合约把手续费都转移到平台手续费收益管理员。

3. 平台手续费收益管理员调用Router合约把手续费全都转换成WETH。

4. Router合约会调用Vault合约进行token swap。

5. 平台手续费收益管理员最后把手续费都转移到RewardDistributor合约。

6. GMX质押用户领取手续费的时候，sbfGMX RewardTracker合约会从sbfGMX RewardDistributor合约获取手续费收入。

7. GLP质押用户领取手续费的时候，fGLP RewardTracker合约会从fGLP RewardDistributor合约获取手续费收入。

### 4.7.2 GMX平台手续费归集并分配收入业务解读

从流程图中可以看出，目前手续费分配的逻辑还是比较中心化的，需要平台管理员EOA账户和平台手续费收益管理员EOA账户来控制。

- 平台管理员EOA账户主要负责提取手续费到平台手续费收益管理员EOA账户。
- 平台手续费收益管理员EOA账户主要负责把收到的手续费都换成WETH，并把WETH都转移到RewardDistributor合约。

**相关合约地址**

| 合约名称                       | 合约地址                                                                                                                                                                              |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Timelock合约                 | [https://arbiscan.io/address/0xe7e740fa40ca16b15b621b49de8e9f0d69cf4858](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xe7e740fa40ca16b15b621b49de8e9f0d69cf4858) |
| Vault合约                    | [https://arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x489ee077994b6658eafa855c308275ead8097c4a) |
| Router合约                   | [https://arbiscan.io/address/0xabbc5f99639c9b6bcb58544ddf04efa6802f4064](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0xabbc5f99639c9b6bcb58544ddf04efa6802f4064) |
| sbfGMX RewardDistributor合约 | [https://arbiscan.io/address/0x1de098faf30bd74f22753c28db17a2560d4f5554](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x1de098faf30bd74f22753c28db17a2560d4f5554) |
| fGLP RewardDistributor合约   | [https://arbiscan.io/address/0x5c04a12eb54a093c396f61355c6da0b15890150d](https://link.zhihu.com/?target=https%3A//arbiscan.io/address/0x5c04a12eb54a093c396f61355c6da0b15890150d) |

**相关交易操作交易Hash**

| 操作名称                                     | 交易Hash                                                                                                                                                                                                                  |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 平台管理员提取手续费收益                             | [https://arbiscan.io/tx/0x8c0c1ceae993b037d003a195a72147a702f772986de3b4076cf614edaf6834d0](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x8c0c1ceae993b037d003a195a72147a702f772986de3b4076cf614edaf6834d0) |
| 手续费管理员执行Token Swap                       | [https://arbiscan.io/tx/0x2612bce63d085248fee6193b0ca3ba189d353bc7d3f5492017c7a6c7d933cbfd](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x2612bce63d085248fee6193b0ca3ba189d353bc7d3f5492017c7a6c7d933cbfd) |
| 手续费管理员执行Token Swap                       | [https://arbiscan.io/tx/0x4b1a039541b367d3fe38db73d491d58b9d9dd5baf7e34cd9bdd5286725634536](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x4b1a039541b367d3fe38db73d491d58b9d9dd5baf7e34cd9bdd5286725634536) |
| 手续费管理员执行Token Swap                       | [https://arbiscan.io/tx/0x8c46063bde7e5f415e0c0c72974c22ca28814f284f268f4565a071734d13bc8b](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x8c46063bde7e5f415e0c0c72974c22ca28814f284f268f4565a071734d13bc8b) |
| 手续费管理员执行Token Swap                       | [https://arbiscan.io/tx/0x0ea7999ad2cb34bbd88e88be66bb5f7758b4f33283d1d20bc82f7e4b507afdf3](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x0ea7999ad2cb34bbd88e88be66bb5f7758b4f33283d1d20bc82f7e4b507afdf3) |
| 手续费管理员执行Token Swap                       | [https://arbiscan.io/tx/0x40cfbc735a065d63f9058cbde762dc1ca7fe7e39308b7b216e285d62a246c206](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x40cfbc735a065d63f9058cbde762dc1ca7fe7e39308b7b216e285d62a246c206) |
| 手续费管理员执行Token Swap                       | [https://arbiscan.io/tx/0x0d39b2273b70f677543a6f204810dd3e16abc0adb09804a721b4502b68b2c8b2](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x0d39b2273b70f677543a6f204810dd3e16abc0adb09804a721b4502b68b2c8b2) |
| 手续费管理员把WETH转移到sbfGMX RewardDistributor合约 | [https://arbiscan.io/tx/0xe77d0ef63db5a776b976dc13f46d5942b7a11ccad953e20f3c7b7ae88f888679](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0xe77d0ef63db5a776b976dc13f46d5942b7a11ccad953e20f3c7b7ae88f888679) |
| 手续费管理员把WETH转移到fGLP RewardDistributor合约   | [https://arbiscan.io/tx/0x71e030541f1e10cd866ab15fa7eb3c0645ddeccce5c782baa7eb05f8d2490613](https://link.zhihu.com/?target=https%3A//arbiscan.io/tx/0x71e030541f1e10cd866ab15fa7eb3c0645ddeccce5c782baa7eb05f8d2490613) |

## 5 总结

总体来看，除了平台手续费分配这块还比较中心化，其它部分都是由智能合约自动完成。因此，可以说整个项目还是比较去中心化。随着中心交易所FTX暴雷，未来使用去中心化交易所可以说是大势所趋，去中心化合约交易所更是兵家必争之地。GMX作为去中心合约交易的龙头，它的优势也是非常明显：

1. **去中心化**。GMX是一个去中心化的永续合约交易平台，所有资产由智能合约保管，智能合约开源，所有运营数据也是公开透明的。
2. **全额保证金**。GMX上面的所有杠杆订单都是有全额保证金的，保障用户的收益能够钢性对付，很多中心化交易所都无法做到全额保证金。
3. **市场报价去中心化**。系统报价主要由ChainLink和报价机器人组成，报价公开透明，有效避免了恶意插针等扰乱市场的行为。

它的劣势也非常明显：

1. **币种太少**。包括4种主流代币、4种稳定币，不能满足大部分用户的需求。
2. **无法做到Permissionless**。由于GMX的架构设计，无法像Uniswap那样自由添加代币，它只能预先设定好支持哪些代币，无法自由扩展代币种类。

但不可否认的是，GMX所在的赛道发展潜力巨大，未来一定会诞生超级巨头。虽然GMX目前是去中心化永续合约交易所的龙头，但是还需要升级改造，解决目前平台目前的问题，让用户能像使用中心化永续合约交易所一样去使用去中心化的永续合约交易所。
