require 'sinatra'
require 'json'
require 'securerandom'
require 'logger'
require 'fileutils'
require_relative '../lib/extractor'
require_relative '../lib/http_client'

module JobRoutes

  JOBS_FILE = ENV.fetch('JOBS_FILE_PATH', '/app/data/jobs.json')

  def self.load_jobs
    if File.exist?(JOBS_FILE)
      JSON.parse(File.read(JOBS_FILE))
    else
      {}
    end
  end

  def self.save_jobs(jobs)
    File.write(JOBS_FILE, jobs.to_json)
  end

  $jobs = load_jobs

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
      $jobs[job_id] = { status: 'in_progress', endpoint: endpoint, created_at: Time.now }
      JobRoutes.save_jobs($jobs)
      settings.logger.info("Job created with ID: #{job_id}")

      begin
        http_client = HTTPClient.new
        extractor = Extractor.new
        result = extractor.extract(http_client: http_client, endpoint: endpoint)
        
        $jobs[job_id][:status] = 'completed'
        $jobs[job_id][:data] = result
        JobRoutes.save_jobs($jobs)
        settings.logger.info("Data extraction completed for job ID: #{job_id}")

        status 201
        { status: $jobs[job_id][:status], url: "/api/v1/data/#{job_id}/download" }.to_json

      rescue Extractor::MaxRetriesReachedError => e
        settings.logger.error("Max retries reached: #{e.message}")
        $jobs[job_id][:status] = 'failed'
        JobRoutes.save_jobs($jobs)
        halt 500, { error: 'Max retries reached while trying to extract data', details: e.message }.to_json

      rescue StandardError => e
        settings.logger.error("Unexpected error: #{e.message}")
        $jobs[job_id][:status] = 'failed'
        JobRoutes.save_jobs($jobs)
        halt 500, { error: 'Unexpected error occurred', details: e.message }.to_json
      end
    end

    app.get '/api/v1/data/:job_id/download' do
      content_type :json
      job_id = params['job_id']
      job = $jobs[job_id]

      if job.nil?
        halt 404, { error: 'Job not found' }.to_json
      elsif job[:status] != 'completed'
        halt 400, { error: 'Job is not completed yet' }.to_json
      else
        { data: job[:data] }.to_json
      end
    end
  end
end
