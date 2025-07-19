// Test if the server can be run via npx
import { spawn } from 'child_process';

console.log('Testing npx execution...');

const child = spawn('npx', ['-y', 'mcp-server-unhcr'], {
  stdio: ['pipe', 'pipe', 'pipe']
});

child.stdout.on('data', (data) => {
  console.log('STDOUT:', data.toString());
});

child.stderr.on('data', (data) => {
  console.log('STDERR:', data.toString());
});

child.on('error', (error) => {
  console.error('Error:', error);
});

child.on('close', (code) => {
  console.log('Process exited with code:', code);
});

// Send a list tools request after 2 seconds
setTimeout(() => {
  console.log('Sending list tools request...');
  child.stdin.write(JSON.stringify({
    jsonrpc: '2.0',
    method: 'tools/list',
    id: 1
  }) + '\n');
}, 2000);

// Kill after 5 seconds
setTimeout(() => {
  child.kill();
}, 5000);