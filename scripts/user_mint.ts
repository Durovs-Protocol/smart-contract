import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano, toNano } from '@ton/core';
import { mintAmount } from '../utils/data';
import { loadAddress, log, saveAddress, timer } from '../utils/helpers';
import { V1Manager } from '../wrappers/V1Manager';
import { Stable } from '../wrappers/V1Stable';
import { StableWallet } from '../wrappers/V1StableWallet';

export async function run(provider: NetworkProvider) {
    const stable = provider.open(await Stable.fromAddress(Address.parse(await loadAddress('stable'))));
    const manager = provider.open(await V1Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();
    const userWalletAddress = await stable.getGetWalletAddress(user.address as Address);

    const mint = toNano(mintAmount);

    log('Mint stable: ' + fromNano(mint).toString());

    await manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'MintStableMessage',
            amount: mint,
        },
    );

    const userWallet = provider.open(await StableWallet.fromAddress(userWalletAddress));
    await provider.waitForDeploy(userWalletAddress, 30);

    await timer(`User stable balance`, mint, userWallet.getGetBalance);
    await saveAddress('user_stable_wallet', userWalletAddress);
    //проверять в обозревателе транзакций
}
