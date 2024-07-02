import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano, toNano } from '@ton/core';
import { loadAddress, log, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();

    const stablesBorrowed = toNano(1);

    const getDebtBalance = async function () {
        const userPositionAddress = await manager.getUserPositionAddress(user.address as Address);
        const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
        const userPositionState = await userPosition.getPositionState();
        return userPositionState.debt;
    };

    // Альтернатива брать с баланса usdTONWallet
    // const userUsdToncoinWalletAddress = await usdTon.getGetWalletAddress(user.address as Address);
    // const userUsdTonWallet = provider.open(await UsdTonWallet.fromAddress(userUsdToncoinWalletAddress));

    log('03 | Пользователь возвращает usdTon | Balance: ' + fromNano(await getDebtBalance()));

    let userUsdTonBalanceAfterBurn = getDebtBalance; // await userUsdTonWallet.getGetBalance();

    await manager.send(
        user,
        { value: toNano(0.2) },
        {
            $$type: 'BurnUsdTONUserMessage',
            user: user.address as Address,
            amount: stablesBorrowed,
        },
    );
    const balance = (await getDebtBalance()) - stablesBorrowed;
    await timer('User stable balance', 'Погашение задолжности', fromNano(balance.toString()), getDebtBalance, true);
}