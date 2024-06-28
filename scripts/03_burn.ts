import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';

export async function run(provider: NetworkProvider) {
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));

    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();

    const stablesBorrowed = toNano(0.2);
    const userUsdToncoinWalletAddress = await usdTon.getGetWalletAddress(user.address as Address);
    const userUsdTonWallet = provider.open(await UsdTonWallet.fromAddress(userUsdToncoinWalletAddress));

    console.log('=============================================================================');
    console.log('03 | Пользователь возвращает usdTon');
    console.log('=============================================================================');

    let userUsdTonBalanceAfterBurn = await userUsdTonWallet.getGetBalance();

    await manager.send(
        user,
        { value: toNano(0.2) },
        {
            $$type: 'BurnUsdTONUserMessage',
            user: user.address as Address,
            amount: stablesBorrowed,
        },
    );

    await timer(
        'User stable balance',
        'Погашение задолжности',
        userUsdTonBalanceAfterBurn - stablesBorrowed,
        userUsdTonWallet.getGetBalance,
    );
}
