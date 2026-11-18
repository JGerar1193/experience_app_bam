module.exports = {
  projects: ['unit', 'integration', 'e2e'].map((suite) => ({
    displayName: suite,
    testEnvironment: 'node',
    testMatch: [`<rootDir>/dist-test/test/${suite}/**/*.spec.js`],
    transform: {},
    setupFiles: ['reflect-metadata'],
    testTimeout: 15000,
    clearMocks: true,
  })),
};