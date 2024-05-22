import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';

import { JettonDefaultWallet as JettonWallet } from '../build/SupplyToken/tact_JettonDefaultWallet';
import { SupplyToken } from '../build/SupplyToken/tact_SupplyToken';
import { Treasury } from '../build/Treasury/tact_Treasury';
import { content, jettonAddress, maxSupply } from '../utils/helpers';

export async function run(provider: NetworkProvider) {

    const deployer = provider.sender().address as Address;
    const treasury = provider.open(await Treasury.fromInit(jettonAddress, deployer));

    await treasury.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(treasury.address);
    console.log('----------------treasury deployed--------------------------')

    const sampleJetton = provider.open(await SupplyToken.fromInit(deployer, content, maxSupply));

    const amount = toNano('100');
    await sampleJetton.send(
        provider.sender(),
        {
            value: toNano('0.5'),
        },
        {
            $$type: 'Mint',
            amount: amount,
            receiver: treasury.address,
        }
    );

    await provider.waitForDeploy(sampleJetton.address);
    const treasury_jetton_wallet = provider.open(await JettonWallet.fromInit(sampleJetton.address, treasury.address));

    console.log(`mint to treasury: ${(await treasury_jetton_wallet.getGetWalletData()).balance}`)
    console.log(`treasury balance: ${(await treasury_jetton_wallet.getGetWalletData()).balance}`)

    await treasury.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'SetMyJettonWallet',
            wallet: treasury_jetton_wallet.address,
        }
    );
    await provider.waitForDeploy(treasury.address);
    console.log('----------------set wallet to treasury-------------------------')
}