
import { NetworkProvider } from '@ton/blueprint';
import { Address, beginCell, toNano } from '@ton/core';
import { assets } from '../utils/data';
import { getBalanceValue, loadAddress, timer } from '../utils/helpers';

import { Manager } from '../wrappers/V0.Manager';
import { ReservePool } from '../wrappers/V0.ReservePool';
import { UserPosition } from '../wrappers/V0.UserPosition';
export async function run(provider: NetworkProvider) {


const user = provider.sender();
const supplyAmount = 1;
const assetIndex = 3

let assetBuilder = beginCell().storeMaybeRef(beginCell().storeAddress(Address.parse(assets[assetIndex].master)).storeInt(1n, 64).endCell()).endCell().asSlice()

const reservePool = provider.open(await ReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))));
const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
const userPositionAddress = await manager.getUserPositionAddress(user.address!!);
const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));

let oldBalance = 0n
let positionId = await manager.getLastPositionId()

if (positionId != 0n) {
    oldBalance =  await (await getBalanceValue(userPosition, assetIndex))()
}

let balanceAfterSupply = oldBalance + toNano(supplyAmount)

await reservePool.send(
  user,
  { value: toNano(1 + supplyAmount) },
  {
      $$type: 'TokenNotification',
      queryId: 0n,
      amount: toNano(supplyAmount),
      from: user.address!!,
      forwardPayload: assetBuilder
  },
);

if (positionId == 0n) {
  await timer(`Supply ${supplyAmount} ${assets[assetIndex].name} `, 1n, manager.getLastPositionId);
} else {
  
  await timer(`Supply ${supplyAmount} ${assets[assetIndex].name} `, balanceAfterSupply, getBalanceValue(userPosition, assetIndex));
}
}


