import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Pool } from '../wrappers/Pool';

export async function run(provider: NetworkProvider) {
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));
    const newTonPrice = toNano(7);

    let getCurrentTonPrice = async function () {
        return await poolContract.getTonPrice();
    };

    await poolContract.send(
        provider.sender(),
        { value: toNano('0.3') },
        {
            $$type: 'UpdateTonPriceMsg',
            price: newTonPrice,
        },
    );
    await timer(`ton price`, 'Настройка стоимости ton', newTonPrice, getCurrentTonPrice);
}