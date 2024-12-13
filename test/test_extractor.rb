require 'json'
require_relative 'test_helper'

class TestExtractor < Minitest::Test
  def setup
    # Given an API client, a logger
    @api_client = APIClient.new(base_url: 'https://api.example.com', headers: {}, timeout: 5)
    @logger = Logger.new(log_path: 'test_log.txt')
    @extractor = Extractor.new(api_client: @api_client, logger: @logger, max_retries: 3)
    @oldest_record_stored = { 
      "connections": [
        { "time": "2024-01-12 00:00:00" }
      ]
    }
  end

  def teardown
    File.delete('test_log.txt') if File.exist?('test_log.txt')
  end

  def test_initialize
    assert_instance_of Extractor, @extractor
    assert_equal 3, @extractor.max_retries
  end

  def test_extract_all_data_without_exceptions
    # Given: No oldest_record, no missing data, no duplicates
    mock_file_path = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01.json')
    mock_response = JSON.parse(File.read(mock_file_path))
    @oldest_record_stored = {}
  
    # Mock the API call to return the mock response
    @api_client.stub(:get, mock_response) do
      # When: Extracting data 
      result = @extractor.extract(oldest_record_stored: @oldest_record_stored)
      
      # Then: Should return a list of all records and log the result
      assert_equal mock_response, result

      # Ensure the variables are updated
      assert_equal mock_response, @extractor.current_data
      assert_equal mock_response["connections"].last, @extractor.oldest_record_stored["connections"].last
      assert_equal mock_response["connections"].first, @extractor.newest_record_received["connections"].first
    end
  end  

  def test_extract_all_data_from_the_oldest_record_without_exceptions
    # Given: Oldest record, no missing data, no duplicates
    mock_file_path = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01.json')
    mock_response = JSON.parse(File.read(mock_file_path))
  
    # Mock the API call to return the mock response
    @api_client.stub(:get, mock_response) do
      # When: Extracting data
      result = @extractor.extract(oldest_record_stored: @oldest_record_stored)
      
      # Then: Should return a list of all records and log the result
      assert_equal mock_response, result

      # Ensure the variables are updated
      assert_equal mock_response, @extractor.current_data
      assert_equal mock_response["connections"].last, @extractor.oldest_record_stored["connections"].last
      assert_equal mock_response["connections"].first, @extractor.newest_record_received["connections"].first
    end
  end

  def test_handle_missing_data_until_all_data_are_retrieved
    # Given: Oldest_record, missing data, no duplicates
    mock_file_path_missing = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01_missing_data.json')
    mock_file_path_complete = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01.json')
    mock_response_missing = JSON.parse(File.read(mock_file_path_missing))
    mock_response_complete = JSON.parse(File.read(mock_file_path_complete))
    call_count = 0

      # Mock the API call to return the missing data first and then the complete data
      @api_client.stub(:get, lambda {
        call_count += 1
        call_count == 1 ? mock_response_missing : mock_response_complete
      }) do
        # When: Extracting data
        result = @extractor.extract(oldest_record_stored: @oldest_record_stored)
        
        # Then: Should fill the holes in the data and return a list of all records and log the result 
        # Ensure mock_response_complete is returned
        assert_equal mock_response_complete, result

        # Ensure `handle_missing` is invoked and it recalls extract to get the complete data
        assert_equal 2, call_count

        # Ensure the variables are updated
        assert_equal mock_response_complete, @extractor.current_data
        assert_equal mock_response_complete["connections"].last, @extractor.oldest_record_stored["connections"].last
        assert_equal mock_response_complete["connections"].first, @extractor.newest_record_received["connections"].first
      end
  end

  def test_handle_duplicates_until_all_data_are_unique
    # Given: Oldest_record, no missing data, duplicates
    mock_file_path_duplicates = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01_duplicates.json')
    mock_file_path_unique = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01.json')
    mock_response_duplicates = JSON.parse(File.read(mock_file_path_duplicates))
    mock_response_unique = JSON.parse(File.read(mock_file_path_unique))
  
    # Mock the API call to simulate duplicate data response
    @api_client.stub(:get, mock_response_duplicates) do

      # When: Extracting data
      result = @extractor.extract(oldest_record_stored: @oldest_record_stored)

      # Then: Should remove duplicates and return a list of all records and log the result
      assert_equal mock_response_unique, result

      # Ensure the variables are updated
      assert_equal mock_response_unique, @extractor.current_data
      assert_equal mock_response_unique["connections"].last, @extractor.oldest_record_stored["connections"].last
      assert_equal mock_response_unique["connections"].first, @extractor.newest_record_received["connections"].first
    end
  end  

  def test_handle_missing_data_and_duplicates_until_all_data_are_unique_and_retrieved
    # Given: Oldest_record, missing data, duplicates
    mock_file_path_missing_duplicates_and_missing = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01_missing_duplicate_data_and_missing_data.json')
    mock_response_with_only_duplicates = {}
    mock_file_path_complete = File.join(__dir__, 'mocks', 'mock_stationboard_lausanne_2024_12_01.json')
    mock_response_missing_duplicates_and_missing = JSON.parse(File.read(mock_file_path_missing_duplicates_and_missing))
    mock_response_complete = JSON.parse(File.read(mock_file_path_complete))

    # Mock the API call to return the missing data first and then the complete data
    @api_client.stub(:get, lambda {
      call_count += 1
      call_count == 1 ? mock_response_missing_duplicates_and_missing : mock_response_with_only_duplicates
    }) do
      # When: Extracting data
      result = @extractor.extract(oldest_record_stored: @oldest_record_stored)
      
      # Then: Should fill the holes in the data, remove duplicates and return a list of all records and log the result
      
      # First handle missing data
      # Ensure handle_missing fills the holes in the data
      mock_response_with_only_duplicates = result

      # Set the current data with after handling missing data
      assert_equal @current_data, mock_response_with_only_duplicates

      # Ensure `handle_missing` is invoked and it recalls extract to get the complete data
      assert_equal 2, call_count
    end
      # Ensure handle_duplicate removes duplicates
      assert_equal mock_response_complete, result_complete

      # Ensure the variables are updated
      assert_equal mock_response_complete, @extractor.current_data
      assert_equal mock_response_complete["connections"].last, @extractor.oldest_record_stored["connections"].last
      assert_equal mock_response_complete["connections"].first, @extractor.newest_record_received["connections"].first
  end

