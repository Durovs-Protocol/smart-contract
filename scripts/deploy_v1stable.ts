import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { setupGas, stableJettonParams } from '../utils/data';
import { buildOnchainMetadata, saveAddress } from '../utils/helpers';
import { Stable } from '../wrappers/V1Stable';
export async function run(provider: NetworkProvider) {
    const owner = provider.sender().address as Address;
    const stable = provider.open(await Stable.fromInit(owner, buildOnchainMetadata(stableJettonParams)));

    await stable.send(
        provider.sender(),
        {
            value: toNano(setupGas),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(stable.address, 30);
    await saveAddress('stable', stable.address, undefined, '1');

    console.log('=============================================================================');
    console.log('Stable deployed successfully');
    console.log('=============================================================================');
    // run methods on `stable`
}
