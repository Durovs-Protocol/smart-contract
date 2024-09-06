import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/v1/stable/stable_wallet.tact',
    options: {
        debug: true,
    },
};
