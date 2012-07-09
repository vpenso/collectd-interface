require 'sinatra/base'
require 'fileutils'

module Collectd
  module Interface
    class Service < Sinatra::Base
      ##
      ## Web-Interface to all graphs generated from the Collectd RRD files
      ##
      get '/graph' do
        # Clients can discover a list of available graphs using the 
        # format parameters
        if params.has_key? 'format'
          graph_list = settings.graphs.keys.sort.map! { |g| "/graph/#{g}" }
          if params['format'] == 'json'
            content_type :json
            JSON.pretty_generate graph_list
          else
            content_type :text
            graph_list.join("\n")
          end
        # By default the web-interface will be displayed 
        else
          # by default each graph presents the last 12 hours
          unless params.has_key? 'start' and params.has_key? 'end'
            params['start'] = 'end-12h'
            params['end'] = 'now' 
          end
          params['image'] = 'png' unless params.has_key?('image')
          # display only a subset of the graphs by default
          unless params.has_key?('display')
            params['display'] = [ 'cpus', 'memory', 'load', ]
          end
          # pass the list of graphs to display into the template
          @display = params['display']
          # remove it from the parameter list
          params.delete('display') if params.has_key?('display')
          # all other parameters will be appended for the graph
          # generation.
          p = Array.new; params.each_pair { |k,v| p << "#{k}=#{v}" }
          @args = p.join('&')
          # list of all available graphs for the drop down menu
          @graphs = settings.graphs
          # identifier for the template
          @target = 'graph'
          # render the templates
          erb :graph, :layout => "template/default".to_sym
        end
      end

      get '/graph/*' do |path|
        unless settings.graphs.has_key? path
          status 404
        else
          # name of the template use to render the graph
          _template = settings.graphs[path]
          # path to the public directory to store the rendered image
          _target_path = File.dirname(File.join(settings.public_folder,'images',path))
          FileUtils.mkdir_p(_target_path) unless File.directory? _target_path 
          # variables available to the plug-in
          @color = {
            :red_light => '#FF000044', :red_dark => '#FF0000AA',
            :green_light => '#00F00022', :green_dark => '#00F000AA',
            :yellow_light => '#FFFF0022', :yellow_dark => '#FFFF00AA',
            :blue_light => '#0000FF22', :blue_dark => '#0000FFAA',
            :orange_light => '#FF450022', :orange_dark => '#FF4500AA',
            :cyan_light => '#00FFFF22', :cyan_dark => '#00FFFFAA',
            :purple_light => '#FF00FF22', :purple_dark => '#FF00FFAA'
          }
          @type = params.has_key?('image') ? params['image'] : 'png'
          if params.has_key? 'start' and params.has_key? 'end'
            @start = params['start']
            @end = params['end']
          else
            @start = 'end-24h'
            @end = 'now'
          end
          # clients can query custom sized graphs, without legend
          @graph_only = false
          if params.has_key?('width') and params.has_key?('height') 
            @width = params['width']
            @height = params['height']
            @graph_only = true 
          # default graph size
          else
            @width = 400 
            @height = 100
          end

          image_dir = Pathname.new(File.join(settings.graph_folder, path)).parent

          unless File.exist?(image_dir)
            FileUtils.mkpath image_dir
          end

          # name of the file to store the graph image into
          @target = %Q[#{settings.graph_folder}/#{path}.#{@type}]
          # location of the Collectd RRD files
          @rrd_path = settings.rrd_path + '/'
          # last value of the URI path is parameter to the template
          @param = path.split('/')[-1]
          # run the plug-in the generate to image
          command = erb :"graphs/#{_template}", :layout => :graph_header
          puts command.chomp if $DEBUG
          output = `#{command} > /dev/null 2>&1`
          puts output.chomp if $DEBUG and not output.empty?
          # redirect the client to the rendered image
          # redirect %Q[/images/#{path}.#{@type}]
          content_type 'image/png'
          File.read(%Q[#{settings.graph_folder}/#{path}.#{@type}])
        end
      end
    end
  end
end
