import "@stdlib/ownable";
import "../utils/messages.tact";
import "./usd_ton_wallet.tact";
@interface("org.ton.jetton.master")
trait Jetton with OwnableTransferable {
    //
    // Storage
    //

    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;

    //
    // Receivers
    //
    receive(msg: TokenUpdateContent){
        // Allow changing content only by owner
        self.requireOwner();
        // Update content
        self.content = msg.content;
    }

    // receive(msg: TokenBurnNotification){
    //     // Check wallet
    //     self.requireWallet(msg.owner);
    //     // Update supply
    //     self.totalSupply = (self.totalSupply - msg.amount);
    //     // Cashback
    //     if (msg.responseAddress != null) {
    //         send(SendParameters{
    //                 to: msg.responseAddress!!,
    //                 value: 0,
    //                 bounce: false,
    //                 mode: (SendRemainingValue + SendIgnoreErrors),
    //                 body: TokenExcesses{queryId: msg.queryId}.toCell()
    //             }
    //         );
    //     }
    // }

    //
    // Get Methods
    //

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

    //
    // Private Methods
    //

    fun requireWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf UsdTonWallet(myAddress(), address);
    }
}