import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { setupGas } from '../utils/data';
import { loadAddress, saveAddress } from '../utils/helpers';
import { NewManager } from '../wrappers/V0.NewManager';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await NewManager.fromInit(provider.sender().address!, Address.parse(await loadAddress('manager', undefined, '0'))));

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
    await saveAddress('manager', manager.address, undefined, '1');
    console.log('=============================================================================');
    console.log('New manager deployed successfully');
    console.log('=============================================================================');

    // run methods on `manager`
}
