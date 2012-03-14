require 'json'
require 'sinatra/base'
require 'collectd/interface/config'
require 'collectd/interface/service/data'
require 'collectd/interface/service/graph'
require 'collectd/interface/service/report'

module Collectd
  module Interface
    class Service < Sinatra::Base
      configure do
        mime_type :json, 'application/json'
        mime_type :plain, 'text/plain'
        # read the configuration object and set the Sinatra defaults
        set :root, Config.root
        set :port, Config['service']['port']
        # by default lookup templates in the application views/ directory
        _views = [ File.join(Config.root,'views') ]
        # optionally add a template directory defined by the user
        _views << Config['plugin_path'] unless Config['plugin_path'].empty?
        set :views, _views
        # overwrite the template lookup method to cover all
        # paths in views
        def find_template(views, name, engine, &block)
          Array(views).each do |path|
            super(path, name, engine, &block)
          end
        end
        set :rrd_path, Config['rrd_path']
        set :public_folder, File.join(Config.root,'public')
        set :static, true
        set :environment, :production
        set :graphs, Config['graphs']
        set :data, Config['data']
        set :reports, Config['reports']
      end
      get '/' do
        redirect '/graph'
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
