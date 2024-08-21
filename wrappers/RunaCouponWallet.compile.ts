import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/runa_coupon/runa_coupon_wallet.tact',
    options: {
        debug: true,
    },
};
