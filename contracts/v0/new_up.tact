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
    withdrawState: map<Int as uint64, WithdrawTransactionInfo>;

    init(user: Address, usdton: Address, manager: Address, reservePool: Address, profitPool: Address) {
        self.user = user; 
        self.manager = manager;
        self.reservePool = reservePool;
        self.balances = emptyMap();

        self.withdrawState = emptyMap();

    }

    receive(msg: SetState) {
        require(sender() == self.manager, "Runa protocol: not from positions manager");

        self.balances = msg.balances;
        let remainingValue: Int = context().value - (self.MinTonsForStorage + self.GasConsumption);
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

        let max: Int = 2^64 - 1;
        let randomId: Int = random(0, max);
         self.withdrawState.set(randomId, WithdrawTransactionInfo{
            amount: msg.amount,
            master: msg.master
         });

        send(SendParameters{
            to: self.reservePool,
            value: remainingValue,
            bounce: true,
            mode: SendBounceIfActionFail,
            body: WithdrawRequest {
                amount: msg.amount,
                user: msg.user,
                master: msg.master,
                queryId: randomId
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
        let transactionInfo: WithdrawTransactionInfo? = self.withdrawState.get(msg.queryId);

        if (transactionInfo != null) {
            let newValue: Int = self.balances.get(transactionInfo!!.master)!! -  transactionInfo!!.amount;
            self.balances.set(transactionInfo!!.master, newValue);
            self.clearTransactionState(msg.queryId);

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
        let transactionInfo: WithdrawTransactionInfo? = self.withdrawState.get(msg.queryId);

        if (transactionInfo != null) {
            let newValue: Int = self.balances.get(transactionInfo!!.master)!! -  transactionInfo!!.amount;
            self.balances.set(transactionInfo!!.master, newValue);

            let comment: StringBuilder = beginString();
            comment.append("Runa protocol: withdraw of: ");
            comment.append(transactionInfo!!.amount.toString());
            comment.append(" ");
            comment.append(transactionInfo!!.master.toString());
            comment.append("was successful");

            send(SendParameters{
                to: self.user,
                value: remainingValue,
                mode: SendIgnoreErrors,
                bounce: false,
                body: comment.toString().asComment()
            });

            self.clearTransactionState(msg.queryId);
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
    fun clearTransactionState(id: Int) {
        self.withdrawState.del(id);
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

