export $(cat ../.env) && docker stack deploy -c stack-portainer.yml portainer
