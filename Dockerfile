FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy server files
COPY . .

# Expose the port (if needed, though MCP uses stdio)
EXPOSE 3000

# Start the server
CMD ["node", "index.js"]