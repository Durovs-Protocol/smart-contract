import "@stdlib/deploy";
import "@stdlib/ownable";
import "./up_pool.tact";
import "./utils/messages.tact";

contract Manager with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01321");
    const GasConsumption: Int = ton("0.01321");
    deps: Deps;
    assets:  map<Address, Asset>;
    balances: map<Address, Int>;

    settings: Settings;
    owner: Address;
    lastPositionId: Int = 0;
    lastMigrationId: Int = 0;
    version: String = "0";

    init(owner: Address){
        require(owner == sender(), "Durovs Protocol: No access to init manager");
        self.owner = sender();
        self.settings = Settings{
            minDelay: 0,
            newManager: newAddress(0, 0),
            maxExecutionTime: 0,
        };
        self.deps = Deps{
            manager: newAddress(0, 0),
            profitPool: newAddress(0, 0),
            reservePool: newAddress(0, 0),
            stable: newAddress(0, 0),
            coupon: newAddress(0, 0),
        };

        self.assets = emptyMap();
        self.balances = emptyMap();
    }


    //=============================================================================
    // Set Deps - ok1
    //=============================================================================
    receive(msg: SetDeps) {
        self.requireOwner();
        self.deps = Deps{
            manager: msg.manager,
            profitPool: msg.profitPool,
            reservePool: msg.reservePool,
            stable: msg.stable,
            coupon: msg.coupon
        };
        self.reply("Durovs Protocol: Manager's dependencies set".asComment());
    }


    //=============================================================================
    // Set Settings
    //=============================================================================
    receive(msg: SetSettings) {
        self.requireOwner();
        self.settings = Settings{
            minDelay: msg.minDelay,
            newManager: msg.newManager,
            maxExecutionTime: msg.maxExecutionTime,

        };
        self.reply("Durovs Protocol: Settings have been updated".asComment());
    }

    receive(msg: SetAssets) {
        self.requireOwner();
        self.assets = msg.assets;
        self.reply("Durovs Protocol: Manager assets set".asComment());
    }

    receive(msg: SetBalances) {
        self.requireOwner();
        self.balances = msg.balances;
        self.reply("Durovs Protocol: Manager balances template set".asComment());
    }

    receive(str: String){
        // принимаем текстовые сообщения и перенаправляем их владельцу контракта
        send(SendParameters {
                to: self.owner,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: str.asComment()
            }
        );
    }
    //=============================================================================
    // User actions
    //=============================================================================
    receive(msg: SupplyMessage) {
        let ctx: Context = context();
        require(sender() == self.deps.reservePool, "Durovs Protocol: No access for supply");
        let valueToSendForward: Int = ctx.value - (self.MinTonForStorage + self.GasConsumption);
        let init: StateInit = initOf UserPosition(msg.user,
            self.deps.manager,
            self.deps.reservePool,
            self.balances
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
                    master: msg.master,
                    userWallet: msg.userWallet
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    bounced(msg: bounced<Supply>) {
        self.bouncedHandler("Durovs Protocol: Error in supply.");
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


    /*04 Проверено */
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
        self.bouncedHandler("Durovs Protocol: Error in withdrawal");
    }

    /* ==Migration== */
    receive(msg: Migration) {
        self.requireOwner();
        let init: StateInit = initOf PositionKeeper(msg.id, myAddress());
        let positionAddress: Address = contractAddress(init);
        self.lastMigrationId = msg.id;

        send(SendParameters {
                to: positionAddress,
                value: 0,
                mode: SendBounceIfActionFail + SendRemainingValue,
                bounce: true,
                body: InformationRequest{}.toCell()
            }
        );
    }
    
    receive(msg: InformationResponce) {
        let init: StateInit = initOf PositionKeeper(self.lastMigrationId, myAddress());
        let positionAddress: Address = contractAddress(init);
        require(sender() == positionAddress, "Durovs Protocol: No access for migration");

        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: MigrationRequest{
                    newManager: self.settings.newManager
                }.toCell()
            }
        );
    }

    receive(msg: BuildPosition) {
        require(sender() == self._userPositionAddress(msg.user), "Durovs Protocol: No access for migration");
        send(SendParameters{
                to: self.settings.newManager,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: msg.toCell(),
            }
        );
    }

    // receive(msg: DeleteManager){
    //     self.requireOwner();
    //     send(SendParameters{
    //             to: self.owner,
    //             value: 0,
    //             mode: SendRemainingBalance + SendDestroyIfZero,
    //             bounce: false,
    //             body: "Manager contract deleted".asComment()
    //         }
    //     );
    // }
    //=============================================================================
    // Helpers
    //=============================================================================

    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf UserPosition(user,
            self.deps.manager,
            self.deps.reservePool,
            self.balances
        );
        return contractAddress(init);
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

    get fun lastMigrationId(): Int {
        return self.lastMigrationId;
    }
}

contract PositionKeeper {
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
            to: self.user,
            bounce: false,
            value: 0,
            mode: SendRemainingValue,
            body: "Durovs Protocol: User position has been created".asComment()
        });
    }

    receive(msg: InformationRequest) {
        require(self.manager == sender(), "Durovs Protocol: No access for information request");
        send(SendParameters{
                to: self.manager,
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: InformationResponce{
                    user: self.user,
                    position: self.position
                }.toCell()
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