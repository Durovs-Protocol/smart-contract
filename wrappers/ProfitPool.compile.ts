import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/v1/profit_pool.tact',
    options: {
        debug: true,
    },
};
