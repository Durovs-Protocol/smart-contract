import "@stdlib/deploy";
import "@stdlib/ownable";
import "./utils/math.tact";
import "./utils/messages.tact";
import "./utils/helpers.tact";

contract V1UserPosition  {
    const MinTonsForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    
    //settings
    user: Address;
    manager: Address;
    pool: Address;
    stable: Address;
    //state
    isActive: Bool = true;
    balances: map<Address, Int>;
    wallets: map<Address, Address>;
    withdrawState: map<Int , WithdrawTransactionInfo>;
    lastWithdrawalRequest: Int = 0;
    supplyTimestamps: map<Address, SupplyTimestamp> = emptyMap();
    updatedTimestamps: SupplyTimestamp? = null;
    version: String = "1";
    //
    debt: Int;
    totalCollateral: Int = 0;
    burnState: map<Int, Int> = emptyMap();

    init(user: Address, manager: Address, pool: Address, stable: Address) {
        require(manager == sender(), "Durovs Protocol: No access to init user position");
        self.user = user; 
        self.manager = manager;
        self.pool = pool;
        self.balances = emptyMap();
        self.wallets = emptyMap();
        self.withdrawState = emptyMap();
        self.debt = 0;
        self.stable = stable;
    }

    receive(msg: SetState) {
        require(sender() == self.manager, "Durovs Protocol: Not from positions manager");
        require(self.balances.isEmpty(), "Durovs Protocol: Already set");

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
            self.errorHandler("Durovs Protocol: Position is not active");
            return;
        }
        if (sender() != self.manager) {
            self.errorHandler("Durovs Protocol: Not from positions manager");
            return;
        }
        let ctx: Context = context();
        let remainingValue: Int = ctx.value - (self.MinTonsForStorage + self.GasConsumption);
        let currency: String = "";

        let oldBalance: Int? = self.balances.get(msg.master);

        if (oldBalance != null) {
            let newValue: Int = oldBalance!! + msg.amount;
            
            if (self.wallets.get(msg.master) == null) {
                self.wallets.set(msg.master, msg.userWallet);
            }

            self.balances.set(msg.master, newValue);

            let currencyType: String = msg.master == newAddress(0, 0) ? " TON" : " token(s)";

            let comment: StringBuilder = beginString();
                comment.append("Durovs Protocol: You have supplied ");
                comment.append(msg.amount.toFloatString(9));
                comment.append(currencyType);

        
        let supplyTimestamp: SupplyTimestamp? = self.supplyTimestamps.get(msg.master);

        let info: map<Int , Int > = emptyMap();


        if (supplyTimestamp == null) {
             info.set(now(), msg.amount);
        } else {
             info = supplyTimestamp!!.info;
             info.set(now(), msg.amount);
        }
        self.supplyTimestamps.set(msg.master, SupplyTimestamp{info: info});

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
                body: "Durovs Protocol: Asset not found".asComment()
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
            self.errorHandler("Durovs Protocol: Wait until the previous withdrawal completed");
            return;
            }

        }
        if (!self.isActive) {
            self.errorHandler("Durovs Protocol: Position is not active");
            return;
        }
        if (sender() != self.manager) {
            self.errorHandler("Durovs Protocol: Not from positions manager");
            return;
        }
        let ctx: Context = context();
        if (!self.enoughFunds(msg.master, msg.amount)) {
            send(SendParameters{
                to: self.user,
                value: ctx.value,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Durovs Protocol: Not enough funds to withdraw".asComment()
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
                body: "Durovs Protocol: Withdrawal available after 6 hours".asComment()
            });
            return;
        }
        let max: Int = 2^64 - 1;
        let randomId: Int = random(0, max);

        self.lastWithdrawalRequest = now();

         self.withdrawState.set(randomId, WithdrawTransactionInfo{
            amount: msg.amount,
            master: msg.master
        });

        // проверка задолженности
        let balancesAfterWithdraw:  map<Address, Int> = self.balances;
        let newValue = balancesAfterWithdraw.get(msg.master)!! - msg.amount;
        balancesAfterWithdraw.set(msg.master, newValue);

        if (!self.isHealthy(balancesAfterWithdraw, msg.rates, self.debt)) {
            self.errorHandler("Durovs Protocol: Position is not healthy");
            return;
        }

        let remainingValue: Int = ctx.value - (self.MinTonsForStorage + self.GasConsumption);
        //


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
        
        self.bouncedHandler();
    }

    
    receive(msg: TokenExcesses) {
        let ctx: Context = context();
        let remainingValue: Int = ctx.value - (self.MinTonsForStorage + self.GasConsumption);
        let transactionInfo: WithdrawTransactionInfo? = self.withdrawState.get(msg.queryId);


        if (transactionInfo != null) {
            let userWallet: Address? = self.wallets.get(transactionInfo!!.master);

            if (userWallet != sender()) {
            let comment: StringBuilder = beginString();
                comment.append("Durovs Protocol: Invalid sender in token transfer confirmation: ");
                comment.append(userWallet!!.toString());
                send(SendParameters{
                    to: self.user,
                    value: remainingValue,
                    mode: SendIgnoreErrors,
                    bounce: false,
                    body: comment.toString().asComment()
                });
                return;
            }

            let newValue: Int = self.balances.get(transactionInfo!!.master)!! - transactionInfo!!.amount;
            self.balances.set(transactionInfo!!.master, newValue);
            self.clearTransactionState(msg.queryId);
            self.supplyTimestamps.set(transactionInfo!!.master, self.updatedTimestamps);
            self.updatedTimestamps = null;

            let comment: StringBuilder = beginString();
                comment.append("Durovs Protocol: Withdraw of ");
                comment.append(transactionInfo!!.amount.toFloatString(9));
                comment.append(" token(s) was successfull");

            send(SendParameters{
                to: self.user,
                value: remainingValue,
                mode: SendIgnoreErrors,
                bounce: false,
                body: comment.toString().asComment()
            });
        } else {
            send(SendParameters{
                to: self.user,
                value: remainingValue,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Durovs Protocol: Undefined withdraw transaction id".asComment()
            });
        }
    }

    /* TODO: проверка адреса пула как sender: отправка TON */
    receive(msg: TonTransfer) {
        require(self.pool == sender(), "Durovs Protocol: Not enough access rights to perform this operation");

        let ctx: Context = context();
        let remainingValue: Int = ctx.value - (self.MinTonsForStorage + self.GasConsumption);
        let transactionInfo: WithdrawTransactionInfo? = self.withdrawState.get(msg.queryId);

        if (transactionInfo != null) {
            let newValue: Int = self.balances.get(transactionInfo!!.master)!! -  transactionInfo!!.amount;
            self.balances.set(transactionInfo!!.master, newValue);


            self.supplyTimestamps.set(transactionInfo!!.master, self.updatedTimestamps);
            self.updatedTimestamps = null;

            let comment: StringBuilder = beginString();
            comment.append("Durovs Protocol: Withdraw of ");
            comment.append(transactionInfo!!.amount.toFloatString(9));
            comment.append(" TON was successful");

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
                body: "Durovs Protocol: Undefined withdraw transaction id".asComment()
            });
        }
    }

    /* Migration */
    receive(msg: MigrationRequest) {

        if (sender() != self.manager) {
            self.errorHandler("Durovs Protocol: Not from positions manager");
            return;
        }
        let remainingValue: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption);
        self.isActive = false;

        send(SendParameters {
                to: msg.newManager,
                value: remainingValue,
                bounce: false,
                body: BuildPosition {
                    user: self.user,
                    balances: self.balances,
                    supplyTimestamps: self.supplyTimestamps,
                    updatedTimestamps: self.updatedTimestamps,
                    withdrawState: self.withdrawState,
                    lastWithdrawalRequest: self.lastWithdrawalRequest,
                }.toCell(),
            }
        );
    }

    //==================================NEW FEATURES===========================================
    //=============================================================================
    receive(msg: MintStable) {
        require(sender() == self.manager, "Durovs Protocol: Not from position Manager");
        let debtAfterMint: Int = self.debt + msg.amount;

        if (!self.burnState.isEmpty()) {
            self.errorHandler("Durovs Protocol: You need to wait for the burn complete, contact support for more information");
            return;
        } 

        if (!self.isHealthy(self.balances, msg.rates, debtAfterMint)) {
            self.errorHandler("Durovs Protocol: Position is not healthy");
            return;
        } 

        send(SendParameters{
            to: self.stable, 
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
        self.debt += msg.amount;
        comment.append("Durovs Protocol: You have minted ");
        comment.append(msg.amount.toFloatString(9));
        comment.append(" durovUSD");
     
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
    receive(msg: BurnStable) {
        require(sender() == self.manager, "not from position manager");
        if (!self.burnState.isEmpty()) {
            self.errorHandler("You need to wait for the burn complete, contact support for more information");
            return;
        } 
        let amountToBurn: Int = msg.amount;

        if (self.debt < msg.amount) {
            amountToBurn = self.debt;
        }

        let remainingValue: Int = context().value - self.GasConsumption; 

        self.burnState.set(now(), amountToBurn);

        send(SendParameters{
            to: self.stable, 
            value: remainingValue,
            bounce: true,
            mode: SendBounceIfActionFail,
            body: BurnRequest {
                user: msg.user,
                amount: amountToBurn,
                fee: 0,
                notificationAddress: myAddress()
            }.toCell()
        });
    }
    bounced(msg: bounced<BurnRequest>) {
        self.bouncedHandler();
    }
    receive(msg: OnBurnComplete) {
        require(sender() == self.stable, "Durovs Protocol: Not from durovUSd");
        self.debt -= msg.amount;
        self.burnState = emptyMap();

        let comment: StringBuilder = beginString();
        comment.append("Durovs Protocol: You have burned ");
        comment.append(msg.amount.toFloatString(9));
        comment.append("durovUSD");

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

    fun isHealthy(balances: map<Address, Int>, rates: map<Address, Int>, debt: Int): Bool {

    let totalCollateral: Int = 0;

    foreach (key, value in balances) {
        let currentRate: Int? = rates.get(key);
        if (currentRate != null && value > 0) {
          totalCollateral += ((value * currentRate!!) / 1000000000);
        }
    }

    self.totalCollateral = totalCollateral;
    return totalCollateral >= debt;
    }

    fun bouncedHandler() {
        send(SendParameters{
                to: self.user,
                bounce: false,
                value: 0,
                mode:  SendRemainingValue + SendIgnoreErrors ,
                body: "Durovs Protocol: Error".asComment()
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
    get fun totalCollateral(): Int {
        return self.totalCollateral;
    }
    get fun debt(): Int {
        return self.debt;
    }
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

contract V1ReservePool with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    owner: Address;
    balances:  map<Address, Int>;
    assets:  map<Address, Asset>;
    version: String = "1";

    init(owner: Address){
        require(owner == sender(), "Durovs Protocol: No access to init pool");
        self.owner = sender();
        self.deps = Deps {
            manager: newAddress(0, 0),
            profitPool: newAddress(0, 0),
            reservePool: newAddress(0, 0),
            stable: newAddress(0, 0),
            coupon: newAddress(0, 0),
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
            stable: msg.stable,
            coupon: msg.coupon
        };
        self.reply("Durovs Protocol: New Pool dependencies set".asComment());
    }
    receive(msg: SetBalances) {
        self.requireOwner();
        self.balances = msg.balances;
        self.reply("Durovs Protocol: New pool balances template set".asComment());
    }
    receive(msg: SetAssets) {
        self.requireOwner();
        self.assets = msg.assets;
        self.reply("Durovs Protocol: New pool assets set".asComment());
    }
    receive(str: String){
        // принимаем текстовые сообщения и перенаправляем их владельцу контракта
        send(SendParameters {
                to: self.owner,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: str.asComment()
            }
        );
    }

    // Прием тона с версии 0
    receive(msg: TonBalanceMigration) {
        send(SendParameters {
                to: self.owner,
                value: 0,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Durovs Protocol: pool migration successfully".asComment()
        });
    }


    // Миграция на новый
    receive(msg: PoolMigrationRequest) {
        self.requireOwner();
        if (msg.wallet != myAddress()) {
        send(SendParameters {
                to: msg.wallet,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransfer {
                    amount: msg.amount,
                    queryId: msg.queryId,
                    destination: msg.newPool,
                    forwardTonAmount: 0,
                    customPayload: null,
                    responseDestination: sender(),
                    forwardPayload: ("Pool migration").asSlice()
                }.toCell()
        });
        } else {
        let remainingBalance: Int = myBalance() - (self.MinTonForStorage + self.GasConsumption);
        send(SendParameters {
                to: msg.newPool,
                value: remainingBalance,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Durovs Protocol: Pool migration".asComment()
        });
        }
    }


    bounced(msg: bounced<TokenTransfer>) {
        send(SendParameters {
                to: self.owner,
                value: 0,
                mode: SendIgnoreErrors + SendRemainingValue,
                bounce: false,
                body: "Durovs Protocol: Token transfer error".asComment()
        });
    }


    receive(msg: TokenNotification) {
        let ctx: Context = context();

        let payload: Slice = msg.forwardPayload.preloadRef().beginParse();
        let master: Address = payload.loadAddress();
        let userWallet: Address = payload.loadAddress();
        let asset: Asset? = self.assets.get(master);

        let op: Int = payload.loadInt(64);

        if (op == 1) {
        // получение ton
            if (ctx.value < (self.GasConsumption + self.MinTonForStorage + msg.amount)) {
                    send(SendParameters{
                        to: msg.from,
                        value: ctx.value,
                        mode: SendIgnoreErrors,
                        bounce: false,
                        body: "Durovs Protocol: Error while recieving ton: not enought tons sended".asComment()
                    });
                    return;
            }
            let remainingValue: Int = ctx.value - (self.GasConsumption + self.MinTonForStorage + msg.amount);
            send(SendParameters{
                to: self.deps.manager,
                value: remainingValue,
                mode: SendBounceIfActionFail,
                bounce: true,
                body: SupplyMessage{amount: msg.amount, user: msg.from, master: master, userWallet: userWallet }.toCell()
            });
        } else if (op == 2) { 
        // получение jetton
            require(asset != null, "Durovs Protocol: Unknown asset");

            if (sender() != asset!!.poolWallet) {
                let comment: StringBuilder = beginString();
                comment.append("Durovs Protocol: Sender does not match with pool wallet: ");
                comment.append(sender().toString());
                    send(SendParameters{
                        to: msg.from,
                        value: ctx.value,
                        mode: SendIgnoreErrors,
                        bounce: false,
                        body: comment.toString().asComment()
                    });
                    return;
            }
            
            let remainingValue: Int = ctx.value - (self.GasConsumption + self.MinTonForStorage);
            send(SendParameters{
                to: self.deps.manager,
                value: remainingValue,
                mode: SendBounceIfActionFail,
                bounce: true,
                body: SupplyMessage{amount: msg.amount, user: msg.from, master: master, userWallet: userWallet }.toCell()
            });
        } else {
            send(SendParameters{
                    to: msg.from,
                    value: ctx.value,
                    mode: SendIgnoreErrors,
                    bounce: false,
                    body: "Durovs Protocol: Error while processing payment: unknown op code".asComment()
                }
            );
        }
    }


    receive(msg: WithdrawRequest) {
        let userPositionAddress: Address = self._userPositionAddress(msg.user);

        if (sender() != userPositionAddress) {
            self.errorHandler("Durovs Protocol: No access to withdraw funds", sender());
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
                        body: "Durovs Protocol: Error while attempting to withdraw (pull is empty).".asComment()
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
                body: "Durovs Protocol: Error while withdraw (requested asset not found)".asComment()
            }
        );
        }
    }
    //=============================================================================
    // Helpers
    //=============================================================================
    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf V1UserPosition(user,
            self.deps.manager,
            self.deps.reservePool,
            self.deps.stable,
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
