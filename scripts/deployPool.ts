import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { saveAddress } from '../utils/helpers';
import { Pool } from '../wrappers/Pool';

export async function run(provider: NetworkProvider) {
    const poolContract = provider.open(await Pool.fromInit());

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

    await provider.waitForDeploy(poolContract.address);
    await saveAddress('pool_contract', poolContract.address);
    console.log(
        '----------------------------------------------------------------------------------pool contract deployed successfully',
    );
    // run methods on `poolContract`
}
