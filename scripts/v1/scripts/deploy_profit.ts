import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { setupGas } from '../../../utils/data';
import { saveAddress } from '../../../utils/helpers';
import { ProfitPool } from '../../../wrappers/ProfitPool';
export async function run(provider: NetworkProvider) {
    const profitPool = provider.open(await ProfitPool.fromInit(provider.sender().address!));

    await profitPool.send(
        provider.sender(),
        {
            value: toNano(setupGas),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(profitPool.address, 30);
    await saveAddress('profitPool', profitPool.address);
    console.log('=============================================================================');
    console.log('Profit pool deployed successfully');
    console.log('=============================================================================');
}
