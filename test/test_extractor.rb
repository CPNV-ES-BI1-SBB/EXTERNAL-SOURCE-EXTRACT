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
    end
  end
end
