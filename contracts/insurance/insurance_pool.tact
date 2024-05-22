import "@stdlib/deploy";

message Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}

contract InsurancePool with Deployable {
    id: Int as uint32;
    amount: Int as uint32;
    title: String;
    type: String;

    init(id: Int) {
        self.id = id;
        self.title = "Uniswap v3";
        self.type = "Standart";
        self.amount = 0;
    }

    receive(msg: Add) {
        self.amount += msg.amount;
    }

    get fun id(): Int {
        return self.id;
    }

    get fun title(): String {
        return self.title;
    }
    get fun type(): String {
        return self.type;
    }

    get fun amount(): Int {
        return self.amount;
    }
}
