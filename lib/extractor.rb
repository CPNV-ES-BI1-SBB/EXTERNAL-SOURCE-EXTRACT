require 'time'
require 'json'
require 'logger'

##
# Extractor class to handle data extraction from an API.
# This class is responsible for extracting data.
#
class Extractor
  class MaxRetriesReachedError < StandardError;end
  attr_accessor :http_client, :logger, :current_data, :endpoint

  # Initializes a new Extractor instance.
  #
  # @param http_client [Object] The API client for data extraction.
  # @param logger [Object] A logger instance for logging events.
  #
  def initialize()
    @http_client = nil
    @logger = Logger.new(ENV.fetch('EXTRACT_LOG_PATH', 'logs/extract_log.log'))
    @current_data = {}
    @endpoint = ''
  end

  ##
  # Main method to extract data from the API.
  #
  # @param endpoint [String] The endpoint to query for data.
  # @return [JSON] The extracted data.
  #
  def extract(http_client:, endpoint:)
    @http_client = http_client
    @endpoint = endpoint

    if ENV['DATA_FORMAT'] == 'JSON'
      @headers = {'Accept' => 'application/json'}
    else
      @headers = {}
    end

    begin
      @logger.info("Extracting data from endpoint: #{@endpoint}")

      @current_data = @http_client.get(@endpoint, @headers)

      @logger.info("Current data size: #{@current_data.size}")

      @logger.info("Data successfully extracted.")
    end

    @logger.info("Session records logged.")
    @current_data
  end
end
