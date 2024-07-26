message DepositCollateralMessage {
    user: Address;
    amount: Int as coins;
    settings: Settings;
    tonPrice: Int as coins;
}
message DepositNotification {
    user: Address;
    amount: Int as coins;
}
message MintUsdTon {
    user: Address;
    amount: Int as uint64;
    settings: Settings;
    tonPrice: Int as coins;
}
message BurnUsdTONMessage {
    user: Address;
    amount: Int as uint64;
    settings: Settings;
    tonPrice: Int as coins;
    deps: Deps;
    fee: Int as uint64;
}
message FeePayment {
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
    notificationAddress: Address?;
}
message OnMintComplete {
    amount: Int as coins;
}
message DexMessage {
    walletOwner: Address;
    amount: Int as coins;
    position: Address;
    price: Int;
}
message DexNotification {
    amount: Int as coins;
    position: Address;
}
message OnLiquidationComplete {
    amount: Int;
}
message BurnMessage {
    user: Address;
    amount: Int as coins;
    reservePool: Address;
    withdrawalAmount: Int;
    fee: Int;
    notificationAddress: Address?;
}
// пересмотреть когда выйдет новая версия
message BurnNotification {
    user: Address;
    amount: Int as coins;
    reservePool: Address;
    withdrawalAmount: Int;
    fee: Int;
    notificationAddress: Address?;
}
message PositionLiquidationInspectorMessage {
    user: Address;
}
message PositionLiquidation {
    settings: Settings;
    user: Address;
    tonPrice: Int as coins;
}
message LiquidationPool {
    position: Address;
    user: Address;
    amount: Int;
    price: Int;
}
message UsdTonBurned {
    user: Address;
    amount: Int as coins;
    withdrawalAmount: Int;
    fee: Int;
    notificationAddress: Address?;
}
message OnBurnComplete {
    ton: Int as coins;
    usdton: Int as coins;
    fee: Int;
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
    notificationAddress: Address?;
}
message TokenTransferInternalDex {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    responseAddress: Address?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
    notificationAddress: Address?;
}
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}
message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}
message TokenUpdateContent {
    content: Cell?;
}
message SetDeps {
    manager: Address;
    profitPool: Address;
    reservePool: Address;
    usdton: Address;
}
struct Deps {
    manager: Address;
    profitPool: Address;
    reservePool: Address;
    usdton: Address;
}
// manager

message SetSettings {
    reservePool: Int;
    reserveMin: Int;
    burnMin: Int;
    serviceFeePercent: Int;
    serviceFee: Int;
    liquidationRatio: Int;
}
struct Settings {
    reservePool: Int;
    reserveMin: Int;
    burnMin: Int;
    serviceFeePercent: Int;
    serviceFee: Int;
    liquidationRatio: Int;
}
message UpdateTonPriceMsg {
    price: Int as coins;
}
message DepositCollateralUserMessage {
    user: Address;
    amount: Int as coins;
}
message MintUsdTonMessage {
    user: Address;
    amount: Int as coins;
}
message BurnUsdTONUserMessage {
    user: Address;
    amount: Int as coins;
    fee: Int as uint64;
}