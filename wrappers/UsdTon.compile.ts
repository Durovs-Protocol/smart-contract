import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/usd_ton/usd_ton.tact',
    options: {
        debug: true,
    },
};
