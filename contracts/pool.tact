import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./user_position.tact";
import "./utils/math.tact";
message PoolSettingsMsg {
    liquidationRatio: Int;
    stabilityFeeRate: Int; // 1000000000625 = X**1.000000000627 every second = 2%/yr., look at ./math/math.tact
    liquidatorIncentiveBps: Int;
}
message UpdateTonPriceMsg {
    price: Int as coins;
}
message DepositCollateralUserMessage {
    user: Address;
    amount: Int as coins;
}
message WithdrawStablecoinUserMessage {
    user: Address;
    amount: Int as coins;
}
message RepayStablecoinUserMessage {
    user: Address;
    amount: Int as coins;
}
message WithdrawCollateralUserMessage {
    user: Address;
    amount: Int as coins;
}

contract Pool with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    // deps
    deps: Deps;
    owner: Address;
    poolSettings: PoolSettings;
    tonPrice: Int;
    tonPriceWithSafetyMargin: Int;
    debtRate: DebtRate;
    totalCollateralAmount: Int as coins = 0;
    stablecoinsIssued: Int as coins = 0;
    totalFeesCollected: Int as coins = 0;
    init(owner: Address){
        self.owner = owner;
        self.poolSettings = PoolSettings{liquidationRatio: 0, stabilityFeeRate: 0, liquidatorIncentiveBps: 0};
        self.tonPrice = 0;
        self.tonPriceWithSafetyMargin = 0;
        self.debtRate = DebtRate{debtAccumulatedRate: 1000000000, lastAccumulationTime: (now() - 1000)};
        self.deps = Deps{
            positionsManagerAddress: newAddress(0, 0),
            poolAddress: newAddress(0, 0),
            stablecoinMasterAddress: newAddress(0, 0)
        };
    }

    //setup
    receive(msg: SetDeps){
        self.requireOwner();
        self.deps = Deps{
            stablecoinMasterAddress: msg.stablecoinMasterAddress,
            poolAddress: msg.poolAddress,
            positionsManagerAddress: msg.positionsManagerAddress
        };
        self.reply("deps set".asComment());
    }

    receive(msg: PoolSettingsMsg){
        self.requireOwner();
        self.poolSettings = PoolSettings{
            liquidationRatio: msg.liquidationRatio,
            stabilityFeeRate: msg.stabilityFeeRate,
            liquidatorIncentiveBps: msg.liquidatorIncentiveBps
        };
        self.reply("pool settings updated".asComment());
    }

    // TODO Заменить на оракул
    receive(msg: UpdateTonPriceMsg){
        self.requireOwner();
        dump(msg.price);
        dump(self.poolSettings.liquidationRatio);
        self.tonPriceWithSafetyMargin = msg.price * 1000000000 / self.poolSettings.liquidationRatio;
        dump(self.tonPriceWithSafetyMargin);
        self.tonPrice = msg.price;
        self.reply("ton price updated".asComment());
    }

    // user actions

    /*01 | Внесение обеспечения пользователем (from user)'*/
    receive(msg: DepositCollateralUserMessage){
        require(sender() == msg.user, "Invalid sender");
        require(context().value >= ((msg.amount + self.GasConsumption) + self.MinTonForStorage),
            "not enough tons sent"
        );
        let valueToSendForward: Int = (((context().value - self.MinTonForStorage) - self.GasConsumption) - msg.amount);
        self.totalCollateralAmount = (self.totalCollateralAmount + msg.amount);
        send(SendParameters{
                to: self.deps.positionsManagerAddress,
                value: valueToSendForward,
                mode: SendBounceIfActionFail,
                bounce: true,
                body: DepositCollateralMessage{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.poolSettings,
                    rate: self.debtRate,
                    tonPriceWithSafetyMargin: self.tonPriceWithSafetyMargin
                }.toCell()
            }
        );
    }

    /*02 | Начисление USDTON пользователю (from user)'*/
    receive(msg: WithdrawStablecoinUserMessage){
        send(SendParameters{
                to: self.deps.positionsManagerAddress,
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: WithdrawStablecoinMessage{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.poolSettings,
                    rate: self.debtRate,
                    tonPriceWithSafetyMargin: self.tonPriceWithSafetyMargin
                }.toCell()
            }
        );
    }

    /*03 | Погашение задолженности (from user)'*/
    receive(msg: RepayStablecoinUserMessage){
        send(SendParameters{
                to: self.deps.positionsManagerAddress,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: RepayStablecoinMessage{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.poolSettings,
                    rate: self.debtRate,
                    tonPriceWithSafetyMargin: self.tonPriceWithSafetyMargin
                }.toCell()
            }
        );
    }

    /*04 | Возврат обеспечения (from user)'*/
    receive(msg: WithdrawCollateralUserMessage){
        require(sender() == msg.user, "invalid sender");
        send(SendParameters{
                to: self.deps.positionsManagerAddress,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: WithdrawCollateralMessage{
                    user: msg.user,
                    amount: msg.amount,
                    settings: self.poolSettings,
                    rate: self.debtRate,
                    tonPriceWithSafetyMargin: self.tonPriceWithSafetyMargin
                }.toCell()
            }
        );
    }

    /*04 | Возврат обеспечения (from manager)'
        transfer ton to user wallet
        */
    receive(msg: DoWithdrawCollateralMessage){
        require(sender() == self.deps.positionsManagerAddress, "invalid sender");
        require((self.totalCollateralAmount - msg.amount) >= 0, "not enough collateral on contract");
        self.totalCollateralAmount = (self.totalCollateralAmount - msg.amount);
        // pay ton collateral to user and send excess
        send(SendParameters{
                to: msg.user,
                bounce: false,
                value: msg.amount,
                mode: (SendRemainingValue + SendIgnoreErrors)
            }
        );
    }

    /*03 |(from manager)'
        decrease stablecoinsIssued
        increase totalFeesCollected
        send excess to user
    */
    receive(msg: DecreaseTotalStableMessage){
        require(sender() == self.deps.positionsManagerAddress, "invalid sender");
        self.stablecoinsIssued = (self.stablecoinsIssued - msg.amount);
        // pay excess
        send(SendParameters{to: msg.user, bounce: false, value: 0, mode: (SendRemainingValue + SendIgnoreErrors)});
    }

    /*02 |(from manager)'
            increasr stablecoinsIssued
        send excess to user
        userStatus.message('stable paid received)
    */
    receive(msg: IncreaseTotalStableMessage){
        require(sender() == self.deps.positionsManagerAddress, "invalid sender");
        self.stablecoinsIssued = (self.stablecoinsIssued + msg.amount);
        // pay excess back to user
        send(SendParameters{to: msg.user, bounce: false, value: 0, mode: (SendRemainingValue + SendIgnoreErrors)});
    }

    receive("EmergencyExit"){
        require(sender() == self.owner, "invalid sender");
        send(SendParameters{
                to: sender(),
                bounce: false,
                value: ((myBalance() - context().value) - self.MinTonForStorage),
                mode: (SendRemainingValue + SendIgnoreErrors)
            }
        );
    }

    receive("CollectFees"){
        require(now() > self.debtRate.lastAccumulationTime, "updateDebtAccumulatedRate: Invalid timestamp");
        let precision: Int = pow(10, 12);
        let updatedDebtAccumulatedRate: Int =
            self.debtRate.debtAccumulatedRate *
                rpow(self.poolSettings.stabilityFeeRate, (now() - self.debtRate.lastAccumulationTime), precision);
        let updatedLastAccumulationTime: Int = now();
        self.debtRate = DebtRate{
            debtAccumulatedRate: updatedDebtAccumulatedRate,
            lastAccumulationTime: updatedLastAccumulationTime
        };
        self.reply("debt rate updated".asComment());
    }

    receive("WithdrawFees"){
        self.requireOwner();
        require(self.totalFeesCollected > 0, "no fees collected");
        send(SendParameters{
                to: sender(),
                bounce: false,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                body: WithdrawFeesMessage{to: sender(), amount: self.totalFeesCollected}.toCell()
            }
        );
        self.totalFeesCollected = 0;
    }

    //helpers
    fun getUserPositionAddress(user: Address): Address {
        let init: StateInit = initOf UserPosition(user, self.deps.stablecoinMasterAddress, myAddress());
        return contractAddress(init);
    }

    // offchain interface

    get fun poolSettings(): PoolSettings {
        return self.poolSettings;
    }

    get fun tonPrice(): Int {
        return self.tonPrice;
    }

    get fun tonPriceWithSafetyMargin(): Int {
        return self.tonPriceWithSafetyMargin;
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

    get fun getBalance(): Int {
        return myBalance();
    }

    get fun deps(): Deps {
        return self.deps;
    }
}