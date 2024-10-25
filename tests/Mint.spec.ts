import { Address, beginCell, toNano } from '@ton/core'
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox'
import '@ton/test-utils'
import { assetsv1, couponJettonParams, mintAmount, stableJettonParams } from '../utils/data'
import { buildOnchainMetadata } from '../utils/helpers'
import { Coupon } from '../wrappers/V1Coupon'
import { V1Manager } from '../wrappers/V1Manager'
import { V1ReservePool } from '../wrappers/V1Pool'
import { Stable } from '../wrappers/V1Stable'

import setup from './scripts/setup'
import { checkAssets, checkDeps, checkRates, checkSettings } from './test-helpers/setup-helpers'

describe('Mint', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let user: SandboxContract<TreasuryContract>;
    let reciever: SandboxContract<TreasuryContract>;
    let pool: SandboxContract<V1ReservePool>;
    let manager: SandboxContract<V1Manager>;
    let stable: SandboxContract<Stable>;
    let coupon: SandboxContract<Coupon>;

    beforeAll(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');
        user = await blockchain.treasury('user');

        manager = blockchain.openContract(
            await V1Manager.fromInit(
                deployer.getSender().address,
                Address.parse('UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ'),
            ),
        );
        pool = blockchain.openContract(await V1ReservePool.fromInit(deployer.getSender().address));
        stable = blockchain.openContract(
            await Stable.fromInit(deployer.getSender().address, buildOnchainMetadata(stableJettonParams)),
        );
        coupon = blockchain.openContract(
            await Coupon.fromInit(deployer.getSender().address, buildOnchainMetadata(couponJettonParams)),
        );
        let managerDeploy = await manager.send(
            deployer.getSender(),
            { value: toNano(0.3) },
            { $$type: 'Deploy', queryId: 0n },
        );
        expect(managerDeploy.transactions).toHaveTransaction({
            from: deployer.address,
            to: manager.address,
            deploy: true,
            success: true,
        });
        let poolDeploy = await pool.send(
            deployer.getSender(),
            { value: toNano(0.3) },
            { $$type: 'Deploy', queryId: 0n },
        );
        expect(poolDeploy.transactions).toHaveTransaction({
            from: deployer.address,
            to: pool.address,
            deploy: true,
            success: true,
        });
        let stableDeploy = await stable.send(
            deployer.getSender(),
            { value: toNano(0.3) },
            { $$type: 'Deploy', queryId: 0n },
        );
        expect(stableDeploy.transactions).toHaveTransaction({
            from: deployer.address,
            to: stable.address,
            deploy: true,
            success: true,
        });
        await setup({ deployer, manager, pool, stable, coupon });
    });
    /* ==setup== */
    it('should deploy contracts', async () => {
        await checkDeps({ manager, pool, stable, coupon });
    });
    it('should set dependencies', async () => {
        await checkDeps({ manager, pool, stable, coupon });
    });
    it('should set assets and balance templates', async () => {
        await checkAssets({ manager, pool, stable, coupon });
    });

    it('should set settings', async () => {
        await checkSettings({ manager });
    });
    it('should set rates', async () => {
        await checkRates({ manager, pool, stable, coupon });
    });

    /* ==actions== */
    it('should mint stable to user wallet and set debt in user position', async () => {
        const assetIndex = 0; // Не менять тк этот скрипт только для assetIndex = 0
        const orderId = '9d4bff8fa95b4b588c0658fc0b2a2b09';
        const tonAmount = '1';
        const mint = toNano(mintAmount);

        let assetBuilder = beginCell()
            .storeMaybeRef(
                beginCell()
                    .storeAddress(Address.parse(assetsv1[assetIndex].master))
                    .storeAddress(Address.parse('UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ'))
                    .storeInt(1n, 64)
                    .storeAddress(reciever.address)
                    .storeStringTail(orderId)
                    .endCell(),
            )
            .endCell()
            .asSlice();

        //supply
        await pool.send(
            user.getSender(),
            { value: toNano(3 + tonAmount) },
            {
                $$type: 'TokenNotification',
                queryId: 0n,
                amount: toNano(tonAmount),
                from: user.getSender().address!!,
                forwardPayload: assetBuilder,
            },
        );

        const mintResult = await manager.send(
            user.getSender(),
            { value: toNano(1) },
            {
                $$type: 'MintStableMessage',
                amount: mint,
            },
        );


        //TODO написать тест для проверки цепочки транзакций
        //TODO написать тест для проверки начисления стейбла пользователю
        //TODO написать тест для проверки записи задолженности
        //TODO написать тест для проверки расчета hr (предварительно добавь расчет hr)

    });
});
