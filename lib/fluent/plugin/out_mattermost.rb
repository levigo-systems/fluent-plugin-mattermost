require "fluent/plugin/output"
require 'fluent-logger'
require 'uri'
require 'net/http'
require 'net/https'
require 'logger'
require "json"

module Fluent
  module Plugin
    class MattermostOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output("mattermost", self)

      # Required parameter: The configuration must have this parameter like 'param1 10'.
      config_param :webhook_url, :string, default: nil

      config_param :record, :string, default: "record"

      config_param :enable_tls,  :bool, default: true

      def configure(conf)
        super
      end
      def start
        super
        log.info(webhook_url: @webhook_url, record: @record)
      end

      def write(chunk)
        begin
          log.error "I am an error"
          logInspector
          if @record
            post(#{@record})
          end
        rescue Timeout::Error => e
          log.warn "out_mattermost:", :error => e.to_s, :error_class => e.class.to_s
          raise e # let Fluentd retry
        rescue => e
          log.error "out_mattermost:", :error => e.to_s, :error_class => e.class.to_s
          log.warn_backtrace e.backtrace
          # discard. @todo: add more retriable errors
        end
      end

      def post(payload)

        url = URI(@webhook_url)

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = @enable_tls

        request = Net::HTTP::Post.new(url)
        request["Content-Type"] = "application/json"
        request.body = JSON.dump({
          "channel_id": URI(@webhook_url).path.split('/').last,
          "attachments": message(payload)
        })

        response = https.request(request)

        if response.read_body != "ok"
          log.error "response from mattermost: ", response.read_body
        else 
          puts response.read_body
        end
      end

      def message(record)
        payload = [{
                    "author_name": "Fluentd",
                    "thumb_url": "https://coralogix.com/wp-content/uploads/2020/04/fluentd-guide-700x430.png",
                    "color": "#FF0000",
                    "fields": [
                    {
                      "short":false,
                      "title":"Fluentd error",
                      "value": record
                    }]
                  }]
        log.info payload
        return payload
      end

      def logInspector()
        # API: FluentLogger.new(tag_prefix, options)
        log = Fluent::Logger::FluentLogger.new(nil, :host => 'localhost', :port => 24224)
        p log.last_error # You can get last error object via last_error method
      end
    end
  end
end
