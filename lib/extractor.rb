require 'time'

class Extractor
  attr_accessor :api_client, :logger, :max_retries, :current_data, :newest_record_stored, :oldest_record_retrieved

  def initialize(api_client:, logger:, max_retries: 3)
    @api_client = api_client
    @logger = logger
    @max_retries = max_retries
    @current_data = []
    @oldest_record_retrieved = nil
  end

  # Main extraction method
  def extract(endpoint: '/data', newest_record_stored: nil)
    @endpoint = endpoint
    @newest_record_stored = newest_record_stored || @newest_record_stored
    @current_data ||= []

    begin
      @logger.log_info("Starting data extraction...")

      # Charger les données depuis un mock ou une API
      if false # Toujours charger depuis un mock dans cet exemple
        file_path = File.expand_path('../test/mocks/mock_shortened.json', __dir__)
        @logger.log_info("Loading mock data from #{file_path}")
        @current_data = File.read(file_path)
        @current_data = JSON.parse(@current_data)
      else
        @current_data = @api_client.get(@endpoint, params: { since: @newest_record_stored })
      end

      @logger.log_info("Current data size: #{@current_data.size}")

      # Met à jour oldest_record_retrieved
      @oldest_record_retrieved = @current_data.first['time']

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
    @logger.log_info("Session records logged.")
    @logger.log_info("Oldest record retrieved: #{@oldest_record_retrieved}")
    @logger.log_info("Newest record stored: #{@newest_record_stored}")
    @current_data
  end


  # Handle duplicate records
  def handle_duplicate()
    @logger.log_info("Checking for duplicates...")
    initial_size = @current_data.size
    @current_data = @current_data['connections']
    @current_data['connections'].uniq! { |record| record }
    @logger.log_info("Duplicates removed: #{@current_data.size - initial_size}")
  end

  # Handle missing records
  def handle_missing()
    @logger.log_info("Checking for missing data...")
    if (!@current_data.empty?)
      # If the newest record received is older than the oldest record stored for more than 15 min, we may have missing data
      if(@newest_record_stored["time"]!=nil)
        if @oldest_record_retrieved && Time.parse(@oldest_record_retrieved["time"]) < Time.parse(@newest_record_stored["time"]) - 900
          get_missing_data()
          @logger.log_info("Missing data detected: First:#{missing_data.first['time']} Last:#{missing_data.last['time']}")
        end
      end
    else
      get_missing_data()
      @logger.log_info("Missing data detected: First:#{missing_data.first['time']} Last:#{missing_data.last['time']}")
    end
  end

  # Retrieve missing data (mock implementation)
  def get_missing_data(newest_record_stored:)
    if @max_retries > 0
      puts "newest_record_stored: '#{newest_record_stored}'"
      extract(newest_record_stored: newest_record_stored, endpoint: '/data')
      @max_retries -= 1
    else
      @logger.log_error("Max retries reached. Unable to retrieve missing data.")
    end
  end

  # Determine the oldest record received
  def get_oldest_record_retrieved(current_data:)
    unless current_data.is_a?(Array)
      puts "Error: current_data is not an Array. "
      return nil
    end

    # Si current_data est vide, on sort tôt.
    return nil if current_data.empty?

    result = current_data.min_by do |record|
      begin
        record["time"] ? Time.parse(record["time"]) : (Time.now + 999999)
      rescue ArgumentError
        puts "Warning: Invalid 'time' format in record #{record.inspect}"
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
  class MaxRetriesReachedError < StandardError; end
end
