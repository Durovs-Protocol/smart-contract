import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, saveAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';

export async function run(provider: NetworkProvider) {
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();

    console.log('=============================================================================');
    console.log('02 | Пользователь минтит usdTON');
    console.log('=============================================================================');
    const userUsdTonWalletAddress = await usdTon.getGetWalletAddress(user.address as Address);
    const usdtonsBorrowed = toNano(0.2);

    await manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'WithdrawUsdTonUserMessage',
            user: user.address as Address,
            amount: usdtonsBorrowed,
        },
    );

    const userUsdTonWallet = provider.open(await UsdTonWallet.fromAddress(userUsdTonWalletAddress));
    await provider.waitForDeploy(userUsdTonWalletAddress, 20);

    const userUsdTonBalance = await userUsdTonWallet.getGetBalance();
    await timer(`User stable balance`, 'Mint usdTon', userUsdTonBalance, userUsdTonWallet.getGetBalance);

    await saveAddress('user_usd_ton_wallet', userUsdTonWalletAddress);
}
