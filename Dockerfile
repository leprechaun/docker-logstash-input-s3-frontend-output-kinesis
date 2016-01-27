FROM logstash:2

RUN /opt/logstash/bin/plugin install logstash-input-s3
RUN /opt/logstash/bin/plugin install logstash-output-kinesis
RUN /opt/logstash/bin/plugin install logstash-filter-de_dot

COPY logstash.conf.tpl /config/logstash-frontend.conf.tpl
