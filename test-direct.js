// Simple test to run the server directly
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log('Testing server directly...');

const child = spawn('node', [join(__dirname, 'index.js')], {
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

// Send a list tools request after 1 second
setTimeout(() => {
  console.log('Sending list tools request...');
  const request = {
    jsonrpc: '2.0',
    method: 'tools/list',
    id: 1
  };
  child.stdin.write(JSON.stringify(request) + '\n');
}, 1000);

// Kill after 3 seconds
setTimeout(() => {
  console.log('Stopping server...');
  child.kill();
}, 3000);