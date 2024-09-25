import { NetworkProvider } from '@ton/blueprint';
import { Address, Dictionary } from '@ton/core';
import contracts from '../utils/contracts';
import { assets } from '../utils/data';
import { log } from '../utils/helpers';
import { Asset } from '../wrappers/Manager';

export async function run(provider: NetworkProvider) {

    const { reservePool, manager, v1manager } = await contracts(provider, provider.sender().address!!);

    await showWallets(manager, 'manager');
    await showWallets(reservePool, 'reservePool');
    await showDeps(manager, 'manager')
    await showDeps(reservePool, 'reservePool')

    log(
        'Versions'.toUpperCase() +
            '\npool   : ' +
            await reservePool.getVersion() +
            '\nmanager: ' +
            await manager.getVersion()
    );

    let settings = await manager.getSettings();
    let settingsv1 = await v1manager.getSettings();
    console.log(settingsv1)

    log(
        'System setting information'.toUpperCase() +
            '\nmin Delay           : ' +
            settings.minDelay +
            '\nnew Manager Address : ' +
            settings.newManager.toString() +
            '\nmax Execution Time  : ' +
            settings.maxExecutionTime + 
            //
            process.env.v == '1' ?
            //
            '\nmax Coupon rate  : ' +
            settingsv1.couponRate!! : ''
    );
    async function showWallets(contract: any, name: string) {
        const allBalances: Dictionary<Address, Asset> = await contract.getBalances();
        const toncoin = allBalances.get(Address.parse(assets[0].master))!!.toString();
        const stakedTON = allBalances.get(Address.parse(assets[1].master))!!.toString();
        const hipoStakedTON = allBalances.get(Address.parse(assets[2].master))!!.toString();
        const tonstakers = allBalances.get(Address.parse(assets[3].master))!!.toString();
        log(
            `Assets in ${name}`.toUpperCase() + 
                '\nStaked TON pool wallet     :' + stakedTON +
                '\nHipo Staked TON pool wallet:' + hipoStakedTON +
                '\nTon Stakers pool wallet    :' + tonstakers +
                '\nToncoin pool wallet        :' + toncoin 
        );
    }

    async function showDeps(contract: any, name: string) {
        const deps = await contract.getDeps();

        log(
            `deps in ${name}`.toUpperCase() +
                '\nmanager    :' +
                deps.manager.toString() +
                '\nreservePool:' +
                deps.reservePool.toString() +
                '\nprofitPool :' +
                deps.profitPool.toString() +
                '\nstable     :' +
                deps.stable.toString(),
        );
    }
}
