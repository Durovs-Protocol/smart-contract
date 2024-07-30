import "./jetton.tact";
import "./runecoin_wallet.tact";
import "../utils/messages.tact";
import "@stdlib/deploy";

message Mint {
    amount: Int;
}

struct Holders {
    supply: Address;
    foundersTeam: Address;
    foundation: Address;
    dao: Address;
    private: Address;
    preSeed: Address;
    seed: Address;
    airdrop: Address;
    advisors: Address;
    publicSales: Address;
    marketMaking: Address;
}

message SetHolders {
    holders:  map<Address, Int>;
    holdersInfo:  Holders;
}


contract Runecoin with Jetton, Deployable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell?;
    mintable: Bool;
    message: String;
    holders: map<Address, Int>;
    holdersInfo: Holders;


    init(owner: Address, content: Cell?) {
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.message = "";
        self.holders = emptyMap();
        self.holdersInfo = Holders{
            supply: newAddress(0, 0),
            foundersTeam: newAddress(0, 0),
            foundation: newAddress(0, 0),
            dao:newAddress(0, 0),
            private: newAddress(0, 0),
            preSeed: newAddress(0, 0),
            seed: newAddress(0, 0),
            airdrop: newAddress(0, 0),
            advisors: newAddress(0, 0),
            publicSales: newAddress(0, 0),
            marketMaking:newAddress(0, 0)
        };
    }

    receive(msg: SetHolders) {
      self.holders = msg.holders;
      self.holdersInfo = msg.holdersInfo;
    }


    receive(msg: Mint) {
      self.requireOwner();
      let ctx: Context = context();

      let addresses: map<Address, Int> = self.holders;

      foreach (key, value in addresses) {
        let amount: Int = msg.amount * value / 1000000000;
        self.mint(key, amount, key, ton("0.3"));
      }

    }

    // Имитация покупки, выпуск без увеличения значения supply
    receive(msg: DexMessage) {
        let winit: StateInit = self.getJettonWalletInit(msg.user);
        let walletAddress: Address = contractAddress(winit);

        send(SendParameters {
                to: walletAddress,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransferInternal{
                    amount: msg.amount,
                    queryId: 0,
                    from: myAddress(),
                    responseAddress: msg.user,
                    forwardTonAmount: 0,
                    forwardPayload: emptySlice()
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    get fun userRunaCoinAddress(userAddress: Address): Address{ 
        let winit: StateInit = self.getJettonWalletInit(userAddress);
        let walletAddress: Address = contractAddress(winit);
        return walletAddress;
    }



    receive(msg: MintMessage) {
        let ctx: Context = context();
        self.mint(msg.user, msg.amount, msg.user, ctx.value);
    }

    get fun totalSupply(): Int {
        return self.totalSupply;
    }

    get fun message(): String {
        return self.message;
    }

    get fun myWallet(): Address {
        let winit: StateInit = self.getJettonWalletInit(sender());
        let walletAddress: Address = contractAddress(winit);
        return walletAddress;
    }

    get fun holders(): map<Address, Int> {
        return self.holders;
    }

    get fun holdersInfo(): Holders {
        return self.holdersInfo;
    }
}
