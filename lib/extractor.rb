require 'time'
require 'json'
require 'logger'

##
# Extractor class to handle data extraction from an API.
# This class is responsible for extracting data, handling missing data, and removing duplicates.
# 
class Extractor
  class MaxRetriesReachedError < StandardError;end
  attr_accessor :http_client, :logger, :max_retries, :current_data, :newest_record_stored, :oldest_record_retrieved, :endpoint

  # Initializes a new Extractor instance.
  #
  # @param http_client [Object] The API client for data extraction.
  # @param logger [Object] A logger instance for logging events.
  # @param max_retries [Integer] The maximum number of retries allowed (default: 3).
  # 
  def initialize()
    @http_client = nil
    @max_retries = ENV.fetch('MAX_RETRIES', 3).to_i
    @logger = Logger.new(ENV.fetch('EXTRACT_LOG_PATH', 'logs/extract_log.log'))
    @max_retries = max_retries
    @current_data = {}
    @oldest_record_retrieved = {}
    @newest_record_stored = {}
    @endpoint = ''
  end

  ##
  # Main method to extract data from the API, checking for missing data and duplicates.
  #
  # @param endpoint [String] The endpoint to query for data.
  # @param newest_record_stored [JSON] The most recent record stored.
  # @return [JSON] The extracted data.
  # 
  def extract(http_client:, endpoint:, newest_record_stored: {})
    @http_client = http_client
    @endpoint = endpoint
    @logger.info(newest_record_stored)
    @headers = {}

    begin
      @logger.info("Extracting data from endpoint: #{@endpoint}")

      @current_data = @http_client.get(@endpoint, @headers)

      @logger.info("Current data size: #{@current_data.size}")

      @oldest_record_retrieved = @current_data['connections'].last

      @logger.info("Oldest record retrieved: #{@oldest_record_retrieved}")

      handle_missing()

      @logger.info("Data successfully extracted and merged.")
    end

    handle_duplicate()
    @newest_record_stored = @oldest_record_retrieved
    @logger.info("Session records logged.")
    @logger.info("Oldest record retrieved: #{@oldest_record_retrieved}")
    @logger.info("Newest record stored: #{@newest_record_stored}")
    @current_data
  end

  private

  def handle_duplicate
    @logger.info("Checking for duplicates...")

    if @current_data['connections'].nil? || @current_data['connections'].empty?
      @logger.info("No data to check for duplicates.")
      return
    end

    initial_size = @current_data['connections'].size

    @current_data['connections'].uniq! { |record| record.to_json }

    duplicates_removed = initial_size - @current_data['connections'].size
    @logger.info("Duplicates removed: #{duplicates_removed}")

    if duplicates_removed > 0
      @logger.info("Duplicate records were found and removed.")
    else
      @logger.info("No duplicate records detected.")
    end
  end

  def handle_missing
    @logger.info("Checking for missing data...")

    if @current_data['connections'].nil? || @current_data['connections'].empty?
      @logger.info("No connections.")
      get_missing_data(newest_record_stored: @newest_record_stored)
      return
    end

    first_connection_time = @current_data['connections'].first['time']
    @logger.info(first_connection_time)
    if first_connection_time.nil?
      @logger.error("First connection time missing, cannot validate data integrity.")
      return
    end

    begin
      first_time = Time.parse(first_connection_time)
      midnight = Time.new(first_time.year, first_time.month, first_time.day, 0, 0, 0)
      fifteen_minutes_after_midnight = midnight + (15 * 60)
  
      if first_time > fifteen_minutes_after_midnight
        @logger.info("Detected missing data: first record is after 15 minutes past midnight.")
        get_missing_data(newest_record_stored: @newest_record_stored)
      else
        @logger.info("No missing data detected.")
      end
  
    rescue ArgumentError => e
      @logger.error("Error parsing time: #{e.message}")
    end
  end

  def get_missing_data(newest_record_stored:)
    @logger.info("Retries left: #{@max_retries}")
    if @max_retries > 0
      @max_retries -= 1
      @logger.info("Retrying data extraction...")
      extract(http_client: @http_client, endpoint: @endpoint, newest_record_stored: newest_record_stored)
    else
      raise MaxRetriesReachedError, "Max retries reached. Cannot retrieve missing data."
    end
  end  
end
