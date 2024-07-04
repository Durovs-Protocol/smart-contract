import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';

export async function run(provider: NetworkProvider) {
    const managerContract = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    let getliquidRatio = async function () {
        const settings = await managerContract.getPoolSettings();
        const liquidationRatio = settings.liquidationRatio;
        return liquidationRatio;
    };

    const newLiquidationRatio = toNano(1.15);

    await managerContract.send(
        provider.sender(),
        { value: toNano('0.1') },
        {
            $$type: 'SetPoolSettings',
            liquidationRatio: newLiquidationRatio,
            stabilityFeeRate: toNano('0.02'),
        },
    );

    await timer(`liquid ratio`, 'Настройка пула', newLiquidationRatio, getliquidRatio);
}
