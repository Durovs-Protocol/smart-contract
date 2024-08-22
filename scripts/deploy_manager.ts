import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { setupGas } from '../utils/data';
import { saveAddress } from '../utils/helpers';
import { Manager } from '../wrappers/V0.Manager';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromInit(provider.sender().address!));

    await manager.send(
        provider.sender(),
        {
            value: toNano(setupGas),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(manager.address, 30);
    await saveAddress('manager', manager.address);
    console.log('=============================================================================');
    console.log('Manager deployedd successfully');
    console.log('=============================================================================');

    // run methods on `manager`
}
