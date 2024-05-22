import { NetworkProvider } from '@ton/blueprint';
import { Address } from '@ton/core';
import { InsurancePool } from '../../wrappers/insurance/InsurancePool';

export async function run(provider: NetworkProvider) {

    const insurancePool = provider.open(InsurancePool.fromAddress(Address.parse('EQAEDBjL4cMLVEh5M4GDrY_FC8tR-HgWQP5bo2nZryBu6g_F')));

    const id = await insurancePool.getId();
    const title = await insurancePool.getTitle();
    const type = await insurancePool.getType();
    const amount = await insurancePool.getAmount();

    console.log('\n\nId:', id)
    console.log('Title:', title)
    console.log('Type:', type)
    console.log('Amount:', amount,'\n\n')
}