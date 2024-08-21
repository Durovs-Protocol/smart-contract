//-----structs
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
struct PositionState {
    collateral: Int as coins;
    debt: Int as uint64;
}
struct Message {
    timestamp: Int as uint64;
    message: String;
}
struct Settings {
    reserveRatio: Int;
    reserveMin: Int;
    burnMin: Int;
    serviceFeePercent: Int;
    serviceFee: Int;
    liquidationRatio: Int;
}
struct Deps {
    manager: Address;
    profitPool: Address;
    reservePool: Address;
    usdton: Address;
    runaCoupon: Address;
}
message SetSettings {
    reserveRatio: Int;
    reserveMin: Int;
    burnMin: Int;
    serviceFeePercent: Int;
    serviceFee: Int;
    liquidationRatio: Int;
}

//-----SUPPLY
//user interface
message SupplyMessage {
    amount: Int as coins;
}
//up interface
message Supply {
    user: Address;
    amount: Int as coins;
    settings: Settings;
    tonPrice: Int as coins;
}
message SupplyNotification {
    user: Address;
    amount: Int as coins;
}
//-----MINT
//user interface
message MintUsdTonMessage {
    amount: Int as coins;
}
//up interface
message MintUsdTon {
    user: Address;
    amount: Int as uint64;
    settings: Settings;
    tonPrice: Int as coins;
}

message OnMintComplete {
    amount: Int as coins;
}
//-----BURN
//user interface
message BurnUsdTonMessage {
    amount: Int as coins;
    fee: Int as uint64;
}
//up interface
message BurnUsdTon {
    user: Address;
    amount: Int as uint64;
    settings: Settings;
    tonPrice: Int as coins;
    deps: Deps;
    fee: Int as uint64;
}
message BurnNotification {
    user: Address;
    amount: Int as coins;
    withdrawalAmount: Int;
    fee: Int;
    notificationAddress: Address?;
}
//-----WITHDRAW
//user interface
message WithdrawMessage {
    amount: Int as coins;
}
//up interface
message Withdraw {
    user: Address;
    amount: Int as coins;
    settings: Settings;
    tonPrice: Int;
}
message WithdrawResponce {
    amount: Int as coins;
}
message WithdrawRequest {
    amount: Int as coins;
    user: Address;
}
//-----LIQUIDATION
//user interface
message PositionLiquidationMessage {
    user: Address;
}
//up interface
message PositionLiquidation {
    settings: Settings;
    user: Address;
    tonPrice: Int as coins;
}
message DoLiquidation {
    position: Address;
    user: Address;
    amount: Int;
    price: Int;
}

//-----MIGRATION
//user interface
message Migration {
    newManager: Address;
    id: Int;
}
//up interface
message MigrationRequest {
    owner: Address;
    manager: Address;
    reservePool: Address;
    profitPool: Address;
    usdton: Address;
}

message SetState {
    collateral: Int;
    debt: Int;
    positionAddress: Address;
}
message BuildPosition {
    user: Address;
    owner: Address;
    positionAddress: Address;
    collateral: Int;
    debt: Int;
    manager: Address;
    reservePool: Address;
    profitPool: Address;
    usdton: Address;
}

message OnMigrationComplete {
    
}
message DeleteManager {
    
}
//-----INCREASE POSITION ID & CREATING ADDRESS KEEPER CONTRACT
message AddPositionId {
    user: Address;
}
message SetAddress {
    user: Address;
    position: Address;
}
//for safety check in up
message SetPositionAddress {
    address: Address;
}

//-----feedBack handlers
message FeePayment {
    amount: Int as uint64;
    user: Address;
}

//-----SETTINGS
message UpdateTonPriceMsg {
    price: Int as coins;
}
message SetDeps {
    manager: Address;
    profitPool: Address;
    reservePool: Address;
    usdton: Address;
    runaCoupon: Address;
}



//-----JETTON interface
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
//-----RUNA USDTON interface
message MintRequest {
    user: Address;
    amount: Int as coins;
    notificationAddress: Address?;
}
//burn/liquidation
message BurnRequest {
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
//-----DEX IMITATION
message DexMessage {
    walletOwner: Address;
    amount: Int as coins;
    position: Address;
    price: Int;
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
message DexNotification {
    amount: Int as coins;
    position: Address;
}


//-----NEW FEATURES(not complete)-----
message MintCoupon {
    user: Address;
    amount: Int as coins;
    notificationAddress: Address;
}
message CreateCoupons {
}
message DeleteCoupons {
}
message BuyCoupons {
    amount: Int;
}
message AccrualMessage {
    user: Address;
    amount: Int as coins;
    notificationAddress: Address?;
}
message OnAccrualComplete {
    amount: Int as coins;
}
message OnMintCouponsComplete {
    amount: Int as coins;
}
message CorrectRate {
}
message GetAccrual {
}
message AccrualJetton {
    total: Int;
    jettonAmount: Int;
}
