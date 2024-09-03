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
    //state
    isActive: Bool = true;
    balances: map<Address, Int>;
    withdrawState: map<Int , WithdrawTransactionInfo>;
    lastWithdrawalRequest: Int = 0;
    supplyTimestamps: map<Address, SupplyTimestamp> = emptyMap();
    updatedTimestamps: SupplyTimestamp? = null;
    version: String = "1";
    init(user: Address, manager: Address) {
        require(manager == sender(), "Durov Protocol: no access to init user position");
        self.user = user; 
        self.manager = manager;
        self.balances = emptyMap();
        self.withdrawState = emptyMap();
    }

    receive(msg: SetState) {
        require(sender() == self.manager, "Durov Protocol: not from positions manager");
        require(self.balances.isEmpty(), "Durov Protocol: already set");

        self.balances = msg.balances;
        self.supplyTimestamps = msg.supplyTimestamps;
        self.updatedTimestamps =  msg.updatedTimestamps;
        self.withdrawState = msg.withdrawState;
        self.lastWithdrawalRequest = msg.lastWithdrawalRequest;

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
        if (!self.isActive) {
            self.errorHandler("Durov Protocol: position is not active");
            return;
        }
        if (sender() != self.manager) {
            self.errorHandler("Durov Protocol: not from positions manager");
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
            comment.append("Durov Protocol: you have supplied ");
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
                body: "Durov Protocol: asset not found".asComment()
            }
        );
        }
    }

    /* Withdraw */
    receive(msg: Withdraw) {
        
        if (self.updatedTimestamps != null) {

            if ((now() - self.lastWithdrawalRequest) > msg.maxExecutionTime) {
                self.withdrawState = emptyMap();
                self.updatedTimestamps = null;
            } else {
            self.errorHandler("Durov Protocol: wait until the previous withdrawal completed");
            return;
            }

        }

        if (!self.isActive) {
            self.errorHandler("Durov Protocol: position is not active");
            return;
        }
        if (sender() != self.manager) {
            self.errorHandler("Durov Protocol: not from positions manager");
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
                body: "Durov Protocol:Not enough funds to withdraw".asComment()
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
                body: "Durov Protocol: withdrawal available after 24 hours".asComment()
            });
            return;
        }

        //     let comment: StringBuilder = beginString();
        //         comment.append("Durov Protocol: Withdrawal will be available in ");
        //         comment.append(self.lastSupply.toString());
        //         comment.append(" seconds");
        

        let max: Int = 2^64 - 1;
        let randomId: Int = random(0, max);

        self.lastWithdrawalRequest = now();

         self.withdrawState.set(randomId, WithdrawTransactionInfo{
            amount: msg.amount,
            master: msg.master
         });


        send(SendParameters{
            to: msg.pool,
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
                body: "Durov Protocol: withdraw was successful".asComment()
            });
        } else {
            send(SendParameters{
                to: self.user,
                value: remainingValue,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Durov Protocol: unidentified withdraw transaction id".asComment()
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
            comment.append("Durov Protocol: withdraw of: ");
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
                body: "Durov Protocol: unidentified withdraw transaction id".asComment()
            });
        }
    }

    /* Migration */
    receive(msg: MigrationRequest) {

        if (sender() != self.manager) {
            self.errorHandler("Durov Protocol: not from positions manager");
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
                    supplyTimestamps: self.supplyTimestamps,
                    updatedTimestamps: self.updatedTimestamps,
                    withdrawState: self.withdrawState,
                    lastWithdrawalRequest: self.lastWithdrawalRequest
                }.toCell(),
            }
        );
    }

    //==================================NEW FEATURES===========================================
    //=============================================================================
    receive(msg: MintDurovUSD) {
        require(sender() == self.manager, "not from position Manager");

        // if (!self.isHealthyForMint(self.balances, msg.rates)) {
        // TODO
        //     self.unhealthyPositionHandler(msg.user);
        //     return;
        // } 

        send(SendParameters{
            to: msg.runausd, 
            value: 0,
            mode: (SendRemainingValue + SendBounceIfActionFail), 
            bounce: true,
            body: MintRequest{
                user: msg.user,
                amount: msg.amount,
                notificationAddress: myAddress(),
            }.toCell()
        });
    }

    receive(msg: OnMintComplete) {
        let comment: StringBuilder = beginString();
        // self.debt += msg.amount; TODO
        comment.append("Durov Protocol: You have minted");
        comment.append(msg.amount.toString());
        comment.append("runas");
     
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
    receive(msg: BurnDurovUSD) {
        require(sender() == self.manager, "not from position manager");

        let amountToBurn: Int = msg.amount;
        // todo add bounced handler in sender to pay ctx.value back to sender
        // if (self.debt < msg.amount) {
        //  TODO self.setMessage("Your debt is less than you want to repay, charge sent back");
        //     amountToBurn = self.debt;
        // }
        // if (amountToBurn < ((msg.settings.burnMin * 1000000000) / msg.tonPrice)) {
            // send(SendParameters {
            //     to: self.user, 
            //     value: 0,
            //     mode: SendRemainingValue + SendIgnoreErrors,
            //     bounce: false,
            //     body: "Your debt is less than minimum possible".asComment()
            // });
            // return;
        // }
        

        // let withdrawalAmount: Int = (msg.amount * msg.settings.reserveRatio) /  msg.tonPrice;

        // осталвяем средства для оплаты комиссии на балансе, также оставляем средства для оплаты газа 
        let remainingValue: Int = myBalance() - self.MinTonsForStorage + self.GasConsumption; 

        send(SendParameters{
            to: msg.runausd, 
            value: remainingValue,
            bounce: true,
            mode: SendBounceIfActionFail,
            body: BurnRequest {
                user: msg.user,
                amount: amountToBurn,
                withdrawalAmount: 0,
                fee: 0,
                notificationAddress: myAddress()
            }.toCell()
        });
    }
    bounced(msg: bounced<BurnRequest>) {
        self.bouncedHandler();
    }
    receive(msg: OnBurnComplete) {
        let comment: StringBuilder = beginString();
        comment.append("Durov Protocol: You have burned");
        comment.append(msg.usdton.toString());
        comment.append("runas");
     
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


    fun bouncedHandler() {
        send(SendParameters{
                to: self.user,
                bounce: false,
                value: 0,
                mode:  SendRemainingValue + SendIgnoreErrors ,
                body: "Durov Protocol: error".asComment()
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
    get fun version(): String {
        return self.version;
    }
}

contract NewReservePool with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    owner: Address;
    balances:  map<Address, Int>;
    assets:  map<Address, Asset>;
    version: String = "1";

    init(owner: Address){
        require(owner == sender(), "Durov Protocol: no access to init pool");
        self.owner = sender();
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
        self.reply("Durov Protocol: new pool's dependencies set".asComment());
    }
    receive(msg: SetBalances) {
        self.requireOwner();
        self.balances = msg.balances;
        self.reply("Durov Protocol: new pool balances template set".asComment());
    }
    receive(msg: SetAssets) {
        self.requireOwner();
        self.assets = msg.assets;
        self.reply("Durov Protocol: new pool assets set".asComment());
    }
    receive(str: String){
        // приимаем текстовые сообщения
    }


    receive(msg: PoolMigrationRequest) {
        self.requireOwner();
        send(SendParameters {
                to: msg.wallet,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: TokenTransfer {
                    amount: msg.amount,
                    queryId: msg.queryId,
                    destination: msg.newPool,
                    forwardTonAmount: 0,
                    customPayload: null,
                    responseDestination: sender(),
                    forwardPayload: ("pool migration").asSlice()
                }.toCell()
        });
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
                        body: "Durov Protocol: error while recieving ton: not enought tons sended".asComment()
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
                    body: "Durov Protocol: error while processing payment: unknown op code".asComment()
                }
            );
        }
    }

    receive(msg: WithdrawRequest) {
        let userPositionAddress: Address = self._userPositionAddress(msg.user);

        
        if (sender() != userPositionAddress) {
            self.errorHandler("Durov Protocol: no access to withdraw funds", sender());
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
                        body: "Durov Protocol: Error while attempting to withdraw (pull is empty).".asComment()
                    });
                }
            } else {
                let remainingValue: Int = ctx.value - (self.GasConsumption + self.MinTonForStorage);
                send(SendParameters {
                to: asset!!.poolWallet,
                value: remainingValue,
                bounce: false,
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
                body: "Durov Protocol: error while withdraw (requested asset not found)".asComment()
            }
        );
        }
    }
    //=============================================================================
    // Helpers
    //=============================================================================
    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf NewUp(user,
            self.deps.manager,
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
    get fun version(): String {
        return self.version;
    }
}
