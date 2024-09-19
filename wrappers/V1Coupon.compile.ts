import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/v1/stable/coupon/coupon.tact',
    options: {
        debug: true,
    },
};
