require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!(Minitest::Reporters::SpecReporter.new) if defined?(Minitest::Reporters)

# Charger les fichiers du projet
require_relative 'lib/extractor'
require_relative 'lib/http_client'

require_relative 'test/test_extractor'
