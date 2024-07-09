import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { liquidationRatio, gasFee, stabilityFeeRate, liquidationFee } from '../utils/test_data';
import { Manager } from '../wrappers/Manager';

export async function run(provider: NetworkProvider) {
    const managerContract = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    let getliquidRatio = async function () {
        const settings = await managerContract.getPoolSettings();
        const liquidationRatio = settings.liquidationRatio;
        return liquidationRatio;
    };

    const newLiquidationRatio = toNano(liquidationRatio);

    await managerContract.send(
        provider.sender(),
        { value: toNano(gasFee) },
        {
            $$type: 'SetPoolSettings',
            liquidationRatio: newLiquidationRatio,
            stabilityFeeRate: toNano(stabilityFeeRate),
            liquidationFee: toNano(liquidationFee),
        },
    );

    await timer(`liquid ratio`, 'Настройка пула', newLiquidationRatio, getliquidRatio);
}
