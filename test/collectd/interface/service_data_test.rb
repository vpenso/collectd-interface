require 'test/unit'
require 'rack/test'
require 'pp'
require 'collectd/interface/service'

class TestCollectdInterfaceService < Test::Unit::TestCase
  include Rack::Test::Methods
  def app
    Collectd::Interface::Service
  end
  def test_service_data_selector
    get "/data"
    assert last_response.ok?
    get "/data?format=json"
    assert last_response.ok?
    assert last_response.header['Content-Type'] =~ /^application\/json.*/
    get "/data?format=text"
    assert last_response.ok?
    assert last_response.header['Content-Type'] =~ /^text\/plain.*/
    get "/data/"
    follow_redirect!
    assert last_response.ok?
  end
  def test_service_data_sources
    _source = '/data/load/load/midterm'
    [
      _source,
      "#{_source}?last=1w",
      "#{_source}?last=1d",
      "#{_source}?last=30",
      "#{_source}?last=3m",
      "#{_source}?last=0",
      "#{_source}?last=1d&function=last",
      "#{_source}?last=1d&resolution=30s",
    ].each do |query|
      get query
      assert last_response.ok?
    end
    get "#{_source}?format=json"
    assert last_response.ok?
    assert last_response.header['Content-Type'] =~ /^application\/json.*/
    get "#{_source}?format=text"
    assert last_response.ok?
    assert last_response.header['Content-Type'] =~ /^text\/plain.*/
  end
end
