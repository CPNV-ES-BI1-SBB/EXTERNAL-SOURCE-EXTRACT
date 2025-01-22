require_relative 'config/env'
require_relative 'routes/job_routes'

class MyApp < Sinatra::Base
  configure do
    set :logger, Logger.new(ENV.fetch('SERVER_LOG_PATH', 'logs/server_log.log'))

  end

  register JobRoutes

  # Root endpoint for health check
  get '/' do
    'API is running. Use /api/v1/data/extract to create a new job and /api/v1/data/:job_id/download to download the processed data.'
  end
end