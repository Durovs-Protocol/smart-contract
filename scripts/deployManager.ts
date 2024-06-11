import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { saveAddress } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromInit());

    await manager.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(manager.address, 30);
    await saveAddress('manager', manager.address);
    console.log('=============================================================================');
    console.log('Manager deployed successfully');
    console.log('=============================================================================');

    // run methods on `manager`
}
