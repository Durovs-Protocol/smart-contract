import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { setupGas, usdTONJettonParams } from '../../../utils/data';
import { buildOnchainMetadata, saveAddress } from '../../../utils/helpers';
import { UsdTonMaster } from '../../../wrappers/UsdTon';
export async function run(provider: NetworkProvider) {
    const owner = provider.sender().address as Address;
    const usdTon = provider.open(await UsdTonMaster.fromInit(owner, buildOnchainMetadata(usdTONJettonParams)));

    await usdTon.send(
        provider.sender(),
        {
            value: toNano(setupGas),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(usdTon.address, 30);
    await saveAddress('usdTon', usdTon.address);
    console.log('=============================================================================');
    console.log('Usd on TON deployed successfully');
    console.log('=============================================================================');
    // run methods on `usdTon`
}
