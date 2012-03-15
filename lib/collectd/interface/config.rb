require 'json'
require 'erb'
require 'singleton'
require 'forwardable'

module Collectd
  module Interface
    class Config

      include Singleton
      
      def initialize
        # Holds all configurations
        @data = Hash.new
        # No debugging by default
        @data['debug'] = false
        # defaults for the Sinatra application
        @data['service'] = Hash.new
        @data['service']['port'] = 5000
        @data['service']['pid_path'] = String.new
        @data['service']['log_path'] = String.new
        # User defined path to graphs and reports plug-ins 
        @data['plugin_path'] = String.new
        # find the application root directory relative to this configuration file
        @data['root'] = File.expand_path(File.join(File.dirname(File.expand_path(__FILE__)),'..','..','..'))
        _hostname = `hostname -f`.chop
        # Path to the RRD file written by Collectd
        @data['rrd_path'] = File.join('/var/lib/collectd/rrd/',_hostname)
        graphs_add_build_ins()
        reports_add_build_ins()
        data_add_all_sources()
      end

      def [](key); @data[key] end
      def []=(key,value); @data[key] = value end

      def to_json; JSON.pretty_generate(@data) end   

      def inspect
        %Q[-- Config --\n#{self.to_json}\n------------] 
      end

      # Is the application in debugging mode?
      def debug?; self['debug'] end

      # Path to the application root directory.
      def root; self['root'] end

      # Does the user wants to write a file containing the PID?
      def pid_file?
        self['service']['pid_path'].empty?
      end
      # Path to the PID file.
      def pid_file(name)
        File.join(self['service']['pid_path'],"#{name}.pid")
      end
      # Does the user wants to write a log file?
      def log_file?
        self['service']['log_path'].empty?
      end
      # Path to the log file.
      def log_file(name)
        File.join(self['service']['log_path'],"#{name}.log")
      end

      # Add optional user plug-ins to the configuration, where
      # _path_ is the path to the directory containing graph
      # and report plug-ins.
      def plugin_path(path)
        # will be added to the Sinatra views array
        self['plugin_path'] = path
        # add all optional graphs
        _path = File.join(path,'graphs')
        if File.directory? _path
          Dir["#{_path}/**/*.erb"].each do |file|
            graphs_add_plugin(_path,file)
          end
        end
        # add all optional reports
        _path = File.join(path,'reports')
        if File.directory? _path
          Dir["#{_path}/**/*.erb"].each do |file|
            reports_add_plugin(_path,file)
          end
        end
      end

      # Make sure all instance methods are accessible for client objects
      class << self
        extend Forwardable
        def_delegators :instance, *Config.instance_methods(false)
      end

      private

      # Find all RRD files written by Collectd and construct 
      # a list of URL paths used to access them.
      def data_add_all_sources
        self['data'] = Array.new 
        Dir["#{self['rrd_path']}/**/*.rrd"].each do |file|
          plugin = file.gsub(%r<#{self['rrd_path']}>,'').split('/')[1]
          rrd = File.basename(file,'.rrd')
          `rrdtool info "#{file}"`.scan(%r{ds\[(\w*)\]}).uniq.flatten.each do |set|
            self['data'] << "#{plugin}/#{rrd}/#{set}"
          end
        end
      end

      # Adds a graph plug-in to the configuration, where _path_ is the URL path 
      # used to call it and _file_ is the location of the plug-in in the file-system. 
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

      # Searches for all graph plug-ins shipped with this application.
      def graphs_add_build_ins
        self['graphs'] = Hash.new
        # path to the plug-ins shipped with this software
        _path = File.join(self.root,'views','graphs')
        Dir["#{_path}/**/*.erb"].each do |file|
          graphs_add_plugin(_path,file)
        end
      end

      # Adds a report plug-in to the configuration, where _path_ is the URL path 
      # used to call it and _file_ is the location of the plug-in in the file-system. 
      def reports_add_plugin(path,file)
        # strip the template suffix
        _name = file.gsub(/\.erb/,'')
        # remove the path to the graph template directory
        _name = _name.gsub(%r<#{path}>,'')[1..-1]
        # strip the application path from the file name
        _file = file.gsub(%r<#{path}/>,'').gsub(/\.erb/,'')
        # if the plug-in lives inside a sub-directory
        if _name.include?('/')
          # ask the plug-in for its configuration
          @config = true
          _supports = JSON.parse(ERB.new(File.read(file)).result(binding))
          # if the answer is empty the plug-in supports only a single URL path
          if _supports.empty?
            self['reports'][_name] = _file
          # otherwise add the list of paths to the configuration
          else
            _supports.each do |path|
              self['reports']["#{_name}/#{path}"] = _file
            end
          end
        else
          self['reports'][_name] = _file
        end
      end

      # Searches for all reports shipped with this application.
      def reports_add_build_ins
        self['reports'] = Hash.new
        _path = File.join(self.root,'views','reports')
        Dir["#{_path}/**/*.erb"].each do |file|
          reports_add_plugin(_path,file)
        end
      end

    end
  end
end
