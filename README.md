# EXTERNAL-SOURCE-EXTRACT

## Description

This project is designed to extract data from an external source and handle various data integrity issues such as missing data and duplicates. It includes a set of tests to ensure the functionality works as expected.

## Getting Started

### Prerequisites

- Ruby 3.3.0+
- Bundler

### Installation

1. Clone the repository:
    ```sh
    git clone git@github.com:CPNV-ES-BI1-SBB/EXTERNAL-SOURCE-EXTRACT.git
    ```

2. Install dependencies:
    ```sh
    bundle install
    ```

### Running the Project

#### Using Ruby

1. Run the main script:
    ```sh
    ruby main.rb
    ```

### Running Tests

#### Using Ruby

1. Run the test script:
    ```sh
    ruby run_tests.rb
    ```

## Directory Structure

```
├── config/
│   └── config.yml
├── docs/
│   ├── class_diagram.puml
│   └── sequence_diagram.puml
├── lib/
│   ├── api_client.rb
│   ├── extractor.rb
│   └── logger.rb
├── main.rb
├── README.md
├── run_tests.rb
├── test/
│   ├── mocks/
│   ├── test_extractor.rb
│   └── test_helper.rb
```

## Contact

If needed, you can create an issue on GitHub, and we will try to respond as quickly as possible.