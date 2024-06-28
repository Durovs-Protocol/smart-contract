import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { Runecoin } from '../wrappers/Runecoin';
import { UsdTonMaster } from '../wrappers/UsdTon';

export async function run(provider: NetworkProvider) {
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool'))));
    const runeCoin = provider.open(await Runecoin.fromAddress(Address.parse(await loadAddress('runecoin'))));

    async function setDeps(contract: any, name: string) {
        console.log(
            `--------------------------------------------------------------------------------------------------------`,
        );
        console.log(
            `======${name.toUpperCase()}=============================================================================`,
        );
        console.log(
            `--------------------------------------------------------------------------------------------------------`,
        );
        await contract.send(
            provider.sender(),
            { value: toNano('0.1') },
            {
                $$type: 'SetDeps',
                managerAddress: manager.address,
                poolAddress: poolContract.address,
                usdTonAddress: usdTon.address,
                runecoinAddress: runeCoin.address,
            },
        );

        await timer(`manager address`, `Set deps in ${name}`, manager.address, managerAddress(contract));
        await timer(`pool address`, `Set deps in ${name}`, poolContract.address, poolAddress(contract));
        await timer(`stable address`, `Set deps in ${name}`, usdTon.address, usdTonAddress(contract));
        await timer(`runeCoin address`, `Set deps in ${name}`, runeCoin.address, runecoinAddress(contract));
    }

    await setDeps(usdTon, 'usdTon');
    await setDeps(manager, 'manager');
    await setDeps(poolContract, 'pool');
    console.log('=============================================================================');
    console.log('Deps installed successfully');
    console.log('=============================================================================');
}

const managerAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.managerAddress.toString();
    };
};
const poolAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.poolAddress.toString();
    };
};
const usdTonAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.usdTonAddress.toString();
    };
};

const runecoinAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.runecoinAddress.toString();
    };
};
