import { NetworkProvider } from '@ton/blueprint';
import { Address, Dictionary, fromNano } from '@ton/core';
import { assets } from '../utils/data';
import { loadAddress, log } from '../utils/helpers';
import { Manager } from '../wrappers/v0.Manager';
import { NewManager } from '../wrappers/v0.NewManager';
import { NewUp } from '../wrappers/v0.NewUp';
import { UserPosition } from '../wrappers/v0.UserPosition';
export async function run(provider: NetworkProvider) {
    log('User Position info');

    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const newManager = provider.open(await NewManager.fromAddress(Address.parse(await loadAddress('new_manager'))));
    const user = provider.sender().address as Address;
    /**
     * User position (определение up, проверка балансов)
     */
    const userPositionAddress = await manager.getUserPositionAddress(user);
    const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
    const isActive = await userPosition.getStatus();
    if (!isActive) {
        // проверка миграции 
        console.log('User position migrated', '\n\n');
        const newUserPositionAddress = await newManager.getUserPositionAddress(user);
        const newUserPosition = provider.open(await NewUp.fromAddress(newUserPositionAddress));
        console.log('new user Position address:  ', newUserPosition.address.toString() + '\n\n');
    } else {
        console.log('User Position address:  ', userPosition.address.toString() + '\n\n');
        await showBalancves()
    }

    async function showBalancves() {
        const balances: Dictionary<Address, bigint> = await userPosition.getBalances();
        const stakedTON = balances.get(Address.parse(assets[0].master)) ?? 0
        const hipoStakedTON = balances.get(Address.parse(assets[1].master)) ?? 0
        const tonstakers = balances.get(Address.parse(assets[2].master)) ?? 0
        const toncoin = balances.get(Address.parse(assets[3].master)) ?? 0
        log(
            'Staked TON:    ' +
                fromNano(stakedTON) +
                '\nHipo Staked TON: ' +
                fromNano(hipoStakedTON) +
                '\nTon Stakers:       ' +
                fromNano(tonstakers) +
                '\nToncoin:   ' +
                fromNano(toncoin)
        );
    }
    log('Finished');
}
