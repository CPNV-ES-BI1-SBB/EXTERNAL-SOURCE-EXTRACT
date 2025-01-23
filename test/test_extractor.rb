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
  end

  def test_initialize
    assert_instance_of Extractor, @extractor
  end

  def test_extract_all_data_without_exceptions
    # Given: No oldest_record, no missing data, no duplicates
    data_file_path = File.join(__dir__, 'data', 'data_stationboard_lausanne_2024_12_01.json')
    data_response = JSON.parse(File.read(data_file_path))

    # Mock the API call to return the mock response
    @http_client.stub(:get, data_response) do
      # When: Extracting data
      result = @extractor.extract(http_client: @http_client, endpoint: @endpoint)

      # Then: Should return a list of all records and log the result
      assert_equal data_response, result
    end
  end
end
