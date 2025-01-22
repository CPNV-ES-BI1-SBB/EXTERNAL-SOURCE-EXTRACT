require 'json'
require 'logger'
require_relative '../lib/extractor'
require_relative '../lib/http_client'

class TestExtractor < Minitest::Test
  def setup
    # Given an API client, a logger
    @endpoint = 'https://api.example.com/data'
    @http_client = HTTPClient.new()
    @logger = Logger.new(ENV.fetch('TEST_LOG_PATH', 'logs/test_log.txt'))
    @extractor = Extractor.new()
    @newest_record_stored = {
      "connections": [
        { "time": "2024-12-01 00:00:00" }
      ]
    }
  end

  def test_initialize
    assert_instance_of Extractor, @extractor
    assert_equal 3, @extractor.max_retries
  end

  def test_extract_all_data_without_exceptions
    # Given: No oldest_record, no missing data, no duplicates
    mock_file_path = File.join(__dir__, 'mocks', 'mock_shortened.json')
    mock_response = JSON.parse(File.read(mock_file_path))
    @newest_record_stored = {}

    # Mock the API call to return the mock response
    @http_client.stub(:get, mock_response) do
      # When: Extracting data
      result = @extractor.extract(http_client: @http_client, endpoint: @endpoint, newest_record_stored: @newest_record_stored)

      # Then: Should return a list of all records and log the result
      assert_equal mock_response, result

      # Ensure the variables are updated
      assert_equal mock_response, @extractor.current_data
      assert_equal mock_response["connections"].last, @extractor.newest_record_stored
    end
  end

  def test_extract_all_data_from_the_oldest_record_without_exceptions
  # Given: Oldest record, no missing data, no duplicates
  mock_file_path = File.join(__dir__, 'mocks', 'mock_shortened.json')
  mock_response = JSON.parse(File.read(mock_file_path))

  #  Mock the API call to return the mock response
  @http_client.stub(:get, mock_response) do
      # When: Extracting data
      result = @extractor.extract(http_client: @http_client, endpoint: @endpoint, newest_record_stored: @newest_record_stored)

      # Then: Should return a list of all records and log the result
      assert_equal mock_response, result

      # Ensure the variables are updated
      assert_equal mock_response, @extractor.current_data
      assert_equal mock_response["connections"].last, @extractor.newest_record_stored
      assert_equal mock_response["connections"].last, @extractor.oldest_record_retrieved
    end
  end

  def test_handle_missing_data_until_all_data_are_retrieved
    # Given: A missing data scenario
    mock_file_path_missing = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01_missing_data.json')
    mock_file_path_complete = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01.json')
    mock_response_missing = JSON.parse(File.read(mock_file_path_missing))
    mock_response_complete = JSON.parse(File.read(mock_file_path_complete))
  
    # This call_count ensures proper response switching
    call_count = 0
  
    # Use a lambda that switches behavior based on call count
    @http_client.stub(:get, lambda { |endpoint|
      call_count += 1
      if call_count == 1
        mock_response_missing
      else
        mock_response_complete
      end
    }) do
      # When: Extracting data
      result = @extractor.extract(http_client: @http_client, endpoint: @endpoint, newest_record_stored: @newest_record_stored)
  
      # Then: Should fill the holes in the data and return a list of all records
      assert_equal mock_response_complete, result
    end
  end    

  def test_handle_duplicates_until_all_data_are_unique
     # Given: Oldest_record, no missing data, duplicates
     mock_file_path_duplicates = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01_duplicate_data.json')
     mock_file_path_unique = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01.json')
     mock_response_duplicates = JSON.parse(File.read(mock_file_path_duplicates))
     mock_response_unique = JSON.parse(File.read(mock_file_path_unique))

     # Mock the API call to simulate duplicate data response
     @http_client.stub(:get, mock_response_duplicates) do

       # When: Extracting data
       result = @extractor.extract(http_client: @http_client, endpoint: @endpoint, newest_record_stored: @newest_record_stored)
       
       # Then: Should remove duplicates and return a list of all records and log the result
       assert_equal mock_response_unique, result
     end
  end

  def test_handle_missing_data_and_duplicates_until_all_data_are_unique_and_retrieved
    # Given: A missing data scenario with duplicates
    mock_file_path_missing = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01_missing_data.json')
    mock_file_path_duplicates = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01_duplicate_data.json')
    mock_file_path_complete = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01.json')
    
    mock_response_missing = JSON.parse(File.read(mock_file_path_missing))
    mock_response_duplicates = JSON.parse(File.read(mock_file_path_duplicates))
    mock_response_complete = JSON.parse(File.read(mock_file_path_complete))
  
    call_count = 0
  
    # Use a lambda to simulate multiple conditions in a single test
    @http_client.stub(:get, lambda { |endpoint|
      call_count += 1
      case call_count
      when 1
        mock_response_missing  # Return incomplete data on the first call
      when 2
        mock_response_duplicates # Return data with duplicates on the second call
      end
    }) do
      # When: Extracting data
      result = @extractor.extract(http_client: @http_client, endpoint: @endpoint, newest_record_stored: @newest_record_stored)
  
      # Then: Ensure all missing data and duplicates are handled
      assert_equal mock_response_complete, result
    end
  end  

  def test_handle_multiple_retries_until_max_retries_0
    # Given: Oldest_record, at least one missing data and/or duplicate, max_retries = 3
    mock_file_path_missing = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01_missing_data.json')
    mock_response_missing = JSON.parse(File.read(mock_file_path_missing))
    @extractor.max_retries = 3
  
    # Simulate retry logic with max_retries = 3
    call_count = 0
  
    @http_client.stub(:get, lambda { |endpoint|
      call_count += 1
      if call_count <= @extractor.max_retries
        mock_response_missing
      else
        mock_response_missing
      end
    }) do
      begin
        # When: Extracting data while max_retries = 3
        @extractor.extract(http_client: @http_client, endpoint: @endpoint, newest_record_stored: @newest_record_stored)
      rescue Extractor::MaxRetriesReachedError
        # Bypass the exception and continue
      end
  
      # Then: Should retry until max_retries is reached
      assert_equal 0, @extractor.max_retries
    end
  end

  def test_should_throw_an_exception_if_max_retries_is_reached
    # Given: Oldest_record, at least one missing data and/or duplicate, max_retries= 0
    mock_file_path_missing = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01_missing_data.json')
    mock_response_missing = JSON.parse(File.read(mock_file_path_missing))
    @max_retries = 0

    # Mock the API call to return missing data indefinitely
    @http_client.stub(:get, mock_response_missing) do

      # Then: Should throw an exception if max_retries is reached
      assert_raises(Extractor::MaxRetriesReachedError) do
        # When: Extracting data with missing data and max_retries = 0
        @extractor.extract(http_client: @http_client, endpoint: @endpoint, newest_record_stored: @newest_record_stored)
      end
    end
  end
end
