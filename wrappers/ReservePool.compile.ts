import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/reserve_pool.tact',
    options: {
        debug: true,
    },
};
