import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { saveAddress } from '../utils/helpers';
import { RuneCoinOwner } from '../wrappers/RunecoinOwner';

export async function run(provider: NetworkProvider) {
    const runecoinsOwner = provider.open(await RuneCoinOwner.fromInit(provider.sender().address!));

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
    console.log('RunecoinOwner deployed successfully');
    console.log('=============================================================================');
}
