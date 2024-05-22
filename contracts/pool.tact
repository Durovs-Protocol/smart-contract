import "@stdlib/deploy";
import "@stdlib/content";
import "@stdlib/ownable";
import "./supply_token.tact";
import "./treasury.tact";
message Supply {
    amount: Int;
    toWallet: Address;
}
message Withdraw {
    YTamount: Int;
    TONamount: Int;
}

contract Pool with Deployable, Ownable {
    owner: Address;
    treasury: Address;
    YToken: Address;
    init(yToken: Address, treasury: Address){
        self.owner = sender();
        self.YToken = yToken;
        self.treasury = treasury;
    }

    receive(msg: Supply){
        self.getYToken(msg);
    }

    receive(msg: Withdraw){
        self.withdrawTon(msg);
    }

    fun getYToken(msg: Supply) {
        send(SendParameters{
                to: self.treasury,
                value: 0,
                mode: SendRemainingValue,
                body: TonToSwapJetton{sender: sender(), amount: msg.amount, queryId: 1, toWallet: msg.toWallet}.toCell()
            }
        );
    }

    fun withdrawTon(msg: Withdraw) {
        send(SendParameters{
                to: self.treasury,
                value: 0,
                mode: SendRemainingValue,
                body: TokenTransfer{
                    queryId: 1,
                    amount: msg.YTamount,
                    destination: sender(),
                    response_destination: sender(),
                    forward_ton_amount: msg.TONamount,
                    custom_payload: null,
                    forward_payload: self.createOffchainContent("JettonToSwapTon").asSlice()
                }.toCell()
            }
        );
    }

    /*
     *   static function
     */

    fun createOffchainContent(pram: String): Cell {
        let s: StringBuilder = beginStringFromBuilder(beginCell().storeBool(true).storeUint(0, 32));
        s.append(pram);
        return s.toCell();
    }
}