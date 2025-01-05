require 'time'
require 'json'

class Extractor
  class MaxRetriesReachedError < StandardError;end
  attr_accessor :api_client, :logger, :max_retries, :current_data, :newest_record_stored, :oldest_record_retrieved

  def initialize(api_client:, logger:, max_retries: 3)
    @api_client = api_client
    @logger = logger
    @max_retries = max_retries
    @current_data = {}
    @oldest_record_retrieved = {}
  end

  # Main extraction method
  def extract(endpoint: '/data', newest_record_stored: {})
    @endpoint = endpoint
    @logger.log_info(newest_record_stored)

    begin
      @logger.log_info("Starting data extraction...")

      @current_data = @api_client.get(@endpoint)

      @logger.log_info("Current data size: #{@current_data.size}")

      # Met à jour oldest_record_retrieved
      @oldest_record_retrieved = @current_data['connections'].last

      @logger.log_info("Oldest record retrieved: #{@oldest_record_retrieved}")

      # Gérer les doublons et les données manquantes
      handle_missing()

      @logger.log_info("Data successfully extracted and merged.")

    rescue StandardError => e
      @logger.log_error("Error during extraction: #{e.message}")
      @max_retries -= 1
      retry if @max_retries > 0
      @logger.log_error("Max retries reached. Extraction failed.")
    end

    handle_duplicate()
    @newest_record_stored = @oldest_record_retrieved
    @logger.log_info("Session records logged.")
    @logger.log_info("Oldest record retrieved: #{@oldest_record_retrieved}")
    @logger.log_info("Newest record stored: #{@newest_record_stored}")
    @current_data
  end


  # Handle duplicate records
  def handle_duplicate
    @logger.log_info("Checking for duplicates...")

    if @current_data['connections'].nil? || @current_data['connections'].empty?
      @logger.log_info("No data to check for duplicates.")
      return
    end

    # Convert each record to a hash string for comparison
    initial_size = @current_data['connections'].size

    # Remove duplicates based on the entire record being the same
    @current_data['connections'].uniq! { |record| record.to_json }

    duplicates_removed = initial_size - @current_data['connections'].size
    @logger.log_info("Duplicates removed: #{duplicates_removed}")

    if duplicates_removed > 0
      @logger.log_info("Duplicate records were found and removed.")
    else
      @logger.log_info("No duplicate records detected.")
    end
  end


  # Handle missing records
  def handle_missing
    @logger.log_info("Checking for missing data...")

    if @current_data['connections'].nil? || @current_data['connections'].empty?
      @logger.log_info("No connections.")
      get_missing_data(newest_record_stored: @newest_record_stored)
      return
    end

    first_connection_time = @current_data['connections'].first['time']
    @logger.log_info(first_connection_time)
    if first_connection_time.nil?
      @logger.log_error("First connection time missing, cannot validate data integrity.")
      return
    end

    begin
      # Parsing the time and checking if the time is later than 00:15
      first_time = Time.parse(first_connection_time)
      midnight = Time.new(first_time.year, first_time.month, first_time.day, 0, 0, 0)
      fifteen_minutes_after_midnight = midnight + (15 * 60) # 15 minutes in seconds
  
      # Check if the first record is later than 00:15
      if first_time > fifteen_minutes_after_midnight
        @logger.log_info("Detected missing data: first record is after 15 minutes past midnight.")
        get_missing_data(newest_record_stored: @newest_record_stored)
      else
        @logger.log_info("No missing data detected.")
      end
  
    rescue ArgumentError => e
      @logger.log_error("Error parsing time: #{e.message}")
    end
  end

  # Retrieve missing data with retry
  def get_missing_data(newest_record_stored:)
    while @max_retries > 0
      @logger.log_info("Attempting to fetch missing data, retries left: #{@max_retries}")
      extract(newest_record_stored: newest_record_stored, endpoint: '/data')
      @max_retries -= 1

      raise MaxRetriesReachedError.new("Max retries reached.") if @max_retries.zero?
      break unless @current_data.empty?
    end
  end

  # Determine the oldest record received
  def get_oldest_record_retrieved(current_data:)
    unless current_data.is_a?(Array)
      logger.log_error("Error: current_data is not an Array. ")
      return nil
    end

    # Si current_data est vide, on sort tôt.
    return nil if current_data.empty?

    result = current_data.min_by do |record|
      begin
        record["time"] ? Time.parse(record["time"]) : (Time.now + 999999)
      rescue ArgumentError
        Time.now + 999999
      end
    end
    result
  end

  # Determine whether retries are allowed
  def should_retry
    @max_retries > 0
  end

  # Retrieve the last sent request (mock implementation)
  def get_last_sent_request
    # Returns a mock request for now
    { endpoint: @endpoint, params: { since: @newest_record_stored } }
  end
end
