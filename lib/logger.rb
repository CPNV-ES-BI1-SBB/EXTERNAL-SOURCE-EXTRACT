class Logger
  attr_accessor :log_path, :last_log

  def initialize(log_path:)
    @log_path = log_path
  end

  def log_info(message)
  end

  def log_error(message)
  end
end
