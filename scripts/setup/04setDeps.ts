import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../../utils/helpers';
import { Manager } from '../../wrappers/Manager';
import { Pool } from '../../wrappers/PoolContract';
import { StablecoinMaster } from '../../wrappers/Stablecoin';

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

        const managerAddressBefore = await managerAddress(contract)();
        await timer(`Адрес менеджера в контракте ${name}: `, managerAddressBefore, managerAddress(contract));

        const poolAddressBefore = await poolAddress(contract)();
        await timer(`Адрес пула в контракте ${name}: `, poolAddressBefore, poolAddress(contract));

        const stableCoinBefore = await stablecoinAddress(contract)();
        await timer(`Адрес стейблкоина в контракте ${name}: `, stableCoinBefore, stablecoinAddress(contract));
    }

    await setDeps(stablecoin, 'stablecoin');
}

const managerAddress = function (contract: any) {
    return async function () {
        const managerAddress = await contract.getDeps();
        return managerAddress.positionsManagerAddress;
    };
};
const poolAddress = function (contract: any) {
    return async function () {
        const managerAddress = await contract.getDeps();
        return managerAddress.poolAddress;
    };
};
const stablecoinAddress = function (contract: any) {
    return async function () {
        const managerAddress = await contract.getDeps();
        return managerAddress.stablecoinMasterAddress;
    };
};
