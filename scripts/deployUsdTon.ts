import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { buildOnchainMetadata, saveAddress } from '../utils/helpers';
import { UsdTonMaster } from '../wrappers/UsdTon';

export async function run(provider: NetworkProvider) {
    const jettonParams = {
        name: 'yt07',
        symbol: 'yt07',
        description: 'yt07',
        image: '',
    };
    const owner = provider.sender().address as Address;
    const stablecoin = provider.open(await UsdTonMaster.fromInit(owner, buildOnchainMetadata(jettonParams)));

    await stablecoin.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(stablecoin.address, 30);
    await saveAddress('stablecoin', stablecoin.address);
    console.log('=============================================================================');
    console.log('Stablecoin deployed successfully');
    console.log('=============================================================================');
    // run methods on `stablecoin`
}
