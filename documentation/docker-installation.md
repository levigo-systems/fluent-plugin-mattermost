# Docker installation

### Dockerfile

You need to enter the repository where you can download and later install the plugin. Here is a snippet code  
**Attention:** If you use gitlab, don't forget to enter the token for oauth2

```docker
...

RUN gem install fluent-plugin-mattermost

...
```