
import { NetworkProvider } from '@ton/blueprint';
import { Address, beginCell, toNano } from '@ton/core';
import contracts from '../utils/contracts';
import { assets } from '../utils/data';
import { getBalanceValue, log, timer } from '../utils/helpers';

export async function run(provider: NetworkProvider) {
	const user = provider.sender();
	const {
		reservePool,
		manager,
		userPosition
        } = await contracts(provider, user.address!!)

	const supplyAmount = 0.5;
	const assetIndex = 0 // Не менять тк этот скрипт только для assetIndex = 0
	/**
	 * TON - 5
	 */
	log('\nВнесение залога ton: ' + supplyAmount
	// `\n${await contractVersion(manager, 'manager')}` +
	// `\n${await contractVersion(userPosition, 'userPosition')}`
	);

	let assetBuilder = beginCell().storeMaybeRef(beginCell().storeAddress(Address.parse(assets[assetIndex].master)).storeAddress(Address.parse('UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ')).storeInt(1n, 64).endCell()).endCell().asSlice()

	
	let oldBalance = 0n
	let positionId = await manager.getLastPositionId()

	if (positionId != 0n) {
		oldBalance =  await (await getBalanceValue(userPosition, assetIndex))()
	}

	let balanceAfterSupply = oldBalance + toNano(supplyAmount)

	/**
	 * A: основной кошелек в принципе (WalletV4)
	 * A->B(reserve pool): сообщение о поступлении TokenNotification
	 * B->C(manager): SupplyMessage
	 * C->D(user position): Supply
	 * D->A: Возврат газа
	 */
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


