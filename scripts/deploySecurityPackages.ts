import { toNano } from '@ton/core';
import { SecurityPackages } from '../wrappers/SecurityPackages';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const randomInt = BigInt(Math.floor(Math.random() * 1000000))
    const securityPackages = provider.open(await SecurityPackages.fromInit());

    await securityPackages.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(securityPackages.address);

    // run methods on `securityPackages`
}
