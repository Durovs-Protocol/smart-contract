import { NetworkProvider } from '@ton/blueprint';
import { Address, Dictionary } from '@ton/core';
import contracts from '../utils/contracts';
import { assets } from '../utils/data';
import { log } from '../utils/helpers';
import { Asset } from '../wrappers/V0.Manager';

export async function run(provider: NetworkProvider) {

    const { reservePool, manager } = await contracts(provider, provider.sender().address!!);
    // await showPoolWallets(managerContract, 'manager');
    // await showPoolWallets(poolContract, 'reservePool');
    // await showDeps(managerContract, 'manager');
    // await showDeps(poolContract, 'reservePool');
    log(
        'Version:'+
            '\npool: ' +
            await reservePool.getVersion() +
            '\nmanager: ' +
            await manager.getVersion()
    );

    let settings = await manager.getSettings();

    log(
        'System setting information'.toUpperCase() +
            'max Amount           : ' +
            settings.maxAmount +
            '\nmin Delay      : ' +
            settings.minDelay +
            ' (ton)' +
            '\nnew Manager      : ' +
            settings.newManager.toString(),
    );

    async function showPoolWallets(contract: any, name: string) {
        const allAssets: Dictionary<Address, Asset> = await contract.getAssets();
        const stakedTON = allAssets.get(Address.parse(assets[0].master))?.poolWallet.toString();
        const hipoStakedTON = allAssets.get(Address.parse(assets[1].master))?.poolWallet.toString();
        const tonstakers = allAssets.get(Address.parse(assets[2].master))?.poolWallet.toString();
        const toncoin = allAssets.get(Address.parse(assets[3].master))?.poolWallet.toString();
        log(
            `Assets in ${name}`.toUpperCase() + 'Staked TON pool wallet :    ' + stakedTON ??
                '' + '\nHipo Staked TON pool wallet: ' + hipoStakedTON ??
                '' + '\nTon Stakers pool wallet:       ' + tonstakers ??
                '' + '\nToncoin pool wallet:   ' + toncoin ??
                '',
        );
    }
    async function showDeps(contract: any, name: string) {
        const deps = await contract.getDeps();

        log(
            `deps in ${name}`.toUpperCase() +
                'manager :    ' +
                deps.manager.toString() +
                '\nreservePool: ' +
                deps.reservePool.toString() +
                '\nprofitPool:       ' +
                deps.profitPool.toString() +
                '\nusdton:   ' +
                deps.usdton.toString(),
        );
    }
}
