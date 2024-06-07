import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';

import { buildOnchainMetadata } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { PositionAddressContract } from '../wrappers/PositionAddress';
import { StablecoinMaster } from '../wrappers/Stablecoin';
import { UserStablecoinWallet } from '../wrappers/StablecoinWallet';

import { UserPosition } from '../wrappers/UserPosition';

describe('Integration test', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let stablecoinWallet: SandboxContract<UserStablecoinWallet>;
    let stablecoinMaster: SandboxContract<StablecoinMaster>;
    let positionsManager: SandboxContract<Manager>;
    let poolContract: SandboxContract<Pool>;

    beforeAll(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        const jettonParams = {
            name: 'yt0.2',
            symbol: 'yt0.2',
            description: 'v0.2',
            image: '',
        };

        let stablecoinMaster = blockchain.openContract(
            await StablecoinMaster.fromInit(deployer.getSender().address, buildOnchainMetadata(jettonParams)),
        );
        let positionsManager = blockchain.openContract(await Manager.fromInit());
        let poolContract = blockchain.openContract(await Pool.fromInit());

        // deps
        const stablecoinSetDepsRes = await stablecoinMaster.send(
            deployer.getSender(),
            { value: toNano(0.1) },
            {
                $$type: 'SetDeps',
                positionsManagerAddress: positionsManager.address,
                poolAddress: poolContract.address,
                stablecoinMasterAddress: stablecoinMaster.address,
            },
        );

        expect(stablecoinSetDepsRes.transactions).toHaveTransaction({
            from: deployer.address,
            to: stablecoinMaster.address,
            deploy: true,
            success: true,
        });

        const managerSetDepsRes = await positionsManager.send(
            deployer.getSender(),
            { value: toNano(0.1) },
            {
                $$type: 'SetDeps',
                positionsManagerAddress: positionsManager.address,
                poolAddress: poolContract.address,
                stablecoinMasterAddress: stablecoinMaster.address,
            },
        );
        expect(managerSetDepsRes.transactions).toHaveTransaction({
            from: deployer.address,
            to: positionsManager.address,
            deploy: true,
            success: true,
        });

        const poolSetDepsRes = await poolContract.send(
            deployer.getSender(),
            { value: toNano(0.1) },
            {
                $$type: 'SetDeps',
                positionsManagerAddress: positionsManager.address,
                poolAddress: poolContract.address,
                stablecoinMasterAddress: stablecoinMaster.address,
            },
        );
        expect(poolSetDepsRes.transactions).toHaveTransaction({
            from: deployer.address,
            to: poolContract.address,
            deploy: true,
            success: true,
        });

        // initial pool settings
        const poolSetting = await poolContract.send(
            deployer.getSender(),
            { value: toNano(1) },
            {
                $$type: 'PoolSettingsMsg',
                liquidationRatio: 1200000000n,
                stabilityFeeRate: 1000000000625n,
                liquidatorIncentiveBps: 10500n,
            },
        );
        expect(poolSetting.transactions).toHaveTransaction({
            from: deployer.address,
            to: poolContract.address,
            deploy: true,
            success: true,
        });

        // initial ton price
        const poolPrice = await poolContract.send(
            deployer.getSender(),
            { value: toNano(1) },
            {
                $$type: 'UpdateTonPriceMsg',
                price: 3200000000n,
            },
        );
        expect(poolPrice.transactions).toHaveTransaction({
            from: deployer.address,
            to: poolContract.address,
            deploy: true,
            success: true,
        });
    });

    it('deps set ok', async () => {
        const stablecoinDeps = await stablecoinMaster.getDeps();
        expect(stablecoinDeps.poolAddress.toString()).toEqual(poolContract.address.toString());
        expect(stablecoinDeps.positionsManagerAddress.toString()).toEqual(positionsManager.address.toString());

        const positionsManagerDeps = await positionsManager.getDeps();
        expect(positionsManagerDeps.poolAddress.toString()).toEqual(poolContract.address.toString());
        expect(positionsManagerDeps.stablecoinMasterAddress.toString()).toEqual(stablecoinMaster.address.toString());

        const poolDeps = await poolContract.getDeps();
        expect(poolDeps.stablecoinMasterAddress.toString()).toEqual(stablecoinMaster.address.toString());
        expect(poolDeps.positionsManagerAddress.toString()).toEqual(positionsManager.address.toString());
    });

    it('pool settings set ok', async () => {
        const poolSettings = await poolContract.getPoolSettings();
        expect(poolSettings.liquidationRatio).toEqual(1200000000n);
        expect(poolSettings.liquidatorIncentiveBps).toEqual(10500n);
        expect(poolSettings.stabilityFeeRate).toEqual(1000000000625n);
    });

    it('initial price set ok', async () => {
        const tonPrice = await poolContract.getTonPrice();
        expect(tonPrice).toEqual(3200000000n);

        const tonPriceWithSafetyMargin = await poolContract.getTonPriceWithSafetyMargin();
        expect(tonPriceWithSafetyMargin).toEqual(2666666666n);
    });

    it('user actions flow', async () => {
        const collateralDepositAmount = toNano(1);
        const currentPositionId = await positionsManager.getLastPositionId();

        await poolContract.send(
            deployer.getSender(),
            { value: collateralDepositAmount + toNano(1) },
            {
                $$type: 'DepositCollateralUserMessage',
                user: deployer.getSender().address,
                amount: collateralDepositAmount,
            },
        );

        const lastPositionId = await positionsManager.getLastPositionId();
        expect(lastPositionId - currentPositionId).toEqual(1n);

        // positionsManager has address of userPositionAddress for new position
        const userPositionAddressContractAddress = await positionsManager.getUserPositionAddressById(lastPositionId);
        expect(userPositionAddressContractAddress).toBeDefined();

        // userPositionAdress stores userPosition contract address
        const userPositionAddressContract = blockchain.openContract(
            await PositionAddressContract.fromAddress(userPositionAddressContractAddress),
        );
        const userPositionContractAddress = await userPositionAddressContract.getPositionAddress();

        // positionsManager know userPositionAddress by user.address
        const positionAddress = await positionsManager.getUserPositionAddress(deployer.getSender().address);
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

        await poolContract.send(
            deployer.getSender(),
            { value: toNano(1) },
            {
                $$type: 'WithdrawStablecoinUserMessage',
                user: deployer.getSender().address,
                amount: stablesBorrowed,
            },
        );

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
        await poolContract.send(
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

        await poolContract.send(
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
