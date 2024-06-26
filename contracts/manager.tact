import "./user_position.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";
import "./utils/messages.tact";

contract Manager with Deployable, OwnableTransferable {
    const MinTonsForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    owner: Address;
    lastPositionId: Int as uint32 = 0;
    init(owner: Address){
        self.owner = owner;
        self.deps = Deps{
            positionsManagerAddress: newAddress(0, 0),
            poolAddress: newAddress(0, 0),
            stablecoinMasterAddress: newAddress(0, 0),
            runecoinAddress: newAddress(0, 0)
        };
    }

    //setup
    receive(msg: SetDeps){
        self.requireOwner();
        self.deps = Deps{
            positionsManagerAddress: msg.positionsManagerAddress,
            poolAddress: msg.poolAddress,
            stablecoinMasterAddress: msg.stablecoinMasterAddress,
            runecoinAddress: msg.runecoinAddress
        };
        self.reply("deps set".asComment());
    }

    /*01 | Внесение обеспечения пользователем (from pool)'
    deploy user position
    добавление обеспечения
    */
    receive(msg: DepositCollateralMessage){
        let ctx: Context = context();
        let init: StateInit = initOf UserPosition(msg.user,
            self.deps.stablecoinMasterAddress,
            self.deps.positionsManagerAddress,
            self.deps.runecoinAddress
        );
        let userPosition: Address = contractAddress(init);
        send(SendParameters{
                to: userPosition,
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: msg.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    /*01 | (from userPosition)
        deploys positionAddressConrtact that stores positionId and position address
        used to get position address by id for liquidations
    */

    receive(msg: NewPositionIdMessage){
        self.onlyUserPosition(msg.user);
        self.lastPositionId = (self.lastPositionId + 1);
        let init: StateInit = initOf PositionAddressContract(self.lastPositionId, myAddress());
        let positionAddress: Address = contractAddress(init);
        send(SendParameters{
                to: positionAddress,
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: SetPositionAddressMessage{user: msg.user, position: sender()}.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    /*02 | Начисление USDTON пользователю (from pool)'*/
    receive(msg: WithdrawStablecoinMessage){
        dump("Начисление USDTON пользователю (from pool)'*/");
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    /*02 |  call pool.increaseTotalStable(amount) (from userPosition)'*/
    receive(msg: IncreaseTotalStableMessage){
        self.onlyUserPosition(msg.user);
        send(SendParameters{
                to: self.deps.poolAddress,
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    /*03 | Погашение задолженности (from pool)'*/
    receive(msg: RepayStablecoinMessage){
        require(sender() == self.deps.poolAddress, "not from pool");
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    /*03 | call pool.decreaseTotalStable (from userPosition)'*/
    receive(msg: DecreaseTotalStableMessage){
        self.onlyUserPosition(msg.user);
        send(SendParameters{
                to: self.deps.poolAddress,
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    /*04 | Возврат обеспечения (from pool)'*/
    receive(msg: WithdrawCollateralMessage){
        require(sender() == self.deps.poolAddress, "not from pool");
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    /*04 | Передача сообщения пулу после расчетов (from userPosition)'*/
    receive(msg: DoWithdrawCollateralMessage){
        self.onlyUserPosition(msg.user);
        send(SendParameters{
                to: self.deps.poolAddress,
                value: 0,
                mode: (SendRemainingValue + SendBounceIfActionFail),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    //helpers
    fun onlyUserPosition(user: Address) {
        // todo enable next line
        // nativeThrowUnless(132, self._userPositionAddress(user) == sender());
    }

    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf UserPosition(user,
            self.deps.stablecoinMasterAddress,
            self.deps.positionsManagerAddress,
            self.deps.runecoinAddress
        );
        return contractAddress(init);
    }

    // offchain interface

    get fun lastPositionId(): Int {
        return self.lastPositionId;
    }

    get fun userPositionAddress(user: Address): Address {
        return self._userPositionAddress(user);
    }

    get fun userPositionAddressById(id: Int): Address {
        let init: StateInit = initOf PositionAddressContract(id, myAddress());
        return contractAddress(init);
    }

    get fun deps(): Deps {
        return self.deps;
    }
}

// this contract stores positionaddress by position id
// for liquidators mostly
contract PositionAddressContract with Deployable {
    id: Int as uint32;
    positionAddress: Address;
    positionsManagerAddress: Address;
    init(id: Int, manager: Address){
        let ctx: Context = context();
        self.id = id;
        self.positionAddress = newAddress(0, 0);
        self.positionsManagerAddress = manager;
    }

    /*
        message came from userPosition
        set position address
        now we can determine this contract address by positionId 
        and get positionAddress by getter
    */
    receive(msg: SetPositionAddressMessage){
        require(sender() == self.positionsManagerAddress, "Invalid sender");
        require(self.positionAddress == newAddress(0, 0), "Already set");
        self.positionAddress = msg.position;
        dump("pay excess");
        // pay excess to user
        send(SendParameters{to: msg.user, bounce: false, value: 0, mode: (SendRemainingValue + SendBounceIfActionFail)}
        );
    }

    get fun positionAddress(): Address {
        return self.positionAddress;
    }
}