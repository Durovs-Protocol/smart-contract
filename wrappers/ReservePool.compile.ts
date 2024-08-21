import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/v1/reserve_pool.tact',
    options: {
        debug: true,
    },
};
