require 'json'
require 'sinatra/base'
require 'collectd/interface/service/data'
require 'collectd/interface/service/graph'

module Collectd
  module Interface
    class Service < Sinatra::Base
      configure do
        mime_type :json, 'application/json'
        mime_type :plain, 'text/plain'
        _hostname = `hostname -f`.chop
        _root = File.expand_path(File.join(File.dirname(File.expand_path(__FILE__)),'..','..','..'))
        if ENV.has_key?('COLLECTD_RRD_FILES')
          _rrd_path = File.join(ENV['COLLECTD_RRD_FILES'],_hostname)
        else
          _rrd_path = File.join('/var/lib/collectd/rrd/',_hostname)
        end
        _public = File.join(_root,'public')
        # get a list of all graph templates available
        _graphs = Hash.new
        Dir["#{_root}/views/graphs/*.erb"].each do |graph|
          _graphs[File.basename(graph,'.erb')] = graph
        end
        # get a list of all RRD file created by Collectd 
        _data = Array.new 
        Dir["#{_rrd_path}/**/*.rrd"].each do |file|
          plugin = file.gsub(%r<#{_rrd_path}>,'').split('/')[1]
          rrd = File.basename(file,'.rrd')
          `rrdtool info "#{file}"`.scan(%r{ds\[(\w*)\]}).uniq.flatten.each do |set|
            _data << "#{plugin}/#{rrd}/#{set}"
          end
        end
        _reports = Hash.new
        Dir["#{_root}/views/reports/*.erb"].each do |report|
          _reports[File.basename(report,'.erb')] = report
        end
        set :root, _root
        set :rrd_path, _rrd_path
        set :public_folder, _public
        set :static, true
        set :environment, :production
        set :graphs, _graphs
        set :data, _data
        set :reports, _reports
      end
      get '/config/:name' do
        if settings.respond_to?(params[:name])
          _data = settings.send(params[:name])
          if %w(graphs reports data).include? params[:name]
            content_type :json
            JSON.pretty_generate(_data)
          else
            content_type :text
            _data
          end
        else
          not_found
        end
      end
    end
  end
end
