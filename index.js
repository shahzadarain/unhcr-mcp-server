#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ErrorCode,
  ListToolsRequestSchema,
  McpError,
} from '@modelcontextprotocol/sdk/types.js';
import axios from 'axios';

// UNHCR API endpoints based on their documentation
const API_BASE_URL = 'https://api.unhcr.org/population/v1';

class UNHCRServer {
  constructor() {
    this.server = new Server(
      {
        name: 'unhcr-api',
        version: '1.0.1',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
    
    this.axiosInstance = axios.create({
      baseURL: API_BASE_URL,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      timeout: 30000,
    });
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'get_population_statistics',
          description: 'Get population statistics for refugees, asylum seekers, and persons of concern',
          inputSchema: {
            type: 'object',
            properties: {
              year_from: {
                type: 'integer',
                description: 'Start year for the statistics (e.g., 2022)',
                default: 2022,
              },
              year_to: {
                type: 'integer',
                description: 'End year for the statistics (e.g., 2023)',
                default: 2023,
              },
              coo_iso: {
                type: 'string',
                description: 'Country of origin ISO3 code (e.g., "SYR" for Syria)',
              },
              coa_iso: {
                type: 'string',
                description: 'Country of asylum ISO3 code (e.g., "TUR" for Turkey)',
              },
              population_type: {
                type: 'string',
                description: 'Type of population',
                enum: ['REF', 'ASY', 'IDP', 'STA', 'OOC', 'VDA'],
              },
              limit: {
                type: 'integer',
                description: 'Number of results to return (default: 100, max: 10000)',
                default: 100,
              },
            },
            required: [],
          },
        },
        {
          name: 'get_demographics',
          description: 'Get demographic breakdown by age and gender',
          inputSchema: {
            type: 'object',
            properties: {
              year_from: {
                type: 'integer',
                description: 'Start year for demographics',
                default: 2022,
              },
              year_to: {
                type: 'integer',
                description: 'End year for demographics',
                default: 2023,
              },
              coo_iso: {
                type: 'string',
                description: 'Country of origin ISO3 code',
              },
              coa_iso: {
                type: 'string',
                description: 'Country of asylum ISO3 code',
              },
            },
            required: [],
          },
        },
        {
          name: 'get_countries',
          description: 'Get list of countries with their ISO codes',
          inputSchema: {
            type: 'object',
            properties: {
              region: {
                type: 'string',
                description: 'Filter by region (e.g., "Africa", "Asia", "Europe")',
              },
            },
            required: [],
          },
        },
        {
          name: 'get_solutions',
          description: 'Get data on durable solutions (resettlement, returns, etc.)',
          inputSchema: {
            type: 'object',
            properties: {
              year_from: {
                type: 'integer',
                description: 'Start year',
                default: 2022,
              },
              year_to: {
                type: 'integer',
                description: 'End year',
                default: 2023,
              },
              coo_iso: {
                type: 'string',
                description: 'Country of origin ISO3 code',
              },
              solution_type: {
                type: 'string',
                description: 'Type of solution',
                enum: ['RET', 'RST', 'NAT'],
              },
            },
            required: [],
          },
        },
        {
          name: 'get_idps',
          description: 'Get internally displaced persons (IDP) statistics',
          inputSchema: {
            type: 'object',
            properties: {
              year_from: {
                type: 'integer',
                description: 'Start year',
                default: 2022,
              },
              year_to: {
                type: 'integer',
                description: 'End year',
                default: 2023,
              },
              coa_iso: {
                type: 'string',
                description: 'Country ISO3 code',
              },
            },
            required: [],
          },
        },
      ],
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      switch (request.params.name) {
        case 'get_population_statistics':
          return this.getPopulationStatistics(request.params.arguments);
        case 'get_demographics':
          return this.getDemographics(request.params.arguments);
        case 'get_countries':
          return this.getCountries(request.params.arguments);
        case 'get_solutions':
          return this.getSolutions(request.params.arguments);
        case 'get_idps':
          return this.getIDPs(request.params.arguments);
        default:
          throw new McpError(
            ErrorCode.MethodNotFound,
            `Unknown tool: ${request.params.name}`
          );
      }
    });
  }

  async getPopulationStatistics(args) {
    try {
      const params = new URLSearchParams();
      
      // Add parameters if provided
      if (args.year_from) params.append('yearFrom', args.year_from);
      if (args.year_to) params.append('yearTo', args.year_to);
      if (args.coo_iso) params.append('coo', args.coo_iso);
      if (args.coa_iso) params.append('coa', args.coa_iso);
      if (args.population_type) params.append('populationType', args.population_type);
      if (args.limit) params.append('limit', args.limit);
      
      // Default to showing data grouped by year
      params.append('aggregate', 'year');
      
      const url = `/population?${params.toString()}`;
      console.error(`Fetching from: ${API_BASE_URL}${url}`);
      
      const response = await this.axiosInstance.get(url);
      
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(response.data, null, 2),
          },
        ],
      };
    } catch (error) {
      console.error('Error details:', error.response?.data || error.message);
      return {
        content: [
          {
            type: 'text',
            text: `Error fetching population statistics: ${error.response?.data?.message || error.message}\nStatus: ${error.response?.status}\nAPI URL: ${API_BASE_URL}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getDemographics(args) {
    try {
      const params = new URLSearchParams();
      
      if (args.year_from) params.append('yearFrom', args.year_from);
      if (args.year_to) params.append('yearTo', args.year_to);
      if (args.coo_iso) params.append('coo', args.coo_iso);
      if (args.coa_iso) params.append('coa', args.coa_iso);
      
      params.append('aggregate', 'age,sex');
      
      const url = `/demographics?${params.toString()}`;
      const response = await this.axiosInstance.get(url);
      
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(response.data, null, 2),
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Error fetching demographics: ${error.response?.data?.message || error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getCountries(args) {
    try {
      const params = new URLSearchParams();
      
      if (args.region) params.append('region', args.region);
      
      const url = `/countries?${params.toString()}`;
      const response = await this.axiosInstance.get(url);
      
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(response.data, null, 2),
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Error fetching countries: ${error.response?.data?.message || error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getSolutions(args) {
    try {
      const params = new URLSearchParams();
      
      if (args.year_from) params.append('yearFrom', args.year_from);
      if (args.year_to) params.append('yearTo', args.year_to);
      if (args.coo_iso) params.append('coo', args.coo_iso);
      if (args.solution_type) params.append('solutionType', args.solution_type);
      
      const url = `/solutions?${params.toString()}`;
      const response = await this.axiosInstance.get(url);
      
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(response.data, null, 2),
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Error fetching solutions data: ${error.response?.data?.message || error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getIDPs(args) {
    try {
      const params = new URLSearchParams();
      
      if (args.year_from) params.append('yearFrom', args.year_from);
      if (args.year_to) params.append('yearTo', args.year_to);
      if (args.coa_iso) params.append('coa', args.coa_iso);
      
      params.append('populationType', 'IDP');
      
      const url = `/population?${params.toString()}`;
      const response = await this.axiosInstance.get(url);
      
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(response.data, null, 2),
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Error fetching IDP statistics: ${error.response?.data?.message || error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('UNHCR MCP server running on stdio');
  }
}

// Auto-start server when script is run directly
if (import.meta.url === `file://${process.argv[1]}`) {
  const server = new UNHCRServer();
  server.run().catch(console.error);
}

export default UNHCRServer;