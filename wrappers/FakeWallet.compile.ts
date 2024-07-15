import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/utils/fake_wallet.tact',
    options: {
        debug: true,
    },
};
