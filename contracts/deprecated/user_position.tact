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

struct LiquidationParams {
    tonForBurn: Int as uint64;
    fee: Int as uint64;
    accountBalance: Int as uint64;
    liquidationAmount: Int as uint64;
    liquidationDebt: Int as uint64;
    feeDebt: Int as uint64;
    tonPrice: Int as uint64;
}

contract UserPosition  {
    const MinTonsForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    user: Address;
    usdTonAddress: Address;
    managerAddress: Address;
    poolAddress: Address;

    debt: Int = 0;
    message: Message;
    
    liquidationParams: LiquidationParams;

    init(user: Address, usdTonAddress: Address, managerAddress: Address, poolAddress: Address) {
        self.user = user; 
        self.usdTonAddress = usdTonAddress;

        self.managerAddress = managerAddress;
        self.poolAddress = poolAddress;

        self.message = Message{
            timestamp: 0,
            message: "Position Created"
        };
        
        self.liquidationParams = LiquidationParams{
            tonForBurn: 0,
            fee: 0,
            accountBalance: 0,
            liquidationAmount: 0,
            liquidationDebt: 0,
            feeDebt: 0,
            tonPrice: 0
    };

        send(SendParameters{
            to: self.managerAddress, 
            mode: SendIgnoreErrors,
            // how much we should send to this contract? 
            // how to pay for storage for this contract later? 
            // we have no more writes in position address contract ever
            value: ton("0.01"), 
            bounce: true,
            body: AddPositionId{
                user: user
            }.toCell()
        });
    }


    //=============================================================================
    // Actions
    //=============================================================================
    receive(msg: DepositCollateralMessage) {
        require(sender() == self.managerAddress, "not from positionsManager");
        
        let ctx: Context = context();
        let remainingValue: Int = ctx.value - (msg.amount + self.MinTonsForStorage + ctx.readForwardFee());
 
        
        self.setMessage("Collateral added");
        let comment: StringBuilder = beginString();
        comment.append("Colleteral was added: ");
        comment.append(msg.amount.toString());
  
        send(SendParameters{to: msg.user, 
            bounce: false, 
            value: remainingValue, 
            mode: SendIgnoreErrors + SendPayGasSeparately, 
            body: comment.toString().asComment()
        });
    }



    /*02 | Mint usdTON */
    receive(msg: MintUsdTon) {
        require(sender() == self.managerAddress, "not from position Manager");

        let debtAfterWithdraw: Int = (self.debt + msg.amount);

        if (!self.isPositionHealthy(myBalance(), debtAfterWithdraw, msg.tonPrice, msg.settings)) {
            self.unhealthyPositionHandler(msg.user);
            return;
        }
        let stabilityFee: Int = msg.amount * 50000000 / msg.tonPrice;

        let ctx: Context = context();
        
        let fwdFee: Int = ctx.readForwardFee();

        // Отправка stability fee в пул
        send(SendParameters{to: self.poolAddress, 
            bounce: true, 
            value: stabilityFee, 
            mode: SendPayGasSeparately + SendIgnoreErrors, 
            body: StabilityFeePayment{amount: stabilityFee, user: msg.user}.toCell()
        });

        send(SendParameters{
            to: self.usdTonAddress, 
            value: 0,
            mode: (SendRemainingValue + SendBounceIfActionFail), 
            bounce: true,
            body: MintMessage{
                user: msg.user,
                amount: msg.amount
            }.toCell()
        });

        self.debt = debtAfterWithdraw;
        self.setMessage("UsdToncoins sent");
    }
    /*03 | Burn usdTON */
    receive(msg: BurnUsdTONMessage) {
        require(sender() == self.managerAddress, "not from position manager");
        let amountToBurn: Int = msg.amount;

        // todo add bounced handler in sender to pay ctx.value back to sender
        if (self.debt < msg.amount) {
            self.setMessage("Your debt is less than you want to repay, charge sent back");
            amountToBurn = self.debt;
        }


        let fee: Int = amountToBurn * 50000000 / msg.tonPrice;
        // todo add bounced handler in sender to pay ctx.value back to sender
        if (myBalance() - (self.GasConsumption + self.MinTonsForStorage) < fee) {

        send(SendParameters{to: self.user, 
            bounce: false, 
            value: 0, 
            mode: SendRemainingValue, 
            body: "Your balance is less than service fee".asComment()
        });
        return;
        }

        self.setMessage("stables are going to burn...");

        // Отправка комиссии в пул
        send(SendParameters{to: self.poolAddress, 
            bounce: true, 
            value: fee, 
            mode: SendPayGasSeparately + SendIgnoreErrors, 
            body: FeePayment{amount: fee, user: msg.user}.toCell()
        });

        // Сжигание
        send(SendParameters{
            to: self.usdTonAddress, 
            value: ton("0.04"),
            mode:  SendIgnoreErrors, 
            bounce: true,
            body: BurnMessage {
                user: msg.user,
                amount: amountToBurn,
                userPosition: myAddress()
            }.toCell()
        });
    }

    /*03 |from usdTonMaster'*/
    receive(msg: UsdTonBurned) {
        require(sender() == self.usdTonAddress, "not from usdTon");

        // todo check if debt still more than repayment
        self.debt = self.debt - msg.amount;

        if (self.message.message == "liquidationProcess") {
        self.setMessage("position liquidated");
        // Отчисление остатков после ликвидации в пул
        send(SendParameters{
            to: self.poolAddress, 
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
        });
        } else {
        self.setMessage("you've paid stables back");
         // возврат пользователю остатков газа при сжигании
        send(SendParameters{
            to: msg.user, 
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false,
            body: self.message.message.asComment()
        });
        }
    }

    /*04 | Возврат обеспечения (from manager)'*/
    receive(msg: WithdrawCollateralMessage) {
        require(sender() == self.managerAddress, "not from positions manager");

        if (msg.amount > myBalance() + (self.GasConsumption + self.MinTonsForStorage)) {
            send(SendParameters{
                to: msg.user,
                bounce: false,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "withdrawal amount more than position has".asComment()
            });
            return;
        }
        if (!self.isPositionHealthy(myBalance() - msg.amount, self.debt, msg.tonPrice, msg.settings)) {
            self.unhealthyPositionHandler(msg.user);
            return;
        }
        send(SendParameters{
            to: msg.user, 
            bounce: false, 
            value: msg.amount, 
            mode: SendPayGasSeparately
        });
        self.setMessage("collateral sent back to yor wallet");
    }
    
    /*05 | Ликвидация (from manager)'*/
    receive(msg: PositionLiquidation) {
        require(sender() == self.managerAddress, "not from positions manager");
        //проверка попадания позиции под ликвидацию
        if ((myBalance() - self.GasConsumption - self.MinTonsForStorage) * msg.tonPrice / self.debt >= msg.settings.liquidationRatio) {
            send(SendParameters{
                to: sender(),
                bounce: false,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "liquidation error: Position is healthy".asComment()
            });
            return;
        }

        let tonForBurn: Int = self.debt / (msg.tonPrice / 1000000000);

        let liquidationAmount: Int = self.debt;
        let liquidationDebt: Int = 0;
        let accountBalance: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption + ton("0.15"));
        // если невозможно оплатить всю позицию рассчитывается задолженность по ней
        if (accountBalance < tonForBurn) {
          liquidationDebt = liquidationAmount - ((accountBalance * msg.tonPrice) / 1000000000);
          tonForBurn = accountBalance;
        }

        self.setMessage("liquidationProcess");

        // записываем параметры ликвидации
        self.setLiquidationParams(LiquidationParams{
            tonForBurn: tonForBurn,
            fee: 0,
            accountBalance: accountBalance,
            liquidationAmount: liquidationAmount - liquidationDebt,
            liquidationDebt: liquidationDebt,
            feeDebt: 0,
            tonPrice: msg.tonPrice
        });

        // покупка usdton для последующего сжигания
        send(SendParameters {
            to: self.usdTonAddress, 
            value: ton("0.12"),
            bounce: true,
            body: DexMessage{
                user: myAddress(),
                amount: liquidationAmount - liquidationDebt
            }.toCell()
        });

        send(SendParameters{to: self.poolAddress, 
            bounce: false, 
            value: self.liquidationParams.tonForBurn, 
            mode: SendPayGasSeparately, 
            body: StabilityFeePayment {
                amount: self.liquidationParams.tonForBurn, 
                user: self.user
            }.toCell()
        });
    }

    receive(msg: DexNotification) {
        // сжигание купленных токенов с кошелька позиции
        send(SendParameters {
            to: self.usdTonAddress, 
            value: ton("0.04"),
            body: BurnMessage {
                user: myAddress(),
                amount: msg.amount,
                userPosition: myAddress()
            }.toCell()
        });

        // считаем комиссию 5%
        let fee: Int =  ( (self.liquidationParams.liquidationAmount - self.liquidationParams.liquidationDebt) * 50000000) /  self.liquidationParams.tonPrice;
        let feeDebt: Int = 0;


        let accountBalance: Int = myBalance() - ton("0.02");
        // расчет наличия долга по комиссии
        if (fee > accountBalance) {
            fee = accountBalance;
            feeDebt = fee - accountBalance;
        }

        self.setLiquidationParams(LiquidationParams{
            tonForBurn: self.liquidationParams.tonForBurn,
            fee: fee,
            accountBalance: self.liquidationParams.accountBalance,
            liquidationAmount: self.liquidationParams.liquidationAmount,
            liquidationDebt: self.liquidationParams.liquidationDebt,
            feeDebt:  feeDebt,
            tonPrice: self.liquidationParams.tonPrice,
        });
        

        //отправка всего ton в pool комиссии
        send(SendParameters{to: self.poolAddress, bounce: false, value: 0, mode: SendRemainingBalance, body: FeePayment{amount: fee, user: myAddress()}.toCell()});
    }

    receive(msg: TokenExcesses) {
        // для приема оставшегося ton после имитации операций на dex или с любых контрактов
    }


    //=============================================================================
    // Helpers
    //=============================================================================

    fun isPositionHealthy(collateral: Int, debt: Int, tonPrice: Int, settings: PoolSettings): Bool {
        let collateralPriceWithHR: Int = collateral * (tonPrice / settings.minHealthRate );
        return  collateralPriceWithHR >= debt;
    }

    fun unhealthyPositionHandler(user: Address) {
            self.setMessage("position is not healthy");
            // pay excess to user
            send(SendParameters{
                to: user,
                bounce: false,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "position is not healthy".asComment()
            });
    }

    fun setMessage(msg: String) {
        let updatedMessage: Message = Message{
            timestamp: now(),
            message: msg
        };
        self.message = updatedMessage;
    }

    fun setLiquidationParams(params: LiquidationParams) {
        self.liquidationParams = params;
    }

    //=============================================================================
    // Offchain interface
    //=============================================================================
    get fun positionUser(): Address {
        return self.user;
    }

    get fun positionState(): PositionState  {
        return PositionState{
            collateral: myBalance(),
            debt: self.debt
        };
    }

    get fun message(): Message {
        return self.message;
    }

    get fun liquidationParams(): LiquidationParams {
        return self.liquidationParams;
    }
}