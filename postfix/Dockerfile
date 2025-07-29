FROM ubuntu:22.04
ENV DEBIAN_FRONTEND noninteractive
# Install postfix with mysql support
RUN apt-get update && apt-get install -y postfix sasl2-bin dnsutils rsyslog opendkim opendkim-tools mailutils

VOLUME /data

COPY entrypoint.sh dns.sh dkim.sh postfix.sh sasl.sh ssl.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh
EXPOSE 25
ENTRYPOINT ["entrypoint.sh"]
CMD ["tail", "-f", "/var/log/mail.log"]
