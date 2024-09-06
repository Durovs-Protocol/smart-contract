import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { setupGas } from '../utils/data';
import { createAssetsList, saveAddress } from '../utils/helpers';
import { ReservePool } from '../wrappers/ReservePool';

export async function run(provider: NetworkProvider) {
    const reservePool = provider.open(await ReservePool.fromInit(provider.sender().address!));

    await reservePool.send(
        provider.sender(),
        {
            value: toNano(setupGas),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(reservePool.address, 30);
    await saveAddress('reservePool', reservePool.address);
    await createAssetsList(reservePool.address.toString(), provider, 'v0')

    console.log('=============================================================================');
    console.log('Reserve pools deployed successfully');
    console.log('=============================================================================');
}
