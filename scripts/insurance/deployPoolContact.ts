import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { InsurancePool } from '../../wrappers/insurance/InsurancePool';

export async function run(provider: NetworkProvider) {
    const randomInt = BigInt(Math.floor(Math.random() * 1000000))
    const insurancePool = provider.open(await InsurancePool.fromInit(randomInt));

    await insurancePool.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(insurancePool.address);
    console.log('Smart contract address: ', insurancePool.address)
    // run methods on `insurancePool`
}
