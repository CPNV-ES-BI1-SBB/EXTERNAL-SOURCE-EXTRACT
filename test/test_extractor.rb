require_relative 'test_helper'

class TestExtractor < Minitest::Test
  def setup
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

  def test_extract_all_data_without_errors
    # test
  end
end
