# TideAssets 项目第一期需求分析说明书

## 代币发行

- TDT，TCA。以MakerDAO为基础，实现我们的发行逻辑。主要是资金池的管理，和其他合约（三大核心服务）的关系。

- tsUSD 稳定币的发行：以maker DAI的为参考发行我们自己的稳定币。

- TTL, TTS, TTP管理代币的发行：分别参考Radiant, Thena和Gmx以及我们的TDT，TCA的发行方式。管理代币和Dao的策略，以及奖励策略， 我们要统一，取长补短。

## 三大服务

### tLend 借贷

参考 Radiant capital 的实现。

radiant 核心业务：

- 存款 用户存入Token后，会得到rToken；燃烧rToken后会得到Token。 Token和rToken是1:1兑换的，用户的rToken会随着时间增长。
  
  ```
    rToken数量 = 当前 rToken数量 X 时间 X 存款利率
  ```

- 取款 用户燃烧rToken, 换取等量token 

- 借款 持有rToken的用户可以借其他token，获取debtToken和token

- 还款 燃烧debtToken, 还入token。 涉及借款利率的问题

- loop 就是不断地存款，借款，并把存款总额的5% zap操作

- zap 就是把资产转换为eth或RAND，抵押到balancer pool， 赚取流动性奖励和RAND排放奖励

- unzap

- 领取手续费奖励

- 领取RAND增发奖励

- 跨链转账RAND, 从A链发起转账，合约burn 掉RAND token, layerZero把金额发给B链，B链合约mint 出RAND token。

- 跨链借贷，在Arbti链或Bsc链存款（抵押），可以在任何EVM 兼容链借款。通过layerzero和stargate实现。

- 私有池 贿赂市场

### tSwap AMM 现货

参考 thena, thena已经实现了limit order。

thena 技术特点：

- swap: 利用OpenOcenn先进的路由技术，获得交易最佳价格。
  
  ```
  OpenOcean 是一个领先的 Web3 DEX 聚合器，
  它可以提供跨 27+ 个区块链的最佳交换价格，同时享受低费用。
  OpenOcean 提供了一系列创新的产品，
  让用户可以使用高效的流动性池、API 和 SDK、限价单、跨链交换、永续期货
  和 ETH 液态质押聚合器等功能。
  OpenOcean 还与多个市场制造者、去中心化交易所、钱包和桥接协议合作，
  构建了一个开放的去中心化金融生态系统
  ```

- limit: THENA 已经集成了由 Orbs 提供的 dLIMIT 协议。

- twap: TWAP（时间加权平均价格）是一个在 CeFi 中常用的订单类型，它将一个订单分割成较小的交易规模，并在规律的时间间隔内执行。TWAP 订单的主要目的是减少订单对市场的价格影响。它也可以用于实现定投策略（DCA），并按照一定的时间表（比如每月一次）购买某种代币。THENA 已经集成了由 Orbs 提供的 dTWAP 协议

- cross-chain: THENA 的跨链交换的核心是 Axelar 的基础设施和 Squid Router 的应用层的创新结合。Axelar 作为一个强大的区块链“互联网基础设施”，确保了无缝和安全的跨链通信。同时，Squid Router 利用 Axelar 的实力，实现了一键高效地在不同链之间转移和交换资产。这种联盟开启了一个新的流动性时代，使用户能够轻松地在众多区块链之间交换资产，所有这些都在 THENA 的安全和流畅的保护伞下进行

- 贿赂市场 cure 

- 流动性池：FUSION 池可以提供最佳的定价和费用组合和最大化的收益，适合任何类型的资产对。创新池结合了集中流动性、动态费用结构和与 GAMMA 和 Algebra 的无缝集成。

- symmio.io支持永续

### tPerp AMM 永续

参考 gmx

gmx v2 核心业务：

- 开仓 用户创建市价单或者限价单开仓， 合约保存订单数据

- 爆仓

- 清算， 清算手续费由管理员设定

- 现货交易， 市价和限价

- GMX 抵押获取sbfGMX, 可以获取GMX,esGMX, weth 等奖励

