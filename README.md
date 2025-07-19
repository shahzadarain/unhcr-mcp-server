# UNHCR MCP Server

An MCP (Model Context Protocol) server that provides access to UNHCR (United Nations High Commissioner for Refugees) data API. This server enables AI assistants to query refugee statistics, demographics, asylum decisions, and other humanitarian data.

## Features

The server provides the following tools:

### 1. `get_population_statistics`
Retrieve population statistics for refugees, asylum seekers, and persons of concern.

**Parameters:**
- `year` (required): Year for the statistics (e.g., 2023)
- `country_code`: ISO3 country code (e.g., "SYR" for Syria)
- `population_type`: Type of population
  - `REF`: Refugees
  - `ASY`: Asylum seekers
  - `IDP`: Internally displaced persons
  - `STA`: Stateless persons
  - `OOC`: Others of concern
  - `ALL`: All types
- `limit`: Number of results (default: 100, max: 1000)

### 2. `get_demographics`
Get demographic breakdown by age and gender for populations of concern.

**Parameters:**
- `year` (required): Year for the demographics data
- `country_code`: ISO3 country code
- `population_type`: Type of population (REF, ASY, IDP, STA, OOC)

### 3. `search_countries`
Search for countries and retrieve their ISO3 codes.

**Parameters:**
- `query` (required): Country name or partial name to search

### 4. `get_time_series`
Retrieve time series data for population statistics across multiple years.

**Parameters:**
- `start_year` (required): Start year for the time series
- `end_year` (required): End year for the time series
- `country_code`: ISO3 country code
- `population_type`: Type of population

### 5. `get_asylum_decisions`
Get data on asylum application decisions.

**Parameters:**
- `year` (required): Year for the asylum decisions
- `country_code`: ISO3 country code of asylum country
- `origin_country_code`: ISO3 country code of origin country

## Installation

1. Clone this repository or save the files
2. Install dependencies:
   ```bash
   npm install
   ```

## Usage

### Running Locally

To run the server locally:

```bash
node index.js
```

### Integrating with Claude Desktop

Add the following to your Claude Desktop configuration:

```json
{
  "mcpServers": {
    "unhcr": {
      "command": "node",
      "args": ["/path/to/unhcr-mcp-server/index.js"]
    }
  }
}
```

### Hosting on mcp.so

1. Upload your server files to mcp.so
2. Configure the server endpoint
3. Share the server URL with users who want to access UNHCR data

## Example Queries

Here are some example queries you can make using this server:

1. **Get refugee statistics for 2023:**
   ```
   Use get_population_statistics with year 2023 and population_type REF
   ```

2. **Search for Syria's country code:**
   ```
   Use search_countries with query "Syria"
   ```

3. **Get demographic data for Syrian refugees:**
   ```
   Use get_demographics with year 2023, country_code "SYR", population_type "REF"
   ```

4. **Get time series data for global refugee populations:**
   ```
   Use get_time_series with start_year 2020, end_year 2023, population_type "REF"
   ```

5. **Get asylum decisions in Germany for 2023:**
   ```
   Use get_asylum_decisions with year 2023, country_code "DEU"
   ```

## API Documentation

This server interfaces with the UNHCR API v2. For more detailed information about the underlying API, visit:
https://data.unhcr.org/api/doc

## Data Usage

Please note that UNHCR data should be used responsibly and in accordance with humanitarian principles. The data represents real people in vulnerable situations.

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve the server functionality.