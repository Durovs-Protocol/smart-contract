import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import contracts from '../utils/contracts';
import { setupGas } from '../utils/data';
import { contractVersion, loadAddress, log, timer } from '../utils/helpers';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const { manager } = await contracts(provider, user.address!!)


    let getMinDelay = async function () {
        const settings = await manager.getSettings();
        const minDelay = settings.minDelay;
        return minDelay;
    };

    const unixDelay = 0n;
    const unixMaxExecutionTime = 0n;
    // const unixDelay = 86400n;
	log('Настройка контракта:'+
        `\n ${await contractVersion(manager, 'manager')}`
    );
    
    await setSettings(manager)

    async function setSettings(contract: any) {
        await contract.send(
            user,
            { value: toNano(setupGas)},
            {
                $$type: 'SetSettings',
                minDelay: unixDelay,
                newManager: Address.parse(await loadAddress('manager', undefined, '1'),),
                maxAmount: 0n,
                maxExecutionTime: unixMaxExecutionTime,
            }
        )

        await timer('Настройка пула', unixDelay, getMinDelay);
    }
}