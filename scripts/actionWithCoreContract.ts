import { Address, toNano } from '@ton/core';
import { InsurancePool } from '../wrappers/InsurancePool';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {

    const insurancePool = provider.open(InsurancePool.fromAddress(Address.parse('EQAEDBjL4cMLVEh5M4GDrY_FC8tR-HgWQP5bo2nZryBu6g_F')));

    const before = await insurancePool.getAmount();

    console.log('Before', before)

    await insurancePool.send(
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

    let after = await insurancePool.getAmount();
    console.log('After', after)
    let attempt = 1;

    while(after === before) {
        console.log('Increment counter, attempt: ', attempt);
        await delay(2000);
        after = await insurancePool.getAmount();
        attempt++;
    }

    console.log('After', after)

    // run methods on `insurancePool`
}

function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}
