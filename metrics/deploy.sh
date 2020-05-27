export $(cat ../.env) && docker stack deploy -c stack-metrics.yml metrics
