import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { loadAddress, log, numberFormat } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { RuneCoinOwner } from '../wrappers/RunecoinOwner';

export async function run(provider: NetworkProvider) {
    log('Runa-info');

    const runecoinOwner = provider.open(
        await RuneCoinOwner.fromAddress(Address.parse(await loadAddress('runecoin_owner'))),
    );

    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    // для проверки решения проблемы с адресами
    const usersRuneWalletFromOwnerContract = await runecoinOwner.getRuneInfo(provider.sender().address!);
    const runesAddress = await runecoinOwner.getAddress();
    console.log(usersRuneWalletFromOwnerContract);
    console.log(runesAddress);
    console.log('runecoinOwner');
    const usersRuneWalletFromManagerContract = await manager.getRuneInfo(provider.sender().address!);
    const runesAddressFromManager = await manager.getDeps();
    console.log(usersRuneWalletFromManagerContract);
    console.log(runesAddressFromManager.runecoinAddress);
    console.log('Manager');

    const totalAmount = await runecoinOwner.getTotalAmount();
    console.log('В хранилище владельца: ', numberFormat(fromNano(totalAmount)));
}
