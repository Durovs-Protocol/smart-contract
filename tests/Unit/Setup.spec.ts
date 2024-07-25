import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { buildOnchainMetadata } from '../../utils/helpers';
import { Manager } from '../../wrappers/Manager';
import { Pool } from '../../wrappers/ReservePool';
import { Runecoin } from '../../wrappers/Runecoin';

import { RunecoinWallet } from '../../wrappers/RunecoinWallet';

import {
    gasFee,
    liquidationFee,
    liquidationRatio,
    stabilityFeeRate,
    testJettonParams,
    testRunecoinParams,
    tonPrice,
} from '../../utils/data';
import { UsdTonMaster } from '../../wrappers/UsdTon';

describe('Setup', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;

    let pool: SandboxContract<Pool>;
    let usdTon: SandboxContract<UsdTonMaster>;
    let manager: SandboxContract<Manager>;
    let runecoin: SandboxContract<Runecoin>;

    let runecoinWallet: SandboxContract<RunecoinWallet>;

    beforeAll(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        usdTon = blockchain.openContract(
            await UsdTonMaster.fromInit(deployer.getSender().address, buildOnchainMetadata(testJettonParams)),
        );

        runecoin = blockchain.openContract(
            await Runecoin.fromInit(deployer.getSender().address, buildOnchainMetadata(testRunecoinParams)),
        );

        runecoinWallet = blockchain.openContract(
            await RunecoinWallet.fromInit(deployer.getSender().address, deployer.getSender().address),
        );

        pool = blockchain.openContract(await Pool.fromInit(deployer.getSender().address));
        manager = blockchain.openContract(await Manager.fromInit(deployer.getSender().address));

        const deployPool = await pool.send(
            deployer.getSender(),
            {
                value: toNano(gasFee),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        expect(deployPool.transactions).toHaveTransaction({
            from: deployer.address,
            to: pool.address,
            deploy: true,
            success: true,
        });

        const deployManager = await manager.send(
            deployer.getSender(),
            {
                value: toNano(gasFee),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        expect(deployManager.transactions).toHaveTransaction({
            from: deployer.address,
            to: manager.address,
            deploy: true,
            success: true,
        });

        const deployUsdToncoin = await usdTon.send(
            deployer.getSender(),
            {
                value: toNano(gasFee),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        expect(deployUsdToncoin.transactions).toHaveTransaction({
            from: deployer.address,
            to: usdTon.address,
            deploy: true,
            success: true,
        });

        await pool.send(
            deployer.getSender(),
            { value: toNano(gasFee) },
            {
                $$type: 'SetDeps',
                managerAddress: manager.address,
                poolAddress: pool.address,
                usdTonAddress: usdTon.address,
                runecoinAddress: runecoin.address,
            },
        );
        await manager.send(
            deployer.getSender(),
            { value: toNano(gasFee) },
            {
                $$type: 'SetDeps',
                managerAddress: manager.address,
                poolAddress: pool.address,
                usdTonAddress: usdTon.address,
                runecoinAddress: runecoin.address,
            },
        );
        await usdTon.send(
            deployer.getSender(),
            { value: toNano(gasFee) },
            {
                $$type: 'SetDeps',
                managerAddress: manager.address,
                poolAddress: pool.address,
                usdTonAddress: usdTon.address,
                runecoinAddress: runecoin.address,
            },
        );

        await manager.send(
            deployer.getSender(),
            { value: toNano(gasFee) },
            {
                $$type: 'SetSettings',
                liquidationFee: toNano(liquidationFee),
                liquidationRatio: toNano(liquidationRatio),
                stabilityFeeRate: toNano(stabilityFeeRate),
            },
        );

        await manager.send(
            deployer.getSender(),
            { value: toNano(gasFee) },
            {
                $$type: 'UpdateTonPriceMsg',
                price: toNano(tonPrice),
            },
        );
    });
    it('Dependencies set successfully', async () => {
        const usdTonDeps = await usdTon.getDeps();
        expect(usdTondeps.resrvePool.toString()).toEqual(pool.address.toString());
        expect(usdTondeps.manager.toString()).toEqual(manager.address.toString());

        const positionsManagerDeps = await manager.getDeps();
        expect(positionsManagerdeps.resrvePool.toString()).toEqual(pool.address.toString());
        expect(positionsManagerdeps.usdton.toString()).toEqual(usdTon.address.toString());

        const poolDeps = await pool.getDeps();
        expect(pooldeps.usdton.toString()).toEqual(usdTon.address.toString());
        expect(pooldeps.manager.toString()).toEqual(manager.address.toString());
    });

    it('Pool settings set successfully', async () => {
        const settings = await manager.getSettings();
        expect(settings.liquidationRatio).toEqual(toNano(liquidationRatio));
        expect(settings.stabilityFeeRate).toEqual(toNano(stabilityFeeRate));
        expect(settings.liquidationFee).toEqual(toNano(liquidationFee));
    });

    it('Initial TON price set successfully', async () => {
        const currentTonPrice = await manager.getTonPrice();
        expect(currentTonPrice).toEqual(toNano(tonPrice));
    });
});
