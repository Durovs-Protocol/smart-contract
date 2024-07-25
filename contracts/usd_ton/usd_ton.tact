import "../user_position.tact";
import "./jetton.tact";
import "./usd_ton_wallet.tact";
import "../utils/messages.tact";
import "@stdlib/deploy";

message Mint {
    amount: Int;
}


contract UsdTonMaster with Jetton, Deployable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell?;
    mintable: Bool;
    deps: Deps;
    message: String;

    init(owner: Address, content: Cell?) {
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.deps = Deps{
            manager: newAddress(0, 0),
            profitPool: newAddress(0, 0),
            reservePool: newAddress(0, 0),
            usdton: newAddress(0, 0)
        };
        self.message = "";
    }

    receive (msg: SetDeps) {
        self.requireOwner();
        self.deps = Deps{
            manager: msg.manager,
            profitPool: msg.profitPool,
            reservePool: msg.reservePool,
            usdton: msg.usdton
        };
        self.reply("usdton's dependencies set".asComment());
    }

    receive(msg: Mint) {
        self.requireOwner();
        self.mint(sender(), msg.amount, sender());
    }

    // usdTon handlers

    /*
        message came from userPosition
        mint new usdTons for to
        todo add 
    */
    receive(msg: MintMessage) {
        //let userPositionAddress: Address = self._userPositionAddress(msg.user);
        //TODO проверка отправителя
        //require(sender() == userPositionAddress, "invalid sender");
        // let ctx: Context = context();
        // let value: Int = ctx.value - ton("0.005");

        self.mint(msg.user, msg.amount, msg.user);
    }



    /*
        message came from userPosition
        send jetton.burn
    */
    receive(msg: BurnMessage) {

        // let userPositionAddress: Address =  self._userPositionAddress(msg.user);

        //TODO проверка отправителя
        //    require(sender() == userPositionAddress, "invalid sender");

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

    /*
        message came from jetton
        decrease totalSupply
        call userPosition.stableBurned(user, amount, fees)
    */
    receive(msg: BurnNotification) {
        self.requireWallet(msg.user);
        self.totalSupply = (self.totalSupply - msg.amount);
        // looks like huge bug here, explain later
        // let userPositionAddress: Address =  self._userPositionAddress(msg.user);
        send(SendParameters{
                    to: self.deps.reservePool,
                    value: 0,
                    bounce: true,
                    mode: SendRemainingValue,
                    body: UsdTonBurned{ 
                amount: msg.amount,
                user: msg.user,
                collateralForWithdrawal: msg.collateralForWithdrawal
            }.toCell()
                }
        );
        //TODO убрать userPosition на 

    }
    fun mint(to: Address, amount: Int, responseAddress: Address) {
        // Update total supply
        self.totalSupply = (self.totalSupply + amount);
        // send(SendParameters{
        //             to: self.deps.resrvePool,
        //             value: 0,
        //             bounce: false,
        //             mode: SendIgnoreErrors,
        //             body: UsdTonUpdateNotification{newValue: self.totalSupply}.toCell()
        // }
        // );
        // Create message
        let winit: StateInit = self.getJettonWalletInit(to);
        let walletAddress: Address = contractAddress(winit);

        let winitPool: StateInit = self.getJettonWalletInit(self.deps.profitPool);
        let addressPool: Address = contractAddress(winitPool);

        send(SendParameters{
                to: addressPool,
                value: ton("0.4"),
                bounce: true,
                body: TokenTransferInternal{
                    amount: (amount * 10000000) / 1000000000,
                    queryId: 0,
                    from: myAddress(),
                    responseAddress: responseAddress,
                    forwardTonAmount: 0,
                    forwardPayload: emptySlice()
                }.toCell(),
                code: winitPool.code,
                data: winitPool.data
            }
        );
        send(SendParameters {
                to: walletAddress,
                value: context().value - ton("0.45"),
                bounce: true,
                body: TokenTransferInternal{
                    amount: (amount * 990000000) / 1000000000,
                    queryId: 0,
                    from: myAddress(),
                    responseAddress: responseAddress,
                    forwardTonAmount: 0,
                    forwardPayload: emptySlice()
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
        let init: StateInit = initOf UserPosition(user, self.deps.usdton, self.deps.manager, self.deps.reservePool, self.deps.profitPool);
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