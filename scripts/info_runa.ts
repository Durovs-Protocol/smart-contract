import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { loadAddress, numberFormat, log } from '../utils/helpers';
import { RuneCoinOwner } from '../wrappers/RunecoinOwner';

export async function run(provider: NetworkProvider) {
    log('Runa-info');

    const runecoinOwner = provider.open(
        await RuneCoinOwner.fromAddress(Address.parse(await loadAddress('runecoin_owner'))),
    );

    const totalAmount = await runecoinOwner.getTotalAmount();
    console.log('В хранилище владельца: ', numberFormat(Number(fromNano(totalAmount))));
}
