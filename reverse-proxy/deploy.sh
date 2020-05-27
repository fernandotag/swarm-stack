export $(cat ../.env) && docker stack deploy -c stack-reverse-proxy.yml reverse-proxy
