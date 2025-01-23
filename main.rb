require_relative 'routes/job_routes'
require_relative 'lib/s3_client'
require_relative 'lib/cache_manager'

class DataExtractorApp < Sinatra::Base
  configure do
    set :logger, Logger.new(ENV.fetch('SERVER_LOG_PATH', 'logs/server_log.log'))
    set :bind, ENV.fetch('BIND_ADDRESS', '0.0.0.0')
    set :port, ENV.fetch('PORT', '4567').to_i
    set :environment, :production
  end
  register JobRoutes

  s3Client = S3Client.new()
  cache_manager = CacheManager.new(s3Client, ENV['AWS_BUCKET_NAME'])

  set :cache_manager, cache_manager


  # Root endpoint for health check
  get '/' do
    'API is running. Use /api/v1/data/extract to create a new job and /api/v1/data/:job_id/download to download the processed data.'
  end
end

DataExtractorApp.run! if $PROGRAM_NAME == __FILE__