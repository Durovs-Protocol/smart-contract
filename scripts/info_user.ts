import { NetworkProvider } from '@ton/blueprint';
import { Address, Dictionary, fromNano } from '@ton/core';
import { assets } from '../utils/data';
import { loadAddress, log } from '../utils/helpers';
import { Manager, SupplyTimestamp } from '../wrappers/V0.Manager';
import { NewManager } from '../wrappers/V0.NewManager';
import { NewUp } from '../wrappers/V0.NewUp';
import { UserPosition } from '../wrappers/V0.UserPosition';
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
        await withdrawState()
        await supplyTimestamps()
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
    async function withdrawState() {
        const withdrawStates = await userPosition.getWithdrawState();
        if ( withdrawStates) {
            console.log(withdrawStates)
            // нужно id
        }
    }
    async function supplyTimestamps() {
        const supplyTimestamps: Dictionary<Address, SupplyTimestamp> = await userPosition.getSupplyTimestamps();
        const stakedTON = supplyTimestamps.get(Address.parse(assets[0].master)) ?? 0
        const hipoStakedTON = supplyTimestamps.get(Address.parse(assets[1].master)) ?? 0
        const tonstakers = supplyTimestamps.get(Address.parse(assets[2].master)) ?? 0
        const toncoin = supplyTimestamps.get(Address.parse(assets[3].master)) ?? 0
        log('Supply timestamps staked TON:');
        console.log(stakedTON != 0 ? stakedTON.info : '')
        log('Supply timestamps hipo');
        console.log(hipoStakedTON != 0 ? hipoStakedTON.info : '' )
        log('Supply timestamps ton Stakers ');
        console.log(tonstakers != 0 ? tonstakers.info : '' )
        log('Supply timestamps toncoin: ');
        console.log(toncoin != 0 ? toncoin.info : '')
    }
    log('Finished');
}
