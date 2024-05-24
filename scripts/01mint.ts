import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import fs from 'fs';
import { JettonDefaultWallet as JettonWallet } from '../build/SupplyToken/tact_JettonDefaultWallet';
import { SupplyToken } from '../build/SupplyToken/tact_SupplyToken';
import { content, maxSupply } from '../utils/helpers';

export async function run(provider: NetworkProvider) {
    const deployer = provider.sender().address as Address;
    
    const sampleJetton = provider.open(await SupplyToken.fromInit(deployer, content, maxSupply));

    const amount = toNano('100000');

    await sampleJetton.send(
        provider.sender(),
        {
            value: toNano('0.5'),
        },
        {
            $$type: 'Mint',
            amount: amount,
            receiver: deployer,
        }
    );

    await provider.waitForDeploy(sampleJetton.address);
    let data = JSON.stringify(sampleJetton.address.toString());
    fs.writeFileSync('JettonAddress.json', data);
    console.log('---------------- sample Jetton deployed --------------------------')
    
    const user_jetton_wallet = provider.open(await JettonWallet.fromInit(sampleJetton.address, deployer));
    console.log(`user's yt: ${(await user_jetton_wallet.getGetWalletData()).balance}`)
}