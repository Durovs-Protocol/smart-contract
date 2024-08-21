import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { setupGas } from '../utils/data';
import { loadAddress, log, timer } from '../utils/helpers';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { Manager } from '../wrappers/v0.Manager';
import { ReservePool } from '../wrappers/v0.ReservePool';

export async function run(provider: NetworkProvider) {
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const profitPool = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('profitPool'))));
    const reservePool = provider.open(await ReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))));

    // const newManager = provider.open(await NewManager.fromAddress(Address.parse(await loadAddress('new_manager'))));

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
                runaCoupon: manager.address,
            },
        );

        await timer(`Set deps in ${name}`, usdTon.address, usdTonAddress(contract));
        await timer(`Set deps in ${name}`, manager.address, managerAddress(contract));
        await timer(`Set deps in ${name}`, profitPool.address, profitPoolAddress(contract));
        await timer(`Set deps in ${name}`, reservePool.address, reservePoolAddress(contract));
    }


    await setDeps(manager, 'manager');
    await setDeps(reservePool, 'reservePool');
    // await setDeps(profitPool, 'profitPool');
    // await setDeps(usdTon, 'usdTon');
    
    // часть миграции
    // await newManager.send(
    //     provider.sender(),
    //     { value: toNano(setupGas) },
    //     {
    //         $$type: 'SetDeps',
    //         manager: newManager.address,
    //         profitPool: manager.address,
    //         reservePool: reservePool.address,
    //         usdton: manager.address,
    //         runaCoupon: manager.address,
    //     },
    // );
    // await timer(`Setup new manager address`, newManager.address, newManagerAddress(newManager));
    log('Deps installed successfully');
}

const managerAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.manager.toString();
    };
};
const newManagerAddress = function (contract: any) {
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
