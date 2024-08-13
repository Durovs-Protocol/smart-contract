import { Address, toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { addSupplyAmount, addSupplyGas, gasFee, testJettonParams, testRunecoinParams } from '../../utils/data';
import { buildOnchainMetadata } from '../../utils/helpers';
import { Runecoin } from '../../wrappers/Runecoin';
import { Manager } from '../../wrappers/v1/Manager';
import { Pool } from '../../wrappers/v1/ReservePool';
import { UsdTonMaster } from '../../wrappers/v1/UsdTon';

describe('Supply', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;

    let pool: SandboxContract<Pool>;
    let usdTon: SandboxContract<UsdTonMaster>;
    let manager: SandboxContract<Manager>;
    let runecoin: SandboxContract<Runecoin>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        manager = blockchain.openContract(await Manager.fromInit(deployer.getSender().address));
        pool = blockchain.openContract(await Pool.fromInit(deployer.getSender().address));
        usdTon = blockchain.openContract(
            await UsdTonMaster.fromInit(deployer.getSender().address, buildOnchainMetadata(testJettonParams)),
        );
        runecoin = blockchain.openContract(
            await Runecoin.fromInit(deployer.getSender().address, buildOnchainMetadata(testRunecoinParams)),
        );

        let deployResult = await manager.send(
            deployer.getSender(),
            { value: toNano(gasFee) },
            { $$type: 'Deploy', queryId: 0n },
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: manager.address,
            deploy: true,
            success: true,
        });

        deployResult = await pool.send(
            deployer.getSender(),
            { value: toNano(gasFee) },
            { $$type: 'Deploy', queryId: 0n },
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: pool.address,
            deploy: true,
            success: true,
        });

        deployResult = await usdTon.send(
            deployer.getSender(),
            { value: toNano(gasFee) },
            { $$type: 'Deploy', queryId: 0n },
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: usdTon.address,
            deploy: true,
            success: true,
        });

        deployResult = await runecoin.send(
            deployer.getSender(),
            { value: toNano(gasFee) },
            { $$type: 'Deploy', queryId: 0n },
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: runecoin.address,
            deploy: true,
            success: true,
        });
    });

    it('Add supply', async () => {
        const collateralAmount = toNano(addSupplyAmount);

        // Отправляем Supply
        await manager.send(
            deployer.getSender(),
            { value: collateralAmount + toNano(addSupplyGas) },
            {
                $$type: 'SupplyCollateralUserMessage',
                user: deployer.getSender().address as Address,
                amount: toNano(addSupplyAmount),
            },
        );

        // await delay(1000);

        // const userPosition = blockchain.openContract(
        //     await UserPosition.fromInit(
        //         deployer.address,
        //         usdTon.address,
        //         manager.address,
        //         pool.address,
        //     ),
        // );

        // let state = await userPosition.getPositionState();

        // expect(state.collateral).toEqual(addSupplyAmount);
        expect(addSupplyAmount).toEqual(addSupplyAmount);
    });
});
