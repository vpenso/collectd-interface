require 'test/unit'
require 'rack/test'
require 'pp'
require 'collectd/interface/service'

class TestCollectdInterfaceService < Test::Unit::TestCase
  include Rack::Test::Methods
  def app
    Collectd::Interface::Service
  end
  def test_config
     %w( 
       root 
       rrd_path 
       public_folder 
       graphs 
       data
       reports
     ).each do |config|
       get "/config/#{config}"
       assert last_response.ok?
     end
     get "/config/foo"
     assert last_response.status == 404
  end
end
