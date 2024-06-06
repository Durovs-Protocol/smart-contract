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

contract Pool with Deployable, Ownable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    // deps
    deps: Deps;
    owner: Address;
    poolSettings: PoolSettings;
    tonPrice: Int as uint32;
    tonPriceWithSafetyMargin: Int;
    debtRate: DebtRate;
    totalCollateralAmount: Int as coins = 0;
    stablecoinsIssued: Int as coins = 0;
    totalFeesCollected: Int as coins = 0;
    init(){
        self.owner = sender();
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

    // owner actions

    receive(msg: SetDeps){
        self.requireOwner();
        self.deps = Deps{
            stablecoinMasterAddress: msg.stablecoinMasterAddress,
            poolAddress: msg.poolAddress,
            positionsManagerAddress: msg.positionsManagerAddress
        };
        self.reply("deps set".asComment());
    }

    // user actions

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
                mode: SendIgnoreErrors,
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

    /*
        called by user owner
        call positionsManager.withdrawStablecoin(WithdrawStablecoinMessage)
    */
    receive(msg: WithdrawStablecoinUserMessage){
        send(SendParameters{
                to: self.deps.positionsManagerAddress,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
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

    /*
        called by user owner
        call positionsManager.repayStablecoin(RepayStablecoinMessage)
    */
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

    /*
        called by user owner
        call positionsManager.withdrawCollateral(RepayStablecoinMessage)
    */
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

    // from positionsManagers actions

    /*
        called by positionsManager
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

    /*
        called by positionsManager
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

    /*
        called by positionsManager
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

    // send all balance to the owner, should be removed later
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

    fun getUserPositionAddress(user: Address): Address {
        let init: StateInit = initOf UserPositionContract(user, self.deps.stablecoinMasterAddress, myAddress());
        return contractAddress(init);
    }

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