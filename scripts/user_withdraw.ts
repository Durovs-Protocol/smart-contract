import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import contracts from '../utils/contracts';
import { assets, gas } from '../utils/data';
import { contractVersion, getBalanceValue, log, timer } from '../utils/helpers';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();

    const {
        manager,
        userPosition
    } = await contracts(provider, user.address!!)

    /**
     * TON - 0
     * stTON - 1
     * hTON - 2
     * tsTON - 3
	 */
    let assetIndex = 0;

    let withdrawAmount = (assetIndex == 0 ? 0.20 : 5);
    log('\nВозвращение залога: ' + withdrawAmount 
        + `\n${await contractVersion(manager, 'manager')}`
    );

    let oldBalance = 0n
    try {
        oldBalance =  await (await getBalanceValue(userPosition, assetIndex))()
    } catch(e) {}
    let balanceAfterWithdraw = oldBalance - toNano(withdrawAmount)
    /**
	 * A: основной кошелек в принципе (WalletV4)
	 * A->B(manager): WithdrawMessage
	 * B->C(user position): Withdraw
	 * C->D(pool): WithdrawRequest
     * D->C(user position): TonTransfer
     * C->A: возврат тона
	 */

    await withdraw(manager)
    async function withdraw(contract: any) {
        await contract.send(
            user,
            { value: toNano(gas) },
            {
                $$type: 'WithdrawMessage',
                amount: toNano(withdrawAmount),
                master: Address.parse(assets[assetIndex].master)
            },
        );
        await timer(`'Обработка запроса на вывод средств: баланс ${withdrawAmount} ${assets[assetIndex].name} `, balanceAfterWithdraw, getBalanceValue(userPosition, assetIndex));
    }
   

}


