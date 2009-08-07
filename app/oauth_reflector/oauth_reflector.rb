#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra/base'
require 'haml'
require 'oauth'
require 'monkeyshines'


DOMAINS = {
  :myspace_api => {
    :site               => 'http://api.myspace.com',
    :http_method        => :post,
    :request_token_path => "/request_token",
    :authorize_path     => "/authorize",
    :access_token_path  => "/access_token",
    :oauth_callback     => "http://monk3shines.com/ext/myspace/cb",
  },
  :friendster_api => {
    :site               => 'http://api.friendster.com',
    :http_method        => :post,
    :request_token_path => '/v1/token',
    :authorize_path     => 'http://www.friendster.com/widget_login.php', # widget_login.php?api_key=....
    :access_token_path  => '/v1/session',
    :oauth_callback     => "http://monk3shines.com/ext/friendster/cb",
  },
  :twitter_api => {
    :site               => 'http://twitter.com',
    :request_token_path => '/oauth/request_token',
    :authorize_path     => '/oauth/authorize',
    :access_token_path  => '/oauth/access_token',
    :oauth_callback     => "http://monk3shines.com/ext/twitter/cb",
  },
}

#
# OauthReflector -- sinatra frontend for Monkeyshines OAuth reflection
#
# sudo gem install --no-ri --no-rdoc sinatra rack rack_csrf thin shotgun oauth oauth-plugin
#
# run with
#   shotgun --port=12000 --server=thin ./oauth_reflector.rb
#
class OauthReflector < Sinatra::Base
  # Server setup
  helpers do include Rack::Utils ; alias_method :h, :escape_html ; end
  set :sessions,           true
  set :static,             true
  set :logging,            true
  set :dump_errors,        true
  set :root,               File.dirname(__FILE__)
  #configure :production do Fiveruns::Dash::Sinatra.start(@@config[:fiveruns_key]) end

  configure do
    @@config = YAML.load_file(ENV['HOME']+"/.monkeyshines") rescue nil || {}
    DOMAINS.each do |api, hsh|
      @@config[api] = hsh.merge(@@config[api])
    end
    Monkeyshines.logger.info "Loaded config file with #{@@config.length} things"
  end

  before do
    next if request.path_info =~ /ping$/
    @user = session[:user]
  end

  #
  # Front Page
  #
  get "/" do
    haml :root
  end

  #
  # Front Page
  #
  get "/ext/myspace/auth" do
    @domain = :myspace_api
    inspection DOMAINS[@domain]
    inspection consumer
    @request_token = consumer.get_request_token(:oauth_callback => DOMAINS[@domain][:oauth_callback])
    session[:request_token]        = @request_token.token
    session[:request_token_secret] = @request_token.secret
    inspection @request_token, @request_token.authorize_url
    redirect @request_token.authorize_url
  end

  get "/ext/twitter/auth" do
    @domain = :twitter_api
    @request_token = consumer.get_request_token(:oauth_callback => DOMAINS[@domain][:oauth_callback])
    session[:request_token]        = @request_token.token
    session[:request_token_secret] = @request_token.secret
    redirect @request_token.authorize_url
  end

  get '/ext/twitter/cb' do
    @access_token = consumer.get_access_token params[:request_token], DOMAINS[DOMAIN]
  end

  get %r{ext/\w+/cb} do
    "Gotcha: #{params.inspect}"
  end

  get %r{ext/\w+/install} do
    "Pretend I'm installed."
  end
  get %r{ext/\w+/uninstall} do
    "Pretend I'm uninstalled."
  end

  private

  def consumer
    @consumer ||= OAuth::Consumer.new(oauth_api_key, oauth_api_secret, DOMAINS[@domain] )
  end

  def config_val attr
    @@config[@domain][attr]
  end

  def oauth_api_key()      config_val(:api_key)    ; end
  def oauth_api_secret()   config_val(:api_secret) ; end
  def oauth_site()         config_val(:site)       ; end
  def request_token_path() config_val(:request_token_path) ; end
  def authorize_path()     config_val(:authorize_path   )  ; end
  def access_token_path()  config_val(:access_token_path)  ; end

  # def nonce
  #   Time.now.utc.to_f.to_s.gsub(/\D/, '')
  # end
  # def request_token_url
  #   "#{oauth_site}#{request_token_path}?api_key=#{oauth_api_key}&format=json&nonce=#{nonce}"
  # end
  # def access_token_url(request_token)
  #   "#{oauth_site}#{access_token_path}?api_key=#{oauth_api_key}&format=json&nonce=#{nonce}&auth_token=#{request_token}"
  # end
  # def authorize_url
  #   base = (authorize_path =~ %r{^http://}) ? authorize_path : oauth_site+authorize_path
  #   "#{base}?api_key=#{oauth_api_key}"
  # end

  def inspection *args
    str = args.map{|thing| thing.inspect }.join("\n")
    Monkeyshines.logger.info str
    '<pre>'+h(str)+'</pre>'
  end

end
