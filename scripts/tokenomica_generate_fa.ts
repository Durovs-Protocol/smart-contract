import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { holders } from '../utils/data';
import { log, saveAddress } from '../utils/helpers';
import { FakeWallet } from '../wrappers/FakeWallet';

export async function run(provider: NetworkProvider) {
    log('00 | Генерация фальшивых кошельков');

    for (const holder of holders) {
        const wallet = provider.open(await FakeWallet.fromInit(holder.name));

        await wallet.send(
            provider.sender(),
            { value: toNano('0.03') },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        await provider.waitForDeploy(wallet.address, 30);
        await saveAddress(holder.name, wallet.address, 'fake_wallet');
    }
}
