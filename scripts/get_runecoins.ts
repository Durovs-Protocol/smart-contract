import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { RuneInfo } from '../wrappers/RuneInfo';
import { Runecoin } from '../wrappers/Runecoin';

export async function run(provider: NetworkProvider) {
    const rune = provider.open(await Runecoin.fromAddress(Address.parse(await loadAddress('runecoin'))));

    log('00 | Покупка runecoin');

    const amount = toNano(123);
    const user = provider.sender();

    await rune.send(
        user,
        { value: toNano(0.1) },
        {
            $$type: 'DexMessage',
            amount: amount,
            user: user.address as Address,
        },
    );
    const runeInfo = provider.open(await RuneInfo.fromInit(user.address as Address));
    await provider.waitForDeploy(runeInfo.address, 30);

    const runeWallet = await runeInfo.getMyAddress();
    console.log('Rune wallet:', runeWallet.toString());
}
