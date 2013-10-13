require 'sinatra/base'
require 'sinatra/respond_with'
require 'digest/sha1'
require 'json'
require 'uri'

if ENV['RACK_ENV'] == 'test'
  require 'fakeredis'
else
  require 'redis'
end

REDIS_URL = ENV["REDIS_URL"] || ENV["REDISTOGO_URL"] ||
            "redis://127.0.0.1:6379"

module Sinatra
  module ChopHelpers
    def shorten(url)
      Digest::SHA1.hexdigest(url)[0..6]
    end
  end

  helpers ChopHelpers
end

class Chop < Sinatra::Base
  helpers Sinatra::ChopHelpers
  register Sinatra::RespondWith

  configure :test do
    $redis = Redis.new
  end

  configure :production, :development do
    uri = URI.parse(REDIS_URL)
    $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  end

  set :views, "./views"

  get '/:hash' do
    url = $redis.get params[:hash]
    if url
      respond_to do |f|
        f.on('text/plain') { url }
        f.on('text/html') do
          if request.query_string == 'p'
            erb :preview, :locals => {:url => url}
          else
            redirect url
          end
        end
        f.json { {:url => url}.to_json }
      end
    else
      halt 404
    end
  end

  post '/' do
    respond_to do |f|
      f.on('text/html') do
        url = params[:url]
        hash = shorten url
        $redis.setnx hash, url
        hash
      end
      f.json do
        url = JSON.parse(request.body.read)['url']
        hash = shorten url
        $redis.setnx hash, url
        {:hash => hash}.to_json
      end
    end
  end
end

# vim: ai ts=2 sw=2 et sts=2
