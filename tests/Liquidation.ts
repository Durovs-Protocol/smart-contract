import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { buildOnchainMetadata } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { Runecoin } from '../wrappers/Runecoin';
import { RunecoinWallet } from '../wrappers/RunecoinWallet';

import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';
import { UserPosition } from '../wrappers/UserPosition';
import { jettonParams, runecoinParams } from '../utils/data';

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

    // it('liquidation', async () => {
    //     const collateralDepositAmount = toNano(1);
    //     const currentPositionId = await manager.getLastPositionId();

    //     await manager.send(
    //         deployer.getSender(),
    //         { value: collateralDepositAmount + toNano(2) },
    //         {
    //             $$type: 'DepositCollateralUserMessage',
    //             user: deployer.getSender().address,
    //             amount: collateralDepositAmount,
    //             runesWallet: deployer.getSender().address,
    //         },
    //     );
    //     const userPositionAddress = await manager.getUserPositionAddress(deployer.getSender().address);
    //     console.log(userPositionAddress);
    //     // запись о залоге есть в контракте user position
    //     const userPosition = blockchain.openContract(await UserPosition.fromAddress(userPositionAddress));

    //     let positionState = await userPosition.getPositionState();

    //     expect(positionState.collateral).toEqual(collateralDepositAmount);

    //     // пользователь минтит USDTON
    //     const initialTotalSupply = await usdTon.getTotalSupply();
    //     expect(initialTotalSupply).toEqual(0n);
    //     const stablesBorrowed = toNano(3.5);

    //     const mintTransaction = await manager.send(
    //         deployer.getSender(),
    //         { value: toNano(1) },
    //         {
    //             $$type: 'MintUsdTonMessage',
    //             user: deployer.getSender().address,
    //             amount: stablesBorrowed,
    //         },
    //     );

    //     expect(mintTransaction.transactions).toHaveTransaction({
    //         from: manager.address,
    //         to: userPosition.address,
    //         success: true,
    //     });

    //     // баланс кашелька равен указанной сумме
    //     const userUsdToncoinWalletAddress = await usdTon.getGetWalletAddress(deployer.getSender().address);
    //     const userUsdTonWallet = blockchain.openContract(await UsdTonWallet.fromAddress(userUsdToncoinWalletAddress));
    //     let userUsdTonBalance = await userUsdTonWallet.getGetBalance();
    //     expect(userUsdTonBalance).toEqual(stablesBorrowed);

    //     // в user position указана та же сумма
    //     positionState = await userPosition.getPositionState();
    //     expect(positionState.debt).toEqual(stablesBorrowed);

    //     await manager.send(
    //         deployer.getSender(),
    //         { value: toNano(1) },
    //         {
    //             $$type: 'UpdateTonPriceMsg',
    //             price: toNano(6),
    //         },
    //     );

    //     await manager.send(
    //         deployer.getSender(),
    //         { value: toNano(1) },
    //         {
    //             $$type: 'PositionLiquidationInspectorMessage',
    //             user: deployer.getSender().address,
    //         },
    //     );
    //     const message = await userPosition.getMessage();
    //     console.log({ message });
    // });
});
