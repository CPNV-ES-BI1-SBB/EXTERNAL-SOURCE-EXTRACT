require 'sinatra'
require 'json'
require 'securerandom'
require 'logger'
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
      $jobs[job_id] = { status: 'in_progress', endpoint: endpoint }
      settings.logger.info("Job created with ID: #{job_id}")

      begin
        http_client = HTTPClient.new
        extractor = Extractor.new
        result = extractor.extract(http_client: http_client, endpoint: endpoint)

        $jobs[job_id][:status] = 'completed'
        $jobs[job_id][:data] = result
        settings.logger.info("Data extraction completed for job ID: #{job_id}")

        status 201
        { status: $jobs[job_id][:status], url: "/api/v1/data/#{job_id}/download" }.to_json

      rescue Extractor::MaxRetriesReachedError => e
        settings.logger.error("Max retries reached: #{e.message}")
        $jobs[job_id][:status] = 'failed'
        halt 500, { error: 'Max retries reached while trying to extract data', details: e.message }.to_json

      rescue StandardError => e
        settings.logger.error("Unexpected error: #{e.message}")
        $jobs[job_id][:status] = 'failed'
        halt 500, { error: 'Unexpected error occurred', details: e.message }.to_json
      end
    end

    app.get '/api/v1/data/:job_id/download' do
      content_type :json
      job_id = params['job_id']
      settings.logger.info("Received request to download data for job ID: #{job_id}")

      job = $jobs[job_id]
      if job.nil?
        settings.logger.error("Job not found for ID: #{job_id}")
        halt 404, { error: 'Job not found' }.to_json
      elsif job[:status] != 'completed'
        settings.logger.error("Job is not completed yet for ID: #{job_id}")
        halt 400, { error: 'Job is not completed yet' }.to_json
      else
        settings.logger.info("Data downloaded for job ID: #{job_id}")
        status 200
        job[:data].to_json
      end
    end
  end
end