- GLP(GM)抵押获取 fsGLP，可以获得weth和esGMX 奖励

- esGMX 不能流通，抵押 1 年可以换取GMX

## 我们的亮点功能

- TDT：真实价格=资金池总价值/总流通量
  
  - 当市场价格高于真实价格 2 倍的时候，以市场价格发行TDT，让市场价格回落到真实价格的1倍左右。发行资金放入资金池，这时真实价格会增长。
  
  - 当市场价格低于真实价格 50% 的时候，资金池回购TDT，并销毁。（如果资金池资金不足以回购，怎么办？）
  
  - 通过空投和其他核心服务收益，让真实价格升值。

- TCA：一揽子tokens(USDT, USDC, Dai, BTC, ETH等) ETF 指数基金。
  
  - 用户购买发行和销毁，实时价格按照资金池价值总量/总流通数量
  
  - 通过核心服务收益，挖矿收益等，让价值升值。

- 打通各种服务，也就是TDT, TCA, tLend，tSwap和tPerp相互支持，增加流动性。
  
  - tSwap和tPerp的资金池中部分资产可以放到tLend中，获得收益。
  
  - 当某个池子的某种token数量低于预设的阈值的时候，可以从其他池子中交换
  
  - 当整个系统的某种token数量低于阈值的时候，通过TDT的外部接口，购买部分token

- tSwap实现限价单，可以完成策略交易。kyberswap.com

- tPerp实现价格对冲，减少TDT，TCA价格波动

- 风险控制： 单次不超过 10%， 32 个数组， 记录最近32区块转出的数量，转出和 > 20%， 转出失败。

- 代币IDO: 
  
  - 我们的代币项目初始发行都在tSwap中进行。
  
  - 功能类似pancakeswap的 IFO。
  
  - 将来可以支持用户的IDO。
  
  - 每种代币初次发行数量 100 万。
  
  - 代币价格为 1 USD.
  
  - 可以使用TDT合约认可的代币参与(USDT, USDC, DAI，ETH, BTC等)。
  
  - 参与后合约会兑换成TDT/TCA 锁定在资金池。
  
  - 用户需要锁定相应数量的 dlp（TDT/TCA） 才能认购新代币的发行，比如想认购 10 万，必须抵押 10w 的TDT/TCA dlp。
  
  - 根据出资的份额获取相应代币数量
  
  - 获得的veToken，将在 6 个月内线性解锁。
  
  - IDO结束后，合约将IDO获得的TDT(TCA), 组成lp (token/TDT)为市场提供流动性，并锁仓 6 个月。

## web

1. 三个合约服务三个网站，比如tlend.io, tswap.io, tperp.io，实现各自的核心服务功能：
   
   1. 连接钱包：获取地址和签名交易
   
   2. 完成借贷，交易等核心业务操作
   
   3. dao建议和投票 （使用snapshot）
   
   4. 贿赂市场
   
   5. 清算收益

2. 主页面引用三个网站；主页面显示TDT，TCA各种信息，比如：
   
   1. 发行量
   
   2. 流通量（+销毁数量）
   
   3. 下个发行周期
   
   4. 实时价格（真实价格）
   
   5. 资金池信息：token 列表和数量
   
   6. 额外收益信息
   
   7. 价格曲线（外部价格）
   
   8. 购买TDT, TCA

## App

1. 钱包功能 （可以导入已有钱包）

2. web 上已有的功能

**注意：app 功能建议不做为第一个版本实现的硬性要求，因为总体工作量较大，以实现核心功能和web页面为主**

## 后端

1. rpc 转发

2. rpc 合并和拆解

3. 保存某些用户数据

## 跨链

1. 在不同链上发行代币如何操作

2. 如何实现跨链服务，多条链当做一条

3. 不同的方式， 选取一种。layerzero

## 预言机

- tSwap和tPerp的外部价格使用chainlink获取.

- 同时也会参考tSwap的价格。

- 比如TDT的市价，参考tSwap的价格和通过chainlink获取外部交易所价格，然后加权平均得出

- 类似ETH, BTC等价格主要参考chainlink 获取。
