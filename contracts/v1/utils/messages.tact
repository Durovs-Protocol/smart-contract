//-----structs
struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;
    walletCode: Cell;
}

struct SupplyTimestamp {
    info: map<Int , Int >;
}
struct WithdrawTransactionInfo {
    amount: Int;
    master: Address;
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

struct Settings {
    minDelay: Int;
    newManager: Address;
    maxExecutionTime: Int;
    couponRate: Int;
}
struct Deps {
    manager: Address;
    profitPool: Address;
    reservePool: Address;
    stable: Address;
    coupon: Address;
}
message SetSettings {
    minDelay: Int;
    newManager: Address;
    maxExecutionTime: Int;
    couponRate: Int;
}

struct Asset {
    name: String;
    poolWallet: Address;
    master: Address;
}

message SetAssets {
    assets:  map<Address, Asset>;
}
message SetBalances {
    balances:  map<Address, Int>;
}
message SetRates {
     rates: map<Address, Int>;
}

//-----SUPPLY
//user interface
message SupplyMessage {
    amount: Int;
    user: Address;
    master: Address;
    userWallet: Address;
}
//up interface
message Supply {
    user: Address;
    amount: Int as coins;
    master: Address;
    userWallet: Address;
}

message SupplyNotification {
    user: Address;
    amount: Int as coins;
}

struct ManagerState {
    totalSupplyed: Int;
    totalMinted: Int;
}

//-----MINT
//user interface
message MintStableMessage {
    amount: Int as coins;

}
//up interface
message MintStable {
    user: Address;
    amount: Int as uint64;
    rates: map<Address, Int>;
}

message OnMintComplete {
    amount: Int as coins;
}
//-----BURN
//user interface
message BurnStableMessage {
    amount: Int as coins;
    fee: Int as uint64;
}
//up interface
message BurnStable {
    user: Address;
    amount: Int as uint64;
    rates: map<Address, Int>;
}
message BurnNotification {
    user: Address;
    amount: Int as coins;
    notificationAddress: Address?;
}
//-----WITHDRAW
//user interface
message WithdrawMessage {
    amount: Int as coins;
    master: Address;
}
// message WithdrawNotification  {
//     amount: Int as coins;
//     payload: Address;
//     name: String;

// }
//up interface
message Withdraw {
    user: Address;
    amount: Int as coins;
    master: Address;
    minDelay: Int;
    maxExecutionTime: Int;
    pool: Address;
    rates: map<Address, Int>;

}
message WithdrawResponce {
    amount: Int as coins;
    master: Address;
}
message WithdrawRequest {
    amount: Int as coins;
    user: Address;
    master: Address;
    queryId: Int;

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
    id: Int;
}
//up interface
message MigrationRequest {
        newManager: Address;
}
message InformationRequest {
}
message PoolMigrationRequest {
    amount: Int;
    queryId: Int;
    newPool: Address;
    wallet:  Address;
}
message InformationResponce {
    user: Address;
    position: Address;
}
message SetState {
    balances: map<Address, Int>;
    supplyTimestamps: map<Address, SupplyTimestamp>;
    updatedTimestamps: SupplyTimestamp?;
    withdrawState: map<Int , WithdrawTransactionInfo>;
    lastWithdrawalRequest: Int;
    wallets: map<Address, Address>;
}

message BuildPosition {
    user: Address;
    balances: map<Address, Int>;
    supplyTimestamps: map<Address, SupplyTimestamp>;
    updatedTimestamps: SupplyTimestamp?;
    withdrawState: map<Int , WithdrawTransactionInfo>;
    lastWithdrawalRequest: Int;
    wallets: map<Address, Address>;
}
message BuildNewPosition {
    user: Address;
    balances: map<Address, Int>;
    supplyTimestamps: map<Address, SupplyTimestamp>;
    updatedTimestamps: SupplyTimestamp?;
    withdrawState: map<Int , WithdrawTransactionInfo>;
    lastWithdrawalRequest: Int;
}

message OnMigrationComplete {
    
}
// message DeleteManager {
    
// }
//-----INCREASE POSITION ID & CREATING ADDRESS KEEPER CONTRACT
message AddPositionId {
    user: Address;
}
message SetAddress {
    user: Address;
    position: Address;
}
message SetId {
    id: Int;
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
    stable: Address;
    coupon: Address;
}


message SetTransactionInfo {
    amount: Int;
    user:  Address;
    master:  Address;
    queryId:  Int as uint64;
    position: Address;
}
message TonTransfer {
    queryId: Int as uint64;
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
    notificationAddress: Address?;
    forwardPayload: Slice as remaining;
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
message TokenUpdateContent {
    content: Cell;
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
    fee: Int;
    notificationAddress: Address?;
}
message OnBurnComplete {
    amount: Int as coins;
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
    notificationAddress: Address?;
    forwardPayload: Slice as remaining;
}
message DexNotification {
    amount: Int as coins;
    position: Address;
}

message TonBalanceMigration {

}


message AccrualMessage {
    user: Address;
    amount: Int as coins;
    notificationAddress: Address?;
}
message OnAccrualComplete {
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
//-----NEW FEATURES-----
message BuyCouponsMessage {
    amount: Int;
} 
message BuyCoupons {
    amount: Int;
    couponsAmount: Int;
} 
message BurnForCoupons {
    amount: Int;
    couponsAmount: Int;
    user: Address;
} 

message ManageCoupons {
    type: String;
    amount: Int;
}

message MintCoupons {
    user: Address;
    amount: Int;
}
message MintCouponNotification {
    user: Address;
    amount: Int;
}

message CouponExchangeRequest {
    amount: Int;
    user: Address;
}

message SellCoupons {
    amount: Int;
}
message CouponExchangeNotification {
    amount: Int;
    user: Address;
}
message OnCouponBurnComplete {
    amount: Int;
    user: Address;
}
message BurnForCouponsNotification {
    amount: Int;
    user: Address;
    couponsAmount: Int;

}
