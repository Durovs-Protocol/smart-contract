import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { setupGas } from '../utils/data';
import { saveAddress } from '../utils/helpers';
import { NewManager } from '../wrappers/v0.NewManager';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await NewManager.fromInit(provider.sender().address!));

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
    await saveAddress('new_manager', manager.address);
    console.log('=============================================================================');
    console.log('New manager deployed successfully');
    console.log('=============================================================================');

    // run methods on `manager`
}
