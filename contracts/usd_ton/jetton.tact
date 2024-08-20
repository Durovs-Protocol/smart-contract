import "@stdlib/ownable";
import "../v1/utils/messages.tact";
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
        require(contractAddress(winit) == ctx.sender, "Runa protocol: invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf UsdTonWallet(myAddress(), address);
    }
}