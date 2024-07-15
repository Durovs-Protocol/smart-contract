import { NetworkProvider } from '@ton/blueprint';
import { Address } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { RuneInfo } from '../wrappers/RuneInfo';
import { Runecoin } from '../wrappers/Runecoin';
import { RunecoinWallet } from '../wrappers/RunecoinWallet';

export async function run(provider: NetworkProvider) {
    log('Rune info');
    const user = provider.sender().address as Address;
    const runeInfo = provider.open(await RuneInfo.fromInit(user));
    await provider.waitForDeploy(runeInfo.address, 30);
    const userWallet = await runeInfo.getMyAddress();
    const rune = provider.open(await Runecoin.fromAddress(Address.parse(await loadAddress('runecoin'))));

    console.log('rune holders________________________________________________________________');
    console.log(await rune.getHolders());
    console.log('rune holders-info________________________________________________________________');
    console.log(await rune.getHoldersInfo());

    console.log('Rune    wallet:', userWallet.toString());
    try {
        const runeWallet = provider.open(await RunecoinWallet.fromAddress(userWallet));
        const balance = await runeWallet.getGetBalance();
        console.log('Wallet balance:', balance);

        const userPosition = await runeWallet.getUserPositionAddress(
            user,
            Address.parse(await loadAddress('usdTon')),
            Address.parse(await loadAddress('manager')),
            Address.parse(await loadAddress('pool')),
        );
        console.log(userPosition);
    } catch (e) {
        console.log('Wallet balance: wallet not initialized');
    }
}
