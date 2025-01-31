import "../utils/messages.tact";

@interface("org.ton.jetton.wallet")
contract StableWallet {
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");
    balance: Int;
    owner: Address;
    master: Address;
    init(master: Address, owner: Address){
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    /* ok */
    receive(msg: TokenTransfer){
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Durov Protocol: invalid sender");
        // Update balance
        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Invalid balance");
        // Gas checks
        let fwdFee: Int = ctx.readForwardFee();
        let fwdCount: Int = 1;
        if (msg.forwardTonAmount > 0) {
            fwdCount = 2;
        }
        require(ctx.value > (((fwdCount * fwdFee) + (2 * self.gasConsumption)) + self.minTonsForStorage),
            "Invalid value"
        );
        // Send tokens
        let init: StateInit = initOf StableWallet(self.master, msg.destination);
        let walletAddress: Address = contractAddress(init);
        send(SendParameters{
                to: walletAddress,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransferInternal{
                    amount: msg.amount,
                    queryId: msg.queryId,
                    from: self.owner,
                    responseAddress: self.owner,
                    forwardTonAmount: msg.forwardTonAmount,
                    forwardPayload: msg.forwardPayload,
                    notificationAddress: null
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }
    receive(msg: PaymentRequest) {

    }
    receive(msg: TokenTransferInternal) {
        // Check sender
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf StableWallet(self.master, msg.from);
            require(contractAddress(sinit) == ctx.sender, "Durov Protocol: invalid sender");
        }

        // Update balance
        self.balance = self.balance + msg.amount;

        require(self.balance >= 0, "Invalid balance");
        // Adjust value for gas
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);

        if (msg.notificationAddress != null) {

            if (msg.queryId == 1) {
                    msgValue = (msgValue - (storageFee + self.gasConsumption * 3) );
                    //проверить точно ли хватает газа в операции

                    send(SendParameters{
                        to: msg.notificationAddress!!,
                        value: msgValue,
                        bounce: false,
                        mode: SendIgnoreErrors,
                        body: OnPaymentComplete{amount: msg.amount, order: msg.forwardPayload.asString()}.toCell()
                    }
                );

            send(SendParameters{
                    to: self.owner,
                    value: self.gasConsumption,
                    bounce: false,

                    body: msg.forwardPayload.asString().asComment()
                }
            );
            } else {
            msgValue = (msgValue - (storageFee + self.gasConsumption * 2) );
            send(SendParameters{
                    to: msg.notificationAddress!!,
                    value: msgValue,
                    bounce: true,
                    body: OnMintComplete{amount: msg.amount }.toCell()
                }
            );
            }

        } else {
            msgValue = (msgValue - (storageFee + self.gasConsumption));
        }

        // Forward ton
        if (msg.forwardTonAmount > 0 && msg.responseAddress != null) {
            let fwdFee: Int = ctx.readForwardFee();
            msgValue = msgValue - (msg.forwardTonAmount + fwdFee);
            send(SendParameters{
                    to: msg.responseAddress!!,
                    value: msg.forwardTonAmount,
                    bounce: false,
                    body: TokenNotification {
                        queryId: msg.queryId,
                        amount: msg.amount,
                        from: msg.from,
                        forwardPayload: msg.forwardPayload
                    }.toCell()
                }
            );
        }

        // Cashback
        if (msg.responseAddress != null && msgValue > 0) {
            send(SendParameters{
                    to: msg.responseAddress!!,
                    value: msgValue,
                    bounce: false,
                    mode: SendIgnoreErrors,
                    body: TokenExcesses{queryId: msg.queryId}.toCell()
                }
            );
        }
    }


    bounced(msg: Slice){
        // Parse bounced message
        msg.skipBits(32); // 0xFFFFFFFF
        let op: Int = msg.loadUint(32);
        let queryId: Int = msg.loadUint(64);
        let jettonAmount: Int = msg.loadCoins();
        require(op == 0x178d4519 || op == 0x7bdd97de, "Invalid bounced message");
        // Update balance
        self.balance = self.balance + jettonAmount;
    }

    // usdTon related method

    receive(msg: BurnRequest){
        /* check if called by master
        if balance >= amount
        decrease balance
        master.repayBurnNotification(amount, fees)

        if balance < amount - error, userStatus.message(error)
        */

        require(sender() == self.master, "Durov Protocol: Invalid sender");
        // todo add bounced handler in master
        require((self.balance - msg.amount) >= 0, "Durov Protocol: Invalid balance");
        self.balance = self.balance - msg.amount;
        // todo error on this check
        // require(ctx.value > fwdFee + 2 * self.GasConsumption + self.MinTonsForStorage, "Invalid value");

        send(SendParameters{
                to: self.master,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: true,
                body: BurnNotification{
                    amount: msg.amount,
                    user: msg.user,
                    notificationAddress: msg.notificationAddress
                }.toCell()
            }
        );
    }

    receive(msg: BurnForCoupons) {
        require(sender() == self.master, "Durov Protocol: Invalid sender");
        require((self.balance - msg.amount) >= 0, "Durov Protocol: Invalid balance");
        self.balance = self.balance - msg.amount;


        send(SendParameters{
                to: self.master,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: true,
                body: BurnForCouponsNotification{
                    amount: msg.amount,
                    user: msg.user,
                    couponsAmount: msg.couponsAmount}.toCell()
            });

    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
                balance: self.balance,
                owner: self.owner,
                master: self.master,
                walletCode: initOf StableWallet(self.master, self.owner).code
            };
    }

    get fun getBalance(): Int {
        return self.balance;
    }
}