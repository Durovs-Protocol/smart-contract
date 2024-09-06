import { Config } from '@ton/blueprint';

export const config: Config = {
    network: {
        endpoint:
            'https://testnet.toncenter.com/api/v2/jsonRPC',
        // endpoint:
        //     'https://ton.access.orbs.network/4410c0ff5Bd3F8B62C092Ab4D238bEE463E64410/1/testnet/toncenter-api-v2/jsonRPC',
        type: 'testnet',
        version: 'v2',
    },
};
