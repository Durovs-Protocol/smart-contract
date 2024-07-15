import { NetworkProvider } from '@ton/blueprint';
import { Address } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { RunecoinWallet } from '../wrappers/RunecoinWallet';

export async function run(provider: NetworkProvider) {
    log('Rune info');
    const user = provider.sender();
    
    try {
        const runeWallet = provider.open(await RunecoinWallet.fromAddress(user.address  as Address));
        const balance = await runeWallet.getGetBalance();
        console.log('Wallet balance:', balance);

        const userPosition = await runeWallet.getUserPositionAddress(
            user.address as Address,
            Address.parse(await loadAddress('usdTon')),
            Address.parse(await loadAddress('manager')),
            Address.parse(await loadAddress('pool')),
        );
        console.log(userPosition);
    } catch (e) {
        console.log('Wallet balance: wallet not initialized');
    }
}
