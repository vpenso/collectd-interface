require 'json'
require 'erb'
require 'singleton'
require 'forwardable'

module Collectd
  module Interface
    class Config
      include Singleton
      def initialize
        @data = Hash.new
        @data['debug'] = false
        # defaults for the Sinatra application
        @data['service'] = Hash.new
        @data['service']['port'] = 5000
        @data['service']['pid_path'] = String.new
        @data['service']['log_path'] = String.new
        @data['plugin_path'] = String.new
        # find the application root directory relative to this configuration file
        @data['root'] = File.expand_path(File.join(File.dirname(File.expand_path(__FILE__)),'..','..','..'))
        _hostname = `hostname -f`.chop
        @data['rrd_path'] = File.join('/var/lib/collectd/rrd/',_hostname)
        find_graphs()
        find_data()
        find_reports()
      end
      # Hash like access to the internals
      def [](key); @data[key] end
      def []=(key,value); @data[key] = value end
      # type casts & inspection
      def to_json; JSON.pretty_generate(@data) end   
      def inspect
        %Q[-- Config --\n#{self.to_json}\n------------] 
      end
      # short cuts for attributes
      def debug?; @data['debug'] end
      # does the user wants to write a file containing the PID
      def pid_file?
        self['service']['pid_path'].empty?
      end
      def pid_file(name)
        File.join(self['service']['pid_path'],"#{name}.pid")
      end
      def log_file?
        self['service']['log_path'].empty?
      end
      def log_file(name)
        File.join(self['service']['log_path'],"#{name}.log")
      end
      # add optional user plug-ins to the configuration
      def plugin_path(path)
        self['plugin_path'] = path
        _path = File.join(path,'graphs')
        if File.directory? _path
          Dir["#{_path}/**/*.erb"].each do |file|
            graphs_add_plugin(_path,file)
          end
        end
      end
      def root; @data['root'] end
      class << self
        extend Forwardable
        def_delegators :instance, *Config.instance_methods(false)
      end
      private
      def graphs_add_plugin(path,file)
        # strip the template suffix
        _name = file.gsub(/\.erb/,'')
        # remove the path to the graph template directory
        _name = _name.gsub(%r<#{path}>,'')[1..-1]
        # strip the application path from the file name
        _file = file.gsub(%r<#{path}/>,'').gsub(/\.erb/,'')
        # does the plug-in supports URI parameters
        if _name.include?('/')
          # ask the plug-in for supported paths
          @config = true
          @rrd_path = self['rrd_path']
          _supports = JSON.parse(ERB.new(File.read(file)).result(binding))
          if _supports.empty?
            self['graphs'][_name] = _file
          else
            _supports.each do |path|
              self['graphs']["#{_name}/#{path}"] = _file
            end
          end
        else
          self['graphs'][_name] = _file
        end
      end
      def find_graphs
        self['graphs'] = Hash.new
        # path to the plug-ins shipped with this software
        _path = File.join(self.root,'views','graphs')
        Dir["#{_path}/**/*.erb"].each do |file|
          graphs_add_plugin(_path,file)
        end
      end
      def find_data
        self['data'] = Array.new 
        Dir["#{self['rrd_path']}/**/*.rrd"].each do |file|
          plugin = file.gsub(%r<#{self['rrd_path']}>,'').split('/')[1]
          rrd = File.basename(file,'.rrd')
          `rrdtool info "#{file}"`.scan(%r{ds\[(\w*)\]}).uniq.flatten.each do |set|
            self['data'] << "#{plugin}/#{rrd}/#{set}"
          end
        end
      end
      def find_reports
        self['reports'] = Hash.new
        _path = File.join(self.root,'views','reports')
        Dir["#{_path}/**/*.erb"].each do |file|
          # strip the template suffix
          _name = file.gsub(/\.erb/,'')
          # remove the path to the graph template directory
          _name = _name.gsub(%r<#{_path}>,'')[1..-1]
          # strip the application path from the file name
          _file = file.gsub(%r<#{_path}/>,'').gsub(/\.erb/,'')
          # path to the template file
          if _name.include?('/')
            @config = true
            _supports = JSON.parse(ERB.new(File.read(file)).result(binding))
            _supports.each do |path|
               self['reports']["#{_name}/#{path}"] = _file
            end
          else
            self['reports'][_name] = _file
          end
        end
      end
    end
  end
end
