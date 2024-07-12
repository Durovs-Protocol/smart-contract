import { toNano } from '@ton/core';
import { RunacoinTest } from '../wrappers/RunacoinTest';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const runacoinTest = provider.open(await RunacoinTest.fromInit());

    await runacoinTest.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(runacoinTest.address);

    // run methods on `runacoinTest`
}
