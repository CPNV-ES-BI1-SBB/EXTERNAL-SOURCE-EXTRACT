require 'time'

class Extractor
  attr_accessor :api_client, :logger, :max_retries, :current_data, :oldest_record_stored, :newest_record_received

  def initialize(api_client:, logger:, max_retries: 3)
    @api_client = api_client
    @logger = logger
    @max_retries = max_retries
    @current_data = []
    @oldest_record_stored = nil
    @newest_record_received = nil
  end

  # Main extraction method
  def extract(oldest_record_stored:)
    @oldest_record_stored = oldest_record_stored
    retries = @max_retries
  
    begin
      @logger.log_info("Starting data extraction...")
  
      # Charger les données depuis un mock ou une API
      if true # Toujours charger depuis un mock dans cet exemple
        file_path = 'test\mocks\mock_shortened.json'
        @logger.log_info("Loading mock data from #{file_path}")
        response = File.read(file_path)
      else
        response = @api_client.get("/data", params: { since: @oldest_record_stored })
      end
  
      # Parse JSON et extraire connections
      parsed_response = JSON.parse(response)
      connections = parsed_response["connections"] || []
  
      # Initialisation sécurisée de @current_data
      @current_data ||= []
  
      # Ajouter les nouvelles connexions
      @current_data.concat(connections).uniq!
      @logger.log_info("Extracted #{connections.size} connections. Current data size: #{@current_data.size}")
  
      # Met à jour newest_record_received
      @newest_record_received = get_oldest_record_received(current_data: @current_data)
      @logger.log_info("Newest record received: #{@newest_record_received}")
  
      # Gérer les doublons et les données manquantes
      handle_missing(current_data: @current_data, oldest_record: @oldest_record_stored)
      handle_duplicate(current_data: @current_data, oldest_record: @oldest_record_stored)
  
      @logger.log_info("Data successfully extracted and merged.")
  
    rescue StandardError => e
      @logger.log_error("Error during extraction: #{e.message}")
      retries -= 1
      retry if retries > 0
      @logger.log_error("Max retries reached. Extraction failed.")
    end
  
    @current_data
  end
  

  # Handle duplicate records
  def handle_duplicate(current_data:, oldest_record:)
    @logger.log_info("Checking for duplicates...")
    filtered_data = current_data.reject { |record| record["id"] <= oldest_record["id"] }
    @logger.log_info("Duplicates removed: #{current_data.size - filtered_data.size}")
    filtered_data
  end

  # Handle missing records
  def handle_missing(current_data:, oldest_record:)
    @logger.log_info("Checking for missing data...")
    missing_data = get_missing_data(oldest_record: oldest_record)

    if missing_data.empty?
      @logger.log_info("No missing data found.")
    else
      @logger.log_info("Missing data detected: #{missing_data}")
      raise "Missing data not resolved" if @max_retries <= 0
    end
  end

  # Retrieve missing data (mock implementation)
  def get_missing_data(oldest_record:)
    # Simulate logic to find missing data based on oldest_record
    # Returns empty array if no data is missing
    []
  end

  # Determine the oldest record received
  def get_oldest_record_received(current_data:)
  
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
    { endpoint: "/data", params: { since: @oldest_record_stored } }
  end
end
