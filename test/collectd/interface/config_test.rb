require 'test/unit'
require 'collectd/interface/config'

class TestCollectdInterfaceConfig < Test::Unit::TestCase
  include Collectd::Interface
  def test_config
    assert_instance_of(String,Config.root)  
  end
end
