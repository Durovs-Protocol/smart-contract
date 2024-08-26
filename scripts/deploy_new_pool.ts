import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { setupGas } from '../utils/data';
import { saveAddress } from '../utils/helpers';
import { NewReservePool } from '../wrappers/V0.NewPool';

export async function run(provider: NetworkProvider) {
    const newPool = provider.open(await NewReservePool.fromInit(provider.sender().address!));

    await newPool.send(
        provider.sender(),
        {
            value: toNano(setupGas),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(newPool.address, 30);
    await saveAddress('new_pool', newPool.address);
    console.log('=============================================================================');
    console.log('New pool deployed successfully');
    console.log('=============================================================================');
}
