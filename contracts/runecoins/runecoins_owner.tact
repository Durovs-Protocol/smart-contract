import "@stdlib/deploy";
import "./runecoins_wallet.tact";
import "./runecoin.tact";
message SetBalance {
    amount: Int;
    content: Cell?;
}
message GetRunecoins {
    amount: Int;
    user: Address;
}

contract RuneCoinsOwner with Deployable {
    runaCoinAddress: Address;
    owner: Address;
    totalCoins: Int;
    init(owner: Address){
        self.owner = owner;
        self.totalCoins = 0;
        self.runaCoinAddress = newAddress(0, 0);
    }

    receive(msg: SetBalance){
        let init: StateInit = initOf Runecoin(myAddress(), msg.content);
        let address: Address = contractAddress(init);
        self.runaCoinAddress = address;
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
    /*01 | Запрос на получение runacoin (from user)'*/
    receive(msg: GetRunecoins){
        let winit: StateInit = initOf RunecoinsWallet(self.runaCoinAddress, myAddress());
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
                    customPayload: self.createOffchainContent("custom"),
                    forwardTonAmount: 0,
                    forwardPayload: self.createOffchainContent("forward").asSlice()
                }.toCell()
            }
        );
        self.totalCoins -= msg.amount;
        self.reply("Runacoins sent".asComment());
    }

    fun createOffchainContent(pram: String): Cell {
        let s: StringBuilder = beginStringFromBuilder(beginCell().storeBool(true).storeUint(0, 32));
        s.append(pram);
        return s.toCell();
    }

    get fun totalAmount(): Int {
        return self.totalCoins;
    }

    get fun address(): Address {
        return self.runaCoinAddress;
    }

    get fun owner(): Address {
        return self.owner;
    }
}