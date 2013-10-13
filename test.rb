ENV['RACK_ENV'] = 'test'

require_relative 'chop'
require 'test/unit'
require 'rack/test'
require 'erb'
require 'ostruct'

def render_erb(template_file, locals)
  fp = File.read(template_file)
  ERB.new(fp).result(OpenStruct.new(locals).instance_eval { binding })
end

class ChopTest < Test::Unit::TestCase
  include Rack::Test::Methods

  @@hash = "89dce6a"
  @@url = "http://example.com"

  def app
    Chop
  end

  def setup
    header 'Accept', 'application/json'
    request = {:url => @@url}.to_json
    post '/', request, "CONTENT_TYPE" => "application/json"
  end

  def test_get_root
    get '/'
    assert last_response.status == 404
  end

  def test_post_url
    request = {:url => @@url}.to_json
    response = {:hash => @@hash}.to_json

    header 'Accept', 'application/json'
    post '/', request, "CONTENT_TYPE" => "application/json"

    assert last_response.ok?
    assert last_response.body == response
  end

  def test_get_url_json
    header 'Accept', 'application/json'
    get "/#{@@hash}"
    assert last_response.status == 200
    assert(last_response.body == {:url => @@url}.to_json)
  end

  def test_get_url_plain
    header 'Accept', '*/*'
    get "/#{@@hash}"
    assert last_response.status == 200
    assert last_response.body == @@url
  end

  # html redirect
  def test_get_url_html
    header 'Accept', 'text/html'
    get "/#{@@hash}"
    assert last_response.status == 302
  end

  def test_get_url_preview
    # html preview
    header 'Accept', 'text/html'
    get "/#{@@hash}?p"
    assert last_response.status == 200
    assert last_response.body == render_erb('views/preview.erb', :url => @@url)
  end

  def test_get_unknown_url
    get '/test'
    assert last_response.status == 404
  end
end

# vim: ai ts=2 sw=2 et sts=2
