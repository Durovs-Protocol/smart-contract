import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { Runecoin } from '../wrappers/Runecoin';

export async function run(provider: NetworkProvider) {
    const rune = provider.open(await Runecoin.fromAddress(Address.parse(await loadAddress('runecoin'))));

    log('00 | Распределение runecoin');
    const user = provider.sender();

    await rune.send(
        user,
        { value: toNano(4) },
        {
            $$type: 'Mint',
            amount: toNano(100),
        },
    );
    //TODO добавить таймер, пока смотреть через транзакции
}
