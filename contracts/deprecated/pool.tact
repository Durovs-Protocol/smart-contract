import "@stdlib/deploy";
import "@stdlib/ownable";
import "./utils/messages.tact";
import "./user_position.tact";
import "./utils/math.tact";
import "./runecoin/runecoin_wallet.tact";
struct PoolState {
    pool: Int;
    income: Int;
    balance: Int;
}

contract Pool with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    owner: Address;
    state: PoolState;
    init(owner: Address){
        self.owner = owner;
        self.deps = Deps{
            managerAddress: newAddress(0, 0),
            poolAddress: newAddress(0, 0),
            usdTonAddress: newAddress(0, 0),
            runecoinAddress: newAddress(0, 0)
        };
        self.state = PoolState{pool: 0, income: 0, balance: 0};
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
        // Принимаем доход
        let value: Int = (context().value + self.state.income);
        self.state.income = value;
    }

    receive(msg: StabilityFeePayment){
        // Принимаем stability fee / от инвесторов
        // потом разделим эти процедуры
        let value: Int = ((context().value + self.state.pool) - (self.GasConsumption + self.MinTonForStorage));
        self.state.pool = value;
        send(SendParameters{
                to: self.deps.managerAddress,
                value: 0,
                bounce: false,
                mode: SendIgnoreErrors,
                body: PoolUpdateNotification{newValue: value}.toCell()
            }
        );
    }

    receive(msg: DoStabilizationTon){
        send(SendParameters{
                to: self.deps.usdTonAddress,
                value: 0,
                bounce: true,
                body: DexMessageTon{user: myAddress(), amount: msg.amount, price: msg.price}.toCell()
            }
        );
    }

    receive(msg: SellNotification){
        //приняли тон
        self.state.pool = (self.pool + msg.price);
    }

    /*|from usdTonMaster, после сжигания начисление ton*/
    receive(msg: UsdTonBurned){
        require(sender() == self.deps.usdTonAddress, "not from usdTon");
        // todo check if debt still more than repayment
        self.debt = (self.debt - msg.amount);
        if (self.message.message == "liquidationProcess") {
            self.setMessage("position liquidated");
            // Отчисление остатков после ликвидации в пул
            send(SendParameters{to: self.poolAddress, value: 0, mode: SendRemainingValue, bounce: false});
        } else {
            self.setMessage("you've paid stables back");
            // возврат пользователю остатков газа при сжигании
            send(SendParameters{
                    to: msg.user,
                    value: 0,
                    mode: (SendRemainingValue + SendIgnoreErrors),
                    bounce: false,
                    body: self.message.message.asComment()
                }
            );
        }
    }

    receive(msg: DoStabilizationUsdton){
        if (self.state.pool < msg.price) {
            send(SendParameters{
                    to: self.deps.managerAddress,
                    value: 0,
                    mode: SendRemainingValue,
                    bounce: true,
                    body: "reserve is less than needed".asComment()
                }
            );
            return ;
        }
        send(SendParameters{
                to: self.deps.usdTonAddress,
                value: msg.price,
                mode: SendPayGasSeparately,
                bounce: true,
                body: DexMessage{user: myAddress(), amount: msg.amount}.toCell()
            }
        );
        //отправка ton на dex
        self.state.pool = (self.state.pool - msg.price);
    }

    receive(msg: DexNotification){
        send(SendParameters{
                to: self.deps.managerAddress,
                value: 0,
                bounce: false,
                mode: SendIgnoreErrors,
                body: PoolUpdateNotification{newValue: self.state.pool}.toCell()
            }
        );
        send(SendParameters{
                to: self.deps.managerAddress,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: "stabilization complete".asComment()
            }
        );
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

    get fun state(): PoolState {
        return self.state;
    }
}