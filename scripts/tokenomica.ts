import { NetworkProvider } from '@ton/blueprint';
import { Address, Dictionary, toNano } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { holders } from '../utils/test_data';
import { Runecoin } from '../wrappers/Runecoin';

export async function run(provider: NetworkProvider) {
    const rune = provider.open(await Runecoin.fromAddress(Address.parse(await loadAddress('runecoin'))));

    log('00 | Назначаем адреса держателей runecoin');
    const user = provider.sender();

    const holdersData: Dictionary<Address, bigint> = Dictionary.empty(
        Dictionary.Keys.Address(),
        Dictionary.Values.BigVarUint(4),
    );
    let holdersInfo: any = {};

    for (const holder of holders) {
        const walletAddress = await loadAddress(holder.name, 'fake_wallet');
        console.log(walletAddress);
        holdersInfo[holder.name] = Address.parse(walletAddress);
        holdersData.set(Address.parse(walletAddress), toNano(holder.percent / 100));
    }

    await rune.send(
        user,
        { value: toNano(0.1) },
        {
            $$type: 'SetHolders',
            holders: holdersData,
            holdersInfo: Object.assign({ $$type: 'Holders' }, holdersInfo),
        },
    );
    // TODO добавить таймер, пока смотреть через транзакции
}
