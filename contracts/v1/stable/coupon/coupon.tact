import "../../up__pool.tact";
import "./coupon_wallet.tact";
import "../../utils/messages.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";

message Mint {
    amount: Int;
}


contract Coupon with Deployable, OwnableTransferable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell?;
    mintable: Bool;
    deps: Deps;



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
    }

    receive(msg: Mint) {
        self.requireOwner();
        self.totalSupply = (self.totalSupply + msg.amount);
        let winit: StateInit = self.getJettonWalletInit(sender());
        let walletAddress: Address = contractAddress(winit);

        send(SendParameters {
                to: walletAddress,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransferInternal { 
                    amount: msg.amount,
                    queryId: 0,
                    from: myAddress(),
                    responseAddress: sender(),
                    forwardTonAmount: 0,
                    forwardPayload: emptySlice(),
                    notificationAddress: sender(),
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
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
        self.reply("Durovs Protocol: Coupon's dependencies set".asComment());
    }



    /*
        from userPosition
    */
    receive(msg: MintCoupons) {
        //let userPositionAddress: Address = self._userPositionAddress(msg.user);
        //TODO проверка отправителя 
        //require(sender() == userPositionAddress, "Durov Protocol: invalid sender");

        self.totalSupply = (self.totalSupply + msg.amount);
        let winit: StateInit = self.getJettonWalletInit(msg.user);
        let walletAddress: Address = contractAddress(winit);

        send(SendParameters {
                to: walletAddress,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransferInternal { 
                    amount: msg.amount,
                    queryId: 0,
                    from: myAddress(),
                    responseAddress: msg.user,
                    forwardTonAmount: 0,
                    forwardPayload: emptySlice(),
                    notificationAddress: msg.user
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }



    receive(msg: MintCouponNotification) {
        self.requireWallet(msg.user);

        send(SendParameters{
                    to: self.deps.manager,
                    value: 0,
                    bounce: true,
                    mode: SendRemainingValue,
                    body: msg.toCell()
                }
        );
    }

    receive(msg: CouponExchangeRequest) {
        require(sender() == self.deps.manager, "Durov Protocol: invalid sender wallet");
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

    receive(msg: CouponExchangeNotification) {
        self.requireWallet(msg.user);
        self.totalSupply = (self.totalSupply - msg.amount);
        send(SendParameters{
                    to: self.deps.stable,
                    value: 0,
                    bounce: true,
                    mode: SendRemainingValue,
                    body: OnCouponBurnComplete{ amount: msg.amount, user: msg.user}.toCell()
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
    
    get fun get_wallet_address(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(winit);
    }

    get fun deps(): Deps {
        return self.deps;
    }

    get fun totalSupply(): Int {
        return self.totalSupply;
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
    get fun userPositionAddress(user: Address): Address {
        return self._userPositionAddress(user);
    }
    fun requireWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Durov Protocol: invalid sender");
    }

    fun getJettonWalletInit(address: Address): StateInit {
        return initOf CouponWallet(myAddress(), address);
    }
}