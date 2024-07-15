struct PoolSettings {
    liquidationRatio: Int;
    stabilityFeeRate: Int;
    liquidationFee: Int;
}
message CreateInfo {
    wallet: Address;
}
message DepositCollateralMessage {
    user: Address;
    amount: Int as coins;
    settings: PoolSettings;
    tonPriceWithHealthRate: Int as coins;
}
message WithdrawCollateralMessage {
    user: Address;
    amount: Int as coins;
    settings: PoolSettings;
    tonPriceWithHealthRate: Int as coins;
}
message MintUsdTon {
    user: Address;
    amount: Int as uint64;
    settings: PoolSettings;
    tonPriceWithHealthRate: Int as coins;
}
message BurnUsdTONMessage {
    user: Address;
    amount: Int as uint64;
    settings: PoolSettings;
    tonPriceWithHealthRate: Int as coins;
    tonPrice: Int as coins;
    userRunaCoinAddress: Address;
    deps: Deps;
}
message TestWithdrawal {
}
message FeePayment {
    amount: Int as uint64;
}

message GetUserRunacoinAddress{
    user: Address;
    amount: Int as uint64;
}

message GetUserRunacoinAddressResponse {
    userRunaCoinAddress: Address;
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
message DexMessage {
    user: Address;
    amount: Int as coins;
}
message DexNotification {
    user: Address;
    amount: Int as coins;
}
message BurnMessage {
    user: Address;
    amount: Int as coins;
    userPosition: Address;
}
message BurnNotification {
    user: Address;
    amount: Int as coins;
    userPosition: Address;
}
message UsdTonBurned {
    user: Address;
    amount: Int as coins;
}
message RunecoinBurned {
    user: Address;
    amount: Int as coins;
}
message PositionLiquidationInspectorMessage {
    user: Address;
}
message PositionLiquidation {
    settings: PoolSettings;
    user: Address;
    tonPriceWithHealthRate: Int as coins;
    tonPrice: Int as coins;
    runePrice: Int as coins;
}
message RuneTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    usdton: Address;
    manager: Address;
    pool: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}
message RuneTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    responseAddress: Address?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
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
    liquidationFee: Int;
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
}
message WithdrawCollateralUserMessage {
    user: Address;
    amount: Int as coins;
}