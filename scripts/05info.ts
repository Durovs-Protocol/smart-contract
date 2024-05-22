import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { JettonDefaultWallet as JettonWallet } from '../build/SupplyToken/tact_JettonDefaultWallet';
import { Treasury } from '../build/Treasury/tact_Treasury';
import { jettonAddress } from '../utils/helpers';


export async function run(provider: NetworkProvider) {
    const user = provider.sender().address as Address;
    const treasury = provider.open(await Treasury.fromInit(jettonAddress, user));
    const user_jetton_wallet = provider.open(await JettonWallet.fromInit(jettonAddress, user));
    const treasury_jetton_wallet = provider.open(await JettonWallet.fromInit(jettonAddress, treasury.address));

    const TonBalance = await treasury.getGetBalance(user);
    console.log('users ton balance', fromNano(TonBalance));
    let walletData = await user_jetton_wallet.getGetWalletData();
    console.log('users jetton balance', fromNano(walletData.balance));
    let treasuryWalletData = await treasury_jetton_wallet.getGetWalletData();
    console.log('treasury jetton balance', fromNano(treasuryWalletData.balance));
}