import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { buildOnchainMetadata, saveAddress } from '../utils/helpers';
import { UsdTonMaster } from '../wrappers/UsdTon';

export async function run(provider: NetworkProvider) {
    const jettonParams = {
        name: 'yt10',
        symbol: '11',
        description: '11',
        image: '',
    };
    const owner = provider.sender().address as Address;
    const usdTon = provider.open(await UsdTonMaster.fromInit(owner, buildOnchainMetadata(jettonParams)));

    await usdTon.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(usdTon.address, 30);
    await saveAddress('usdTon', usdTon.address);
    console.log('=============================================================================');
    console.log('UsdToncoin deployed successfully');
    console.log('=============================================================================');
    // run methods on `usdTon`
}
