import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/jetton/stablecoin.tact',
    options: {
        debug: true,
    },
};
