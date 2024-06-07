import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Pool } from '../wrappers/Pool';
import { StablecoinMaster } from '../wrappers/Stablecoin';
import { UserStablecoinWallet } from '../wrappers/StablecoinWallet';

export async function run(provider: NetworkProvider) {
    const stablecoin = provider.open(
        await StablecoinMaster.fromAddress(Address.parse(await loadAddress('stablecoin'))),
    );

    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));
    const user = provider.sender();

    const stablesBorrowed = toNano(1);
    const userStablecoinWalletAddress = await stablecoin.getGetWalletAddress(user.address as Address);
    const userStableWallet = provider.open(await UserStablecoinWallet.fromAddress(userStablecoinWalletAddress));

    console.log('03 | Пользователь возвращает stablecoin--------------------------------');
    let userStableBalanceAfterRepay = await userStableWallet.getGetBalance();

    await poolContract.send(
        user,
        { value: toNano(0.3) },
        {
            $$type: 'RepayStablecoinUserMessage',
            user: user.address as Address,
            amount: stablesBorrowed,
        },
    );

    await timer(
        `Баланс stablecoin при погашении задолжности:`,
        userStableBalanceAfterRepay,
        userStableWallet.getGetBalance,
    );
}
