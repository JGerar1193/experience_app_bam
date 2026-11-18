const { rmSync } = require('node:fs');
const { resolve } = require('node:path');
const { spawnSync } = require('node:child_process');

const projectRoot = resolve(__dirname, '..');
rmSync(resolve(projectRoot, 'dist-test'), { recursive: true, force: true });
const compilation = spawnSync(
  process.execPath,
  [require.resolve('typescript/bin/tsc'), '--project', 'tsconfig.test.json'],
  { cwd: projectRoot, stdio: 'inherit' },
);

if (compilation.error) {
  process.stderr.write('Unable to launch the test compiler.\n');
}
process.exitCode = compilation.status ?? 1;