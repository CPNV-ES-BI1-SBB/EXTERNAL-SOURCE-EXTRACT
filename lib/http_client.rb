require 'net/http'
require 'json'

##
# A client for making HTTP GET requests to an external API.
#
# This class handles building requests, setting headers, and making the request.
#
# @param base_url [String] The base URL for the API (e.g., 'https://api.example.com').
# @param headers [Hash] Optional headers to include in requests (e.g., authorization tokens).
# @param timeout [Integer] Timeout in seconds for requests. Default is 30 seconds.
#
class HTTPClient
  attr_accessor :base_url, :headers, :timeout

  ##
  # Initializes a new APIClient instance.
  # 
  # @param base_url [String] The base URL for the API.
  # @param headers [Hash] Optional headers to include in requests.
  # @param timeout [Integer] Timeout in seconds for requests.
  #
  def initialize(base_url:, headers: {}, timeout: 30)
    @base_url = base_url
    @headers = headers
    @timeout = timeout
  end

  ##
  # Makes an HTTP GET request to the specified endpoint with optional query parameters.
  #
  # @param endpoint [String] The endpoint to send the request to (e.g., '/data').
  # @param params [Hash] Query parameters to include in the request if needed.
  # @return [JSON] The JSON response from the API.
  #
  # @raise [StandardError] If the request fails.
  #
  def get(endpoint, params = {})
    uri = URI.join(@base_url, endpoint)

    request = Net::HTTP::Get.new(uri)
    @headers.each { |key, value| request[key] = value }

    make_request(uri, request)
  end

  private

  def make_request(uri, request)
    response = nil

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', read_timeout: @timeout) do |http|
      response = http.request(request)
    end

    handle_response(response)
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        raise StandardError, "Failed to parse JSON response: #{e.message}"
      end
    else
      raise StandardError, "HTTP Error: #{response.code} - #{response.message}"
    end
  end
end
