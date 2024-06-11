import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/user_position.tact',
    options: {
        debug: true,
    },
};
