require 'sinatra'
require 'json'
require 'securerandom'
require 'logger'
require 'fileutils'
require_relative '../lib/extractor'
require_relative '../lib/http_client'

module JobRoutes

  def self.registered(app)
    app.post '/api/v1/data/extract' do
      content_type :json
      request_body = JSON.parse(request.body.read)
      endpoint = request_body['endpoint']
      settings.logger.info("Received request to extract data. Request endpoint: #{endpoint}")

      if endpoint.nil? || endpoint.empty?
        settings.logger.error("Missing or empty 'endpoint' parameter.")
        halt 400, { error: 'Missing endpoint parameter' }.to_json
      end

      job_id = SecureRandom.uuid
      settings.logger.info("Job created with ID: #{job_id}")

      begin
        cached_data = settings.cache_manager.search_json_db(endpoint)
          
        if cached_data
          settings.logger.info("Data already extracted for endpoint: #{endpoint}")
          status 200
          return { status: 'completed', url: settings.cache_manager.generate_signed_url(cached_data['uuid']) }.to_json
        end
        
        http_client = HTTPClient.new
        extractor = Extractor.new
        result = extractor.extract(http_client: http_client, endpoint: endpoint)      

        settings.logger.info("Data extraction completed for job ID: #{job_id}")
        
        status 200
        { status: 'completed', url: settings.cache_manager.upload_json_data(job_id, endpoint, result) }.to_json

      rescue Extractor::MaxRetriesReachedError => e
        settings.logger.error("Max retries reached: #{e.message}")
        halt 500, { error: 'Max retries reached while trying to extract data', details: e.message }.to_json

      rescue StandardError => e
        settings.logger.error("Unexpected error: #{e.message}")
        halt 500, { error: 'Unexpected error occurred', details: e.message }.to_json
      end
    end
  end
end
