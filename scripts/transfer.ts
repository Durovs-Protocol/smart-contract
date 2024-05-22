import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { JettonDefaultWallet } from '../build/SupplyToken/tact_JettonDefaultWallet';
import { cell } from '../utils/helpers';

export async function run(provider: NetworkProvider) {
    const jetton = Address.parse("EQAMkP-Vtx-i_txjPRkY9ZpL8BCDXOzcIhxOwwU2ae9FfzKk");
    const to = Address.parse("00000000");
    const user = provider.sender().address as Address;
    const jettonWallet = provider.open(await JettonDefaultWallet.fromInit(jetton, user));
    
    await jettonWallet.send(
        provider.sender(),
        {
            value: toNano('0.5'),
        },
        {
            $$type: "TokenTransfer",
            queryId: 1n,
            amount: toNano('7'),
            destination: to,
            response_destination: user,
            custom_payload: cell("transfer"),
            forward_ton_amount: toNano('0.2'),
            forward_payload: cell("transfer"),
        }
    );

    await provider.waitForDeploy(jettonWallet.address);
}
