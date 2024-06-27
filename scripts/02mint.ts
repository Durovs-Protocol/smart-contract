import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, saveAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';

export async function run(provider: NetworkProvider) {
    const stablecoin = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usd_ton'))));
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();

    console.log('=============================================================================');
    console.log('02 | Пользователь минтит usdTON');
    console.log('=============================================================================');
    const userStablecoinWalletAddress = await stablecoin.getGetWalletAddress(user.address as Address);
    const stablesBorrowed = toNano(0.2);

    await manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'WithdrawStablecoinUserMessage',
            user: user.address as Address,
            amount: stablesBorrowed,
        },
    );

    const userStableWallet = provider.open(await UsdTonWallet.fromAddress(userStablecoinWalletAddress));
    await provider.waitForDeploy(userStableWallet.address, 20);

    const userStableBalance = await userStableWallet.getGetBalance();
    await timer(`User stable balance`, 'Mint stablecoin', userStableBalance, userStableWallet.getGetBalance);

    await saveAddress('user_stablecoin_wallet_address', userStablecoinWalletAddress);
}
