import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, log, timer } from '../utils/helpers';
import { addSupplyAmount, addSupplyGas } from '../utils/data';
import { Manager } from '../wrappers/Manager';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    log('1. Пользователь вносит обеспечение, создается/обновляется контракт пользовательской позиции');

    const collateralAmount = toNano(addSupplyAmount);
    const currentPositionId = await manager.getLastPositionId();

    // тут передан оптимальный газ
    await manager.send(
        user,
        { value: collateralAmount + toNano(addSupplyGas) },
        {
            $$type: 'DepositCollateralUserMessage',
            user: user.address as Address,
            amount: collateralAmount,
        },
    );

    console.log(`currentPositionId | ${currentPositionId}`);
    if (currentPositionId <= 0) {
        await timer(`Position Id`, 'Внесение обеспечения', currentPositionId + 1n, manager.getLastPositionId);
    } else {
        log('Без проверки supply баланса')
    }
}
