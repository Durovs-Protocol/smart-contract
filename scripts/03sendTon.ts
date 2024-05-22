import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { JettonDefaultWallet as JettonWallet } from '../build/SupplyToken/tact_JettonDefaultWallet';
import { Treasury } from '../build/Treasury/tact_Treasury';
import { jettonAddress } from '../utils/helpers';

export async function run(provider: NetworkProvider) {

    const user = provider.sender().address as Address;
    const teasury = provider.open(await Treasury.fromInit(jettonAddress, user));
    const jettonWallet = provider.open(await JettonWallet.fromInit(jettonAddress, user));
    const toWallet = jettonWallet.address;

    const jettonAmount = toNano(10);
    const tonAmount = toNano('0.5');

    await teasury.send(
        provider.sender(),
        {
            value: tonAmount,
        },
        {
            $$type: 'TonToSwapJetton',
            sender: toWallet ,
            amount: jettonAmount,
            queryId: 1n,
            toWallet: user,
        }
    );

    await provider.waitForDeploy(teasury.address);

    const user_jetton_wallet = provider.open(await JettonWallet.fromInit(jettonAddress, user));
    console.log(`user's balance: ${(await user_jetton_wallet.getGetWalletData()).balance}`)

    const teasury_jetton_wallet = provider.open(await JettonWallet.fromInit(jettonAddress, teasury.address));
    console.log(`teasury balance: ${(await teasury_jetton_wallet.getGetWalletData()).balance}`)
}