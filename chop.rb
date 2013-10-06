require_relative 'app_config'
require 'sinatra/base'
require 'sinatra/respond_with'
require 'redis'
require 'digest/sha1'
require 'json'
require 'uri'

# setup redis
uri = URI.parse(REDIS_URI)
RD = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

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

  set :views, "./views"

  get '/:hash' do
    url = RD.get params[:hash]
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
        RD.setnx hash, url
        hash
      end
      f.json do
        url = JSON.parse(request.body.read)['url']
        hash = shorten url
        RD.setnx hash, url
        {:hash => hash}.to_json
      end
    end
  end
end

# vim: ai ts=2 sw=2 et sts=2
