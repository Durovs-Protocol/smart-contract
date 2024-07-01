import { toNano, fromNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { buildOnchainMetadata } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { Runecoin } from '../wrappers/Runecoin';
import { RuneCoinOwner } from '../wrappers/RunecoinOwner';
import { RunecoinWallet } from '../wrappers/RunecoinWallet';

import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';
import { UserPosition } from '../wrappers/UserPosition';

describe('UserFlow', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let pool: SandboxContract<Pool>;
    let usdTon: SandboxContract<UsdTonMaster>;
    let manager: SandboxContract<Manager>;
    let runecoin: SandboxContract<Runecoin>;
    let runecoinOwner: SandboxContract<RuneCoinOwner>;
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
        runecoinOwner = blockchain.openContract(await RuneCoinOwner.fromInit(deployer.getSender().address));

        runecoin = blockchain.openContract(
            await Runecoin.fromInit(runecoinOwner.address, buildOnchainMetadata(runecoinParams)),
        );

        await runecoinOwner.send(
            deployer.getSender(),
            {
                value: toNano(1),
            },
            {
                $$type: 'SetBalance',
                amount: toNano(1000000000),
                content: buildOnchainMetadata(jettonParams),
            },
        );
        runecoinWallet = blockchain.openContract(
            await RunecoinWallet.fromInit(runecoin.address, deployer.getSender().address),
        );
        console.log('runecoinWallet');
        console.log(runecoinWallet.address);

        pool = blockchain.openContract(await Pool.fromInit(deployer.getSender().address));
        manager = blockchain.openContract(await Manager.fromInit(deployer.getSender().address));

        // userPosition = blockchain.openContract(
        //     await UserPosition.fromInit(
        //         deployer.getSender().address,
        //         usdTon.address,
        //         manager.address,
        //         pool.address,
        //         runecoin.address,
        //     ),
        // );
        const deployPool = await pool.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
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

        // const deployUserPosition = await userPosition.send(
        //     deployer.getSender(),
        //     {
        //         value: toNano('0.05'),
        //     },
        //     {
        //         $$type: 'Test',
        //         amount: toNano('0.05'),
        //         user: deployer.getSender().address!,
        //     },
        // );

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

        const deployManager = await manager.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
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
                liquidationRatio: toNano(1.2),
                stabilityFeeRate: toNano('0.02'),
                liquidatorIncentiveBps: toNano(1.05),
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

        await runecoinOwner.send(
            deployer.getSender(),
            { value: toNano(1) },
            {
                $$type: 'GetRunecoin',
                amount: toNano(123),
                user: deployer.getSender().address,
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
        expect(poolSettings.liquidatorIncentiveBps).toEqual(toNano(1.05));
        expect(poolSettings.stabilityFeeRate).toEqual(toNano('0.02'));
    });

    it('initial price set ok', async () => {
        const tonPrice = await manager.getTonPrice();
        expect(tonPrice).toEqual(toNano(7));
        const tonPriceWithHealthRate = await manager.getTonPriceWithHealthRate();
        expect(tonPriceWithHealthRate).toEqual(5833333333n);
        ///???
    });

    it('user flow', async () => {
        const collateralDepositAmount = toNano(1);
        const currentPositionId = await manager.getLastPositionId();

        await manager.send(
            deployer.getSender(),
            { value: collateralDepositAmount + toNano(2) },
            {
                $$type: 'DepositCollateralUserMessage',
                user: deployer.getSender().address,
                amount: collateralDepositAmount,
            },
        );

        /**
         * 
         */
        const lastPositionId = await manager.getLastPositionId();
        // expect(Number(lastPositionId) - Number(currentPositionId)).toEqual(1n);

        // userPosition contract has a state with deposited collateral stored
        // const userPositionContract = blockchain.openContract(
        //     await UserPosition.fromInit(
        //         deployer.address,
        //         usdTon.address,
        //         manager.address,
        //         pool.address,
        //         runecoin.address,
        //     ),
        // );
        // let positionState = await userPositionContract.getPositionState();

        // expect(positionState.collateral).toEqual(collateralDepositAmount);

    //     // -- user draw usdTons
    //     const initialTotalSupply = await usdTon.getTotalSupply();

    //     expect(initialTotalSupply).toEqual(0n);

    //     const stablesBorrowed = toNano(2);

    //     await manager.send(
    //         deployer.getSender(),
    //         { value: toNano(1) },
    //         {
    //             $$type: 'MintUsdTonMessage',
    //             user: deployer.getSender().address,
    //             amount: stablesBorrowed,
    //         },
    //     );

    //     const userUsdToncoinWalletAddress = await usdTon.getGetWalletAddress(deployer.getSender().address);
    //     const userUsdTonWallet = blockchain.openContract(await UsdTonWallet.fromAddress(userUsdToncoinWalletAddress));
    //     let userUsdTonBalance = await userUsdTonWallet.getGetBalance();

    //     expect(userUsdTonBalance).toEqual(stablesBorrowed);

    //     const currentTotalSupply = await usdTon.getTotalSupply();
    //     expect(currentTotalSupply).toEqual(stablesBorrowed);

    //     // position updated
    //     positionState = await userPositionContract.getPositionState();
    //     expect(positionState.debt).toEqual(stablesBorrowed);

    //     userUsdTonBalance = await userUsdTonWallet.getGetBalance();
    //     console.log('balance before repay', userUsdTonBalance);

    //     // user pays stables back
    //     await manager.send(
    //         deployer.getSender(),
    //         { value: toNano('1') },
    //         {
    //             $$type: 'BurnUsdTONUserMessage',
    //             user: deployer.getSender().address,
    //             amount: stablesBorrowed,
    //         },
    //     );

    //     let positionMessage = await userPositionContract.getMessage();
    //     console.log({ positionMessage });

    //     userUsdTonBalance = await userUsdTonWallet.getGetBalance();
    //     console.log('balance after repay', userUsdTonBalance);

    //     expect(userUsdTonBalance).toEqual(0n);

    //     positionState = await userPositionContract.getPositionState();
    //     console.log({ positionState });
    //     expect(positionState.debt).toEqual(0n);

    //     // withdraw collateral

    //     const collateralToWithdraw = toNano('0.5');

    //     await manager.send(
    //         deployer.getSender(),
    //         { value: toNano('1') },
    //         {
    //             $$type: 'WithdrawCollateralUserMessage',
    //             user: deployer.getSender().address,
    //             amount: collateralToWithdraw,
    //         },
    //     );

    //     positionState = await userPositionContract.getPositionState();
    //     console.log({ positionState });
    //     expect(positionState.collateral).toEqual(500000000n);

    //     const message = await userPositionContract.getMessage();
    //     console.log({ message });
    });
});
