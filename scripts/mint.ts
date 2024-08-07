import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano, toNano } from '@ton/core';
import { mintAmount } from '../utils/data';
import { loadAddress, log, saveAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';

export async function run(provider: NetworkProvider) {
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();

    const userUsdTonWalletAddress = await usdTon.getGetWalletAddress(user.address as Address);
    const usdtonsBorrowed = toNano(mintAmount);

    log('2. Пользователь минтит usdTON: ' + fromNano(usdtonsBorrowed).toString());

    await manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'MintUsdTonMessage',
            amount: usdtonsBorrowed,
        },
    );

    const userUsdTonWallet = provider.open(await UsdTonWallet.fromAddress(userUsdTonWalletAddress));
    await provider.waitForDeploy(userUsdTonWalletAddress, 30);

    await timer(`User stable balance`, 'Mint usdTon', usdtonsBorrowed, userUsdTonWallet.getGetBalance);
    await saveAddress('user_usd_ton_wallet', userUsdTonWalletAddress);
    //проверять в обозревателе транзакций
}
