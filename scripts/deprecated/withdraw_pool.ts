import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress } from '../utils/helpers';
import { Pool } from '../wrappers/Pool';

export async function run(provider: NetworkProvider) {
    const pool = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool'))));
    await pool.send(
        provider.sender(),
        { value: toNano(0.1) },
        {
            $$type: 'TestWithdrawal',
        },
    );
}
