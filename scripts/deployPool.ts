import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { saveAddress } from '../utils/helpers';
import { Pool } from '../wrappers/Pool';

export async function run(provider: NetworkProvider) {
    const poolContract = provider.open(await Pool.fromInit(provider.sender().address!));

    await poolContract.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(poolContract.address, 30);
    await saveAddress('pool_contract', poolContract.address);

    console.log('=============================================================================');
    console.log('Pool deployed successfully');
    console.log('=============================================================================');

    // run methods on `poolContract`
}
