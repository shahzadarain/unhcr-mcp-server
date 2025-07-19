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

const API_BASE_URL = 'https://data.unhcr.org/api';
const API_VERSION = 'v2';

class UNHCRServer {
  constructor() {
    this.server = new Server(
      {
        name: 'unhcr-api',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
    
    this.axiosInstance = axios.create({
      baseURL: `${API_BASE_URL}/${API_VERSION}`,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
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
              year: {
                type: 'integer',
                description: 'Year for the statistics (e.g., 2023)',
              },
              country_code: {
                type: 'string',
                description: 'ISO3 country code (e.g., "SYR" for Syria)',
              },
              population_type: {
                type: 'string',
                description: 'Type of population: REF (refugees), ASY (asylum seekers), IDP (internally displaced), STA (stateless)',
                enum: ['REF', 'ASY', 'IDP', 'STA', 'OOC', 'ALL'],
              },
              limit: {
                type: 'integer',
                description: 'Number of results to return (default: 100, max: 1000)',
                default: 100,
              },
            },
            required: ['year'],
          },
        },
        {
          name: 'get_demographics',
          description: 'Get demographic breakdown by age and gender',
          inputSchema: {
            type: 'object',
            properties: {
              year: {
                type: 'integer',
                description: 'Year for the demographics data',
              },
              country_code: {
                type: 'string',
                description: 'ISO3 country code',
              },
              population_type: {
                type: 'string',
                description: 'Type of population',
                enum: ['REF', 'ASY', 'IDP', 'STA', 'OOC'],
              },
            },
            required: ['year'],
          },
        },
        {
          name: 'search_countries',
          description: 'Search for countries and get their codes',
          inputSchema: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: 'Country name or partial name to search',
              },
            },
            required: ['query'],
          },
        },
        {
          name: 'get_time_series',
          description: 'Get time series data for population statistics',
          inputSchema: {
            type: 'object',
            properties: {
              country_code: {
                type: 'string',
                description: 'ISO3 country code',
              },
              population_type: {
                type: 'string',
                description: 'Type of population',
                enum: ['REF', 'ASY', 'IDP', 'STA', 'OOC'],
              },
              start_year: {
                type: 'integer',
                description: 'Start year for the time series',
              },
              end_year: {
                type: 'integer',
                description: 'End year for the time series',
              },
            },
            required: ['start_year', 'end_year'],
          },
        },
        {
          name: 'get_asylum_decisions',
          description: 'Get asylum application decisions data',
          inputSchema: {
            type: 'object',
            properties: {
              year: {
                type: 'integer',
                description: 'Year for the asylum decisions',
              },
              country_code: {
                type: 'string',
                description: 'ISO3 country code of asylum country',
              },
              origin_country_code: {
                type: 'string',
                description: 'ISO3 country code of origin country',
              },
            },
            required: ['year'],
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
        case 'search_countries':
          return this.searchCountries(request.params.arguments);
        case 'get_time_series':
          return this.getTimeSeries(request.params.arguments);
        case 'get_asylum_decisions':
          return this.getAsylumDecisions(request.params.arguments);
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
      const params = {
        year: args.year,
        limit: args.limit || 100,
        page: 1,
      };

      if (args.country_code) {
        params.coo_iso3 = args.country_code;
      }

      if (args.population_type && args.population_type !== 'ALL') {
        params.population_type = args.population_type;
      }

      const response = await this.axiosInstance.get('/population', { params });
      
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
            text: `Error fetching population statistics: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getDemographics(args) {
    try {
      const params = {
        year: args.year,
        limit: 100,
        page: 1,
      };

      if (args.country_code) {
        params.coo_iso3 = args.country_code;
      }

      if (args.population_type) {
        params.population_type = args.population_type;
      }

      const response = await this.axiosInstance.get('/demographics', { params });
      
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
            text: `Error fetching demographics: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async searchCountries(args) {
    try {
      const response = await this.axiosInstance.get('/countries', {
        params: {
          name: args.query,
          limit: 20,
        },
      });
      
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
            text: `Error searching countries: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getTimeSeries(args) {
    try {
      const results = [];
      
      for (let year = args.start_year; year <= args.end_year; year++) {
        const params = {
          year: year,
          limit: 100,
        };

        if (args.country_code) {
          params.coo_iso3 = args.country_code;
        }

        if (args.population_type) {
          params.population_type = args.population_type;
        }

        const response = await this.axiosInstance.get('/population', { params });
        results.push({
          year: year,
          data: response.data.items,
        });
      }
      
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(results, null, 2),
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Error fetching time series: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getAsylumDecisions(args) {
    try {
      const params = {
        year: args.year,
        limit: 100,
        page: 1,
      };

      if (args.country_code) {
        params.coa_iso3 = args.country_code;
      }

      if (args.origin_country_code) {
        params.coo_iso3 = args.origin_country_code;
      }

      const response = await this.axiosInstance.get('/asylum-decisions', { params });
      
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
            text: `Error fetching asylum decisions: ${error.message}`,
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

const server = new UNHCRServer();
server.run().catch(console.error);