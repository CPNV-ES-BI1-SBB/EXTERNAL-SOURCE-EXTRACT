require_relative './lib/extractor'
require_relative './lib/api_client'
require_relative './lib/logger'

# Initialisation des dépendances
api_client = APIClient.new(base_url: 'https://api.example.com', headers: { 'Authorization' => 'Bearer token' }, timeout: 10)
logger = Logger.new(log_path: 'log.txt')
extractor = Extractor.new(api_client: api_client, logger: logger, max_retries: 3)

# Exemple d'utilisation
result = extractor.extract()
#puts "Extraction result: #{result}"
