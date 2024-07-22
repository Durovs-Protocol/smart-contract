import "./user_position.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";
import "./utils/messages.tact";
import "./runecoin/runecoin_wallet.tact";
struct ManagerState {
    totalSupplyed: Int;
    totalMinted: Int;
}

contract Manager with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    poolSettings: PoolSettings;
    owner: Address;
    tonPrice: Int;
    lastPositionId: Int as coins = 0;
    state: ManagerState;
    const allowableError: Int = 800000;
    //0.0008



    init(owner: Address){
        self.owner = owner;
        self.poolSettings = PoolSettings{liquidationRatio: 0, stabilityFeeRate: 0, liquidationFee: 0, minHealthRate: 0};
        self.deps = Deps{
            managerAddress: newAddress(0, 0),
            poolAddress: newAddress(0, 0),
            usdTonAddress: newAddress(0, 0),
            runecoinAddress: newAddress(0, 0)
        };
        self.state = ManagerState{totalSupplyed: 0, totalMinted: 0};
        self.tonPrice = 0;
    }

    //=============================================================================
    // Settings
    //=============================================================================
    receive(msg: SetDeps){
        self.requireOwner();
        self.deps = Deps{
            managerAddress: msg.managerAddress,
            poolAddress: msg.poolAddress,
            usdTonAddress: msg.usdTonAddress,
            runecoinAddress: msg.runecoinAddress
        };
        self.reply("manager's dependencies set".asComment());
    }

    receive(msg: SetPoolSettings){
        self.requireOwner();
        self.poolSettings = PoolSettings{
            liquidationRatio: msg.liquidationRatio,
            stabilityFeeRate: msg.stabilityFeeRate,
            liquidationFee: msg.liquidationFee,
            minHealthRate: msg.minHealthRate
        };
        self.reply("Pool settings updated".asComment());
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
    receive(msg: DepositCollateralUserMessage){
        let init: StateInit = initOf UserPosition(msg.user,
            self.deps.usdTonAddress,
            self.deps.managerAddress,
            self.deps.poolAddress
        );
        let userPosition: Address = contractAddress(init);
        require(sender() == msg.user, "Invalid sender");
        let ctx: Context = context();
        require(ctx.value >= (msg.amount + self.GasConsumption + self.MinTonForStorage), "not enough tons sent");
        //TODO рассчитать газ для всех дальнейших операций сразу

        let valueToSendForward: Int = ctx.value - (self.GasConsumption + self.MinTonForStorage);
        send(SendParameters{
                to: userPosition,
                value: valueToSendForward,
                mode: SendBounceIfActionFail,
                bounce: true,
                body: DepositCollateralMessage{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.poolSettings,
                    tonPrice: self.tonPrice
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    receive(msg: AddPositionId){
        self.lastPositionId = (self.lastPositionId + 1);
        send(SendParameters{to: msg.user, bounce: false, value: 0, mode: (SendRemainingValue + SendBounceIfActionFail)}
        );
    }

    /*02 | Mint usdTON */
    receive(msg: MintUsdTonMessage) {
        let stabilityFee: Int = msg.amount * 50000000 / 1000000000;

        if (!(self.poolIsHealthy(msg.amount, stabilityFee))) {
            return ;
        }
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: MintUsdTon{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.poolSettings,
                    tonPrice: self.tonPrice,
                }.toCell()
            }
        );
    }

    /*03 | Burn usdTON */
    receive(msg: BurnUsdTONUserMessage){
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: BurnUsdTONMessage{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.poolSettings,
                    tonPrice: self.tonPrice,
                    deps: self.deps
                }.toCell()
            }
        );
    }

    /*04 | Возврат залога */
    receive(msg: WithdrawCollateralUserMessage) {
        require(sender() == msg.user, "invalid sender");
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: WithdrawCollateralMessage{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.poolSettings,
                    tonPrice: self.tonPrice
                }.toCell()
            }
        );
    }

    // from: code, to: UserPosition
    receive(msg: PositionLiquidationInspectorMessage){
        require(sender() == self.owner, "invalid sender");
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: PositionLiquidation{settings: self.poolSettings, user: msg.user, tonPrice: self.tonPrice}.toCell()
            }
        );
    }

    receive(msg: UsdTonUpdateNotification){
        self.state.totalMinted = msg.newValue;
    }

    receive(msg: PoolUpdateNotification){
        self.state.totalSupplyed = msg.newValue;
    }

    /*| Стабилизация */
    receive(msg: Stabilization) {
        //0.12
        let rateDiff: Int = abs(1000000000 - msg.rate);
        if (rateDiff > self.allowableError) {

        if (msg.rate > 1000000000) {

        let price: Int = (rateDiff * (msg.usdtonAmount / 2));
        let amount: Int = (price * 1000000000) / self.tonPrice;

        send(SendParameters {
            to: self.deps.poolAddress, 
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: DoStabilizationTon{
                amount: amount,
                price: price,
            }.toCell()
            });

        } else {

        let price: Int = (rateDiff * (msg.usdtonAmount / 2)) / msg.rate;
        let amount: Int = (price * 1000000000) / self.tonPrice;

            send(SendParameters {
            to: self.deps.poolAddress, 
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: DoStabilizationUsdton{
                amount: amount,
                price: price,
            }.toCell()
            });
        }
        } else {
             self.reply("Stabilization error: usdton is stable".asComment());
        }

    }



    // receive("EmergencyExit"){
    //     require(sender() == self.owner, "invalid sender");
    //     send(SendParameters{
    //             to: sender(),
    //             bounce: false,
    //             value: ((myBalance() - context().value) - self.MinTonForStorage),
    //             mode: (SendRemainingValue + SendIgnoreErrors)
    //         }
    //     );
    // }

    // receive("CollectFees"){
    //     require(now() > self.debtRate.lastAccumulationTime, "updateDebtAccumulatedRate: Invalid timestamp");
    //     let precision: Int = pow(10, 12);
    //     let updatedDebtAccumulatedRate: Int =
    //         self.debtRate.debtAccumulatedRate *
    //             rpow(self.poolSettings.stabilityFeeRate, (now() - self.debtRate.lastAccumulationTime), precision);
    //     let updatedLastAccumulationTime: Int = now();
    //     self.debtRate = DebtRate{
    //         debtAccumulatedRate: updatedDebtAccumulatedRate,
    //         lastAccumulationTime: updatedLastAccumulationTime
    //     };
    //     self.reply("debt rate updated".asComment());
    // }

    // receive("WithdrawFees"){
    //     self.requireOwner();
    //     require(self.totalFeesCollected > 0, "no fees collected");
    //     send(SendParameters{
    //             to: sender(),
    //             bounce: false,
    //             value: 0,
    //             mode: (SendRemainingValue + SendIgnoreErrors),
    //             body: WithdrawFeesMessage{to: sender(), amount: self.totalFeesCollected}.toCell()
    //         }
    //     );
    //     self.totalFeesCollected = 0;
    // }

    //=============================================================================
    // Helpers
    //=============================================================================
    fun onlyUserPosition(user: Address) {
        nativeThrowUnless(132, self._userPositionAddress(user) == sender());
    }

    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf UserPosition(user,
            self.deps.usdTonAddress,
            self.deps.managerAddress,
            self.deps.poolAddress
        );
        return contractAddress(init);
    }

    fun payBack(user: Address) {
        send(SendParameters{to: user, bounce: false, value: 0, mode: (SendRemainingValue + SendIgnoreErrors)});
    }

    fun poolIsHealthy(amount: Int, stabilityFee: Int): Bool {
        let totalSupplyed: Int = self.state.totalSupplyed * self.tonPrice / 1000000000;

        return (self.state.totalMinted + amount) / 100 <= (stabilityFee + totalSupplyed);
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

    get fun poolSettings(): PoolSettings {
        return self.poolSettings;
    }

    get fun tonPrice(): Int {
        return self.tonPrice;
    }

    get fun state(): ManagerState {
        return self.state;
    }
}