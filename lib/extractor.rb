class Extractor
  attr_accessor :api_client, :logger, :max_retries, :current_data, :oldest_record_stored, :newest_record_received

  def initialize(api_client:, logger:, max_retries: 3)
    @api_client = api_client
    @logger = logger
    @max_retries = max_retries
  end

  def extract(oldest_record:)
  end

  def handle_duplicate(current_data:, oldest_record:)
  end

  def handle_missing(current_data:, oldest_record:)
  end

  def get_missing_data(oldest_record:)
  end

  def should_retry
  end

  def get_last_sent_request
  end

end
