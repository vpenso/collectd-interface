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
          # the default report to display
          unless params.has_key? 'display'
            @display = 'storage'
          # when a selection is passed by URI parameter
          else 
            _display = params['display']
            # show all reports
            if _display == 'all'
              @display = 'all'
              # list of all templates 
              @templates = Array.new
              @reports.each do |report|
                @templates << settings.reports[report]
              end
            # select a specific report
            else
              if settings.reports.has_key?(_display)
                @display = settings.reports[_display]
              else
                not_found
              end
            end
          end
          @target = 'report'
          erb :report, :layout => "template/default".to_sym
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
