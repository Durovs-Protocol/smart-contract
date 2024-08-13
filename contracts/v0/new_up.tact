import "@stdlib/deploy";
import "@stdlib/ownable";
import "../utils/math.tact";
import "../utils/messages.tact";
import "../utils/helpers.tact";

contract NewUp  {
    const MinTonsForStorage: Int = ton("0.01");
    const GasConsumption: Int = ton("0.01");
    user: Address;
    manager: Address;
    reservePool: Address;
    debt: Int;
    debtBeforeBurn: Int = 0;

    positionAddress: Address;
    collateral: Int;
    collateralBefore: Int = 0;
    message: Message;
    version: String = "v1";

    init(user: Address, usdton: Address, manager: Address, reservePool: Address, profitPool: Address) {
        self.user = user; 
        self.manager = manager;
        self.reservePool = reservePool;

        self.collateral = 0;
        self.debt = 0;
        self.positionAddress = newAddress(0,0);
        self.message = Message{
            timestamp: 0,
            message: "Position Created"
        };
    }
    receive(msg: SetState) {
        self.collateral = msg.collateral;
        self.debt = msg.debt;

        let remainingValue: Int = myBalance() - (self.MinTonsForStorage + self.GasConsumption);

        send(SendParameters{
                to: self.manager,
                value: remainingValue,
                bounce: true,
                body: AddPositionId {
                    user: self.user
                }.toCell()
            }
        );


    }

    receive(msg: SetPositionAddress) {
        if (self.positionAddress == newAddress(0,0)) {
            self.positionAddress = msg.address;
        }

        send(SendParameters{to: self.manager, value: 0, mode: SendRemainingValue, bounce: false, body: OnMigrationComplete{

        }.toCell()});
    }
}
