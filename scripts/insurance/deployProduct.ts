import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { Product } from '../../wrappers/insurance/Product';

export async function run(provider: NetworkProvider) {
    const product = provider.open(await Product.fromInit(BigInt(Math.floor(Math.random() * 10000))));

    await product.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(product.address);

    console.log('ID', await product.getId());
}
