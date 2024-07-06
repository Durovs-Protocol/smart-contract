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
    tonForFee: Int as uint64;
    accountBalance: Int as uint64;
    liquidationAmount: Int as uint64;
    liquidationDebt: Int as uint64;
    feeDebt: Int as uint64;
    runePrice: Int as uint64;
}

contract UserPosition  {
    const MinTonsForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.02");
    user: Address;
    usdTonAddress: Address;
    runecoinAddress: Address;
    managerAddress: Address;
    poolAddress: Address;
    collateral: Int as coins = 0;
    debt: Int = 0;
    message: Message;
    liquidationParams: LiquidationParams;

    init(user: Address, usdTonAddress: Address, managerAddress: Address, poolAddress: Address, runecoinAddress: Address) {
        self.user = user; 
        self.usdTonAddress = usdTonAddress;
        self.runecoinAddress = runecoinAddress;

        self.managerAddress = managerAddress;
        self.poolAddress = poolAddress;

        self.message = Message{
            timestamp: 0,
            message: "Position Created"
        };
        self.liquidationParams = LiquidationParams{
            tonForBurn: 0,
    tonForFee: 0,
    accountBalance: 0,
    liquidationAmount: 0,
    liquidationDebt: 0,
    feeDebt: 0,
    runePrice: 0
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
        let remainingValue: Int = (ctx.value - ((msg.amount + self.MinTonsForStorage) + self.GasConsumption));

        send(SendParameters{to: msg.user, bounce: false, value: remainingValue, mode: SendIgnoreErrors});

        self.collateral = self.collateral + msg.amount;
        self.setMessage("Collateral added");
        self.reply("Colleteral was added".asComment());
    }



    /*02 | Mint usdTON */
    receive(msg: MintUsdTon) {
        require(sender() == self.managerAddress, "not from position Manager");



        let debtAfterWithdraw: Int = (self.debt + msg.amount);



        if (!self.isPositionHealthy(self.collateral, debtAfterWithdraw, msg.tonPriceWithHealthRate, msg.settings)){
            self.unhealthyPositionHandler(msg.user);
            return;
        } 


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

        self.setMessage("stables are going to burn...");

        // send(SendParameters {
        //         to: msg.runecoinWallet,
        //         value: ton("0.1"),
        //         mode: SendBounceIfActionFail,
        //         bounce: true,
        //         body: TokenTransfer{
        //             queryId: 0,
        //             amount: msg.amount * 2 / 100,
        //             destination: self.poolAddress,
        //             responseDestination: myAddress(),

        //             customPayload: createOffchainContent("custom"),
        //             forwardTonAmount: 0,
        //             forwardPayload: createOffchainContent("forward").asSlice()
        //         }.toCell()
        //     }
        // );

        send(SendParameters{
            to: self.usdTonAddress, 
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors, 
            bounce: true,
            body: BurnMessage{
                user: msg.user,
                amount: amountToBurn,
                userPosition: myAddress()
            }.toCell()
        });
    }

    /*03 |from usdTonMaster'*/
    receive(msg: UsdTonWereBurned) {

        require(sender() == self.usdTonAddress, "not from usdTon");

        // todo check if debt still more than repayment
        self.debt = self.debt - msg.amount;

        if (self.message.message == "liquidationProcess") {
            self.setMessage("position liquidated");
        } else {
            self.setMessage("you've paid stables back");
        }

        send(SendParameters{
            to: self.managerAddress, 
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: true,
            body: DecreaseTotalUsdTon {
                user: msg.user,
                amount: msg.amount
            }.toCell()
        });
    }

    /*04 | Возврат обеспечения (from manager)'*/
    receive(msg: WithdrawCollateralMessage) {
        require(sender() == self.managerAddress, "not from positions manager");

        if (msg.amount  > self.collateral) {
            send(SendParameters{
                to: msg.user,
                bounce: false,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "withdrawal amount more than position has".asComment()
            });
            return;
        }

        let collateralAfterWithdraw: Int = self.collateral - msg.amount;


        if (!self.isPositionHealthy(collateralAfterWithdraw, self.debt, msg.tonPriceWithHealthRate, msg.settings)) {
            self.unhealthyPositionHandler(msg.user);
            return;
        }

        send(SendParameters{to: msg.user, bounce: false, value: msg.amount, mode:  SendIgnoreErrors + SendPayGasSeparately });

        self.collateral = collateralAfterWithdraw;
        self.setMessage("collateral sent back to yor wallet");

    }
    /*05 | Ликвидация (from manager)'*/
    receive(msg: PositionLiquidation) {
        require(sender() == self.managerAddress, "not from positions manager");


        if (self.isPositionHealthy(self.collateral, self.debt, msg.tonPriceWithHealthRate, msg.settings)) {
            send(SendParameters{
                to: sender(),
                bounce: false,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "liquidation error: Position is healthy".asComment()
            });
            return;
        }


        let tonForBurn: Int = (self.debt / msg.tonPrice) * 1000000000;
        // тон нужно для покупки тех usdton что взял пользователь
        let tonForFee: Int = tonForBurn * msg.settings.liquidationFee / 1000000000;
        // тон нужно для покупки тех usdton что взял пользователь
        let accountBalance: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption);
        let liquidationAmount: Int = self.debt;
        let liquidationDebt: Int = 0;
        // если невозможно оплатить всю позицию рассчитывается задолженность по ней
        if (accountBalance < tonForBurn) {
          liquidationDebt = liquidationAmount - ((accountBalance * msg.tonPrice) / 1000000000);
        // tonForBurn = accountBalance;
        }

        self.setMessage("liquidationProcess");

        // записываем параметры ликвидации
        self.setLiquidationParams(LiquidationParams{
            tonForBurn: tonForBurn,
            tonForFee: tonForFee,
            accountBalance: accountBalance,
            liquidationAmount: liquidationAmount,
            liquidationDebt: liquidationDebt,
            feeDebt: 0,
            runePrice: msg.runePrice
        });

        // покупка usdton для последующего сжигания
        send(SendParameters {
            to: self.usdTonAddress, 
            value: 0,
            mode: SendRemainingValue, 
            bounce: true,
            body: DexMessage{
                user: myAddress(),
                amount: liquidationAmount - liquidationDebt
            }.toCell()
        });
    }

    receive(msg: DexNotification) {
        // сжигание купленных токенов с кошелька позиции
        send(SendParameters {
            to: self.usdTonAddress, 
            value: ton("0.06"),
            body: BurnMessage {
                user: myAddress(),
                amount: msg.amount,
                userPosition: myAddress()
            }.toCell()
        });

        // оплата комиссии
        let feeDebt: Int = 0;
        let accountBalance: Int = myBalance() - ton("0.8");
        // расчет наличия долга по комиссии
        if (self.liquidationParams.tonForFee > accountBalance) {
            feeDebt = self.liquidationParams.tonForFee - accountBalance;

        // обновляем значение feeDebt в параметрах ликвидации если оно изменилось
        self.setLiquidationParams(LiquidationParams{
            tonForBurn: self.liquidationParams.tonForBurn,
            tonForFee: self.liquidationParams.tonForFee,
            accountBalance: self.liquidationParams.accountBalance,
            liquidationAmount: self.liquidationParams.liquidationAmount,
            liquidationDebt: self.liquidationParams.liquidationDebt,
            feeDebt: feeDebt,
            runePrice:self.liquidationParams.runePrice,
        });
        }
        // расчет количества рун для передачи в пул
        let runesAmount: Int = ((self.liquidationParams.tonForFee  - feeDebt) / (self.liquidationParams.runePrice / 1000000000));

        // покупка runecoin для передачи в пул
        send(SendParameters {
            to: self.runecoinAddress, 
            value: ton("0.06"), 
            mode: SendBounceIfActionFail, 
            bounce: true,
            body: DexMessage {
                user: myAddress(),
                amount: runesAmount
            }.toCell()
        });
    }

    receive(msg: TokenExcesses) {
        // для приема оставшегося ton после имитации операций на dex
    }

    receive(msg: RuneDexNotification) {
        send(SendParameters{
                to: msg.wallet,
                value: ton("0.08"), 
                mode: SendBounceIfActionFail,
                bounce: true,
                body: TokenTransfer{
                    queryId: 0,
                    amount: msg.amount,
                    destination: self.poolAddress,
                    responseDestination: myAddress(),
                    customPayload: createOffchainContent("custom"),
                    forwardTonAmount: 0,
                    forwardPayload: createOffchainContent("forward").asSlice()
                }.toCell()
            }
        ); 
        //отправка ton тестировщику (после замены на реальные операции с покупкой на dex убрать)
        send(SendParameters{to: self.user, bounce: false, value: 0, mode: (SendRemainingBalance + SendIgnoreErrors)});
    }
    //=============================================================================
    // Helpers
    //=============================================================================

    fun isPositionHealthy(collateral: Int, debt: Int, tonPriceWithHealthRate: Int, settings: PoolSettings): Bool {
        let collateralPriceWithSafetyMargin: Int = collateral * tonPriceWithHealthRate / 1000000000;
        return  collateralPriceWithSafetyMargin >= debt;
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
            collateral: self.collateral,
            debt: self.debt
        };
    }

    get fun message(): Message {
        return self.message;
    }
        get fun comment(): LiquidationParams {
        return self.liquidationParams;
    }
}