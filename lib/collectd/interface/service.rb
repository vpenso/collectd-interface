require 'json'
require 'sinatra/base'
require 'collectd/interface/config'
require 'collectd/interface/service/data'
require 'collectd/interface/service/graph'

module Collectd
  module Interface
    class Service < Sinatra::Base
      configure do
        mime_type :json, 'application/json'
        mime_type :plain, 'text/plain'
        # read the configuration object and set the Sinatra defaults
        set :root, Config.root
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
