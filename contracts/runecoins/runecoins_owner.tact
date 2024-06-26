import "@stdlib/deploy";
import "./runecoins_wallet.tact";
import "./runecoin.tact";
import "../utils/helpers.tact";
message SetBalance {
    amount: Int;
    content: Cell?;
}
message GetRunecoins {
    amount: Int;
    user: Address;
}

contract RuneCoinsOwner with Deployable {
    runecoinAddress: Address;
    owner: Address;
    totalCoins: Int;
    init(owner: Address){
        self.owner = owner;
        self.totalCoins = 0;
        self.runecoinAddress = newAddress(0, 0);
    }

    receive(msg: SetBalance){
        let init: StateInit = initOf Runecoin(myAddress(), msg.content);
        let address: Address = contractAddress(init);
        self.runecoinAddress = address;
        send(SendParameters{
                to: address,
                value: ton("0.5"),
                mode: SendBounceIfActionFail,
                code: init.code,
                data: init.data,
                body: Mint{amount: msg.amount}.toCell()
            }
        );
        self.totalCoins = msg.amount;
        self.reply("Runecoins released".asComment());
    }

    // user actions
    /*01 | Запрос на получение runecoin (from user)'*/
    receive(msg: GetRunecoins){
        let winit: StateInit = initOf RunecoinsWallet(self.runecoinAddress, myAddress());
        let walletAddress: Address = contractAddress(winit);
        send(SendParameters{
                to: walletAddress,
                value: ton("0.3"),
                mode: SendBounceIfActionFail,
                bounce: false,
                body: TokenTransfer{
                    queryId: 0,
                    amount: msg.amount,
                    destination: msg.user,
                    responseDestination: myAddress(),
                    customPayload: createOffchainContent("custom"),
                    forwardTonAmount: 0,
                    forwardPayload: createOffchainContent("forward").asSlice()
                }.toCell()
            }
        );
        self.totalCoins -= msg.amount;
        self.reply("Runacoins sent".asComment());
    }

    get fun totalAmount(): Int {
        return self.totalCoins;
    }

    get fun address(): Address {
        return self.runecoinAddress;
    }

    get fun owner(): Address {
        return self.owner;
    }
}