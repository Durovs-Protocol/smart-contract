import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { buildOnchainMetadata, saveAddress } from '../utils/helpers';
import { jettonParams } from '../utils/data';
import { Runecoin } from '../wrappers/Runecoin';

export async function run(provider: NetworkProvider) {

    const runecoin = provider.open(
        await Runecoin.fromInit(provider.sender().address!, buildOnchainMetadata(jettonParams)),
    );

    await runecoin.send(
        provider.sender(),
        {
            value: toNano('0.02'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(runecoin.address, 30);
    await saveAddress('runecoin', runecoin.address);

    console.log('=============================================================================');
    console.log('Runecoin deployed successfully');
    console.log('=============================================================================');
}
