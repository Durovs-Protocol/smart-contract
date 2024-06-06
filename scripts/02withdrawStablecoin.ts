import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Pool } from '../wrappers/PoolContract';
import { StablecoinMaster } from '../wrappers/Stablecoin';
import { UserStablecoinWallet } from '../wrappers/StablecoinWallet';

export async function run(provider: NetworkProvider) {
    const stablecoin = provider.open(
        await StablecoinMaster.fromAddress(Address.parse(await loadAddress('stablecoin'))),
    );
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));
    const user = provider.sender();

    console.log('02 | Пользователь берет stablecoin--------------------------------');
    const stablesBorrowed = toNano(1);
    const userStablecoinWalletAddress = await stablecoin.getGetWalletAddress(user.address as Address);
    const userStableWallet = provider.open(await UserStablecoinWallet.fromAddress(userStablecoinWalletAddress));

    const userStableBalance = await userStableWallet.getGetBalance();

    await poolContract.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'WithdrawStablecoinUserMessage',
            user: user.address as Address,
            amount: stablesBorrowed,
        },
    );

    await timer(`Баланс stablecoin при оформлении займа:`, userStableBalance, userStableWallet.getGetBalance);

    console.log('02 | info:');
    console.log('----адрес пользовательского кошелька stablecoin:', userStablecoinWalletAddress);
}
