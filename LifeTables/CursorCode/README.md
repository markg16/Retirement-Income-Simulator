# Mortality Table Analysis System

A MATLAB-based system for analyzing and processing mortality tables, with a focus on Australian Government Actuary (AGA) data sources. The system provides robust data retrieval, validation, and analysis capabilities for mortality tables.

## Architecture

### Core Components

1. **Data Sources**
   - `MortalityDataSource` (Abstract Base Class)
   - `AustralianGovernmentActuarySource` (AGA Implementation)
   - Future support for additional data sources

2. **Data Processing**
   - Data validation and error handling
   - Table adjustments and improvements
   - Caching system for efficient data retrieval

3. **Utilities**
   - File management utilities
   - Data transformation tools
   - Logging and error tracking

### Class Hierarchy

```
MortalityDataSource (Abstract)
└── AustralianGovernmentActuarySource
    ├── URL Management
    ├── Data Fetching
    ├── Cache Management
    └── Data Validation
```

## Features

### Implemented
- ✅ AGA data source integration
- ✅ Data validation and error handling
- ✅ URL pattern management
- ✅ Caching system
- ✅ Logging system

### In Progress
- 🔄 Advanced data analysis tools
- 🔄 Multiple data source support
- 🔄 Performance optimization

### Planned
- 📊 Visualization tools
- 📈 Statistical analysis
- 🔍 Advanced search capabilities

## Installation

### Prerequisites

- MATLAB R2020b or later
- Statistics and Machine Learning Toolbox
- Internet connection for AGA data retrieval

### Setup

1. Clone the repository:
```bash
git clone https://github.com/markg16/mortality-table-analysis.git
cd mortality-table-analysis
```

2. Add the project to MATLAB path:
```matlab
addpath(genpath('path/to/mortality-table-analysis'));
```

3. Initialize the AGA data source:
```matlab
agaSource = AustralianGovernmentActuarySource();
```

## Usage

### Basic Usage

```matlab
% Create AGA data source
agaSource = AustralianGovernmentActuarySource();

% Fetch latest mortality data
data = agaSource.fetchLatestData();

% Get specific table
table = agaSource.getMortalityTable(TableNames.ALT_Table2020_22);
```

### Data Validation

```matlab
% Validate table data
isValid = agaSource.validateTableData(rawData);

% Check data source availability
isAvailable = agaSource.checkAvailability();
```

## Project Structure

```
mortality-table-analysis/
├── lifeandothercontingencyclasses/
│   ├── MortalityDataSource.m
│   ├── AustralianGovernmentActuarySource.m
│   └── test_AGA.m
├── +utilities/
│   └── LifeTableUtilities.m
├── +runtimeclasses/
│   └── aga_url_patterns.json
└── docs/
    └── examples/
```

## Development Status

### Current Focus
1. Enhancing data validation
2. Improving error handling
3. Optimizing data retrieval
4. Adding support for additional data sources

### Next Steps
1. Implement advanced analysis tools
2. Add visualization capabilities
3. Develop statistical analysis features
4. Create comprehensive documentation

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Support

For support, please:
1. Check the [documentation](docs/)
2. Search [existing issues](https://github.com/markg16/mortality-table-analysis/issues)
3. Create a new issue if needed

## Acknowledgments

- Australian Government Actuary for mortality data
- MATLAB community for development tools and support 