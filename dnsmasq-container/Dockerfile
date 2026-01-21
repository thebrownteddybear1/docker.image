FROM ubuntu:20.04
RUN apt-get update && apt-get install -y dnsmasq && rm -rf /var/lib/apt/lists/*
COPY config/dnsmasq.conf /etc/dnsmasq.conf
COPY config/hosts.custom /etc/hosts.custom
EXPOSE 53/udp 53/tcp
CMD ["dnsmasq", "-k"]