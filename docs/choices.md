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

## Other choices

### Timestamp in Data

As we receive the data, it is necessary to define a convention for the timestamp. This is important to keep track of the data and to be able to compare it with other data.

There's no dedicated timestamp, so we need to create one. We can use the connection time. There is only one each day, but it might not be enough. It is also possible to use a combination of the connection time to get the date and the departure date to get the time of departure of the latest train. This could be better but still may not be unique.