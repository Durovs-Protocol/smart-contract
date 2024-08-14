import "./utils/messages.tact";
import "./utils/helpers.tact";


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
    accrualedJettons: Int = 0;
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
    /*01 | Supply TON */
    // receive(msg: SupplyNotification) {
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
    receive(msg: Supply) {

        // require(sender() == self.manager, "Runa protocol: not from positions manager");
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

    bounced(msg: bounced<Supply>) {
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
            body: MintRequest{
                user: msg.user,
                amount: msg.amount,
                notificationAddress: myAddress(),
            }.toCell()
        });

        self.setMessage("UsdToncoins sent");
    }

    receive(msg: OnMintComplete) {
        let comment: StringBuilder = beginString();

        self.debt += msg.amount;
        comment.append("Runa Protocol: You have minted");
        comment.append(msg.amount.toString());
     
        send(SendParameters {
            to: self.user, 
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false,
            body: comment.toString().asComment()
        });
    }

    bounced(msg: bounced<MintRequest>) {
        self.bouncedHandler();
    }

    /*03 | Burn usdTON */
    receive(msg: BurnUsdTon) {
        require(sender() == self.manager, "not from position manager");

        let amountToBurn: Int = msg.amount;
        // todo add bounced handler in sender to pay ctx.value back to sender
        if (self.debt < msg.amount) {
            self.setMessage("Your debt is less than you want to repay, charge sent back");
            amountToBurn = self.debt;
        }
        if (amountToBurn < ((msg.settings.burnMin * 1000000000) / msg.tonPrice)) {
            send(SendParameters {
                to: self.user, 
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: false,
                body: "Your debt is less than minimum possible".asComment()
            });
            return;
        }
        

        let withdrawalAmount: Int = (msg.amount * msg.settings.reserveRatio) /  msg.tonPrice;

        self.setMessage("stables are going to burn...");
        // осталвяем средства для оплаты комиссии на балансе, также оставляем средства для оплаты газа 
        let remainingValue: Int = myBalance() - (msg.fee + self.MinTonsForStorage + (self.GasConsumption * 2)); 

        send(SendParameters{
            to: self.usdton, 
            value: remainingValue,
            bounce: true,
            mode: SendBounceIfActionFail,
            body: BurnRequest {
                user: msg.user,
                amount: amountToBurn,
                withdrawalAmount: withdrawalAmount,
                fee: msg.fee,
                notificationAddress: myAddress()
            }.toCell()
        });
    }
    bounced(msg: bounced<BurnRequest>) {
        self.bouncedHandler();
    }
    receive(msg: OnBurnComplete) {

    if (self.message.message == "liquidation process") {
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

    } else {
        self.debt = self.debt - msg.usdton;
    let remainingValue: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption + msg.fee); 
    send(SendParameters{to: self.profitPool, value: msg.fee + remainingValue,  bounce: false, body: FeePayment{amount: msg.fee, user: self.user}.toCell()});
    }
    }

    
    receive(msg: Withdraw) {
        require(sender() == self.manager, "not from position manager");

        let collateralAfterWithdraw: Int = self.collateral - msg.amount;
        
        if (!self.isHealthyForWithdraw(collateralAfterWithdraw, self.debt, msg.tonPrice, msg.settings)) {
            self.unhealthyPositionHandler(msg.user);
            return;
        }

        let remainingValue: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption); 
        send(SendParameters{
            to: self.reservePool,
            value: remainingValue,
            bounce: true,
            mode: SendBounceIfActionFail,
            body: WithdrawRequest {
                amount: msg.amount,
                user: self.user,
            }.toCell()
        });
    }

    receive(msg: WithdrawResponce) {
    self.collateral -=  msg.amount;

    let ctx: Context = context();
    let remainingValue: Int = ctx.value - (self.MinTonsForStorage + (self.GasConsumption * 2) + msg.amount); 
    send(SendParameters{to: self.user, value: msg.amount, mode: SendIgnoreErrors + SendPayGasSeparately, bounce: false});
    send(SendParameters{to: self.user, value: remainingValue, bounce: false});
    }


    bounced(msg: bounced<Withdraw>) {
        self.bouncedHandler();
    }
        /*05 | Ликвидация (from manager)'*/
    receive(msg: PositionLiquidation) {
        require(sender() == self.manager, "Runa protocol: not from positions manager");
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
        self.setMessage("liquidation process");

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
            body: DoLiquidation{
                position: myAddress(),
                user: self.user,
                price: tonForBurn,
                amount: liquidationAmount - liquidationDebt,
            }.toCell()
        });

    }
    
    
    receive(msg: TokenExcesses) {
    }
    
    receive(msg: AccrualJetton) {

        let myPercent: Int = self.collateral * 1000000000 / msg.total;
        let myPart: Int = (myPercent * msg.total) / 1000000000;
        let comment: StringBuilder = beginString();
        comment.append("Runa protokol: you recieved runa-usdton:");
        comment.append(self.accrualedJettons.toString());
        self.accrualedJettons += myPart;
            send(SendParameters{
                to: self.user,
                bounce: false,
                value: 0,
                mode: SendIgnoreErrors ,
                body: comment.toString().asComment()
            }
            
        );
    }
    receive(msg: GetAccrual) {
        require(sender() == self.manager, "not from position Manager");
        send(SendParameters{
            to: self.usdton, 
            value: 0,
            mode: (SendRemainingValue + SendBounceIfActionFail), 
            bounce: true,
            body: AccrualMessage {
                user: self.user,
                amount: self.accrualedJettons,
                notificationAddress: myAddress(),
            }.toCell()
        });

        self.setMessage("UsdToncoins sent");
    }
    
    receive(msg: OnAccrualComplete) {
        let comment: StringBuilder = beginString();

        self.accrualedJettons = 0;
        comment.append("Runa Protocol: You have recieved incentive payment:");
        comment.append(msg.amount.toString());
        
        send(SendParameters {
            to: self.user, 
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false,
            body: comment.toString().asComment()
        });
    }
    
    //=============================================================================
    // Helpers
    //=============================================================================

    fun isHealthyForMint(collateral: Int, debt: Int, tonPrice: Int, settings: Settings): Bool {
        if (collateral == 0) {
            return false;
        }
        return (collateral * tonPrice / 1000000000)  >= debt * settings.reserveRatio / 1000000000;
    }
    fun isHealthyForWithdraw(collateral: Int, debt: Int, tonPrice: Int, settings: Settings): Bool {
        if (debt == 0) {
            return true;
        }
        
        return collateral * tonPrice / self.debt >= settings.liquidationRatio;
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
    get fun maxForWithdraw(tonPrice: Int, liquidationRatio: Int): Int {
        if (self.debt == 0) {
            return self.collateral;
        } else {
            let debtRatio: Int = self.collateral * tonPrice / self.debt;
            if (debtRatio < liquidationRatio) {
                return 0;
            } else {
                return ((debtRatio - liquidationRatio) * self.collateral) / 1000000000;
            }
        }
    }
    get fun maxForMint(tonPrice: Int, reserveRatio: Int): Int {

        if (self.debt == 0) {
            return self.collateral * tonPrice / reserveRatio;
        } else {
           let collateralInUsd: Int = self.collateral * tonPrice / 1000000000;
           return (collateralInUsd  * 1000000000) / reserveRatio;
        }
    }
    get fun maxForBurn(): Int {
        return self.debt;
    }
        get fun message(): Message {
        return self.message;
    }
}