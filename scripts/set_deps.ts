import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import contracts from '../utils/contracts';
import { setupGas } from '../utils/data';
import { contractVersion, log, timer } from '../utils/helpers';

export async function run(provider: NetworkProvider) {
    const user = provider.sender().address as Address;
    const { reservePool, manager, stable, coupon } = await contracts(provider, user);


	log('Установка зависимостей:'+
        `\n ${await contractVersion(manager, 'manager')}` +
        `\n ${await contractVersion(reservePool, 'reserve pool')}` 
    );
    async function setDeps(contract: any, name: string) {
        log(name.toUpperCase());
        await contract.send(
            provider.sender(),
            { value: toNano(setupGas) },
            {
                $$type: 'SetDeps',
                manager: manager.address,
                profitPool: Address.parse('UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ'),
                reservePool: reservePool.address,
                stable: stable.address,
                coupon: coupon.address,
            },
        );

        await timer(`Set deps in ${name}`, stable.address, stableAddress(contract));
        await timer(`Set deps in ${name}`, manager.address, managerAddress(contract));
        await timer(`Set deps in ${name}`, reservePool.address, reservePoolAddress(contract));
        await timer(`Set deps in ${name}`, coupon.address, couponAddress(contract));
        
    }

    // await setDeps(manager, 'manager');
    // await setDeps(reservePool, 'reservePool');
    
    if (process.env.v == '1') {
        // await setDeps(stable, 'stableContract');
        await setDeps(coupon, 'coupon');
    }

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
const stableAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();

        return deps.stable.toString();
    };
};
const couponAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();

        return deps.coupon.toString();
    };
};
