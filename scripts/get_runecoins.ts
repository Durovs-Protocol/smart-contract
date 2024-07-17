import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { testnetMintAmount } from '../utils/data';
import { loadAddress, log } from '../utils/helpers';
import { Runecoin } from '../wrappers/Runecoin';

export async function run(provider: NetworkProvider) {
    const runecoin = provider.open(await Runecoin.fromAddress(Address.parse(await loadAddress('runecoin'))));

    log('Покупка runecoin');

    const amount = toNano(testnetMintAmount);
    const user = provider.sender();

    await runecoin.send(
        user,
        { value: toNano(0.1) },
        {
            $$type: 'DexMessage',
            amount: amount,
            user: user.address as Address,
        },
    );
}
