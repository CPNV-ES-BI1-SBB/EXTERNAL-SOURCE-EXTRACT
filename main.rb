require_relative 'routes/job_routes'

$jobs = {}

class MyApp < Sinatra::Base
  configure do
    set :logger, Logger.new(ENV.fetch('SERVER_LOG_PATH', 'logs/server_log.log'))
    set :bind, ENV.fetch('BIND_ADDRESS', '0.0.0.0')
    set :port, ENV.fetch('PORT', '4567').to_i
  end
  register JobRoutes

  # Root endpoint for health check
  get '/' do
    'API is running. Use /api/v1/data/extract to create a new job and /api/v1/data/:job_id/download to download the processed data.'
  end
end