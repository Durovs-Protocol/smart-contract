import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { buildOnchainMetadata, saveAddress } from '../utils/helpers';
import { StablecoinMaster } from '../wrappers/Stablecoin';

export async function run(provider: NetworkProvider) {
    const jettonParams = {
        name: 'yt0.3',
        symbol: 'yt0.3',
        description: 'v0.3',
        image: '',
    };
    const owner = provider.sender().address as Address;
    const stablecoin = provider.open(await StablecoinMaster.fromInit(owner, buildOnchainMetadata(jettonParams)));

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

    await provider.waitForDeploy(stablecoin.address);
    await saveAddress('stablecoin', stablecoin.address);
    console.log(
        '----------------------------------------------------------------------------------stablecoin deployed successfully',
    );
    // run methods on `stablecoin`
}
