#!/usr/bin/env node

// Import with full file extension for better compatibility
import UNHCRServer from './index.js';

// Start the server immediately
const server = new UNHCRServer();
server.run().catch(console.error);