require 'json'
require_relative 'test_helper'

class TestExtractor < Minitest::Test
  def setup
    # Given an API client, a logger
    @api_client = APIClient.new(base_url: 'https://api.example.com', headers: {}, timeout: 5)
    @logger = Logger.new(log_path: 'test_log.txt')
    @extractor = Extractor.new(api_client: @api_client, logger: @logger, max_retries: 3)
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

    # When: Extracting data
    @api_client.stub(:get, mock_response) do
      result = @extractor.extract(oldest_record: {})

      # Then: Should return a list of all records and log the result
      assert_equal mock_response["trains"], result
      @oldest_record = result.last
      assert_includes @logger.last_log, "Extraction result: #{result}"
    end
  end
end
