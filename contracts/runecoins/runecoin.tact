import "./jetton.tact";
import "./runecoins_wallet.tact";
import "../messages";
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


    receive(msg: Mint) {
        self.requireOwner();
        self.mint(sender(), msg.amount, sender());
    }

    receive(msg: MintMessage) {
      self.mint(msg.user, msg.amount, msg.user);
    }


    receive(msg: RepayBurnMessage) {
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


    receive(msg: RepayBurnNotification) {
        send(SendParameters{
            to: msg.userPosition, 
            value: 0, 
            bounce: false,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: StablecoinBurnedMessage{ 
                amount: msg.amount,
                user: msg.user,
                rate: msg.rate
            }.toCell()
        });
    }


    get fun totalSupply(): Int {
        return self.totalSupply;
    }

    get fun message(): String {
        return self.message;
    }

}