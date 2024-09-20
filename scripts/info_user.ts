import { NetworkProvider } from '@ton/blueprint';
import { Address, Dictionary, fromNano } from '@ton/core';
import contracts from '../utils/contracts';
import { assets } from '../utils/data';
import { log } from '../utils/helpers';
// import { SupplyTimestamp } from '../wrappers/Manager';
export async function run(provider: NetworkProvider) {
    const user = provider.sender().address as Address;
    log('User Position info');

    const {
        userPosition, // зависит от env
        v1userPosition,
    } = await contracts(provider, user);

    /*
     * User position (определение up, проверка балансов)
     */
    log(
        'User position version: '
        + await  userPosition.getVersion()
    );

    await showBalancves(userPosition);
    // await withdrawState(userPosition)
    // await supplyTimestamps(userPosition)

    try {
        // значение тут появится только после проверки, те после вызова функций mint/withdraw
        log('Total collateral in USD: ' + fromNano(await v1userPosition.getTotalCollateral()));
    } catch (e) {
        //TODO написать разветвление по версиям позиций и убрать этот блок
    }

    async function showBalancves(contract: any) {
        /**
         * TON - 0
         * stTON - 1
         * hTON - 2
         * tsTON - 3
         */
        const balances: Dictionary<Address, bigint> = await contract.getBalances();
        console.log(balances)
        const ton = balances.get(Address.parse(assets[0].master)) ?? -1
        const stakedTON = balances.get(Address.parse(assets[1].master)) ?? -1
        const hipoStakedTON = balances.get(Address.parse(assets[2].master)) ?? -1
        const tonstakers = balances.get(Address.parse(assets[3].master)) ?? -1
        log(
                '\nStaked TON     :' +
                fromNano(stakedTON) +
                '\nHipo Staked TON:' +
                fromNano(hipoStakedTON) +
                '\nTon Stakers    :' +
                fromNano(tonstakers) +
                '\nTON            :' +
                fromNano(ton)
        );
    }
    async function withdrawState(contract: any) {
        const withdrawStates = await contract.getWithdrawState();
        if (withdrawStates) {
            console.log(withdrawStates);
        }
    }

    // async function supplyTimestamps(contract: any) {
    //     const supplyTimestamps: Dictionary<Address, SupplyTimestamp> = await contract.getSupplyTimestamps();
    //     const stakedTON = supplyTimestamps.get(Address.parse(assets[0].master)) ?? 0;
    //     const hipoStakedTON = supplyTimestamps.get(Address.parse(assets[1].master)) ?? 0;
    //     const tonstakers = supplyTimestamps.get(Address.parse(assets[2].master)) ?? 0;
    //     const toncoin = supplyTimestamps.get(Address.parse(assets[3].master)) ?? 0;
    //     log('Supply timestamps staked TON:');
    //     console.log(stakedTON != 0 ? stakedTON.info : '');
    //     log('Supply timestamps hipo');
    //     console.log(hipoStakedTON != 0 ? hipoStakedTON.info : '');
    //     log('Supply timestamps ton Stakers ');
    //     console.log(tonstakers != 0 ? tonstakers.info : '');
    //     log('Supply timestamps toncoin: ');
    //     console.log(toncoin != 0 ? toncoin.info : '');
    // }
}
