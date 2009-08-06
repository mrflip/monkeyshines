#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra/base'
require 'haml'
require 'oauth'
require 'monkeyshines'

DOMAIN = :twitter_api

DOMAINS = {
  :myspace_api => {
    :site               => 'http://api.myspace.com',
    :request_token_path => "/request_token",
    :authorize_path     => "/authorize",
    :access_token_path  => "/access_token",
    :oauth_callback     => "http://monk3shines.com/ext/myspace/cb",
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

  get %r{ext/\w+/cb} do
    "Gotcha."
  end

  #
  # Front Page
  #
  get "/foo" do
    # # haml :root
    out = ''
    @consumer = OAuth::Consumer.new(oauth_api_key, oauth_api_secret,
      DOMAINS[DOMAIN]
      )
    out << inspection(@user, @@config, @consumer)

    @request_token_foo = @consumer.create_signed_request(@consumer.http_method, @consumer.request_token_path, nil, DOMAINS[DOMAIN])
    out << inspection(@request_token_foo)
    out << inspection(@request_token_foo.to_hash)
    @request_token = @consumer.get_request_token
    out << inspection(@consumer, @request_token)

    session[:request_token] = @request_token
    # redirect_to @request_token.authorize_url
    out
  end


  private

  def oauth_api_key
    @@config[DOMAIN][:api_key]
  end
  def oauth_api_secret
    @@config[DOMAIN][:api_secret]
  end
  def oauth_site
    DOMAINS[DOMAIN][:site]
  end

  def inspection *args
    str = args.map{|thing| thing.inspect }.join("\n")
    Monkeyshines.logger.info str
    '<pre>'+h(str)+'</pre>'
  end

end
