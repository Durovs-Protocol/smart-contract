import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { setupGas } from '../utils/data';
import { loadAddress, log, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { ProfitPool } from '../wrappers/ProfitPool';
import { ReservePool } from '../wrappers/ReservePool';
import { RunaCoupon } from '../wrappers/RunaCoupon';
import { UsdTonMaster } from '../wrappers/UsdTon';

export async function run(provider: NetworkProvider) {
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const runaCoupon = provider.open(await RunaCoupon.fromAddress(Address.parse(await loadAddress('runaCoupon'))));
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const profitPool = provider.open(await ProfitPool.fromAddress(Address.parse(await loadAddress('profitPool'))));
    const reservePool = provider.open(await ReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))));

    async function setDeps(contract: any, name: string) {
        log(name.toUpperCase());
        await contract.send(
            provider.sender(),
            { value: toNano(setupGas) },
            {
                $$type: 'SetDeps',
                manager: manager.address,
                profitPool: profitPool.address,
                reservePool: reservePool.address,
                usdton: usdTon.address,
                runaCoupon: runaCoupon.address,
            },
        );

        await timer(`Setup manager address`, `Set deps in ${name}`, manager.address, managerAddress(contract));
        await timer(
            `Setup reservePool address`,
            `Set deps in ${name}`,
            reservePool.address,
            reservePoolAddress(contract),
        );
        await timer(`Setup profitPool address`, `Set deps in ${name}`, profitPool.address, profitPoolAddress(contract));
        await timer(`Setup stable address`, `Set deps in ${name}`, usdTon.address, usdTonAddress(contract));
    }

    await setDeps(usdTon, 'usdTon');
    await setDeps(manager, 'manager');
    await setDeps(reservePool, 'reservePool');
    await setDeps(profitPool, 'profitPool');
    log('Deps installed successfully');
}

const managerAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.manager.toString();
    };
};

const reservePoolAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.reservePool.toString();
    };
};
const profitPoolAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.profitPool.toString();
    };
};
const usdTonAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.usdton.toString();
    };
};
