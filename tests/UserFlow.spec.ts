import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { buildOnchainMetadata } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { PositionAddressContract } from '../wrappers/PositionAddress';
import { StablecoinMaster } from '../wrappers/Stablecoin';
import { UserStablecoinWallet } from '../wrappers/StablecoinWallet';
import { UserPosition } from '../wrappers/UserPosition';

describe('UserFlow', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let pool: SandboxContract<Pool>;
    let stablecoinMaster: SandboxContract<StablecoinMaster>;
    let manager: SandboxContract<Manager>;

    beforeAll(async () => {
        const jettonParams = {
            name: 'yt0.2',
            symbol: 'yt0.2',
            description: 'v0.2',
            image: '',
        };

        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        stablecoinMaster = blockchain.openContract(
            await StablecoinMaster.fromInit(deployer.getSender().address, buildOnchainMetadata(jettonParams)),
        );
        pool = blockchain.openContract(await Pool.fromInit(deployer.getSender().address));
        manager = blockchain.openContract(await Manager.fromInit(deployer.getSender().address));

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

        await pool.send(
            deployer.getSender(),
            { value: toNano(0.1) },
            {
                $$type: 'SetDeps',
                positionsManagerAddress: manager.address,
                poolAddress: pool.address,
                stablecoinMasterAddress: stablecoinMaster.address,
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
                positionsManagerAddress: manager.address,
                poolAddress: pool.address,
                stablecoinMasterAddress: stablecoinMaster.address,
            },
        );

        const deployStablecoin = await stablecoinMaster.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        expect(deployStablecoin.transactions).toHaveTransaction({
            from: deployer.address,
            to: stablecoinMaster.address,
            deploy: true,
            success: true,
        });

        await stablecoinMaster.send(
            deployer.getSender(),
            { value: toNano(0.1) },
            {
                $$type: 'SetDeps',
                positionsManagerAddress: manager.address,
                poolAddress: pool.address,
                stablecoinMasterAddress: stablecoinMaster.address,
            },
        );

        await pool.send(
            deployer.getSender(),
            { value: toNano(1) },
            {
                $$type: 'PoolSettingsMsg',
                liquidationRatio: toNano(1.2),
                stabilityFeeRate: 1000000000625n,
                liquidatorIncentiveBps: toNano(1.05),
            },
        );

        await pool.send(
            deployer.getSender(),
            { value: toNano(1) },
            {
                $$type: 'UpdateTonPriceMsg',
                price: toNano(7),
            },
        );
    });
    it('deps set ok', async () => {
        const stablecoinDeps = await stablecoinMaster.getDeps();
        expect(stablecoinDeps.poolAddress.toString()).toEqual(pool.address.toString());
        expect(stablecoinDeps.positionsManagerAddress.toString()).toEqual(manager.address.toString());

        const positionsManagerDeps = await manager.getDeps();
        expect(positionsManagerDeps.poolAddress.toString()).toEqual(pool.address.toString());
        expect(positionsManagerDeps.stablecoinMasterAddress.toString()).toEqual(stablecoinMaster.address.toString());

        const poolDeps = await pool.getDeps();
        expect(poolDeps.stablecoinMasterAddress.toString()).toEqual(stablecoinMaster.address.toString());
        expect(poolDeps.positionsManagerAddress.toString()).toEqual(manager.address.toString());
    });

    it('pool settings set ok', async () => {
        const poolSettings = await pool.getPoolSettings();
        expect(poolSettings.liquidationRatio).toEqual(toNano(1.2));
        expect(poolSettings.liquidatorIncentiveBps).toEqual(toNano(1.05));
        expect(poolSettings.stabilityFeeRate).toEqual(1000000000625n);
    });

    it('initial price set ok', async () => {
        const tonPrice = await pool.getTonPrice();
        expect(tonPrice).toEqual(toNano(3.5));
        const tonPriceWithSafetyMargin = await pool.getTonPriceWithSafetyMargin();
        expect(tonPriceWithSafetyMargin).toEqual(2916666666n);
        ///???
    });

    it('user actions flow', async () => {
        const collateralDepositAmount = toNano(1);
        const currentPositionId = await manager.getLastPositionId();

        await pool.send(
            deployer.getSender(),
            { value: collateralDepositAmount + toNano(1) },
            {
                $$type: 'DepositCollateralUserMessage',
                user: deployer.getSender().address,
                amount: collateralDepositAmount,
            },
        );

        const lastPositionId = await manager.getLastPositionId();
        expect(lastPositionId - currentPositionId).toEqual(1n);

        // manager has address of userPositionAddress for new position
        const userPositionAddressContractAddress = await manager.getUserPositionAddressById(lastPositionId);
        expect(userPositionAddressContractAddress).toBeDefined();

        // userPositionAdress stores userPosition contract address
        const userPositionAddressContract = blockchain.openContract(
            await PositionAddressContract.fromAddress(userPositionAddressContractAddress),
        );
        const userPositionContractAddress = await userPositionAddressContract.getPositionAddress();

        // manager know userPositionAddress by user.address
        const positionAddress = await manager.getUserPositionAddress(deployer.getSender().address);
        expect(positionAddress.toString()).toEqual(userPositionContractAddress.toString());

        // userPosition contract has a state with deposited collateral stored
        const userPositionContract = blockchain.openContract(
            await UserPosition.fromAddress(userPositionContractAddress),
        );
        let positionState = await userPositionContract.getPositionState();

        expect(positionState.collateral).toEqual(collateralDepositAmount);

        // -- user draw stablecoins
        const initialTotalSupply = await stablecoinMaster.getTotalSupply();

        expect(initialTotalSupply).toEqual(0n);

        const stablesBorrowed = toNano(1);

        await pool.send(
            deployer.getSender(),
            { value: toNano(1) },
            {
                $$type: 'WithdrawStablecoinUserMessage',
                user: deployer.getSender().address,
                amount: stablesBorrowed,
            },
        );

        // TODO понять почему так не работает////////////////////////////////////////////////////////////////////////
        // const userStablecoinWalletAddress = await stablecoinMaster.getGetWalletAddress(deployer.getSender().address);
        // const userStableWallet = blockchain.openContract(
        //     await UserStablecoinWallet.fromInit(stablecoinMaster.address, deployer.getSender().address),
        // );
        // let userStableBalance = await userStableWallet.getGetBalance();
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////

        const userStablecoinWalletAddress = await stablecoinMaster.getGetWalletAddress(deployer.getSender().address);
        const userStableWallet = blockchain.openContract(
            await UserStablecoinWallet.fromAddress(userStablecoinWalletAddress),
        );
        let userStableBalance = await userStableWallet.getGetBalance();

        expect(userStableBalance).toEqual(stablesBorrowed);

        const currentTotalSupply = await stablecoinMaster.getTotalSupply();
        expect(currentTotalSupply).toEqual(stablesBorrowed);

        // position updated
        positionState = await userPositionContract.getPositionState();
        expect(positionState.debt).toEqual(stablesBorrowed);

        userStableBalance = await userStableWallet.getGetBalance();
        console.log('balance before repay', userStableBalance);

        // user pays stables back
        await pool.send(
            deployer.getSender(),
            { value: toNano('1') },
            {
                $$type: 'RepayStablecoinUserMessage',
                user: deployer.getSender().address,
                amount: stablesBorrowed,
            },
        );

        let positionMessage = await userPositionContract.getMessage();
        console.log({ positionMessage });

        userStableBalance = await userStableWallet.getGetBalance();
        console.log('balance after repay', userStableBalance);

        expect(userStableBalance).toEqual(0n);

        positionState = await userPositionContract.getPositionState();
        console.log({ positionState });
        expect(positionState.debt).toEqual(0n);

        // withdraw collateral

        const collateralToWithdraw = toNano('0.5');

        await pool.send(
            deployer.getSender(),
            { value: toNano('1') },
            {
                $$type: 'WithdrawCollateralUserMessage',
                user: deployer.getSender().address,
                amount: collateralToWithdraw,
            },
        );

        positionState = await userPositionContract.getPositionState();
        console.log({ positionState });
        expect(positionState.collateral).toEqual(500000000n);

        const message = await userPositionContract.getMessage();
        console.log({ message });
    });
});
