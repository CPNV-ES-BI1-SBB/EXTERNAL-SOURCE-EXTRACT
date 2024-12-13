# EXTERNAL-SOURCE-EXTRACT

# Behavior tests

## Test 1
- Should extract all data without exceptions

- Given: APIClient instance, Logger instance, no oldest_record, no missing data, no duplicates
- When: Extracting data
- Then: Should return a list of all records and log the result

## Test 2
- Should extract all data from the oldest_record without exceptions

- Given: APIClient instance, Logger instance, oldest_record, no missing data, no duplicates
- When: Extracting data
- Then: Should return a list of all records and log the result

## Test 3
- Should handle missing data until all data are retrieved

- Given: APIClient instance, Logger instance, oldest_record, missing data, no duplicates
- When: Extracting data
- Then: Should fill the holes in the data and return a list of all records and log the result

## Test 4
- Should handle duplicates until all data are unique

- Given: APIClient instance, Logger instance, oldest_record, no missing data, duplicates
- When: Extracting data
- Then: Should remove duplicates and return a list of all records and log the result

## Test 5
- Should handle missing data and duplicates until all data are unique and retrieved

- Given: APIClient instance, Logger instance, oldest_record, missing data, duplicates
- When: Extracting data
- Then: Should fill the holes in the data, remove duplicates and return a list of all records and log the result

## Test 6
- Should handle multiple retries until should_retry returns False

- Given: APIClient instance, Logger instance, oldest_record, at least one missing data and/or duplicate, should_retry returns True
- When: Extracting data while should_retry returns True
- Then: Should retry until should_retry returns False

## Test 7
- Should throw an exception if max_retries is reached

- Given: APIClient instance, Logger instance, oldest_record, at least one missing data and/or duplicate, max_retries=0
- When: Failed to extract data
- Then: Should throw an exception


# Choices
## Timestamp in data
As we recive the data it is needed to define a convention for the timestamp. This is important to keep track of the data and to be able to compare it with other data.
There's not a dedicated timestamp so we need to create one. We can use the Connection time. There is only one each day, it might won't be enough. It is also possible to use a
combination of the connection time to get the DATE and the departure date to get the time of departure of the lastest train. I could be better but still it is not unique.