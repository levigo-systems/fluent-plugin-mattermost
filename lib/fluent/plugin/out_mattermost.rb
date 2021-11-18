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

      config_param :channel_id, :string, default: nil

      config_param :message_title, :string, default: "fluent_title_default"

      config_param :message_color, :string, default: "#A9A9A9"

      config_param :message, :string, default: nil

      config_param :enable_tls,  :bool, default: true

      def configure(conf)
        super
      end

      def start
        super
        check_config_params
      end

      def write(chunk)
        begin
          message = get_infos(chunk)

          post(message)
        rescue Timeout::Error => e
          log.warn "out_mattermost:", :error => e.to_s, :error_class => e.class.to_s
          raise e # let Fluentd retry
        rescue => e
          log.error "out_mattermost:", :error => e.to_s, :error_class => e.class.to_s
          log.warn_backtrace e.backtrace
        end
      end

      def post(payload)

        url = URI(@webhook_url)

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = @enable_tls

        request = Net::HTTP::Post.new(url)
        request["Content-Type"] = "application/json"
        request.body = JSON.dump({
          "channel_id": @channel_id,
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
                    "color": @message_color,
                    "fields": [
                    {
                      "short": false,
                      "title": @message_title,
                      "value": record
                    }]
                  }]
        return payload
      end

      def get_infos(chunk) 
        messages = []
        messages << "\n"
        chunk.msgpack_each do |time, record|
          messages << "#{build_message(record)}\n"
        end

        return messages
      end

      def build_message(record)
        @message % record.to_json
      end

      def check_config_params()
        if @webhook_url.nil? || @channel_id.nil? || @message.nil?
          raise "Check in your Mattermost config, that all parameters in the configuration file are filled"
          abort
        end
      end
    end
  end
end
