import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { RuneCoinOwner } from '../wrappers/RunecoinOwner';

export async function run(provider: NetworkProvider) {
    const runecoinsOwner = provider.open(
        await RuneCoinOwner.fromAddress(Address.parse(await loadAddress('runecoin_owner'))),
    );
    console.log('=============================================================================');
    console.log('04 | Покупка runecoin');
    console.log('=============================================================================');

    const amount = toNano(123);
    const user = provider.sender();
    const totalAmount = await runecoinsOwner.getTotalAmount();

    await runecoinsOwner.send(
        user,
        { value: toNano(0.3) },
        {
            $$type: 'GetRunecoin',
            amount: amount,
            user: user.address as Address,
        },
    );

    await timer('owners runecoins', 'Покупка runecoin', totalAmount, runecoinsOwner.getTotalAmount);
}
