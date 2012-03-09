require 'sinatra/base'
module Collectd
  module Interface
    class Service < Sinatra::Base
      # give the user an interface to select data from the Collectd
      # RRD file stored on disk
      get '/data' do
        @data = settings.data
        # client has selected a specific data source
        if params.has_key?('display')
          @target = params['display']
          # this URI parameter needs to be removed for the redirect
          params.delete('display') 
          # all other URI parameters will be passed on
          p = Array.new; params.each_pair { |k,v| p << "#{k}=#{v}" }
          @args = p.join('&')
          # get the data
          redirect "/data/#{@target}?#{@args}"
        # REST style interface discovery to list all available data sources
        elsif params.has_key?('format')
          case params['format']
          when 'json'
            content_type :json
            JSON.pretty_generate @data.map! { |d| "/data/#{d}" }
          # present a clear text by default
          else
            content_type :plain
            @data.join("\n")
          end
        # render the default view display the selection menu
        else
          @target = 'data'
          erb :data, :layout => "template/default".to_sym
        end
      end
      # interface to the data source 
      get '/data/*' do |path|
        redirect '/data' if path.empty?
        # build the data sources file name
        plugin,type,value = path.split("/")
        file = "#{settings.rrd_path}/#{plugin}/#{type}.rrd" 
        unless File.exists? file
          "Couldn't find source file #{file}"
        else
          data = Array.new
          # construct the RRD query
          # return average bu default
          function = 'AVERAGE'
          if params.has_key? 'function'
            param = params['function'].upcase
            if %w(AVERAGE MIN MAX).include? param
              function = param
            end
          end
          # build the command line to read the RRD file
          command = "rrdtool fetch #{file} #{function}"
          command << " --end Now --start Now-#{params['last']}" if params.has_key? 'last'
          command << " --r #{params['resolution']}"if params.has_key? 'resolution'
          # get the data
          output = `#{command}`.split("\n")
          # select the value of interest
          headers = output.shift.split # remove header
          key = headers.index(value)
          output.delete_at 0 # remove empty line
          # collect the data
            output.each do |line|
            line = line.delete(':').split
            time = line[0].to_i
            value = line[key+1].to_f # omit time stamp
            lv = data[-1]
            data << [time, value]
          end
          # remove most time wrong elements
          data.slice!(0)
          data.slice!(-1)
          # filter values which are the same for multiple timestamps
          final_data = []
          data.each_index do |el|
            cur_e = data[el][1]
            if data[el-1] != nil and data[el+1] != nil and el != 0 and el != data.size-1
              last_e = data[el-1][1]
              next_e = data[el+1][1]
              if cur_e != last_e or cur_e != next_e then
                final_data.push(data[el])
              end
            else
              final_data.push(data[el])
            end
          end
          data = final_data
          if params.has_key? 'format'
            if params['format'] == 'json'
              content_type :json
              json = {'name'=>"#{plugin} #{file}",'data'=>data}
              JSON.pretty_generate json
            else
              content_type 'text/plain'
              output = String.new
              data.each { |line| output << "#{line[0]}: #{line[1..-1].join(' ')}\n" }
              output
            end
          else
            @data = data
            erb :show_values
          end
        end
      end
    end
  end
end
