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
    // Actions
    //=============================================================================

    // вывод всех средств с пула на кошелек владельца пула, после тестов удалить
    receive(msg: TestWithdrawal){
        send(SendParameters{to: self.owner, bounce: false, value: 0, mode: (SendRemainingBalance + SendIgnoreErrors)});
    }

    // TODO реализовать перевод поступлений в runecoin
    receive(msg: FeePayment){
        //
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
}