import "@stdlib/deploy";
import "./runecoin_wallet.tact";
import "./runecoin.tact";
import "../utils/helpers.tact";
message SetBalance {
    amount: Int;
    content: Cell?;
}
message GetRunecoin {
    amount: Int;
    user: Address;
}

contract RuneCoinOwner with Deployable {
    runecoinAddress: Address;
    owner: Address;
    totalCoins: Int;
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.03");
    init(owner: Address){
        self.owner = owner;
        self.totalCoins = 0;
        self.runecoinAddress = newAddress(0, 0);
    }

    receive(msg: SetBalance){
        let init: StateInit = initOf Runecoin(myAddress(), msg.content);
        let address: Address = contractAddress(init);
        self.runecoinAddress = address;
        let ctx: Context = context();
        send(SendParameters{
                to: address,
                value: (ctx.value - self.GasConsumption),
                mode: SendBounceIfActionFail,
                code: init.code,
                data: init.data,
                body: Mint{amount: msg.amount}.toCell()
            }
        );
        self.totalCoins = msg.amount;
        self.reply("Runecoin released".asComment());
    }

    receive(msg: TokenExcesses){
        // для приема оставшегося ton после установки баланса
    }

    // user actions
    /*01 | Запрос на получение runecoin (from user)'*/
    receive(msg: GetRunecoin){
        let winit: StateInit = initOf RunecoinWallet(self.runecoinAddress, myAddress());
        let walletAddress: Address = contractAddress(winit);
        send(SendParameters{
                to: walletAddress,
                value: ton("0.3"),
                mode: SendBounceIfActionFail,
                bounce: true,
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
    // для проверки решения проблемы с адресами

    get fun runeInfo(user: Address): Address {
        let winit: StateInit = initOf RunecoinWallet(self.runecoinAddress, user);
        let walletAddress: Address = contractAddress(winit);
        return walletAddress;
    }

    get fun owner(): Address {
        return self.owner;
    }
}