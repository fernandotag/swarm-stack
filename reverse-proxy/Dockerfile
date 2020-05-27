FROM traefik:v2.2

WORKDIR /traefik

COPY ./traefik/rules /traefik/rules
COPY ./traefik/data/traefik.log /traefik/data/traefik.log
COPY ./traefik/data/acme/acme.json /traefik/data/acme/acme.json 

USER root

RUN chmod 600 /traefik/data/acme/acme.json 