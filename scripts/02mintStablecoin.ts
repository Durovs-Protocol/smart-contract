import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, saveAddress, timer } from '../utils/helpers';
import { Pool } from '../wrappers/Pool';
import { StablecoinMaster } from '../wrappers/Stablecoin';
import { UserStablecoinWallet } from '../wrappers/StablecoinWallet';

export async function run(provider: NetworkProvider) {
    const stablecoin = provider.open(
        await StablecoinMaster.fromAddress(Address.parse(await loadAddress('stablecoin'))),
    );
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));
    const user = provider.sender();

    console.log('=============================================================================');
    console.log('02 | Пользователь минтит usdTON');
    console.log('=============================================================================');
    const userStablecoinWalletAddress = await stablecoin.getGetWalletAddress(user.address as Address);
    const stablesBorrowed = toNano(0.2);

    await poolContract.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'WithdrawStablecoinUserMessage',
            user: user.address as Address,
            amount: stablesBorrowed,
        },
    );

    const userStableWallet = provider.open(await UserStablecoinWallet.fromAddress(userStablecoinWalletAddress));
    await provider.waitForDeploy(userStableWallet.address, 20);

    const userStableBalance = await userStableWallet.getGetBalance();
    await timer(`User stable balance`, 'Mint stablecoin', userStableBalance, userStableWallet.getGetBalance);

    await saveAddress('user_stablecoin_wallet_address', userStablecoinWalletAddress);
}
