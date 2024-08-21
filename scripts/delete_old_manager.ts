import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { Manager } from '../wrappers/v0.Manager';


export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    log('Удаление контракта manager');

    await manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'DeleteManager',
        },
    );


}
