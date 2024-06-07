import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { StablecoinMaster } from '../wrappers/Stablecoin';

export async function run(provider: NetworkProvider) {
    const stablecoin = provider.open(
        await StablecoinMaster.fromAddress(Address.parse(await loadAddress('stablecoin'))),
    );
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));

    async function setDeps(contract: any, name: string) {
        await contract.send(
            provider.sender(),
            { value: toNano('0.1') },
            {
                $$type: 'SetDeps',
                positionsManagerAddress: manager.address,
                poolAddress: poolContract.address,
                stablecoinMasterAddress: stablecoin.address,
            },
        );

        const managerAddr = 'EQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM9c';
        await timer(`Адрес менеджера в контракте ${name}: `, managerAddr, managerAddress(contract));

        const poolAddr = await poolAddress(contract)();

        await timer(`Адрес пула в контракте ${name}: `, managerAddr, poolAddress(contract));
        const stablecoinAddressAddr = await stablecoinAddress(contract)();
        await timer(`Адрес стейблкоина в контракте ${name}: `, managerAddr, stablecoinAddress(contract));
    }

    await setDeps(stablecoin, 'stablecoin');
    await setDeps(manager, 'manager');
    await setDeps(poolContract, 'pool');
}

const managerAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.positionsManagerAddress.toString();
    };
};
const poolAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.poolAddress.toString();
    };
};
const stablecoinAddress = function (contract: any) {
    return async function () {
        const deps = await contract.getDeps();
        return deps.stablecoinMasterAddress.toString();
    };
};
