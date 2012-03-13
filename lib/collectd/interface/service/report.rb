require 'uri'
require 'net/http'
require 'sinatra/base'

module Collectd
  module Interface
    class Service < Sinatra::Base

      get '/report' do
        @reports = settings.reports.keys.sort 
        # List all available path to reports
        if params.has_key? 'format' 
          report_list = @reports.map! { |r| "/report/#{r}" }
          if params['format'] == 'json'
            content_type :json
            JSON.pretty_generate report_list
          else # default is plain text
            content_type :text
            report_list.join("\n")
          end
        # Render a HTML representation of all/one report(s)
        else
          # list of the URLs to requested all reports selected by the client query
          _reports_selected = Array.new
          # the default report to display
          unless params.has_key? 'display'
            _reports_selected << '/report/storage?format=html'
          # when a selection is passed by URI parameter
          else 
            _display = params['display']
            # show all reports
            if _display == 'all'
              @reports.each do |path|
                _reports_selected << "/report/#{path}?format=html"
              end
            # a report select by the client
            else
              not_fount unless settings.reports.has_key?(_display)
              # query URL for this request
              _reports_selected << "/report/#{_display}?format=html"
            end
          end
          @target = 'report'
          # actual reports requested by the client query
          @reports_selected = Hash.new
          _reports_selected.each do |path| 
            __uri = URI.parse("http://localhost:#{settings.port}#{path}")
            @reports_selected[path] = Net::HTTP.get_response(__uri).body
          end
          erb :report, :layout => :'template/default'
        end
      end

      get '/report/*' do |path|
        redirect '/report' if path.empty?
        unless settings.reports.has_key?(path)
          redirect '/report'
        end
        _template = settings.reports[path]
        # user asks for a specific output format
        if params.has_key?('format')
          case params['format']
          when 'json'
            content_type :json
            @type = 'json'
          when 'html'
            @type = 'html'
          else 
            content_type :plain 
            @type = 'text'
          end
        else
          content_type :plain
          @type = 'text'
        end
        @param = path.split('/')[-1]
        erb :"reports/#{_template}"
      end
   
    end
  end
end
