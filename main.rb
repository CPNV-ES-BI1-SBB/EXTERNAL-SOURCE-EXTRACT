require 'sinatra'
require 'json'
require_relative 'lib/extractor'
require_relative 'lib/http_client'
require_relative 'lib/logger'
require_relative 'lib/s3_client'
require 'dotenv/load'

# Initialisation de S3Client
s3_client = S3Client.new

# Configure Sinatra
set :bind, ENV.fetch('BIND_ADDRESS', '0.0.0.0')
set :port, ENV.fetch('PORT', '4567').to_i

# Logger instance for the application
logger = CLogger.new(log_path: ENV.fetch('SERVER_LOG_PATH', 'server_log.txt'))

# Define the /api/v1/extract endpoint
get '/api/v1/extract' do
  content_type :json
  endpoint = params['endpoint']

  if endpoint.nil? || endpoint.empty?
    logger.log_error("Missing or empty 'endpoint' parameter.")
    halt 400, { error: 'Missing endpoint parameter' }.to_json
  end

  begin
    http_client = HTTPClient.new
    extractor = Extractor.new
    result = extractor.extract(http_client: http_client, endpoint: endpoint)

    status 200
    result.to_json

  rescue Extractor::MaxRetriesReachedError => e
    logger.log_error("Max retries reached: #{e.message}")
    headers 'X-Error-Type' => 'MaxRetriesReachedError'
    halt 500, {
      error: 'Max retries reached while trying to extract data',
      details: e.message
    }.to_json

  rescue StandardError => e
    logger.log_error("Unexpected error: #{e.message}")
    headers 'X-Error-Type' => 'StandardError'
    halt 500, {
      error: 'Unexpected error occurred',
      details: e.message
    }.to_json
  end
end

# Route pour lister les fichiers
get '/list_s3' do
  bucket = params[:bucket] || 'dev.external.source.extract.cld.education'
  s3_client.list_files(bucket).join("\n")
end

# Route pour uploader un fichier
post '/upload_s3' do
  bucket = params[:bucket] || 'dev.external.source.extract.cld.education'
  file = params[:file][:tempfile] if params[:file]
  filename = params[:file][:filename] if params[:file]

  if file && filename
    object_key = filename
    s3_client.upload_file(file, bucket, object_key)
    "Fichier #{filename} uploadé avec succès dans le bucket #{bucket}."
  else
    status 400
    "Aucun fichier fourni pour l'upload."
  end
end

# Root endpoint for health check
get '/' do
  'API is running. Use /api/v1/extract?endpoint=<URL> to call the extractor.'
end
