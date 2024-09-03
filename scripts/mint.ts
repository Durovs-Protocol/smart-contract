import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano, toNano } from '@ton/core';
import { mintAmount } from '../utils/data';
import { loadAddress, log, saveAddress, timer } from '../utils/helpers';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';
import { NewManager } from '../wrappers/V0.NewManager';

export async function run(provider: NetworkProvider) {
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const manager = provider.open(await NewManager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();

    const userUsdTonWalletAddress = await usdTon.getGetWalletAddress(user.address as Address);
    const usdtonsBorrowed = toNano(mintAmount);
    console.log(userUsdTonWalletAddress);

    log('2. Пользователь минтит usdTON: ' + fromNano(usdtonsBorrowed).toString());

    await manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'MintDurovUSDMessage',
            amount: usdtonsBorrowed,
        },
    );

    const userUsdTonWallet = provider.open(await UsdTonWallet.fromAddress(userUsdTonWalletAddress));
    await provider.waitForDeploy(userUsdTonWalletAddress, 30);

    await timer(`User stable balance`, usdtonsBorrowed, userUsdTonWallet.getGetBalance);
    await saveAddress('user_usd_ton_wallet', userUsdTonWalletAddress);
    //проверять в обозревателе транзакций
}
