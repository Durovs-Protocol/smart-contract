import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress } from '../utils/helpers';
import { Pool } from '../wrappers/Pool';

export async function run(provider: NetworkProvider) {
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool'))));
    const user = provider.sender();
    await poolContract.send(
        user,
        { value: toNano(0.1) },
        {
            $$type: 'TestWithdrawal',
        },
    );
}
