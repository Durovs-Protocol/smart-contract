import { Address, toNano } from '@ton/core';
import { SecurityPackages } from '../wrappers/SecurityPackages';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {

    const securityPackages = provider.open(SecurityPackages.fromAddress(Address.parse('EQCgL4oJnEVUoT3wI9UzucdhWQAQG06DNP_lvX1Bt0a7v-VO')));

    const before = await securityPackages.getLog();

    console.log('Before', before)

    await securityPackages.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Add',
            queryId: 0n,
            amount: 2n,
        }
    );

    let after = await securityPackages.getLog();
    console.log('After', after)
    let attempt = 1;

    while(after === before) {
        console.log('Increment counter, attempt: ', attempt);
        await delay(2000);
        after = await securityPackages.getLog();
        attempt++;
    }

    console.log('After', after)

    // run methods on `securityPackages`
}

function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}
