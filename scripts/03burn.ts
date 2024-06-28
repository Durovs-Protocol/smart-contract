import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Pool } from '../wrappers/Pool';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';

export async function run(provider: NetworkProvider) {
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));

    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool'))));
    const user = provider.sender();

    const stablesBorrowed = toNano(0.5);
    const userUsdToncoinWalletAddress = await usdTon.getGetWalletAddress(user.address as Address);
    const userUsdTonWallet = provider.open(await UsdTonWallet.fromAddress(userUsdToncoinWalletAddress));

    console.log('=============================================================================');
    console.log('03 | Пользователь возвращает usdTon');
    console.log('=============================================================================');

    let userUsdTonBalanceAfterBurn = await userUsdTonWallet.getGetBalance();

    await poolContract.send(
        user,
        { value: toNano(0.3) },
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
