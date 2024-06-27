import "./user_position.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";
import "./utils/messages.tact";
import "./runecoin/runecoin_wallet.tact";

contract Manager with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    poolSettings: PoolSettings;
    owner: Address;
    lastPositionId: Int as uint32 = 0;
    tonPrice: Int;
    tonPriceWithHealthRate: Int;
    totalCollateralAmount: Int as coins = 0;
    stablecoinsIssued: Int as coins = 0;
    totalFeesCollected: Int as coins = 0;
    debtRate: DebtRate;
    init(owner: Address){
        self.owner = owner;
        self.poolSettings = PoolSettings{liquidationRatio: 0, stabilityFeeRate: 0, liquidatorIncentiveBps: 0};
        self.deps = Deps{
            managerAddress: newAddress(0, 0),
            poolAddress: newAddress(0, 0),
            usdTonAddress: newAddress(0, 0),
            runecoinAddress: newAddress(0, 0)
        };
        self.tonPrice = 0;
        self.tonPriceWithHealthRate = 0;
        self.debtRate = DebtRate{debtAccumulatedRate: 1000000000, lastAccumulationTime: (now() - 1000)};
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
        self.reply("deps set".asComment());
    }

    receive(msg: SetPoolSettings){
        self.requireOwner();
        self.poolSettings = PoolSettings{
            liquidationRatio: msg.liquidationRatio,
            stabilityFeeRate: msg.stabilityFeeRate,
            liquidatorIncentiveBps: msg.liquidatorIncentiveBps
        };
        self.reply("pool settings updated".asComment());
    }

    //=============================================================================
    // Oracle
    // TODO Заменить на оракул
    //=============================================================================
    receive(msg: UpdateTonPriceMsg){
        self.requireOwner();
        self.tonPriceWithHealthRate = msg.price * 1000000000 / self.poolSettings.liquidationRatio;
        self.tonPrice = msg.price;
        self.reply("ton price updated".asComment());
    }

    //=============================================================================
    // User actions
    //=============================================================================

    /*01 | Внесение залога */
    receive(msg: DepositCollateralUserMessage){
        dump(sender() == msg.user);
        require(sender() == msg.user, "Invalid sender");
        let ctx: Context = context();
        require(ctx.value >= ((msg.amount + self.GasConsumption) + self.MinTonForStorage), "not enough tons sent");
        let valueToSendForward: Int = ((context().value - self.MinTonForStorage) - self.GasConsumption);
        dump(valueToSendForward);
        dump(msg.amount);
        dump(ctx.value);
        let init: StateInit = initOf UserPosition(msg.user,
            self.deps.usdTonAddress,
            self.deps.managerAddress,
            self.deps.poolAddress,
            self.deps.runecoinAddress
        );
        let userPosition: Address = contractAddress(init);
        dump(userPosition);
        send(SendParameters{
                to: self.deps.managerAddress,
                value: valueToSendForward,
                bounce: true,
                body: DepositCollateralMessage{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.poolSettings,
                    rate: self.debtRate,
                    tonPriceWithHealthRate: self.tonPriceWithHealthRate
                }.toCell()
            }
        );
        self.totalCollateralAmount = (self.totalCollateralAmount + msg.amount);
    }

    receive(msg: AddPositionId){
        dump(msg.user);
        self.lastPositionId = (self.lastPositionId + 1);
        let init: StateInit = initOf PositionAddressContract(self.lastPositionId, myAddress());
        let positionAddress: Address = contractAddress(init);
        send(SendParameters{
                to: positionAddress,
                value: 0,
                bounce: true,
                body: SetPositionAddressMessage{user: msg.user, position: sender()}.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    /*02 | Mint usdTON */
    receive(msg: WithdrawStablecoinUserMessage){
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: WithdrawStablecoinMessage{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.poolSettings,
                    rate: self.debtRate
                }.toCell()
            }
        );
    }

    receive(msg: IncreaseTotalStable){
        self.stablecoinsIssued = (self.stablecoinsIssued + msg.amount);
        // pay excess back to user
        send(SendParameters{to: msg.user, bounce: false, value: 0, mode: (SendRemainingValue + SendIgnoreErrors)});
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
                    rate: self.debtRate,
                    tonPriceWithHealthRate: self.tonPriceWithHealthRate
                }.toCell()
            }
        );
    }

    receive(msg: DecreaseTotalStable){
        self.stablecoinsIssued = (self.stablecoinsIssued - msg.amount);
        // pay excess
        send(SendParameters{to: msg.user, bounce: false, value: 0, mode: (SendRemainingValue + SendIgnoreErrors)});
    }

    /*04 | Возврат залога */
    receive(msg: WithdrawCollateralUserMessage){
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
                    rate: self.debtRate,
                    tonPriceWithHealthRate: self.tonPriceWithHealthRate
                }.toCell()
            }
        );
    }

    /* проверка что адрес требующий возврат залога является владельцем позиции которая отправила запрос */
    receive(msg: DoWithdrawCollateral){
        self.onlyUserPosition(msg.user);
        require((self.totalCollateralAmount - msg.amount) >= 0, "not enough collateral on contract");
        self.totalCollateralAmount = (self.totalCollateralAmount - msg.amount);
        send(SendParameters{
                to: self.deps.poolAddress,
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    // let stabilityFee: Int = msg.amount / 1000000000 * msg.settings.stabilityFeeRate;
    // dump(stabilityFee);
    // dump(msg.runecoinWalletAddress);

    // send(SendParameters {
    //         to: msg.runecoinWalletAddress,
    //         value: ton("0.1"),
    //         // mode: (SendRemainingValue + SendBounceIfActionFail),
    //         bounce: false,
    //         body: TokenTransferFromPositionManager {
    //             queryId: 0,
    //             amount: stabilityFee,
    //             destination: self.poolAddress,
    //             responseDestination: msg.user,
    //             deps: msg.deps,
    //             customPayload: createOffchainContent("custom"),
    //             forwardTonAmount: 0,
    //             forwardPayload: createOffchainContent("forward").asSlice()
    //         }.toCell()
    //     }
    // );
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
            self.deps.poolAddress,
            self.deps.runecoinAddress
        );
        return contractAddress(init);
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

    get fun userPositionAddressById(id: Int): Address {
        let init: StateInit = initOf PositionAddressContract(id, myAddress());
        return contractAddress(init);
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

    get fun tonPriceWithHealthRate(): Int {
        return self.tonPriceWithHealthRate;
    }

    get fun debtRate(): DebtRate {
        return self.debtRate;
    }

    get fun stablecoinsIssued(): Int {
        return self.stablecoinsIssued;
    }

    get fun totalCollateralAmount(): Int {
        return self.totalCollateralAmount;
    }
}

//=============================================================================
// PositionAddressContract
// this contract stores positionaddress by position id
// for liquidators mostly
//=============================================================================

contract PositionAddressContract with Deployable {
    id: Int as uint32;
    positionAddress: Address;
    managerAddress: Address;
    init(id: Int, manager: Address){
        let ctx: Context = context();
        self.id = id;
        self.positionAddress = newAddress(0, 0);
        self.managerAddress = manager;
    }

    /*
        message came from userPosition
        set position address
        now we can determine this contract address by positionId 
        and get positionAddress by getter
    */
    receive(msg: SetPositionAddressMessage){
        require(sender() == self.managerAddress, "Invalid sender");
        require(self.positionAddress == newAddress(0, 0), "Already set");
        self.positionAddress = msg.position;
        // dump("pay excess");
        // // pay excess to user
        // send(SendParameters{to: msg.user, bounce: false, value: 0, mode: (SendRemainingValue + SendBounceIfActionFail)}
        // );
    }

    get fun positionAddress(): Address {
        return self.positionAddress;
    }
}