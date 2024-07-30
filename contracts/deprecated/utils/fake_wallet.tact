import "@stdlib/deploy";
message CreateWallet {
}

contract FakeWallet with Deployable {
    holderName: String;
    init(holderName: String){
        self.holderName = holderName;
    }

    receive(msg: CreateWallet){
        dump(self.holderName);
    }

    get fun name(): String {
        return self.holderName;
    }
}