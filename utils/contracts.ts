import { NetworkProvider } from '@ton/blueprint';
import { Address } from '@ton/core';

import { Manager } from '../wrappers/Manager';
import { ReservePool } from '../wrappers/ReservePool';
import { UserPosition } from '../wrappers/UP';
import { V1Manager } from '../wrappers/V1Manager';
import { V1ReservePool } from '../wrappers/V1Pool';

import { Stable } from '../wrappers/V1Stable';
import { V1UserPosition } from '../wrappers/V1UP';
import { loadAddress } from './helpers';

async function contracts(provider: NetworkProvider, user: Address) {

        const reservePool = provider.open(process.env.v == '0' ?  ReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))) :  V1ReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))))
        const manager = provider.open(process.env.v == '0' ?  Manager.fromAddress(Address.parse(await loadAddress('manager'))) : V1Manager.fromAddress(Address.parse(await loadAddress('manager'))))
        const v1manager = provider.open(V1Manager.fromAddress(Address.parse(await loadAddress('manager'))))
        const stable =  provider.open(Stable.fromAddress(Address.parse(await loadAddress('stable'))))
        const userPositionAddress = await manager.getUserPositionAddress(user)
        const userPosition = provider.open(process.env.v == '0' ?  UserPosition.fromAddress(userPositionAddress) : V1UserPosition.fromAddress(userPositionAddress))
        const v1userPosition = provider.open(V1UserPosition.fromAddress(userPositionAddress))

        return {
                reservePool,
                manager,
                stable,
                userPosition,
                v1manager,
                v1userPosition
        }
}

export default contracts