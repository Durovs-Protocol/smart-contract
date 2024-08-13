import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano, toNano } from '@ton/core';
import { loadAddress, log, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();

    const userPositionAddress = await manager.getUserPositionAddress(Address.parse(process.env.USER_WALLET_ADDRESS!));
    const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));

    const getMessage = async function () {
        const message = await userPosition.getMessage();
        return message.message;
    };

    console.log('Supply for liquidate', fromNano(await usdTon.getTotalSupply()));

    let positionMessage = await getMessage();

    log('Ликвидация позиции пользователя | ' + positionMessage);

    await manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'CorrectRate',
            user: Address.parse(process.env.USER_WALLET_ADDRESS!),
        },
    );

    await timer('Ликвидация позиции', 'position liquidated', getMessage, true);
}
