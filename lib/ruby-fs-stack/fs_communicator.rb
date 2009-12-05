require 'net/https'
require 'uri'

class FsCommunicator
  attr_accessor :domain, :key, :user_agent, :session, :handle_throttling
  
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
  def initialize(options = {})
    # merge default options with options hash
    o = {
      :domain => 'http://www.dev.usys.org',
      :key => '',
      :user_agent => 'FsCommunicator/0.1 (Ruby)', # should be overridden by options user_agent
      :session => nil,
      :handle_throttling => false
    }.merge(options)
    @domain = o[:domain]
    @key = o[:key]
    @user_agent = o[:user_agent]
    @session = o[:session]
    @handle_throttling = o[:handle_throttling]
  end
  
  def post(url,payload)
    uri = URI.parse(self.domain+url)
    full_url = set_extra_params(uri)
    request = Net::HTTP::Post.new(full_url)
    request.body = payload
    request['Content-Type'] = "application/json"
    request['User-Agent'] = self.user_agent
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == 'https'
      http.use_ssl = true 
      http.ca_file = File.join File.dirname(__FILE__), 'assets','entrust-ca.crt'
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
    res = http.start do |ht|
      ht.request(request)
    end
    if res.code == '503' && @handle_throttling
      sleep 15
      res = post(url,payload)
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
    if uri.scheme == 'https'
      http.use_ssl = true 
      http.ca_file = File.join File.dirname(__FILE__), 'assets','entrust-ca.crt'
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
    res = http.start do |ht|
      ht.request(request)
    end
    if res.code == '503' && @handle_throttling
      sleep 15
      res = get(url,credentials)
    end
    return res
  end
  
  private
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