import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/PoolContract';
import { PositionAddressContract } from '../wrappers/PositionAddress';
import { StablecoinMaster } from '../wrappers/Stablecoin';
import { UserStablecoinWallet } from '../wrappers/StablecoinWallet';
import { UserPositionContract } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const stablecoin = provider.open(
        await StablecoinMaster.fromAddress(Address.parse(await loadAddress('stablecoin'))),
    );
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));

    const user = provider.sender();

    console.log(
        '01 | Пользователь вносит залог , создается контракт пользовательской позиции--------------------------------',
    );

    const collateralAmount = toNano(1);
    const currentPositionId = await manager.getLastPositionId();

    await poolContract.send(
        user,
        { value: collateralAmount + toNano(0.5) },
        {
            $$type: 'DepositCollateralUserMessage',
            user: user.address as Address,
            amount: collateralAmount,
        },
    );

    await timer(`Id последней зарегистрированной позиции:`, currentPositionId, manager.getLastPositionId);
    const lastPositionId = await manager.getLastPositionId();

    const positionAddressContractAddress = await manager.getUserPositionAddressById(lastPositionId);
    console.log('Адрес контракта хранящего адрес позиции пользователя:', positionAddressContractAddress);
    const positionAddressContract = provider.open(
        await PositionAddressContract.fromAddress(positionAddressContractAddress),
    );

    let userPossitionAddress = await positionAddressContract.getPositionAddress();
    console.log('Адрес контракта позиции пользователя', userPossitionAddress);

    const userPositionContract = provider.open(await UserPositionContract.fromAddress(userPossitionAddress));
    const state = await userPositionContract.getPositionState();
    console.log('State пользователя', state);

    console.log('02 | Пользователь берет stablecoin в займ--------------------------------');
    const stablesBorrowed = toNano(1);
    const userStablecoinWalletAddress = await stablecoin.getGetWalletAddress(user.address as Address);
    console.log('Адрес пользовательского кошелька stablecoin:', userStablecoinWalletAddress);
    const userStableWallet = provider.open(await UserStablecoinWallet.fromAddress(userStablecoinWalletAddress));

    const userStableBalance = await userStableWallet.getGetBalance();
    console.log(userStableBalance);

    await poolContract.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'WithdrawStablecoinUserMessage',
            user: user.address as Address,
            amount: stablesBorrowed,
        },
    );

    await timer(`Баланс stablecoin при оформлении займа:`, userStableBalance, userStableWallet.getGetBalance);

    console.log('03 | Пользователь возвращает stablecoin--------------------------------');

    await poolContract.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'RepayStablecoinUserMessage',
            user: user.address as Address,
            amount: stablesBorrowed,
        },
    );

    let userStableBalanceAfterRepay = await userStableWallet.getGetBalance();
    await timer(
        `Баланс stablecoin при погашении задолжности:`,
        userStableBalanceAfterRepay,
        userStableWallet.getGetBalance,
    );

    console.log('04 | Возврат залога--------------------------------');

    const collateralToWithdraw = toNano('2');

    const userCollateral = async function () {
        const state = await userPositionContract.getPositionState();
        console.log(state);
        return state.collateral;
    };
    const collateralBeforeWithdraw = await userCollateral();

    await poolContract.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'WithdrawCollateralUserMessage',
            user: user.address as Address,
            amount: collateralToWithdraw,
        },
    );

    await timer('Баланс пользователя при возврате залога', collateralBeforeWithdraw, userCollateral);
}
