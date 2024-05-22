import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { ProductOwner } from '../../wrappers/insurance/ProductOwner';

export async function run(provider: NetworkProvider) {
    const productOwner = provider.open(await ProductOwner.fromInit());

    await productOwner.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(productOwner.address);

    // run methods on `productOwner`
}
