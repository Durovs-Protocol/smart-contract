import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { assets } from '../utils/data';
import { loadAddress, log, saveLog } from '../utils/helpers';
import { ReservePool } from '../wrappers/ReservePool';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const reservePool = provider.open(await ReservePool.fromAddress(Address.parse(await loadAddress('reservePool', undefined, '0'))));
    const newPool: Address = Address.parse(await loadAddress('reservePool', undefined, '1'))

     const migrationData = [
        // {
        //     name: 'stTON',
        //     pool_wallet: Address.parse(assets[0].pool_wallet!!),
        //     amount: 499999999
        // },
        // {
        //     name: 'NOT',
        //     pool_wallet: Address.parse(assets[3].pool_wallet!!),
        //     amount: 450000000
        // },

        {
            name: 'TON',
            pool_wallet: Address.parse(assets[5].pool_wallet!!),
            amount: 139473896,// Не надо указывать
        },
    ]
    //TODO нужно сделать автоматическую проверку баланса и формирование этой структуры

    const migrationIndex: number = 0;
        try {
            log('Миграция pool');
            await reservePool.send(
                user,
                { value: toNano(0.5) },
                {
                    $$type: 'PoolMigrationRequest',
                    amount: toNano(migrationData[migrationIndex].amount),
                    queryId: BigInt(migrationIndex),
                    newPool: newPool,
                    wallet: migrationData[migrationIndex].pool_wallet,
                },
            );
            // тут нужно добавить какой-то таймер, без него логи бесполезны
            await saveLog(`migration_pool`, `\nMigration complete: \n old pool: ${reservePool.address};
                \nnew pool: ${newPool};`)
        } catch (error) {
            await saveLog(`migration_pool`, `\nMigration complete with errors:
                \n Error: ${error};`)
        }
    
    
}
