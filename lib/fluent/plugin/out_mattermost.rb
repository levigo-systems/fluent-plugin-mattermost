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

      config_param :message_title, :string, default: "fluent_error_title_default"

      config_param :message_color, :string, default: "#A9A9A9"

      config_param :message, :string, default: nil

      config_param :message_keys, default: nil do |val|
        val.split(',')
      end

      config_param :enable_tls,  :bool, default: true

      def configure(conf)
        super
      end

      def start
        super
        log.info(webhook_url: @webhook_url, 
                 channel_id: @channel_id, 
                 message_title: @message_title, 
                 message_color: @message_color, 
                 message: @message, 
                 enable_tls: @enable_tls)
      end

      def write(chunk)
        begin
          message = getInfos(chunk)
          
          #it checks if the message contains information. If it is empty, no message is sent.
          if JSON.parse(message[1]) != [""]
            post(message)
          end
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

      def getInfos(chunk)
        messages = []
        messages << "\n"
        chunk.msgpack_each do |time, record|
          messages << "#{build_message(record)}\n"
        end

        return messages
      end

      def build_message(record)
        if @message_keys != nil
          values = fetch_keys(record, @message_keys)
          @message % values.to_json
        else
          @message % record.to_json
        end
      end

      def fetch_keys(record, keys)
        Array(keys).map do |key|
          begin
            record.dig("message".to_sym, key, nil).to_s
          rescue KeyError
            log.warn "out_mattermost: the specified message_key '#{key}' not found in record. [#{record}]"
            ''
          end
        end
      end
    end
  end
end
