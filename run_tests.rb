require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!(Minitest::Reporters::SpecReporter.new) if defined?(Minitest::Reporters)

# Charger les fichiers du projet
require_relative 'lib/extractor'
require_relative 'lib/api_client'
require_relative 'lib/logger'
