import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { setupGas } from '../utils/data';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/V0.Manager';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
   

    let getMinDelay = async function () {
        const settings = await manager.getSettings();
        const minDelay = settings.minDelay;
        return minDelay;
    };

    const unixDelay = 240n;
    // const unixDelay = 86400n;
    await manager.send(
        provider.sender(),
        { value: toNano(setupGas) },
        {
            $$type: 'SetSettings',
            minDelay: unixDelay,
            newManager: Address.parse(await loadAddress('new_manager')),
            maxAmount: 0n
        },
    );
    await timer('Настройка пула', unixDelay, getMinDelay);
}
