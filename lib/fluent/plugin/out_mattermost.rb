require "fluent/plugin/output"
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

      config_param :text, :string, default: nil

      config_param :enable_tls,  :bool, default: true

      def configure(conf)
        super
      end
      def start
        super
        log.info(webhook_url: @webhook_url, text: @text)
      end

      def write(chunk)
        begin
          if @text
            post(@text)
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

      def message(text)
        payload = [{
                    "author_name": "Fluentd",
                    "thumb_url": "https://coralogix.com/wp-content/uploads/2020/04/fluentd-guide-700x430.png",
                    "color": "#FF0000",
                    "fields": [
                    {
                      "short":false,
                      "title":"Fluentd error",
                      "value": text
                    }]
                  }]
        log.info payload
        return payload
      end

      def chunkInspector(chunk)
        chunk.open do |io|
          begin
            data = io.read
            records = Fluent::MessagePackFactory.msgpack_unpacker(StringIO.new(data)).to_enum.to_a
            puts "data #{data.size / 1024} KB - #{records.size} records"
            puts records.first
            log.info records.first
            puts "^^ this should not happen - msgpack parsing error" unless records.first.is_a? Array
          end
        end
      end
    end
  end
end
