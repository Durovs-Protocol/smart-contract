import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { saveAddress } from '../utils/helpers';
import { RuneCoinsOwner } from '../wrappers/RunecoinsOwner';

export async function run(provider: NetworkProvider) {
    const runecoinsOwner = provider.open(await RuneCoinsOwner.fromInit(provider.sender().address!));

    await runecoinsOwner.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(runecoinsOwner.address, 30);
    await saveAddress('runecoins_owner', runecoinsOwner.address);

    console.log('=============================================================================');
    console.log('RunecoinsOwner deployed successfully');
    console.log('=============================================================================');
}
