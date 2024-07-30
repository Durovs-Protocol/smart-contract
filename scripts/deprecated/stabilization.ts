import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const pool = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool'))));
    const user = provider.sender();

    const poolState = (await pool.getState()).pool;
    console.log(poolState);
    // TODO после завершения проверок вынести в отдельный скрипт как пополнение пула инвестором
    // await pool.send(
    //     user,
    //     { value: toNano(1) },
    //     {
    //         $$type: 'StabilityFeePayment',
    //         amount: toNano(1),
    //         user: user.address!,
    //     },
    // );
    // await timer(`pool replenishment`, 'Пополнение пула', poolState + toNano(1), async function () {
    //     return (await pool.getState()).pool;
    // });

    await manager.send(
        user,
        { value: toNano(0.12) },
        {
            $$type: 'Stabilization',
            rate: toNano(0.960784),
            usdtonAmount: toNano(5.1),
        },
    );

    console.log(await manager.getState());
    console.log(await pool.getState());
}
