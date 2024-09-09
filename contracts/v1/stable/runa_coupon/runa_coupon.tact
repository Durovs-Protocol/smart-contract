import "../v1/user_position.tact";
import "../jetton.tact";
import "./runa_coupon_wallet.tact";
import "../utils/messages.tact";
import "@stdlib/deploy";


contract coupon with Jetton, Deployable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell?;
    mintable: Bool;
    deps: Deps;
    message: String;

    init(owner: Address, content: Cell?) {
        self.totalSupply = 0;
        self.owner = sender();
        self.mintable = true;
        self.content = content;
        self.deps = Deps{
            manager: newAddress(0, 0),
            profitPool: newAddress(0, 0),
            reservePool: newAddress(0, 0),
            stable: newAddress(0, 0),
            coupon: newAddress(0, 0),
        };
        self.message = "";
    }

    receive (msg: SetDeps) {
        self.requireOwner();
        self.deps = Deps{
            manager: msg.manager,
            profitPool: msg.profitPool,
            reservePool: msg.reservePool,
            stable: msg.stable,
            coupon: msg.coupon,
        };
        self.reply("coupon contract dependencies set".asComment());
    }


    /*
        from userPosition
    */
    receive(msg: MintCoupon) {
        //let userPositionAddress: Address = self._userPositionAddress(msg.user);
        //TODO проверка отправителя
        //require(sender() == userPositionAddress, "Durov Protocol: invalid sender");
        self.mint(msg.user, msg.amount, msg.user, msg.notificationAddress);
    }




    receive(msg: BurnNotification) {
        self.requireWallet(msg.user);
        self.totalSupply = (self.totalSupply - msg.amount);
        send(SendParameters{
                    to: msg.notificationAddress!!,
                    value: 0,
                    bounce: true,
                    mode: SendRemainingValue,
                    body: OnBurnComplete{ton: msg.withdrawalAmount, stable: msg.amount, fee: msg.fee}.toCell()
                }
        );
    }

    fun mint(to: Address, amount: Int, responseAddress: Address, notificationAddress: Address) {
        // Update total supply
        self.totalSupply = (self.totalSupply + amount);
        let winit: StateInit = self.getJettonWalletInit(to);
        let walletAddress: Address = contractAddress(winit);

        send(SendParameters {
                to: walletAddress,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransferInternal { 
                    amount: amount,
                    queryId: 0,
                    from: myAddress(),
                    responseAddress: responseAddress,
                    forwardTonAmount: 0,
                    forwardPayload: emptySlice(),
                    notificationAddress: notificationAddress
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    bounced(msg: bounced<TokenTransferInternal>) {
        send(SendParameters{
                to: self.deps.profitPool,
                bounce: false,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors ,
                body: "error".asComment()
            }
        );
    }


    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf V1UserPosition(user, self.deps.manager, self.deps.reservePool, self.deps.stable);
        let userPositionAddress: Address = contractAddress(init);
        return userPositionAddress;
    }


    get fun deps(): Deps {
        return self.deps;
    }

    get fun totalSupply(): Int {
        return self.totalSupply;
    }

    get fun userPositionAddress(user: Address): Address {
        return self._userPositionAddress(user);
    }

    get fun message(): String {
        return self.message;
    }

}