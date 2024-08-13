import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { gas } from '../utils/data';
import { loadAddress, log, timer } from '../utils/helpers';
import { Manager } from '../wrappers/v0.Manager';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    log('1. Пользователь вносит обеспечение, создается/обновляется контракт пользовательской позиции');

    const collateralAmount = toNano(0.2);
    const currentPositionId = await manager.getLastPositionId();

    // передаем везде газ 1, после получим возврат

    await manager.send(
        user,
        { value: collateralAmount + toNano(gas) },
        {
            $$type: 'SupplyMessage',
            amount: collateralAmount,
        },
    );

    console.log(`currentPositionId | ${currentPositionId}`);
    if (currentPositionId <= 0) {
        await timer('Внесение обеспечения: проверка id', currentPositionId + 1n, manager.getLastPositionId);
    } else {
        log('Без проверки supply баланса');
    }
}
