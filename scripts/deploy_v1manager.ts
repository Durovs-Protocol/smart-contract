import { NetworkProvider } from '@ton/blueprint'
import { Address, toNano } from '@ton/core'
import { setupGas } from '../utils/data'
import { saveAddress } from '../utils/helpers'
import { V1Manager } from '../wrappers/V1Manager'

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await V1Manager.fromInit(provider.sender().address!, Address.parse('UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ')))

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
