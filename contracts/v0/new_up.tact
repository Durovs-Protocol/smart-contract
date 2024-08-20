import "@stdlib/deploy";
import "@stdlib/ownable";
import "../utils/math.tact";
import "../utils/messages.tact";
import "../utils/helpers.tact";

contract NewUp  {
    const MinTonsForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    
    //settings
    user: Address;
    manager: Address;
    reservePool: Address;
    //state
    isActive: Bool = true;
    balances: map<Address, Int>;
    withdrawState: WithdrawTransactionInfo;

    init(user: Address, usdton: Address, manager: Address, reservePool: Address, profitPool: Address, balances: map<Address, Int>) {
        self.user = user; 
        self.manager = manager;
        self.reservePool = reservePool;
        self.balances = balances;

        self.withdrawState = WithdrawTransactionInfo{
            queryId: 0,
            amount: 0,
            master: newAddress(0,0)
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

    receive(msg: SetState) {
        require(sender() == self.manager, "Runa protocol: not from positions manager");

        self.balances = msg.balances;

        let remainingValue: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption);
        send(SendParameters{
                to: self.manager,
                value: remainingValue,
                bounce: true,
                body: AddPositionId {
                    user: self.user
                }.toCell()
            }
        );

    }
    /* Supply */
    receive(msg: Supply) {
        require(self.isActive, "position is not active");
        require(sender() == self.manager, "Runa protocol: not from positions manager");

        let ctx: Context = context();
        let remainingValue: Int = ctx.value - (self.MinTonsForStorage + self.GasConsumption);
        let currency: String = "";

        let oldBalance: Int? = self.balances.get(msg.payload);
        if (oldBalance != null) {

        let newValue: Int = oldBalance!! + msg.amount;
        self.balances.set(msg.payload, newValue);
        let comment: StringBuilder = beginString();
        comment.append("Runa protocol: you have supplied ");
        comment.append(msg.amount.toString());

        send(SendParameters{
                to: self.user,
                bounce: false,
                value: remainingValue,
                mode:  SendIgnoreErrors,
                body: comment.toString().asComment()
            }
        );
        } else {
                    send(SendParameters{
                to: self.user,
                bounce: false,
                value: remainingValue,
                mode:  SendIgnoreErrors,
                body: "Runa protocol: asset not found".asComment()
            }
        );
        }


    }

    /* Withdraw */
    receive(msg: Withdraw) {
        require(self.isActive, "position is not active");
        require(sender() == self.manager, "Runa protocol: not from positions manager");

        let ctx: Context = context();
        let remainingValue: Int = ctx.value - (self.MinTonsForStorage + self.GasConsumption);

        if (!self.enoughFunds(msg.master, msg.amount)) {
            send(SendParameters{
                to: self.user,
                value: ctx.value,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Runa protocol:Not enough funds to withdraw".asComment()
            });
            return;
        }

        self.withdrawState.queryId = random(0, 18446);
        self.withdrawState.amount = msg.amount;
        self.withdrawState.master = msg.master;

        send(SendParameters{
            to: self.reservePool,
            value: remainingValue,
            bounce: true,
            mode: SendBounceIfActionFail,
            body: WithdrawRequest {
                amount: msg.amount,
                user: msg.user,
                master: msg.master,
                queryId: self.withdrawState.queryId
            }.toCell()
        });
    }

    bounced(msg: bounced<WithdrawRequest>) {
        //TODO
        self.bouncedHandler();
    }

    receive(msg: TokenExcesses) {
        let ctx: Context = context();
        let remainingValue: Int = ctx.value - (self.MinTonsForStorage + self.GasConsumption);
        if (self.withdrawState.queryId == msg.queryId) {
            let newValue: Int = self.balances.get(self.withdrawState.master)!! -  self.withdrawState.amount;
            self.balances.set(self.withdrawState.master, newValue);
            self.clearTransactionState();
            send(SendParameters{
                to: self.user,
                value: remainingValue,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Runa protocol: withdraw was successful".asComment()
            });
        } else {
            send(SendParameters{
                to: self.user,
                value: remainingValue,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Runa protocol: unidentified withdraw transaction id".asComment()
            });
        }
    }
    receive(msg: TonTransfer) {
        let ctx: Context = context();
        let remainingValue: Int = ctx.value - (self.MinTonsForStorage + self.GasConsumption);

        if (self.withdrawState.queryId == msg.queryId) {
            let newValue: Int = self.balances.get(self.withdrawState.master)!! -  self.withdrawState.amount;
            self.balances.set(self.withdrawState.master, newValue);

            let comment: StringBuilder = beginString();
            comment.append("Runa protocol: withdraw of: ");
            comment.append(self.withdrawState.amount.toString());
            comment.append(" ");
            comment.append(self.withdrawState.master.toString());
            comment.append("was successful");

            send(SendParameters{
                to: self.user,
                value: remainingValue,
                mode: SendIgnoreErrors,
                bounce: false,
                body: comment.toString().asComment()
            });

            self.clearTransactionState();
        } else {
            send(SendParameters{
                to: self.user,
                value: remainingValue,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Runa protocol: unidentified withdraw transaction id".asComment()
            });
        }
    }

    /* Migration */
    receive(msg: MigrationRequest) {
        let remainingValue: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption);
        self.isActive = false;

        send(SendParameters {
                to: self.manager,
                value: remainingValue,
                bounce: false,
                body: BuildPosition {
                    user: self.user,
                    balances: self.balances,
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


    fun bouncedHandler() {
        send(SendParameters{
                to: self.user,
                bounce: false,
                value: 0,
                mode:  SendRemainingValue + SendIgnoreErrors ,
                body: "Runa protocol: error".asComment()
            }
        );
    }
    fun clearTransactionState() {
        self.withdrawState = WithdrawTransactionInfo{
            queryId: 0,
            amount: 0,
            master: newAddress(0,0)
        };
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

    fun enoughFunds(master: Address, amount: Int): Bool {
        let currentBalance: Int? = self.balances.get(master);
        if (currentBalance == null) {
            return false;
        } else {
            return currentBalance!! >= amount;
        }
    }


    //=============================================================================
    // Offchain interface
    //=============================================================================
    get fun user(): Address {
        return self.user;
    }
    get fun balances(): map<Address, Int> {
        return self.balances;
    }
    get fun status(): Bool {
        return self.isActive;
    }
}

