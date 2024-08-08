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
    usdton: Address;
    manager: Address;
    reservePool: Address;
    profitPool: Address;
    debt: Int;
    debtBeforeBurn: Int = 0;
    collateral: Int;
    collateralBefore: Int = 0;
    message: Message;
    liquidationParams: LiquidationParams;


    init(user: Address, usdton: Address, manager: Address, reservePool: Address, profitPool: Address) {
        self.user = user; 
        self.usdton = usdton;

        self.manager = manager;
        self.reservePool = reservePool;
        self.profitPool = profitPool;


        self.collateral = 0;
        self.debt = 0;

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
            to: self.manager, 
            mode: SendIgnoreErrors,
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
    /*01 | Deposit TON */
    // receive(msg: DepositNotification) {
    //     require(sender() == self.reservePool, "not from reserve pool");
    //     self.collateral = self.collateral + msg.amount;
    //     let remainingValue: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption);
        
    //     send(SendParameters{
    //         to: msg.user, 
    //         bounce: false, 
    //         value: remainingValue, 
    //         body: "Collateral added".asComment()
    //     });
    // }
    receive(msg: DepositCollateralMessage) {

        // require(sender() == self.manager, "not from positionsManager");
        let remainingValue: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption);
        if (remainingValue < msg.amount) {
            self.errorHandler("not enough tone for deposit and service fee");
            return;
        }
        send(SendParameters{
                to: self.reservePool,
                bounce: true,
                value: remainingValue,
                body: msg.toCell(),
            }
        );
        self.collateralBefore = self.collateral;
        self.collateral = self.collateral + msg.amount;
    }

    bounced(msg: bounced<DepositCollateralMessage>) {
        self.collateral = self.collateralBefore;
        self.bouncedHandler();
    }

    /*02 | Mint usdTON */
    receive(msg: MintUsdTon) {
        require(sender() == self.manager, "not from position Manager");

        let debtAfterWithdraw: Int = (self.debt + msg.amount);

        if (!self.isHealthyForMint(self.collateral, debtAfterWithdraw, msg.tonPrice, msg.settings)) {
            self.unhealthyPositionHandler(msg.user);
            return;
        } 

        send(SendParameters{
            to: self.usdton, 
            value: 0,
            mode: (SendRemainingValue + SendBounceIfActionFail), 
            bounce: true,
            body: MintMessage{
                user: msg.user,
                amount: msg.amount,
                notificationAddress: myAddress()
            }.toCell()
        });

        self.setMessage("UsdToncoins sent");
    }

    receive(msg: OnMintComplete) {
        self.debt += msg.amount;
    }
    bounced(msg: bounced<MintMessage>) {
        self.bouncedHandler();
    }

    /*03 | Burn usdTON */
    receive(msg: BurnUsdTONMessage) {
        require(sender() == self.manager, "not from position manager");

        if (self.debt < ((msg.settings.burnMin * 1000000000) / msg.tonPrice)) {
            send(SendParameters {
                to: self.user, 
                value: 0,
                bounce: false,
                mode: SendIgnoreErrors,
                body: "Your debt is less than minimum possible".asComment()
            });
            return;
        }
        let amountToBurn: Int = msg.amount;
        // todo add bounced handler in sender to pay ctx.value back to sender
        if (self.debt < msg.amount) {
            self.setMessage("Your debt is less than you want to repay, charge sent back");
            amountToBurn = self.debt;
        }


        let withdrawalAmount: Int = (msg.amount * msg.settings.reservePool) /  msg.tonPrice;

        self.setMessage("stables are going to burn...");
        // осталвяем средства для оплаты комиссии на балансе, также оставляем средства для оплаты газа 
        let remainingValue: Int = myBalance() - (msg.fee + self.MinTonsForStorage + (self.GasConsumption * 2)); 

        send(SendParameters{
            to: self.usdton, 
            value: remainingValue,
            bounce: true,
            mode: SendBounceIfActionFail,
            body: BurnMessage {
                user: msg.user,
                amount: amountToBurn,
                reservePool: self.reservePool,
                withdrawalAmount: withdrawalAmount,
                fee: msg.fee,
                notificationAddress: myAddress()
            }.toCell()
        });
    }

    receive(msg: OnBurnComplete) {
        self.debt = self.debt - msg.usdton;
        // self.collateral = self.collateral - msg.ton; TODO: должно быть в выводе
        let unusedTonFee: Int = myBalance() - (msg.ton + msg.fee + self.MinTonsForStorage + (self.GasConsumption * 2));
        send(SendParameters{
            to: self.user,
            value: msg.ton + unusedTonFee,
            mode: SendIgnoreErrors + SendPayGasSeparately,
            bounce: false
        });
        send(SendParameters{
            to: self.profitPool,
            value: msg.fee,
            mode: SendPayGasSeparately,
            bounce: false,
            body: FeePayment{amount: msg.fee}.toCell()
        });
    }

    bounced(msg: bounced<BurnMessage>) {
        self.bouncedHandler();
    }
        /*05 | Ликвидация (from manager)'*/
    receive(msg: PositionLiquidation) {
        require(sender() == self.manager, "not from positions manager");
        //проверка попадания позиции под ликвидацию
        if (self.isLiquid(self.collateral, self.debt, msg.tonPrice, msg.settings)) {
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
        // TODO убрать эти вычитания 
        let accountBalance: Int = self.collateral - (self.MinTonsForStorage + self.GasConsumption);
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

        // передаем сообщение о ликвидации в пул
        send(SendParameters {
            to: self.reservePool, 
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: LiquidationPool{
                position: myAddress(),
                user: self.user,
                price: tonForBurn,
                amount: liquidationAmount - liquidationDebt,
            }.toCell()
        });

    }
    
    receive(msg: OnLiquidationComplete) {
        self.collateral = 0;
        self.debt = 0;

        let remainingValue: Int = myBalance() - self.MinTonsForStorage;

        send(SendParameters {
                to: self.profitPool,
                bounce: false,
                value: remainingValue,
                body: "position liquidated".asComment()
            }
        );
    }
    
    receive(msg: TokenExcesses) {
        self.collateral = self.collateralBefore;
    }


    //=============================================================================
    // Helpers
    //=============================================================================

    fun isHealthyForMint(collateral: Int, debt: Int, tonPrice: Int, settings: Settings): Bool {
        return (collateral * tonPrice / 1000000000)  >= debt * settings.reservePool / 1000000000;
    }
    fun isLiquid(collateral: Int, debt: Int, tonPrice: Int, settings: Settings): Bool {
        return collateral * tonPrice / self.debt >= settings.liquidationRatio;
    }
    fun setLiquidationParams(params: LiquidationParams) {
        self.liquidationParams = params;
    }
    fun bouncedHandler() {
        send(SendParameters{
                to: self.user,
                bounce: false,
                value: 0,
                mode:  SendRemainingValue + SendIgnoreErrors ,
                body: "error".asComment()
            }
        );
    }
    fun errorHandler(comment: String) {
        send(SendParameters{
                to: self.user,
                bounce: false,
                value: 0,
                mode:  SendRemainingValue + SendIgnoreErrors ,
                body: comment.asComment()
            }
        );
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


    //=============================================================================
    // Offchain interface
    //=============================================================================
    get fun positionUser(): Address {
        return self.user;
    }
    get fun getLiquidationParams(): LiquidationParams {
        return self.liquidationParams;
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