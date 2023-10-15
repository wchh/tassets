# THENA 协议分析

## 1. 概述

    [THENA](https://thena.fi/)主要是解决AMM流动性激励问题给出的解决方案。在Solidly基础上, 改进了费用分配、流动性挖矿和启动流动性等问题, 保留了时间加权平均价格（TWAP）等受欢迎的功能。

## 2. 合约地址

| Contract Name      | Info                                  | Address                                          | is Proxy? |
| ------------------ | ------------------------------------- | ------------------------------------------------ | --------- |
| PermissionRegistry | handle access to Thena ecosystem      | 0xe3Db58904B868eFDECD374Ed4f7b75e2A0f3e0Eb       | FALSE     |
|                    |                                       |                                                  |           |
| BribeFactory       | Create bribes contracts               | 0xD50CEAB3071c61c85D04bDD65Feb12FEe7C91375       | TRUE      |
| GaugeFactoryV2     | Create Gauges for s/vAMM LP           | 0x2c788FE40A417612cb654b14a944cd549B5BF130       | TRUE      |
| GaugeFactoryV2_CL  | Create Gauges and FeeVault for CL LPs | 0xb065E4F5D71a55a4e4FC2BD871B36E33053cabEB       | TRUE      |
| PairFactory        | Create sAMM and vAMM pairs            | 0xAFD89d21BdB66d00817d4153E055830B1c2B3970       | TRUE      |
| AlgebraFactory     | Create Con. Liq. LP                   | 0x306F06C147f064A010530292A1EB6737c3e378e4       | FALSE     |
|                    |                                       |                                                  |           |
| VoterV3            | Voter contract                        | 0x3A1D0952809F4948d15EBCe8d345962A282C4fCb       | TRUE      |
|                    |                                       |                                                  |           |
| Minter             | Minter of $THE token                  | 0x86069FEb223EE303085a1A505892c9D4BdBEE996       | TRUE      |
|                    |                                       |                                                  |           |
| Thena              | Thena ERC20 token                     | 0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11       | FALSE     |
| veThena            | Thena Governance veNFT                | 0xfBBF371C9B0B994EebFcC977CEf603F7f31c070D       | FALSE     |
| veArtProxy         | Art proxy for veNFT                   | 0xb2B37c4221DaBFFF5B34883e95D88d498F03E516       | TRUE      |
| Thenian            | theNFT                                | 0x2Af749593978CB79Ed11B9959cD82FD128BA4f8d       | FALSE     |
|                    |                                       |                                                  |           |
| Royalties          | theNFT sales royalties                | 0xBB2caf56BF29379e329dFED453cbe60E4d913882       | FALSE     |
| theNFT Staking     | theNFT staking contract               | 0xe58E64fb76e3C3246C34Ee596fB8Da300b5Adfbb       | FALSE     |
| RewardDistributor  | Rebase distributor for veNFT          | 0xC6bE40f6a14D4C2F3AAdf9b02294b003e3967779 (new) | FALSE     |
|                    |                                       |                                                  |           |
| AlgebraRouter      | Router for Conc. Liq. Swaps           | 0x327Dd3208f0bCF590A66110aCB6e5e6941A4EfA0       | FALSE     |
| RouterV2           | Router for Solidly LP                 | 0xd4ae6eca985340dd434d38f470accce4dc78d109       | FALSE     |
| UniProxy           | Proxy to interface with Gamma         | 0xF75c017E3b023a593505e281b565ED35Cc120efa (new) | FALSE     |
|                    |                                       |                                                  |           |
| PairAPI            | help read LP info                     | 0xE89080cEb6CAEb9Eba5a0d4Aa13686eFcB78A32E       | TRUE      |
| RewardsAPI         | help read bribe info                  | 0x0b6CFf48836Eea83795Ab8b9a04b1b4654d96c46 (new) | TRUE      |
| veNFT API          | help read veNFT info                  | 0xe09E1aA537382c82245C04536E90fDB7121283b0 (new) | TRUE      |

## 3. 分析

### 3.1 添加流动性

    THENA的流动性池结合了集中流动性（CL）、动态费用结构和与GAMMA和Algebra的无缝集成，为用户提供了更好的体验和资本效率。集中流动性是一种技术，让用户可以指定一个价格区间，只在该区间内提供流动性，从而提高交易深度和收益。GAMMA和Algebra是两个DeFi项目，分别提供了流动性管理和风险控制的解决方案。

    THENA的最新创新是FUSION池，它是与GAMMA和Algebra合作开发的一种集中流动性池。FUSION池简化了集中流动性的管理，降低了暂时损失（IL）的风险，适应了市场波动，并优化了动态费用。

    Algebra是一种基于集中流动性的池技术，让LP可以通过自定义价格区间来提供流动性，并支持高级的做市操作。Algebra为FUSION提供了底层技术。

    GAMMA是一种流动性管理协议，可以根据市场波动、流动性和交易量自动调整LP的价格区间，以最大化收益并减少无常损失。GAMMA与FUSION无缝集成，为LP提供了便捷的服务和经过验证的做市服务。

    FUSION池采用了基础费用和动态费用的结构，让协议合作伙伴可以灵活地设置和修改费用水平，而不需要重新部署流动性。基础费用是固定的组成部分，可以由核心团队自由设定。动态费用是根据市场波动自动调整的组成部分，以适应不同的市场情况。

    除了FUSION池外，THENA还提供了经典的vAMM和sAMM池。

    

    Thena协议合约为流动性池提供了2个接口合约:

- UniProxy: 用来为FUSION池添加流动性
  
  ```
  UniProxy.deposit->Hypervisor.deposit->AlgebraPool.mint
  ```
  
      这里, Hypervisor是一个FUSION lp池. Hypervisor合约也是一个的ERC20合约, 在Hypervisor.deposit函数最后, 会mint Hypervisor lp代币给到调用者, lp代币数量代表此次添加的流动性数量. AlgebraPool合约用于管理流动性池, 包括流动性的提供和销毁, 以及交换以及闪电贷. AlgebraPool.mint就是提供流动性的函数.

- RouterV2: 用来为V1的stable池(sAMM pool)或volatile池(vAMM pool)
  
  ```
  RouterV2.addLiquidity->Pair.mint
  ```
  
      RouterV2.addLiquidity用于添加流动性. 如果没有对应的Pair合约, 会创建相应的Pair合约, Pair合约会调用mint, 创建lp代币给到调用者. Pair合约包含了Hypervisor和AlgebraPool的功能, 既是ERC20代币合约, 也是用于swap操作的流动性池.
  
      用户可以把代币添加流动性获取的lp代币抵押到Gauge中, 获得额外的THE 奖励.

### 3.2 投票

    通过锁定THE代币获取veTHE代币. THE是Thena的主代币, veTHE是Thena的治理代币, 也可以认为是DAO代币. veTHE是一种NFT, 用户锁定THE代币, 可以获得veTHE, 锁定THE的数量即为veTHE的投票权重, 但是投票权重随着时间递减.

    拥有veTHE的用户可以对lp pool进行投票, 投票是通过gauge进行的, 因为gauge和lp pool是一对一的关系. 每个veTHE都有不同的tokenId, 也有不同的投票权重.

    投票的操作是在VoterV3合约进行的.

    投票是把用户持有的的veThe代币, 抵押到Gauge中. 每个Gauge对应一个lp池. 每次可以对多个池投票, 每个池子不同的权重比例, 比如vote(tokenId, [pool1, pool2, pool3], [20, 30, 50]), 表示tokenId的代币同时给三个池子投票, 每个池子的权重分别是20%, 30%和50%, 假设用户的tokenId抵押了100个THE代币, 那么每个池子的票数分别是20, 30和50. 但是同一个池子,同一个tokenId不能投2次. 投票的用户在投票周期结束后, 有3种奖励, 一种是lp pool的交易费, 一种是贿赂, 还有一种是THE的排放.

```
VoterV3.vote->Bribe.deposit
```

    VoterV3合约管理了所有gauges和bribes. 所以投票, 取消投票, 以及获取奖励都从VoterV3合约进行. VoterV3.vote会调用相应的gauge的bribe的deposit函数. 把veThe的tokenId抵押在bribe中. bribe负责结算lp 池的交易费和贿赂费用.

### 3.3 创建Gauge

    如上所述, 创建Gauge和Bribe都是在VoterV3合约中进行的. createGauge创建gauge时, 要提供lp pool的地址作为参数. 也就是一个gauge对应一个lp pool. 还要提供一个表示gauge的类型参数, 0表示普通式, 1表示CL.  createGauge内部会调用2次createBribe, 创建两个Bribe合约, 一个用于管理lp pool的交易费, 一个用于lp pool的贿赂. createGauge会调用IGaugeFactory.createGaugeV2接口. 根据gauge类型参数, 使用GaugeFactoryV2或GaugeFactoryV2_Cl实例化IGaugeFactory接口. 其中GaugeFactoryV2_Cl和GaugeFactoryV2区别在于创建GaugeV2_Cl还是GaugeV2, GaugeV2_CL合约在构造的时候多了个CLFeesVault合约地址, 通过名字可知, CLFeeVault是一个集中流动性交易费的资金池. 在Hypervisor合约里, 有个feeRecipient成员, 是个address类型, 用于保存Hypervisor提供流动性费用奖励, 这个地址其实就是CLFeesVault的合约地址. 

### 3.4 获取奖励

    Thena主代币THE每周排放会根据每个lp pool的投票数量进行奖励. gauge会把获取的THE根据lp抵押的lp代币数量进行奖励. THE只会奖励lp, 不会对veTHE投票进行奖励. 

    lp用户通过gauge的getReward函数获取THE排放奖励.

    而veTHE投票获取的奖励是pool的交易费和贿赂费用. 

    上面提到过, 交易费和会路费是在Bribe合约计算的. 用户可以根据VoteV3中的poolVote获取自己tokenId对应的pool, 然后通过gauges获取pool对应的gauge, 然后internal_bribes获取gauge对应的internal_bribes, internal_bribe用来计算交易费的; 通过external_bribes获取gauge对应的external_bribes, external_bribe用来计算贿赂的. 同过Bribe合约的getReward获取不同的tokenId和不同tokens的奖励.

### 3.5 锁定THE

    锁定THE代币, 获得veTHE代币. 通过合约VotingEscrow.create_lock函数, 输入锁定THE数量和周期, 既可获得veTHE NFT tokenId.

### 3.6 Swap

    Thena支持的交易类型有: 

- market: 就是现价交易. 又分为:
  
  - MAIN: Thena默认使用的, 应该是直接调用OpenOcean API进行的, 利用OpenOcean先进的路由技术. 
  
  - FUSION: 应该是在FUSION池中进行的. 通过Hypervisor.pool调用的是AlgebraPool.swap实现的.
  
  - V1: 应该是在V1池进行的. 通过RouterV2合约的swapExactTokensForTokensSimple和swapExactTokensForTokens进行的, 前者直接在在对应的池子, 通过Pair.swap实现交易. 后者需要提供会提供一个 route[] 类型的参数，这个参数是一个包含了多个路由的数组. 每个路由是一个结构体，包含了交易的输入代币地址（from）、输出代币地址（to）和是否稳定（stable）三个字段。这个路由数组描述了代币交易的路径，例如，如果用户想要通过一个中间代币从代币 A 兑换到代币 B，他们可以提供一个包含两个路由的数组，第一个路由的 from 是代币 A，to 是中间代币，第二个路由的 from 是中间代币，to 是代币 B。  
    
    这种设计使得用户可以灵活地选择交易路径，可以通过中间代币进行交易，也可以直接进行交易。同时，由于路由数组是由用户提供的，所以用户可以根据市场情况自由选择最优的交易路径。

- limit: THENA集成了由Orbs提供支持的dLIMIT协议，以去中心化的方式将这种订单类型带入DeFi。dLIMIT协议为DEXs确保了限价单以最佳价格和公平费用执行，以去中心化和可靠的方式。

- twap: TWAP（时间加权平均价格）是CeFi中的一种常用订单类型，它将一个大订单分割成多个小订单，并按照一定的时间间隔执行。TWAP订单的主要目的是减少订单对价格的影响。如果用户想要实施定投策略（DCA），并按照一定的时间表购买某种代币（例如每月一次），TWAP订单也很有用。当订单规模与可用流动性相比较大，或者当用户预期一个高波动性且没有明显趋势的时期时，TWAP是最合适的。THENA集成了由Orbs支持的dTWAP协议，以去中心化的方式将这种订单类型引入DeFi。

- Cross-chain:THENA的跨链交换由Axelar和Squid Router提供支持，实现了不同区块链之间的无缝和安全的通信和交换。Axelar是一个强大的区块链“互联网基础设施”，Squid Router是一个应用层工具。它们结合起来，可以让用户用一键完成跨链资产转移和交换。THENA的跨链交换，借助Axelar和Squid Router的能力，保证了效率和安全。用户可以在多个区块链之间自由地交换资产，或者连接不同的区块链生态系统。

### 3.7 外围合约

- BeefyVaultV7: [地址](https://bscscan.com/address/0x77c9a64c88ad5e5467b53e20e66ad2f8800bbf3d#code), [代码](https://github.com/beefyfinance/beefy-contracts)

- AlgebraPool: [地址](https://bscscan.com/address/0x1b9a1120a17617D8eC4dC80B921A9A1C50Caef7d#code), [代码](https://github.com/cryptoalgebra/Algebra)

- StrategyThenaGamma: [地址](https://bscscan.com/address/0x74f45020ea8b760ab558f82f5aae5c772403dc27#code), 没有开源

- Hypervisor: [地址](https://bscscan.com/address/0x5eeca990e9b7489665f4b57d27d92c78bc2afbf2#code), [代码](https://github.com/GammaStrategies/hypervisor)

## 4. 部署

    Thena合约提供了部署脚本, 但是许多地址都是硬编码的. 测试代码都是在主链跑的, 需要修改后才能再本地链或者测试链上跑起来.

## 
