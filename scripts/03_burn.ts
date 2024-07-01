import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano, fromNano } from '@ton/core';
import { loadAddress, timer, log } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();

    const stablesBorrowed = toNano(0.1);

    const getDebtBalance = async function () {
        const userPositionAddress = await manager.getUserPositionAddress(user.address as Address);
        const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
        const userPositionState = await userPosition.getPositionState();
        return userPositionState.debt;
    }

    // Альтернатива брать с баланса usdTONWallet
    // const userUsdToncoinWalletAddress = await usdTon.getGetWalletAddress(user.address as Address);
    // const userUsdTonWallet = provider.open(await UsdTonWallet.fromAddress(userUsdToncoinWalletAddress));

    const currentDebt = await getDebtBalance();// TODO: сделать проверку на текущий баланс - если долга нет - дальше не пускать

    log('03 | Пользователь возвращает usdTon | Balance: ') // TODO: вывести текущий долг

    // let userUsdTonBalanceAfterBurn = getDebtBalance; // await userUsdTonWallet.getGetBalance();

    await manager.send(
        user,
        { value: toNano(0.2) },
        {
            $$type: 'BurnUsdTONUserMessage',
            user: user.address as Address,
            amount: stablesBorrowed,
        },
    );
    const balance = await getDebtBalance() - stablesBorrowed;
    await timer(
        'User stable balance',
        'Погашение задолжности',
        balance,
        getDebtBalance,
        true
    );
}