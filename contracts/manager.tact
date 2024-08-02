import "./user_position.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";
import "./utils/messages.tact";
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
    lastPositionId: Int as coins = 0;
    tonPrice: Int;
    totalCollateralAmount: Int as coins = 0;
    totalFeesCollected: Int as coins = 0;
    init(owner: Address){
        self.owner = owner;
        self.settings = Settings{
            reservePool: 0,
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
            usdton: newAddress(0, 0)
        };
        self.tonPrice = 0;
    }

    //=============================================================================
    // Set Deps
    //=============================================================================
    receive(msg: SetDeps){
        self.requireOwner();
        self.deps = Deps{
            manager: msg.manager,
            profitPool: msg.profitPool,
            reservePool: msg.reservePool,
            usdton: msg.usdton
        };
        self.reply("manager's dependencies set".asComment());
    }

    //=============================================================================
    // Set Settings
    //=============================================================================
    receive(msg: SetSettings){
        self.requireOwner();
        self.settings = Settings{
            reservePool: msg.reservePool,
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
    /*01 | Внесение залога */
    // receive(msg: DepositCollateralUserMessage){
    //     require(sender() == msg.user, "Invalid sender");
    //     let ctx: Context = context();
    //     require(ctx.value >= ((msg.amount + self.GasConsumption) + self.MinTonForStorage), "not enough tons sent");
    //     require(msg.amount < self.settings.reserveMin, "tons amount is less than minimum possible");

    //     //TODO рассчитать газ для всех дальнейших операций сразу

    //     let valueToSendForward: Int = ((context().value - self.MinTonForStorage) - self.GasConsumption);
    //     send(SendParameters{
    //             to: self.deps.reservePool,
    //             value: valueToSendForward,
    //             mode: SendBounceIfActionFail,
    //             bounce: true,
    //             body: DepositCollateralMessage{
    //                 user: msg.user,
    //                 amount: msg.amount,
    //                 settings: self.settings,
    //                 tonPrice: self.tonPrice
    //             }.toCell()
    //             // code: init.code,
    //             // data: init.data
    //         }
    //     );
    //     self.totalCollateralAmount = (self.totalCollateralAmount + msg.amount);
    // }
    receive(msg: DepositCollateralUserMessage){
        require(sender() == msg.user, "Invalid sender");
        let ctx: Context = context();
        require(ctx.value >= ((msg.amount + self.GasConsumption) + self.MinTonForStorage), "not enough TONs sent");
        require(msg.amount >= self.settings.reserveMin, "TONs amount is less than minimum possible");

        //TODO рассчитать газ для всех дальнейших операций сразу

        let valueToSendForward: Int = ((context().value - self.MinTonForStorage) - self.GasConsumption);
        let init: StateInit = initOf UserPosition(msg.user,
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
                body: DepositCollateralMessage{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.settings,
                    tonPrice: self.tonPrice
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
        self.totalCollateralAmount = (self.totalCollateralAmount + msg.amount);
    }

    bounced(msg: bounced<DepositCollateralMessage>){
        self.bouncedHandler();
    }

    receive(msg: AddPositionId){
        self.lastPositionId = (self.lastPositionId + 1);
        send(SendParameters{to: msg.user, bounce: false, value: 0, mode: (SendRemainingValue + SendBounceIfActionFail)}
        );
    }

    /*02 | Mint usdTON */
    receive(msg: MintUsdTonMessage){
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: MintUsdTon{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.settings,
                    tonPrice: self.tonPrice
                }.toCell()
            }
        );
    }

    bounced(msg: bounced<MintUsdTon>){
        self.bouncedHandler();
    }

    /*03 | Burn usdTON */
    receive(msg: BurnUsdTONUserMessage){
        require(msg.amount >= self.settings.burnMin, "burn amount is less than minimum possible");
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: BurnUsdTONMessage{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.settings,
                    tonPrice: self.tonPrice,
                    deps: self.deps,
                    fee: msg.fee
                }.toCell()
            }
        );
    }

    bounced(msg: bounced<BurnUsdTONMessage>){
        self.bouncedHandler();
    }

    receive(msg: PositionLiquidationInspectorMessage){
        require(sender() == self.owner, "invalid sender");
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: PositionLiquidation{settings: self.settings, user: msg.user, tonPrice: self.tonPrice}.toCell()
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
        send(SendParameters{to: user, bounce: false, value: 0, mode: (SendRemainingValue + SendIgnoreErrors)});
    }

    fun service(value: Int): Int {
        let balance: Int = (myBalance() - value);
        let fee: Int = (self.MinTonForStorage - min(balance, self.MinTonForStorage));
        return ((value - fee) + self.GasConsumption);
    }

    fun bouncedHandler() {
        send(SendParameters{
                to: self.deps.profitPool,
                bounce: false,
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                body: "error".asComment()
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