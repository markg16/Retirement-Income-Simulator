# Mortality Table Analysis System

A MATLAB-based system for handling mortality tables, with capabilities for data retrieval, analysis, and visualization.

## Features

- ✅ Core mortality table functionality
- ✅ Data validation and error handling
- ✅ Improvement factor calculations
- ✅ Table adjustments
- 🔄 Web data integration (in progress)
- 📊 Advanced visualization (planned)
- 📈 Statistical analysis tools (planned)

## Installation

### Prerequisites

- MATLAB R2020b or later
- Statistics and Machine Learning Toolbox
- Financial Toolbox (optional, for advanced features)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/mortality-table-analysis.git
cd mortality-table-analysis
```

2. Add the project to MATLAB path:
```matlab
addpath(genpath('path/to/mortality-table-analysis'));
```

3. Run the test suite to verify installation:
```matlab
testMortalityTableSystem
```

## Usage

### Basic Usage

```matlab
% Create a mortality table instance
table = MortalityTableFactory.createTable('Australian_Life_Tables_2015-17');

% Get mortality rate for age 65
rate = table.getRate('M', 65);

% Get survivorship probabilities
probs = table.getSurvivorshipProbabilities('F', 65, 75);
```

### Reading Custom Tables

```matlab
% Read from Excel files
maleFile = 'path/to/male_table.xlsx';
femaleFile = 'path/to/female_table.xlsx';
table = utilities.LifeTableUtilities.readLifeTables(maleFile, femaleFile);
```

### Applying Improvement Factors

```matlab
% Load improvement factors
improvementFactors = utilities.LifeTableUtilities.loadImprovementFactors('path/to/factors.xlsx');

% Adjust mortality table
[revisedlx, revisedqx] = utilities.LifeTableUtilities.adjustMortalityTable(...
    table.qx, table.lx, improvementFactors, entryAge);
```

## Project Structure

```
mortality-table-analysis/
├── lifeandothercontingencyclasses/
│   ├── MortalityTable.m
│   ├── BasicMortalityTable.m
│   ├── MortalityTableFactory.m
│   └── testMortalityTableSystem.m
├── +utilities/
│   └── LifeTableUtilities.m
├── LifeTables/
│   ├── Australian_Life_Tables_2015-17_Males.xlsx
│   ├── Australian_Life_Tables_2015-17_Females.xlsx
│   └── Improvement_factors_2015-17.xlsx
└── docs/
    └── examples/
```

## Documentation

- [Project Plan](PROJECT_PLAN.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [License](LICENSE.md)

## Development Status

See our [Project Plan](PROJECT_PLAN.md) for detailed development status and roadmap.

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Support

For support, please:
1. Check the [documentation](docs/)
2. Search [existing issues](https://github.com/yourusername/mortality-table-analysis/issues)
3. Create a new issue if needed

## Acknowledgments

- Australian Bureau of Statistics for mortality data
- MATLAB community for development tools and support 