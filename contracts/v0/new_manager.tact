import "@stdlib/deploy";
import "@stdlib/ownable";
import "./new_up.tact";
import "../utils/messages.tact";


contract NewManager with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    assets:  map<Address, Asset>;
    balances: map<Address, Int>;

    settings: Settings;
    owner: Address;
    lastPositionId: Int = 0;
    oldManager: Address;
    version: String = "1";
    rates: map<Address, Int>;

    init(owner: Address, oldManager: Address) {
        require(owner == sender(), "Durov Protocol: no access to init manager");
        self.owner = sender();
        self.settings = Settings{
            minDelay: 0,
            newManager: newAddress(0, 0),
            maxAmount: 0,
            maxExecutionTime: 0,
        };
        self.deps = Deps{
            manager: newAddress(0, 0),
            profitPool: newAddress(0, 0),
            reservePool: newAddress(0, 0),
            usdton: newAddress(0, 0),
            runaCoupon: newAddress(0, 0)
        };

        self.assets = emptyMap();
        self.balances = emptyMap();
        self.oldManager = oldManager;
        self.rates = emptyMap();
    }

    //=============================================================================
    // Set Deps
    //=============================================================================
    receive(msg: SetDeps) {
        self.requireOwner();
        self.deps = Deps{
            manager: msg.manager,
            profitPool: msg.profitPool,
            reservePool: msg.reservePool,
            usdton: msg.usdton,
            runaCoupon: msg.runaCoupon
        };
        self.reply("Durov Protocol: new manager's dependencies set".asComment());
    }


    //=============================================================================
    // Set Settings
    //=============================================================================
    receive(msg: SetSettings) {
        self.requireOwner();
        self.settings = Settings{
            minDelay: msg.minDelay,
            newManager: msg.newManager,
            maxAmount: msg.maxAmount,
            maxExecutionTime: msg.maxExecutionTime,

        };
        self.reply("Durov Protocol: Settings have been updated".asComment());
    }
    receive(msg: SetAssets) {
        self.requireOwner();
        self.assets = msg.assets;
        self.reply("Durov Protocol: new manager assets set".asComment());
    }
    receive(msg: SetBalances) {
        self.requireOwner();
        self.balances = msg.balances;
        self.reply("Durov Protocol: new manager balances template set".asComment());
    }

    //=============================================================================
    // User actions
    //=============================================================================

    receive(msg: SupplyMessage) {
        let ctx: Context = context();
        require(sender() == self.deps.reservePool, "Durov Protocol: Insufficient TONs sent");
        let valueToSendForward: Int = ctx.value - (self.MinTonForStorage + self.GasConsumption);
        let init: StateInit = initOf NewUp(msg.user,
            self.deps.manager,
        );
        let userPosition: Address = contractAddress(init);

        send(SendParameters {
                to: userPosition,
                value: valueToSendForward,
                mode: SendBounceIfActionFail,
                bounce: true,
                body: Supply{
                    user: msg.user,
                    amount: msg.amount,
                    payload: msg.payload,
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    bounced(msg: bounced<Supply>) {
        self.bouncedHandler("Durov Protocol: Error in supply.");
    }

    receive(msg: AddPositionId) {
        self.lastPositionId = self.lastPositionId + 1;
        let init: StateInit = initOf NewPositionKeeper(self.lastPositionId, myAddress());
        let positionAddress: Address = contractAddress(init);
        send(SendParameters{
                to: positionAddress,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: true,
                body: SetAddress{user: msg.user, position: sender()}.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }


    /*04 | withdraw TON */
    receive(msg: WithdrawMessage) {
        send(SendParameters{
                to: self._userPositionAddress(sender()),
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: Withdraw{
                    user: sender(),
                    amount: msg.amount,
                    master: msg.master,
                    minDelay: self.settings.minDelay,
                    maxExecutionTime: self.settings.maxExecutionTime,
                    pool: self.deps.reservePool
                }.toCell()
            }
        );
    }

    bounced(msg: bounced<Withdraw>){
        self.bouncedHandler("Durov Protocol: Error in withdrawal");
    }

    /* ==Migration== */
    receive(msg: BuildPosition) {
        require(sender() == self.oldManager, "Durov Protocol: Unable to create a new position");
        let init: StateInit = initOf NewUp(msg.user, self.deps.manager);
        let newUserPosition: Address = contractAddress(init);

        send(SendParameters{
                to: newUserPosition,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: SetState{
                    balances: msg.balances,
                    supplyTimestamps: msg.supplyTimestamps,
                    updatedTimestamps: msg.updatedTimestamps,
                    withdrawState: msg.withdrawState,
                    lastWithdrawalRequest: msg.lastWithdrawalRequest
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }
    /* ==Migration== */
    receive(msg: Migration){
        self.requireOwner();
        let jettonAmount: Int = 0;
        let init: StateInit = initOf NewPositionKeeper(msg.id, myAddress());
        let positionAddress: Address = contractAddress(init);
        send(SendParameters{
                to: positionAddress,
                value: 0,
                mode: SendBounceIfActionFail,
                bounce: true,
                body: MigrationRequest{
                }.toCell()
            }
        );
    }

    receive(msg: OnMigrationComplete){
        send(SendParameters{to: self.owner, bounce: false, value: 0, mode: SendRemainingValue + SendIgnoreErrors});
    }

    receive(msg: DeleteManager){
        self.requireOwner();
        send(SendParameters{
                to: self.owner,
                value: 0,
                mode: SendRemainingBalance + SendDestroyIfZero,
                bounce: false,
                body: "Manager contract deleted".asComment()
            }
        );
    }

    //==================================NEW FEATURES===========================================
    //=============================================================================
    // Oracle
    // TODO Заменить на оракул
    //=============================================================================
    receive(msg: SetRates) {
        self.requireOwner();
        self.rates = msg.rates;
        self.reply("Durov Protocol: rates updated".asComment());
    }

    /* Mint usdTON */
    receive(msg: MintDurovUSDMessage){
        send(SendParameters{
                to: self._userPositionAddress(sender()),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: MintDurovUSD{
                    user: sender(),
                    amount: msg.amount,
                    rates: self.rates,
                    runausd: self.deps.usdton
                }.toCell()
            }
        );
    }

    bounced(msg: bounced<MintDurovUSD>){
        self.bouncedHandler("Durov Protocol: mint error");
    }

    /*03 | Burn usdTON */
    receive(msg: BurnDurovUSDMessage){
        send(SendParameters{
                to: self._userPositionAddress(sender()),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: BurnDurovUSD{
                    user: sender(),
                    amount: msg.amount,
                    rates: self.rates,
                    runausd: self.deps.usdton
                }.toCell()
            }
        );
    }

    //=============================================================================
    // Helpers
    //=============================================================================

    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf NewUp(user,
            self.deps.manager,
        );
        return contractAddress(init);
    }

    fun payBack(user: Address) {
        send(SendParameters{to: user, bounce: false, value: 0, mode: SendRemainingValue + SendIgnoreErrors});
    }

    fun service(value: Int): Int {
        let balance: Int = myBalance() - value;
        let fee: Int = self.MinTonForStorage - min(balance, self.MinTonForStorage);
        return (value - fee) + self.GasConsumption;
    }

    fun bouncedHandler(reason: String) {
        send(SendParameters{
                to: self.deps.reservePool,
                bounce: false,
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                body: reason.asComment()
            }
        );
    }


    //=============================================================================
    // Offchain interface
    //=============================================================================

    get fun lastPositionId(): Int {
        return self.lastPositionId;
    }

    get fun userPositionAddress(user: Address): Address {
        return self._userPositionAddress(user);
    }
    get fun positionKeeper(id: Int): Address {
        let init: StateInit = initOf NewPositionKeeper(id, myAddress());
        let posKeeper: Address = contractAddress(init);
        return posKeeper;
    }

    get fun deps(): Deps {
        return self.deps;
    }
    get fun assets(): map<Address, Asset> {
        return self.assets;
    }
    get fun settings(): Settings {
        return self.settings;
    }

    get fun balances(): map<Address, Int> {
        return self.balances;
    }
    get fun version(): String {
        return self.version;
    }
}

contract NewPositionKeeper  {
    id: Int as uint32;
    position: Address;
    manager: Address;
    user: Address;

    init(id: Int, manager: Address){
        let ctx: Context = context();
        self.manager = ctx.sender;
        self.user = newAddress(0, 0);
        self.id = id;
        self.position = newAddress(0, 0);
    }

    receive(msg: SetAddress) {
        require(self.position == newAddress(0, 0), "Already set");
        self.position = msg.position;
        self.user = msg.user;

        send(SendParameters{
            to: self.manager,
            bounce: false,
            value: 0,
            mode: SendRemainingValue,
            body: "Durov Protocol: User position has been created".asComment()
        }
        );
    }

    receive(msg: MigrationRequest) {
        send(SendParameters{
                to: self.position,
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    get fun position(): Address {
        return self.position;
    }
    
    get fun user(): Address {
        return self.user;
    }
}