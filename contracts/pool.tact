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
        self.reply("deps set".asComment());
    }

    //=============================================================================
    // Actions
    //=============================================================================

    /*01 | Пополнение пула, сообщение от user position*/
    receive(msg: DoDeposit){
        dump(context().value);
        send(SendParameters{to: msg.user, bounce: false, value: 0, mode: (SendRemainingValue + SendIgnoreErrors)});
        self.reply("Colleteral was added".asComment());
    }

    /*04 | Возврат залога от user position */
    receive(msg: DoWithdrawCollateral){
        send(SendParameters{
                to: msg.user,
                bounce: false,
                value: msg.amount,
                mode: (SendRemainingValue + SendIgnoreErrors)
            }
        );
    }

    //=============================================================================
    // Helpers
    //=============================================================================
    fun getUserPositionAddress(user: Address): Address {
        let init: StateInit = initOf UserPosition(user,
            self.deps.usdTonAddress,
            self.deps.managerAddress,
            myAddress(),
            self.deps.runecoinAddress
        );
        return contractAddress(init);
    }

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