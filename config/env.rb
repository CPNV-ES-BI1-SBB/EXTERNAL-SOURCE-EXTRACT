require 'sinatra'
require 'json'
require 'securerandom'
require 'logger'
require_relative '../lib/extractor'
require_relative '../lib/http_client'

# Configure Sinatra
set :bind, ENV.fetch('BIND_ADDRESS', '0.0.0.0')
set :port, ENV.fetch('PORT', '4567').to_i

# In-memory storage for jobs with their status and data
$jobs = {}
