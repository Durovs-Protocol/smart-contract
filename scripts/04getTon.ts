import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { JettonDefaultWallet as JettonWallet } from '../build/SupplyToken/tact_JettonDefaultWallet';
import { Treasury } from '../build/Treasury/tact_Treasury';
import { cell, jettonAddress } from '../utils/helpers';

export async function run(provider: NetworkProvider) {

    const user = provider.sender().address as Address;
    const treasury = provider.open(await Treasury.fromInit(jettonAddress, user));
    const jettonWallet = provider.open(await JettonWallet.fromInit(jettonAddress, user));
    
    const tonAmount = toNano(0.05);
    const jettonAmount = toNano(5);
//Отправка ST пользователем в хранилище и возврат TON
    await jettonWallet.send(
        provider.sender(),
        {
            value: toNano('0.1') + tonAmount,
        },
        {
            $$type: "TokenTransfer",
            queryId: 1n,
            amount: jettonAmount,
            destination: treasury.address,
            response_destination: user,
            custom_payload: cell("first swap ton"),
            forward_ton_amount: tonAmount,
            forward_payload: cell("JettonToSwapTon"),
        }
    );
    await provider.waitForDeploy(jettonWallet.address);
}
