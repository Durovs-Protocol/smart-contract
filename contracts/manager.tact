import "./user_position.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";

contract Manager with Deployable, Ownable {
    const MinTonsForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    owner: Address;
    lastPositionId: Int as uint32 = 0;
    init(){
        self.owner = sender();
        self.deps = Deps{
            positionsManagerAddress: newAddress(0, 0),
            poolAddress: newAddress(0, 0),
            stablecoinMasterAddress: newAddress(0, 0)
        };
    }

    receive(msg: SetDeps){
        self.requireOwner();
        self.deps = Deps{
            positionsManagerAddress: msg.positionsManagerAddress,
            poolAddress: msg.poolAddress,
            stablecoinMasterAddress: msg.stablecoinMasterAddress
        };
        self.reply("deps set".asComment());
    }

    /*
        message came from pool
        deploy new user position (if needed) 
        and call userPosition.addCollateral
    */
    receive(msg: DepositCollateralMessage){
        let ctx: Context = context();

        // require(ctx.value > msg.amount + fwdFee + 2 * self.GasConsumption + self.MinTonsForStorage, "Invalid value");

        let init: StateInit = initOf UserPositionContract(msg.user,
            self.deps.stablecoinMasterAddress,
            self.deps.positionsManagerAddress
        );
        let userPosition: Address = contractAddress(init);
        send(SendParameters{
                to: userPosition,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: msg.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    receive(msg: NewPositionIdMessage){
        self.onlyUserPosition(msg.user);
        self.lastPositionId = (self.lastPositionId + 1);
        let init: StateInit = initOf PositionAddressContract(self.lastPositionId);
        let positionAddress: Address = contractAddress(init);
        send(SendParameters{
                to: positionAddress,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: SetPositionAddressMessage{user: msg.user, position: sender()}.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    receive(msg: WithdrawStablecoinMessage){
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    /*  
        message came from userPosition
        call pool.increaseTotalStable(amount)
    */
    receive(msg: IncreaseTotalStableMessage){
        self.onlyUserPosition(msg.user);
        send(SendParameters{
                to: self.deps.poolAddress,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    /*  
        message came from pool
        call userPosition.repayStable()
    */
    receive(msg: RepayStablecoinMessage){
        require(sender() == self.deps.poolAddress, "not from pool");
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    /*  
        message came from userPosition
        call pool.decreaseTotalStable
    */
    receive(msg: DecreaseTotalStableMessage){
        self.onlyUserPosition(msg.user);
        send(SendParameters{
                to: self.deps.poolAddress,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    /*  
        message came from pool
        call userPosition.withdrawCollateral
    */
    receive(msg: WithdrawCollateralMessage){
        require(sender() == self.deps.poolAddress, "not from pool");
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    /*  
        message came from userPosition
        call pool.doWithdrawCollateral(DoWithdrawCollateralMessage)
    */
    receive(msg: DoWithdrawCollateralMessage){
        self.onlyUserPosition(msg.user);
        send(SendParameters{
                to: self.deps.poolAddress,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: msg.toCell()
            }
        );
    }

    fun onlyUserPosition(user: Address) {
        // todo enable next line
        // nativeThrowUnless(132, self._userPositionAddress(user) == sender());
    }

    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf UserPositionContract(user,
            self.deps.stablecoinMasterAddress,
            self.deps.positionsManagerAddress
        );
        return contractAddress(init);
    }

    get fun lastPositionId(): Int {
        return self.lastPositionId;
    }

    get fun userPositionAddress(user: Address): Address {
        return self._userPositionAddress(user);
    }

    // todo add test

    get fun userPositionAddressById(id: Int): Address {
        let init: StateInit = initOf PositionAddressContract(id);
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
    init(id: Int){
        let ctx: Context = context();
        self.id = id;
        self.positionAddress = newAddress(0, 0);
        self.positionsManagerAddress = ctx.sender;
    }

    /*
        message came from userPosition
        set position address
        now we can determine this contract address by positionId 
        and get positionAddress by getter
    */
    receive(msg: SetPositionAddressMessage){
        // todo enable access check below
        require(sender() == self.positionsManagerAddress, "Invalid sender");
        require(self.positionAddress == newAddress(0, 0), "Already set");
        self.positionAddress = msg.position; //msg.positionAddress;

        dump("pay excess");
        // pay excess to user
        send(SendParameters{to: msg.user, bounce: false, value: 0, mode: (SendRemainingValue + SendIgnoreErrors)});
    }

    get fun positionAddress(): Address {
        return self.positionAddress;
    }
}