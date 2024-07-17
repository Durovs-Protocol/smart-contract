import "@stdlib/deploy";
import "@stdlib/ownable";
import "./utils/messages.tact";
import "./user_position.tact";
import "./utils/math.tact";
import "./runecoin/runecoin_wallet.tact";

contract Pool with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    owner: Address;
    init(owner: Address){
        self.owner = owner;
        self.deps = Deps{
            managerAddress: newAddress(0, 0),
            poolAddress: newAddress(0, 0),
            usdTonAddress: newAddress(0, 0),
            runecoinAddress: newAddress(0, 0)
        };
    }

    //=============================================================================
    // Settings
    //=============================================================================
    receive(msg: SetDeps){
        self.requireOwner();
        self.deps = Deps{
            managerAddress: msg.managerAddress,
            poolAddress: msg.poolAddress,
            usdTonAddress: msg.usdTonAddress,
            runecoinAddress: msg.runecoinAddress
        };
        self.reply("pool's dependencies set".asComment());
    }

    //=============================================================================
    // Actions: TODO: вывод дохода, конвертация TON в runacoin
    //=============================================================================

    receive(msg: FeePayment){
        // Принимаем TON при ликвидации
        // TODO: обмен через DEX на RUNA
        let comment: StringBuilder = beginString();
        comment.append("Fee payment:");
        comment.append(msg.amount.toString());
        send(SendParameters{to: msg.user, value: 0, bounce: false, body: comment.toString().asComment()});
    }

    //=============================================================================
    // Helpers
    //=============================================================================

    //=============================================================================
    // Offchain interface
    //=============================================================================

    get fun getBalance(): Int {
        return myBalance();
    }

    get fun deps(): Deps {
        return self.deps;
    }

    get fun myAddress(): Address {
        return myAddress();
    }

    get fun userPoolAddress(userAddress: Address): Address {
        let init: StateInit = initOf Pool(userAddress);
        return contractAddress(init);
    }
}