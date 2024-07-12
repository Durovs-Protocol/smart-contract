import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { buildOnchainMetadata } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { Runecoin } from '../wrappers/Runecoin';

import { RunecoinWallet } from '../wrappers/RunecoinWallet';

import { UsdTonMaster } from '../wrappers/UsdTon';
import { UserPosition } from '../wrappers/UserPosition';

describe('UserFlow', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;

    let pool: SandboxContract<Pool>;
    let usdTon: SandboxContract<UsdTonMaster>;
    let manager: SandboxContract<Manager>;
    let runecoin: SandboxContract<Runecoin>;

    let runecoinWallet: SandboxContract<RunecoinWallet>;
    let userPosition: SandboxContract<UserPosition>;

    beforeAll(async () => {
        const jettonParams = {
            name: 'yt',
            symbol: 'yt',
            description: 'yt',
            image: '',
        };
        const runecoinParams = {
            name: 'rune',
            symbol: 'rune',
            description: 'rune',
            image: '',
        };

        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        usdTon = blockchain.openContract(
            await UsdTonMaster.fromInit(deployer.getSender().address, buildOnchainMetadata(jettonParams)),
        );

        runecoin = blockchain.openContract(
            await Runecoin.fromInit(deployer.getSender().address, buildOnchainMetadata(runecoinParams)),
        );

        runecoinWallet = blockchain.openContract(
            await RunecoinWallet.fromInit(runecoin.address, deployer.getSender().address),
        );

        pool = blockchain.openContract(await Pool.fromInit(deployer.getSender().address));
        manager = blockchain.openContract(await Manager.fromInit(deployer.getSender().address));

        const deployPool = await pool.send(
            deployer.getSender(),
            {
                value: toNano('1'),
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
                value: toNano('1'),
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
                value: toNano('0.05'),
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
            { value: toNano(0.1) },
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
            { value: toNano(0.1) },
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
            { value: toNano(0.1) },
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
            { value: toNano(1) },
            {
                $$type: 'SetPoolSettings',
                liquidationFee: toNano(0.15),
                liquidationRatio: toNano(1.2),
                stabilityFeeRate: toNano('0.02'),
                liquidationFee: toNano('0.15'),
            },
        );

        await manager.send(
            deployer.getSender(),
            { value: toNano(1) },
            {
                $$type: 'UpdateTonPriceMsg',
                price: toNano(7),
            },
        );
    });
    it('deps set ok', async () => {
        const usdTonDeps = await usdTon.getDeps();
        expect(usdTonDeps.poolAddress.toString()).toEqual(pool.address.toString());
        expect(usdTonDeps.managerAddress.toString()).toEqual(manager.address.toString());

        const positionsManagerDeps = await manager.getDeps();
        expect(positionsManagerDeps.poolAddress.toString()).toEqual(pool.address.toString());
        expect(positionsManagerDeps.usdTonAddress.toString()).toEqual(usdTon.address.toString());

        const poolDeps = await pool.getDeps();
        expect(poolDeps.usdTonAddress.toString()).toEqual(usdTon.address.toString());
        expect(poolDeps.managerAddress.toString()).toEqual(manager.address.toString());
    });

    it('pool settings set ok', async () => {
        const poolSettings = await manager.getPoolSettings();
        expect(poolSettings.liquidationRatio).toEqual(toNano(1.2));

        expect(poolSettings.stabilityFeeRate).toEqual(toNano('0.02'));
    });

    it('initial price set ok', async () => {
        const tonPrice = await manager.getTonPrice();
        expect(tonPrice).toEqual(toNano(7));
        const tonPriceWithHealthRate = await manager.getTonPriceWithHealthRate();
        expect(tonPriceWithHealthRate).toEqual(5833333333n);
        ///???
    });
});
