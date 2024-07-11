import "@stdlib/deploy";
import "../utils/messages.tact";

contract RuneInfo with Deployable {
    user: Address;
    runeAddress: Address;
    init(user: Address){
        self.user = user;
        self.runeAddress = newAddress(0, 0);
    }

    receive(msg: CreateInfo){
        self.runeAddress = msg.wallet;
        send(SendParameters{to: self.user, bounce: false, value: 0, mode: (SendRemainingValue + SendIgnoreErrors)});
    }

    get fun myAddress(): Address {
        return self.runeAddress;
    }
}