class APIClient
  attr_accessor :base_url, :headers, :timeout

  def initialize(base_url:, headers: {}, timeout: 10)
    @base_url = base_url
    @headers = headers
    @timeout = timeout
  end

  def get(endpoint:, params:)
  end
end
