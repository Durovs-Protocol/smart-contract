import "@stdlib/deploy";
import "@stdlib/ownable";
import "../utils/messages.tact";
import "../utils/math.tact";
import "../utils/helpers.tact";

struct SupplyTimestamp {
    info: map<Int , Int >;
}

contract UserPosition  {
    const MinTonsForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    
    //settings
    user: Address;
    manager: Address;
    reservePool: Address;
    //state
    isActive: Bool = true;
    balances: map<Address, Int>;
    withdrawState: map<Int , WithdrawTransactionInfo>;
    supplyTimestamps: map<Address, SupplyTimestamp> = emptyMap();
    updatedTimestamps: SupplyTimestamp? = null;

    init(user: Address, usdton: Address, manager: Address, reservePool: Address, profitPool: Address, balances: map<Address, Int>) {
        self.user = user; 
        self.manager = manager;
        self.reservePool = reservePool;
        self.balances = balances;

        

        self.withdrawState = emptyMap();

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


    /* Supply */
    receive(msg: Supply) {
        if (!self.isActive) {
            self.errorHandler("Runa protocol: position is not active");
            return;
        }
        if (sender() != self.manager) {
            self.errorHandler("Runa protocol: not from positions manager");
            return;
        }
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
        
        let supplyTimestamp: SupplyTimestamp? = self.supplyTimestamps.get(msg.payload);

        let info: map<Int , Int > = emptyMap();


        if (supplyTimestamp == null) {
             info.set(now(), msg.amount);
        } else {
             info = supplyTimestamp!!.info;
             info.set(now(), msg.amount);
        }
        self.supplyTimestamps.set(msg.payload, SupplyTimestamp{info: info});

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
        
        if (self.updatedTimestamps != null) {
            self.errorHandler("Runa protocol: wait until the previous withdrawal completed");
            return;
        }

        if (!self.isActive) {
            self.errorHandler("Runa protocol: position is not active");
            return;
        }
        if (sender() != self.manager) {
            self.errorHandler("Runa protocol: not from positions manager");
            return;
        }
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

        let availableAmount: Int = self.availableBalance(msg.minDelay, msg.master, msg.amount);


        if (availableAmount < msg.amount) {
            self.updatedTimestamps = null;
            send(SendParameters{
                to: self.user,
                value: ctx.value,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Runa protocol: withdrawal available after 24 hours".asComment()
            });
            return;
        }

        //     let comment: StringBuilder = beginString();
        //         comment.append("Runa protocol: Withdrawal will be available in ");
        //         comment.append(self.lastSupply.toString());
        //         comment.append(" seconds");
        

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
        self.updatedTimestamps = null;
        //TODO
        self.bouncedHandler();
    }

    receive(msg: TokenExcesses) {
        let ctx: Context = context();
        let remainingValue: Int = ctx.value - (self.MinTonsForStorage + self.GasConsumption);
        let transactionInfo: WithdrawTransactionInfo? = self.withdrawState.get(msg.queryId);

        if (transactionInfo != null) {
            let newValue: Int = self.balances.get(transactionInfo!!.master)!! - transactionInfo!!.amount;
            self.balances.set(transactionInfo!!.master, newValue);
            self.clearTransactionState(msg.queryId);
            self.supplyTimestamps.set(transactionInfo!!.master, self.updatedTimestamps);
            self.updatedTimestamps = null;

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


            self.supplyTimestamps.set(transactionInfo!!.master, self.updatedTimestamps);
            self.updatedTimestamps = null;

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

        if (sender() != self.manager) {
            self.errorHandler("Runa protocol: not from positions manager");
            return;
        }
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


    fun availableBalance(minDelay: Int, master: Address, amount: Int): Int {
            let currentBalance: SupplyTimestamp? = self.supplyTimestamps.get(master);
            if (currentBalance == null) {
                return 0;
            }
            let info: map<Int , Int > = currentBalance!!.info;
            let updatedTimestamps: SupplyTimestamp = SupplyTimestamp{info: emptyMap()};

            let availableAmount: Int = 0;
            foreach(key, value in info) {
                if ((now() - key) >= minDelay) {

                    if (availableAmount == amount) {
                        updatedTimestamps.info.set(key, value);
                    } else if ((availableAmount + value) <= amount) {
                        availableAmount += value;
                    } else if ((availableAmount + value) > amount) {
                        let remainderVal: Int = (availableAmount + value) - amount;
                        availableAmount += (value - remainderVal);
                        updatedTimestamps.info.set(key, remainderVal);
                    }

                    // supplyTimestamps.del(key);
                } else {
                    updatedTimestamps.info.set(key, value);

                }
            }
            self.updatedTimestamps = updatedTimestamps;
        return availableAmount;
    }



    //=============================================================================
    // Offchain interface
    //=============================================================================
    get fun user(): Address {
        return self.user;
    }
    get fun updatedTimestamps(): SupplyTimestamp? {
        return self.updatedTimestamps;
    }
    get fun balances(): map<Address, Int> {
        return self.balances;
    }
    get fun status(): Bool {
        return self.isActive;
    }
    get fun withdrawState(): map<Int , WithdrawTransactionInfo> {
        return self.withdrawState;
    }   
    get fun supplyTimestamps(): map<Address, SupplyTimestamp> {
        return self.supplyTimestamps;
    }
}

// ======POOL==================================================================

contract ReservePool with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    owner: Address;
    balances:  map<Address, Int>;
    assets:  map<Address, Asset>;

    init(owner: Address){
        self.owner = owner;
        self.deps = Deps {
            manager: newAddress(0, 0),
            profitPool: newAddress(0, 0),
            reservePool: newAddress(0, 0),
            usdton: newAddress(0, 0),
            runaCoupon: newAddress(0, 0)
        };
        self.balances = emptyMap();
        self.assets = emptyMap();
    }
    // ------------------------Settings------------------------------------------------
    receive(msg: SetDeps){
        self.requireOwner();
        self.deps = Deps{
            manager: msg.manager,
            profitPool: msg.profitPool,
            reservePool: msg.reservePool,
            usdton: msg.usdton,
            runaCoupon: msg.runaCoupon
        };
        self.reply("Runa protocol: pool's dependencies set".asComment());
    }
    receive(msg: SetBalances) {
        self.requireOwner();
        self.balances = msg.balances;
        self.reply("Runa protocol: pool Balances template is set".asComment());
    }
    receive(msg: SetAssets) {
        self.requireOwner();
        self.assets = msg.assets;
        self.reply("Runa protocol: Pool asset template set.".asComment());
    }
    receive(msg: TokenNotification) {
        let ctx: Context = context();

        let payload: Slice = msg.forwardPayload.preloadRef().beginParse();
        let master: Address = payload.loadAddress();
        let op: Int = payload.loadInt(64);

        if (op == 1) {
        // получение ton
            if (ctx.value < (self.GasConsumption + self.MinTonForStorage + msg.amount)) {
                    send(SendParameters{
                        to: msg.from,
                        value: ctx.value,
                        mode: SendIgnoreErrors,
                        bounce: false,
                        body: "Runa protocol: error while recieving ton: not enought tons sended".asComment()
                    });
                    return;
            }
            let remainingValue: Int = ctx.value - (self.GasConsumption + self.MinTonForStorage + msg.amount);
            send(SendParameters{
                to: self.deps.manager,
                value: remainingValue,
                mode: SendBounceIfActionFail,
                bounce: true,
                body: SupplyMessage{amount: msg.amount, user: msg.from, payload: master }.toCell()
            });
        } else if (op == 2) { 
        // получение jetton
            let remainingValue: Int = ctx.value - (self.GasConsumption + self.MinTonForStorage);
            send(SendParameters{
                to: self.deps.manager,
                value: remainingValue,
                mode: SendBounceIfActionFail,
                bounce: true,
                body: SupplyMessage{amount: msg.amount, user: msg.from, payload: master }.toCell()
            });
        } else {
            send(SendParameters{
                    to: msg.from,
                    value: ctx.value,
                    mode: SendIgnoreErrors,
                    bounce: false,
                    body: "Runa protocol: error while processing payment: unknown op code".asComment()
                }
            );
        }
    }

    receive(msg: WithdrawRequest) {
        let userPositionAddress: Address = self._userPositionAddress(msg.user);

        
        if (sender() != userPositionAddress) {
            self.errorHandler("Runa protocol: no access to withdraw funds", sender());
            return;
        }

        let ctx: Context = context();
        let asset: Asset? = self.assets.get(msg.master);

        if (asset != null) {
            if (msg.master == newAddress(0, 0)) {
                let remainingValue: Int = msg.amount + (ctx.value - (self.GasConsumption + self.MinTonForStorage));

                if (remainingValue <= myBalance()) {
                    send(SendParameters {
                        to: sender(),
                        value: remainingValue,
                        bounce: true,
                        body: TonTransfer{queryId: msg.queryId}.toCell()
                    });
                } else {
                    send(SendParameters{
                        to: msg.user,
                        value: remainingValue,
                        mode: SendIgnoreErrors,
                        bounce: false,
                        body: "Runa protocol: Error while attempting to withdraw (pull is empty).".asComment()
                    });
                }
            } else {
                let remainingValue: Int = ctx.value - (self.GasConsumption + self.MinTonForStorage);
                send(SendParameters {
                to: asset!!.poolWallet,
                value: remainingValue,
                bounce: true,
                body: TokenTransfer {
                    amount: msg.amount,
                    queryId: msg.queryId,
                    destination: msg.user,
                    forwardTonAmount: 0,
                    customPayload: null,
                    responseDestination: sender(),
                    forwardPayload: ("withdraw transfer").asSlice()
                }.toCell()

            });
            }
        } else {
            send(SendParameters{
                to: msg.user,
                value: ctx.value,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Runa protocol: error while withdraw (requested asset not found)".asComment()
            }
        );
        }
    }

    bounced(msg: bounced<TokenTransfer>) {

        //TODO
    }
    //=============================================================================
    // Helpers
    //=============================================================================
    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf UserPosition(user,
            self.deps.usdton,
            self.deps.manager,
            self.deps.reservePool,
            self.deps.profitPool,
            self.balances
        );
        return contractAddress(init);
    }
    fun errorHandler(comment: String, user: Address) {
        send(SendParameters{
                to: user,
                bounce: false,
                value: 0,
                mode:  SendRemainingValue + SendIgnoreErrors ,
                body: comment.asComment()
            }
        );
    }
    //=============================================================================
    // Offchain interface
    //=============================================================================
    get fun balances(): map<Address, Int> {
        return self.balances;
    }

    get fun deps(): Deps {
        return self.deps;
    }
    get fun assets(): map<Address, Asset> {
        return self.assets;
    }
}
