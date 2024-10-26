import "@stdlib/deploy";
import "@stdlib/ownable";
import "./up__pool.tact";
import "./utils/messages.tact";

contract V1Manager with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    deps: Deps;
    assets: map<Address, Asset>;
    balances: map<Address, Int>;
    settings: Settings;
    owner: Address;
    lastPositionId: Int = 0;
    lastMigrationId: Int = 0;
    version: String = "1";
    oldManager: Address;
    rates: map<Address, Int>;
    couponsForBuy: Int;
    couponsForSell: Int;

    init(owner: Address, oldManager: Address){
        require(owner == sender(), "Durovs Protocol: No access to init manager");
        self.owner = sender();
        self.settings = Settings{minDelay: 0, newManager: newAddress(0, 0), maxExecutionTime: 0, couponRate: 0};
        self.deps = Deps{
            manager: newAddress(0, 0),
            profitPool: newAddress(0, 0),
            reservePool: newAddress(0, 0),
            stable: newAddress(0, 0),
            coupon: newAddress(0, 0)
        };
        self.assets = emptyMap();
        self.balances = emptyMap();
        self.oldManager = oldManager;
        self.rates = emptyMap();
        self.couponsForBuy = 0;
        self.couponsForSell = 0;



    }

    //=============================================================================
    // Set Deps
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
        self.reply("Durovs Protocol: Manager's dependencies set".asComment());
    }

    //=============================================================================
    // Set Settings
    //=============================================================================
    receive(msg: SetSettings){
        self.requireOwner();
        self.settings = Settings{
            minDelay: msg.minDelay,
            newManager: msg.newManager,
            maxExecutionTime: msg.maxExecutionTime,
            couponRate: msg.couponRate
        };
        self.reply("Durovs Protocol: Settings have been updated".asComment());
    }

    receive(msg: SetAssets){
        self.requireOwner();
        self.assets = msg.assets;
        self.reply("Durovs Protocol: New Manager assets set".asComment());
    }
    // нужно этот кусок переделать, формировать из assets балансы в up
    receive(msg: SetBalances){
        self.requireOwner();
        self.balances = msg.balances;
        self.reply("Durovs Protocol: New Manager balances template set".asComment());
    }

    receive(str: String){

        // приимаем текстовые сообщения и перенаправляем их владельцу контракта
        send(SendParameters{to: self.owner, value: 0, mode: SendRemainingValue, bounce: false, body: str.asComment()});
    }

    //=============================================================================
    // User actions
    //=============================================================================
    receive(msg: SupplyMessage) {

        let ctx: Context = context();
        require(sender() == self.deps.reservePool, "Durovs Protocol: Invalid sender");
  
        let init: StateInit = initOf V1UserPosition(msg.user,
            self.deps.manager,
            self.deps.reservePool,
            self.deps.stable,
            self.balances
        );
        let userPosition: Address = contractAddress(init);


        send(SendParameters{
                to: userPosition,
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: Supply{
                    user: msg.user,
                    amount: msg.amount,
                    master: msg.master,
                    userWallet: msg.userWallet
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }


    receive(msg: PaymentMessage) {

        let ctx: Context = context();
        require(sender() == self.deps.reservePool, "Durovs Protocol: Invalid sender");

        // let valueToSendForward: Int = ctx.value - (self.MinTonForStorage + self.GasConsumption + self.GasConsumption);
        let init: StateInit = initOf V1UserPosition(msg.user,
            self.deps.manager,
            self.deps.reservePool,
            self.deps.stable,
            self.balances
        );
        let userPosition: Address = contractAddress(init);

        send(SendParameters{
                to: userPosition,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,

                body: Payment{
                    user: msg.user,
                    amount: msg.amount,
                    master: msg.master,
                    userWallet: msg.userWallet,
                    order: msg.order,
                    receiver: msg.receiver,
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }
    /* ok */
    bounced(msg: bounced<Payment>){

        self.bouncedHandler("Durovs Protocol: Error in payment.");
    }
    /* ok */
    bounced(msg: bounced<Supply>){
        self.bouncedHandler("Durovs Protocol: Error in supply.");
    }

    receive(msg: AddPositionId){
        self.lastPositionId = self.lastPositionId + 1;
        let init: StateInit = initOf V1PositionKeeper(self.lastPositionId, myAddress());
        let positionAddress: Address = contractAddress(init);

        send(SendParameters{
                to: positionAddress,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: true,
                body: SetAddress{user: msg.user, position: sender()}.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    /*04 | withdraw TON */
    receive(msg: WithdrawMessage){
        send(SendParameters{
                to: self._userPositionAddress(sender()),
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: Withdraw{
                    user: sender(),
                    amount: msg.amount,
                    master: msg.master,
                    minDelay: self.settings.minDelay,
                    maxExecutionTime: self.settings.maxExecutionTime,
                    pool: self.deps.reservePool,
                    rates: self.rates
                }.toCell()
            }
        );
    }

    bounced(msg: bounced<Withdraw>){
        self.bouncedHandler("Durovs Protocol: Error in withdrawal");
    }

    /* ==Migration== (обработка миграции с предыдущей версии) */
    receive(msg: BuildPosition){
        //!! вернуть после теста !!
        // require(sender() == self.oldManager, "Durovs Protocol: Unable to create a new position");
        let init: StateInit = initOf V1UserPosition(msg.user,
            self.deps.manager,
            self.deps.reservePool,
            self.deps.stable,
            self.balances
        );
        let newUserPosition: Address = contractAddress(init);
        send(SendParameters{
                to: newUserPosition,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: SetState{
                    balances: msg.balances,
                    supplyTimestamps: msg.supplyTimestamps,
                    updatedTimestamps: msg.updatedTimestamps,
                    withdrawState: msg.withdrawState,
                    lastWithdrawalRequest: msg.lastWithdrawalRequest,
                    wallets: msg.wallets
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    receive(msg: OnMigrationComplete){
        send(SendParameters{to: self.owner, bounce: false, value: 0, mode: SendRemainingValue + SendIgnoreErrors});
    }

    /* ==Migration== (обработка миграции на новую версию) */
    receive(msg: Migration){
        self.requireOwner();
        let init: StateInit = initOf V1PositionKeeper(msg.id, myAddress());
        let positionAddress: Address = contractAddress(init);
        self.lastMigrationId = msg.id;
        send(SendParameters{
                to: positionAddress,
                value: 0,
                mode: SendBounceIfActionFail + SendRemainingValue,
                bounce: true,
                body: InformationRequest{}.toCell()
            }
        );
    }

    receive(msg: InformationResponce){
        let init: StateInit = initOf V1PositionKeeper(self.lastMigrationId, myAddress());
        let positionAddress: Address = contractAddress(init);
        require(sender() == positionAddress, "Durovs Protocol: No access for migration");
        send(SendParameters{
                to: self._userPositionAddress(msg.user),
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: MigrationRequest{newManager: self.settings.newManager}.toCell()
            }
        );
    }

    //для миграции с v1 раскомментировать
    // receive(msg: BuildNewPosition) {
    //     require(sender() == self._userPositionAddress(msg.user), "Durovs Protocol: No access for migration");
    //     send(SendParameters{
    //             to: self.settings.newManager,
    //             value: 0,
    //             mode: SendRemainingValue,
    //             bounce: true,
    //             body: msg.toCell(),
    //         }
    //     );
    // }

    // receive(msg: DeleteManager){
    //     self.requireOwner();
    //     send(SendParameters{
    //             to: self.owner,
    //             value: 0,
    //             mode: SendRemainingBalance + SendDestroyIfZero,
    //             bounce: false,
    //             body: "Manager contract deleted".asComment()
    //         }
    //     );
    // }

    //==================================NEW FEATURES===========================================
    //=============================================================================
    // Oracle
    // TODO Заменить на оракул
    //=============================================================================
    receive(msg: SetRates){
        self.requireOwner();
        self.rates = msg.rates;
        self.reply("Durovs Protocol: Rates updated".asComment());
    }

    /* Mint usdTON */
    receive(msg: MintStableMessage){
        send(SendParameters{
                to: self._userPositionAddress(sender()),
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: MintStable{user: sender(), amount: msg.amount, rates: self.rates}.toCell()
            }
        );
    }

    bounced(msg: bounced<MintStable>){
        self.bouncedHandler("Durovs Protocol: mint error");
    }

    /*| Burn usdTON */
    receive(msg: BurnStableMessage){
        send(SendParameters{
                to: self._userPositionAddress(sender()),
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: BurnStable{user: sender(), amount: msg.amount, rates: self.rates}.toCell()
            }
        );
    }

    receive(msg: ManageCoupons){
        //временное решение, нужен автоматический вызов в зависимости от курса
        let comment: StringBuilder = beginString();
        comment.append("Durovs Protocol:  ");
        comment.append(msg.amount.toFloatString(9));
        comment.append(" coupons available: ");
        comment.append(msg.type);
        if (msg.type == "buy") {
            self.offerCoupons(msg.amount);
        }
        if (msg.type == "sell") {
            self.offerCouponsExchange(msg.amount);
        }
        send(SendParameters{
                to: self.owner,
                value: 0,
                mode: SendIgnoreErrors + SendRemainingValue,
                bounce: false,
                body: comment.toString().asComment()
            }
        );
    }

    receive(msg: BuyCouponsMessage){

        let totalCoupons = (msg.amount * self.settings.couponRate) / 1000000000;

        if (self.couponsForBuy <= totalCoupons) {
            let availableAmount = (self.couponsForBuy * 1000000000) / self.settings.couponRate;
            let comment: StringBuilder = beginString();
            comment.append("Durovs Protocol: You can buy coupons for ");
            comment.append(availableAmount.toFloatString(9));
            comment.append(" durovUSD");
            // убери строку ниже
            comment.append(msg.amount.toString());
            
            send(SendParameters{
                    to: sender(),
                    value: 0,
                    mode: SendIgnoreErrors + SendRemainingValue,
                    bounce: false,
                    body: comment.toString().asComment()
                }
            );
            return;
        }
        send(SendParameters{
                to: self.deps.stable,
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: BurnForCoupons{amount: msg.amount, couponsAmount: totalCoupons, user: sender()}.toCell()
            }
        );
    }

    receive(msg: MintCouponNotification){
        self.couponsForBuy -= msg.amount;
        let comment: StringBuilder = beginString();
        comment.append("Durovs Protocol: You purchased  ");
        comment.append(msg.amount.toFloatString(9));
        comment.append(" coupons. They will be available for sale after the rate increases.");
        send(SendParameters{
                to: msg.user,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: comment.toString().asComment()
            }
        );
    }

    receive(msg: SellCoupons){

        if (self.couponsForSell <= msg.amount) {
            let comment: StringBuilder = beginString();
            comment.append("Durovs Protocol:  ");
            comment.append(self.couponsForSell.toFloatString(9));
            comment.append(" coupons available for sale");
            send(SendParameters{
                    to: sender(),
                    value: 0,
                    mode: SendIgnoreErrors + SendRemainingValue,
                    bounce: false,
                    body: comment.toString().asComment()
                }
            );
            return;
        }

        send(SendParameters{
                to: self.deps.coupon,
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: CouponExchangeRequest{amount: msg.amount,  user: sender()}.toCell()
            }
        );
    }

    receive(msg: TokenNotification) {
            let payload: Slice = msg.forwardPayload.preloadRef().beginParse();

            let prevSender: Address = payload.loadAddress();
            let user: Address = payload.loadAddress();
            
            if (prevSender == self.deps.coupon) {
                self.couponsForSell -= msg.amount;
                let comment: StringBuilder = beginString();
                comment.append("Durovs Protocol:  ");
                comment.append(msg.amount.toFloatString(9));
                comment.append(" coupons were paid,");
                comment.append(" you recieved ");
                comment.append(msg.amount.toFloatString(9));
                comment.append(" durovUSD.");

                send(SendParameters{
                        to: user,
                        value: 0,
                        mode: SendIgnoreErrors + SendRemainingValue,
                        bounce: false,
                        body: comment.toString().asComment()
                    }
                );
                return;
            }
    }

    //=============================================================================
    // Helpers
    //=============================================================================

    fun _userPositionAddress(user: Address): Address {
        let init: StateInit = initOf V1UserPosition(user, self.deps.manager, self.deps.reservePool, self.deps.stable, self.balances);
        return contractAddress(init);
    }

    fun payBack(user: Address) {
        send(SendParameters{to: user, bounce: false, value: 0, mode: SendRemainingValue + SendIgnoreErrors});
    }

    fun service(value: Int): Int {
        let balance: Int = myBalance() - value;
        let fee: Int = self.MinTonForStorage - min(balance, self.MinTonForStorage);
        return (value - fee) + self.GasConsumption;
    }

    fun bouncedHandler(reason: String) {
        send(SendParameters{
                to: self.deps.reservePool,
                bounce: false,
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                body: reason.asComment()
            }
        );
    }

    fun offerCoupons(amount: Int) {
        //TODO расчет количества купонов в зависимости от курса
        //функция должна быть вызвана из аналога оракула при определенных обстоятельсвах
        //до обсуждения этих обстоятельств я устанавливаю фиксированное количество купонов
        self.couponsForBuy = amount;
    }

    fun offerCouponsExchange(amount: Int) {
        //TODO расчет количества купонов в зависимости от курса
        //функция должна быть вызвана из аналога оракула при определенных обстоятельсвах
        //до обсуждения этих обстоятельств я устанавливаю фиксированное количество купонов
        self.couponsForSell = amount;
    }
    //=============================================================================
    // Offchain interface
    //=============================================================================

    get fun lastPositionId(): Int {
        return self.lastPositionId;
    }

    get fun userPositionAddress(user: Address): Address {
        return self._userPositionAddress(user);
    }

    get fun positionKeeper(id: Int): Address {
        let init: StateInit = initOf V1PositionKeeper(id, myAddress());
        let posKeeper: Address = contractAddress(init);
        return posKeeper;
    }

    get fun deps(): Deps {
        return self.deps;
    }

    get fun assets(): map<Address, Asset> {
        return self.assets;
    }
    get fun rates(): map<Address, Int> {
        return self.rates;
    }

    get fun settings(): Settings {
        return self.settings;
    }

    get fun balances(): map<Address, Int> {
        return self.balances;
    }

    get fun version(): String {
        return self.version;
    }

    get fun couponsForBuy(): Int {
        return self.couponsForBuy;
    }

    get fun couponsForSell(): Int {
        return self.couponsForSell;
    }
}

contract V1PositionKeeper {
        const MinTonForStorage: Int = ton("0.01");
            const GasConsumption: Int = ton("0.01");
    id: Int as uint32;
    position: Address;
    manager: Address;
    user: Address;
    init(id: Int, manager: Address){
        let ctx: Context = context();
        self.manager = ctx.sender;
        self.user = newAddress(0, 0);
        self.id = id;
        self.position = newAddress(0, 0);
    }

    receive(msg: SetAddress){

        require(self.position == newAddress(0, 0), "Already set");
        self.position = msg.position;
        self.user = msg.user;
        let ctx: Context = context();
        send(SendParameters{
                to: self.user,
                bounce: false,
                value: (ctx.value - (self.MinTonForStorage + self.GasConsumption)),
                mode: SendIgnoreErrors,
                body: "Durovs Protocol: User position has been created".asComment()
            }
        );
    }

    receive(msg: InformationRequest){
        require(self.manager == sender(), "Durovs Protocol: No access for information request");
        send(SendParameters{
                to: self.manager,
                value: 0,
                mode: SendRemainingValue + SendBounceIfActionFail,
                bounce: true,
                body: InformationResponce{user: self.user, position: self.position}.toCell()
            }
        );
    }

    get fun position(): Address {
        return self.position;
    }

    get fun user(): Address {
        return self.user;
    }
}