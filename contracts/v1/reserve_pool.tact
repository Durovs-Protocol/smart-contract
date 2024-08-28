import "@stdlib/deploy";
import "@stdlib/ownable";
import "./utils/messages.tact";
import "./user_position.tact";
import "./utils/math.tact";

contract ReservePool with Deployable, OwnableTransferable {
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
            usdton: newAddress(0, 0),
            runaCoupon: newAddress(0, 0)
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
            usdton: msg.usdton,
            runaCoupon: msg.runaCoupon
        };
        self.reply("pool's dependencies set".asComment());
    }

    //=============================================================================
    // Actions
    //=============================================================================
    receive(msg: Supply){
        let ctx: Context = context();
        let remainingValue: Int = ctx.value - (msg.amount + self.GasConsumption);
        send(SendParameters{
                to: msg.user,
                bounce: false,
                value: remainingValue,
                mode: SendIgnoreErrors + SendPayGasSeparately,
                body: "Collateral added".asComment()
            }
        );
    }

    receive(msg: WithdrawRequest){
        // TODO !!! дыра! после выхода новой версии сделать проверку на то что контракт вызван up!!!
        let ctx: Context = context();
        let remainingValue: Int = ctx.value - self.GasConsumption;
        send(SendParameters{
                to: sender(),
                value: msg.amount + remainingValue,
                mode: SendBounceIfActionFail,
                bounce: true,
                body: WithdrawResponce{amount: msg.amount}.toCell()
            }
        );
    }

    // bounced(msg: bounced<WithdrawResponce>){
    //This message is small enough for bounce receiver, you need to remove bounced modifier. ??
    //TODO
    // }

    receive(msg: DoLiquidation){
        // покупка usdton для последующего сжигания
        send(SendParameters{
                to: self.deps.usdton,
                value: msg.price,
                mode: SendRemainingValue,
                bounce: true,
                body: DexMessage{
                    walletOwner: myAddress(),
                    amount: msg.amount,
                    position: msg.position,
                    price: msg.price
                }.toCell()
            }
        );
    }

    receive(msg: DexNotification){
        // сжигание купленных токенов с кошелька позиции
        send(SendParameters{
                to: self.deps.usdton,
                value: 0,
                mode: SendRemainingValue,
                body: BurnRequest{
                    user: myAddress(),
                    amount: msg.amount,
                    withdrawalAmount: 0,
                    fee: 0,
                    notificationAddress: msg.position
                }.toCell()
            }
        );
    }

    receive(msg: FeePayment){
        // Принимаем TON при ликвидаци
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