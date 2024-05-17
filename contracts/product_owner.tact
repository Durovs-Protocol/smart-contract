import "@stdlib/deploy";
import "@stdlib/ownable";
import "./product.tact";
message CreateProduct {
    name: String;
    description: String;
}
message UpdateProduct {
    id: Int;
    name: String;
    description: String;
}
message SetPool {
    id: Int;
    address: Address;
}

contract ProductOwner with Deployable, Ownable {
    owner: Address;
    products: map<Int, Address>;
    nextd: Int as uint32;
    init(){
        self.owner = sender();
        self.nextd = 1;
        self.products = emptyMap();
    }

    fun createProduct(name: String, desc: String) {
        self.requireOwner();
        let init: StateInit = initOf Product(self.nextd);
        let address: Address = contractAddress(init);
        send(SendParameters{to: address, value: ton("0.2"), mode: SendIgnoreErrors, code: init.code, data: init.data});
        self.products.set(self.nextd, address);
        self.nextd += 1;
    }

    get fun getProductAddress(id: Int): Address? {
        return self.products.get(id);
    }

    get fun getProducts(): map<Int, Address> {
        return self.products;
    }

    receive(msg: CreateProduct){
        self.requireOwner();
        self.nextd += 1;
        let init: StateInit = initOf Product(self.nextd);
        let address: Address = contractAddress(init);
        send(SendParameters{
                to: address,
                body: SetInfo{name: msg.name, description: msg.description}.toCell(),
                value: ton("0.02"),
                mode: SendIgnoreErrors,
                code: init.code,
                data: init.data
            }
        );
        self.products.set(self.nextd, address);
    }

    receive(msg: UpdateProduct){
        self.requireOwner();
        let address: Address = self.getProductAddress(msg.id)!!;
        require(address != null, "Contract does not exist");
        send(SendParameters{
                to: address,
                body: SetInfo{name: msg.name, description: msg.description}.toCell(),
                value: ton("0.02"),
                mode: SendIgnoreErrors
            }
        );
    }

    receive(msg: SetPool){
        self.requireOwner();
        let address: Address = self.getProductAddress(msg.id)!!;
        require(address != null, "Contract does not exist");
        send(SendParameters{
                to: address,
                body: PoolInfo{address: msg.address}.toCell(),
                value: ton("0.02"),
                mode: SendIgnoreErrors
            }
        );
    }
}