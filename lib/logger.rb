##
# A logger class that writes log messages to a file.
#
# Use this class to log messages at different levels (INFO and ERROR) to a file.
#
# @param log_path [String] The path to the log file.
#
class CLogger
  attr_reader :last_log

  def initialize(log_path:)
    @log_path = log_path
    @file = File.open(@log_path, 'a')
  end

  ##
  # Logs a message at the "info" level.
  #
  # Use this to log normal operation messages, like "Process started".
  #
  # @param message [String] The message to log.
  #
  def log_info(message)
    @last_log = "[INFO] #{timestamp}: #{message}"
    write_log(@last_log)
  end

  ##
  # Logs a message at the "error" level.
  #
  # Use this to log issues or exceptions, like "API call failed".
  #
  # @param error [String] The error message to log.
  #
  def log_error(error)
    @last_log = "[ERROR] #{timestamp}: #{error}"
    write_log(@last_log)
  end

  ##
  # Archives the log file the file handle with the current log messages and the timestamp.
  #
  # Call this method when you're done logging messages.
  #
  # @param archive_dir [String] The directory to archive the log file in.
  #
  def archive_log(archive_dir)
    Dir.mkdir(archive_dir) unless Dir.exist?(archive_dir)

    archive_path = File.join(archive_dir, "log_#{timestamp}.log")

    @file.close
    File.rename(@log_path, archive_path)
  end

  private

  def write_log(log_message)
    @file.puts(log_message)
  end

  def timestamp
    Time.now.strftime('%Y-%m-%d_%H-%M-%S')
  end
end
