# fluent-plugin-mattermost

[Fluentd](https://fluentd.org/) output plugin to send message to Mattermost.

With this plugin you can send messages directly to a channel in Mattermost (for example in case of errors).

# Installation requirement

For the plugin to work properly, you need to have the following gem installed
- fluent-logger
```
$ gem install fluent-logger
```

# Installation

[Installation](documentation/installation.md)  
[Docker-installation](documentation/docker-installation.md)

# Usage (Incoming Webhook)
Link for
[Mattermost incoming webhook](https://docs.mattermost.com/developer/webhooks-incoming.html)

```apache
<match mattermost>
    @type mattermost
    webhook_url https://xxx.xx/hooks/xxxxxxxxxxxxxxx
    channel_id xxxxxxxxxxxxxxx
    message_color "#FFA500"
    message_title mattermost
    message %s
    enable_tls true
</match>
```

### Parameter

|parameter|description|type|dafault|
|---|---|---|---|
|webhook_url|Incoming Webhook URI (Required for Incoming Webhook mode). See https://docs.mattermost.com/developer/webhooks-incoming.html|string|nil|
|channel_id|the id of the channel where you want to receive the information|string|nil|
|message_color|color of the message you are sending, the format is hex code|string|#A9A9A9|
|message_title|title you want to add to the message|string|fluent_title_default
|message|The message you want to send, can be a static message, which you add at this point, or you can receive the fluent infos with the %s|string|nil
|enable_tls|you can set the communication channel if it uses tls|bool|true|

## Copyright

* Copyright(c) 2021- [levigo gruppe](https://www.levigo.de/)
* License