import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { buildOnchainMetadata } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/ReservePool';
import { Runecoin } from '../wrappers/Runecoin';
import { RunecoinWallet } from '../wrappers/RunecoinWallet';

import { jettonParams } from '../utils/data';
import { UserPosition } from '../wrappers/UserPosition';
import { Stable } from '../wrappers/V1Stable';

describe('UserFlow', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;

    let pool: SandboxContract<Pool>;
    let stable: SandboxContract<Stable>;
    let manager: SandboxContract<Manager>;
    let runecoin: SandboxContract<Runecoin>;
    let runecoinWallet: SandboxContract<RunecoinWallet>;
    let userPosition: SandboxContract<UserPosition>;

    beforeAll(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        stable = blockchain.openContract(
            await Stable.fromInit(deployer.getSender().address, buildOnchainMetadata(jettonParams)),
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

        const deployDurovUsdcoin = await stable.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        expect(deployDurovUsdcoin.transactions).toHaveTransaction({
            from: deployer.address,
            to: stable.address,
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
                stableAddress: stable.address,
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
                stableAddress: stable.address,
                runecoinAddress: runecoin.address,
            },
        );
        await stable.send(
            deployer.getSender(),
            { value: toNano(0.1) },
            {
                $$type: 'SetDeps',
                managerAddress: manager.address,
                poolAddress: pool.address,
                stableAddress: stable.address,
                runecoinAddress: runecoin.address,
            },
        );

        await manager.send(
            deployer.getSender(),
            { value: toNano(1) },
            {
                $$type: 'SetSettings',
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

    it('deps set ok', async () => {
        const stableDeps = await stable.getDeps();
        expect(stabledeps.resrvePool.toString()).toEqual(pool.address.toString());
        expect(stabledeps.manager.toString()).toEqual(manager.address.toString());

        const positionsManagerDeps = await manager.getDeps();
        expect(positionsManagerdeps.resrvePool.toString()).toEqual(pool.address.toString());
        expect(positionsManagerdeps.usdton.toString()).toEqual(stable.address.toString());

        const poolDeps = await pool.getDeps();
        expect(pooldeps.usdton.toString()).toEqual(stable.address.toString());
        expect(pooldeps.manager.toString()).toEqual(manager.address.toString());
    });

    it('pool settings set ok', async () => {
        const settings = await manager.getSettings();
        expect(settings.liquidationRatio).toEqual(toNano(1.2));
        // expect(settings.liquidatorIncentiveBps).toEqual(toNano(1.05));
        expect(settings.stabilityFeeRate).toEqual(toNano('0.02'));
    });

    it('initial price set ok', async () => {
        const tonPrice = await manager.getTonPrice();
        expect(tonPrice).toEqual(toNano(7));
    });

    // it('user flow', async () => {
    //     const collateralSupplyAmount = toNano(1);
    //     const currentPositionId = await manager.getLastPositionId();

    //     await manager.send(
    //         deployer.getSender(),
    //         { value: collateralSupplyAmount + toNano(2) },
    //         {
    //             $$type: 'SupplyCollateralUserMessage',
    //             user: deployer.getSender().address,
    //             amount: collateralSupplyAmount,
    //             runesWallet: deployer.getSender().address,
    //         },
    //     );

    //     const lastPositionId = await manager.getLastPositionId();
    //     // expect(Number(lastPositionId) - Number(currentPositionId)).toEqual(1n);

    //     // userPosition contract has a state with deposited collateral stored
    //     const userPositionContract = blockchain.openContract(
    //         await UserPosition.fromInit(
    //             deployer.address,
    //             stable.address,
    //             manager.address,
    //             pool.address,
    //             // runecoin.address,
    //         ),
    //     );
    //     let positionState = await userPositionContract.getPositionState();

    //     // expect(positionState.collateral).toEqual(collateralSupplyAmount);
    //     // пользователь минтит USDTON
    //     const initialTotalSupply = await stable.getTotalSupply();
    //     expect(initialTotalSupply).toEqual(0n);
    //     const stablesBorrowed = toNano(2);
    // //     // -- user draw stables
    // //     const initialTotalSupply = await stable.getTotalSupply();

    // //     expect(initialTotalSupply).toEqual(0n);

    // //     const stablesBorrowed = toNano(2);

    // //     await manager.send(
    // //         deployer.getSender(),
    // //         { value: toNano(1) },
    // //         {
    // //             $$type: 'MintDurovUsdMessage',
    // //             user: deployer.getSender().address,
    // //             amount: stablesBorrowed,
    // //         },
    // //     );
    //     // баланс кашелька равен указанной сумме
    //     const userDurovUsdcoinWalletAddress = await stable.getGetWalletAddress(deployer.getSender().address);
    //     const userDurovUsdWallet = blockchain.openContract(await DurovUsdWallet.fromAddress(userDurovUsdcoinWalletAddress));
    //     let userDurovUsdBalance = await userDurovUsdWallet.getGetBalance();
    //     expect(userDurovUsdBalance).toEqual(stablesBorrowed);

    //     // монет выпущенно столько сколько наминтил пользователь
    //     const currentTotalSupply = await stable.getTotalSupply();
    //     expect(currentTotalSupply).toEqual(stablesBorrowed);

    //     // в user position указана та же сумма
    //     positionState = await userPositionContract.getPositionState();
    //     expect(positionState.debt).toEqual(stablesBorrowed);

    //     // burn
    //     userDurovUsdBalance = await userDurovUsdWallet.getGetBalance();
    //     console.log('balance before burn', userDurovUsdBalance);

    //     await manager.send(
    //         deployer.getSender(),
    //         { value: toNano('1') },
    //         {
    //             $$type: 'BurnUsdTONUserMessage',
    //             user: deployer.getSender().address,
    //             amount: stablesBorrowed,
    //         },
    //     );
    // //     const userDurovUsdcoinWalletAddress = await stable.getGetWalletAddress(deployer.getSender().address);
    // //     const userDurovUsdWallet = blockchain.openContract(await DurovUsdWallet.fromAddress(userDurovUsdcoinWalletAddress));
    // //     let userDurovUsdBalance = await userDurovUsdWallet.getGetBalance();

    // //     expect(userDurovUsdBalance).toEqual(stablesBorrowed);

    // //     const currentTotalSupply = await stable.getTotalSupply();
    // //     expect(currentTotalSupply).toEqual(stablesBorrowed);

    // //     // position updated
    // //     positionState = await userPositionContract.getPositionState();
    // //     expect(positionState.debt).toEqual(stablesBorrowed);

    // //     userDurovUsdBalance = await userDurovUsdWallet.getGetBalance();
    // //     console.log('balance before repay', userDurovUsdBalance);

    // //     // user pays stables back
    // //     await manager.send(
    // //         deployer.getSender(),
    // //         { value: toNano('1') },
    // //         {
    // //             $$type: 'BurnUsdTONUserMessage',
    // //             user: deployer.getSender().address,
    // //             amount: stablesBorrowed,
    // //         },
    // //     );

    // //     let positionMessage = await userPositionContract.getMessage();
    // //     console.log({ positionMessage });

    // //     userDurovUsdBalance = await userDurovUsdWallet.getGetBalance();
    // //     console.log('balance after repay', userDurovUsdBalance);

    // //     expect(userDurovUsdBalance).toEqual(0n);

    // //     positionState = await userPositionContract.getPositionState();
    // //     console.log({ positionState });
    // //     expect(positionState.debt).toEqual(0n);

    // // withdraw collateral

    // //     const collateralToWithdraw = toNano('0.5');

    // //     await manager.send(
    // //         deployer.getSender(),
    // //         { value: toNano('1') },
    // //         {
    // //             $$type: 'WithdrawCollateralUserMessage',
    // //             user: deployer.getSender().address,
    // //             amount: collateralToWithdraw,
    // //         },
    // //     );

    // //     positionState = await userPositionContract.getPositionState();
    // //     console.log({ positionState });
    // //     expect(positionState.collateral).toEqual(500000000n);

    //     // expect(positionState.collateral).toEqual(collateralSupplyAmount);

    // //     // -- user draw stables
    // //     const initialTotalSupply = await stable.getTotalSupply();

    // //     expect(initialTotalSupply).toEqual(0n);

    // //     const stablesBorrowed = toNano(2);

    // //     await manager.send(
    // //         deployer.getSender(),
    // //         { value: toNano(1) },
    // //         {
    // //             $$type: 'MintDurovUsdMessage',
    // //             user: deployer.getSender().address,
    // //             amount: stablesBorrowed,
    // //         },
    // //     );

    // //     const userDurovUsdcoinWalletAddress = await stable.getGetWalletAddress(deployer.getSender().address);
    // //     const userDurovUsdWallet = blockchain.openContract(await DurovUsdWallet.fromAddress(userDurovUsdcoinWalletAddress));
    // //     let userDurovUsdBalance = await userDurovUsdWallet.getGetBalance();

    // //     expect(userDurovUsdBalance).toEqual(stablesBorrowed);

    // //     const currentTotalSupply = await stable.getTotalSupply();
    // //     expect(currentTotalSupply).toEqual(stablesBorrowed);

    // //     // position updated
    // //     positionState = await userPositionContract.getPositionState();
    // //     expect(positionState.debt).toEqual(stablesBorrowed);

    // //     userDurovUsdBalance = await userDurovUsdWallet.getGetBalance();
    // //     console.log('balance before repay', userDurovUsdBalance);

    // //     // user pays stables back
    // //     await manager.send(
    // //         deployer.getSender(),
    // //         { value: toNano('1') },
    // //         {
    // //             $$type: 'BurnUsdTONUserMessage',
    // //             user: deployer.getSender().address,
    // //             amount: stablesBorrowed,
    // //         },
    // //     );

    // //     let positionMessage = await userPositionContract.getMessage();
    // //     console.log({ positionMessage });

    // //     userDurovUsdBalance = await userDurovUsdWallet.getGetBalance();
    // //     console.log('balance after repay', userDurovUsdBalance);

    // //     expect(userDurovUsdBalance).toEqual(0n);

    // //     positionState = await userPositionContract.getPositionState();
    // //     console.log({ positionState });
    // //     expect(positionState.debt).toEqual(0n);

    // //     // withdraw collateral

    // //     const collateralToWithdraw = toNano('0.5');

    // //     await manager.send(
    // //         deployer.getSender(),
    // //         { value: toNano('1') },
    // //         {
    // //             $$type: 'WithdrawCollateralUserMessage',
    // //             user: deployer.getSender().address,
    // //             amount: collateralToWithdraw,
    // //         },
    // //     );

    // //     positionState = await userPositionContract.getPositionState();
    // //     console.log({ positionState });
    // //     expect(positionState.collateral).toEqual(500000000n);
    // //     const message = await userPositionContract.getMessage();
    // //     console.log({ message });
    // });
});
