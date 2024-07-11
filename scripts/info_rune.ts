import { NetworkProvider } from '@ton/blueprint';
import { Address } from '@ton/core';
import { log } from '../utils/helpers';
import { RuneInfo } from '../wrappers/RuneInfo';
import { RunecoinWallet } from '../wrappers/RunecoinWallet';

export async function run(provider: NetworkProvider) {
    log('Rune info');
    const user = provider.sender().address as Address;
    const runeInfo = provider.open(await RuneInfo.fromInit(user));
    await provider.waitForDeploy(runeInfo.address, 30);
    const userWallet = await runeInfo.getMyAddress();

    console.log('Rune    wallet:', userWallet.toString());
    try {
        const runeWallet = provider.open(await RunecoinWallet.fromAddress(userWallet));
        const balance = await runeWallet.getGetBalance();
        console.log('Wallet balance:', balance);
    } catch (e) {
        console.log('Wallet balance: wallet not initialized');
    }
}
