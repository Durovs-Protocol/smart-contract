import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { saveAddress } from '../utils/helpers';
import { ReservePool } from '../wrappers/ReservePool';

export async function run(provider: NetworkProvider) {
    const reservePool = provider.open(await ReservePool.fromInit(provider.sender().address!));

    await reservePool.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(reservePool.address, 30);
    await saveAddress('reservePool', reservePool.address);

    console.log('=============================================================================');
    console.log('Reserve pools deployed successfully');
    console.log('=============================================================================');
}
