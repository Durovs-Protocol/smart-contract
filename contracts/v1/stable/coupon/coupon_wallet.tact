import "../../utils/messages.tact";

@interface("org.ton.jetton.wallet")
contract CouponWallet
{
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
        let init: StateInit = initOf CouponWallet(self.master, msg.destination);
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
                    forwardPayload: msg.forwardPayload
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    receive(msg: TokenTransferInternal){
        // Check sender
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf CouponWallet(self.master, msg.from);
            require(contractAddress(sinit) == ctx.sender, "Durov Protocol: invalid sender");
        }
        // Update balance
        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance");
        // Adjust value for gas
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue = msgValue - (storageFee + (self.gasConsumption * 3));


        send(SendParameters {
                to: self.master,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: MintCouponNotification{
                    amount: msg.amount,
                    user: self.owner
                }.toCell()
            }
        );
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

    // coupon related method

    receive(msg: CouponExchangeRequest){

        require(sender() == self.master, "Durov Protocol: invalid sender");

        require((self.balance - msg.amount) >= 0, "Durov Protocol: Not enough coupons to exchange");

        self.balance = self.balance - msg.amount;

        send(SendParameters{
                to: self.master,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: true,
                body: CouponExchangeNotification{
                    amount: msg.amount,
                    stableAmount: msg.stableAmount,
                    user: self.owner,
                }.toCell()
            }
        );
    }

    get fun get_wallet_data(): JettonWalletData {
        return
            JettonWalletData{
                balance: self.balance,
                owner: self.owner,
                master: self.master,
                walletCode: initOf CouponWallet(self.master, self.owner).code
            };
    }

    get fun getBalance(): Int {
        return self.balance;
    }
}