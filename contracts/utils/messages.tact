struct PoolSettings {
    liquidationRatio: Int;
    stabilityFeeRate: Int;
    liquidatorIncentiveBps: Int;
}
struct DebtRate {
    debtAccumulatedRate: Int;
    lastAccumulationTime: Int;
}
message DepositCollateralMessage {
    user: Address;
    amount: Int as coins;
    settings: PoolSettings;
    rate: DebtRate;
    tonPriceWithHealthRate: Int as coins;
}
message WithdrawCollateralMessage {
    user: Address;
    amount: Int as coins;
    settings: PoolSettings;
    rate: DebtRate;
    tonPriceWithHealthRate: Int as coins;
}
message WithdrawUsdToncoinMessage {
    user: Address;
    amount: Int as uint64;
    settings: PoolSettings;
    rate: DebtRate;
}
message BurnUsdTONMessage {
    user: Address;
    amount: Int as uint64;
    settings: PoolSettings;
    rate: DebtRate;
    tonPriceWithHealthRate: Int as coins;
}
message DoWithdrawCollateral {
    user: Address;
    amount: Int as uint64;
}
message DoDeposit {
    user: Address;
    amount: Int as uint64;
}
message IncreaseTotalUsdTon {
    user: Address;
    amount: Int as uint64;
}
message DecreaseTotalUsdTon {
    user: Address;
    amount: Int as uint64;
}

// usdTonMaster messages

struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;
    walletCode: Cell;
}
struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}
// userPosition messages

message SetUserPositionDependecyMessage {
    usdTonAddress: Address;
    managerAddress: Address;
}
message SetPositionIdMessage {
    user: Address;
    positionId: Int;
}
message AddPositionId {
    user: Address;
}
message SetPositionAddressMessage {
    user: Address;
    position: Address;
}

// usdTonMaster messages

message MintMessage {
    user: Address;
    amount: Int as coins;
}
message BurnBurnMessage {
    user: Address;
    amount: Int as coins;
    rate: DebtRate;
    userPosition: Address;
}
message BurnBurnNotification {
    user: Address;
    amount: Int as coins;
    rate: DebtRate;
    userPosition: Address;
}
message UsdToncoinBurnedMessage {
    user: Address;
    amount: Int as coins;
    rate: DebtRate;
}
message TokenTransferFromPositionManager {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
    deps: Deps;
}
// jetton messages

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}
message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    responseAddress: Address?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}
message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    responseAddress: Address?;
}
message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    responseAddress: Address?;
}
message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}
message TokenUpdateContent {
    content: Cell?;
}
message WithdrawFeesMessage {
    to: Address;
    amount: Int as coins;
}
message SetDeps {
    managerAddress: Address;
    poolAddress: Address;
    usdTonAddress: Address;
    runecoinAddress: Address;
}
struct Deps {
    managerAddress: Address;
    poolAddress: Address;
    usdTonAddress: Address;
    runecoinAddress: Address;
}
// manager
message SetPoolSettings {
    liquidationRatio: Int;
    stabilityFeeRate: Int; // 1000000000625 = X**1.000000000627 every second = 2%/yr., look at ./math/math.tact
    liquidatorIncentiveBps: Int;
}
message UpdateTonPriceMsg {
    price: Int as coins;
}
message DepositCollateralUserMessage {
    user: Address;
    amount: Int as coins;
}
message WithdrawUsdTonUserMessage {
    user: Address;
    amount: Int as coins;
}
message BurnUsdTONUserMessage {
    user: Address;
    amount: Int as coins;
}
message WithdrawCollateralUserMessage {
    user: Address;
    amount: Int as coins;
}