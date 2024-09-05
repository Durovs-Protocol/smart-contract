import { NetworkProvider } from '@ton/blueprint';
import { Address, Dictionary, toNano } from '@ton/core';
import contracts from '../utils/contracts';
import { assets, setupGas } from '../utils/data';

export async function run(provider: NetworkProvider) {
    const user = provider.sender().address as Address;

    const { v1manager } = await contracts(provider, user);
    const rates: Dictionary<Address, bigint> = Dictionary.empty();

    interface RatesData {
        [index: string]: bigint;
    }

    const ratesData: RatesData = {
        stTON: toNano(1.1),
        hTON: toNano(1.2),
        tsTON: toNano(1.3),
        NOT: toNano(1.4),
        Dogs: toNano(1.5),
        TON: toNano(1.6),
    };

    assets.forEach((asset: { name: any; pool_wallet: string; master: string }) => {
        rates.set(Address.parse(asset.master), ratesData[asset.name]);
    });

    await v1manager.send(
        provider.sender(),
        { value: toNano(setupGas) },
        {
            $$type: 'SetRates',
            rates: rates,
        },
    );
}
