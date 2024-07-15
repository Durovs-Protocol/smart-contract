import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, log, timer } from '../utils/helpers';
import { burnAmount, burnGas } from '../utils/data';
import { Manager } from '../wrappers/Manager';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();

    log('03 | Пользователь возвращает usdTon | Burn amount: ' + burnAmount);

    const getDebtBalance = async function () {
        const userPositionAddress = await manager.getUserPositionAddress(user.address as Address);
        const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
        const userPositionState = await userPosition.getPositionState();
        return userPositionState.debt;
    };

    // Альтернатива брать с баланса usdTONWallet
    // const userUsdToncoinWalletAddress = await usdTon.getGetWalletAddress(user.address as Address);
    // const userUsdTonWallet = provider.open(await UsdTonWallet.fromAddress(userUsdToncoinWalletAddress));
    let usdTonBalance = await getDebtBalance();

    // TODO: сделать проверку на текущий баланс - если долга нет - дальше не пускать
    // оптимальный газ 0.12 (до правок по runes)
    // TODO пересчитать газ
    await manager.send(
        user,
        { value: toNano(burnGas) },
        {
            $$type: 'BurnUsdTONUserMessage',
            user: user.address as Address,
            amount: toNano(burnAmount),
        },
    );

    await timer(
        'User stable balance',
        'Погашение задолжности',
        usdTonBalance - toNano(burnAmount),
        getDebtBalance,
        true,
    );
}
