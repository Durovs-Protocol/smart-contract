

import "./stable_wallet.tact";
import "../utils/messages.tact";
import "../up__pool.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";

message Mint {
    amount: Int;
}

contract Stable with Deployable, OwnableTransferable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    deps: Deps;
    message: String;

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
        self.message = "";
    }
    receive(msg: TokenUpdateContent){
        // Allow changing content only by owner
        self.requireOwner();
        // Update content
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
        //let userPositionAddress: Address = self._userPositionAddress(msg.user);
        //TODO проверка отправителя
        //require(sender() == userPositionAddress, "Durov Protocol: invalid sender");
        self.mint(msg.user, msg.amount, msg.user, msg.notificationAddress);
    }

    /*
        from userPosition
    */
    receive(msg: BurnRequest) {
        //TODO проверка отправителя
        //    require(sender() == userPositionAddress, "Durov Protocol: invalid sender");
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
    fun mint(to: Address, amount: Int, responseAddress: Address, notificationAddress: Address?) {
        // Update total supply
        self.totalSupply = (self.totalSupply + amount);
        let winit: StateInit = self.getJettonWalletInit(to);
        let walletAddress: Address = contractAddress(winit);

        let winitPool: StateInit = self.getJettonWalletInit(self.deps.profitPool);
        let addressPool: Address = contractAddress(winitPool);
        // for pool
        send(SendParameters{
                to: addressPool,
                value: ton("0.4"),
                bounce: true,
                body: TokenTransferInternal {
                    amount: (amount * 10000000) / 1000000000,
                    queryId: 0,
                    from: myAddress(),
                    responseAddress: responseAddress,
                    forwardTonAmount: 0,
                    forwardPayload: emptySlice(),
                    notificationAddress: null,
                }.toCell(),
                code: winitPool.code,
                data: winitPool.data
            }
        );
        // for user
        send(SendParameters {
                to: walletAddress,
                value: context().value - ton("0.43"),
                bounce: true,
                body: TokenTransferInternal { 
                    amount: (amount * 990000000) / 1000000000,
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
    receive(msg: DexMessage) {
        // имитация покупки, выпуск без увеличения значения supply на кошелек пула
        let winit: StateInit = self.getJettonWalletInit(msg.walletOwner);
        let walletAddress: Address = contractAddress(winit);

        let remainingValue: Int = context().value - msg.price;

        send(SendParameters {
                to: walletAddress,
                value: remainingValue,
 
                bounce: false,
                body: TokenTransferInternalDex {
                    amount: msg.amount,
                    queryId: 0,
                    from: myAddress(),
                    responseAddress: msg.walletOwner,
                    notificationAddress:  msg.position,
                    forwardTonAmount: 0,
                    forwardPayload: emptySlice()
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf V1UserPosition(user, self.deps.manager, self.deps.reservePool, self.deps.stable );
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