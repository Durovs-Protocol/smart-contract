import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { assets } from '../utils/data';
import { loadAddress, log, saveLog } from '../utils/helpers';
import { ReservePool } from '../wrappers/V0.ReservePool';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const reservePool = provider.open(await ReservePool.fromAddress(Address.parse(await loadAddress('reservePool', undefined, '0'))));
    const newPool: Address = Address.parse(await loadAddress('reservePool', undefined, '1'))

     const migrationData = [
        {
            name: 'stakedTON',
            pool_wallet: Address.parse(assets[0].pool_wallet),
            amount: 1
        },
        // {
        //     name: 'hipoStakedTON',
        //     pool_wallet: Address.parse('0QDfVL4vaXwyZBPU1m731WMVN2QD0R2P02rSg6-jA4nvUd6s'),
        //     amount: 1n
        // },
        // {
        //     name: 'tonstakers',
        //     pool_wallet: Address.parse('0QDocfDqfObKtOMc08eY-rxz7-TL7I4oSAUxciuN82HfUXNE'),
        //     amount: 1n
        // },
        {
            name: 'toncoin',
            amount: 0,
            pool_wallet: reservePool.address
        },
    ]
    const migrationIndex: number = 0;
        try {
            log('Миграция pool');
            await reservePool.send(
                user,
                { value: toNano(0.5) },
                {
                    $$type: 'PoolMigrationRequest',
                    amount: BigInt(migrationData[migrationIndex].amount),
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
