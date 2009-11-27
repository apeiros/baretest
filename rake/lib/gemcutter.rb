require 'uri'
require 'net/http'
require 'net/https'

class GemCutter
  URL = URI.parse("https://gemcutter.org/gems")

  def initialize
    @api_key   = Gem.configuration[:gemcutter_key]
    @proxy_uri = Gem.configuration[:http_proxy] || ENV['http_proxy'] || ENV['HTTP_PROXY']
    if [nil, :no_proxy].include?(@proxy_uri) then
      @proxy = Net::HTTP
    else
      proxy  = URI.parse(@proxy_uri)
      @proxy = Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password)
    end
    @http = @proxy.new(URL.host, URL.port)
    if URL.scheme == 'https'
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @http.use_ssl = true
    end
  end

  def push(gem_file)
    request_method = @proxy_class::Post
    request        = request_method.new(URL.path)

    request.body   = File.read(name)
    request.add_field("Content-Length", request.body.size)
    request.add_field("Content-Type", "application/octet-stream")
    request.add_field("Authorization", @api_key)

    @http.request(request)
  end
end
