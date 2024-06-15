import { NetworkProvider } from '@ton/blueprint';
import { Address } from '@ton/core';
import { loadAddress } from '../utils/helpers';
import { RuneCoinsOwner } from '../wrappers/RunecoinsOwner';

export async function run(provider: NetworkProvider) {
    console.log('=============================================================================');
    console.log('| Runa-info');
    console.log('=============================================================================');

    const runecoinOwner = provider.open(
        await RuneCoinsOwner.fromAddress(Address.parse(await loadAddress('runecoins_owner'))),
    );

    const totalAmount = await runecoinOwner.getTotalAmount();
    console.log('В хранилище владельца: ', totalAmount);
}
