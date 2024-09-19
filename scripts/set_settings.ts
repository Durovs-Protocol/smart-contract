import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import contracts from '../utils/contracts';
import { couponRate, setupGas } from '../utils/data';
import { contractVersion, loadAddress, log, timer } from '../utils/helpers';
export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const { manager } = await contracts(provider, user.address!!)


    let getMinDelay = async function () {
        const settings = await manager.getSettings();
        const minDelay = settings.minDelay;
        return minDelay;
    };

    const unixDelay = 300n;
    const unixMaxExecutionTime = 600n;
    // const unixDelay = 86400n;
	log('`\nНастройка контракта:'+
        `\n${await contractVersion(manager, 'manager')}`
    );
    
    await setSettings(manager)

    async function setSettings(contract: any) {

        if (process.env.v == '0') {
            await contract.send(
                user,
                { value: toNano(setupGas)},
                {
                    $$type: 'SetSettings',
                    minDelay: unixDelay,
                    newManager: Address.parse(await loadAddress('manager', undefined, '1')),
                    maxExecutionTime: unixMaxExecutionTime,
                }
            )
        }
        if (process.env.v == '1') {
        await contract.send(
            user,
            { value: toNano(setupGas)},
            {
                $$type: 'SetSettings',
                minDelay: unixDelay,
                newManager: Address.parse(await loadAddress('manager', undefined, '1')),
                maxExecutionTime: unixMaxExecutionTime,
                couponRate: toNano(couponRate)
            }
        )
    }

        await timer('Настройка пула', unixDelay, getMinDelay);
    }
}