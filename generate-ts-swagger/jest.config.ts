import type {Config} from '@jest/types';
// Sync object
const config: Config.InitialOptions = {
    // testMatch: [ "**/__tests__/**/*.js?(x)", "**/?(*.)+(spec|test).js?(x)" ],
    verbose: true,
    transform: {
  '^.+\\.tsx?$': 'ts-jest',
},
};
export default config;