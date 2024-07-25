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
    receive(msg: DepositCollateralMessage){
        require(sender() == self.manager, "not from positionsManager");
        let remainingValue: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption);
        send(SendParameters{
                to: self.reservePool,
                bounce: false,
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
        self.debtBeforeBurn = self.debt;

        if (!self.isPositionHealthy(self.collateral, debtAfterWithdraw, msg.tonPrice, msg.settings)) {
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
                amount: msg.amount
            }.toCell()
        });

        self.debt = debtAfterWithdraw;
        self.setMessage("UsdToncoins sent");
    }
    bounced(msg: bounced<MintMessage>) {
        self.debt = self.debtBeforeBurn;
        self.bouncedHandler();
    }

    /*03 | Burn usdTON */
    receive(msg: BurnUsdTONMessage) {
        require(sender() == self.manager, "not from position manager");
        let amountToBurn: Int = msg.amount;
        // todo add bounced handler in sender to pay ctx.value back to sender
        if (self.debt < msg.amount) {
            self.setMessage("Your debt is less than you want to repay, charge sent back");
            amountToBurn = self.debt;
        }

        self.debtBeforeBurn = self.debt;
        self.collateralBefore = self.collateral;
        let collateralForWithdrawal: Int = (msg.amount * 1000000000) /  msg.tonPrice;

        self.setMessage("stables are going to burn...");
        let remainingValue: Int = myBalance() - (msg.fee + self.MinTonsForStorage + (self.GasConsumption * 2)); 
        send(SendParameters{to: self.profitPool, value: msg.fee,  mode: SendPayGasSeparately,  bounce: true, body: FeePayment{amount: msg.fee}.toCell()});
        


        send(SendParameters{
            to: self.usdton, 
            value: remainingValue,
            bounce: true,
            mode: SendBounceIfActionFail,
            body: BurnMessage {
                user: msg.user,
                amount: amountToBurn,
                reservePool: self.reservePool,
                collateralForWithdrawal: collateralForWithdrawal
            }.toCell()
        });

        self.debt = self.debt - msg.amount;
        self.collateral = self.collateral - collateralForWithdrawal;
    }
    bounced(msg: bounced<BurnMessage>) {
        self.debt = self.debtBeforeBurn;
        self.bouncedHandler();
    }
    receive(msg: TokenExcesses) {
        self.debt = self.debtBeforeBurn;
        self.collateral = self.collateralBefore;
    }


    //=============================================================================
    // Helpers
    //=============================================================================

    fun isPositionHealthy(collateral: Int, debt: Int, tonPrice: Int, settings: Settings): Bool {
        return (collateral * tonPrice / 1000000000) * settings.reservePool / 1000000000  >= debt;
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