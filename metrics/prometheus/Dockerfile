FROM prom/prometheus:v2.18.1

COPY conf /etc/prometheus/

CMD  [ "--config.file=/etc/prometheus/prometheus.yml", \
       "--storage.tsdb.path=/prometheus", \
       "--web.console.libraries=/usr/share/prometheus/console_libraries", \
       "--web.console.templates=/usr/share/prometheus/consoles"]
