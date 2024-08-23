//-----structs
struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;
    walletCode: Cell;
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
    maxAmount: Int;
}
struct Deps {
    manager: Address;
    profitPool: Address;
    reservePool: Address;
    usdton: Address;
    runaCoupon: Address;
}
message SetSettings {
    minDelay: Int;
    newManager: Address;
    maxAmount: Int;
}

struct Asset {
    name: String;
    poolWallet: Address;
    op_code: Int;
}

message SetAssets {
    assets:  map<Address, Asset>;
}
message SetBalances {
    balances:  map<Address, Int>;
}

//-----SUPPLY
//user interface
message SupplyMessage {
    amount: Int;
    user: Address;
    payload: Address;
}
//up interface
message Supply {
    user: Address;
    amount: Int as coins;
    payload: Address;
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
    newManager: Address;
    id: Int;
}
//up interface
message MigrationRequest {
}
message InformationRequest {
}
message InformationResponce {
    user: Address;
    position: Address;
}
message SetState {
    balances: map<Address, Int>;
}
message BuildPosition {
    user: Address;
    balances: map<Address, Int>;
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
    usdton: Address;
    runaCoupon: Address;
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
    notificationAddress: Address?;
    forwardPayload: Slice as remaining;
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
