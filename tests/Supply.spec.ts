import { Address, beginCell, fromNano, toNano } from '@ton/core'
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox'
import '@ton/test-utils'
import { assetsv1, couponJettonParams, stableJettonParams } from '../utils/data'
import { buildOnchainMetadata } from '../utils/helpers'
import { Coupon } from '../wrappers/V1Coupon'
import { V1Manager } from '../wrappers/V1Manager'
import { V1ReservePool } from '../wrappers/V1Pool'
import { Stable } from '../wrappers/V1Stable'
import { V1UserPosition } from '../wrappers/V1UP'

import { findTransaction, flattenTransaction } from '@ton/test-utils'
import setup from './scripts/setup'
import { addressByIndex, checkAssets, checkDeps, checkRates, checkSettings } from './test-helpers/setup-helpers'

describe('Supply', () => {
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
    it('should hold ton in treasury, create user position, increese last position id, change user position balance', async () => {
        const assetIndex = 0; // Не менять тк этот скрипт только для assetIndex = 0
        const orderId = '9d4bff8fa95b4b588c0658fc0b2a2b09'
        const tonAmount = "1"

        // TODO добавить проверку создания pk
        
        //state before message
        const lastPositionId = await manager.getLastPositionId()
        const poolBalanceBeforeSupply = await pool.getBalance()

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

        // запрос к up пользователя, проверка увеличения id
        const userPosition = await manager.getUserPositionAddress(user.getSender().address!!);
        expect(paymentResult.transactions).toHaveTransaction({
            from: manager.address,
            to: userPosition,
            success: true,
        });

        const positionIdAfterFirstSupply = await manager.getLastPositionId()
        expect(positionIdAfterFirstSupply).toEqual(lastPositionId + 1n)

        // проверка записи баланса пользователя
        const userPositionContract = blockchain.openContract(V1UserPosition.fromAddress(userPosition));
        const userBalance = await userPositionContract.getBalances()
        expect(fromNano(userBalance.get(addressByIndex(0))!!)).toEqual(tonAmount)

        // проверка баланса хранилища
        const poolBalanceAfterSupply = await pool.getBalance()
        expect(poolBalanceAfterSupply).toBeGreaterThanOrEqual(toNano(Number(poolBalanceBeforeSupply) + Number(tonAmount)))
    });
    // TODO нужно найти способ как проверять баланс токенов пользователя и отправлять сообщения на его кошелек
    //TODO подумать как сделать этот тест учитывая что необходимо иметь внутри него разврнутый контракт жетона
    // it('should hold jetton in treasury, change user position balance', async () => {
    //     const paymentAmount = 1;
    //     const assetIndex = 1; // Не менять тк этот скрипт только для assetIndex = 0
    //     const orderId = '9d4bff8fa95b4b588c0658fc0b2a2b09'
    //     const jettonAmount = "1"
    //     const debtAmount = "1"

    //     //state before message
    //     // const poolBalanceBeforeSupply = await pool.getBalance()

    //     const masterInterface = JettonMaster.create(Address.parse(assetsv1[assetIndex].master!!));

    //     const master = await blockchain.openContract(masterInterface);
    //     const jettonUserWallet = await master.getWalletAddress(user.address!!);


    //     let assetBuilder = beginCell()
    //                 .storeAddress(Address.parse(assetsv1[assetIndex].master))
    //                 .storeAddress(jettonUserWallet)
    //                 .storeInt(2n, 64)
    //                 .endCell()

    //     const body = beginCell()
    //         .storeUint(0xf8a7ea5, 32)
    //         .storeUint(0, 64)
    //         .storeCoins(toNano(jettonAmount)) // Сумма
    //         .storeAddress(pool.address) // Кто получит jetton
    //         .storeAddress(user.address) // Остаток газа
    //         .storeUint(0, 1)
    //         .storeCoins(300000000)
    //         .storeMaybeRef(assetBuilder)
    //         .endCell();

    //     // let balanceAfterSupply = toNano(oldBalance) + toNano(supplyAmount);

    //     const paymentResult = await  user.send({
    //         value: 1n,
    //         to: jettonUserWallet,
    //         body: body,
    //     })

    //     // перевод в pool c jetton wallet пользователя
    //     expect(paymentResult.transactions).toHaveTransaction({
    //         from: user.address,
    //         to: jettonUserWallet,
    //         success: true,
    //     });

    //     // запрос из pool к manager
    //     expect(paymentResult.transactions).toHaveTransaction({
    //         from: pool.address,
    //         to: manager.address,
    //         success: true,
    //     });

    //     // запрос к up пользователя
    //     const userPosition = await manager.getUserPositionAddress(user.getSender().address!!);
    //     expect(paymentResult.transactions).toHaveTransaction({
    //         from: manager.address,
    //         to: userPosition,
    //         success: true,
    //     });

    //     // проверка записи баланса пользователя
    //     const userPositionContract = blockchain.openContract(V1UserPosition.fromAddress(userPosition));
    //     const userBalance = await userPositionContract.getBalances()
    //     expect(fromNano(userBalance.get(addressByIndex(assetIndex))!!)).toEqual(jettonAmount)

    //     // проверка баланса хранилища
    //     // TODO добавить эту проверку
    // });

    it('should check user balance before withdrawal', async () => {
        const withdrawAmount = 2;
        const assetIndex = 0; // Не менять тк этот скрипт только для assetIndex = 0
        const tonAmount = "1"

        const withdrawalResult = await manager.send(
            user.getSender(),
            { value: toNano(1) },
            {
                $$type: 'WithdrawMessage',
                amount: toNano(withdrawAmount),
                master: Address.parse(assetsv1[assetIndex].master)

            },
        );

        expect(withdrawalResult.transactions).toHaveTransaction({
            from: user.address,
            to: manager.address,
            success: true,
        });

        const userPosition = await manager.getUserPositionAddress(user.getSender().address!!);
        // запрос из manager к userPosition
        expect(withdrawalResult.transactions).toHaveTransaction({
            from: manager.address,
            to: userPosition,
            success: true,
        });

        // отправка сообщения об отказе в связи с нехваткой средств пользователю
        expect(withdrawalResult.transactions).toHaveTransaction({
            from: userPosition,
            to: user.address,
            success: true,
        });
        // транзакция с комментарием об отказе возврата
        const comment = findTransaction(withdrawalResult.transactions, {
            from: userPosition,
            to: user.address,
            success: true,
        })
        // проверка комментария
        const textComment = flattenTransaction(comment!!).body!!.beginParse().loadStringTail().toString()
        expect(textComment).toMatch("Durovs Protocol: Not enough funds to withdraw")
    })

    it('should return ton to user, decrease balance', async () => {
        const withdrawAmount = 1;
        const assetIndex = 0;

        const userPosition = await manager.getUserPositionAddress(user.getSender().address!!);
        const userPositionContract = blockchain.openContract(V1UserPosition.fromAddress(userPosition));

        const balanceBeforeWithdrawal = Number(fromNano((await userPositionContract.getBalances()).get(addressByIndex(0))!!))

        const withdrawalResult = await manager.send(
            user.getSender(),
            { value: toNano(1) },
            {
                $$type: 'WithdrawMessage',
                amount: toNano(withdrawAmount),
                master: Address.parse(assetsv1[assetIndex].master)
            },
        );

        expect(withdrawalResult.transactions).toHaveTransaction({
            from: user.address,
            to: manager.address,
            success: true,
        });


        // запрос из manager к userPosition
        expect(withdrawalResult.transactions).toHaveTransaction({
            from: manager.address,
            to: userPosition,
            success: true,
        });
        // запрос из userPosition к pool
        expect(withdrawalResult.transactions).toHaveTransaction({
            from: manager.address,
            to: userPosition,
            success: true,
        });
        // проверка изменения баланса пользователя
        const userBalance = fromNano((await userPositionContract.getBalances()).get(addressByIndex(0))!!)
        expect(Number(userBalance)).toEqual(balanceBeforeWithdrawal - withdrawAmount)

        // проверка баланса хранилища
        const poolBalanceAfterWithdraw = await pool.getBalance()
        expect(Number(fromNano(poolBalanceAfterWithdraw - BigInt(withdrawAmount)))).toBeCloseTo(Number(fromNano(poolBalanceAfterWithdraw)), 2)
    })
    it('should return token to user, decrease balance', async () => {
        // TODO нужно найти способ как проверять баланс токенов пользователя и отправлять сообщения на его
    })
});
