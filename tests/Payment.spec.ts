import { Address, beginCell, fromNano, toNano } from '@ton/core'
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox'
import '@ton/test-utils'
import { findTransaction, flattenTransaction } from '@ton/test-utils'
import { assetsv1, couponJettonParams, stableJettonParams } from '../utils/data'
import { buildOnchainMetadata } from '../utils/helpers'
import { Coupon } from '../wrappers/V1Coupon'
import { V1Manager } from '../wrappers/V1Manager'
import { V1ReservePool } from '../wrappers/V1Pool'
import { Stable } from '../wrappers/V1Stable'
import { StableWallet } from '../wrappers/V1StableWallet'
import { V1UserPosition } from '../wrappers/V1UP'

import setup from './scripts/setup'
import { checkAssets, checkDeps, checkRates, checkSettings } from './test-helpers/setup-helpers'

describe('Payment', () => {
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
        reciever = await blockchain.treasury('reciever');
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

        let poolDeploy = await pool.send(deployer.getSender(), { value: toNano(0.3) }, { $$type: 'Deploy', queryId: 0n });

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
        await checkDeps({ manager, pool, stable, coupon })
    })
    it('should set dependencies', async () => {
        await checkDeps({ manager, pool, stable, coupon })
    })
    it('should set assets and balance templates', async () => {
        await checkAssets({ manager, pool, stable, coupon })
    })

    it('should set settings', async () => {
        await checkSettings({ manager})
    })
    it('should set rates', async () => {
        await checkRates({ manager, pool, stable, coupon })
    })

    /* ==actions== */
    it('should hold ton, transfer tokens and add debt to user', async () => {
        const assetIndex = 0; // Не менять тк этот скрипт только для assetIndex = 0
        const orderId = '9d4bff8fa95b4b588c0658fc0b2a2b09'
        const tonAmount = 1
        const debtAmount = "1"
        const poolBalanceBeforePayment = await pool.getBalance()

        let assetBuilder = beginCell()
            .storeMaybeRef(
                beginCell()
                    .storeAddress(Address.parse(assetsv1[assetIndex].master))
                    .storeAddress(Address.parse('UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ'))
                    .storeInt(3n, 64)
                    .storeAddress(reciever.address)
                    .storeStringTail(orderId)
                    .endCell(),
            )
            .endCell()
            .asSlice();

        const paymentResult = await pool.send(
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

        // перевод в pool
        expect(paymentResult.transactions).toHaveTransaction({
            from: user.address,
            to: pool.address,
            success: true,
        });

        // запрос из pool к manager
        expect(paymentResult.transactions).toHaveTransaction({
            from: pool.address,
            to: manager.address,
            success: true,
        });

        // запрос к up пользователя
        const userPosition = await manager.getUserPositionAddress(user.getSender().address!!);
        expect(paymentResult.transactions).toHaveTransaction({
            from: manager.address,
            to: userPosition,
            success: true,
        });

        // запрос из up пользователя к stable master
        expect(paymentResult.transactions).toHaveTransaction({
            from: userPosition,
            to: stable.address,
            success: true,
        });

        const walletAddress = await stable.getGetWalletAddress(reciever.address);
        const userDurovUsdWallet = blockchain.openContract(StableWallet.fromAddress(walletAddress));


        // запрос из up пользователя к stable master
        expect(paymentResult.transactions).toHaveTransaction({
            from: stable.address,
            to: walletAddress,
            success: true

        });
        // запрос из кошелька reciever к up чтобы записать долг на пользователя
        expect(paymentResult.transactions).toHaveTransaction({
            from: walletAddress,
            to: userPosition,
            success: true

        });

        // транзакция с order id
        const commentForReciever = findTransaction(paymentResult.transactions, {
            from: walletAddress,
            to: reciever.address,
        })
        // проверка комментария
        const commentText = flattenTransaction(commentForReciever!!).body!!.beginParse().loadStringTail().toString()
        expect(commentText).toMatch(orderId)
        
        // задолженность
        const userPositionContract = blockchain.openContract(V1UserPosition.fromAddress(userPosition));
        const userDebt = await userPositionContract.getDebt()
        expect(debtAmount).toEqual(fromNano(userDebt))
        // кошелек конечного получателя
        const recieverBalance =  await userDurovUsdWallet.getGetBalance()
        expect(fromNano(recieverBalance)).toEqual(debtAmount)

        // проверка баланса хранилища
        const poolBalanceAfterPayment = await pool.getBalance()
        expect(poolBalanceAfterPayment).toBeGreaterThanOrEqual(toNano(Number(poolBalanceBeforePayment) + Number(tonAmount)))
        // prettyLogTransactions(paymentResult.transactions);
        //toFlatTransaction
    });

    it('should hold jetton, transfer tokens and add debt to user', async () => {
       // TODO нужно найти способ как проверять баланс токенов пользователя и отправлять сообщения на его кошелек
    })

});
