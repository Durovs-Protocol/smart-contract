import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { setupGas } from '../utils/data';
import { createAssetsList, saveAddress } from '../utils/helpers';
import { V1ReservePool } from '../wrappers/V1Pool';

export async function run(provider: NetworkProvider) {
    const v1pool = provider.open(await V1ReservePool.fromInit(provider.sender().address!));

    await v1pool.send(
        provider.sender(),
        {
            value: toNano(setupGas),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(v1pool.address, 30);
    await saveAddress('reservePool', v1pool.address, undefined, '1');
    await createAssetsList(v1pool.address.toString(), provider)
    console.log('=============================================================================');
    console.log('New pool deployed successfully');
    console.log('=============================================================================');
}
