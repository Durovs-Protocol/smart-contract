import { NetworkProvider } from '@ton/blueprint';
import { Address } from '@ton/core';
import { ProfitPool } from '../wrappers/ProfitPool';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { Manager } from '../wrappers/V0.Manager';
import { NewManager } from '../wrappers/V0.NewManager';
import { NewReservePool } from '../wrappers/V0.NewPool';
import { NewUp } from '../wrappers/V0.NewUp';
import { ReservePool } from '../wrappers/V0.ReservePool';
import { UserPosition } from '../wrappers/V0.UserPosition';
import { loadAddress } from './helpers';

async function contracts(provider: NetworkProvider, user: Address) {

        const reservePool = provider.open(process.env.v == '0' ?  ReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))) :  NewReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))))
        const manager = provider.open(process.env.v == '0' ?  Manager.fromAddress(Address.parse(await loadAddress('manager'))) : NewManager.fromAddress(Address.parse(await loadAddress('manager'))))
        const runaUsd =  provider.open(UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))))
        const profitPool =  provider.open(ProfitPool.fromAddress(Address.parse(await loadAddress('profitPool'))))
        const userPositionAddress = await manager.getUserPositionAddress(user)
        const userPosition = provider.open(process.env.v == '0' ?  UserPosition.fromAddress(userPositionAddress) : NewUp.fromAddress(userPositionAddress))

        return {
                reservePool,
                manager,
                runaUsd,
                profitPool,
                userPosition
        }
}

export default contracts