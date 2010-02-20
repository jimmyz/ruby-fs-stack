require 'ruby-fs-stack/errors'
require 'net/https'
require 'uri'

class FsCommunicator
  attr_accessor :domain, :key, :user_agent, :session, :handle_throttling, :logger, :timeout
  include RubyFsStack
  # ====Params
  # <tt>options</tt> - a hash with the following options
  # * :domain - Defaults to "http://www.dev.usys.org" (the Reference System)
  # * :key - Your developer key. Defaults to ''
  # * :user_agent - Your User-Agent string. This should be overridden by your app. It
  #   defaults to "FsCommunicator/0.1 (Ruby)"
  # * :session - A session string if you already have one.
  # * :handle_throttling - (true|false) Defaults to false. If true, when a 503 response
  #   is received from the API, it will sleep 15 seconds, and try again until successful.
  #   You will likely want this turned off when running this library from Rails or any other
  #   system that is single-threaded so as to not sleep the entire process until throttling 
  #   is successful.
  # * :logger - (optional) if a logger is assigned to the communicator, all get requests and 
  #   responses will be logged. The request and response ("GET /path" and "200 OK") will be
  #   logged at the info level. Headers and request/response bodies will be logged at the debug
  #   level.
  def initialize(options = {})
    # merge default options with options hash
    o = {
      :domain => 'http://www.dev.usys.org',
      :key => '',
      :user_agent => 'FsCommunicator/0.1 (Ruby)', # should be overridden by options user_agent
      :session => nil,
      :handle_throttling => false,
      :logger => nil,
      :timeout => nil
    }.merge(options)
    @domain = o[:domain]
    @key = o[:key]
    @user_agent = o[:user_agent]
    @session = o[:session]
    @handle_throttling = o[:handle_throttling]
    @logger = o[:logger]
    @timeout = o[:timeout]
  end
  
  def post(url,payload)
    uri = URI.parse(self.domain+url)
    full_url = set_extra_params(uri)
    request = Net::HTTP::Post.new(full_url)
    request.body = payload
    request['Content-Type'] = "application/json"
    request['User-Agent'] = self.user_agent
    
    http = Net::HTTP.new(uri.host, uri.port)
    set_ssl(http) if uri.scheme == 'https'
    http.read_timeout = @timeout unless @timeout.nil?
    
    log_request('POST',full_url,request) if logger
    res = http.start do |ht|
      ht.request(request)
    end
    log_response(res) if logger
    
    if res.code == '503' && @handle_throttling
      sleep 15
      res = post(url,payload)
    elsif res.code != '200'
      raise_exception(res)
    end
    return res
  end
  
  def get(url,credentials = {})
    uri = URI.parse(self.domain+url)
    full_url = set_extra_params(uri,credentials)
    request = Net::HTTP::Get.new(full_url)
    request['User-Agent'] = self.user_agent
    if credentials[:username] && credentials[:password]
      request.basic_auth credentials[:username], credentials[:password]
    end
    
    http = Net::HTTP.new(uri.host, uri.port)
    set_ssl(http) if uri.scheme == 'https'
    http.read_timeout = @timeout unless @timeout.nil?
    
    log_request('GET',full_url,request) if logger
    res = http.start do |ht|
      ht.request(request)
    end
    log_response(res) if logger
    
    if res.code == '503' && @handle_throttling
      sleep 15
      res = get(url,credentials)
    elsif res.code != '200'
      raise_exception(res)
    end
    return res
  end
  
  private
  
  # 310 UserActionRequired
  # 400 BadRequest
  # 401 Unauthorized
  # 403 Forbidden
  # 404 NotFound
  # 409 Conflict
  # 410 Gone
  # 415 InvalidContentType
  # 430 BadVersion
  # 431 InvalidDeveloperKey
  # 500 ServerError
  # 501 NotImplemented
  # 503 ServiceUnavailable
  def raise_exception(res)
    case res.code
    when "310"
      exception = UserActionRequired.new res.message, self
    when "400"
      exception = BadRequest.new res.message, self
    when "401"
      exception = Unauthorized.new res.message, self
    when "403"
      exception = Forbidden.new res.message, self
    when "404"
      exception = NotFound.new res.message, self
    when "409"
      exception = Conflict.new res.message, self
    when "410"
      exception = Gone.new res.message, self
    when "415"
      exception = InvalidContentType.new res.message, self
    when "430"
      exception = BadVersion.new res.message, self
    when "431"
      exception = InvalidDeveloperKey.new res.message, self
    when "500"
      exception = ServerError.new res.message, self
    when "501"
      exception = NotImplemented.new res.message, self
    when "503"
      exception = ServiceUnavailable.new res.message, self
    end
    raise exception
  end
  
  def log_request(method,url,request)
    logger.info "#{method} #{url}"
    request.each_header do |k,v|
      logger.debug "#{k}: #{v}"
    end
    logger.debug request.body unless request.body.nil?
  end
  
  def log_response(response)
    logger.info "#{response.code} #{response.message}"
    response.each_header do |k,v|
      logger.debug "#{k}: #{v}"
    end
    logger.debug response.body
  end
  
  def set_ssl(http)
    http.use_ssl = true 
    http.ca_file = File.join File.dirname(__FILE__), 'assets','entrust-ca.crt'
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  end
  
  def set_extra_params(uri,credentials = {})
    if credentials[:username] && credentials[:password]
      sessionized_url = add_key(uri)
    else
      sessionized_url = add_session(uri)
    end
    sessionized_url << '&dataFormat=application/json'
  end
  
  def add_session(uri)
    if uri.query
      uri.query << '&sessionId=' + self.session
    else
      uri.query = 'sessionId=' + self.session
    end
    uri.request_uri
  end
  
  def add_key(uri)
    if uri.query
      uri.query << '&key=' + self.key
    else
      uri.query = 'key=' + self.key
    end
    uri.request_uri
  end
end