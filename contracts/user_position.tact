import "./utils/messages.tact";
import "./utils/helpers.tact";

struct PositionState {
    collateral: Int as coins;
    debt: Int as uint64;
}

struct Message {
    timestamp: Int as uint64;
    message: String;
}

contract UserPosition  {
    const MinTonsForStorage: Int = ton("0.01");
    user: Address;
    usdTonAddress: Address;
    runecoinAddress: Address;

    managerAddress: Address;
    poolAddress: Address;
    collateral: Int as coins = 0;
    debt: Int = 0;
    message: Message;

    init(user: Address, usdTonAddress: Address, managerAddress: Address, poolAddress: Address, runecoinAddress: Address) {
        self.user = user; 
        self.usdTonAddress = usdTonAddress;
        self.runecoinAddress = runecoinAddress;

        self.managerAddress = managerAddress;
        self.poolAddress = poolAddress;
        dump("Position Created");

        self.message = Message{
            timestamp: 0,
            message: "Position Created"
        };

        // register this position in positionsManager


        send(SendParameters{
            to: self.managerAddress, 
            // how much we should send to this contract? 
            // how to pay for storage for this contract later? 
            // we have no more writes in position address contract ever
            value: ton("0.1"), 
            bounce: true,
            body: AddPositionId{
                user: user
            }.toCell()
        });
    }

    //=============================================================================
    // Actions
    //=============================================================================
    /*01 | Внесение залога */
    receive(msg: DepositCollateralMessage) {
              dump(sender());
              dump(self.managerAddress);

        dump(context().value);
        require(sender() == self.managerAddress, "not from positionsManager");

        dump(context().value);

        // pay excess to user
        send(SendParameters{
                to: self.poolAddress,
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: DoDeposit {
                    user: msg.user,
                    amount: msg.amount,
                }.toCell()
            }
        );
                self.collateral = self.collateral + msg.amount;
        self.setMessage("Collateral added");
    }

    /*02 | Mint usdTON */
    receive(msg: WithdrawStablecoinMessage) {
        require(sender() == self.managerAddress, "not from positionsManager");
        let normalizedWithdrawDebt: Int = msg.amount * 1000000000 / msg.rate.debtAccumulatedRate;
        let debtAfterWithdraw: Int = self.debt + normalizedWithdrawDebt;

        // dump("check healthy");
        // if (!self.isPositionHealthy(self.collateral, debtAfterWithdraw, msg.tonPriceWithHealthRate, msg.rate.debtAccumulatedRate)){
        //     self.unhealthyPositionHandler(msg.user);
        //     return;
        // } 
        // dump("position healthy");

        send(SendParameters{
            to: self.usdTonAddress, 
            value: ton("0.1"),
            mode: (SendRemainingValue + SendIgnoreErrors), 
            bounce: true,
            body: MintMessage{
                user: msg.user,
                amount: msg.amount
            }.toCell()
        });

        self.debt = debtAfterWithdraw;
        self.setMessage("Stablecoins sent");

        // todo move this send after successfull stable mint notification
        send(SendParameters{
            to: self.managerAddress, 
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors, 
            bounce: true,
            body: IncreaseTotalStable{
                user: msg.user,
                amount: msg.amount
            }.toCell()
        });
    }
    /*02 |from stablecoinMaster'*/
    receive(msg: StablecoinBurnedMessage) {

        require(sender() == self.usdTonAddress, "not from stablecoin master");

        // todo check if debt still more than repayment

        self.debt = self.debt - msg.amount * 1000000000 / msg.rate.debtAccumulatedRate;

        self.setMessage("you've paid stables back");

        send(SendParameters{
            to: self.managerAddress, 
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: true,
            body: DecreaseTotalStable{
                user: msg.user,
                amount: msg.amount
            }.toCell()
        }); 
        
    }

    /*03 | Burn usdTON */
    receive(msg: BurnUsdTONMessage) {
        require(sender() == self.managerAddress, "not from positionsManager");
        let amountToBurn: Int = msg.amount;
        // let factDebtInStables: Int = self.debt * msg.rate.debtAccumulatedRate / 1000000000;
        // dump("check healthy");
        // if (!self.isPositionHealthy(self.collateral, self.debt, msg.tonPriceWithHealthRate, msg.rate.debtAccumulatedRate)){
        //     self.unhealthyPositionHandler(msg.user);
        //     return;
        // } 
        // dump("position healthy");

        // todo add bounced handler in sender to pay ctx.value back to sender
        if (self.debt < msg.amount) {
            self.setMessage("Your debt is less than you want to repay, charge sent back");
            amountToBurn = self.debt;
        }

        self.setMessage("stables are going to burn...");

        send(SendParameters{
            to: self.usdTonAddress, 
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors, 
            bounce: true,
            body: BurnBurnMessage{
                user: msg.user,
                amount: amountToBurn,
                rate: msg.rate,
                userPosition: myAddress()
            }.toCell()
        });
    }


    /*04 | Возврат обеспечения (from positionsManager)'*/
    receive(msg: WithdrawCollateralMessage) {
        require(sender() == self.managerAddress, "not from positions manager");

        if (msg.amount  > self.collateral) {
            self.setMessage("withdrawal amount more than position has");
            // pay excess to user
            send(SendParameters{
                to: msg.user,
                bounce: false,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors
            });
            return;
        }

        let collateralAfterWithdraw: Int = self.collateral - msg.amount;

        // dump("check healthy");
        // if (!self.isPositionHealthy(collateralAfterWithdraw, self.debt, msg.tonPriceWithHealthRate, msg.rate.debtAccumulatedRate)){
        //     self.unhealthyPositionHandler(msg.user);
        //     return;
        // } 
        // dump("position healthy");
        

        self.collateral = collateralAfterWithdraw;
        self.setMessage("collateral sent back to yor wallet");

        send(SendParameters{
            to: self.managerAddress, 
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors, 
            bounce: true,
            body: DoWithdrawCollateral{
                user: msg.user,
                amount: msg.amount
            }.toCell()
        });
    }
    //=============================================================================
    // Helpers
    //=============================================================================

    fun isPositionHealthy(collateral: Int, debt: Int, tonPriceWithHealthRate: Int, debtRate: Int): Bool {
        // todo rewrite healh calculation to loanToValue ratio
        dump("collateral");
        dump(collateral);
        dump("debt");
        dump(debt);
        dump("tonPriceWithHealthRate");
        dump(tonPriceWithHealthRate);
        dump("debtRate"); 
        dump(debtRate);
        // 1000000000 * 0 / 1000000000 / 1000000000
        // todo normalize debt to stables
        let normalizedDebt: Int = debt * 1000000000 / debtRate;
        dump("isPositionHealthy.normalizedDebt");
        dump(normalizedDebt);
        let collateralPriceWithSafetyMargin: Int = collateral * tonPriceWithHealthRate / 1000000000;
        dump("isPositionHealthy.collateralPriceWithSafetyMargin");
        dump(collateralPriceWithSafetyMargin);
        return  collateralPriceWithSafetyMargin >= debt;
    }

    fun unhealthyPositionHandler(user: Address) {
            self.setMessage("position is not healthy");
            dump("position is not healthy");
            // pay excess to user
            send(SendParameters{
                to: user,
                bounce: false,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors
            });
    }

    fun setMessage(msg: String) {
        let updatedMessage: Message = Message{
            timestamp: now(),
            message: msg
        };
        self.message = updatedMessage;
    }

    //=============================================================================
    // Offchain interface
    //=============================================================================
    get fun positionUser(): Address {
        return self.user;
    }

    get fun positionState(): PositionState  {
        return PositionState{
            collateral: self.collateral,
            debt: self.debt
        };
    }

    get fun message(): Message {
        return self.message;
    }
}