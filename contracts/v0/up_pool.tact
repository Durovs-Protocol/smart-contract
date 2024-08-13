import "@stdlib/deploy";
import "@stdlib/ownable";
import "../utils/messages.tact";
import "../utils/math.tact";
import "../utils/helpers.tact";


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
    manager: Address;
    positionAddress: Address;
    reservePool: Address;
    debt: Int;
    debtBeforeBurn: Int = 0;
    isActive: Bool = true;

    collateral: Int;
    collateralBefore: Int = 0;
    collateralAfterWithdraw: Int = 0;

    message: Message;

    init(user: Address, usdton: Address, manager: Address, reservePool: Address, profitPool: Address) {
        self.user = user; 
        self.manager = manager;
        self.reservePool = reservePool;
        self.positionAddress = newAddress(0,0);


        self.collateral = 0;
        self.debt = 0;

        self.message = Message{
            timestamp: 0,
            message: "Position Created"
        };

        send(SendParameters {
            to: self.manager, 
            mode: SendIgnoreErrors,
            value: ton("0.5"), 
            bounce: true,
            body: AddPositionId{
                user: user
            }.toCell()
        });
    }
    receive(msg: SetPositionAddress) {

        if (self.positionAddress == newAddress(0,0)) {
          self.positionAddress = msg.address;
        }
        send(SendParameters{to: self.user, value: 0, mode: SendRemainingValue, bounce: false});
    }
    
    /* Supply */
    receive(msg: Supply) {
        require(self.isActive, "position is not active");
        require(sender() == self.manager, "not from positionsManager");

        let remainingValue: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption + ton("0.5"));
        if (remainingValue < msg.amount) {
            self.errorHandler("not enough tone for deposit and service fee");
            return;
        }

        self.collateralBefore = self.collateral;
        self.collateral = self.collateral + msg.amount;

        send(SendParameters{
                to: self.reservePool,
                bounce: true,
                value: remainingValue,
                body: msg.toCell(),
        });
    }

    bounced(msg: bounced<Supply>) {
        self.collateral = self.collateralBefore;
        self.bouncedHandler();
    }

    /* Supply */
    receive(msg: Withdraw) {
        require(self.isActive, "position is not active");
        require(sender() == self.manager, "not from position manager");
                require(self.positionAddress != newAddress(0,0), "Position deployed wuth error, support: support@yandex.ru");
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
    require(sender() == self.reservePool, "message not from reserve pool");

    self.collateral -= msg.amount;

    let ctx: Context = context();
    let remainingValue: Int = ctx.value - (self.MinTonsForStorage + (self.GasConsumption * 2) + msg.amount); 
    send(SendParameters{to: self.user, value: msg.amount, mode: SendIgnoreErrors + SendPayGasSeparately, bounce: false});
    send(SendParameters{to: self.user, value: remainingValue, bounce: false});
    }


    bounced(msg: bounced<Withdraw>) {
        self.bouncedHandler();
    }
    
    /* Migration */
    receive(msg: MigrationRequest) {
        require(self.positionAddress != newAddress(0,0), "Position deployed wuth error, support: support@yandex.ru");
        require(sender() == self.positionAddress, "not from position manager");

        let remainingValue: Int = myBalance() - self.MinTonsForStorage;
        self.isActive = false;

        send(SendParameters {
                to: msg.manager,
                value: remainingValue,
                bounce: true,
                body: BuildPosition {
                    user: self.user,
                    positionAddress: self.user,
                    owner: msg.owner,
                    collateral: self.collateral,
                    debt: self.debt,
                    manager: msg.manager, 
                    reservePool: msg.reservePool, 
                    usdton: msg.usdton,
                    profitPool: msg.profitPool
                    
                }.toCell(),
            }
        );
    }
    //=============================================================================
    // Helpers
    //=============================================================================

    fun isHealthyForWithdraw(collateral: Int, debt: Int, tonPrice: Int, settings: Settings): Bool {
        if (debt == 0) {
            return true;
        }
        return collateral * tonPrice / self.debt >= settings.liquidationRatio;
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
    get fun positionAddressContract(): Address {
        return self.positionAddress;
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
    get fun message(): Message {
        return self.message;
    }
    get fun status(): Bool {
        return self.isActive;
    }
}
////////////////////////////////////////////////////////////////
contract ReservePool with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    owner: Address;

    init(owner: Address){
        self.owner = owner;
        self.deps = Deps {
            manager: newAddress(0, 0),
            profitPool: newAddress(0, 0),
            reservePool: newAddress(0, 0),
            usdton: newAddress(0, 0),
            runaCoupon: newAddress(0, 0)
        };
    }
    //=============================================================================
    // Settings
    //=============================================================================
    receive(msg: SetDeps){
        self.requireOwner();
        self.deps = Deps{
            manager: msg.manager,
            profitPool: msg.profitPool,
            reservePool: msg.reservePool,
            usdton: msg.usdton,
            runaCoupon: msg.runaCoupon
        };
        self.reply("pool's dependencies set".asComment());
    }

    receive(msg: Supply){
        let ctx: Context = context();
        let remainingValue: Int = ctx.value - (msg.amount + self.GasConsumption);

        send(SendParameters{
                to: msg.user,
                bounce: false,
                value: remainingValue,
                mode: (SendIgnoreErrors + SendPayGasSeparately),
                body: "Collateral added".asComment()
            }
        );
    }

    receive(msg: WithdrawRequest) {
        let userPositionAddress: Address = self._userPositionAddress(msg.user);
        require(sender() == userPositionAddress, "invalid sender");

        let ctx: Context = context();
        let remainingValue: Int = (ctx.value - self.GasConsumption);
        send(SendParameters{
                to: sender(),
                value: (msg.amount + remainingValue),
                mode: SendBounceIfActionFail,
                bounce: true,
                body: WithdrawResponce{amount: msg.amount}.toCell()
            }
        );
    }

    // bounced(msg: bounced<WithdrawResponce>){
    //This message is small enough for bounce receiver, you need to remove bounced modifier. ??
    //TODO
    // }

    //=============================================================================
    // Helpers
    //=============================================================================
    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf UserPosition(user,
            self.deps.usdton,
            self.deps.manager,
            self.deps.reservePool,
            self.deps.profitPool
        );
        return contractAddress(init);
    }
    //=============================================================================
    // Offchain interface
    //=============================================================================

    get fun getBalance(): Int {
        return myBalance();
    }

    get fun deps(): Deps {
        return self.deps;
    }

}