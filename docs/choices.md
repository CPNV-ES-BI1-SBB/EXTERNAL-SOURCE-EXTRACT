# Choices about the project

## Description
- This document outlines the choices made in the project, including technologies and attributes names

## Technologies
### Ruby with Minitest

The project is written in Ruby using Minitest for testing.

We needed a language with excellent community support that could handle making HTTP requests, handling JSON data and that our team could understand and enjoy coding with.

We chose Ruby because it meets the following requirements:

- Support for easy-to-write and readable tests
- An object-oriented scripting language
- Language must be compatible with HTTP and JSON
- Can be dockerized

## Attributes Names 
- `api_client`: An instance of the `APIClient` class responsible for making HTTP requests.
- `logger`: An instance of the `Logger` class responsible for logging information and errors.
- `max_retries`: The maximum number of retries when missing data.
- `current_data`: The current data being processed.
- `oldest_record_stored`: The oldest record stored in the system that is the time of the last connection of a stationboard.
- `newest_record_received`: The newest record received from the API that is the time of the last connection of a stationboard.