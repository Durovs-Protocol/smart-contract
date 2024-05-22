import "@stdlib/deploy";
import "@stdlib/content";
import "./jetton";

message TonToSwapJetton{
    sender: Address;
    amount: Int;
    queryId: Int;
    toWallet: Address;
}

struct MyDescription {
    name: String = "treasury";
    description: String = "-";
}

message SetMyJettonWallet{
    wallet: Address;
}


contract Treasury with Jetton, Deployable{
    jetton: Address;
    totalSupply: Int as coins; // Already set initially 
    mintable: Bool;
    owner: Address;
    content: Cell;
    max_supply: Int; // This is not in the TEP-74 interface
    jettonReserve: Int;
    LP: map<Address, Int>;

    MyJettonWallet: Address;
    isSetMyJettonWallet: Bool;

    init(jetton: Address, owner: Address){
        self.jetton = jetton;
        self.owner = owner;
        self.MyJettonWallet = newAddress(0, 0);
        self.isSetMyJettonWallet = false;
        self.totalSupply = 0;
        self.mintable = true;
        self.content = MyDescription{}.toCell();
        self.max_supply = ton("123456766689011");
        self.jettonReserve = 0;
    }
        

    receive(msg: SetMyJettonWallet){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "The sender is not the owner!");
        require(self.isSetMyJettonWallet == false, "The jetton wallet has been set!");
        self.MyJettonWallet = msg.wallet;
        self.isSetMyJettonWallet = true;
    }

    
    receive(msg: TokenNotification){

        let ctx: Context = context();
        let jettonAmount: Int = msg.amount;

        // // jetton to swap Ton
        if (msg.forward_payload == self.createOffchainContent("JettonToSwapTon").asSlice()) {
            require(ctx.sender == self.MyJettonWallet, "sender error.");
            let tonAmount: Int = ctx.value;
            send(SendParameters{
                to: ctx.sender, 
                value: ctx.value,
                mode: 0, 
                bounce: false,
                body: "Jetton to swap Ton success!".asComment()
            });
            self.jettonReserve += jettonAmount;
        }
    }



    receive(msg: TonToSwapJetton){
        let ctx: Context = context();
        // require(msg.sender == ctx.sender, "The sender is not the same as the user!");
        // require(msg.amount > 0, "The amount of Ton is not enough!");

        // send the Jetton to the user
        self.sendJetton(msg.sender, msg.amount, msg.queryId, msg.amount);
    }

    fun sendJetton(to: Address, amount: Int, queryId: Int, value: Int){
        let ctx: Context = context();
        require(amount > 0, "The amount of Jetton is not enough!");
        require(to != newAddress(0, 0), "The address is not correct!");

        send(SendParameters{
            to: self.MyJettonWallet, 
            value: ton("0.3") + value,
            mode: SendRemainingValue, 
            bounce: false,
            body: TokenTransfer{
                queryId: queryId,
                amount: amount,
                destination: to,
                response_destination: myAddress(),
                custom_payload: createOffchainContent("custom"),
                forward_ton_amount: value,
                forward_payload: createOffchainContent("forward").asSlice()
            }.toCell()
        });
        self.jettonReserve -= amount;
    }

    /* 
     *   static function
     */

    fun createOffchainContent(pram: String): Cell {
        let s:StringBuilder = beginStringFromBuilder(beginCell().storeBool(true).storeUint(0, 32));
        s.append(pram);
        return s.toCell();
    }



    // test function
    // ===================
    get fun getTotalSupply(): Int{
        return self.totalSupply;
    }

    get fun getBalance(pram: Address): Int{
        let res: Int = self.LP.get(pram) == null ? 0 : self.LP.get(pram)!!;
        return res;
    }

    get fun getMyBalance(): Int{
        return myBalance();
    }

    get fun getJettonReserve(): Int{
        return self.jettonReserve;
    }

    get fun getOwner(): Address{
        return self.owner;
    }

    get fun getMyAddress(): Address{
        return myAddress();
    }   
}