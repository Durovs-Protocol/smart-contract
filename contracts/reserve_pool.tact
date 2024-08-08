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
        self.owner = owner;
        self.deps = Deps{
            manager: newAddress(0, 0),
            profitPool: newAddress(0, 0),
            reservePool: newAddress(0, 0),
            usdton: newAddress(0, 0)
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
            usdton: msg.usdton
        };
        self.reply("pool's dependencies set".asComment());
    }

    //=============================================================================
    // Actions
    //=============================================================================
    // receive(msg: DepositMessage){
    //     require(sender() == self.deps.manager, "not from positionsManager");
    //     let ctx: Context = context();
    //     let init: StateInit = initOf UserPosition(msg.user,
    //         self.deps.usdton,
    //         self.deps.manager,
    //         self.deps.reservePool,
    //         self.deps.profitPool
    //     );
    //     let userPosition: Address = contractAddress(init);
    //     let remainingValue: Int = (ctx.value - ((msg.amount + self.MinTonForStorage) + self.GasConsumption));
    //     send(SendParameters{
    //             to: userPosition,
    //             bounce: false,
    //             value: remainingValue,
    //             mode: (SendIgnoreErrors + SendPayGasSeparately),
    //             body: DepositNotification{amount: msg.amount, user: msg.user}.toCell(),
    //             code: init.code,
    //             data: init.data
    //         }
    //     );
    // }
    receive(msg: Deposit){
        let ctx: Context = context();
        let remainingValue: Int = (ctx.value - (msg.amount + self.GasConsumption));
        send(SendParameters{
                to: msg.user,
                bounce: false,
                value: remainingValue,
                mode: (SendIgnoreErrors + SendPayGasSeparately),
                body: "Collateral added".asComment()
            }
        );
    }

    receive(msg: UsdTonBurned){
        require(sender() == self.deps.usdton, "not from usdTon");
        // let ctx: Context = context();
        // let myAddress: Address = myAddress();
        // if (msg.user != myAddress) {
        //     send(SendParameters{
        //             to: msg.notificationAddress!!,
        //             value: msg.withdrawalAmount,
        //             mode: SendRemainingValue,
        //             bounce: false,
        //             body: OnBurnComplete{ton: msg.withdrawalAmount, usdton: msg.amount, fee: msg.fee}.toCell()
        //         }
        //     );
        // } else {
        send(SendParameters{
                to: msg.notificationAddress!!,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: OnLiquidationComplete{amount: msg.amount}.toCell()
            }
        );
        // }
    }

    receive(msg: WithdrawRequest){
        // TODO !!! дыра! после выхода новой версии сделать проверку на то что контракт вызван up!!!
        let ctx: Context = context();
        let remainingValue: Int = (ctx.value - self.GasConsumption);
        send(SendParameters{
                to: sender(),
                value: (msg.amount + remainingValue),
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

    receive(msg: LiquidationPool){
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
                body: BurnMessage{
                    user: myAddress(),
                    amount: msg.amount,
                    reservePool: myAddress(),
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