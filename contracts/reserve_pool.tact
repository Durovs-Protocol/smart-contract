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
    // receive(msg: DepositCollateralMessage){
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
    receive(msg: DepositCollateralMessage){
        let ctx: Context = context();
        let remainingValue: Int = (ctx.value - ((msg.amount + self.MinTonForStorage) + self.GasConsumption));
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
        send(SendParameters{
                to: msg.user,
                value: msg.collateralForWithdrawal,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: false,
                body: "you've paid stables back".asComment()
            }
        );
    }

    receive(msg: FeePayment){
        // Принимаем TON при ликвидации
        // TODO: обмен через DEX на RUNA
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