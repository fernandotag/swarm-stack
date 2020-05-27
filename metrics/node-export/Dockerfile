FROM prom/node-exporter:latest

COPY conf/docker-entrypoint.sh /etc/node-exporter/docker-entrypoint.sh

USER root
RUN chown nobody:wheel /etc/node-exporter
USER nobody

ENTRYPOINT  [ "/etc/node-exporter/docker-entrypoint.sh" ]
CMD [ "/bin/node_exporter" ]