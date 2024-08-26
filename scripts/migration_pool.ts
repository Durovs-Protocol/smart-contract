import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { assets } from '../utils/data';
import { loadAddress, log } from '../utils/helpers';
import { NewReservePool } from '../wrappers/V0.NewPool';
import { ReservePool } from '../wrappers/V0.ReservePool';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const reservePool = provider.open(await ReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))));
    const newReservePool = provider.open(await NewReservePool.fromAddress(Address.parse(await loadAddress('new_pool'))));

     const migrationData = [
        {
            name: 'stakedTON',
            pool_wallet: Address.parse(assets[0].pool_wallet),
            amount: 49n
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
            amount: 1n,
            pool_wallet: Address.parse(await loadAddress('reservePool'))
        },
    ]
    const migrationIndex: number = 1;
     

        try {
            log('Миграция pool');
            await reservePool.send(
                user,
                { value: toNano(1) },
                {
                    $$type: 'PoolMigrationRequest',
                    amount: toNano(migrationData[migrationIndex].amount),
                    queryId: BigInt(migrationIndex),
                    newPool: newReservePool.address,
                    wallet: migrationData[migrationIndex].pool_wallet,
                },
            );
        } catch (error) {
          
        }
    
    
}
