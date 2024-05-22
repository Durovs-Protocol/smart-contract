import "@stdlib/deploy";

message Add {
    queryId: Int as uint64;
    log: String;
    bio: String;
    system: String;
}

contract SecurityPackages with Deployable {
    id: Int as uint32;
    log: String;
    bio: String;
    system: String;

    init(id: Int, log: String) {
        self.id = id;
        self.log = log;
        self.bio = "";
        self.system = "Kafka";
    }

    receive(data: Add) {
        self.log += data.log;
        self.bio += data.bio;
        self.system += data.system;
    }

    get fun id(): Int {
        return self.id;
    }

    get fun bio(): String {
        return self.bio;
    }
    get fun system(): String {
        return self.system;
    }

    get fun log(): String {
        return self.log;
    }
}

