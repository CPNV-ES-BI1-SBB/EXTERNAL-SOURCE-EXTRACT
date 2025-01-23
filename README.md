# External Source Extract

## Description

This project is designed to extract data from external sources and handle various data integrity issues, such as missing data and duplicates. The application ensures robust error handling and provides clear logging for each operation. The codebase is thoroughly tested, making it easy to maintain and extend.

## Prerequisites

Before running the project, ensure you have the following installed:

- **Ruby**: Version `3.3.6` - [Installation Guide](https://www.ruby-lang.org/en/news/2024/11/05/ruby-3-3-6-released/)
- **Bundler**: Version `2.5.22`
- **Docker**: Version `20.10.8` - [Installation Guide](https://docs.docker.com/get-docker/)

Verify your installed versions:
```sh
ruby --version
bundler --version
```

- **Ruby**: Configuration standard.

## Installation

1. Install dependencies using Bundler:
   ```sh
   bundle install
   ```

2. Set environment variables in `.env` file by copying the `.env.example` file:
   ```sh
   cp .env.example .env
   ```

3. Update the `.env` file with the required environment variables.

## Running the Project

### Docker

To run the application using Docker:

1. Start the Docker container:
   ```sh
   docker-compose up --build -d
   ```

### Local

You can run the application locally to extract data using the provided API:

1. Start the Sinatra server:
   ```sh
   ruby main.rb
   ```

2. The API will be accessible at:
   ```
   http://localhost:4567/
   ```

3. Example API endpoint to extract data:
   ```
   POST http://localhost:4567/api/v1/extract

   Request Body:
   {
     "url": "<URL>"
   }
   ```

Replace `<URL>` with the desired API endpoint to extract data.

---

## Testing the Project

The project includes a comprehensive test suite using Minitest. To run the tests:

1. Run all tests:
   ```sh
   ruby run_tests.rb
   ```

2. Run a specific test:
   ```sh
   ruby -Itest test/test_extractor.rb --name test_extract_all_data_without_exceptions
   ```

---

## Run with Docker

To run the application using Docker:

1. Ensure Docker and Docker Compose are installed on your system.

1. Copy the `.env.example` file to `.env` and configure it with the required environment variables.

1. Build and run the Docker container:
```sh
docker compose up --build
````


## Contributing

We welcome contributions to improve the project. Follow these guidelines to ensure consistency:

### Conventional Commit Messages

Use the following structure for your commit messages:
- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, missing semi-colons, etc.)
- **refactor**: Code restructuring without functionality changes
- **test**: Adding or updating tests
- **chore**: Maintenance tasks (e.g., dependency updates)

#### Example Commit Messages

- `feat: add support for retry logic`
- `fix: resolve log rotation issue`
- `docs: update testing instructions`