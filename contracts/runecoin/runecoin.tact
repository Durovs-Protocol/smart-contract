import "./jetton.tact";
import "./runecoin_wallet.tact";
import "../utils/messages.tact";
import "@stdlib/deploy";

message Mint {
    amount: Int;
}

contract Runecoin with Jetton, Deployable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell?;
    mintable: Bool;
    message: String;

    init(owner: Address, content: Cell?) {
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.message = "";
    }

    // Имитация покупки, выпуск без увеличения значения supply
    receive(msg: DexMessage) {
        let winit: StateInit = self.getJettonWalletInit(msg.user);
        let walletAddress: Address = contractAddress(winit);

        send(SendParameters {
                to: walletAddress,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransferInternal{
                    amount: msg.amount,
                    queryId: 0,
                    from: myAddress(),
                    responseAddress: msg.user,
                    forwardTonAmount: 0,
                    forwardPayload: emptySlice()
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }


    receive(msg: Mint) {
        self.requireOwner();
        let ctx: Context = context();
        self.mint(sender(), msg.amount, sender(), ctx.value);
    }

    receive(msg: MintMessage) {
        let ctx: Context = context();
        self.mint(msg.user, msg.amount, msg.user, ctx.value);
    }

    // TODO зачем ??
    receive(msg: BurnMessage) {
        let winit: StateInit = self.getJettonWalletInit(msg.user);
        let walletAddress: Address = contractAddress(winit);
        send(SendParameters{
            to: walletAddress, 
            value: 0, 
            bounce: false,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: msg.toCell()
        });
    }

    // TODO remove this code
    receive(msg: BurnNotification) {
        send(SendParameters{
            to: msg.userPosition, 
            value: 0, 
            bounce: false,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: RunecoinBurned{ 
                amount: msg.amount,
                user: msg.user,
            }.toCell()
        });
    }


    get fun totalSupply(): Int {
        return self.totalSupply;
    }

    get fun message(): String {
        return self.message;
    }

    get fun myWallet(): Address {
        let winit: StateInit = self.getJettonWalletInit(sender());
        let walletAddress: Address = contractAddress(winit);
        return walletAddress;
    }
}
