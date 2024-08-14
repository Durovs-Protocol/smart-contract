import "@stdlib/deploy";
import "@stdlib/ownable";
import "./up_pool.tact";
import "../utils/messages.tact";
struct ManagerState {
    totalSupplyed: Int;
    totalMinted: Int;
}

contract Manager with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    settings: Settings;
    owner: Address;
    lastPositionId: Int = 0;
    tonPrice: Int;
    totalCollateralAmount: Int as coins = 0;
    totalFeesCollected: Int as coins = 0;
    availableCoupons: Int as coins = 0;
    init(owner: Address){
        self.owner = owner;
        self.settings = Settings{
            reserveRatio: 0,
            reserveMin: 0,
            burnMin: 0,
            serviceFeePercent: 0,
            serviceFee: 0,
            liquidationRatio: 0
        };
        self.deps = Deps{
            manager: newAddress(0, 0),
            profitPool: newAddress(0, 0),
            reservePool: newAddress(0, 0),
            usdton: newAddress(0, 0),
            runaCoupon: newAddress(0, 0)
        };
        self.tonPrice = 0;
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
        self.reply("manager's dependencies set".asComment());
    }

    //=============================================================================
    // Set Settings
    //=============================================================================
    receive(msg: SetSettings) {
        self.requireOwner();
        self.settings = Settings{
            reserveRatio: msg.reserveRatio,
            reserveMin: msg.reserveMin,
            burnMin: msg.burnMin,
            serviceFeePercent: msg.serviceFeePercent,
            serviceFee: msg.serviceFee,
            liquidationRatio: msg.liquidationRatio
        };
        self.reply("Settings updated".asComment());
    }

    //=============================================================================
    // Oracle
    // TODO Заменить на оракул
    //=============================================================================
    receive(msg: UpdateTonPriceMsg){
        self.requireOwner();
        self.tonPrice = msg.price;
        self.reply("Ton price updated".asComment());
    }

    //=============================================================================
    // User actions
    //=============================================================================

    receive(msg: SupplyMessage) {
        let ctx: Context = context();
        require(ctx.value >= ((msg.amount + self.GasConsumption) + self.MinTonForStorage), "Runa protocol: not enough TONs sent");

        let valueToSendForward: Int = ctx.value - (self.MinTonForStorage + self.GasConsumption);
        let init: StateInit = initOf UserPosition(sender(),
            self.deps.usdton,
            self.deps.manager,
            self.deps.reservePool,
            self.deps.profitPool
        );
        let userPosition: Address = contractAddress(init);

        send(SendParameters{
                to: userPosition,
                value: valueToSendForward,
                mode: SendBounceIfActionFail,
                bounce: true,
                body: Supply{
                    user: sender(),
                    amount: msg.amount,
                    settings: self.settings,
                    tonPrice: self.tonPrice
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );

    }

        // self.totalCollateralAmount = self.totalCollateralAmount + msg.amount;
    bounced(msg: bounced<Supply>) {
        self.bouncedHandler("Runa protocol: error in supply");
    }

    receive(msg: AddPositionId) {
        self.lastPositionId = self.lastPositionId + 1;
        let init: StateInit = initOf PositionKeeper(self.lastPositionId, myAddress());
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
    receive(msg: SetPositionAddress) {
        send(SendParameters{to: msg.user, value: 0, mode: SendRemainingValue, bounce: false, body: msg.toCell()});
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
                    settings: self.settings,
                    tonPrice: self.tonPrice
                }.toCell()
            }
        );
    }

    bounced(msg: bounced<Withdraw>){
        self.bouncedHandler("Runa protocol: error in withdraw");
    }

    /* ==Migration== */
    receive(msg: Migration) {
        self.requireOwner();
        let init: StateInit = initOf PositionKeeper(msg.id, myAddress());
        let positionAddress: Address = contractAddress(init);
        send(SendParameters {
                to: positionAddress,
                value: 0,
                mode: SendBounceIfActionFail + SendRemainingValue,
                bounce: true,
                body: MigrationRequest{
                    manager: msg.newManager,
                    reservePool: self.deps.reservePool,
                    usdton: self.deps.usdton,
                    profitPool: self.deps.profitPool
                }.toCell()
            }
        );
    }


    receive(msg: BuildPosition) {
        send(SendParameters{
                to: msg.manager,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: msg.toCell(),
            }
        );
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
    //=============================================================================
    // Helpers
    //=============================================================================

    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf UserPosition(user,
            self.deps.usdton,
            self.deps.manager,
            self.deps.reservePool,
            self.deps.profitPool
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
        let init: StateInit = initOf PositionKeeper(id, myAddress());
        let positionKeeper: Address = contractAddress(init);
        return positionKeeper;
    }

    get fun deps(): Deps {
        return self.deps;
    }

    get fun settings(): Settings {
        return self.settings;
    }

    get fun tonPrice(): Int {
        return self.tonPrice;
    }

    get fun totalCollateralAmount(): Int {
        return self.totalCollateralAmount;
    }
}

contract PositionKeeper with Deployable {
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
                body: SetPositionAddress{user: self.user, address: myAddress()}.toCell()
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