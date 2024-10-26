import "@stdlib/deploy";
import "@stdlib/ownable";
import "./utils/messages.tact";
import "./user_position.tact";
import "./utils/math.tact";

contract ProfitPool with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    owner: Address;
    init(owner: Address){
        self.owner = sender();
        self.deps = Deps{
            manager: newAddress(0, 0),
            profitPool: newAddress(0, 0),
            reservePool: newAddress(0, 0),
            stable: newAddress(0, 0),
            coupon: newAddress(0, 0),
        };
    }

    //=============================================================================
    // Settings
    //=============================================================================
    receive(msg: SetDeps){
        self.requireOwner();
        self.deps = Deps{
            manager: msg.manager,
            profitPool: msg.profitPool,
            reservePool: msg.reservePool,
            stable: msg.stable,
            coupon: msg.coupon
        };
        self.reply("pool's dependencies set".asComment());
    }

    //=============================================================================
    // Actions
    //=============================================================================

    /* ok */
    receive(msg: FeePayment){
        let ctx: Context = context();
        let remainingValue: Int = (ctx.value - msg.amount);
        send(SendParameters{
                to: msg.user,
                value: remainingValue,
                bounce: false,
                mode: SendIgnoreErrors,
                body: "You have paid back".asComment()
            }
        );
    }

    receive(str: String){
        // приимаем текстовые сообщения
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