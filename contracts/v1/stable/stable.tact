import "./stable_wallet.tact";
import "../utils/messages.tact";
import "../up__pool.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";

message Mint {
    amount: Int;
}

    /* ok */
contract Stable with Deployable, OwnableTransferable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    deps: Deps;
    balances: map<Address, Int>;

    init(owner: Address, content: Cell) {
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
        self.balances = emptyMap();
    }
    receive(msg: SetBalances){
        self.requireOwner();
        self.balances = msg.balances;
        self.reply("Durovs Protocol: Stable balances template set".asComment());
    }
    receive(msg: TokenUpdateContent){
        self.requireOwner();
        self.content = msg.content;
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
        self.reply("Durovs Protocol: Stable's dependencies set".asComment());
    }

    receive(msg: Mint) {
        self.requireOwner();
        self.mint(sender(), msg.amount, sender(), null);
    }

    /*
        from userPosition
    */
    receive(msg: MintRequest) {
        let userPositionAddress: Address = self._userPositionAddress(msg.user);
        require(sender() == userPositionAddress, "Durov Protocol: invalid sender");
        self.mint(msg.user, msg.amount, msg.user, msg.notificationAddress);
    }




    /*
        from userPosition
    */
    receive(msg: BurnRequest) {
        let userPositionAddress: Address = self._userPositionAddress(msg.user);
        require(sender() == userPositionAddress, "Durov Protocol: invalid sender");
        let winit: StateInit = self.getJettonWalletInit(msg.user);
        let walletAddress: Address = contractAddress(winit);

        send(SendParameters{
            to: walletAddress, 
            value: 0, 
            bounce: true,
            mode: SendRemainingValue + SendBounceIfActionFail,
            body: msg.toCell()
        });
    }


    receive(msg: BurnNotification) {
        self.requireWallet(msg.user);
        self.totalSupply = (self.totalSupply - msg.amount);
        send(SendParameters{
                    to: msg.notificationAddress!!,
                    value: 0,
                    bounce: true,
                    mode: SendRemainingValue,
                    body: OnBurnComplete{amount: msg.amount}.toCell()
                }
        );
    }

    receive(msg: PaymentRequest) {
        let userPositionAddress: Address = self._userPositionAddress(msg.owner);
        require(sender() == userPositionAddress, "Durov Protocol: invalid sender");

        let sender: Address = sender();
        self.processPayment(msg.receiver, msg.owner, msg.amount, sender(), msg.order);
    }

    fun processPayment(to: Address, owner: Address, amount: Int, responseAddress: Address, comment: String) {
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
                    queryId: 1,
                    from: myAddress(),
                    responseAddress: owner,
                    forwardTonAmount: 0,
                    forwardPayload: comment.asSlice(),
                    notificationAddress: responseAddress,
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }
    fun mint(to: Address, amount: Int, responseAddress: Address, notificationAddress: Address?) {
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
                    notificationAddress: notificationAddress,
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    receive(msg: BurnForCoupons) {
        require(sender() == self.deps.manager, "Durovs Protocol: Not from position Manager");
        let winit: StateInit = self.getJettonWalletInit(msg.user);
        let walletAddress: Address = contractAddress(winit);
        send(SendParameters{
            to: walletAddress, 
            value: 0, 
            bounce: true,
            mode: SendRemainingValue + SendBounceIfActionFail,
            body: msg.toCell()
        });
    }

    receive(msg: MintCouponNotification) {
        
        let comment: StringBuilder = beginString();

        comment.append("Durovs Protocol: You recieved ");
        comment.append(msg.amount.toFloatString(9));
        comment.append(" coupons ");
     
        send(SendParameters {
            to: msg.user, 
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false,
            body: comment.toString().asComment()
        });
    }


    receive(msg: BurnForCouponsNotification) {
        self.requireWallet(msg.user);
        self.totalSupply = (self.totalSupply - msg.amount);
        send(SendParameters{
                    to: self.deps.coupon,
                    value: 0,
                    bounce: true,
                    //TODO bounce handler
                    mode: SendRemainingValue,
                    body: MintCoupons{user: msg.user, amount: msg.couponsAmount}.toCell()
                }
        );
    }

    receive(msg: OnCouponBurnComplete) {
        require(sender() == self.deps.coupon, "Durovs Protocol: Not from Coupon Master");

        self.totalSupply = (self.totalSupply + msg.amount);
        let winit: StateInit = self.getJettonWalletInit(msg.user);
        let walletAddress: Address = contractAddress(winit);

        let infoCell = beginCell().storeAddress(sender()).storeAddress(msg.user).endCell();
        let builder = beginCell().storeRef(infoCell);



        send(SendParameters {
                to: walletAddress,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransferInternal { 
                    amount: msg.amount,
                    queryId: 0,
                    from: myAddress(),
                    responseAddress: self.deps.manager,
                    forwardTonAmount: ton("0.03"),
                    forwardPayload: builder.asSlice(),
                    notificationAddress: msg.user,
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
        let init: StateInit = initOf V1UserPosition(user, self.deps.manager, self.deps.reservePool, self.deps.stable, self.balances );
        let userPositionAddress: Address = contractAddress(init);
        return userPositionAddress;
    }

    get fun balances(): map<Address, Int> {
        return self.balances;
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


    get fun get_wallet_address(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(winit);
    }

    get fun get_jetton_data(): JettonData {
        let code: Cell = self.getJettonWalletInit(myAddress()).code;
        return
            JettonData{
                totalSupply: self.totalSupply,
                mintable: self.mintable,
                owner: self.owner,
                content: self.content,
                walletCode: code
            };
    }
    fun requireWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Durov Protocol: invalid sender");
    }

    fun getJettonWalletInit(address: Address): StateInit {
        return initOf StableWallet(myAddress(), address);
    }
}