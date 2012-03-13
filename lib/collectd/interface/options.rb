require 'getoptlong'
require 'singleton'
require 'forwardable'
require 'collectd/interface/config'

module Collectd
  module Interface
    class Options
      include Singleton
      attr_writer :help
      def initialize
        @help = String.new
        @options = GetoptLong.new(
          ['--debug','-d',GetoptLong::NO_ARGUMENT],
          ['--help','-h',GetoptLong::NO_ARGUMENT],
          ['--port','-p',GetoptLong::REQUIRED_ARGUMENT],
          ['--log-file-path','-l',GetoptLong::REQUIRED_ARGUMENT],
          ['--pid-file-path','-P',GetoptLong::REQUIRED_ARGUMENT],
          ['--config-dump','-C',GetoptLong::NO_ARGUMENT],
          ['--config','-c',GetoptLong::REQUIRED_ARGUMENT],
          ['--version',GetoptLong::NO_ARGUMENT],
        )
      end
      def parse
       @options.each do |opt,arg|
           case opt
           when '--port'
             Config['service']['port'] = arg.to_i
           when '--log-file-path'
             if File.directory? arg
               Config['service']['log_path'] = arg
             else
               raise("#{arg} is not a directory!")
             end
           when '--pid-file-path'
             if File.directory? arg
               Config['service']['pid_path'] = arg
             else
               raise("#{arg} is not a directory!")
             end
           when '--config-dump'
             $stdout.puts Config.inspect
             exit 0
           when '--debug'
             Config['debug'] = true
           when '--help'
             $stdout.puts @help
             exit 0
           when '--config'
             config = File.expand_path(arg)
             if File.directory? config
             else
               raise %Q[Configuration directory "#{config}" missing!]
             end
           when '--version'
             $stdout.puts '0.5.0'
             exit 0 
          end
        end
      end
      class << self
        extend Forwardable
        def_delegators :instance, *Options.instance_methods(false)
      end    
    end
  end
end
