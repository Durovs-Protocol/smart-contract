import "@stdlib/deploy";
import "@stdlib/stoppable";
struct ProductStruct {
    id: Int as uint256;
    name: String?;
    description: String?;
    productAddress: Address;
    isDepricated: Bool;
    pool: Address;
}
message SetInfo {
    name: String;
    description: String;
}
message PoolInfo {
    address: Address;
}

contract Product with Deployable, Resumable {
    owner: Address;
    stopped: Bool;
    productInstance: ProductStruct;
    pool: Address;
    productAddress: Address;
    init(instanceId: Int){
        self.owner = sender();
        self.stopped = false;
        self.pool = newAddress(0, 0);
        self.productAddress = myAddress();
        self.productInstance = ProductStruct{
            id: instanceId,
            name: null,
            description: null,
            productAddress: self.productAddress,
            isDepricated: false,
            pool: self.productAddress
        };
    }

    receive(msg: SetInfo){
        self.requireOwner();
        self.productInstance.name = msg.name;
        self.productInstance.description = msg.description;
    }

    get fun getInctance(): ProductStruct {
        self.requireNotStopped();
        return self.productInstance;
    }
}
// receive("Resume") is added automatically to allow owner to resume the contract
// receive("Stop") is added automatically to allow owner to stop the contract
// get fun stopped(): Bool is added automatically to query if contract is stopped
// get fun owner(): Address is added automatically to query who the owner is